import 'dart:async';
import 'package:flutter/material.dart';
import 'completed_screen.dart';
import 'scan_failed.dart';
import '../bluetooth/bluetooth_manager.dart';

class Countdown extends StatefulWidget {
  final String foot;
  final int? patientId;
  const Countdown({super.key, required this.foot, this.patientId});

  @override
  State<Countdown> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<Countdown> {
  int _seconds = 3;
  Timer? _timer;

  // Holds the raw string responses from the ESP32
  String _tempData = '';
  String _pressureData = '';

  // Which response we're currently waiting for
  bool _waitingForPressure = false;

  bool get _dataReceived => _tempData.isNotEmpty && _pressureData.isNotEmpty;

  @override
  void initState() {
    super.initState();

    // Register our data callback BEFORE sending commands so we don't miss
    // any response that arrives quickly.
    BluetoothManager.updateCallback(_onBtData);

    // Kick off the scan immediately: ask for temperature first.
    // When the temp response arrives, _onBtData will request pressure.
    _sendTempCommand();

    _startCountdown();
  }

  Future<void> _sendTempCommand() async {
    _waitingForPressure = false;
    await BluetoothManager.sendCommand('scan temperature');
  }

  // Called by BluetoothManager every time a complete line arrives from ESP32
  void _onBtData(String raw) {
    if (!mounted) return;

    if (!_waitingForPressure) {
      // First response is temperature
      setState(() {
        _tempData = raw.trim();
        _waitingForPressure = true;
      });
      // Now immediately ask for pressure
      BluetoothManager.sendCommand('scan pressure');
    } else {
      // Second response is pressure
      setState(() {
        _pressureData = raw.trim();
      });
      // Both datasets received — no need to keep listening here
      BluetoothManager.updateCallback(null);
    }
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds == 1) {
        _timer?.cancel();

        if (mounted) {
          if (_dataReceived) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => CompletedScreen(
                  foot: widget.foot,
                  scanData: _tempData,
                  pressureData: _pressureData,
                  patientId: widget.patientId,
                ),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ScanFailed(
                  foot: widget.foot,
                  patientId: widget.patientId,
                ),
              ),
            );
          }
        }
      } else {
        if (mounted) setState(() => _seconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Clear callback if we're disposed before data arrives
    BluetoothManager.updateCallback(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$_seconds',
              style: const TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 254, 5, 0),
                fontFamily: 'Lexend',
              ),
            ),
            const SizedBox(height: 30),
            if (_dataReceived)
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Data received',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green,
                      fontFamily: 'Lexend',
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Waiting for scan data...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          fontFamily: 'Lexend',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Show which data has arrived so far
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _tempData.isNotEmpty
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: _tempData.isNotEmpty
                            ? Colors.green
                            : Colors.black26,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      const Text('Temperature',
                          style: TextStyle(
                              fontFamily: 'Lexend',
                              fontSize: 13,
                              color: Colors.black54)),
                      const SizedBox(width: 20),
                      Icon(
                        _pressureData.isNotEmpty
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: _pressureData.isNotEmpty
                            ? Colors.green
                            : Colors.black26,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      const Text('Pressure',
                          style: TextStyle(
                              fontFamily: 'Lexend',
                              fontSize: 13,
                              color: Colors.black54)),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}