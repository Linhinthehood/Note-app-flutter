// lib/widgets/rich_text_editor.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'image_overlay_manager.dart';
import 'highlighted_text.dart';

mixin ImageMetadataProvider {
  String saveImageMetadata(String text);
}

class RichTextEditor extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String searchQuery;
  final Function(String) onImageRemove;

  const RichTextEditor({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.searchQuery,
    required this.onImageRemove,
  });

  @override
  State<RichTextEditor> createState() => _RichTextEditorState();
}

class _RichTextEditorState extends State<RichTextEditor> with ImageMetadataProvider {
  final ScrollController _scrollController = ScrollController();
  late TextEditingController _displayController;
  String _lastControllerText = '';
  late ImageOverlayManager _imageManager;

  @override
  void initState() {
    super.initState();
    _displayController = TextEditingController();
    _imageManager = ImageOverlayManager(
      onImageRemove: widget.onImageRemove,
      onStateChanged: () => setState(() {}),
      onMetadataChanged: _saveMetadataToController,
      
    );
    widget.controller.addListener(_onControllerChange);
    _updateDisplayController();
    _imageManager.initializeFromText(widget.controller.text);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    _displayController.dispose();
    _scrollController.dispose();
    _imageManager.dispose();
    super.dispose();
  }

  void _saveMetadataToController() {
    final currentText = widget.controller.text;
    final updatedText = _imageManager.saveImageMetadata(currentText);
    
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
      _lastControllerText = widget.controller.text;
    }
  }

  void _updateDisplayController() {
    final cleanText = widget.controller.text
        .replaceAll(RegExp(r'\[IMAGE:[^\]]+\]\n?'), '')
        .replaceAll(RegExp(r'\[IMAGE_META:[^\]]+\]\n?'), '');
    
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
    final existingImages = imageRegex.allMatches(widget.controller.text)
        .map((match) => match.group(0)!)
        .toList();
    
    String newText = value;
    for (String imageTag in existingImages) {
      newText += '\n$imageTag';
    }
    
    _lastControllerText = newText;
    widget.controller.text = newText;
  }

  void _handleTapOutside() {
    _imageManager.deselectAll();
  }

  @override
  String saveImageMetadata(String text) {
    return _imageManager.saveImageMetadata(text);
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
          
          return GestureDetector(
            onTap: _handleTapOutside,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Container(
                // Set a minimum height to allow for proper scrolling
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 24, // Account for padding
                ),
                padding: const EdgeInsets.all(12),
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
                              minLines: 15,
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