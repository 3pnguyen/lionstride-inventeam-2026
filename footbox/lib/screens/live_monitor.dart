import 'dart:async';
import 'package:flutter/material.dart';
import '../bluetooth/bluetooth_manager.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Threshold and Configuration Constants
// ─────────────────────────────────────────────────────────────────────────────
const double _kTempAlertDeltaF = 2.2;    
const double _kPressureAlertRatio = 0.75; 

class LiveMonitorScreen extends StatefulWidget {
  const LiveMonitorScreen({super.key});

  @override
  State<LiveMonitorScreen> createState() => _LiveMonitorScreenState();
}

class _LiveMonitorScreenState extends State<LiveMonitorScreen>
    with SingleTickerProviderStateMixin {
  static const int _rows = 12;
  static const int _cols = 26;

  List<List<double>> _tempMatrix =
      List.generate(_rows, (_) => List.filled(_cols, 0.0));
  List<List<double>> _pressMatrix =
      List.generate(_rows, (_) => List.filled(_cols, 0.0));

  bool _hasData = false;
  DateTime? _lastUpdate;

  bool _cycleInProgress = false;
  int _activePollingTab = 0; 

  // Millisecond-based state tracking
  int _currentIntervalMs = 1000; // Default to 1000ms (1 second)
  late TabController _tabController;
  Timer? _pollTimer;
  Timer? _uiRefreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);

    BluetoothManager.updateCallback(_onBtData);

    _restartPollTimer();

    _uiRefreshTimer = Timer.periodic(
      const Duration(milliseconds: 75),
      (_) { if (mounted) setState(() {}); },
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _uiRefreshTimer?.cancel();
    BluetoothManager.updateCallback(null);
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  // Uses clean integer millisecond durations
  void _restartPollTimer() {
    _pollTimer?.cancel();
    _startPollCycle(); 
    _pollTimer = Timer.periodic(
      Duration(milliseconds: _currentIntervalMs),
      (_) => _startPollCycle(),
    );
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return; 
    _startPollCycle();
  }

  Future<void> _startPollCycle() async {
    if (_cycleInProgress) return; 
    if (BluetoothManager.connection == null ||
        !BluetoothManager.connection!.isConnected) {
      return;
    }

    _cycleInProgress = true;
    _activePollingTab = _tabController.index; 

    if (_activePollingTab == 0) {
      await BluetoothManager.sendCommand('scan temperature');
    } else {
      await BluetoothManager.sendCommand('scan pressure');
    }
  }

  void _onBtData(String raw) {
    if (!mounted) return;
    final trimmed = raw.trim();
    final matrix = _parseMatrix(trimmed);

    if (matrix != null) {
      setState(() {
        if (_activePollingTab == 0) {
          _tempMatrix = matrix;
        } else {
          _pressMatrix = matrix;
        }
        _hasData = true;
        _lastUpdate = DateTime.now();
      });
    }
    _cycleInProgress = false;
  }

  List<List<double>>? _parseMatrix(String raw) {
    final values = raw.split(' ')
        .map((s) => double.tryParse(s) ?? 0.0)
        .toList();
    if (values.length < _rows * _cols) return null;

    final matrix = List.generate(_rows, (_) => List.filled(_cols, 0.0));
    int idx = 0;
    for (int col = 0; col < _cols; col++) {
      for (int row = 0; row < _rows; row++) {
        matrix[row][col] = values[idx++];
      }
    }
    return matrix;
  }

  ({double min, double max, double mean}) _stats(List<List<double>> m) {
    double mn = double.infinity, mx = double.negativeInfinity, sum = 0;
    int n = 0;
    for (final row in m) {
      for (final v in row) {
        if (v.isFinite) {
          if (v < mn) mn = v;
          if (v > mx) mx = v;
          sum += v;
          n++;
        }
      }
    }
    if (mn == double.infinity) { mn = 0; mx = 1; }
    if (mn == mx) { mn -= 1; mx += 1; }
    return (min: mn, max: mx, mean: n > 0 ? sum / n : 0);
  }

  List<Rect> _alertRects(List<List<double>> m, bool isTemp) {
    final s = _stats(m);
    final threshold = isTemp
        ? s.mean + _kTempAlertDeltaF
        : s.min + (s.max - s.min) * _kPressureAlertRatio;

    final flagged = List.generate(
        _rows, (r) => List.generate(_cols, (c) => m[r][c] >= threshold));
    final visited = List.generate(_rows, (_) => List.filled(_cols, false));
    final rects = <Rect>[];

    for (int r = 0; r < _rows; r++) {
      for (int c = 0; c < _cols; c++) {
        if (flagged[r][c] && !visited[r][c]) {
          int minR = r, maxR = r, minC = c, maxC = c;
          final queue = <(int, int)>[(r, c)];
          visited[r][c] = true;
          while (queue.isNotEmpty) {
            final (cr, cc) = queue.removeAt(0);
            if (cr < minR) minR = cr;
            if (cr > maxR) maxR = cr;
            if (cc < minC) minC = cc;
            if (cc > maxC) maxC = cc;
            for (final (nr, nc) in [
              (cr - 1, cc), (cr + 1, cc), (cr, cc - 1), (cr, cc + 1)
            ]) {
              if (nr >= 0 && nr < _rows && nc >= 0 && nc < _cols &&
                  flagged[nr][nc] && !visited[nr][nc]) {
                visited[nr][nc] = true;
                queue.add((nr, nc));
              }
            }
          }
          rects.add(Rect.fromLTRB(
              minC.toDouble(), minR.toDouble(),
              (maxC + 1).toDouble(), (maxR + 1).toDouble()));
        }
      }
    }
    return rects;
  }

  bool get _btConnected =>
      BluetoothManager.connection != null &&
      BluetoothManager.connection!.isConnected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Live Monitor',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Lexend'),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 254, 5, 0),
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72.0),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color.fromARGB(255, 254, 5, 0),
              labelColor: const Color.fromARGB(255, 254, 5, 0),
              unselectedLabelColor: Colors.black54,
              labelStyle: const TextStyle(
                fontFamily: 'Lexend',
                fontWeight: FontWeight.bold,
              ),
              tabs: const [
                Tab(icon: Icon(Icons.thermostat_outlined), text: 'Temperature'),
                Tab(icon: Icon(Icons.compress_outlined), text: 'Pressure'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _StatusBar(
            connected: _btConnected,
            hasData: _hasData,
            lastUpdate: _lastUpdate,
            cycleInProgress: _cycleInProgress,
          ),
          
          // Updated Millisecond Interval Slider Panel
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.speed, color: Colors.black54, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Poll Rate:',
                  style: TextStyle(fontFamily: 'Lexend', fontSize: 13, fontWeight: FontWeight.w500),
                ),
                Expanded(
                  child: Slider(
                    value: _currentIntervalMs.toDouble(),
                    min: 0.0,
                    max: 1000.0,
                    divisions: 100, // 10ms increments
                    activeColor: const Color.fromARGB(255, 254, 5, 0),
                    inactiveColor: Colors.grey.shade300,
                    label: '${_currentIntervalMs}ms',
                    onChanged: (newValue) {
                      setState(() {
                        _currentIntervalMs = newValue.toInt();
                      });
                    },
                    onChangeEnd: (newValue) {
                      _restartPollTimer();
                    },
                  ),
                ),
                Text(
                  '${_currentIntervalMs}ms',
                  style: const TextStyle(fontFamily: 'Lexend', fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _HeatmapPanel(
                  matrix: _tempMatrix,
                  hasData: _hasData,
                  isTemp: true,
                  alertRects: _hasData ? _alertRects(_tempMatrix, true) : [],
                ),
                _HeatmapPanel(
                  matrix: _pressMatrix,
                  hasData: _hasData,
                  isTemp: false,
                  alertRects: _hasData ? _alertRects(_pressMatrix, false) : [],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-Widgets
// ─────────────────────────────────────────────────────────────────────────────
class _StatusBar extends StatelessWidget {
  final bool connected;
  final bool hasData;
  final DateTime? lastUpdate;
  final bool cycleInProgress;

  const _StatusBar({
    required this.connected,
    required this.hasData,
    required this.lastUpdate,
    required this.cycleInProgress,
  });

  @override
  Widget build(BuildContext context) {
    final String updateText = lastUpdate == null
        ? 'No data yet'
        : 'Updated ${_elapsed(lastUpdate!)}';

    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            connected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
            size: 16,
            color: connected ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 6),
          Text(
            connected ? 'FootBox connected' : 'Not connected',
            style: TextStyle(
                fontFamily: 'Lexend',
                fontSize: 12,
                color: connected ? Colors.green : Colors.red),
          ),
          const Spacer(),
          if (cycleInProgress) ...[
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 254, 5, 0))),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            updateText,
            style: const TextStyle(
                fontFamily: 'Lexend', fontSize: 12, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  String _elapsed(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 5) return 'just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    return '${diff.inMinutes}m ago';
  }
}

class _HeatmapPanel extends StatelessWidget {
  final List<List<double>> matrix;
  final bool hasData;
  final bool isTemp;
  final List<Rect> alertRects;

  const _HeatmapPanel({
    required this.matrix,
    required this.hasData,
    required this.isTemp,
    required this.alertRects,
  });

  ({double min, double max}) _minMax() {
    double mn = double.infinity, mx = double.negativeInfinity;
    for (final row in matrix) {
      for (final v in row) {
        if (v.isFinite) {
          if (v < mn) mn = v;
          if (v > mx) mx = v;
        }
      }
    }
    if (mn == double.infinity) { mn = 0; mx = 1; }
    if (mn == mx) { mn -= 1; mx += 1; }
    return (min: mn, max: mx);
  }

  @override
  Widget build(BuildContext context) {
    final s = _minMax();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (hasData && alertRects.isNotEmpty)
            _AlertBanner(count: alertRects.length, isTemp: isTemp),

          const SizedBox(height: 12),

          hasData
              ? AspectRatio(
                  aspectRatio: 26 / 12,
                  child: CustomPaint(
                    painter: _LiveHeatmapPainter(
                      matrix: matrix,
                      minValue: s.min,
                      maxValue: s.max,
                      isTemp: isTemp,
                      alertRects: alertRects,
                    ),
                  ),
                )
              : _PlaceholderGrid(isTemp: isTemp),

          const SizedBox(height: 16),
          _Legend(min: s.min, max: s.max, isTemp: isTemp),

          if (hasData) ...[
            const SizedBox(height: 16),
            _StatsRow(matrix: matrix, isTemp: isTemp),
          ],
        ],
      ),
    );
  }
}

