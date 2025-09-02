import 'package:flutter/cupertino.dart';

class HighlightedText extends StatelessWidget {
  final String text;
  final String searchQuery;
  final TextStyle? textStyle;
  final TextStyle? highlightStyle;

  const HighlightedText({
    super.key,
    required this.text,
    required this.searchQuery,
    this.textStyle,
    this.highlightStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (searchQuery.isEmpty) {
      return Text(text, style: textStyle);
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
          style: textStyle,
        ));
      }
      
      // Add highlighted match
      spans.add(TextSpan(
        text: text.substring(index, index + searchQuery.length),
        style: highlightStyle ?? TextStyle(
          backgroundColor: CupertinoColors.systemYellow.withOpacity(0.3),
          color: CupertinoColors.label,
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
        style: textStyle,
      ));
    }
    
    return RichText(
      text: TextSpan(children: spans),
    );
  }
}