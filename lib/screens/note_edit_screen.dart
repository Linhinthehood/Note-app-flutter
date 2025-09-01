// lib/screens/note_edit_screen.dart
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/note_provider.dart';

class NoteEditScreen extends StatefulWidget {
  const NoteEditScreen({super.key, this.note});
  final Note? note; // Make it nullable
  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  final _textController = TextEditingController();
  Timer? _debounceTimer;
  Timer? _periodicSaveTimer;
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;
  Note? _currentNote;

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
    if (widget.note != null) {
      _textController.text = '${widget.note!.title}\n${widget.note!.content}';
    }

    // Listen to text changes for auto-save
    _textController.addListener(_onTextChanged);

    // Set up periodic save timer (every 30 seconds)
    _periodicSaveTimer = Timer.periodic(Duration(seconds: 30), (_) {
      if (_hasUnsavedChanges) {
        _saveNote();
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _periodicSaveTimer?.cancel();
    _textController.removeListener(_onTextChanged);
    _textController.dispose();

    // Save any pending changes before disposing
    if (_hasUnsavedChanges) {
      _saveNote();
    }

    super.dispose();
  }

  void _onTextChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }

    // Cancel previous timer and start a new one (debounce)
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(seconds: 2), () {
      _saveNote();
    });
  }

  Future<void> _saveNote() async {
    if (_isSaving) return;

    final fullText = _textController.text.trim();

    // Don't save if text is empty
    if (fullText.isEmpty) {
      setState(() {
        _hasUnsavedChanges = false;
      });
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final newlineIndex = fullText.indexOf('\n');
    String title;
    String content;

    if (newlineIndex != -1) {
      title = fullText.substring(0, newlineIndex).trim();
      content = fullText.substring(newlineIndex + 1).trim();
    } else {
      title = fullText.trim();
      content = "";
    }

    // Use a default title if empty
    if (title.isEmpty) {
      title = 'Untitled Note';
    }

    try {
      final noteProvider = Provider.of<NoteProvider>(context, listen: false);

      if (_currentNote == null) {
        // Creating a new note
        Note newNote = Note(
          title: title,
          content: content,
          createdAt: DateTime.now(),
          isPinned: false,
        );
        await noteProvider.addNote(title, content);

        // Update current note reference for future saves
        // We need to get the newly created note from the provider
        await noteProvider.fetchNotes();
        _currentNote = noteProvider.notes.firstWhere(
          (note) => note.title == title && note.content == content,
          orElse: () => newNote,
        );
      } else {
        // Updating existing note
        Note updatedNote = Note(
          id: _currentNote!.id,
          title: title,
          content: content,
          createdAt: _currentNote!.createdAt,
          isPinned: _currentNote!.isPinned,
        );
        await noteProvider.updateNote(updatedNote);
        _currentNote = updatedNote;
      }

      setState(() {
        _hasUnsavedChanges = false;
        _isSaving = false;
      });
    } catch (error) {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _goBack() async {
    if (_hasUnsavedChanges) {
      await _saveNote();
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_currentNote == null ? 'New Note' : 'Edit Note'),
        leading: // Fixed (move child to the end):
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _goBack,
              child: const Icon(CupertinoIcons.back),  // child is now last
            )
      ),
      backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: SafeArea(
          child: CupertinoTextField(
            controller: _textController,
            autofocus: true,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: TextStyle(fontSize: 18),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground
                  .resolveFrom(context), // Adapts to light/dark mode
            ),
          ),
        ),
      ),
    );
  }
}
