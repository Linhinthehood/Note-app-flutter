// lib/widgets/rich_text_editor.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'image_overlay_manager.dart';
import 'audio_overlay_manager.dart'; // Add this import
import 'highlighted_text.dart';

mixin ImageMetadataProvider {
  String saveImageMetadata(String text);
}

mixin AudioMetadataProvider {
  String saveAudioMetadata(String text);
}

class RichTextEditor extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String searchQuery;
  final Function(String) onImageRemove;
  final Function(String) onAudioRemove; // Add this parameter

  const RichTextEditor({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.searchQuery,
    required this.onImageRemove,
    required this.onAudioRemove, // Add this parameter
  });

  @override
  State<RichTextEditor> createState() => _RichTextEditorState();
  static _RichTextEditorState? of(BuildContext context) {
    return context.findAncestorStateOfType<_RichTextEditorState>();
  }
}

class _RichTextEditorState extends State<RichTextEditor> 
  with ImageMetadataProvider, AudioMetadataProvider {
  final ScrollController _scrollController = ScrollController();
  late TextEditingController _displayController;
  String _lastControllerText = '';
  late ImageOverlayManager _imageManager;
  late AudioOverlayManager _audioManager; // Add this

  @override
  void initState() {
    super.initState();
    _displayController = TextEditingController();
    _imageManager = ImageOverlayManager(
      onImageRemove: widget.onImageRemove,
      onStateChanged: () => setState(() {}),
      onMetadataChanged: _saveMetadataToController,
    );
    
    // Initialize audio manager
    _audioManager = AudioOverlayManager(
      onAudioRemove: widget.onAudioRemove,
      onStateChanged: () => setState(() {}),
      onMetadataChanged: _saveMetadataToController,
    );
    
    widget.controller.addListener(_onControllerChange);
    _updateDisplayController();
    _imageManager.initializeFromText(widget.controller.text);
    _audioManager.initializeFromText(widget.controller.text); // Add this
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    _displayController.dispose();
    _scrollController.dispose();
    _imageManager.dispose();
    _audioManager.dispose(); // Add this
    super.dispose();
  }

  void _saveMetadataToController() {
      final currentText = widget.controller.text;
      String updatedText = _imageManager.saveImageMetadata(currentText);
      updatedText = _audioManager.saveAudioMetadata(updatedText); // Make sure this is called
      
      if (currentText != updatedText) {
        widget.controller.removeListener(_onControllerChange);
        widget.controller.text = updatedText;
        _lastControllerText = updatedText;
        widget.controller.addListener(_onControllerChange);
      }
  }

  void _onControllerChange() {
    if (widget.controller.text != _lastControllerText) {
      _updateDisplayController();
      _imageManager.initializeFromText(widget.controller.text);
      _audioManager.initializeFromText(widget.controller.text); // Add this
      _lastControllerText = widget.controller.text;
    }
  }

  void _updateDisplayController() {
    final cleanText = widget.controller.text
        .replaceAll(RegExp(r'\[IMAGE:[^\]]+\]\n?'), '')
        .replaceAll(RegExp(r'\[IMAGE_META:[^\]]+\]\n?'), '')
        .replaceAll(RegExp(r'\[AUDIO:[^\]]+\]\n?'), '') // Add this
        .replaceAll(RegExp(r'\[AUDIO_META:[^\]]+\]\n?'), ''); // Add this
    
    if (_displayController.text != cleanText) {
      final selection = _displayController.selection;
      _displayController.text = cleanText;
      
      if (selection.baseOffset <= cleanText.length) {
        _displayController.selection = selection;
      } else {
        _displayController.selection = TextSelection.collapsed(offset: cleanText.length);
      }
    }
  }

  void _onDisplayTextChanged(String value) {
    final RegExp imageRegex = RegExp(r'\[IMAGE:([^\]]+)\]');
    final RegExp audioRegex = RegExp(r'\[AUDIO:([^\]]+)\]'); // Add this
    
    final existingImages = imageRegex.allMatches(widget.controller.text)
        .map((match) => match.group(0)!)
        .toList();
        
    final existingAudios = audioRegex.allMatches(widget.controller.text) // Add this
        .map((match) => match.group(0)!)
        .toList();
    
    String newText = value;
    for (String imageTag in existingImages) {
      newText += '\n$imageTag';
    }
    for (String audioTag in existingAudios) { // Add this
      newText += '\n$audioTag';
    }
    
    _lastControllerText = newText;
    widget.controller.text = newText;
  }

  void _handleTapOutside() {
    _imageManager.deselectAll();
    _audioManager.deselectAll(); // Add this
  }

  @override
  String saveImageMetadata(String text) {
    return _imageManager.saveImageMetadata(text);
  }

  @override
  String saveAudioMetadata(String text) { // Add this method
    return _audioManager.saveAudioMetadata(text);
  }

  // Add method to add audio from outside
  void addAudio(String audioPath) {
    _audioManager.addAudio(audioPath);
  }

  @override
Widget build(BuildContext context) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: CupertinoColors.separator.resolveFrom(context),
        width: 0.5,
      ),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        _imageManager.updateContainerSize(Size(constraints.maxWidth, constraints.maxHeight));
        _audioManager.updateContainerSize(Size(constraints.maxWidth, constraints.maxHeight));
        
        return GestureDetector(
          onTap: _handleTapOutside,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Container(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 24, // Reduced padding
              ),
              padding: const EdgeInsets.all(12), // Reduced padding
              child: Stack(
                children: [
                  // Text input area
                  Column(
                    children: [
                      Stack(
                        children: [
                          // Background text field for editing
                          CupertinoTextField(
                            controller: _displayController,
                            focusNode: widget.focusNode,
                            placeholder: 'Start typing your note...',
                            maxLines: null,
                            minLines: 20, // Increased minLines for larger text area
                            style: TextStyle(
                              fontSize: 16,
                              color: widget.searchQuery.isNotEmpty 
                                  ? Colors.transparent 
                                  : null,
                            ),
                            decoration: const BoxDecoration(
                              color: Colors.transparent,
                            ),
                            padding: EdgeInsets.zero,
                            onChanged: _onDisplayTextChanged,
                          ),
                          
                          // Overlay highlighted text when searching
                          if (widget.searchQuery.isNotEmpty)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: HighlightedText(
                                    text: _displayController.text.isEmpty 
                                        ? 'Start typing your note...' 
                                        : _displayController.text,
                                    searchQuery: widget.searchQuery,
                                    textStyle: TextStyle(
                                      fontSize: 16,
                                      color: _displayController.text.isEmpty
                                          ? CupertinoColors.placeholderText.resolveFrom(context)
                                          : CupertinoColors.label.resolveFrom(context),
                                    ),
                                    highlightStyle: TextStyle(
                                      backgroundColor: CupertinoColors.systemYellow.withOpacity(0.3),
                                      color: CupertinoColors.label.resolveFrom(context),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  
                  // Images positioned within the scrollable content
                  ..._imageManager.buildImageOverlays(context, widget.controller.text),
                  
                  // Audio players positioned within the scrollable content
                  ..._audioManager.buildAudioOverlays(context, widget.controller.text),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
}