class Note {
  final int? id;
  final String title;
  final String content;
  final DateTime createdAt;
  final bool isPinned;
  final List<String> imagePaths; // Add this field

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.isPinned = false,
    this.imagePaths = const [], // Add this parameter
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'isPinned': isPinned ? 1 : 0,
      'imagePaths': imagePaths.join('|'), // Store as pipe-separated string
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      createdAt: DateTime.parse(map['createdAt']),
      isPinned: (map['isPinned'] ?? 0) == 1,
      imagePaths: (map['imagePaths'] as String?)
          ?.split('|')
          .where((s) => s.isNotEmpty)
          .toList() ?? [],
    );
  }
}