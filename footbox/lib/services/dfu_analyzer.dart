import 'dart:math';
import 'package:footbox/database/database_helper.dart';
import 'package:footbox/models/dfu_result.dart';
import 'package:footbox/models/patient.dart';
import 'package:flutter/foundation.dart';
import 'package:footbox/services/composite_analyzer.dart';

CompositeAnalysisResult _runComposite(Map<String, dynamic> args) {
  return CompositeAnalyzer.analyze(
    currentMatrix:           args['currentMatrix']  as List<List<double>>,
    oppositeMatrix:          args['oppositeMatrix'] as List<List<double>>,
    currentTemps:            args['currentTemps']   as Map<String, double>,
    oppositeTemps:           args['oppositeTemps']  as Map<String, double>,
    currentPressure:         args['currentPressure']  as List<List<double>>?,
    oppositePressure:        args['oppositePressure'] as List<List<double>>?,
    currentPressureRegions:  args['currentPressureRegions']  as Map<String, double>?,
    oppositePressureRegions: args['oppositePressureRegions'] as Map<String, double>?,
  );
}

class DFUAnalyzer {
  // Fallback thresholds used when no clinical profile is available (IWGDF Risk 0)
  static const double _defaultModerateThreshold = 2.0;

  static const List<String> regions = ['heel', 'forefoot', 'midfoot', 'toes'];
  static const int rows = 12;
  static const int cols = 26;

