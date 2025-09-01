// lib/providers/note_provider.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';
import '../helpers/db_helper.dart';

class NoteProvider with ChangeNotifier {
  List<Note> _notes = [];
  final DBHelper _dbHelper = DBHelper.instance;
  final Map<String, bool> _expandedSections = {};

  List<Note> get notes => _notes;
  Map<String, bool> get expandedSections => _expandedSections;

  NoteProvider() {
    fetchNotes();
  }

  Future<void> fetchNotes() async {
    _notes = await _dbHelper.getAllNotes();
    notifyListeners();
  }

  Future<void> addNote(String title, String content) async {
    Note newNote = Note(
      title: title,
      content: content,
      createdAt: DateTime.now(),
      isPinned: false,
    );
    await _dbHelper.insert(newNote);
    fetchNotes(); // Refresh the list from DB
  }

  Future<void> updateNote(Note note) async {
    await _dbHelper.update(note);
    fetchNotes(); // Refresh the list
  }

  Future<void> deleteNote(int id) async {
    await _dbHelper.delete(id);
    fetchNotes(); // Refresh the list
  }

  Future<void> togglePinNote(Note note) async {
    Note updatedNote = Note(
      id: note.id,
      title: note.title,
      content: note.content,
      createdAt: note.createdAt,
      isPinned: !note.isPinned,
    );
    await _dbHelper.update(updatedNote);
    fetchNotes(); // Refresh the list
  }

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
      String monthKey = DateFormat('MMM yyyy').format(note.createdAt).toUpperCase();
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