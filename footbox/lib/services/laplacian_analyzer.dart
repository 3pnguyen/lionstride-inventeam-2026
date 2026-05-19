import 'package:footbox/models/dfu_result.dart';

class LaplacianAnalyzer {
  static const double _flagThresholdThermal  = 3.5;
  static const double _flagThresholdPressure = 50.0;

  static AlgorithmSignal analyze(
    List<List<double>> thermalMatrix, {
    List<List<double>>? pressureMatrix,
  }) {
    final thermalSignal  = _analyzeMatrix(
        thermalMatrix, _flagThresholdThermal, '°F');
    final pressureSignal = pressureMatrix != null
        ? _analyzeMatrix(
            pressureMatrix, _flagThresholdPressure, 'kPa')
        : null;

    final bool tFlagged = thermalSignal['flagged'] as bool;
    final bool pFlagged =
        pressureSignal != null && pressureSignal['flagged'] as bool;

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
        ? thermalSignal['score'] as double
        : pFlagged
            ? pressureSignal['score'] as double
            : 0.0;

    String detail = '';
    if (tFlagged) detail += 'Thermal: ${thermalSignal['detail']}';
    if (pFlagged) {
      if (detail.isNotEmpty) detail += ' | ';
      detail += 'Pressure: ${pressureSignal['detail']}';
    }
    if (!flagged) {
      detail = 'No focal hotspot detected '
          '(T=${thermalSignal['score']})';
    }

    return AlgorithmSignal(
      name: 'Laplacian',
      flagged: flagged,
      score: score,
      detail: detail,
      modality: modality,
    );
  }

  static Map<String, dynamic> _analyzeMatrix(
    List<List<double>> matrix,
    double threshold,
    String unit,
  ) {
    final int rows = matrix.length;
    final int cols = matrix[0].length;

    int minR = rows, maxR = 0, minC = cols, maxC = 0;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (matrix[r][c] > 0) {
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

    double maxLap = 0.0;
    double totalLap = 0.0;
    int activeCount = 0;
    int peakR = 0, peakC = 0;

    for (int r = minR; r <= maxR; r++) {
      for (int c = minC; c <= maxC; c++) {
        final double v = matrix[r][c];
        if (v <= 0) continue;
        final double up    = matrix[r - 1][c];
        final double down  = matrix[r + 1][c];
        final double left  = matrix[r][c - 1];
        final double right = matrix[r][c + 1];
        if (up <= 0 || down <= 0 || left <= 0 || right <= 0) continue;
        final double lap =
            (up + down + left + right - 4 * v).abs();
        totalLap += lap;
        activeCount++;
        if (lap > maxLap) {
          maxLap = lap;
          peakR  = r;
          peakC  = c;
        }
      }
    }

    final double mean =
        activeCount > 0 ? totalLap / activeCount : 0.0;
    final bool flagged = maxLap > threshold;

    return {
      'flagged': flagged,
      'score':   double.parse(maxLap.toStringAsFixed(3)),
      'detail':  flagged
          ? 'Hotspot at R${peakR + 1}/C${peakC + 1} '
            '(${maxLap.toStringAsFixed(2)}$unit, '
            'mean ${mean.toStringAsFixed(2)}$unit)'
          : 'No spike (max ${maxLap.toStringAsFixed(2)}$unit)',
    };
  }
}