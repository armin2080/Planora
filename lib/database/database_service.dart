import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  static const _databaseName = 'planora.db';
  static const _databaseVersion = 7;
  Future<void> _createAttractionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE attractions_suggestions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        lat REAL,
        lng REAL,
        type TEXT,
        rating TEXT,
        url TEXT,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE
      )
    ''');
  }

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _databaseName);

    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );

    return _database!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE trips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        cover_photo_path TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await _createNotesTable(db);
    await _createPlacesTable(db);
    await _createDaysTable(db);
    await _createItineraryItemsTable(db);
    await _createDocumentsTable(db);
    await _createAttractionsTable(db);
    await _createIndexes(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createNotesTable(db);
    }

    if (oldVersion < 3) {
      await _createPlacesTable(db);
    }

    if (oldVersion < 4) {
      await _createDaysTable(db);
      await _createItineraryItemsTable(db);
    }

    if (oldVersion < 5) {
      await _createDocumentsTable(db);
    }

    if (oldVersion < 6) {
      await db.execute('ALTER TABLE trips ADD COLUMN cover_photo_path TEXT');
    }

    if (oldVersion < 7) {
      await _createAttractionsTable(db);
    }

    await _createIndexes(db);
  }

  Future<void> _createNotesTable(Database db) async {
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createPlacesTable(Database db) async {
    await db.execute('''
      CREATE TABLE places (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        lat REAL NOT NULL,
        lng REAL NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createDaysTable(Database db) async {
    await db.execute('''
      CREATE TABLE days (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        day_order INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createItineraryItemsTable(Database db) async {
    await db.execute('''
      CREATE TABLE itinerary_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL,
        day_id INTEGER NOT NULL,
        place_id INTEGER NOT NULL,
        position INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE,
        FOREIGN KEY (day_id) REFERENCES days (id) ON DELETE CASCADE,
        FOREIGN KEY (place_id) REFERENCES places (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createDocumentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL,
        file_path TEXT NOT NULL,
        type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_notes_trip_id ON notes(trip_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_places_trip_id ON places(trip_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_days_trip_id_order ON days(trip_id, day_order)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_itinerary_day_pos ON itinerary_items(day_id, position)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_documents_trip_created ON documents(trip_id, created_at)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_attractions_trip_id ON attractions_suggestions(trip_id)');
  }
}
