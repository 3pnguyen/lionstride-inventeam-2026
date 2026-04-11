import 'package:flutter/material.dart';
// import 'package:FootBox/screens/home_screen.dart';
import 'package:FootBox/screens/bluetooth_check.dart';

void main() {
  runApp(const FootScanApp());
}

class FootScanApp extends StatelessWidget {
  const FootScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Foot Scan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const BluetoothCheckScreen(),
    );
  }
}
