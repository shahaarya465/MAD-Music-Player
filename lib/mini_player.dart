import 'package:flutter/material.dart';

class MiniPlayer extends StatelessWidget {
  final String songTitle;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final VoidCallback onPlayPause;
  final VoidCallback onSeekForward;
  final VoidCallback onSeekBackward;
  // We need to add these back
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
    required this.onNext, // Added back
    required this.onPrevious, // Added back
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
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
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row for Title and Slider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.music_note_rounded,
                    color: Color(0xFF6D5DF6),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      songTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            // Slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 8.0,
                ),
                overlayShape: const RoundSliderOverlayShape(
                  overlayRadius: 12.0,
                ),
                trackHeight: 2.0,
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
                activeColor: const Color(0xFF6D5DF6),
                inactiveColor: const Color(0xFFB2A9F7),
                onChanged: onSeek,
              ),
            ),
            // UPDATED: Row with all 5 control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded),
                  onPressed: onPrevious,
                  iconSize: 32,
                ),
                IconButton(
                  icon: const Icon(Icons.replay_10_rounded),
                  onPressed: onSeekBackward,
                  iconSize: 32,
                ),
                IconButton(
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_filled_rounded,
                  ),
                  onPressed: onPlayPause,
                  iconSize:
                      50, // Made this slightly larger as it's the main button
                  color: const Color(0xFF6D5DF6),
                ),
                IconButton(
                  icon: const Icon(Icons.forward_10_rounded),
                  onPressed: onSeekForward,
                  iconSize: 32,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded),
                  onPressed: onNext,
                  iconSize: 32,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
