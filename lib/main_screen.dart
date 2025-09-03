
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'home_screen.dart';
import 'library_screen.dart';
import 'mini_player.dart';
import 'player_manager.dart';
import 'settings_screen.dart';
import 'songs_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = <Widget>[
    HomeScreen(),
    SongsScreen(),
    LibraryScreen(), // This will be your renamed playlist browser
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        // Use IndexedStack to keep state of screens
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Consumer<PlayerManager>(
            builder: (context, playerManager, child) {
              if (playerManager.currentSongTitle == null) {
                return const SizedBox.shrink();
              }
              return MiniPlayer(
                songTitle: playerManager.currentSongTitle!,
                isPlaying: playerManager.isPlaying,
                position: playerManager.position,
                duration: playerManager.duration,
                onPlayPause: () => playerManager.isPlaying
                    ? playerManager.pause()
                    : playerManager.resume(),
                onPrevious: playerManager.playPrevious,
                onNext: playerManager.playNext,
                onSeek: (value) =>
                    playerManager.seek(Duration(seconds: value.toInt())),
                onSeekBackward: playerManager.seekBackward10,
                onSeekForward: playerManager.seekForward10,
              );
            },
          ),
          BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Icon(Icons.music_note),
                label: 'Songs',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.library_music),
                label: 'Library',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            // These properties are important for making the bar look good with more than 3 items
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Colors.grey,
          ),
        ],
      ),
    );
  }
}
