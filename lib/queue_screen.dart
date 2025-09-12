import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'player_manager.dart';
import 'theme.dart';
import 'theme_manager.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerManager = Provider.of<PlayerManager>(context);
    final themeManager = Provider.of<ThemeManager>(context);
    final theme = Theme.of(context);

    return Container(
      // Use the gradient from the currently active theme
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppThemes.gradientData[themeManager.appTheme] ??
              AppThemes.darkGradient,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Up Next'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: playerManager.currentPlaylist.isEmpty
            ? Center(
                child: Text(
                'No songs in queue.',
                style: theme.textTheme.bodyLarge,
              ))
            : ReorderableListView.builder(
                itemCount: playerManager.currentPlaylist.length,
                itemBuilder: (context, index) {
                  final song = playerManager.currentPlaylist[index];
                  final isCurrent = playerManager.currentIndex == index;
                  return ListTile(
                    key: ValueKey(song.id),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 4.0),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: Image.asset(
                        'assets/icon/icon.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent
                            ? theme.colorScheme.primary
                            : theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    trailing: ReorderableDragStartListener(
                      index: index,
                      child: Icon(
                        Icons.drag_handle,
                        color: theme.iconTheme.color?.withOpacity(0.7),
                      ),
                    ),
                    onTap: () {
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
