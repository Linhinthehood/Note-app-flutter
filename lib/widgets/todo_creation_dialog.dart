import 'package:flutter/cupertino.dart';

class TodoCreationDialog extends StatefulWidget {
  final Function(String) onCreateTodo;

  const TodoCreationDialog({
    super.key,
    required this.onCreateTodo,
  });

  @override
  State<TodoCreationDialog> createState() => _TodoCreationDialogState();
}

class _TodoCreationDialogState extends State<TodoCreationDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _createTodo() {
    final content = _controller.text.trim();
    if (content.isNotEmpty) {
      widget.onCreateTodo(content);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Text(
          'Create To-Do Item',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      content: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(
          minHeight: 120,
          maxHeight: 200,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(
                minHeight: 80,
              ),
              child: CupertinoTextField(
                controller: _controller,
                placeholder: 'Enter your to-do item...',
                placeholderStyle: TextStyle(
                  color: CupertinoColors.placeholderText.resolveFrom(context),
                  fontSize: 16,
                ),
                autofocus: true,
                maxLines: 4,
                minLines: 3,
                style: const TextStyle(fontSize: 16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6.resolveFrom(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: CupertinoColors.separator.resolveFrom(context),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(12),
                onSubmitted: (_) => _createTodo(),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tip: Double-tap on text to create more to-do items',
              style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text(
            'Cancel',
            style: TextStyle(
              fontSize: 17,
              color: CupertinoColors.destructiveRed,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          child: const Text(
            'Create',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: _createTodo,
        ),
      ],
    );
  }
}