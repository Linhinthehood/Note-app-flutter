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
}