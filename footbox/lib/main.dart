import 'package:flutter/material.dart';
import 'package:footbox/screens/home_screen.dart';

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
      theme: ThemeData(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}