  /// Analyse [sessionId] for DFU risk.
  ///
  /// Pass [profile] to get risk-stratified thresholds. When null the analyzer
  /// falls back to the IWGDF Risk-0 defaults (moderateThreshold = 2.0°C,
  /// highThreshold = 3.96°C).
  static Future<DFUResult?> analyze(
    int sessionId,
    String foot, {
    ClinicalProfile? profile,
  }) async {
    // ── Derive thresholds from profile ────────────────────────────────────
    //
    // moderateThreshold = profile's ΔT alert threshold
    // highThreshold     = moderateThreshold + 2.16 (preserves the original
    //                     2.0 → 3.96 gap of 1.96, rounded to 2.16 for a
    //                     clean spread across risk levels)
    final double moderateThreshold =
        profile?.deltaThreshold ?? _defaultModerateThreshold;
    final double highThreshold = moderateThreshold + 1.96;

    debugPrint(
      'DFUAnalyzer: IWGDF risk=${profile?.iwgdfRisk ?? "no profile"} '
      'moderate=${moderateThreshold.toStringAsFixed(2)}°C '
      'high=${highThreshold.toStringAsFixed(2)}°C',
    );

    // ── Load sessions ─────────────────────────────────────────────────────
    final opposite =
        await DatabaseHelper.instance.getOppositeFootSession(sessionId, foot);
    if (opposite == null) return null;
    final int oppositeId = opposite['id'] as int;

    final List<List<double>> currentMatrix =
        await DatabaseHelper.instance.getMatrix(sessionId);
    final List<List<double>> oppositeMatrix =
        await DatabaseHelper.instance.getMatrix(oppositeId);

    // ── load clinical insights ──────────────────────
    final sessionRow = await DatabaseHelper.instance.getSessionById(sessionId);

    if (sessionRow == null) {
      return null;
    }

    final int patientId = sessionRow['patient_id'] != null 
    ? int.parse(sessionRow['patient_id'].toString()) 
    : 0;
    
    // Get Spatial Symmetry (Pixel-by-pixel Left vs Right)
    final SymmetryDetail symmetryScore = await DatabaseHelper.instance
        .calculateSymmetryDifference(sessionId);

    // Get Temporal Volatility (Current vs Previous for this specific foot)
    final double volatilityScore = await DatabaseHelper.instance
        .getVolatility(patientId, foot, int.parse(sessionId.toString()));

    debugPrint('DFUAnalyzer Insights - Symmetry: $symmetryScore, Volatility: $volatilityScore');

    // ── Landmark detection + alignment ───────────────────────────────────
    final _Landmark? cL = _getLandmarks(currentMatrix);
    final _Landmark? oL = _getLandmarks(oppositeMatrix);

    debugPrint(
      'Current landmarks: '
      'toe=(${cL?.toeCentroidC.toStringAsFixed(1)}, ${cL?.toeCentroidR.toStringAsFixed(1)}) '
      'heel=(${cL?.heelCentroidC.toStringAsFixed(1)}, ${cL?.heelCentroidR.toStringAsFixed(1)}) '
      'angle=${cL?.angle.toStringAsFixed(3)}',
    );
    debugPrint(
      'Opposite landmarks: '
      'toe=(${oL?.toeCentroidC.toStringAsFixed(1)}, ${oL?.toeCentroidR.toStringAsFixed(1)}) '
      'heel=(${oL?.heelCentroidC.toStringAsFixed(1)}, ${oL?.heelCentroidR.toStringAsFixed(1)}) '
      'angle=${oL?.angle.toStringAsFixed(3)}',
    );
    debugPrint(
      'Delta angle: ${((cL?.angle ?? 0) - (oL?.angle ?? 0)).toStringAsFixed(3)} rad  '
      'scale: ${((cL?.length ?? 1) / (oL?.length ?? 1)).toStringAsFixed(3)}',
    );

    final List<List<double>> alignedOpposite =
        (cL != null && oL != null)
            ? _alignMatrix(oppositeMatrix, oL, cL)
            : oppositeMatrix;

    // ── Region comparison ─────────────────────────────────────────────────
    final Map<String, double> currentTemps =
        _getRegionAvgTempsFromMatrix(currentMatrix);
    final Map<String, double> oppositeTemps =
        _getRegionAvgTempsFromMatrix(alignedOpposite);

    final List<RegionResult> results = [];
    RiskLevel overallRisk = RiskLevel.none;

    for (final region in regions) {
      final double currentTemp = currentTemps[region] ?? 0.0;
      final double oppositeTemp = oppositeTemps[region] ?? 0.0;
      if (currentTemp == 0.0 || oppositeTemp == 0.0) continue;

      final double deltaT = (currentTemp - oppositeTemp).abs();

      RiskLevel riskLevel;
      if (deltaT >= highThreshold) {
        riskLevel = RiskLevel.high;
        overallRisk = RiskLevel.high;
      } else if (deltaT >= moderateThreshold) {
        riskLevel = RiskLevel.moderate;
        if (overallRisk == RiskLevel.none) overallRisk = RiskLevel.moderate;
      } else {
        riskLevel = RiskLevel.none;
      }

      final hotspot =
          await DatabaseHelper.instance.getHotspot(sessionId, region);
      final String hotspotLocation =
          hotspot != null ? hotspot['anatomicalLabel'] as String : region;

      results.add(RegionResult(
        region: region,
        deltaT: deltaT,
        riskLevel: riskLevel,
        hotspotLocation: hotspotLocation,
        recommendation: _generateRecommendation(
          region,
          deltaT,
          riskLevel,
          hotspotLocation,
          moderateThreshold,
          profile?.iwgdfRisk,
        ),
        currentTemp: currentTemp,
        oppositeTemp: oppositeTemp,
      ));
    }

    final List<List<double>>? currentPressure =
    await DatabaseHelper.instance.getPressureMatrix(sessionId);
    final List<List<double>>? oppositePressure =
        await DatabaseHelper.instance.getPressureMatrix(oppositeId);

    // Compute pressure region averages
    Map<String, double>? currentPressureRegions;
    Map<String, double>? oppositePressureRegions;
    if (currentPressure != null) {
      currentPressureRegions =
          _getRegionAvgTempsFromMatrix(currentPressure);
    }
    if (oppositePressure != null) {
      oppositePressureRegions =
          _getRegionAvgTempsFromMatrix(oppositePressure);
    }

    // ── Run composite analysis ────────────────────────────────────────────
    final CompositeAnalysisResult composite = await compute(
      _runComposite,
      {
        'currentMatrix':          currentMatrix,
        'oppositeMatrix':         oppositeMatrix,
        'currentTemps':           currentTemps,
        'oppositeTemps':          oppositeTemps,
        'currentPressure':        currentPressure,
        'oppositePressure':       oppositePressure,
        'currentPressureRegions': currentPressureRegions,
        'oppositePressureRegions':oppositePressureRegions,
      },
    );

    // Take the higher risk between ΔT and composite
    final RiskLevel finalRisk = _maxRisk(overallRisk, composite.compositeRisk);


    return DFUResult(
      regions: results,
      overallRisk: finalRisk,
      comparedToSessionId: oppositeId,
      comparedToFoot: opposite['foot'] as String,
      comparedToTimestamp: opposite['timestamp'] as String,
      compositeAnalysis:   composite,
    );
  }

