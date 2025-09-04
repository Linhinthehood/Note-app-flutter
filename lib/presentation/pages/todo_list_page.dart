import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../widgets/todo_item_widget.dart';
import '../widgets/add_todo_dialog.dart';

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TodoProvider>().loadTodos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Todos'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<TodoProvider>(
        builder: (context, todoProvider, child) {
          if (todoProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                key: Key('loading_indicator'),
              ),
            );
          }

          if (todoProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${todoProvider.error}',
                    key: const Key('error_text'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    key: const Key('retry_button'),
                    onPressed: () => todoProvider.loadTodos(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (todoProvider.todos.isEmpty) {
            return const Center(
              child: Text(
                'No todos yet. Add one!',
                key: Key('empty_state'),
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            key: const Key('todo_list'),
            itemCount: todoProvider.todos.length,
            itemBuilder: (context, index) {
              return TodoItemWidget(
                key: Key('todo_item_$index'),
                todo: todoProvider.todos[index],
                onToggle: () => todoProvider.toggleTodo(index),
                onDelete: () => todoProvider.removeTodo(index),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('add_todo_fab'),
        onPressed: () => _showAddTodoDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTodoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddTodoDialog(),
    );
  }
}
