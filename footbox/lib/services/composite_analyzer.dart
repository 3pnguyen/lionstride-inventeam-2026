import 'package:footbox/models/dfu_result.dart';
import 'package:flutter/foundation.dart';
import 'laplacian_analyzer.dart';
import 'zscore_analyzer.dart';
import 'lbp_analyzer.dart';
import 'mahalanobis_analyzer.dart';

class CompositeAnalyzer {
  static CompositeAnalysisResult analyze({
    required List<List<double>> currentMatrix,
    required List<List<double>> oppositeMatrix,
    required Map<String, double> currentTemps,
    required Map<String, double> oppositeTemps,
    List<List<double>>? currentPressure,
    List<List<double>>? oppositePressure,
    Map<String, double>? currentPressureRegions,
    Map<String, double>? oppositePressureRegions,
  }) {
    final signals = <AlgorithmSignal>[
      LaplacianAnalyzer.analyze(
        currentMatrix,
        pressureMatrix: currentPressure,
      ),
      ZScoreAnalyzer.analyze(
        currentMatrix,
        oppositeMatrix,
        currentPressure: currentPressure,
        oppositePressure: oppositePressure,
      ),
      LBPAnalyzer.analyze(
        currentMatrix,
        pressureMatrix: currentPressure,
      ),
      MahalanobisAnalyzer.analyze(
        currentTemps,
        oppositeTemps,
        currentPressure: currentPressureRegions,
        oppositePressure: oppositePressureRegions,
      ),
    ];

    for (final signal in signals) {
      debugPrint(
        '[${signal.name}] flagged=${signal.flagged} '
        'modality=${signal.modality.name} '
        'score=${signal.score} — ${signal.detail}',
      );
    }

    final int flagCount =
        signals.where((s) => s.flagged).length;
    final double confidence = flagCount / signals.length;

    final RiskLevel compositeRisk;
    if (flagCount >= 3) {
      compositeRisk = RiskLevel.high;
    } else if (flagCount >= 2) {
      compositeRisk = RiskLevel.moderate;
    } else {
      compositeRisk = RiskLevel.none;
    }

    // Build modality summary
    final tempFlags = signals
        .where((s) => s.flagged &&
            (s.modality == AnalysisModality.temperature ||
             s.modality == AnalysisModality.both))
        .length;
    final pressFlags = signals
        .where((s) => s.flagged &&
            (s.modality == AnalysisModality.pressure ||
             s.modality == AnalysisModality.both))
        .length;

    String modalitySummary = '';
    if (tempFlags > 0 && pressFlags > 0) {
      modalitySummary =
          ' ($tempFlags thermal, $pressFlags pressure)';
    } else if (tempFlags > 0) {
      modalitySummary = ' (thermal)';
    } else if (pressFlags > 0) {
      modalitySummary = ' (pressure)';
    }

    final String summary;
    if (flagCount == 0) {
      summary =
          'All four algorithms agree: no anomaly detected.';
    } else if (flagCount == 1) {
      final name = signals.firstWhere((s) => s.flagged).name;
      summary = '$name detected a potential anomaly$modalitySummary. '
          'Monitor closely.';
    } else if (flagCount == 2) {
      final names =
          signals.where((s) => s.flagged).map((s) => s.name);
      summary = '${names.join(' and ')} flagged$modalitySummary. '
          'Moderate confidence — consider clinical review.';
    } else if (flagCount == 3) {
      final names =
          signals.where((s) => s.flagged).map((s) => s.name);
      summary =
          '${names.join(', ')} flagged$modalitySummary. '
          'High confidence — clinical review recommended.';
    } else {
      summary =
          'All four algorithms flagged$modalitySummary. '
          'Very high confidence — seek clinical attention.';
    }

    debugPrint(
      '[Composite] flagCount=$flagCount '
      'confidence=${(confidence * 100).toStringAsFixed(0)}% '
      'risk=$compositeRisk',
    );

    return CompositeAnalysisResult(
      signals: signals,
      flagCount: flagCount,
      confidence: confidence,
      compositeRisk: compositeRisk,
      summary: summary,
    );
  }
}

