import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'music_player_screen.dart';
import 'theme.dart';
import 'theme_manager.dart';

void main() {
  runApp(
    ChangeNotifierProvider(create: (_) => ThemeManager(), child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Consumer widget listens to ThemeManager changes
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return MaterialApp(
          title: 'MAD Music Player',
          theme: AppThemes.lightTheme, // Set the light theme
          darkTheme: AppThemes.darkTheme, // Set the dark theme
          themeMode: themeManager.themeMode, // Control which theme is active
          home: const MusicPlayerScreen(),
        );
      },
    );
  }
}
