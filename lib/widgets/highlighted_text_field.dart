import 'package:flutter/cupertino.dart';


class HighlightedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String searchQuery;
  final String placeholder;
  final TextStyle? style;
  final EdgeInsets? padding;

  const HighlightedTextField({
    super.key,
    required this.controller,
    required this.searchQuery,
    required this.placeholder,
    this.style,
    this.padding,
  });

  @override
  State<HighlightedTextField> createState() => _HighlightedTextFieldState();
}

class _HighlightedTextFieldState extends State<HighlightedTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  TextSpan _buildHighlightedTextSpan(String text, String searchQuery) {
    if (searchQuery.isEmpty || text.isEmpty) {
      return TextSpan(
        text: text,
        style: widget.style,
      );
    }

    final List<TextSpan> spans = [];
    final String lowerCaseText = text.toLowerCase();
    final String lowerCaseQuery = searchQuery.toLowerCase();
    
    int start = 0;
    int index = lowerCaseText.indexOf(lowerCaseQuery);
    
    while (index != -1) {
      // Add text before match
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: widget.style,
        ));
      }
      
      // Add highlighted match
      spans.add(TextSpan(
        text: text.substring(index, index + searchQuery.length),
        style: widget.style?.copyWith(
          backgroundColor: CupertinoColors.systemYellow.withOpacity(0.4),
          fontWeight: FontWeight.bold,
        ) ?? TextStyle(
          backgroundColor: CupertinoColors.systemYellow.withOpacity(0.4),
          fontWeight: FontWeight.bold,
        ),
      ));
      
      start = index + searchQuery.length;
      index = lowerCaseText.indexOf(lowerCaseQuery, start);
    }
    
    // Add remaining text
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: widget.style,
      ));
    }
    
    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Highlighted text background
        if (widget.searchQuery.isNotEmpty && widget.controller.text.isNotEmpty && !_isFocused)
          Positioned.fill(
            child: Container(
              padding: widget.padding ?? const EdgeInsets.all(8),
              child: RichText(
                text: _buildHighlightedTextSpan(widget.controller.text, widget.searchQuery),
                maxLines: null,
              ),
            ),
          ),
        
        // Actual text field
        CupertinoTextField(
          controller: widget.controller,
          focusNode: _focusNode,
          placeholder: widget.placeholder,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          style: widget.style?.copyWith(
            // Make text semi-transparent when showing highlights and not focused
            color: (widget.searchQuery.isNotEmpty && !_isFocused)
                ? widget.style?.color?.withOpacity(0.3) ?? CupertinoColors.label.withOpacity(0.3)
                : widget.style?.color ?? CupertinoColors.label,
          ),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
          ),
          padding: widget.padding ?? const EdgeInsets.all(8),
        ),
      ],
    );
  }
}