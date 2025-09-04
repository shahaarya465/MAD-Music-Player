import 'package:flutter/material.dart';

enum AppTheme { light, dark, midnight, dracula }

extension AppThemeExtension on AppTheme {
  String get name {
    switch (this) {
      case AppTheme.light:
        return 'Light';
      case AppTheme.dark:
        return 'Dark';
      case AppTheme.midnight:
        return 'Midnight';
      case AppTheme.dracula:
        return 'Dracula';
    }
  }
}

class AppThemes {
  static final Map<AppTheme, ThemeData> themeData = {
    AppTheme.light: _lightTheme,
    AppTheme.dark: _darkTheme,
    AppTheme.midnight: _midnightTheme,
    AppTheme.dracula: _draculaTheme,
  };

  // Gradients for each theme's background
  static final List<Color> lightGradient = [
    const Color(0xFFFFFFFF),
    const Color(0xFFF2F2F2),
  ];
  static final List<Color> darkGradient = [
    const Color(0xFF050506),
    const Color(0xFF0F0F12),
    const Color(0xFF2A2A2D),
  ];
  static final List<Color> midnightGradient = [
    const Color(0xFF16222A),
    const Color(0xFF3A6073),
  ];
  static final List<Color> draculaGradient = [
    const Color(0xFF282a36),
    const Color(0xFF44475a),
  ];

  // ADDED: A map to easily access the correct gradient
  static final Map<AppTheme, List<Color>> gradientData = {
    AppTheme.light: lightGradient,
    AppTheme.dark: darkGradient,
    AppTheme.midnight: midnightGradient,
    AppTheme.dracula: draculaGradient,
  };

  // --- Theme Data Definitions ---

  static final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.black,
    scaffoldBackgroundColor: Colors.white,
    canvasColor: const Color(0xFFF7F7F7),
    cardColor: Colors.white,
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black54),
      titleMedium: TextStyle(color: Colors.black54),
      bodySmall: TextStyle(color: Colors.black45),
    ),
    primaryTextTheme: const TextTheme(
      titleLarge: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(color: Colors.black),
      bodyMedium: TextStyle(color: Colors.black87),
    ),
    iconTheme: const IconThemeData(color: Colors.black),
    colorScheme: const ColorScheme.light(
      primary: Colors.black,
      secondary: Color(0xFF4A4A4A),
      onPrimary: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 1,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.black,
        fontSize: 20,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all<Color>(Colors.black),
        foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
        textStyle: WidgetStateProperty.all<TextStyle>(
          const TextStyle(color: Colors.white),
        ),
        iconColor: WidgetStateProperty.all<Color>(Colors.white),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: Colors.black,
      thumbColor: Colors.black,
      inactiveTrackColor: const Color(0xFFE6E6E6),
      overlayColor: const Color(0x33000000),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.black54,
      elevation: 8,
    ),
    listTileTheme: const ListTileThemeData(
      tileColor: Colors.white,
      textColor: Colors.black,
      iconColor: Colors.black54,
    ),
  );

  static final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.white,
    scaffoldBackgroundColor: const Color(0xFF070708),
    canvasColor: const Color(0xFF0C0C0E),
    cardColor: const Color(0xFF121214),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(color: Colors.white70),
      bodyMedium: TextStyle(color: Colors.white60),
      titleMedium: TextStyle(color: Colors.white60),
      bodySmall: TextStyle(color: Colors.white38),
    ),
    primaryTextTheme: const TextTheme(
      titleLarge: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
    colorScheme: const ColorScheme.dark(
      primary: Colors.white,
      secondary: Color(0xFF3A3A3E),
      onPrimary: Colors.black,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontSize: 20,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2A2A2D),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: Colors.white,
      thumbColor: Colors.white,
      inactiveTrackColor: Colors.white.withOpacity(0.3),
      overlayColor: Colors.white.withOpacity(0.2),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF0C0C0E),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white54,
    ),
    listTileTheme: const ListTileThemeData(
      tileColor: Color(0xFF0C0C0E),
      textColor: Colors.white,
      iconColor: Colors.white70,
    ),
  );

  static final ThemeData _midnightTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.white,
    scaffoldBackgroundColor: const Color(0xFF1c2833),
    canvasColor: const Color(0xFF212f3c),
    cardColor: const Color(0xFF283747),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(color: Colors.white70),
      bodyMedium: TextStyle(color: Colors.white60),
    ),
    colorScheme: const ColorScheme.dark(
      primary: Colors.white,
      secondary: Color(0xFF566573),
      onPrimary: Colors.black,
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF3A6073); 
        }
        return Colors.white70; 
      }),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontSize: 20,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: Colors.white,
      thumbColor: Colors.white,
      inactiveTrackColor: Colors.white.withOpacity(0.3),
      overlayColor: Colors.white.withOpacity(0.2),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF212f3c),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white54,
    ),
    listTileTheme: const ListTileThemeData(
      textColor: Colors.white,
      iconColor: Colors.white70,
    ),
  );

  static final ThemeData _draculaTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFFbd93f9), // Purple
    scaffoldBackgroundColor: const Color(0xFF282a36),
    canvasColor: const Color(0xFF282a36),
    cardColor: const Color(0xFF44475a),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: Color(0xFFf8f8f2),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(color: Color(0xFFf8f8f2)),
      bodyMedium: TextStyle(color: Colors.white60),
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFbd93f9), // Purple
      secondary: Color(0xFFff79c6), // Pink
      onPrimary: Colors.white,
      surface: Color(0xFF44475a),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFFf8f8f2)),
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.bold,
        color: Color(0xFFf8f8f2),
        fontSize: 20,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFbd93f9),
      foregroundColor: Color(0xFF44475a),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: const Color(0xFFbd93f9),
      thumbColor: const Color(0xFFbd93f9),
      inactiveTrackColor: const Color(0xFFbd93f9).withOpacity(0.3),
      overlayColor: const Color(0xFFbd93f9).withOpacity(0.2),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF282a36),
      selectedItemColor: Color(0xFFbd93f9),
      unselectedItemColor: Colors.white54,
    ),
    listTileTheme: const ListTileThemeData(
      textColor: Color(0xFFf8f8f2),
      iconColor: Colors.white70,
    ),
  );
}