// lib/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode {
  light,
  dark,
  sepia,
  blue,
}

class ThemeProvider extends ChangeNotifier {
  AppThemeMode _themeMode = AppThemeMode.light;
  
  AppThemeMode get themeMode => _themeMode;
  
  ThemeProvider() {
    _loadTheme();
  }
  
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString('theme_mode') ?? 'light';
    _themeMode = AppThemeMode.values.firstWhere(
      (e) => e.name == themeName,
      orElse: () => AppThemeMode.light,
    );
    notifyListeners();
  }
  
  Future<void> setTheme(AppThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
  }
  
  ThemeData get themeData {
    switch (_themeMode) {
      case AppThemeMode.light:
        return _lightTheme;
      case AppThemeMode.dark:
        return _darkTheme;
      case AppThemeMode.sepia:
        return _sepiaTheme;
      case AppThemeMode.blue:
        return _blueTheme;
    }
  }
  
  // Light Theme
  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.blue.shade700,
      elevation: 1,
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 2,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black87),
    ),
  );
  
  // Dark Theme
  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.blue,
      elevation: 1,
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF1E1E1E),
      elevation: 2,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white70),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
  );
  
  // Sepia Theme
  static final ThemeData _sepiaTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primarySwatch: Colors.brown,
    scaffoldBackgroundColor: const Color(0xFFF4F1EA),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFE8E3D3),
      foregroundColor: Color(0xFF5D4E37),
      elevation: 1,
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFFE8E3D3),
      elevation: 2,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF3E2F1F)),
      bodyMedium: TextStyle(color: Color(0xFF3E2F1F)),
    ),
  );
  
  // Blue Theme
  static final ThemeData _blueTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: const Color(0xFF0D1B2A),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1B263B),
      foregroundColor: Color(0xFF6FBAFF),
      elevation: 1,
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF1B263B),
      elevation: 2,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFE0E1DD)),
      bodyMedium: TextStyle(color: Color(0xFFE0E1DD)),
    ),
  );
  
  Color get primaryTextColor {
    switch (_themeMode) {
      case AppThemeMode.light:
        return Colors.black87;
      case AppThemeMode.dark:
        return Colors.white70;
      case AppThemeMode.sepia:
        return const Color(0xFF3E2F1F);
      case AppThemeMode.blue:
        return const Color(0xFFE0E1DD);
    }
  }
  
  Color get secondaryTextColor {
    switch (_themeMode) {
      case AppThemeMode.light:
        return Colors.grey.shade600;
      case AppThemeMode.dark:
        return Colors.grey.shade400;
      case AppThemeMode.sepia:
        return const Color(0xFF6B5D4F);
      case AppThemeMode.blue:
        return const Color(0xFFB0B7C3);
    }
  }
  
  Color get highlightColor {
    switch (_themeMode) {
      case AppThemeMode.light:
        return Colors.yellow;
      case AppThemeMode.dark:
        return Colors.yellow.shade700;
      case AppThemeMode.sepia:
        return const Color(0xFFFFE6A0);
      case AppThemeMode.blue:
        return Colors.amber.shade700;
    }
  }
}
