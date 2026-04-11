import 'package:flutter/material.dart';
import 'countdown.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:FootBox/bluetooth/bluetooth_manager.dart';

class FootTestScreen extends StatefulWidget {
  final String foot;

  const FootTestScreen({
    super.key,
    required this.foot,
  });

  @override
  State<FootTestScreen> createState() => _FootTestScreenState();
}

class _FootTestScreenState extends State<FootTestScreen> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.foot} Foot',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Lexend',
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () async {
                final connection = BluetoothManager.connection;

                if (connection == null || !connection.isConnected) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Device not connected')),
                  );
                  return;
                }

                try {
                  // Send SCAN command via classic Bluetooth
                  String command = "scan\n";
                  connection.output.add(Uint8List.fromList(utf8.encode(command)));
                  await connection.output.allSent;
                  
                  print('SCAN command sent successfully');
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to send command: $e')),
                  );
                  return;
                }

                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Countdown(foot: widget.foot),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(screenWidth * 0.5, screenHeight * 0.08),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Start',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lexend',
                ),
              ),
            ),

            SizedBox(height: screenHeight * 0.25),

            Text(
              'Please ensure your foot is properly positioned on the scanner before starting the test.',
              style: TextStyle(
                fontSize: screenHeight * 0.022,
                fontFamily: 'Lexend',
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}