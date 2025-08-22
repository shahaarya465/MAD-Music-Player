import 'package:flutter/material.dart';

class MiniPlayer extends StatelessWidget {
  final String songTitle;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final VoidCallback onPlayPause;
  final VoidCallback onSeekForward;
  final VoidCallback onSeekBackward;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final ValueChanged<double> onSeek;

  const MiniPlayer({
    super.key,
    required this.songTitle,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onPlayPause,
    required this.onSeekForward,
    required this.onSeekBackward,
    required this.onNext,
    required this.onPrevious,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    // Get colors from the current theme to work in both light and dark mode
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onSurfaceColor = theme.colorScheme.onSurface;
    final backgroundColor = theme.cardColor.withOpacity(0.95);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: The interactive slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 8.0,
                ),
                overlayShape: const RoundSliderOverlayShape(
                  overlayRadius: 12.0,
                ),
                trackHeight: 2.0,
                activeTrackColor: primaryColor,
                inactiveTrackColor: primaryColor.withOpacity(0.3),
                thumbColor: primaryColor,
              ),
              child: Slider(
                min: 0,
                max: duration.inSeconds.toDouble() > 0
                    ? duration.inSeconds.toDouble()
                    : 0.0,
                value: position.inSeconds.toDouble().clamp(
                  0.0,
                  duration.inSeconds.toDouble(),
                ),
                onChanged: onSeek,
              ),
            ),
            // Row 2: Song Title on the left, Buttons on the right
            Row(
              children: [
                Expanded(
                  child: Text(
                    songTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: onSurfaceColor, // Theme-aware color
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                // Buttons are grouped to the right
                IconButton(
                  icon: Icon(
                    Icons.skip_previous_rounded,
                    color: onSurfaceColor,
                  ),
                  onPressed: onPrevious,
                  iconSize: 28,
                ),
                IconButton(
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_filled_rounded,
                    color: primaryColor,
                  ),
                  onPressed: onPlayPause,
                  iconSize: 42,
                ),
                IconButton(
                  icon: Icon(Icons.skip_next_rounded, color: onSurfaceColor),
                  onPressed: onNext,
                  iconSize: 28,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
