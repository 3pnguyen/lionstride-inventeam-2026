import 'package:footbox/models/dfu_result.dart';

class ZScoreAnalyzer {
  static const double _flagThreshold = 2.0;

  static AlgorithmSignal analyze(
    List<List<double>> currentThermal,
    List<List<double>> oppositeThermal, {
    List<List<double>>? currentPressure,
    List<List<double>>? oppositePressure,
  }) {
    final tResult = _analyzeMatrix(currentThermal, oppositeThermal);
    final pResult = (currentPressure != null && oppositePressure != null)
        ? _analyzeMatrix(currentPressure, oppositePressure)
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
    if (!flagged) detail = 'No asymmetry (peak Z=${tResult['score']})';

    return AlgorithmSignal(
      name: 'Z-Score',
      flagged: flagged,
      score: score,
      detail: detail,
      modality: modality,
    );
  }

  static Map<String, dynamic> _analyzeMatrix(
    List<List<double>> current,
    List<List<double>> opposite,
  ) {
    final int rows = current.length;
    final int cols = current[0].length;

    int minR = rows, maxR = 0, minC = cols, maxC = 0;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (current[r][c] > 0) {
          if (r < minR) minR = r;
          if (r > maxR) maxR = r;
          if (c < minC) minC = c;
          if (c > maxC) maxC = c;
        }
      }
    }
    minR = (minR + 2).clamp(0, rows - 1);
    maxR = (maxR - 2).clamp(0, rows - 1);
    minC = (minC + 2).clamp(0, cols - 1);
    maxC = (maxC - 2).clamp(0, cols - 1);

    final List<double> diffs = [];
    for (int r = minR; r <= maxR; r++) {
      for (int c = minC; c <= maxC; c++) {
        if (current[r][c] > 0 && opposite[r][c] > 0) {
          diffs.add((current[r][c] - opposite[r][c]).abs());
        }
      }
    }

    if (diffs.isEmpty) {
      return {'flagged': false, 'score': 0.0,
              'detail': 'Insufficient data'};
    }

    final double mean =
        diffs.reduce((a, b) => a + b) / diffs.length;
    final double variance = diffs
            .map((d) => (d - mean) * (d - mean))
            .reduce((a, b) => a + b) /
        diffs.length;
    final double std = variance > 0 ? _sqrt(variance) : 1.0;

    double maxZ = 0.0;
    int peakR = 0, peakC = 0;
    int flaggedPixels = 0;

    for (int r = minR; r <= maxR; r++) {
      for (int c = minC; c <= maxC; c++) {
        if (current[r][c] <= 0 || opposite[r][c] <= 0) continue;
        final double diff =
            (current[r][c] - opposite[r][c]).abs();
        final double z = (diff - mean) / std;
        if (z > _flagThreshold) flaggedPixels++;
        if (z > maxZ) {
          maxZ  = z;
          peakR = r;
          peakC = c;
        }
      }
    }

    final bool flagged = maxZ > _flagThreshold;
    return {
      'flagged': flagged,
      'score':   double.parse(maxZ.toStringAsFixed(3)),
      'detail':  flagged
          ? 'Peak Z=${maxZ.toStringAsFixed(2)} at '
            'R${peakR + 1}/C${peakC + 1} '
            '($flaggedPixels pixels above threshold)'
          : 'No asymmetry (peak Z=${maxZ.toStringAsFixed(2)})',
    };
  }

  static double _sqrt(double x) {
    if (x <= 0) return 0;
    double z = x / 2;
    for (int i = 0; i < 50; i++) {
      z -= (z * z - x) / (2 * z);
    }
    return z;
  }
}