import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme.dart';

class ThemeManager with ChangeNotifier {
  // Change from ThemeMode to our new AppTheme enum
  AppTheme _appTheme = AppTheme.dark; // Default theme
  AppTheme get appTheme => _appTheme;

  ThemeManager() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    // Read the theme name as a string, default to 'dark'
    final themeName = prefs.getString('theme') ?? AppTheme.dark.name;

    // Find the corresponding enum value
    _appTheme = AppTheme.values.firstWhere(
      (theme) => theme.name == themeName,
      orElse: () => AppTheme.dark,
    );
    notifyListeners();
  }

  // Replace toggleTheme with a method that accepts a specific theme
  Future<void> setTheme(AppTheme theme) async {
    if (_appTheme == theme) return;

    _appTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    // Save the theme's name as a string
    await prefs.setString('theme', theme.name);
    notifyListeners();
  }
}
