class Patient {
  final int? id;
  final String name;
  final String dob;
  final String sex;
  final String createdAt;

  const Patient({
    this.id,
    required this.name,
    required this.dob,
    required this.sex,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'dob': dob,
        'sex': sex,
        'created_at': createdAt,
      };

  factory Patient.fromMap(Map<String, dynamic> map) => Patient(
        id: map['id'] as int?,
        name: map['name'] as String,
        dob: map['dob'] as String,
        sex: map['sex'] as String,
        createdAt: map['created_at'] as String,
      );

  Patient copyWith({
    int? id,
    String? name,
    String? dob,
    String? sex,
    String? createdAt,
  }) =>
      Patient(
        id: id ?? this.id,
        name: name ?? this.name,
        dob: dob ?? this.dob,
        sex: sex ?? this.sex,
        createdAt: createdAt ?? this.createdAt,
      );
}


// Neuropathy / PAD severity levels
enum Severity { none, mild, severe }

extension SeverityExt on Severity {
  int toInt() => index; // none=0, mild=1, severe=2
  static Severity fromInt(int v) => Severity.values[v.clamp(0, 2)];
  String get label => ['None', 'Mild', 'Severe'][index];
}

// Foot deformity types
enum DeformityType { none, hammerToes, charcot, collapsedMidfoot, other }

extension DeformityTypeExt on DeformityType {
  String toDb() => name; // stores as 'none', 'hammerToes', etc.
  static DeformityType fromDb(String? v) =>
      DeformityType.values.firstWhere((e) => e.name == v,
          orElse: () => DeformityType.none);
  String get label => const {
        DeformityType.none: 'None',
        DeformityType.hammerToes: 'Hammer toes',
        DeformityType.charcot: 'Charcot',
        DeformityType.collapsedMidfoot: 'Collapsed midfoot',
        DeformityType.other: 'Other',
      }[this]!;
}

// Prior ulcer anatomical sites
enum UlcerSite { none, hallux, firstMetHead, lesserMetHeads, midfoot, heel }

extension UlcerSiteExt on UlcerSite {
  String toDb() => name;
  static UlcerSite fromDb(String? v) =>
      UlcerSite.values.firstWhere((e) => e.name == v,
          orElse: () => UlcerSite.none);
  String get label => const {
        UlcerSite.none: 'None',
        UlcerSite.hallux: 'Hallux',
        UlcerSite.firstMetHead: '1st met head',
        UlcerSite.lesserMetHeads: 'Lesser met heads',
        UlcerSite.midfoot: 'Midfoot',
        UlcerSite.heel: 'Heel',
      }[this]!;
}

class ClinicalProfile {
  final int? id;
  final int patientId;
  final Severity neuropathy;
  final Severity pad;
  final DeformityType deformity;
  final UlcerSite priorUlcerSite;
  final bool priorAmputation;
  final bool esrd;
  final String updatedAt;

  const ClinicalProfile({
    this.id,
    required this.patientId,
    this.neuropathy = Severity.none,
    this.pad = Severity.none,
    this.deformity = DeformityType.none,
    this.priorUlcerSite = UlcerSite.none,
    this.priorAmputation = false,
    this.esrd = false,
    required this.updatedAt,
  });

  /// IWGDF risk 0–3 derived from clinical fields.
  /// Risk 3: prior amputation, ESRD, or prior ulcer history
  /// Risk 2: neuropathy + PAD, or neuropathy + deformity
  /// Risk 1: neuropathy or PAD alone
  /// Risk 0: no risk factors
  int get iwgdfRisk {
  // Risk 3 — severe disease or prior complications
  if (priorAmputation ||
      esrd ||
      priorUlcerSite != UlcerSite.none ||
      pad == Severity.severe ||
      neuropathy == Severity.severe) {
    return 3;
  }

  // Risk 2 — neuropathy + PAD, or neuropathy + deformity
  if (neuropathy.index >= 1 &&
      (pad.index >= 1 || deformity != DeformityType.none)) {
    return 2;
  }

  // Risk 1 — any single risk factor present
  if (neuropathy.index >= 1 ||
      pad.index >= 1 ||
      deformity != DeformityType.none) {
    return 1;
  }

  // Risk 0 — no risk factors at all
  return 0;
}

