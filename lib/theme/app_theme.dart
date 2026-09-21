import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  // Dark mode colors required by spec:
  // background: #212327, icons & buttons: #232627
  static const Color darkBg = Color(0xFF212327);
  static const Color darkButton = Color(0xFF232627);
  static const Color darkSurface = Color(0xFF282B2F);
  static const Color darkBorder = Color(0xFF34383D);
  static const Color darkAccent = Color(0xFF00E5FF);
  static const Color darkTextPrimary = Color(0xFFE4E6EB);
  static const Color darkTextSecondary = Color(0xFF9AA0A6);

  // Light mode colors required by spec:
  // background: #efeef1, icons & buttons: #fefefe
  static const Color lightBg = Color(0xFFEFEEF1);
  static const Color lightButton = Color(0xFFFEFEFE);
  static const Color lightSurface = Color(0xFFFEFEFE);
  static const Color lightBorder = Color(0xFFD6D8DC);
  static const Color lightAccent = Color(0xFF0070F3);
  static const Color lightTextPrimary = Color(0xFF1A1C1E);
  static const Color lightTextSecondary = Color(0xFF5F6368);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      canvasColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: darkAccent,
        onPrimary: Color(0xFF000000),
        secondary: Color(0xFF38D39F),
        onSecondary: Color(0xFF000000),
        surface: darkSurface,
        onSurface: darkTextPrimary,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: const Color(0xFF000000),
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: darkBorder, width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        iconTheme: IconThemeData(color: darkAccent),
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      iconTheme: const IconThemeData(color: darkAccent),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkButton,
          foregroundColor: darkTextPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: darkBorder, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkTextPrimary,
          side: const BorderSide(color: darkBorder, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      canvasColor: lightBg,
      colorScheme: const ColorScheme.light(
        primary: lightAccent,
        onPrimary: Color(0xFFFFFFFF),
        secondary: Color(0xFF10B981),
        onSecondary: Color(0xFFFFFFFF),
        surface: lightSurface,
        onSurface: lightTextPrimary,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: const Color(0xFFFFFFFF),
        ),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: lightBorder, width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBg,
        elevation: 0,
        iconTheme: IconThemeData(color: lightAccent),
        titleTextStyle: TextStyle(
          color: lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      iconTheme: const IconThemeData(color: lightAccent),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightButton,
          foregroundColor: lightTextPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: lightBorder, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightTextPrimary,
          side: const BorderSide(color: lightBorder, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class ThemeController extends ChangeNotifier {
  static final ThemeController instance = ThemeController._internal();

  ThemeMode _themeMode = ThemeMode.dark;

  ThemeController._internal() {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mode = prefs.getString('app_theme') ?? 'dark';
      _themeMode = (mode == 'light') ? ThemeMode.light : ThemeMode.dark;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'app_theme',
        mode == ThemeMode.light ? 'light' : 'dark',
      );
    } catch (_) {}
  }

  void toggleTheme() {
    setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }
}