class _PlaceholderGrid extends StatelessWidget {
  final bool isTemp;
  const _PlaceholderGrid({required this.isTemp});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 26 / 12,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isTemp ? Icons.thermostat_outlined : Icons.compress_outlined,
                size: 36,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              Text(
                'Waiting for live data…',
                style: TextStyle(
                    fontFamily: 'Lexend',
                    fontSize: 13,
                    color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final int count;
  final bool isTemp;
  const _AlertBanner({required this.count, required this.isTemp});

  @override
  Widget build(BuildContext context) {
    final msg = isTemp
        ? '$count zone${count > 1 ? 's' : ''} with ≥2.2°F temperature elevation — possible DFU risk'
        : '$count high-pressure zone${count > 1 ? 's' : ''} detected — possible DFU risk';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 12,
                  color: Colors.orange.shade800),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final List<List<double>> matrix;
  final bool isTemp;
  const _StatsRow({required this.matrix, required this.isTemp});

  @override
  Widget build(BuildContext context) {
    double sum = 0, mn = double.infinity, mx = double.negativeInfinity;
    int n = 0;
    for (final row in matrix) {
      for (final v in row) {
        if (v.isFinite) {
          sum += v;
          n++;
          if (v < mn) mn = v;
          if (v > mx) mx = v;
        }
      }
    }
    final mean = n > 0 ? sum / n : 0.0;
    final unit = isTemp ? '°F' : 'kPa';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _Stat('Min', '${mn.toStringAsFixed(1)}$unit', Colors.blue),
        _Stat('Avg', '${mean.toStringAsFixed(1)}$unit', Colors.green),
        _Stat('Max', '${mx.toStringAsFixed(1)}$unit', Colors.red),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, fontFamily: 'Lexend', color: Colors.black45)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lexend',
                color: color)),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final double min;
  final double max;
  final bool isTemp;
  const _Legend({required this.min, required this.max, required this.isTemp});

