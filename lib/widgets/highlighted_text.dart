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

  // Helper method to clean text from metadata tags
  String _cleanText(String text) {
    // Remove all image and audio tags and metadata
    return text
        .replaceAll(RegExp(r'\[IMAGE:[^\]]+\]\n?'), '')
        .replaceAll(RegExp(r'\[IMAGE_META:[^\]]+\]\n?'), '')
        .replaceAll(RegExp(r'\[AUDIO:[^\]]+\]\n?'), '') // Add this
        .replaceAll(RegExp(r'\[AUDIO_META:[^\]]+\]\n?'), '')
        .replaceAll(RegExp(r'\[TODO_META:[^\]]+\]\n?'), '')
        .trim(); // Remove extra whitespace
  }

  @override
  Widget build(BuildContext context) {
    // Clean the text before searching
    final String cleanText = _cleanText(text);

    if (searchQuery.isEmpty || cleanText.isEmpty) {
      return Text(cleanText, style: textStyle);
    }

    final List<TextSpan> spans = [];
    final String lowerCaseText = cleanText.toLowerCase();
    final String lowerCaseQuery = searchQuery.toLowerCase();

    int start = 0;
    int index = lowerCaseText.indexOf(lowerCaseQuery);

    while (index != -1) {
      // Add text before match
      if (index > start) {
        spans.add(TextSpan(
          text: cleanText.substring(start, index),
          style: textStyle,
        ));
      }

      // Add highlighted match
      spans.add(TextSpan(
        text: cleanText.substring(index, index + searchQuery.length),
        style: highlightStyle ??
            TextStyle(
              backgroundColor: CupertinoColors.systemYellow.withOpacity(0.3),
              color: CupertinoColors.label,
              fontWeight: FontWeight.bold,
            ),
      ));

      start = index + searchQuery.length;
      index = lowerCaseText.indexOf(lowerCaseQuery, start);
    }

    // Add remaining text
    if (start < cleanText.length) {
      spans.add(TextSpan(
        text: cleanText.substring(start),
        style: textStyle,
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
