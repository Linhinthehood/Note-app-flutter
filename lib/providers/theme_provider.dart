import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _prefKey = 'isDarkMode';

  bool _isDark = false;
  bool get isDark => _isDark;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_prefKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, _isDark);
  }

  CupertinoThemeData get themeData {
    if (_isDark) {
      return const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: CupertinoColors.systemBlue,
        scaffoldBackgroundColor: CupertinoColors.black,
      );
    }
    return const CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: CupertinoColors.systemBlue,
      scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
    );
  }
}


