import 'package:flutter/foundation.dart';
import '../models/patient.dart';
import 'database_helper.dart';
 
class PatientRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
 
  // ─── Patients ────────────────────────────────────────────────────────────
 
  Future<int> insertPatient(Patient patient) async {
    final db = await _db.database;
    return db.insert('patients', patient.toMap());
  }
 
  Future<List<Patient>> getAllPatients() async {
    final db = await _db.database;
    final rows = await db.query('patients', orderBy: 'name ASC');
    return rows.map(Patient.fromMap).toList();
  }
 
  Future<Patient?> getPatient(int id) async {
    final db = await _db.database;
    final rows = await db.query('patients', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Patient.fromMap(rows.first);
  }
 
  Future<void> updatePatient(Patient patient) async {
    final db = await _db.database;
    await db.update('patients', patient.toMap(),
        where: 'id = ?', whereArgs: [patient.id]);
  }
 
  Future<void> deletePatient(int id) async {
    final db = await _db.database;
    // Cascade: delete profile, overrides (via sessions), then sessions, then patient
    final sessions = await db
        .query('sessions', where: 'patient_id = ?', whereArgs: [id]);
    for (final s in sessions) {
      await db.delete('session_overrides',
          where: 'session_id = ?', whereArgs: [s['id']]);
    }
    await db
        .delete('sessions', where: 'patient_id = ?', whereArgs: [id]);
    await db
        .delete('clinical_profiles', where: 'patient_id = ?', whereArgs: [id]);
    await db.delete('patients', where: 'id = ?', whereArgs: [id]);
  }
 
  // ─── Clinical profiles ───────────────────────────────────────────────────
 
  Future<int> insertProfile(ClinicalProfile profile) async {
    final db = await _db.database;
    return db.insert('clinical_profiles', profile.toMap());
  }
 
  Future<ClinicalProfile?> getProfile(int patientId) async {
    final db = await _db.database;
    final rows = await db.query('clinical_profiles',
        where: 'patient_id = ?', whereArgs: [patientId]);
    if (rows.isEmpty) return null;
    return ClinicalProfile.fromMap(rows.first);
  }
 
  Future<void> upsertProfile(ClinicalProfile profile) async {
    final db = await _db.database;
    final existing = await getProfile(profile.patientId);
    if (existing == null) {
      await db.insert('clinical_profiles', profile.toMap());
    } else {
      await db.update(
        'clinical_profiles',
        profile.copyWith(
          id: existing.id,
          updatedAt: DateTime.now().toIso8601String(),
        ).toMap(),
        where: 'patient_id = ?',
        whereArgs: [profile.patientId],
      );
    }
  }

  Future<ClinicalProfile?> getProfileForPatient(int patientId) async {
  final db = await DatabaseHelper.instance.database;
  final rows = await db.query(
    'clinical_profiles',
    where: 'patient_id = ?',
    whereArgs: [patientId],
    limit: 1,
  );
  if (rows.isEmpty) return null;
  return ClinicalProfile.fromMap(rows.first);
}
 
  // ─── Session overrides ───────────────────────────────────────────────────
 
  Future<int> upsertSessionOverride(SessionOverride override) async {
    final db = await _db.database;
    final existing = await db.query('session_overrides',
        where: 'session_id = ?', whereArgs: [override.sessionId]);
    if (existing.isEmpty) {
      return db.insert('session_overrides', override.toMap());
    } else {
      await db.update('session_overrides', override.toMap(),
          where: 'session_id = ?', whereArgs: [override.sessionId]);
      return override.id ?? (existing.first['id'] as int);
    }
  }
 
  Future<SessionOverride?> getSessionOverride(int sessionId) async {
    final db = await _db.database;
    final rows = await db.query('session_overrides',
        where: 'session_id = ?', whereArgs: [sessionId]);
    if (rows.isEmpty) return null;
    return SessionOverride.fromMap(rows.first);
  }
 
  // ─── Effective profile for a session ─────────────────────────────────────
 
  /// Returns the ClinicalProfile that should be used when analysing [sessionId].
  /// Override fields (if any) are merged on top of the base profile.
  /// Returns null if the session has no linked patient or profile yet.
  Future<ClinicalProfile?> getEffectiveProfile(int sessionId) async {
    final db = await _db.database;
 
    // Find the patient linked to this session
    final sessionRows = await db.query('sessions',
        where: 'id = ?', whereArgs: [sessionId]);
    if (sessionRows.isEmpty) return null;
 
    final patientId = sessionRows.first['patient_id'] as int?;
    if (patientId == null) return null;
 
    final base = await getProfile(patientId);
    if (base == null) return null;
 
    final override = await getSessionOverride(sessionId);
    if (override == null) return base;
 
    return override.mergeWith(base);
  }
 
  // ─── Convenience: create patient + profile in one call ───────────────────
 
  Future<({int patientId, int profileId})> createPatientWithProfile({
    required Patient patient,
    required ClinicalProfile profile,
  }) async {
    final db = await _db.database;
    return db.transaction((txn) async {
      final patientId = await txn.insert('patients', patient.toMap());
      final profileWithId = profile.copyWith(
        patientId: patientId,
        updatedAt: DateTime.now().toIso8601String(),
      );
      final profileId =
          await txn.insert('clinical_profiles', profileWithId.toMap());
      debugPrint('Created patient $patientId with profile $profileId');
      return (patientId: patientId, profileId: profileId);
    });
  }
}