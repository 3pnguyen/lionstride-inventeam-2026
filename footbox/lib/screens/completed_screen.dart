import 'package:flutter/material.dart';
import 'package:footbox/screens/home_screen.dart';
import 'package:footbox/database/database_helper.dart';
import 'package:footbox/models/dfu_result.dart';
import 'package:footbox/services/dfu_analyzer.dart';
import 'package:footbox/widgets/dfu_result_widget.dart';
import 'package:footbox/widgets/clinical_insights_widget.dart';
import 'package:footbox/database/patient_repository.dart';

class CompletedScreen extends StatefulWidget {
  final String foot;
  final String scanData;
  final String pressureData;
  final int? patientId;

  const CompletedScreen({
    super.key,
    required this.foot,
    required this.scanData,
    this.pressureData = '',
    this.patientId,
  });

  // Retained as a utility in case you need to convert matrices back to strings elsewhere
  static String matrixToScanData(List<List<double>> matrix) {
    List<String> values = [];
    for (int col = 0; col < matrix[0].length; col++) {
      for (int row = 0; row < matrix.length; row++) {
        values.add(matrix[row][col].toStringAsFixed(1));
      }
    }
    return values.join(' ');
  }

  List<List<double>> _parseMatrixData() {
    // Strictly uses real data passed from the Bluetooth device
    List<String> values = scanData.trim().split(' ');

    int columnCount = 26;
    int rowCount = 12;

    List<List<double>> matrix = List.generate(
      rowCount,
      (_) => List.filled(columnCount, 0.0),
    );

    int index = 0;
    for (int col = 0; col < columnCount; col++) {
      for (int row = 0; row < rowCount; row++) {
        if (index < values.length && values[index].isNotEmpty) {
          double value = double.tryParse(values[index]) ?? 0.0;
          matrix[row][col] = value;
          index++;
        }
      }
    }
    return matrix;
  }

  List<List<double>> _parsePressureData() {
    // Strictly uses real data passed from the Bluetooth device
    List<String> values = pressureData.trim().split(' ');
    
    const int columnCount = 26;
    const int rowCount = 12;
    
    List<List<double>> matrix = List.generate(
      rowCount, (_) => List.filled(columnCount, 0.0));
      
    int index = 0;
    for (int col = 0; col < columnCount; col++) {
      for (int row = 0; row < rowCount; row++) {
        if (index < values.length && values[index].isNotEmpty) {
          matrix[row][col] = double.tryParse(values[index]) ?? 0.0;
          index++;
        }
      }
    }
    return matrix;
  }

  Color _getHeatmapColor(double value, double min, double max) {
    double normalized = (max - min) > 0 ? (value - min) / (max - min) : 0.0;
    if (normalized < 0.25) {
      return Color.lerp(Colors.blue, Colors.cyan, normalized * 4)!;
    } else if (normalized < 0.5) {
      return Color.lerp(Colors.cyan, Colors.green, (normalized - 0.25) * 4)!;
    } else if (normalized < 0.75) {
      return Color.lerp(Colors.green, Colors.yellow, (normalized - 0.5) * 4)!;
    } else {
      return Color.lerp(Colors.yellow, Colors.red, (normalized - 0.75) * 4)!;
    }
  }

  Color _getPressureColor(double value, double min, double max) {
    double normalized =
        (max - min) > 0 ? (value - min) / (max - min) : 0.0;
    if (normalized < 0.25) {
      return Color.lerp(Colors.black, Colors.blue, normalized * 4)!;
    } else if (normalized < 0.5) {
      return Color.lerp(
          Colors.blue, Colors.cyan, (normalized - 0.25) * 4)!;
    } else if (normalized < 0.75) {
      return Color.lerp(
          Colors.cyan, Colors.yellow, (normalized - 0.5) * 4)!;
    } else {
      return Color.lerp(
          Colors.yellow, Colors.red, (normalized - 0.75) * 4)!;
    }
  }

