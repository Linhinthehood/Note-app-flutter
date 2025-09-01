// lib/screens/note_edit_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
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
  final _contentSearchController = TextEditingController();
  Timer? _debounceTimer;
  Timer? _periodicSaveTimer;
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;
  bool _showContentSearch = false;
  Note? _currentNote;
  List<String> _imagePaths = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _imagePaths = List.from(widget.note!.imagePaths);
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
    _contentSearchController.dispose();
    
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
    
    if (title.isEmpty && content.isEmpty && _imagePaths.isEmpty) {
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
        Note newNote = Note(
          title: finalTitle,
          content: content,
          createdAt: DateTime.now(),
          isPinned: false,
          imagePaths: _imagePaths,
        );
        await noteProvider.addNoteWithMedia(newNote);
        await noteProvider.fetchNotes();
        _currentNote = noteProvider.notes.firstWhere(
          (note) => note.title == finalTitle && note.content == content,
          orElse: () => newNote,
        );
      } else {
        Note updatedNote = Note(
          id: _currentNote!.id,
          title: finalTitle,
          content: content,
          createdAt: _currentNote!.createdAt,
          isPinned: _currentNote!.isPinned,
          imagePaths: _imagePaths,
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
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Add Image'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _getImage(ImageSource.camera);
            },
            child: const Text('Take Photo'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _getImage(ImageSource.gallery);
            },
            child: const Text('Choose from Gallery'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      // Copy image to app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final String fileName = 'note_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String newPath = '${directory.path}/$fileName';
      await File(image.path).copy(newPath);
      
      setState(() {
        _imagePaths.add(newPath);
        _hasUnsavedChanges = true;
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
      _hasUnsavedChanges = true;
    });
  }

  void _toggleContentSearch() {
    setState(() {
      _showContentSearch = !_showContentSearch;
      if (!_showContentSearch) {
        _contentSearchController.clear();
      }
    });
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
        middle: Text(_currentNote == null ? 'NewNotes' : 'Edit Note'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _goBack,
          child: const Icon(CupertinoIcons.back),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _toggleContentSearch,
              child: Icon(
                _showContentSearch ? CupertinoIcons.search_circle_fill : CupertinoIcons.search,
                color: _showContentSearch ? CupertinoColors.activeBlue : null,
              ),
            ),
            CupertinoButton(
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
          ],
        ),
      ),
      backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
      child: SafeArea(
        child: Column(
          children: [
            // Title field
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

            // Content search bar (when enabled)
            if (_showContentSearch)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CupertinoSearchTextField(
                  controller: _contentSearchController,
                  placeholder: 'Search in note content...',
                  onChanged: (value) {
                    // Highlight matching text in content
                    setState(() {});
                  },
                ),
              ),
            
            // Content field
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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

            // Images section
            if (_imagePaths.isNotEmpty)
              Container(
                height: 120,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imagePaths.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_imagePaths[index]),
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.destructiveRed,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  CupertinoIcons.xmark,
                                  color: CupertinoColors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            // Media and action buttons
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CupertinoButton(
                    onPressed: _pickImage,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.camera),
                        const SizedBox(height: 4),
                        Text('Image', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  CupertinoButton(
                    onPressed: () {
                      Navigator.of(context).push(CupertinoPageRoute(
                        builder: (context) => const NoteEditScreen(),
                      ));
                    },
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.add_circled),
                        SizedBox(height: 4),
                        Text('New Note', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Status indicator
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
                    const Text(
                      'Unsaved changes',
                      style: TextStyle(
                        color: CupertinoColors.systemOrange,
                        fontSize: 14,
                      ),
                    ),
                  ] else if (_titleController.text.isNotEmpty || _contentController.text.isNotEmpty || _imagePaths.isNotEmpty) ...[
                    const Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      size: 16,
                      color: CupertinoColors.systemGreen,
                    ),
                    const SizedBox(width: 8),
                    const Text(
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