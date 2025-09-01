import 'package:flutter/foundation.dart';
import '../../data/models/todo_model.dart';
import '../../data/services/todo_api_service.dart';

class TodoProvider with ChangeNotifier {
  final TodoApiService _apiService;

  TodoProvider({TodoApiService? apiService})
      : _apiService = apiService ?? TodoApiService();

  List<TodoModel> _todos = [];
  bool _isLoading = false;
  String? _error;

  List<TodoModel> get todos => _todos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTodos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _todos = await _apiService.getTodos();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTodo(String title) async {
    try {
      final newTodo = TodoModel(
        id: 0, // JSONPlaceholder will assign ID
        userId: 1,
        title: title,
        completed: false,
      );

      final createdTodo = await _apiService.createTodo(newTodo);
      _todos.insert(0, createdTodo);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void toggleTodo(int index) {
    if (index >= 0 && index < _todos.length) {
      final todo = _todos[index];
      _todos[index] = TodoModel(
        id: todo.id,
        userId: todo.userId,
        title: todo.title,
        completed: !todo.completed,
      );
      notifyListeners();
    }
  }

  void removeTodo(int index) {
    if (index >= 0 && index < _todos.length) {
      _todos.removeAt(index);
      notifyListeners();
    }
  }
}
