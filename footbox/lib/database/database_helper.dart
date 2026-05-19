import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
 
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();
 
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('footbox.db');
    return _database!;
  }
 
  Future<Database> _initDB(String filePath) async {
    final path = join(await getDatabasesPath(), filePath);
    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }
 
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
  // Existing v2 and v3 upgrades...
  if (oldVersion < 2) { /* ... */ }
  if (oldVersion < 3) { /* ... */ }
  

  // v3 → v4: Add the missing thermal_data column
  if (oldVersion < 4) {
    await db.execute('ALTER TABLE sessions ADD COLUMN thermal_data TEXT');
    debugPrint('DB upgraded to v4: thermal_data column added to sessions');
  }

  // v4 → v5: Add the missing pressure_data column
  if (oldVersion < 5) {
    await db.execute(
        'ALTER TABLE sessions ADD COLUMN pressure_data TEXT');
    debugPrint('DB upgraded to v5: pressure_data added to sessions');
  }
}

  Future _createDB(Database db, int version) async {
    // ── Core tables ──────────────────────────────────────────────────────
 
    await db.execute('''
      CREATE TABLE sessions (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        foot          TEXT,
        thermal_data  TEXT,
        pressure_data TEXT,
        timestamp     TEXT,
        patient_id    INTEGER
      )
    ''');
 
    await db.execute(
      'INSERT INTO sqlite_sequence (name, seq) VALUES ("sessions", 0)',
    );
 
    await db.execute('''
      CREATE TABLE temperature_readings (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER,
        row        INTEGER,
        col        INTEGER,
        temperature REAL,
        row_norm   REAL,
        col_norm   REAL,
        FOREIGN KEY (session_id) REFERENCES sessions(id)
      )
    ''');
 
    await db.execute(_regionViewDDL);
 
    // ── Patient / clinical tables ────────────────────────────────────────
 
    await db.execute(_patientsDDL);
    await db.execute(_clinicalProfilesDDL);
    await db.execute(_sessionOverridesDDL);
  }
 
  // ── DDL constants ────────────────────────────────────────────────────────
 
  static const _regionViewDDL = '''
    CREATE VIEW region_view AS
    SELECT
      session_id,
      row,
      col,
      temperature,
      row_norm,
      col_norm,
      CASE
        WHEN col_norm < 0.15 THEN 'toes'
        WHEN col_norm < 0.40 THEN 'forefoot'
        WHEN col_norm < 0.70 THEN 'midfoot'
        ELSE 'heel'
      END AS region
    FROM temperature_readings
  ''';
 
  static const _patientsDDL = '''
    CREATE TABLE patients (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      name       TEXT NOT NULL,
      dob        TEXT,
      sex        TEXT,
      created_at TEXT NOT NULL
    )
  ''';
 
  static const _clinicalProfilesDDL = '''
    CREATE TABLE clinical_profiles (
      id                INTEGER PRIMARY KEY AUTOINCREMENT,
      patient_id        INTEGER NOT NULL UNIQUE,
      neuropathy        INTEGER NOT NULL DEFAULT 0,
      pad               INTEGER NOT NULL DEFAULT 0,
      deformity         TEXT    NOT NULL DEFAULT 'none',
      prior_ulcer_site  TEXT    NOT NULL DEFAULT 'none',
      prior_amputation  INTEGER NOT NULL DEFAULT 0,
      esrd              INTEGER NOT NULL DEFAULT 0,
      iwgdf_risk        INTEGER NOT NULL DEFAULT 0,
      updated_at        TEXT    NOT NULL,
      FOREIGN KEY (patient_id) REFERENCES patients(id)
    )
  ''';
 
  static const _sessionOverridesDDL = '''
    CREATE TABLE session_overrides (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      session_id  INTEGER NOT NULL UNIQUE,
      neuropathy  INTEGER,
      pad         INTEGER,
      deformity   TEXT,
      notes       TEXT,
      FOREIGN KEY (session_id) REFERENCES sessions(id)
    )
  ''';
 
  // ── Session insert (unchanged logic, new patient_id param) ───────────────

  Future<List<Map<String, dynamic>>> getSessionsForPatient(int patientId) async {
  final db = await database;
  return await db.query(
    'sessions',
    where: 'patient_id = ?',
    whereArgs: [patientId],
    orderBy: 'id DESC',
  );
}
 
  Future<int> insertSession({
  required String foot,
  required List<List<double>> matrix,
  List<List<double>>? pressureMatrix,
  int? patientId,
}) async {
  final db = await database;
  const int rows = 12;
  const int cols = 26;

  final sessionId = await db.insert('sessions', {
    'foot': foot,
    'timestamp': DateTime.now().toIso8601String(),
    'thermal_data': jsonEncode(matrix),
    if (pressureMatrix != null)
      'pressure_data': jsonEncode(pressureMatrix),
    if (patientId != null) 'patient_id': patientId,
  });
 
    int minRow = rows, maxRow = 0;
    int minCol = cols, maxCol = 0;
    bool hasActive = false;
 
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (matrix[r][c] > 0) {
          if (r < minRow) minRow = r;
          if (r > maxRow) maxRow = r;
          if (c < minCol) minCol = c;
          if (c > maxCol) maxCol = c;
          hasActive = true;
        }
      }
    }
 
    if (!hasActive) {
      minRow = 0; maxRow = rows - 1;
      minCol = 0; maxCol = cols - 1;
    }
 
    final int activeRowRange = (maxRow - minRow).clamp(1, rows);
    final int activeColRange = (maxCol - minCol).clamp(1, cols);
 
    final batch = db.batch();
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final double rowNorm =
            ((r - minRow) / activeRowRange).clamp(0.0, 1.0);
        final double colNorm =
            ((c - minCol) / activeColRange).clamp(0.0, 1.0);
        batch.insert('temperature_readings', {
          'session_id': sessionId,
          'row': r,
          'col': c,
          'temperature': matrix[r][c],
          'row_norm': rowNorm,
          'col_norm': colNorm,
        });
      }
    }
    await batch.commit(noResult: true);
    return sessionId;
  }
 
  // ── All other existing methods unchanged below ───────────────────────────
 
  Future<List<Map<String, dynamic>>> getSessions() async {
    final db = await database;
    return await db.query('sessions', orderBy: 'id DESC');
  }

  Future<Map<String, dynamic>?> getSessionById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }
 
  Future<List<List<double>>> getMatrix(int sessionId) async {
    final db = await database;
    const int rows = 12;
    const int cols = 26;
 
    final readings = await db.query(
      'temperature_readings',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'row ASC, col ASC',
    );
 
    final matrix =
        List.generate(rows, (_) => List<double>.filled(cols, 0.0));
    for (final r in readings) {
      matrix[r['row'] as int][r['col'] as int] =
          r['temperature'] as double;
    }
    return matrix;
  }

  Future<List<List<double>>?> getPressureMatrix(int sessionId) async {
  final db = await database;
  final rows = await db.query(
    'sessions',
    columns: ['pressure_data'],
    where: 'id = ?',
    whereArgs: [sessionId],
  );
  if (rows.isEmpty) return null;
  final raw = rows.first['pressure_data'];
  if (raw == null) return null;
  try {
    final decoded = jsonDecode(raw.toString());
    return (decoded as List)
        .map((row) =>
            (row as List).map((v) => (v as num).toDouble()).toList())
        .toList();
  } catch (e) {
    debugPrint('getPressureMatrix error: $e');
    return null;
  }
}
 
  Future<Map<String, double>> getRegionStats(
      int sessionId, String region) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        AVG(temperature) as avg_temp,
        MAX(temperature) as max_temp,
        MIN(temperature) as min_temp
      FROM region_view
      WHERE session_id = ? AND region = ? AND temperature > 0
    ''', [sessionId, region]);
 
    return {
      'avg': (result.first['avg_temp'] as num?)?.toDouble() ?? 0.0,
      'max': (result.first['max_temp'] as num?)?.toDouble() ?? 0.0,
      'min': (result.first['min_temp'] as num?)?.toDouble() ?? 0.0,
    };
  }
 
  Future<Map<String, Map<String, double>>> getAllRegionStats(
      int sessionId) async {
    final regions = ['toes', 'forefoot', 'midfoot', 'heel'];
    final Map<String, Map<String, double>> allStats = {};
    for (final region in regions) {
      allStats[region] = await getRegionStats(sessionId, region);
    }
    return allStats;
  }
 
  Future<void> deleteSession(int id) async {
    final db = await database;
    await db.delete('session_overrides',
        where: 'session_id = ?', whereArgs: [id]);
    await db.delete('temperature_readings',
        where: 'session_id = ?', whereArgs: [id]);
    await db.delete('sessions', where: 'id = ?', whereArgs: [id]);
  }
 
  Future<Map<String, dynamic>?> getOppositeFootSession(
      int sessionId, String foot) async {
    final db = await database;
    final String oppositeFoot = foot == 'Left' ? 'Right' : 'Left';
 
    final current = await db.query('sessions',
        where: 'id = ?', whereArgs: [sessionId]);
    if (current.isEmpty) return null;
 
    final String currentTimestamp =
        current.first['timestamp'] as String;
 
    debugPrint(
        'Looking for opposite of: $foot, sessionId: $sessionId');
    debugPrint('Current timestamp: $currentTimestamp');
 
    final List<Map<String, dynamic>> sameDayResults =
        await db.rawQuery('''
      SELECT * FROM sessions
      WHERE foot = ?
      AND date(timestamp) = date(?)
      AND id != ?
      ORDER BY id DESC
      LIMIT 1
    ''', [oppositeFoot, currentTimestamp, sessionId]);
 
    debugPrint('Same day results: $sameDayResults');
    if (sameDayResults.isNotEmpty) return sameDayResults.first;
 
    final List<Map<String, dynamic>> fallbackResults =
        await db.rawQuery('''
      SELECT * FROM sessions
      WHERE foot = ?
      AND id != ?
      ORDER BY id DESC
      LIMIT 1
    ''', [oppositeFoot, sessionId]);
 
    debugPrint('Fallback results: $fallbackResults');
    if (fallbackResults.isNotEmpty) return fallbackResults.first;
    return null;
  }
 
  Future<Map<String, double>> getRegionAvgTemps(int sessionId) async {
    final db = await database;
 
    final sample = await db.rawQuery('''
      SELECT col_norm, region FROM region_view
      WHERE session_id = ? LIMIT 10
    ''', [sessionId]);
    debugPrint('Region sample for session $sessionId: $sample');
 
    final result = await db.rawQuery('''
      SELECT region, AVG(temperature) as avg_temp
      FROM region_view
      WHERE session_id = ? AND temperature > 0
      GROUP BY region
    ''', [sessionId]);
 
    debugPrint('Avg temps for session $sessionId: $result');
 
    final Map<String, double> avgTemps = {};
    for (final row in result) {
      avgTemps[row['region'] as String] =
          (row['avg_temp'] as num).toDouble();
    }
    return avgTemps;
  }

  // Put this after getOppositeFootSession
Future<SymmetryDetail> calculateSymmetryDifference(int sessionId) async {
  try {
    final db = await database;

    // 1. Get current session
    final List<Map<String, dynamic>> currentRows = await db.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );
    if (currentRows.isEmpty) {
      return SymmetryDetail(maxDiff: 0.0, row: 0, col: 0, regionName: "N/A");
    }

    final current = currentRows.first;
    final String currentFoot = current['foot']?.toString() ?? 'Left';
    final int? patientId = current['patient_id'] as int?;

    // 2. Find opposite foot — scoped to same patient if linked
    final List<Map<String, dynamic>> oppositeRows = await db.query(
      'sessions',
      where: patientId != null
          ? 'foot != ? AND patient_id = ? AND id != ?'
          : 'foot != ? AND id != ?',
      whereArgs: patientId != null
          ? [currentFoot, patientId, sessionId]
          : [currentFoot, sessionId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (oppositeRows.isEmpty) {
      return SymmetryDetail(
          maxDiff: 0.0, row: 0, col: 0, regionName: "No Pair");
    }

    debugPrint(
        "DEBUG: Pairing session $sessionId ($currentFoot) "
        "with session ${oppositeRows.first['id']} "
        "(patientId: $patientId)");

    // 3. Decode grids
    List<List<double>> extractGrid(Map<String, dynamic> session) {
      try {
        final rawData = session['thermal_data'];
        if (rawData == null || rawData.toString().isEmpty) {
          debugPrint(
              "DEBUG: thermal_data NULL for session ${session['id']}");
          return List.generate(12, (_) => List.generate(26, (_) => 0.0));
        }
        final decoded = jsonDecode(rawData.toString());
        return (decoded as List)
            .map((row) =>
                (row as List).map((val) => (val as num).toDouble()).toList())
            .toList();
      } catch (e) {
        debugPrint("DEBUG: Grid decode error for session ${session['id']}: $e");
        return List.generate(12, (_) => List.generate(26, (_) => 0.0));
      }
    }

    // 4. Smooth a pixel using 3x3 neighborhood average
    double getSmoothedValue(List<List<double>> matrix, int r, int c) {
      double sum = 0;
      int count = 0;
      for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
          final int nr = r + i;
          final int nc = c + j;
          if (nr >= 0 && nr < 12 && nc >= 0 && nc < 26) {
            if (matrix[nr][nc] > 85.0) {
              sum += matrix[nr][nc];
              count++;
            }
          }
        }
      }
      return count > 0 ? sum / count : matrix[r][c];
    }

    final leftData = extractGrid(
        currentFoot == 'Left' ? current : oppositeRows.first);
    final rightData = extractGrid(
        currentFoot == 'Right' ? current : oppositeRows.first);

    // 5. Find peak asymmetry
    double maxDiff = 0.0;
    String peakRegion = "N/A";
    int peakRow = 0;
    int peakCol = 0;

    for (int r = 0; r < 12; r++) {
      for (int c = 0; c < 26; c++) {
        final double lVal = getSmoothedValue(leftData, r, c);
        final int mirroredCol = 25 - c;

        // Find max value in 3x3 neighborhood around mirrored pixel
        double maxNearbyR = 0;
        for (int i = -1; i <= 1; i++) {
          for (int j = -1; j <= 1; j++) {
            final int nRow = r + i;
            final int nCol = mirroredCol + j;
            if (nRow >= 0 && nRow < 12 && nCol >= 0 && nCol < 26) {
              if (rightData[nRow][nCol] > maxNearbyR) {
                maxNearbyR = rightData[nRow][nCol];
              }
            }
          }
        }

        // Only compare valid foot pixels on both sides
        if (lVal > 88 && maxNearbyR > 88) {
          final double diff = (lVal - maxNearbyR).abs();
          if (diff > maxDiff) {
            maxDiff = diff;
            peakRow = r;
            peakCol = c;
            peakRegion = getRegionName(row: r, col: c);
          }
        }
      }
    }

    return SymmetryDetail(
      maxDiff: maxDiff,
      row: peakRow,
      col: peakCol,
      regionName: peakRegion,
    );
  } catch (e) {
    debugPrint("Symmetry Error: $e");
    return SymmetryDetail(
        maxDiff: 0.0, row: 0, col: 0, regionName: "Error");
  }
}


  // HELPER: Matches the UI regions
  String getRegionName({required int row, required int col}) {
    if (row <= 2) return "Toes";
    if (row <= 5) return "Forefoot";
    if (row <= 8) return "Midfoot";
    return "Heel";
  }

 
  Future<Map<String, dynamic>?> getHotspot(
      int sessionId, String region) async {
    final db = await database;
 
    final readings = await db.rawQuery('''
      SELECT row, col, temperature
      FROM region_view
      WHERE session_id = ? AND region = ? AND temperature > 0
      ORDER BY temperature DESC
    ''', [sessionId, region]);
 
    if (readings.isEmpty) return null;
 
    double bestAvg = 0;
    int bestRow = 0, bestCol = 0;
 
    for (final center in readings) {
      final int cr = center['row'] as int;
      final int cc = center['col'] as int;
 
      double sum = 0;
      int count = 0;
      for (final r in readings) {
        final int rr = r['row'] as int;
        final int rc = r['col'] as int;
        if ((rr - cr).abs() <= 1 && (rc - cc).abs() <= 1) {
          sum += r['temperature'] as double;
          count++;
        }
      }
 
      final double avg = count > 0 ? sum / count : 0;
      if (avg > bestAvg) {
        bestAvg = avg;
        bestRow = cr;
        bestCol = cc;
      }
    }
 
    final String lateral = bestRow < 6 ? 'lateral' : 'medial';
    final String position = _getPositionLabel(region, bestCol);
 
    return {
      'row': bestRow,
      'col': bestCol,
      'avgTemp': bestAvg,
      'anatomicalLabel': '$lateral $position',
    };
  }
 
  String _getPositionLabel(String region, int col) {
    switch (region) {
      case 'toes':
        return col <= 1 ? 'great toe' : 'lesser toes';
      case 'forefoot':
        return col < 7 ? 'proximal forefoot' : 'distal forefoot';
      case 'midfoot':
        return col < 14 ? 'proximal midfoot' : 'distal midfoot';
      case 'heel':
        return col < 22 ? 'anterior heel' : 'posterior heel';
      default:
        return region;
    }
  }
  
  // Put this at the end of the DatabaseHelper class
  Future<double> getVolatility(int patientId, String foot, int currentSessionId) async {
    final db = await database;
    
    // Get the previous session for this specific patient and foot
    final previousSessions = await db.query(
      'sessions',
      where: 'patient_id = ? AND foot = ? AND id < ?',
      whereArgs: [patientId, foot, currentSessionId],
      orderBy: 'id DESC',
      limit: 1,
    );

    if (previousSessions.isEmpty) return 0.0;

    final int prevId = previousSessions.first['id'] as int;
    final List<List<double>> currentMatrix = await getMatrix(currentSessionId);
    final List<List<double>> prevMatrix = await getMatrix(prevId);

    double varianceSum = 0;
    int count = 0;

    for (int r = 0; r < 12; r++) {
      for (int c = 0; c < 26; c++) {
        if (currentMatrix[r][c] > 0 && prevMatrix[r][c] > 0) {
          // Mean Squared Error math
          double diff = currentMatrix[r][c] - prevMatrix[r][c];
          varianceSum += diff * diff;
          count++;
        }
      }
    }

    // Return the square root of the average variance (RMSE)
    return count > 0 ? sqrt(varianceSum / count) : 0.0;
  }
}

class SymmetryDetail {
  final double maxDiff;
  final int row;
  final int col;
  final String regionName;

  SymmetryDetail({
    required this.maxDiff, 
    required this.row, 
    required this.col, 
    required this.regionName,
  });
}