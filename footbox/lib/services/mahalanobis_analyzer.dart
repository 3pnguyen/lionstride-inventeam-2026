import 'dart:math';
import 'package:footbox/models/dfu_result.dart';
import 'package:flutter/material.dart';

class MahalanobisAnalyzer {
  static const double _flagThreshold = 2.5;
  static const List<String> _regions =
      ['toes', 'forefoot', 'midfoot', 'heel'];

  static AlgorithmSignal analyze(
    Map<String, double> currentTemps,
    Map<String, double> oppositeTemps, {
    Map<String, double>? currentPressure,
    Map<String, double>? oppositePressure,
  }) {
    final tResult = _analyzeRegions(currentTemps, oppositeTemps);
    final pResult = (currentPressure != null && oppositePressure != null)
        ? _analyzeRegions(currentPressure, oppositePressure, sd: 30.0)
        : null;

    final bool tFlagged = tResult['flagged'] as bool;
    final bool pFlagged =
        pResult != null && pResult['flagged'] as bool;

    final AnalysisModality modality;
    if (tFlagged && pFlagged) {
      modality = AnalysisModality.both;
    } else if (tFlagged) {
      modality = AnalysisModality.temperature;
    } else if (pFlagged) {
      modality = AnalysisModality.pressure;
    } else {
      modality = AnalysisModality.none;
    }

    final bool flagged = tFlagged || pFlagged;
    final double score = tFlagged
        ? tResult['score'] as double
        : pFlagged
            ? pResult['score'] as double
            : 0.0;

    String detail = '';
    if (tFlagged) detail += 'Thermal: ${tResult['detail']}';
    if (pFlagged) {
      if (detail.isNotEmpty) detail += ' | ';
      detail += 'Pressure: ${pResult['detail']}';
    }
    if (!flagged) {
      detail =
          'Normal range (D=${tResult['score'].toStringAsFixed(2)})';
    }

    return AlgorithmSignal(
      name: 'Mahalanobis',
      flagged: flagged,
      score: score,
      detail: detail,
      modality: modality,
    );
  }

  static Map<String, dynamic> _analyzeRegions(
    Map<String, double> current,
    Map<String, double> opposite, {
    double sd = 1.5,
  }) {
    final List<double> x  = [];
    final List<double> mu = [];

    for (final region in _regions) {
      final double c = current[region]  ?? 0.0;
      final double o = opposite[region] ?? 0.0;
      if (c == 0.0 || o == 0.0) continue;
      x.add(c);
      mu.add(o);
    }

    if (x.length < 2) {
      return {'flagged': false, 'score': 0.0,
              'detail': 'Insufficient data'};
    }

    final int n = x.length;
    final List<double> diff =
        List.generate(n, (i) => x[i] - mu[i]);

    double dSquared = 0.0;
    for (int i = 0; i < n; i++) {
      // Fixed variance: SD = 1.5 units (°F or kPa depending on input)
      dSquared += (diff[i] * diff[i]) / (sd * sd);
    }

    final double distance = sqrt(dSquared);
    final bool   flagged  = distance > _flagThreshold;

    int peakIdx = 0;
    double peakAbs = 0.0;
    for (int i = 0; i < n; i++) {
      if (diff[i].abs() > peakAbs) {
        peakAbs = diff[i].abs();
        peakIdx = i;
      }
    }

    debugPrint('Mahalanobis _analyzeRegions: d=${distance.toStringAsFixed(3)} sd=$sd');

    return {
      'flagged': flagged,
      'score':   double.parse(distance.toStringAsFixed(3)),
      'detail':  flagged
          ? 'Anomaly D=${distance.toStringAsFixed(2)}, '
            'peak: ${_regions[peakIdx]} '
            '(Δ${diff[peakIdx].toStringAsFixed(1)})'
          : 'Normal (D=${distance.toStringAsFixed(2)})',
    };
  }
}