import 'package:flutter/material.dart';
import 'past_scans.dart';
import 'foot_test_start.dart';
import 'package:url_launcher/url_launcher.dart';
import 'patients_screen.dart';
import 'bluetooth_check.dart';
import 'scan_failed.dart';
import '../bluetooth/bluetooth_manager.dart';
import 'live_monitor.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  bool get _isConnected =>
      BluetoothManager.connection != null &&
      BluetoothManager.connection!.isConnected;

  Future<void> _launchWebsite() async {
    final Uri url = Uri.parse('https://kcle102.wixsite.com/my-site');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  /// Checks BT connection and either navigates to [FootTestScreen] for the
  /// given [foot] or pushes [ScanFailed] with [bluetoothError: true].
  void _onFootTap(BuildContext context, String foot) {
    if (!_isConnected) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScanFailed(
            foot: foot,
            bluetoothError: true,
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FootTestScreen(foot: foot),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final buttonWidth = screenWidth * 0.8;
    final buttonHeight = screenHeight * 0.12;
    final buttonSpacing = screenHeight * 0.075;
    final footerBottomPadding = screenHeight * 0.05;

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Padding(
              padding: EdgeInsets.only(left: screenWidth * 0.03),
              child: Image.asset(
                'assets/menu_icon.png',
                height: screenHeight * 0.09,
                width: screenHeight * 0.09,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'FootBox',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            fontFamily: 'Lexend',
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: screenWidth * 0.03),
            child: Image.asset(
              'assets/logo.png',
              height: screenHeight * 0.09,
              width: screenHeight * 0.09,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 254, 5, 0),
              ),
              child: const Text(
                'LionStride',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontFamily: 'Lexend',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home', style: TextStyle(fontFamily: 'Lexend')),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.people_outline),
              title:
                  const Text('Patients', style: TextStyle(fontFamily: 'Lexend')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PatientsScreen()),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Past Scans',
                  style: TextStyle(fontFamily: 'Lexend')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PastScansScreen()),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.bluetooth),
              title: const Text('Bluetooth',
                  style: TextStyle(fontFamily: 'Lexend')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const BluetoothCheckScreen()),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.monitor_heart_outlined),
              title: const Text('Live Monitor', 
                  style: TextStyle(fontFamily: 'Lexend')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LiveMonitorScreen()),
                  );
                },
              ),
 

            ListTile(
              leading: const Icon(Icons.info),
              title:
                  const Text('About', style: TextStyle(fontFamily: 'Lexend')),
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: 'FootBox',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© 2026 LionStride',
                  children: [
                    const Text(
                      'FootBox is an app designed to pair along with a FootBox device to analyze foot pressure and temperature patterns as seen in DFUs.',
                      style: TextStyle(fontFamily: 'Lexend'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _launchWebsite,
                      child: const Text(
                        'LionStride Website',
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),

      body: SizedBox.expand(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: screenHeight * 0.35),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Right Foot ──────────────────────────────────────────
                    ElevatedButton(
                      onPressed: () => _onFootTap(context, 'Right'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(buttonWidth, buttonHeight),
                        backgroundColor: const Color.fromARGB(255, 254, 5, 0),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                      ),
                      child: SizedBox(
                        width: buttonWidth,
                        height: buttonHeight,
                        child: Stack(
                          children: [
                            Positioned(
                              left: buttonWidth * 0.11,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: Text(
                                  'Right Foot',
                                  style: TextStyle(
                                    fontSize: buttonHeight * 0.26,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Lexend',
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: buttonWidth * 0.11,
                              top: buttonHeight * 0.13,
                              child: Image.asset(
                                'assets/right_foot.png',
                                height: buttonHeight * 0.74,
                                width: buttonHeight * 0.74,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: buttonSpacing),

                    // ── Left Foot ───────────────────────────────────────────
                    ElevatedButton(
                      onPressed: () => _onFootTap(context, 'Left'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(buttonWidth, buttonHeight),
                        backgroundColor: const Color.fromARGB(255, 254, 5, 0),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                      ),
                      child: SizedBox(
                        width: buttonWidth,
                        height: buttonHeight,
                        child: Stack(
                          children: [
                            Positioned(
                              right: buttonWidth * 0.11,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: Text(
                                  'Left Foot',
                                  style: TextStyle(
                                    fontSize: buttonHeight * 0.26,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Lexend',
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: buttonWidth * 0.11,
                              top: buttonHeight * 0.13,
                              child: Image.asset(
                                'assets/left_foot.png',
                                height: buttonHeight * 0.74,
                                width: buttonHeight * 0.74,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              bottom: footerBottomPadding,
              left: 0,
              right: 0,
              child: const Center(
                child: Text(
                  'Select a foot to start the test!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lexend',
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}