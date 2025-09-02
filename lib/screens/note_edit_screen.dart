// lib/screens/note_edit_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/note.dart';
import '../providers/note_provider.dart';

import '../widgets/rich_text_editor.dart';

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
  final FocusNode _contentFocusNode = FocusNode();
  Timer? _debounceTimer;
  Timer? _periodicSaveTimer;
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;
  bool _showContentSearch = false;
  Note? _currentNote;
  List<String> _imagePaths = [];
  final ImagePicker _picker = ImagePicker();
  
  // Key to access the RichTextEditor's functionality
  final GlobalKey<State<RichTextEditor>> _editorKey = GlobalKey<State<RichTextEditor>>();

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

  int _getMatchCount() {
    if (_contentSearchController.text.isEmpty || _contentController.text.isEmpty) {
      return 0;
    }
    
    final text = _contentController.text.toLowerCase();
    final query = _contentSearchController.text.toLowerCase();
    int count = 0;
    int index = text.indexOf(query);
    
    while (index != -1) {
      count++;
      index = text.indexOf(query, index + 1);
    }
    
    return count;
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
    _contentFocusNode.dispose();
    
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
    _debounceTimer = Timer(const Duration(milliseconds: 500), () { // Shorter delay for metadata
      _saveNote();
    });
  }

  Future<void> _saveNote() async {
    if (_isSaving) return;
    
    final title = _titleController.text.trim();
    var content = _contentController.text.trim();
    
    // Save image metadata before processing content
    final editorState = _editorKey.currentState;
    if (editorState != null && editorState is ImageMetadataProvider) {
      content = (editorState as ImageMetadataProvider).saveImageMetadata(content);
    }
    
    // Extract image paths from content
    final imagePattern = RegExp(r'\[IMAGE:([^\]]+)\]');
    final matches = imagePattern.allMatches(content);
    _imagePaths = matches.map((match) => match.group(1)!).toList();
    
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
          content: content, // This now includes image metadata
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
          content: content, // This now includes image metadata
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
    List<CupertinoActionSheetAction> actions = [];
    
    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      actions.add(
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
            _getImage(ImageSource.camera);
          },
          child: const Text('Take Photo'),
        ),
      );
    }
    
    actions.add(
      CupertinoActionSheetAction(
        onPressed: () {
          Navigator.pop(context);
          _getImage(ImageSource.gallery);
        },
        child: const Text('Choose from Gallery'),
      ),
    );

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Add Image'),
        actions: actions,
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        final directory = await getApplicationDocumentsDirectory();
        final String fileName = 'note_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String newPath = '${directory.path}/$fileName';
        await File(image.path).copy(newPath);
        
        _insertImageAtCursor(newPath);
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to pick image: ${e.toString()}'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  void _insertImageAtCursor(String imagePath) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    
    int cursorPosition = selection.baseOffset;
    if (cursorPosition < 0 || cursorPosition > text.length) {
      cursorPosition = text.length;
    }
    
    final imageTag = '[IMAGE:$imagePath]\n';
    final newText = text.replaceRange(cursorPosition, cursorPosition, imageTag);
    
    setState(() {
      _contentController.text = newText;
      _contentController.selection = TextSelection.collapsed(
        offset: cursorPosition + imageTag.length,
      );
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
      navigationBar: _buildNavigationBar(),
      backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
      child: SafeArea(
        child: Column(
          children: [
            _buildTitleField(),
            _buildContentSearchBar(),
            _buildContentSection(),
            _buildActionButtons(),
            _buildStatusIndicator(),
          ],
        ),
      ),
    );
  }

  CupertinoNavigationBar _buildNavigationBar() {
    return CupertinoNavigationBar(
      middle: Text(_currentNote == null ? 'New Note' : 'Edit Note'),
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _goBack,
        child: const Icon(CupertinoIcons.back),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSearchButton(),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildSearchButton() {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _toggleContentSearch,
      child: Icon(
        _showContentSearch ? CupertinoIcons.search_circle_fill : CupertinoIcons.search,
        color: _showContentSearch ? CupertinoColors.activeBlue : null,
      ),
    );
  }

  Widget _buildSaveButton() {
    return CupertinoButton(
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
    );
  }

  Widget _buildTitleField() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: CupertinoTextField(
        controller: _titleController,
        placeholder: 'Note title',
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
    );
  }

  Widget _buildContentSearchBar() {
    if (!_showContentSearch) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          CupertinoSearchTextField(
            controller: _contentSearchController,
            placeholder: 'Search in note content...',
            onChanged: (value) => setState(() {}),
            onSuffixTap: () {
              _contentSearchController.clear();
              setState(() {});
            },
          ),
          if (_contentSearchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${_getMatchCount()} matches found',
                style: TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: RichTextEditor(
          key: _editorKey, // This key allows us to access the editor's state
          controller: _contentController,
          focusNode: _contentFocusNode,
          searchQuery: _showContentSearch ? _contentSearchController.text : '',
          onImageRemove: (imagePath) {
            setState(() {
              var text = _contentController.text;
              text = text
                  .replaceAll('[IMAGE:$imagePath]\n', '')
                  .replaceAll('[IMAGE:$imagePath]', '');
              
              // Also update metadata after removing image
              final editorState = _editorKey.currentState;
              if (editorState != null && editorState is ImageMetadataProvider) {
                text = (editorState as ImageMetadataProvider).saveImageMetadata(text);
              }
              
              _contentController.text = text;
              _hasUnsavedChanges = true;
            });
          },
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: CupertinoIcons.camera,
            label: 'Image',
            onPressed: _pickImage,
          ),
          _buildActionButton(
            icon: CupertinoIcons.add_circled,
            label: 'New Note',
            onPressed: () => Navigator.of(context).push(
              CupertinoPageRoute(builder: (context) => const NoteEditScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return CupertinoButton(
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
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
            const Icon(CupertinoIcons.circle_fill, size: 8, color: CupertinoColors.systemOrange),
            const SizedBox(width: 8),
            const Text('Unsaved changes', style: TextStyle(color: CupertinoColors.systemOrange, fontSize: 14)),
          ] else if (_titleController.text.isNotEmpty || _contentController.text.isNotEmpty || _imagePaths.isNotEmpty) ...[
            const Icon(CupertinoIcons.checkmark_circle_fill, size: 16, color: CupertinoColors.systemGreen),
            const SizedBox(width: 8),
            const Text('All changes saved', style: TextStyle(color: CupertinoColors.systemGreen, fontSize: 14)),
          ],
        ],
      ),
    );
  }
}