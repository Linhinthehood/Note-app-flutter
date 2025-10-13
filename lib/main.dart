import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'providers/note_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/notes_list_screen.dart';
import 'services/semantic_search_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database factory for desktop platforms
  await SemanticSearchService.initializeDatabaseFactory();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NoteProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return CupertinoApp(
            title: 'Flutter Notes',
            theme: themeProvider.themeData,
            debugShowCheckedModeBanner: false,
            home: const NotesListScreen(),
          );
        },
      ),
    );
  }
}