    static RiskLevel _maxRisk(RiskLevel a, RiskLevel b) {
    if (a == RiskLevel.high || b == RiskLevel.high) return RiskLevel.high;
    if (a == RiskLevel.moderate || b == RiskLevel.moderate) return RiskLevel.moderate;
    return RiskLevel.none;
  }

  // ─── Landmark Detection ───────────────────────────────────────────────────

  static _Landmark? _getLandmarks(List<List<double>> matrix) {
    int minCol = cols, maxCol = 0;
    bool hasActive = false;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (matrix[r][c] > 0) {
          if (c < minCol) minCol = c;
          if (c > maxCol) maxCol = c;
          hasActive = true;
        }
      }
    }
    if (!hasActive) return null;
    final int colRange = (maxCol - minCol).clamp(1, cols);

    double toeSumR = 0, toeSumC = 0, toeWeight = 0;
    double heelSumR = 0, heelSumC = 0, heelWeight = 0;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final double temp = matrix[r][c];
        if (temp <= 0) continue;
        final double colNorm = (c - minCol) / colRange;

        if (colNorm < 0.15) {
          toeSumR += r * temp;
          toeSumC += c * temp;
          toeWeight += temp;
        } else if (colNorm > 0.70) {
          heelSumR += r * temp;
          heelSumC += c * temp;
          heelWeight += temp;
        }
      }
    }

    if (toeWeight == 0 || heelWeight == 0) return null;

    final double toeCentroidR = toeSumR / toeWeight;
    final double toeCentroidC = toeSumC / toeWeight;
    final double heelCentroidR = heelSumR / heelWeight;
    final double heelCentroidC = heelSumC / heelWeight;

    final double angle = atan2(
      heelCentroidR - toeCentroidR,
      heelCentroidC - toeCentroidC,
    );
    final double length = sqrt(
      pow(heelCentroidC - toeCentroidC, 2) +
          pow(heelCentroidR - toeCentroidR, 2),
    );

    return _Landmark(
      toeCentroidC: toeCentroidC,
      toeCentroidR: toeCentroidR,
      heelCentroidC: heelCentroidC,
      heelCentroidR: heelCentroidR,
      angle: angle,
      length: length,
    );
  }

  // ─── Matrix Alignment ─────────────────────────────────────────────────────

  static List<List<double>> _alignMatrix(
    List<List<double>> source,
    _Landmark sourceLm,
    _Landmark targetLm,
  ) {
    final aligned = List.generate(rows, (_) => List<double>.filled(cols, 0.0));

    final double cosT = cos(targetLm.angle);
    final double sinT = sin(targetLm.angle);
    final double cosS = cos(sourceLm.angle);
    final double sinS = sin(sourceLm.angle);

    final double scale =
        (sourceLm.length > 0 && targetLm.length > 0)
            ? (sourceLm.length / targetLm.length)
            : 1.0;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        double dx = c - targetLm.toeCentroidC;
        double dr = r - targetLm.toeCentroidR;

        double tx = dx * cosT + dr * sinT;
        double ty = -dx * sinT + dr * cosT;

        tx *= scale;
        ty *= scale;

        double sx = tx * cosS - ty * sinS;
        double sy = tx * sinS + ty * cosS;

        double srcC = sx + sourceLm.toeCentroidC;
        double srcR = sy + sourceLm.toeCentroidR;

        aligned[r][c] = _bilinearSample(source, srcC, srcR);
      }
    }

    return aligned;
  }

  static double _bilinearSample(
      List<List<double>> matrix, double x, double y) {
    if (x < 0 || y < 0 || x >= cols - 1 || y >= rows - 1) return 0.0;

    final int x0 = x.floor().clamp(0, cols - 1);
    final int y0 = y.floor().clamp(0, rows - 1);
    final int x1 = (x0 + 1).clamp(0, cols - 1);
    final int y1 = (y0 + 1).clamp(0, rows - 1);

    final double fx = x - x0;
    final double fy = y - y0;

    final double v00 = matrix[y0][x0];
    final double v10 = matrix[y0][x1];
    final double v01 = matrix[y1][x0];
    final double v11 = matrix[y1][x1];

    return (v00 * (1 - fx) + v10 * fx) * (1 - fy) +
        (v01 * (1 - fx) + v11 * fx) * fy;
  }

  // ─── Region Avg Temps from Matrix ─────────────────────────────────────────

  static Map<String, double> _getRegionAvgTempsFromMatrix(
      List<List<double>> matrix) {
    int minCol = cols, maxCol = 0;
    bool hasActive = false;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (matrix[r][c] > 0) {
          if (c < minCol) minCol = c;
          if (c > maxCol) maxCol = c;
          hasActive = true;
        }
      }
    }
    if (!hasActive) return {};
    final int colRange = (maxCol - minCol).clamp(1, cols);

    final Map<String, double> sums = {
      'toes': 0, 'forefoot': 0, 'midfoot': 0, 'heel': 0,
    };
    final Map<String, int> counts = {
      'toes': 0, 'forefoot': 0, 'midfoot': 0, 'heel': 0,
    };

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final double temp = matrix[r][c];
        if (temp <= 0) continue;
        final double colNorm = (c - minCol) / colRange;

        final String region;
        if (colNorm < 0.15) {
          region = 'toes';
        } else if (colNorm < 0.40) {
          region = 'forefoot';
        } else if (colNorm < 0.70) {
          region = 'midfoot';
        } else {
          region = 'heel';
        }

        sums[region] = (sums[region] ?? 0) + temp;
        counts[region] = (counts[region] ?? 0) + 1;
      }
    }

    return {
      for (final region in regions)
        if ((counts[region] ?? 0) > 0)
          region: sums[region]! / counts[region]!,
    };
  }

  // ─── Recommendation ───────────────────────────────────────────────────────

  static String _generateRecommendation(
    String region,
    double deltaT,
    RiskLevel risk,
    String location,
    double moderateThreshold,
    int? iwgdfRisk,
  ) {
    final String regionName = region[0].toUpperCase() + region.substring(1);
    final String deltaTStr = deltaT.toStringAsFixed(1);
    final String thresholdStr = moderateThreshold.toStringAsFixed(1);

    switch (risk) {
      case RiskLevel.none:
        return '$regionName temperatures are symmetric. No concern detected.';

      case RiskLevel.moderate:
        final String riskNote = iwgdfRisk != null && iwgdfRisk >= 2
            ? ' Given elevated IWGDF Risk $iwgdfRisk, treat this with caution.'
            : '';
        return 'Moderate asymmetry of $deltaTStr°F detected at the $location '
            '(threshold: $thresholdStr°C).$riskNote '
            'Monitor this area closely over the next few days. '
            'Reduce pressure on this region if possible.';

      case RiskLevel.high:
        return 'Significant asymmetry of $deltaTStr°F detected at the $location. '
            'This exceeds the high-risk threshold for IWGDF Risk '
            '${iwgdfRisk ?? 0}. '
            'Monitor daily and consult a podiatrist or healthcare provider '
            'as soon as possible to rule out early-stage ulceration.';
    }
  }
}

// ─── Landmark Data Class ──────────────────────────────────────────────────────

class _Landmark {
  final double toeCentroidC;
  final double toeCentroidR;
  final double heelCentroidC;
  final double heelCentroidR;
  final double angle;
  final double length;

  const _Landmark({
    required this.toeCentroidC,
    required this.toeCentroidR,
    required this.heelCentroidC,
    required this.heelCentroidR,
    required this.angle,
    required this.length,
  });
}