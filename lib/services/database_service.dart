import 'dart:developer' as developer;

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/coordinate_model.dart';
import '../models/eco_buddy_model.dart';
import '../models/observation_model.dart';

/// sqflite database — the Flutter equivalent of the Kotlin Room `AppDatabase`.
/// Holds the `coordinates` and `observations` tables.
class DatabaseService {
  static const String _tag = 'EcoLifeDb';
  static const String _dbName = 'ecolife.db';
  static const int _dbVersion = 2;

  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  // Cache the future (not the resolved Database) so concurrent first callers
  // share a single open operation instead of racing.
  Future<Database>? _dbFuture;

  Future<Database> get _db => _dbFuture ??= _open();

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), _dbName);
    developer.log('_open: opening $path', name: _tag);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    developer.log('_onCreate: creating tables (v$version)', name: _tag);
    await db.execute('''
      CREATE TABLE coordinates (
        timestamp INTEGER PRIMARY KEY,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        altitude REAL NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE observations (
        timestamp INTEGER PRIMARY KEY,
        type TEXT NOT NULL,
        value TEXT NOT NULL,
        note TEXT NOT NULL,
        lat TEXT NOT NULL,
        lon TEXT NOT NULL
      )
    ''');
    await _createBuddyTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    developer.log('_onUpgrade: $oldVersion → $newVersion', name: _tag);
    if (oldVersion < 2) {
      await _createBuddyTable(db);
    }
  }

  Future<void> _createBuddyTable(Database db) async {
    await db.execute('''
      CREATE TABLE ecobuddy (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        hp REAL NOT NULL,
        lastCheck INTEGER NOT NULL,
        isAlive INTEGER NOT NULL
      )
    ''');
  }

  // ── Coordinates ───────────────────────────────────────────────────────────

  Future<void> insertCoordinate(CoordinateModel coord) async {
    final db = await _db;
    await db.insert(
      'coordinates',
      {
        'timestamp': coord.timestamp.millisecondsSinceEpoch,
        'latitude': coord.latitude,
        'longitude': coord.longitude,
        'altitude': coord.altitude,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CoordinateModel>> getCoordinates() async {
    final db = await _db;
    final rows = await db.query('coordinates', orderBy: 'timestamp ASC');
    return rows
        .map((r) => CoordinateModel(
              timestamp:
                  DateTime.fromMillisecondsSinceEpoch(r['timestamp'] as int),
              latitude: r['latitude'] as double,
              longitude: r['longitude'] as double,
              altitude: r['altitude'] as double,
            ))
        .toList();
  }

  Future<int> coordinateCount() async {
    final db = await _db;
    final result =
        await db.rawQuery('SELECT COUNT(*) AS c FROM coordinates');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ── Observations ──────────────────────────────────────────────────────────

  Future<void> insertObservation(ObservationModel obs) async {
    final db = await _db;
    await db.insert(
      'observations',
      {
        'timestamp': obs.timestamp.millisecondsSinceEpoch,
        'type': obs.type,
        'value': obs.value,
        'note': obs.note,
        'lat': obs.lat,
        'lon': obs.lon,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ObservationModel>> getObservations() async {
    final db = await _db;
    final rows = await db.query('observations', orderBy: 'timestamp DESC');
    return rows
        .map((r) => ObservationModel(
              timestamp:
                  DateTime.fromMillisecondsSinceEpoch(r['timestamp'] as int),
              type: r['type'] as String,
              value: r['value'] as String,
              note: r['note'] as String,
              lat: r['lat'] as String,
              lon: r['lon'] as String,
            ))
        .toList();
  }

  Future<int> observationCount() async {
    final db = await _db;
    final result =
        await db.rawQuery('SELECT COUNT(*) AS c FROM observations');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> clearObservations() async {
    final db = await _db;
    await db.delete('observations');
    developer.log('clearObservations: observations table cleared', name: _tag);
  }

  // ── EcoBuddy ──────────────────────────────────────────────────────────────

  Future<int> insertBuddy(EcoBuddyModel buddy) async {
    final db = await _db;
    final id = await db.insert('ecobuddy', _buddyToRow(buddy));
    developer.log('insertBuddy: ${buddy.name} (id=$id)', name: _tag);
    return id;
  }

  Future<void> updateBuddy(EcoBuddyModel buddy) async {
    final db = await _db;
    await db.update('ecobuddy', _buddyToRow(buddy),
        where: 'id = ?', whereArgs: [buddy.id]);
  }

  /// The most recently created living buddy, or null if none exists.
  Future<EcoBuddyModel?> getActiveBuddy() async {
    final db = await _db;
    final rows = await db.query(
      'ecobuddy',
      where: 'isAlive = 1',
      orderBy: 'createdAt DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return EcoBuddyModel(
      id: r['id'] as int,
      name: r['name'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(r['createdAt'] as int),
      hp: r['hp'] as double,
      lastCheck: DateTime.fromMillisecondsSinceEpoch(r['lastCheck'] as int),
      isAlive: (r['isAlive'] as int) == 1,
    );
  }

  Map<String, Object?> _buddyToRow(EcoBuddyModel b) => {
        'name': b.name,
        'createdAt': b.createdAt.millisecondsSinceEpoch,
        'hp': b.hp,
        'lastCheck': b.lastCheck.millisecondsSinceEpoch,
        'isAlive': b.isAlive ? 1 : 0,
      };
}