  @override
  State<CompletedScreen> createState() => _CompletedScreenState();
}

class _CompletedScreenState extends State<CompletedScreen> {
  bool _saved = false;
  int? _currentSessionId;
  DFUResult? _dfuResult;
  bool _analyzingDFU = false;
  bool _showPressure = false;

  @override
  void initState() {
    super.initState();
    _saveSession();
  }

  Future<void> _saveSession() async {
    final matrix = widget._parseMatrixData();
    final pressureMatrix = widget._parsePressureData();
    final sessionId = await DatabaseHelper.instance.insertSession(
      foot: widget.foot,
      matrix: matrix,
      pressureMatrix: pressureMatrix,
      patientId: widget.patientId,
    );
    setState(() {
      _saved = true;
      _currentSessionId = sessionId;
    });

    // Run DFU analysis after saving
    setState(() => _analyzingDFU = true);
    final profile = await PatientRepository().getEffectiveProfile(sessionId);
    final result = await DFUAnalyzer.analyze(sessionId, widget.foot, profile: profile);
    if (mounted) {
      setState(() {
        _dfuResult = result;
        _analyzingDFU = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final matrix = widget._parseMatrixData();

    double minValue = double.infinity;
    double maxValue = double.negativeInfinity;

    for (var row in matrix) {
      for (var value in row) {
        if (!value.isNaN && !value.isInfinite) {
          if (value < minValue) minValue = value;
          if (value > maxValue) maxValue = value;
        }
      }
    }

    if (minValue == maxValue) {
      minValue -= 1;
      maxValue += 1;
    }
    
    // Safety check just in case the data is entirely 0s and empty
    if (minValue == double.infinity) {
      minValue = 0;
      maxValue = 1;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          },
        ),
        title: Text(
          '${widget.foot} Foot Scan',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Lexend',
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Scan Complete!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                  fontFamily: 'Lexend',
                ),
              ),
              const SizedBox(height: 4),
              // Saved indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _saved ? Icons.check_circle : Icons.circle_outlined,
                    color: _saved ? Colors.green : Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _saved ? 'Saved to history' : 'Saving...',
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'Lexend',
                      color: _saved ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Range: ${minValue.toStringAsFixed(1)}°F - ${maxValue.toStringAsFixed(1)}°F',
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Lexend',
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),

              // Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('Thermal',
                        style: TextStyle(fontFamily: 'Lexend')),
                    selected: !_showPressure,
                    selectedColor: Colors.red.shade300,
                    onSelected: (_) => setState(() => _showPressure = false),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Pressure',
                        style: TextStyle(fontFamily: 'Lexend')),
                    selected: _showPressure,
                    selectedColor: Colors.blue.shade300,
                    onSelected: (_) => setState(() => _showPressure = true),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Heatmap
              Builder(builder: (context) {
                final displayMatrix = _showPressure
                    ? widget._parsePressureData()
                    : widget._parseMatrixData();

                double minVal = double.infinity;
                double maxVal = double.negativeInfinity;
                for (var row in displayMatrix) {
                  for (var v in row) {
                    if (v > 0) {
                      if (v < minVal) minVal = v;
                      if (v > maxVal) maxVal = v;
                    }
                  }
                }
                if (minVal == maxVal) { minVal -= 1; maxVal += 1; }
                if (minVal == double.infinity) { minVal = 0; maxVal = 1; }

                return Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AspectRatio(
                          aspectRatio: 26 / 12,
                          child: CustomPaint(
                            painter: InterpolatedHeatmapPainter(
                              matrix: displayMatrix,
                              minValue: minVal,
                              maxValue: maxVal,
                              getColor: _showPressure
                                  ? widget._getPressureColor
                                  : widget._getHeatmapColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildLegend(minVal, maxVal,
                        _showPressure ? 'kPa' : '°F',
                        _showPressure ? Colors.blue : Colors.red),
                  ],
                );
              }),

              const SizedBox(height: 20),

              if (_currentSessionId != null)
                ClinicalInsightsWidget(
                  sessionId: _currentSessionId!,
                  foot: widget.foot,
                ),

              const SizedBox(height: 20),

              // DFU Analysis Banner
              if (_analyzingDFU) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Running DFU analysis...',
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_dfuResult != null) ...[
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'DFU Risk Analysis',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lexend',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                DFUResultWidget(
                  result: _dfuResult!,
                  currentFoot: widget.foot,
                ),
              ] else if (!_analyzingDFU && _saved) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.black45),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No opposite foot scan found for comparison. '
                          'Scan the other foot to enable DFU analysis.',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Lexend',
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Statistics
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Scan Statistics',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lexend',
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard('Min Temp', '${minValue.toStringAsFixed(1)}°F', Colors.blue),
                        _buildStatCard('Max Temp', '${maxValue.toStringAsFixed(1)}°F', Colors.red),
                        _buildStatCard('Sensors', '312', Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontFamily: 'Lexend', color: Colors.black54)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lexend',
                color: color)),
      ],
    );
  }
}

