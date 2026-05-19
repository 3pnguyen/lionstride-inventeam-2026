import 'package:flutter/material.dart';
import 'package:footbox/database/database_helper.dart';
import 'package:footbox/models/dfu_result.dart';
import 'package:footbox/services/dfu_analyzer.dart';
import 'package:footbox/widgets/dfu_result_widget.dart';
import 'package:footbox/database/patient_repository.dart';
import 'package:footbox/widgets/clinical_insights_widget.dart';

class PastScansScreen extends StatefulWidget {
  const PastScansScreen({super.key});

  @override
  State<PastScansScreen> createState() => _PastScansScreenState();
}

class _PastScansScreenState extends State<PastScansScreen> {
  List<Map<String, dynamic>> _sessions = [];
  int? _expandedSessionId;
  List<List<double>> _expandedMatrix = [];
  Map<String, Map<String, double>> _regionStats = {};
  Map<String, Map<String, double>> _pressureRegionStats = {};
  String _selectedRegion = 'all';
  bool _loadingMatrix = false;  // ← was missing
  int _minCol = 0, _maxCol = 25;
  DFUResult? _dfuResult;
  bool _analyzingDFU = false;
  bool _showPressure = false;
  List<List<double>> _expandedPressureMatrix = [];  

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final sessions = await DatabaseHelper.instance.getSessions();
    setState(() => _sessions = sessions);
  }

  String _formatTime(String isoString) {
    final time = DateTime.parse(isoString);
    final hour = time.hour > 12
        ? time.hour - 12
        : time.hour == 0
            ? 12
            : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '${time.month}/${time.day}/${time.year}  $hour:$minute $period';
  }

  Future<void> _toggleSession(Map<String, dynamic> session) async {
    final id = session['id'] as int;
    if (_expandedSessionId == id) {
      setState(() {
        _expandedSessionId = null;
        _expandedMatrix = [];
        _expandedPressureMatrix = [];
        _regionStats = {};
        _selectedRegion = 'all';
        _dfuResult = null;
        _analyzingDFU = false;
        _showPressure = false;
      });
      return;
    }

    setState(() => _loadingMatrix = true);

    final matrix = await DatabaseHelper.instance.getMatrix(id);
    final stats = await DatabaseHelper.instance.getAllRegionStats(id);
    final pressureMatrix = await DatabaseHelper.instance.getPressureMatrix(id);

    int minCol = 26, maxCol = 0;
    bool hasActive = false;
    for (int r = 0; r < matrix.length; r++) {
      for (int c = 0; c < matrix[r].length; c++) {
        if (matrix[r][c] > 0) {
          if (c < minCol) minCol = c;
          if (c > maxCol) maxCol = c;
          hasActive = true;
        }
      }
    }

    final pressureStats = pressureMatrix != null
      ? _computePressureRegionStats(pressureMatrix, minCol, maxCol)
      : <String, Map<String, double>>{};

    setState(() {
      _expandedSessionId = id;
      _expandedMatrix = matrix;
      _expandedPressureMatrix = pressureMatrix ?? [];
      _pressureRegionStats = pressureStats;
      _regionStats = stats;
      _selectedRegion = 'all';
      _loadingMatrix = false;
      _showPressure = false;
      _minCol = hasActive ? minCol : 0;
      _maxCol = hasActive ? maxCol : 25;
      _analyzingDFU = true;
    });

    // ✅ Single call only — passes current foot, analyzer finds opposite internally
    final profile = await PatientRepository().getEffectiveProfile(id);
    final result = await DFUAnalyzer.analyze(id, session['foot'] as String, profile: profile);
    setState(() {
      _dfuResult = result;
      _analyzingDFU = false;
    });
  }

  Color _regionColor(String region) {
    switch (region) {
      case 'heel': return Colors.purple;
      case 'forefoot': return Colors.blue;
      case 'midfoot': return Colors.orange;
      case 'toes': return Colors.pink;
      default: return Colors.green;
    }
  }

  Color _getHeatmapColor(double value, double min, double max, {bool dimmed = false}) {
    double normalized = (max - min) > 0 ? (value - min) / (max - min) : 0.0;
    Color base;
    if (normalized < 0.25) {
      base = Color.lerp(Colors.blue, Colors.cyan, normalized * 4)!;
    } else if (normalized < 0.5) {
      base = Color.lerp(Colors.cyan, Colors.green, (normalized - 0.25) * 4)!;
    } else if (normalized < 0.75) {
      base = Color.lerp(Colors.green, Colors.yellow, (normalized - 0.5) * 4)!;
    } else {
      base = Color.lerp(Colors.yellow, Colors.red, (normalized - 0.75) * 4)!;
    }
    return dimmed ? base.withValues(alpha: 0.2) : base;
  }

  Color _getPressureColor(double value, double min, double max, {bool dimmed = false}) {
    double normalized = (max - min) > 0 ? (value - min) / (max - min) : 0.0;
    Color base;
    if (normalized < 0.25) {
      base = Color.lerp(Colors.black, Colors.blue, normalized * 4)!;
    } else if (normalized < 0.5) {
      base = Color.lerp(Colors.blue, Colors.cyan, (normalized - 0.25) * 4)!;
    } else if (normalized < 0.75) {
      base = Color.lerp(Colors.cyan, Colors.yellow, (normalized - 0.5) * 4)!;
    } else {
      base = Color.lerp(Colors.yellow, Colors.red, (normalized - 0.75) * 4)!;
    }
    return dimmed ? base.withValues(alpha: 0.2) : base;
  }

  Map<String, Map<String, double>> _computePressureRegionStats(
    List<List<double>> matrix, int minCol, int maxCol) {
  final regions = ['toes', 'forefoot', 'midfoot', 'heel'];
  final Map<String, List<double>> buckets = {
    for (final r in regions) r: []
  };

  final int colRange = (maxCol - minCol).clamp(1, 26);

  for (int r = 0; r < matrix.length; r++) {
    for (int c = 0; c < matrix[r].length; c++) {
      final double v = matrix[r][c];
      if (v <= 0) continue;
      final double norm = (c - minCol) / colRange;
      final String region;
      if (norm < 0.15) {
        region = 'toes';
      } else if (norm < 0.40) {
        region = 'forefoot';
      } else if (norm < 0.70) {
        region = 'midfoot';
      } else {
        region = 'heel';
      }
      buckets[region]!.add(v);
    }
  }

  final Map<String, Map<String, double>> stats = {};
  for (final region in regions) {
    final vals = buckets[region]!;
    if (vals.isEmpty) continue;
    double sum = 0, min = double.infinity, max = double.negativeInfinity;
    for (final v in vals) {
      sum += v;
      if (v < min) min = v;
      if (v > max) max = v;
    }
    stats[region] = {
      'avg': sum / vals.length,
      'min': min,
      'max': max,
    };
  }
  return stats;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Past Scans',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Lexend'),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _sessions.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No scans yet.',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontFamily: 'Lexend')),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sessions.length,
              itemBuilder: (context, index) {
                final session = _sessions[index];
                final id = session['id'] as int;
                final isExpanded = _expandedSessionId == id;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      // Session header
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Text('$id',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Lexend')),
                        ),
                        title: Text(
                          'Session $id — ${session['foot']} Foot',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Lexend'),
                        ),
                        subtitle: Text(
                          _formatTime(session['timestamp']),
                          style: const TextStyle(fontFamily: 'Lexend'),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await DatabaseHelper.instance.deleteSession(id);
                                if (_expandedSessionId == id) {
                                  setState(() {
                                    _expandedSessionId = null;
                                    _expandedMatrix = [];
                                    _regionStats = {};
                                  });
                                }
                                _loadSessions();
                              },
                            ),
                            Icon(
                              isExpanded ? Icons.expand_less : Icons.expand_more,
                              color: Colors.green,
                            ),
                          ],
                        ),
                        onTap: () => _toggleSession(session),
                      ),

                      // Expanded content
                      if (isExpanded) ...[
                        const Divider(height: 1),
                        _loadingMatrix
                            ? const Padding(
                                padding: EdgeInsets.all(24),
                                child: CircularProgressIndicator(color: Colors.green),
                              )
                            : Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [

                                    // Region filter chips
                                    const Text('Filter by Region',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            fontFamily: 'Lexend')),
                                    const SizedBox(height: 8),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: ['all', 'toes', 'forefoot', 'midfoot', 'heel']
                                            .map((region) {
                                          final isSelected = _selectedRegion == region;
                                          return Padding(
                                            padding: const EdgeInsets.only(right: 8),
                                            child: ChoiceChip(
                                              label: Text(
                                                region[0].toUpperCase() + region.substring(1),
                                                style: const TextStyle(fontFamily: 'Lexend'),
                                              ),
                                              selected: isSelected,
                                              selectedColor: region == 'all'
                                                  ? Colors.green
                                                  : _regionColor(region),
                                              labelStyle: TextStyle(
                                                color: isSelected ? Colors.white : Colors.black,
                                                fontFamily: 'Lexend',
                                              ),
                                              onSelected: (_) =>
                                                  setState(() => _selectedRegion = region),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    // Region stats box
                                    if (_selectedRegion != 'all') ...[
                                      Builder(builder: (context) {
                                        final stats = _showPressure
                                            ? _pressureRegionStats
                                            : _regionStats;
                                        final unit = _showPressure ? 'kPa' : '°F';
                                        if (!stats.containsKey(_selectedRegion)) {
                                          return const SizedBox.shrink();
                                        }
                                        return Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: _regionColor(_selectedRegion).withValues(alpha: .1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                                color: _regionColor(_selectedRegion).withValues(alpha: .4)),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                                            children: [
                                              _statBox('AVG',
                                                  '${stats[_selectedRegion]!['avg']!.toStringAsFixed(1)}$unit',
                                                  _regionColor(_selectedRegion)),
                                              _statBox('MAX',
                                                  '${stats[_selectedRegion]!['max']!.toStringAsFixed(1)}$unit',
                                                  _regionColor(_selectedRegion)),
                                              _statBox('MIN',
                                                  '${stats[_selectedRegion]!['min']!.toStringAsFixed(1)}$unit',
                                                  _regionColor(_selectedRegion)),
                                            ],
                                          ),
                                        );
                                      }),
                                      const SizedBox(height: 12),
                                    ],

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
                                          onSelected: _expandedPressureMatrix.isNotEmpty
                                            ? (_) => setState(() => _showPressure = true)
                                            : null,
                                          // Only enable if pressure data exists
                                          disabledColor: Colors.grey.shade200,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Heatmap
                                    Builder(builder: (context) {
                                      final displayMatrix = _showPressure && _expandedPressureMatrix.isNotEmpty
                                          ? _expandedPressureMatrix
                                          : _expandedMatrix;

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
                                          AspectRatio(
                                            aspectRatio: 26 / 12,
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: CustomPaint(
                                                painter: _PastScanHeatmapPainter(
                                                  matrix: displayMatrix,
                                                  minValue: minVal,
                                                  maxValue: maxVal,
                                                  selectedRegion: _selectedRegion,
                                                  minCol: _minCol,
                                                  maxCol: _maxCol,
                                                  getColor: _showPressure && _expandedPressureMatrix.isNotEmpty
                                                      ? _getPressureColor
                                                      : _getHeatmapColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          // Legend
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  '${minVal.toStringAsFixed(1)} '
                                                  '${_showPressure ? 'kPa' : '°F'}',
                                                  style: const TextStyle(
                                                      fontFamily: 'Lexend',
                                                      fontSize: 11,
                                                      color: Colors.black54),
                                                ),
                                                Container(
                                                  width: 80, height: 12,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: _showPressure
                                                          ? [Colors.black, Colors.blue,
                                                            Colors.cyan, Colors.yellow, Colors.red]
                                                          : [Colors.blue, Colors.cyan,
                                                            Colors.green, Colors.yellow, Colors.red],
                                                    ),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                ),
                                                Text(
                                                  '${maxVal.toStringAsFixed(1)} '
                                                  '${_showPressure ? 'kPa' : '°F'}',
                                                  style: const TextStyle(
                                                      fontFamily: 'Lexend',
                                                      fontSize: 11,
                                                      color: Colors.black54),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                                    // DFU Analysis
                                    const Text(
                                      'DFU Risk Analysis',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        fontFamily: 'Lexend',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (_analyzingDFU)
                                      const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(12),
                                          child: CircularProgressIndicator(
                                            color: Colors.red,
                                          ),
                                        ),
                                      )
                                    else if (_dfuResult != null)
                                      const SizedBox(height: 16),
                                        ClinicalInsightsWidget(
                                          sessionId: id, 
                                          patientId: int.tryParse(session['patientId'].toString()),
                                          foot: session['foot'].toString(),
                                        ),
                                        const SizedBox(height: 16),
                                        if (_analyzingDFU) 
                                          const CircularProgressIndicator()
                                        else if (_dfuResult != null)
                                      DFUResultWidget(
                                        result: _dfuResult!,
                                        currentFoot: session['foot'] as String,
                                      )
                                    else
                                      const Text(
                                        'No opposite foot scan available for comparison.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'Lexend',
                                          color: Colors.black45,
                                        ),
                                      ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.bold, fontFamily: 'Lexend')),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Lexend')),
      ],
    );
  }
}

