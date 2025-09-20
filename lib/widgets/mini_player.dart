import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_manager.dart';
import '../screens/now_playing_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final playerManager = Provider.of<PlayerManager>(context);
    final theme = Theme.of(context);

    if (playerManager.currentSongTitle == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const NowPlayingScreen(),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(0.95),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: (playerManager.duration.inSeconds > 0)
                  ? playerManager.position.inSeconds /
                      playerManager.duration.inSeconds
                  : 0.0,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.3),
              valueColor:
                  AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.0),
                    child: Image.asset(
                      'assets/icon/icon.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      playerManager.currentSongTitle!,
                      style: theme.textTheme.bodyLarge,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded),
                    onPressed: playerManager.playPrevious,
                  ),
                  // This is the updated part
                  if (playerManager.isLoading)
                    const SizedBox(
                      width: 36,
                      height: 36,
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    IconButton(
                      icon: Icon(
                        playerManager.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      iconSize: 36,
                      onPressed: () {
                        if (playerManager.isPlaying) {
                          playerManager.pause();
                        } else {
                          playerManager.resume();
                        }
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded),
                    onPressed: playerManager.playNext,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
