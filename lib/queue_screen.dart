import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'player_manager.dart';
import 'theme.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerManager = Provider.of<PlayerManager>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              playerManager.isShuffle ? Icons.shuffle_on : Icons.shuffle,
            ),
            onPressed: playerManager.toggleShuffle,
          ),
          IconButton(
            icon: Icon(
              playerManager.repeatMode == RepeatMode.none
                  ? Icons.repeat
                  : playerManager.repeatMode == RepeatMode.one
                  ? Icons.repeat_one
                  : Icons.repeat_on,
            ),
            onPressed: playerManager.toggleRepeat,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? AppThemes.darkGradient
                : AppThemes.lightGradient,
          ),
        ),
        child: playerManager.currentPlaylist.isEmpty
            ? const Center(child: Text('No songs in queue.'))
            : ReorderableListView.builder(
                itemCount: playerManager.currentPlaylist.length,
                itemBuilder: (context, index) {
                  final song = playerManager.currentPlaylist[index];
                  final isCurrent = playerManager.currentIndex == index;
                  return ListTile(
                    key: ValueKey(song.id),
                    leading: isCurrent
                        ? const Icon(Icons.play_arrow, color: Colors.green)
                        : const Icon(Icons.music_note),
                    title: Text(
                      song.title,
                      style: TextStyle(
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: const Icon(Icons.drag_handle),
                    onTap: () {
                      // Add this onTap callback
                      playerManager.playAtIndex(index);
                    },
                  );
                },
                onReorder: (oldIndex, newIndex) {
                  playerManager.reorderPlaylist(oldIndex, newIndex);
                },
              ),
      ),
    );
  }
}
