import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'player_manager.dart';
import 'theme.dart';
import 'theme_manager.dart';
import 'queue_screen.dart';
import 'playlist_detail_screen.dart'; // For Song class

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerManager = Provider.of<PlayerManager>(context);
    final themeManager = Provider.of<ThemeManager>(context);
    final theme = Theme.of(context);
    final Song? currentSong = playerManager.currentIndex != null
        ? playerManager.currentPlaylist[playerManager.currentIndex!]
        : null;

    return Scaffold(
      endDrawer: const Drawer(
        child: QueueScreen(),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.expand_more),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.queue_music),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppThemes.gradientData[themeManager.appTheme] ??
                AppThemes.darkGradient,
          ),
        ),
        child: currentSong == null
            ? const Center(child: Text('No song is playing.'))
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Album Art
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: Image.asset(
                        'assets/icon/icon.png',
                        fit: BoxFit.cover,
                        width: MediaQuery.of(context).size.width * 0.7,
                        height: MediaQuery.of(context).size.width * 0.7,
                      ),
                    ),

                    // Song Title and Artist
                    Column(
                      children: [
                        Text(
                          currentSong.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge?.color),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "MAD Music Player", // Placeholder
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),

                    // Seek Bar
                    Column(
                      children: [
                        Slider(
                          value: playerManager.position.inSeconds.toDouble(),
                          min: 0.0,
                          max: playerManager.duration.inSeconds.toDouble() > 0
                              ? playerManager.duration.inSeconds.toDouble()
                              : 1.0,
                          onChanged: (value) {
                            playerManager.seek(Duration(seconds: value.toInt()));
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDuration(playerManager.position)),
                              Text(_formatDuration(playerManager.duration)),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Playback Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(
                            playerManager.isShuffle
                                ? Icons.shuffle_on
                                : Icons.shuffle,
                          ),
                          iconSize: 32,
                          onPressed: playerManager.toggleShuffle,
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_previous),
                          iconSize: 48,
                          onPressed: playerManager.playPrevious,
                        ),
                        IconButton(
                          icon: Icon(
                            playerManager.isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            color: theme.colorScheme.primary,
                          ),
                          iconSize: 72,
                          onPressed: () {
                            if (playerManager.isPlaying) {
                              playerManager.pause();
                            } else {
                              playerManager.resume();
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next),
                          iconSize: 48,
                          onPressed: playerManager.playNext,
                        ),
                        IconButton(
                          icon: Icon(
                            playerManager.repeatMode == RepeatMode.none
                                ? Icons.repeat
                                : playerManager.repeatMode == RepeatMode.one
                                    ? Icons.repeat_one
                                    : Icons.repeat_on,
                          ),
                          iconSize: 32,
                          onPressed: playerManager.toggleRepeat,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