  @override
  Widget build(BuildContext context) {
    final colors = isTemp
        ? [Colors.blue, Colors.cyan, Colors.green, Colors.yellow, Colors.red]
        : [Colors.black, Colors.blue, Colors.cyan, Colors.yellow, Colors.red];
    final unit = isTemp ? '°F' : 'kPa';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(
            isTemp ? 'Temperature Scale' : 'Pressure Scale',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontFamily: 'Lexend', fontSize: 13),
          ),
          const SizedBox(height: 8),
          Container(
            height: 20,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${min.toStringAsFixed(1)} $unit',
                  style: const TextStyle(fontSize: 11, fontFamily: 'Lexend')),
              Text('${max.toStringAsFixed(1)} $unit',
                  style: const TextStyle(fontSize: 11, fontFamily: 'Lexend')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.orange, width: 2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'DFU concern zone',
                style: TextStyle(
                    fontFamily: 'Lexend', fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rendering Canvas Pipeline
// ─────────────────────────────────────────────────────────────────────────────
class _LiveHeatmapPainter extends CustomPainter {
  final List<List<double>> matrix;
  final double minValue;
  final double maxValue;
  final bool isTemp;
  final List<Rect> alertRects;

  _LiveHeatmapPainter({
    required this.matrix,
    required this.minValue,
    required this.maxValue,
    required this.isTemp,
    required this.alertRects,
  });

  Color _color(double v) {
    final t = (maxValue - minValue) > 0
        ? ((v - minValue) / (maxValue - minValue)).clamp(0.0, 1.0)
        : 0.0;
    if (isTemp) {
      if (t < 0.25) return Color.lerp(Colors.blue, Colors.cyan, t * 4)!;
      if (t < 0.5) return Color.lerp(Colors.cyan, Colors.green, (t - 0.25) * 4)!;
      if (t < 0.75) return Color.lerp(Colors.green, Colors.yellow, (t - 0.5) * 4)!;
      return Color.lerp(Colors.yellow, Colors.red, (t - 0.75) * 4)!;
    } else {
      if (t < 0.25) return Color.lerp(Colors.black, Colors.blue, t * 4)!;
      if (t < 0.5) return Color.lerp(Colors.blue, Colors.cyan, (t - 0.25) * 4)!;
      if (t < 0.75) return Color.lerp(Colors.cyan, Colors.yellow, (t - 0.5) * 4)!;
      return Color.lerp(Colors.yellow, Colors.red, (t - 0.75) * 4)!;
    }
  }

  double _interpolate(double x, double y) {
    final cols = matrix[0].length;
    final rows = matrix.length;
    int x0 = x.floor().clamp(0, cols - 1);
    int y0 = y.floor().clamp(0, rows - 1);
    int x1 = (x0 + 1).clamp(0, cols - 1);
    int y1 = (y0 + 1).clamp(0, rows - 1);
    final fx = x - x0;
    final fy = y - y0;
    final v00 = matrix[y0][x0];
    final v10 = matrix[y0][x1];
    final v01 = matrix[y1][x0];
    final v11 = matrix[y1][x1];
    return (v00 * (1 - fx) + v10 * fx) * (1 - fy) +
        (v01 * (1 - fx) + v11 * fx) * fy;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const upscale = 4;
    final cols = matrix[0].length;
    final rows = matrix.length;
    final pw = size.width / (cols * upscale);
    final ph = size.height / (rows * upscale);

    for (int px = 0; px < cols * upscale; px++) {
      for (int py = 0; py < rows * upscale; py++) {
        final v = _interpolate(px / upscale, py / upscale);
        canvas.drawRect(
          Rect.fromLTWH(px * pw, py * ph, pw + 0.5, ph + 0.5),
          Paint()..color = _color(v),
        );
      }
    }

    final cellW = size.width / cols;
    final cellH = size.height / rows;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5;

    final boxPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (final r in alertRects) {
      final screenRect = Rect.fromLTRB(
        r.left * cellW,
        r.top * cellH,
        r.right * cellW,
        r.bottom * cellH,
      );
      canvas.drawRRect(
          RRect.fromRectAndRadius(screenRect, const Radius.circular(3)),
          shadowPaint);
      canvas.drawRRect(
          RRect.fromRectAndRadius(screenRect, const Radius.circular(3)),
          boxPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: '⚠',
          style: TextStyle(
            fontSize: cellH * 0.9,
            color: Colors.orange,
            shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(screenRect.left + 2, screenRect.top + 1));
    }
  }

  @override
  bool shouldRepaint(covariant _LiveHeatmapPainter old) =>
      old.matrix != matrix ||
      old.minValue != minValue ||
      old.maxValue != maxValue;
}