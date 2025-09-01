import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';

class AddTodoDialog extends StatefulWidget {
  const AddTodoDialog({super.key});

  @override
  State<AddTodoDialog> createState() => _AddTodoDialogState();
}

class _AddTodoDialogState extends State<AddTodoDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Todo'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          key: const Key('todo_input_field'),
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Todo title',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a todo title';
            }
            return null;
          },
          autofocus: true,
        ),
      ),
      actions: [
        TextButton(
          key: const Key('cancel_button'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: const Key('add_button'),
          onPressed: () => _addTodo(context),
          child: const Text('Add'),
        ),
      ],
    );
  }

  void _addTodo(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      context.read<TodoProvider>().addTodo(_controller.text.trim());
      Navigator.of(context).pop();
    }
  }
}
