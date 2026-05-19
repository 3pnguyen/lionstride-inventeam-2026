import 'package:flutter/material.dart';
import 'countdown.dart';
import 'patient_picker_sheet.dart';
import 'scan_failed.dart';
import '../bluetooth/bluetooth_manager.dart';

class FootTestStart extends StatefulWidget {
  const FootTestStart({super.key});

  @override
  State<FootTestStart> createState() => _FootTestStartState();
}

class _FootTestStartState extends State<FootTestStart> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Foot Test'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FootTestScreen(foot: 'Left'),
              ),
            );
          },
          child: const Text('Start Test'),
        ),
      ),
    );
  }
}

class FootTestScreen extends StatefulWidget {
  final String foot;
  final int? patientId;

  const FootTestScreen({
    super.key,
    required this.foot,
    this.patientId,
  });

  @override
  State<FootTestScreen> createState() => _FootTestScreenState();
}

class _FootTestScreenState extends State<FootTestScreen> {
  bool get _isConnected =>
      BluetoothManager.connection != null &&
      BluetoothManager.connection!.isConnected;

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
                // Guard: verify BT connection before doing anything else.
                if (!_isConnected) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScanFailed(
                        foot: widget.foot,
                        patientId: widget.patientId,
                        bluetoothError: true,
                      ),
                    ),
                  );
                  return;
                }

                int? finalPatientId = widget.patientId;

                if (finalPatientId == null) {
                  final dynamic patientId = await showModalBottomSheet<dynamic>(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => const PatientPickerSheet(),
                  );

                  if (!mounted) return;

                  // null  → user dismissed sheet without choosing → stay on screen
                  if (patientId == null) return;

                  // -1   → user tapped "Skip" → pass null to Countdown
                  finalPatientId = (patientId == -1) ? null : patientId as int?;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Countdown(
                      foot: widget.foot,
                      patientId: finalPatientId,
                    ),
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

            SizedBox(height: screenHeight * 0.02),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Please ensure your foot is properly positioned on the scanner before starting the test.',
                style: TextStyle(
                  fontSize: screenHeight * 0.022,
                  fontFamily: 'Lexend',
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}