  /// ΔT alert threshold in °C, derived from IWGDF risk.
  double get deltaThreshold {
    switch (iwgdfRisk) {
      case 3:
        return 1.5;
      case 2:
        return 1.8;
      case 1:
        return 2.0;
      default:
        return 2.2;
    }
  }

  String get iwgdfRiskLabel {
    final reasons = <String>[];
    if (priorAmputation) reasons.add('prior amputation');
    if (esrd) reasons.add('ESRD');
    if (priorUlcerSite != UlcerSite.none) reasons.add('prior ulcer');
    if (reasons.isEmpty && neuropathy.index >= 1) reasons.add('neuropathy');
    if (reasons.isEmpty && pad.index >= 1) reasons.add('PAD');
    return reasons.isEmpty ? 'No risk factors' : reasons.join(' + ');
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'patient_id': patientId,
        'neuropathy': neuropathy.toInt(),
        'pad': pad.toInt(),
        'deformity': deformity.toDb(),
        'prior_ulcer_site': priorUlcerSite.toDb(),
        'prior_amputation': priorAmputation ? 1 : 0,
        'esrd': esrd ? 1 : 0,
        'iwgdf_risk': iwgdfRisk,
        'updated_at': updatedAt,
      };

  factory ClinicalProfile.fromMap(Map<String, dynamic> map) => ClinicalProfile(
        id: map['id'] as int?,
        patientId: map['patient_id'] as int,
        neuropathy: SeverityExt.fromInt(map['neuropathy'] as int? ?? 0),
        pad: SeverityExt.fromInt(map['pad'] as int? ?? 0),
        deformity: DeformityTypeExt.fromDb(map['deformity'] as String?),
        priorUlcerSite: UlcerSiteExt.fromDb(map['prior_ulcer_site'] as String?),
        priorAmputation: (map['prior_amputation'] as int? ?? 0) == 1,
        esrd: (map['esrd'] as int? ?? 0) == 1,
        updatedAt: map['updated_at'] as String,
      );

  ClinicalProfile copyWith({
    int? id,
    int? patientId,
    Severity? neuropathy,
    Severity? pad,
    DeformityType? deformity,
    UlcerSite? priorUlcerSite,
    bool? priorAmputation,
    bool? esrd,
    String? updatedAt,
  }) =>
      ClinicalProfile(
        id: id ?? this.id,
        patientId: patientId ?? this.patientId,
        neuropathy: neuropathy ?? this.neuropathy,
        pad: pad ?? this.pad,
        deformity: deformity ?? this.deformity,
        priorUlcerSite: priorUlcerSite ?? this.priorUlcerSite,
        priorAmputation: priorAmputation ?? this.priorAmputation,
        esrd: esrd ?? this.esrd,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class SessionOverride {
  final int? id;
  final int sessionId;
  final Severity? neuropathy; // null = use base profile
  final Severity? pad;        // null = use base profile
  final DeformityType? deformity;
  final String? notes;

  const SessionOverride({
    this.id,
    required this.sessionId,
    this.neuropathy,
    this.pad,
    this.deformity,
    this.notes,
  });

  /// Merge this override onto a base profile to produce effective values.
  /// Override fields take precedence; nulls fall back to the base.
  ClinicalProfile mergeWith(ClinicalProfile base) => base.copyWith(
        neuropathy: neuropathy ?? base.neuropathy,
        pad: pad ?? base.pad,
        deformity: deformity ?? base.deformity,
        updatedAt: DateTime.now().toIso8601String(),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'session_id': sessionId,
        'neuropathy': neuropathy?.toInt(),
        'pad': pad?.toInt(),
        'deformity': deformity?.toDb(),
        'notes': notes,
        // iwgdf_risk is derived, not stored — compute via mergeWith()
      };

  factory SessionOverride.fromMap(Map<String, dynamic> map) => SessionOverride(
        id: map['id'] as int?,
        sessionId: map['session_id'] as int,
        neuropathy: map['neuropathy'] != null
            ? SeverityExt.fromInt(map['neuropathy'] as int)
            : null,
        pad: map['pad'] != null
            ? SeverityExt.fromInt(map['pad'] as int)
            : null,
        deformity: map['deformity'] != null
            ? DeformityTypeExt.fromDb(map['deformity'] as String)
            : null,
        notes: map['notes'] as String?,
      );
}