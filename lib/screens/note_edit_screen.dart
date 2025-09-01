// lib/screens/note_edit_screen.dart
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/note_provider.dart';

class NoteEditScreen extends StatefulWidget {
  const NoteEditScreen({super.key, this.note});
  final Note? note;
  
  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
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
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
    }
    
    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
    
    _periodicSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_hasUnsavedChanges) {
        _saveNote();
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _periodicSaveTimer?.cancel();
    _titleController.removeListener(_onTextChanged);
    _contentController.removeListener(_onTextChanged);
    _titleController.dispose();
    _contentController.dispose();
    
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
    
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      _saveNote();
    });
  }

  Future<void> _saveNote() async {
    if (_isSaving) return;
    
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    
    if (title.isEmpty && content.isEmpty) {
      setState(() {
        _hasUnsavedChanges = false;
      });
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final finalTitle = title.isEmpty ? 'Untitled Note' : title;

    try {
      final noteProvider = Provider.of<NoteProvider>(context, listen: false);

      if (_currentNote == null) {
        await noteProvider.addNote(finalTitle, content);
        await noteProvider.fetchNotes();
        _currentNote = noteProvider.notes.firstWhere(
          (note) => note.title == finalTitle && note.content == content,
          orElse: () => Note(
            title: finalTitle,
            content: content,
            createdAt: DateTime.now(),
            isPinned: false,
          ),
        );
      } else {
        Note updatedNote = Note(
          id: _currentNote!.id,
          title: finalTitle,
          content: content,
          createdAt: _currentNote!.createdAt,
          isPinned: _currentNote!.isPinned,
        );
        await noteProvider.updateNote(updatedNote);
        _currentNote = updatedNote;
      }

      if (mounted) {
        setState(() {
          _hasUnsavedChanges = false;
          _isSaving = false;
        });
      }
    } catch (error) {
      print('Save error: $error');
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
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
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _goBack,
          child: const Icon(CupertinoIcons.back),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _hasUnsavedChanges ? () => _saveNote() : null,
          child: Text(
            'Save',
            style: TextStyle(
              color: _hasUnsavedChanges 
                  ? CupertinoColors.activeBlue 
                  : CupertinoColors.secondaryLabel.resolveFrom(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: CupertinoTextField(
                controller: _titleController,
                placeholder: 'Note title',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: CupertinoTextField(
                  controller: _contentController,
                  placeholder: 'Start typing your note...',
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(fontSize: 16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground.resolveFrom(context),
                  ),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isSaving) ...[
                    const CupertinoActivityIndicator(),
                    const SizedBox(width: 8),
                    Text(
                      'Saving...',
                      style: TextStyle(
                        color: CupertinoColors.secondaryLabel.resolveFrom(context),
                        fontSize: 14,
                      ),
                    ),
                  ] else if (_hasUnsavedChanges) ...[
                    const Icon(
                      CupertinoIcons.circle_fill,
                      size: 8,
                      color: CupertinoColors.systemOrange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Unsaved changes',
                      style: TextStyle(
                        color: CupertinoColors.systemOrange,
                        fontSize: 14,
                      ),
                    ),
                  ] else if (_titleController.text.isNotEmpty || _contentController.text.isNotEmpty) ...[
                    const Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      size: 16,
                      color: CupertinoColors.systemGreen,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'All changes saved',
                      style: TextStyle(
                        color: CupertinoColors.systemGreen,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}