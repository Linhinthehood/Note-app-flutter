// lib/providers/note_provider.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';
import '../helpers/db_helper.dart';

class NoteProvider with ChangeNotifier {
  List<Note> _notes = [];

  final dynamic _dbHelper; // Use dynamic to accept both types

  final DBHelper _dbHelper = DBHelper.instance;

  final Map<String, bool> _expandedSections = {};

  List<Note> get notes => _notes;
  Map<String, bool> get expandedSections => _expandedSections;

  // Regular constructor
  NoteProvider() : _dbHelper = DBHelper.instance {
    fetchNotes();
  } 

  // Test constructor
  NoteProvider.forTesting() : _dbHelper = _MockDBHelper() {
    _notes = [];
  }

  Future<void> fetchNotes() async {
    if (_dbHelper != null) {
      _notes = await _dbHelper!.getAllNotes();
      notifyListeners();
    }
  }

  Future<void> addNote(String title, String content) async {
    Note newNote = Note(
      title: title,
      content: content,
      createdAt: DateTime.now(),
      isPinned: false,
    );
    
    if (_dbHelper != null) {
      await _dbHelper!.insert(newNote);
      fetchNotes(); // Refresh the list from DB
    } else {
      // For testing - just add to memory
      _notes.add(newNote);
      notifyListeners();
    }
  }

  Future<void> updateNote(Note note) async {
    if (_dbHelper != null) {
      await _dbHelper!.update(note);
      fetchNotes(); // Refresh the list
    } else {
      // For testing - update in memory
      int index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = note;
        notifyListeners();
      }
    }
  }

  Future<void> deleteNote(int id) async {
    if (_dbHelper != null) {
      await _dbHelper!.delete(id);
      fetchNotes(); // Refresh the list
    } else {
      // For testing - remove from memory
      _notes.removeWhere((note) => note.id == id);
      notifyListeners();
    }
  }

  Future<void> togglePinNote(Note note) async {
    Note updatedNote = Note(
      id: note.id,
      title: note.title,
      content: note.content,
      createdAt: note.createdAt,
      isPinned: !note.isPinned,
    );
    await updateNote(updatedNote);
  }

  // Keep your existing groupedNotes, toggleSection, and isSectionExpanded methods unchanged
  Map<String, List<Note>> get groupedNotes {
    Map<String, List<Note>> grouped = {};
    List<Note> pinnedNotes = [];
    List<Note> unpinnedNotes = [];

    // Separate pinned and unpinned notes
    for (Note note in _notes) {
      if (note.isPinned) {
        pinnedNotes.add(note);
      } else {
        unpinnedNotes.add(note);
      }
    }

    // Create PINNED group if there are pinned notes
    if (pinnedNotes.isNotEmpty) {
      grouped['PINNED'] = pinnedNotes;
      // Initialize PINNED section as expanded if not set
      if (!_expandedSections.containsKey('PINNED')) {
        _expandedSections['PINNED'] = true;
      }
      // Sort pinned notes by creation date (newest first)
      pinnedNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    // Group unpinned notes by month
    for (Note note in unpinnedNotes) {
      String monthKey =
          DateFormat('MMM yyyy').format(note.createdAt).toUpperCase();
      if (!grouped.containsKey(monthKey)) {
        grouped[monthKey] = [];
        // Initialize section as expanded if not set
        if (!_expandedSections.containsKey(monthKey)) {
          _expandedSections[monthKey] = true;
        }
      }
      grouped[monthKey]!.add(note);
    }

    // Sort notes within each month group by creation date (newest first)
    grouped.forEach((key, notes) {
      if (key != 'PINNED') {
        notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    });

    return grouped;
  }

  void toggleSection(String monthKey) {
    _expandedSections[monthKey] = !(_expandedSections[monthKey] ?? true);
    notifyListeners();
  }

  bool isSectionExpanded(String monthKey) {
    return _expandedSections[monthKey] ?? true;
  }
}

// Remove the _MockDBHelper class entirely and replace with this:
abstract class DBHelperInterface {
  Future<List<Note>> getAllNotes();
  Future<int> insert(Note note);
  Future<int> update(Note note);
  Future<int> delete(int id);
}

class _MockDBHelper implements DBHelperInterface {
  @override
  Future<List<Note>> getAllNotes() async => [];
  
  @override
  Future<int> insert(Note note) async => 1;
  
  @override
  Future<int> update(Note note) async => 1;
  
  @override
  Future<int> delete(int id) async => 1;
}

