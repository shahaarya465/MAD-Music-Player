import 'package:flutter/material.dart';

class AppThemes {
  static final List<Color> lightGradient = [
    const Color(0xFFFFFFFF),
    const Color(0xFFF2F2F2),
  ];
  static final List<Color> darkGradient = [
    const Color(0xFF050506), // almost black
    const Color(0xFF0F0F12), // very dark gray
    const Color(0xFF2A2A2D), // dark gray
  ]; // Grayscale dark gradient (black -> dark gray)

  static final ThemeData lightTheme = ThemeData(
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

  static final ThemeData darkTheme = ThemeData(
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
    // UPDATED: FloatingActionButton theme for dark mode
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
}
