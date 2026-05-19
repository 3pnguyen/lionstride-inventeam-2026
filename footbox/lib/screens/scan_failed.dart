import 'package:flutter/material.dart';
import 'countdown.dart';
import 'patient_picker_sheet.dart';
import 'home_screen.dart';
import 'bluetooth_check.dart';

class ScanFailed extends StatefulWidget {
  /// Which foot was being tested — passed through so Retry restarts
  /// the correct foot's countdown.
  final String foot;

  /// The patient linked to this scan (may be null if skipped).
  final int? patientId;

  /// Set to [true] when the device was not connected to the FootBox at all
  /// (navigated here from HomeScreen / FootTestScreen).
  /// Set to [false] (default) when a connection existed but no scan data
  /// arrived within the countdown window (navigated here from Countdown).
  final bool bluetoothError;

  const ScanFailed({
    super.key,
    required this.foot,
    this.patientId,
    this.bluetoothError = false,
  });

  @override
  State<ScanFailed> createState() => _ScanFailedState();
}

class _ScanFailedState extends State<ScanFailed> {
  // ── Retry: re-ask for patient then restart countdown (scan-data-missing) ────
  Future<void> _retryScan() async {
    final dynamic patientId = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const PatientPickerSheet(),
    );

    if (!mounted) return;

    // -1 means the user tapped "Skip". Convert to null for Countdown.
    final int? finalPatientId = (patientId == -1) ? null : patientId as int?;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => Countdown(
          foot: widget.foot,
          patientId: finalPatientId,
        ),
      ),
    );
  }

  // ── Go to Bluetooth scan screen (BT-not-connected) ─────────────────────────
  void _goToBluetooth() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BluetoothCheckScreen()),
    );
  }

  void _goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    // Copy and colours differ depending on which error triggered this screen.
    final String headline = widget.bluetoothError
        ? 'FootBox not connected'
        : 'Scan failed, please try again.';

    final String subtext = widget.bluetoothError
        ? 'Your app is not connected to the FootBox device. '
          'Please connect via Bluetooth before starting a test.'
        : 'This may be due to a Bluetooth connection issue.'
          'Please try again.';

    final String retryLabel =
        widget.bluetoothError ? 'Connect to FootBox' : 'Retry';

    final Color primaryColor =
        widget.bluetoothError ? Colors.redAccent : Colors.green;

    final IconData icon =
        widget.bluetoothError ? Icons.bluetooth_disabled : Icons.error_outline;

    final Color iconColor =
        widget.bluetoothError ? Colors.red : Colors.redAccent;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(flex: 3),

              Icon(icon, size: screenHeight * 0.08, color: iconColor),

              SizedBox(height: screenHeight * 0.025),

              Text(
                headline,
                style: TextStyle(
                  fontSize: screenHeight * 0.025,
                  fontFamily: 'Lexend',
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: screenHeight * 0.012),

              Text(
                subtext,
                style: TextStyle(
                  fontSize: screenHeight * 0.02,
                  fontFamily: 'Lexend',
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 4),

              // Primary action
              SizedBox(
                width: double.infinity,
                height: screenHeight * 0.065,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: TextStyle(
                      fontSize: screenHeight * 0.02,
                      fontFamily: 'Lexend',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed:
                      widget.bluetoothError ? _goToBluetooth : _retryScan,
                  child: Text(retryLabel),
                ),
              ),

              SizedBox(height: screenHeight * 0.02),

              // Back to Home
              SizedBox(
                width: double.infinity,
                height: screenHeight * 0.065,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: TextStyle(
                      fontSize: screenHeight * 0.02,
                      fontFamily: 'Lexend',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: _goHome,
                  child: const Text('Back to Home'),
                ),
              ),

              SizedBox(height: screenHeight * 0.05),
            ],
          ),
        ),
      ),
    );
  }
}