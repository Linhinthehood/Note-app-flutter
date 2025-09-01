import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note.dart';

class DBHelper {
  static const _databaseName = "NotesDatabase.db";
  static const _databaseVersion = 2;

  static const table = 'notes_table';

  static const columnId = 'id';
  static const columnTitle = 'title';
  static const columnContent = 'content';
  static const columnCreatedAt = 'createdAt';
  static const columnIsPinned = 'isPinned';

  // Make this a singleton class.
  DBHelper._privateConstructor();
  static final DBHelper instance = DBHelper._privateConstructor();

  // Only have a single app-wide reference to the database.
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // SQL code to create the database table.
  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnTitle TEXT NOT NULL,
            $columnContent TEXT NOT NULL,
            $columnCreatedAt TEXT NOT NULL,
            $columnIsPinned INTEGER NOT NULL DEFAULT 0
          )''');
  }

  // Handle database upgrade
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Check if column already exists before adding it
      final result = await db.rawQuery("PRAGMA table_info($table)");
      final columnExists =
          result.any((column) => column['name'] == columnIsPinned);

      if (!columnExists) {
        await db.execute(
            'ALTER TABLE $table ADD COLUMN $columnIsPinned INTEGER NOT NULL DEFAULT 0');
      }
    }
  }

  // Helper methods.
  // Inserts a row in the database where each key in the Map is a column name
  // and the value is the column value. The return value is the id of the
  // inserted row.
  Future<int> insert(Note note) async {
    Database db = await instance.database;
    return await db.insert(table, note.toMap());
  }

  // All of the rows are returned as a list of maps, where each map is
  // a key-value list of columns. Pinned notes are shown first, then sorted by creation date.
  Future<List<Note>> getAllNotes() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(table,
        orderBy: "$columnIsPinned DESC, $columnCreatedAt DESC");
    return List.generate(maps.length, (i) {
      return Note.fromMap(maps[i]);
    });
  }

  // We are assuming here that the id column in the map is set. The other
  // column values will be used to update the row.
  Future<int> update(Note note) async {
    Database db = await instance.database;
    return await db.update(
      table,
      note.toMap(),
      where: '$columnId = ?',
      whereArgs: [note.id],
    );
  }

  // Deletes the row specified by the id. The number of affected rows is
  // returned. This should be 1 as long as the row exists.
  Future<int> delete(int id) async {
    Database db = await instance.database;
    return await db.delete(
      table,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }
}
