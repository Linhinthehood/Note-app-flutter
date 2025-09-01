
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:note_app/providers/note_provider.dart';
import 'package:note_app/screens/notes_list_screen.dart';

void main() {
  testWidgets('NotesListScreen displays empty state', (WidgetTester tester) async {
    // Create a completely isolated test without database dependency
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => NoteProvider.forTesting(),
        child: const CupertinoApp(
          home: NotesListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    
    // Should show empty state message
    expect(find.text('No notes yet. Add one!'), findsOneWidget);
  });


import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:note_app/main.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for sqflite in tests
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';

import 'package:note_app/presentation/providers/todo_provider.dart';
import 'package:note_app/presentation/pages/todo_list_page.dart';
import 'package:note_app/presentation/widgets/todo_item_widget.dart';
import 'package:note_app/data/models/todo_model.dart';
import 'package:note_app/data/services/todo_api_service.dart';

// Generate mocks
@GenerateMocks([TodoApiService])
import 'widget_test.mocks.dart';

void main() {
  group('TodoListPage Widget Tests', () {
    late MockTodoApiService mockApiService;

    setUp(() {
      mockApiService = MockTodoApiService();
    });

    Widget createTestWidget(TodoProvider provider) {
      return ChangeNotifierProvider<TodoProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: TodoListPage(),
        ),
      );
    }

    testWidgets('shows loading indicator when loading', (tester) async {
      // Arrange
      final todoProvider = TodoProvider(apiService: mockApiService);

      // Create a completer to control when the future completes
      when(mockApiService.getTodos()).thenAnswer((_) => Future.delayed(
          const Duration(milliseconds: 100), () => <TodoModel>[]));

      // Act
      await tester.pumpWidget(createTestWidget(todoProvider));

      // Trigger loading without waiting for completion
      todoProvider.loadTodos();
      await tester.pump(); // Just pump once to update the UI

      // Assert
      expect(find.byKey(const Key('loading_indicator')), findsOneWidget);

      // Wait for the async operation to complete
      await tester.pumpAndSettle();
    });

    testWidgets('shows empty state when no todos', (tester) async {
      // Arrange
      final todoProvider = TodoProvider(apiService: mockApiService);
      when(mockApiService.getTodos()).thenAnswer((_) async => <TodoModel>[]);

      // Act
      await tester.pumpWidget(createTestWidget(todoProvider));
      await tester.pumpAndSettle(); // Wait for initial load

      // Assert
      expect(find.byKey(const Key('empty_state')), findsOneWidget);
      expect(find.text('No todos yet. Add one!'), findsOneWidget);
    });

    testWidgets('shows todo list when todos loaded', (tester) async {
      // Arrange
      final todoProvider = TodoProvider(apiService: mockApiService);
      final mockTodos = [
        const TodoModel(
            id: 1, userId: 1, title: 'Test Todo 1', completed: false),
        const TodoModel(
            id: 2, userId: 1, title: 'Test Todo 2', completed: true),
      ];
      when(mockApiService.getTodos()).thenAnswer((_) async => mockTodos);

      // Act
      await tester.pumpWidget(createTestWidget(todoProvider));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('todo_list')), findsOneWidget);
      expect(find.byType(TodoItemWidget), findsNWidgets(2));
      expect(find.text('Test Todo 1'), findsOneWidget);
      expect(find.text('Test Todo 2'), findsOneWidget);
    });

    testWidgets('shows error state when API fails', (tester) async {
      // Arrange
      final todoProvider = TodoProvider(apiService: mockApiService);
      when(mockApiService.getTodos()).thenThrow(Exception('Network error'));

      // Act
      await tester.pumpWidget(createTestWidget(todoProvider));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('error_text')), findsOneWidget);
      expect(find.byKey(const Key('retry_button')), findsOneWidget);
      expect(find.textContaining('Network error'), findsOneWidget);
    });

    testWidgets('can tap add todo button and show dialog', (tester) async {
      // Arrange
      final todoProvider = TodoProvider(apiService: mockApiService);
      when(mockApiService.getTodos()).thenAnswer((_) async => <TodoModel>[]);

      // Act
      await tester.pumpWidget(createTestWidget(todoProvider));
      await tester.pumpAndSettle();

      // Tap the FAB
      await tester.tap(find.byKey(const Key('add_todo_fab')));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Add New Todo'), findsOneWidget);
      expect(find.byKey(const Key('todo_input_field')), findsOneWidget);
      expect(find.byKey(const Key('add_button')), findsOneWidget);
      expect(find.byKey(const Key('cancel_button')), findsOneWidget);
    });
  });

  group('TodoItemWidget Tests', () {
    testWidgets('displays todo correctly', (tester) async {
      // Arrange
      const todo =
          TodoModel(id: 1, userId: 1, title: 'Test Todo', completed: false);
      bool toggleCalled = false;
      bool deleteCalled = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TodoItemWidget(
              todo: todo,
              onToggle: () => toggleCalled = true,
              onDelete: () => deleteCalled = true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Test Todo'), findsOneWidget);
      expect(find.byKey(const Key('checkbox_1')), findsOneWidget);
      expect(find.byKey(const Key('delete_1')), findsOneWidget);

      // Test interactions
      await tester.tap(find.byKey(const Key('checkbox_1')));
      await tester.pump();
      expect(toggleCalled, isTrue);

      await tester.tap(find.byKey(const Key('delete_1')));
      await tester.pump();
      expect(deleteCalled, isTrue);
    });

    testWidgets('shows completed todo with strikethrough', (tester) async {
      // Arrange
      const completedTodo =
          TodoModel(id: 1, userId: 1, title: 'Completed Todo', completed: true);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TodoItemWidget(
              todo: completedTodo,
              onToggle: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Assert
      final textWidget = tester.widget<Text>(find.byKey(const Key('title_1')));
      expect(textWidget.style?.decoration, TextDecoration.lineThrough);
    });

  });

  testWidgets('App should launch without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    
    // Wait for async initialization to complete
    await tester.pumpAndSettle();
    
    expect(find.byType(CupertinoApp), findsOneWidget);
  });

}