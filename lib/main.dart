import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'main_screen.dart';
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
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return MaterialApp(
          title: 'MAD Music',
          // Get the ThemeData from our map based on the selected theme
          theme: AppThemes.themeData[themeManager.appTheme],
          // No need for darkTheme or themeMode anymore
          home: const MainScreen(),
        );
      },
    );
  }
}
