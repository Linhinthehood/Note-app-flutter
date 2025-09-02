class TodoItem {
  final String id;
  final String content;
  final bool isCompleted;
  final DateTime createdAt;

  TodoItem({
    required this.id,
    required this.content,
    this.isCompleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  TodoItem copyWith({
    String? id,
    String? content,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return TodoItem(
      id: id ?? this.id,
      content: content ?? this.content,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static TodoItem fromMap(Map<String, dynamic> map) {
    return TodoItem(
      id: map['id'],
      content: map['content'],
      isCompleted: map['isCompleted'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}