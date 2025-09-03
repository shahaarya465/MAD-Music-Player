import 'package:flutter/material.dart';
import 'main_screen.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'theme_manager.dart';
import 'player_manager.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeManager()),
        ChangeNotifierProvider(create: (_) => PlayerManager()),
      ],
      child: const MyApp(),
    ),
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
          title: 'MAD Music',
          theme: AppThemes.lightTheme, // Set the light theme
          darkTheme: AppThemes.darkTheme, // Set the dark theme
          themeMode: themeManager.themeMode, // Control which theme is active
          home: const MainScreen(), // Change this to your new main screen
        );
      },
    );
  }
}
