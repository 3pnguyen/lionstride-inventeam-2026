import 'package:footbox/models/dfu_result.dart';

class LBPAnalyzer {
  static const List<List<int>> _neighbours = [
    [-1, -1], [-1, 0], [-1, 1],
    [ 0,  1],
    [ 1,  1], [ 1, 0], [ 1, -1],
    [ 0, -1],
  ];

  static const int    _minBitsSet = 7;
  static const double _flagRatio  = 0.04;

  static AlgorithmSignal analyze(
    List<List<double>> thermalMatrix, {
    List<List<double>>? pressureMatrix,
  }) {
    final tResult = _analyzeMatrix(thermalMatrix);
    final pResult = pressureMatrix != null
        ? _analyzeMatrix(pressureMatrix)
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
          'Normal texture (${tResult['score'].toStringAsFixed(1)}% flagged)';
    }

    return AlgorithmSignal(
      name: 'LBP',
      flagged: flagged,
      score: score,
      detail: detail,
      modality: modality,
    );
  }

  static Map<String, dynamic> _analyzeMatrix(
      List<List<double>> matrix) {
    final int rows = matrix.length;
    final int cols = matrix[0].length;

    int flaggedPixels = 0;
    int activePixels  = 0;
    int peakCode      = 0;
    int peakR = 0, peakC = 0;
    int peakBits = 0;

    for (int r = 1; r < rows - 1; r++) {
      for (int c = 1; c < cols - 1; c++) {
        final double centre = matrix[r][c];
        if (centre <= 0) continue;

        bool allActive = true;
        for (final n in _neighbours) {
          if (matrix[r + n[0]][c + n[1]] <= 0) {
            allActive = false;
            break;
          }
        }
        if (!allActive) continue;
        activePixels++;

        int code    = 0;
        int bitsSet = 0;
        for (int i = 0; i < _neighbours.length; i++) {
          final int nr = r + _neighbours[i][0];
          final int nc = c + _neighbours[i][1];
          if (matrix[nr][nc] < centre) {
            code |= (1 << i);
            bitsSet++;
          }
        }

        if (bitsSet >= _minBitsSet) {
          flaggedPixels++;
          if (bitsSet > peakBits) {
            peakBits = bitsSet;
            peakCode = code;
            peakR    = r;
            peakC    = c;
          }
        }
      }
    }

    final double ratio   =
        activePixels > 0 ? flaggedPixels / activePixels : 0;
    final bool   flagged = ratio > _flagRatio;

    return {
      'flagged': flagged,
      'score':   double.parse((ratio * 100).toStringAsFixed(2)),
      'detail':  flagged
          ? 'Abnormal texture: ${(ratio * 100).toStringAsFixed(1)}% '
            'of pixels. Peak at R${peakR + 1}/C${peakC + 1} '
            '(code $peakCode)'
          : 'Normal (${(ratio * 100).toStringAsFixed(1)}% flagged)',
    };
  }
}