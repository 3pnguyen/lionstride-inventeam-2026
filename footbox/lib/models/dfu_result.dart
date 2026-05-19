enum RiskLevel { none, moderate, high }

enum AnalysisModality { temperature, pressure, both, none }

class RegionResult {
  final String region;
  final double deltaT;
  final RiskLevel riskLevel;
  final String hotspotLocation;
  final String recommendation;
  final double currentTemp;
  final double oppositeTemp;

  RegionResult({
    required this.region,
    required this.deltaT,
    required this.riskLevel,
    required this.hotspotLocation,
    required this.recommendation,
    required this.currentTemp,
    required this.oppositeTemp,
  });
}

class AlgorithmSignal {
  final String name;
  final bool flagged;
  final double score;
  final String detail;
  final AnalysisModality modality;

  const AlgorithmSignal({
    required this.name,
    required this.flagged,
    required this.score,
    required this.detail,
    this.modality = AnalysisModality.none,
  });
}

class CompositeAnalysisResult {
  final List<AlgorithmSignal> signals;
  final int flagCount;
  final double confidence;
  final RiskLevel compositeRisk;
  final String summary;

  const CompositeAnalysisResult({
    required this.signals,
    required this.flagCount,
    required this.confidence,
    required this.compositeRisk,
    required this.summary,
  });

  AlgorithmSignal? signal(String name) =>
      signals.where((s) => s.name == name).firstOrNull;
}

class DFUResult {
  final List<RegionResult> regions;
  final RiskLevel overallRisk;
  final int comparedToSessionId;
  final String comparedToFoot;
  final String comparedToTimestamp;
  final CompositeAnalysisResult? compositeAnalysis;

  DFUResult({
    required this.regions,
    required this.overallRisk,
    required this.comparedToSessionId,
    required this.comparedToFoot,
    required this.comparedToTimestamp,
    this.compositeAnalysis,
  });

  List<RegionResult> get flaggedRegions =>
      regions.where((r) => r.riskLevel != RiskLevel.none).toList();

  bool get hasRisk => overallRisk != RiskLevel.none;
}