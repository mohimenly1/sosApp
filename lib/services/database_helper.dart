import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'resqtrack.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createTables(db);
    }
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS alerts (
        id TEXT PRIMARY KEY,
        title TEXT,
        description TEXT,
        disasterType TEXT,
        location_lat REAL,
        location_lon REAL,
        timestamp TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS rescue_teams (
        id TEXT PRIMARY KEY,
        name TEXT,
        membersCount INTEGER,
        assignedRouteId TEXT,
        creatorId TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS evacuation_routes (
        id TEXT PRIMARY KEY,
        startPoint_lat REAL,
        startPoint_lon REAL,
        endPoint_lat REAL,
        endPoint_lon REAL,
        safetyLevel INTEGER,
        isOfflineAvailable INTEGER
      )
    ''');
    // NEW: Add medical_files table creation here as well
    await db.execute('''
      CREATE TABLE IF NOT EXISTS medical_files (
        id TEXT PRIMARY KEY,
        ownerId TEXT,
        bloodType TEXT,
        chronicDiseases TEXT,
        allergies TEXT,
        emergencyContact TEXT,
        lastUpdated TEXT
      )
    ''');
  }

  // --- Methods for 'alerts' table ---
  Future<void> insertAlert(Map<String, dynamic> alert) async {
    final db = await database;
    await db.insert('alerts', alert,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllAlerts() async {
    final db = await database;
    return await db.query('alerts', orderBy: 'timestamp DESC');
  }

  Future<void> clearAlerts() async {
    final db = await database;
    await db.delete('alerts');
  }

  // --- Methods for 'rescue_teams' table ---
  Future<void> insertRescueTeam(Map<String, dynamic> team) async {
    final db = await database;
    await db.insert('rescue_teams', team,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getMyRescueTeams(String creatorId) async {
    final db = await database;
    return await db
        .query('rescue_teams', where: 'creatorId = ?', whereArgs: [creatorId]);
  }

  // NEW: Get a single team by its ID
  Future<Map<String, dynamic>?> getTeamById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('rescue_teams', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<void> clearRescueTeams() async {
    final db = await database;
    await db.delete('rescue_teams');
  }

  // --- Methods for 'evacuation_routes' table ---
  Future<void> insertEvacuationRoute(Map<String, dynamic> route) async {
    final db = await database;
    await db.insert('evacuation_routes', route,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // NEW: Get a single route by its ID
  Future<Map<String, dynamic>?> getRouteById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('evacuation_routes', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<void> clearEvacuationRoutes() async {
    final db = await database;
    await db.delete('evacuation_routes');
  }

  // --- NEW: Methods for 'medical_files' table ---
  Future<void> insertMedicalFile(Map<String, dynamic> file) async {
    final db = await database;
    await db.insert('medical_files', file,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getMedicalFileByOwnerId(String ownerId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db
        .query('medical_files', where: 'ownerId = ?', whereArgs: [ownerId]);
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<void> clearMedicalFiles() async {
    final db = await database;
    await db.delete('medical_files');
  }
}