class _PastScanHeatmapPainter extends CustomPainter {
  final List<List<double>> matrix;
  final double minValue;
  final double maxValue;
  final String selectedRegion;
  final int minCol;
  final int maxCol;
  final Color Function(double value, double min, double max, {bool dimmed}) getColor;

  _PastScanHeatmapPainter({
    required this.matrix,
    required this.minValue,
    required this.maxValue,
    required this.selectedRegion,
    required this.minCol,
    required this.maxCol,
    required this.getColor,
  });

  bool _inRegion(int col) {
    if (selectedRegion == 'all') return true;
    final int range = (maxCol - minCol).clamp(1, 26);
    final double norm = (col - minCol) / range;
    switch (selectedRegion) {
      case 'toes': return norm < 0.15;
      case 'forefoot': return norm >= 0.15 && norm < 0.40;
      case 'midfoot': return norm >= 0.40 && norm < 0.70;
      case 'heel': return norm >= 0.70;
      default: return true;
    }
  }

  double _interpolate(double x, double y) {
    int x0 = x.floor().clamp(0, matrix[0].length - 1);
    int y0 = y.floor().clamp(0, matrix.length - 1);
    int x1 = (x0 + 1).clamp(0, matrix[0].length - 1);
    int y1 = (y0 + 1).clamp(0, matrix.length - 1);

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
        int col = mx.floor().clamp(0, cols - 1);
        bool inRegion = _inRegion(col);
        Color color = getColor(value, minValue, maxValue, dimmed: !inRegion);
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}