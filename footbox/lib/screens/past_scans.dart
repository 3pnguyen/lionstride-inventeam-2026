import 'package:flutter/material.dart';

class PastScansScreen extends StatelessWidget {
  const PastScansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Scans',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Lexend',
            )),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'This will show past scan results.',
          style: TextStyle(fontSize: 20, fontFamily: 'Lexend'),
        ),
      ),
    );
  }
}
