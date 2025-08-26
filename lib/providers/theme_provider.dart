import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode;
  Color _primaryColor;
  String _printerName;
  
  static const String _darkModeKey = 'darkMode';
  static const String _primaryColorKey = 'primaryColor';
  static const String _printerNameKey = 'printerName';

  ThemeProvider()
      : _isDarkMode = false,
        _primaryColor = Colors.blue,
        _printerName = 'La mia Stampante' {
    _loadPreferences();
  }

  bool get isDarkMode => _isDarkMode;
  Color get primaryColor => _primaryColor;
  String get printerName => _printerName;

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
    _primaryColor = Color(prefs.getInt(_primaryColorKey) ?? Colors.blue.value);
    _printerName = prefs.getString(_printerNameKey) ?? 'La mia Stampante';
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
    notifyListeners();
  }

  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_primaryColorKey, color.value);
    notifyListeners();
  }

  Future<void> setPrinterName(String name) async {
    _printerName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_printerNameKey, name);
    notifyListeners();
  }

  ThemeData get themeData {
    final baseTheme = _isDarkMode ? ThemeData.dark() : ThemeData.light();
    
    return baseTheme.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: _isDarkMode ? Brightness.dark : Brightness.light,
      ),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: _isDarkMode 
            ? Color.lerp(_primaryColor, Colors.black, 0.9)
            : Color.lerp(_primaryColor, Colors.white, 0.9),
        elevation: 2,
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
      ),
    );
  }
}
