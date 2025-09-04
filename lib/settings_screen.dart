import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme.dart';
import 'theme_manager.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);

    // Reorder themes with dark themes first, as requested.
    final orderedThemes = [
      AppTheme.dark,
      AppTheme.midnight,
      AppTheme.dracula,
      AppTheme.light,
      AppTheme.ocean_breeze,
      AppTheme.sunset,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text(
              'Theme',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...orderedThemes.map((theme) {
            return RadioListTile<AppTheme>(
              title: Text(theme.name),
              value: theme,
              groupValue: themeManager.appTheme,
              onChanged: (newTheme) {
                if (newTheme != null) {
                  themeManager.setTheme(newTheme);
                }
              },
            );
          }).toList(),
        ],
      ),
    );
  }
}