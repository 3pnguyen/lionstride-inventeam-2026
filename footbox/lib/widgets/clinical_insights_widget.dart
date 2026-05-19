import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class ClinicalInsightsWidget extends StatefulWidget {
  final int sessionId;
  final int? patientId;
  final String foot;

  const ClinicalInsightsWidget({
    super.key, 
    required this.sessionId, 
    this.patientId, 
    required this.foot
  });

  @override
  State<ClinicalInsightsWidget> createState() => _ClinicalInsightsWidgetState();
}

class _ClinicalInsightsWidgetState extends State<ClinicalInsightsWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SymmetryDetail>(
      future: DatabaseHelper.instance.calculateSymmetryDifference(widget.sessionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData && snapshot.data != null) {
          final insights = snapshot.data as SymmetryDetail;
          final double symmetryVal = insights.maxDiff;
          final String symmetryLoc = insights.regionName;
          final double volatilityVal = 0.0;

          return Row(
            children: [
              _buildCard(
                'Symmetry',
                '${symmetryVal.toStringAsFixed(1)}°F',
                symmetryVal > 4.0,
                Icons.compare_arrows,
                symmetryVal > 4.0 ? 'Peak: $symmetryLoc' : 'Stable',
              ),
              const SizedBox(width: 12),
              _buildCard(
                'Volatility',
                volatilityVal.toStringAsFixed(1),
                volatilityVal > 1.5,
                Icons.trending_up,
                volatilityVal > 1.5 ? 'High Fluctuations' : 'Stable',
              ),
            ],
          );
        }
        return const Center(child: Text("Error loading data"));
      },
    );
  }

  // Your _buildCard function stays here
  Widget _buildCard(String title, String value, bool isAlert, IconData icon, String status) {
    final color = isAlert ? Colors.red : Colors.green;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: .3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54, fontFamily: 'Lexend')),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color, fontFamily: 'Lexend')),
            Text(status, 
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color, fontFamily: 'Lexend')),
          ],
        ),
      ),
    );
  }
}