Widget _buildLegend(double min, double max, String unit, Color endColor) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Text(
          unit == 'kPa' ? 'Pressure Scale' : 'Temperature Scale',
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Lexend',
              fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          height: 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: unit == 'kPa'
                  ? [Colors.black, Colors.blue, Colors.cyan,
                     Colors.yellow, Colors.red]
                  : [Colors.blue, Colors.cyan, Colors.green,
                     Colors.yellow, Colors.red],
            ),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${min.toStringAsFixed(1)} $unit',
                style: const TextStyle(
                    fontSize: 12, fontFamily: 'Lexend')),
            Text('${max.toStringAsFixed(1)} $unit',
                style: const TextStyle(
                    fontSize: 12, fontFamily: 'Lexend')),
          ],
        ),
      ],
    ),
  );
}

// Custom painter for smooth interpolated heatmap
class InterpolatedHeatmapPainter extends CustomPainter {
  final List<List<double>> matrix;
  final double minValue;
  final double maxValue;
  final Color Function(double value, double min, double max) getColor;

  InterpolatedHeatmapPainter({
    required this.matrix,
    required this.minValue,
    required this.maxValue,
    required this.getColor,
  });

  double _interpolate(double x, double y) {
    int x0 = x.floor();
    int y0 = y.floor();
    int x1 = (x0 + 1).clamp(0, matrix[0].length - 1);
    int y1 = (y0 + 1).clamp(0, matrix.length - 1);
    x0 = x0.clamp(0, matrix[0].length - 1);
    y0 = y0.clamp(0, matrix.length - 1);

    double fx = x - x0;
    double fy = y - y0;

    double v00 = matrix[y0][x0];
    double v10 = matrix[y0][x1];
    double v01 = matrix[y1][x0];
    double v11 = matrix[y1][x1];

    double v0 = v00 * (1 - fx) + v10 * fx;
    double v1 = v01 * (1 - fx) + v11 * fx;

    return v0 * (1 - fy) + v1 * fy;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const int upscaleFactor = 4;
    final int cols = matrix[0].length;
    final int rows = matrix.length;
    final int width = cols * upscaleFactor;
    final int height = rows * upscaleFactor;
    final pixelWidth = size.width / width;
    final pixelHeight = size.height / height;

    for (int px = 0; px < width; px++) {
      for (int py = 0; py < height; py++) {
        double mx = px / upscaleFactor;
        double my = py / upscaleFactor;
        double value = _interpolate(mx, my);
        Color color = getColor(value, minValue, maxValue);
        final paint = Paint()..color = color;
        canvas.drawRect(
          Rect.fromLTWH(
            px * pixelWidth,
            py * pixelHeight,
            pixelWidth + 0.5,
            pixelHeight + 0.5,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}