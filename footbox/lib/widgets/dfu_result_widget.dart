import 'package:flutter/material.dart';
import 'package:footbox/models/dfu_result.dart';

class DFUResultWidget extends StatelessWidget {
  final DFUResult result;
  final String currentFoot;

  const DFUResultWidget({
    super.key,
    required this.result,
    required this.currentFoot,
  });

  Color _riskColor(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.none: return Colors.green;
      case RiskLevel.moderate: return Colors.orange;
      case RiskLevel.high: return Colors.red;
    }
  }

  IconData _riskIcon(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.none: return Icons.check_circle;
      case RiskLevel.moderate: return Icons.warning_amber_rounded;
      case RiskLevel.high: return Icons.dangerous;
    }
  }

  String _riskLabel(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.none: return 'No Risk';
      case RiskLevel.moderate: return 'Moderate Risk';
      case RiskLevel.high: return 'High Risk';
    }
  }

  String _formatTimestamp(String isoString) {
    final time = DateTime.parse(isoString);
    final hour = time.hour > 12
        ? time.hour - 12
        : time.hour == 0 ? 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '${time.month}/${time.day}/${time.year} $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // Overall risk banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _riskColor(result.overallRisk).withValues(alpha: .1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _riskColor(result.overallRisk).withValues(alpha: .5),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _riskIcon(result.overallRisk),
                color: _riskColor(result.overallRisk),
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _riskLabel(result.overallRisk),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lexend',
                        color: _riskColor(result.overallRisk),
                      ),
                    ),
                    Text(
                      'Compared to ${result.comparedToFoot} foot scan\n'
                      '${_formatTimestamp(result.comparedToTimestamp)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'Lexend',
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Per-region results
        ...result.regions.map((region) => _buildRegionCard(region)),
         // Composite analysis
        
        if (result.compositeAnalysis != null) ...[
          const SizedBox(height: 16),
          _buildCompositeSection(result.compositeAnalysis!),
        ],
      ],
    );
  }

  Widget _modalityBadge(String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontFamily: 'Lexend',
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    ),
  );
}

  Widget _buildRegionCard(RegionResult region) {
    final String regionName =
        region.region[0].toUpperCase() + region.region.substring(1);
    final Color color = _riskColor(region.riskLevel);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Region header
          Row(
            children: [
              Icon(_riskIcon(region.riskLevel), color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                regionName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lexend',
                  color: color,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ΔT ${region.deltaT.toStringAsFixed(1)}°F',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lexend',
                    color: color,
                  ),
                ),
              ),
            ],
          ),

          if (region.riskLevel != RiskLevel.none) ...[
            const SizedBox(height: 8),

            // Temp comparison
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _tempChip('This foot', region.currentTemp, Colors.blue),
                const Icon(Icons.compare_arrows, color: Colors.black38),
                _tempChip('Opposite', region.oppositeTemp, Colors.purple),
              ],
            ),

            const SizedBox(height: 8),

            // Hotspot location
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.black45),
                const SizedBox(width: 4),
                Text(
                  'Hotspot: ${region.hotspotLocation}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'Lexend',
                    color: Colors.black54,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Recommendation
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                region.recommendation,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'Lexend',
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 4),
            Text(
              region.recommendation,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'Lexend',
                color: Colors.black54,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tempChip(String label, double temp, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontFamily: 'Lexend',
            color: Colors.black45,
          ),
        ),
        Text(
          '${temp.toStringAsFixed(1)}°F',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lexend',
            color: color,
          ),
        ),
      ],
    );
  }
    Widget _buildCompositeSection(CompositeAnalysisResult composite) {
    final Color color = _riskColor(composite.compositeRisk);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            'Multi-Algorithm Analysis',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              fontFamily: 'Lexend',
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics_outlined, color: color, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${composite.flagCount}/4 algorithms flagged',
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: color,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(composite.confidence * 100).toStringAsFixed(0)}% confidence',
                      style: TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                composite.summary,
                style: const TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 12,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...composite.signals.map((signal) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: signal.flagged
                  ? Colors.red.withValues(alpha: 0.05)
                  : Colors.green.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: signal.flagged
                    ? Colors.red.withValues(alpha: 0.3)
                    : Colors.green.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  signal.flagged
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline,
                  color: signal.flagged ? Colors.red : Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        signal.name,
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: signal.flagged ? Colors.red : Colors.green,
                        ),
                      ),
                      if (signal.modality != AnalysisModality.none) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (signal.modality == AnalysisModality.temperature ||
                                signal.modality == AnalysisModality.both)
                              _modalityBadge('Thermal', Colors.red),
                            if (signal.modality == AnalysisModality.both)
                              const SizedBox(width: 4),
                            if (signal.modality == AnalysisModality.pressure ||
                                signal.modality == AnalysisModality.both)
                              _modalityBadge('Pressure', Colors.blue),
                          ],
                        ),
                      ],
                      Text(
                        signal.detail,
                        style: const TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 11,
                          color: Colors.black54,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  signal.score.toStringAsFixed(2),
                  style: const TextStyle(
                    fontFamily: 'Lexend',
                    fontSize: 11,
                    color: Colors.black38,
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }
}