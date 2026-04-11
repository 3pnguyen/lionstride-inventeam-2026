import 'dart:async';
import 'package:flutter/material.dart';
import 'completed_screen.dart';
import 'package:FootBox/bluetooth/bluetooth_manager.dart';

class Countdown extends StatefulWidget {
  final String foot;
  const Countdown({super.key, required this.foot});

  @override
  State<Countdown> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<Countdown> {
  int _seconds = 3;
  Timer? _timer;
  String _scanData = '';
  bool _dataReceived = false;

  @override
  void initState() {
    super.initState();
    _setupDataCallback();
    _startCountdown();
  }

  void _setupDataCallback() {
    // Update the BluetoothManager's callback to handle incoming data
    BluetoothManager.updateCallback((String data) {
      if (mounted) {
        setState(() {
          _scanData = data;
          _dataReceived = true;
        });
        print('Scan data received in countdown: ${data.substring(0, data.length > 50 ? 50 : data.length)}...');
      }
    });
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds == 1) {
        _timer?.cancel();
        
        // Navigate to completed screen with the scan data
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CompletedScreen(
                foot: widget.foot,
                scanData: _scanData,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _seconds--;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Clear the callback when leaving this screen
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
          ],
        ),
      ),
    );
  }
}