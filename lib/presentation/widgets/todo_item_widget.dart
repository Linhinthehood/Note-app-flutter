import 'package:flutter/material.dart';
import '../../data/models/todo_model.dart';

class TodoItemWidget extends StatelessWidget {
  final TodoModel todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TodoItemWidget({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Checkbox(
          key: Key('checkbox_${todo.id}'),
          value: todo.completed,
          onChanged: (_) => onToggle(),
        ),
        title: Text(
          todo.title,
          key: Key('title_${todo.id}'),
          style: TextStyle(
            decoration: todo.completed 
                ? TextDecoration.lineThrough 
                : TextDecoration.none,
          ),
        ),
        trailing: IconButton(
          key: Key('delete_${todo.id}'),
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }
}