import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';

class DBHelper {
  static const String _notesKey = 'notes_list';
  static const String _counterKey = 'note_counter';
  
  static final DBHelper instance = DBHelper._privateConstructor();
  DBHelper._privateConstructor();


  Future<List<Note>> getAllNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getStringList(_notesKey) ?? [];
    
    return notesJson.map((noteStr) {
      final noteMap = json.decode(noteStr) as Map<String, dynamic>;
      return Note.fromMap(noteMap);
    }).toList()..sort((a, b) {
      // Sort: pinned first, then by creation date (newest first)
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.createdAt.compareTo(a.createdAt);

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

  Future<int> insert(Note note) async {
    final notes = await getAllNotes();
    final prefs = await SharedPreferences.getInstance();
    
    // Generate new ID
    final counter = prefs.getInt(_counterKey) ?? 0;
    final newId = counter + 1;
    await prefs.setInt(_counterKey, newId);
    
    final noteWithId = Note(
      id: newId,
      title: note.title,
      content: note.content,
      createdAt: note.createdAt,
      isPinned: note.isPinned,
    );
    
    notes.add(noteWithId);
    await _saveNotes(notes);
    return newId;
  }

  Future<int> update(Note note) async {
    final notes = await getAllNotes();
    final index = notes.indexWhere((n) => n.id == note.id);
    
    if (index != -1) {
      notes[index] = note;
      await _saveNotes(notes);
      return 1;
    }
    return 0;
  }

  Future<int> delete(int id) async {

    final notes = await getAllNotes();
    final initialLength = notes.length;
    notes.removeWhere((note) => note.id == id);
    
    await _saveNotes(notes);
    return initialLength - notes.length;
  }

  Future<void> _saveNotes(List<Note> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = notes.map((note) => json.encode(note.toMap())).toList();
    await prefs.setStringList(_notesKey, notesJson);

    Database db = await instance.database;
    return await db.delete(
      table,
      where: '$columnId = ?',
      whereArgs: [id],
    );

  }
}
