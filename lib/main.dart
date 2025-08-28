// lib/main.dart
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'providers/note_provider.dart';
import 'screens/notes_list_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => NoteProvider(),
      child: CupertinoApp(
        title: 'Flutter Notes',
        theme: CupertinoThemeData(
          primaryColor: CupertinoColors.systemBlue,
          scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
        ),
        debugShowCheckedModeBanner: false,
        home: NotesListScreen(),
      ),
    );
  }
}