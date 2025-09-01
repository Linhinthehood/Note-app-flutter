import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:note_app/main.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for sqflite in tests
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('App should launch without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    
    // Wait for async initialization to complete
    await tester.pumpAndSettle();
    
    expect(find.byType(CupertinoApp), findsOneWidget);
  });
}