import 'package:flutter/material.dart';

class SongListWidget extends StatelessWidget {
  final List<String> songPaths;
  final List<String> songTitles;
  final int? currentSongIndex;
  final void Function(int) onSongTap;
  final void Function(int) onRemove;
  final void Function(int, String) onRename;

  const SongListWidget({
    super.key,
    required this.songPaths,
    required this.songTitles,
    required this.currentSongIndex,
    required this.onSongTap,
    required this.onRemove,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    // Get the current theme's color for text and icons
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    if (songPaths.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Text(
            'No songs imported. Tap button below to start!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.9),
            ),
          ),
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Song List:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).iconTheme.color,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: songPaths.length,
            itemBuilder: (context, index) {
              final isSelected = index == currentSongIndex;
              return ListTile(
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        songTitles[index],
                        style: TextStyle(
                          color: Theme.of(context).iconTheme.color,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    IconButton(
                      // UPDATED: Color is now theme-aware
                      icon: Icon(Icons.edit, color: onSurfaceColor, size: 20),
                      tooltip: 'Rename',
                      onPressed: () async {
                        final controller = TextEditingController(
                          text: songTitles[index],
                        );
                        final newName = await showDialog<String>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Rename Song'),
                            content: TextField(
                              controller: controller,
                              autofocus: true,
                              decoration: const InputDecoration(
                                hintText: 'Enter new name',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(
                                  context,
                                  controller.text.trim(),
                                ),
                                child: const Text('Save'),
                              ),
                            ],
                          ),
                        );
                        if (newName != null &&
                            newName.isNotEmpty &&
                            newName != songTitles[index]) {
                          onRename(index, newName);
                        }
                      },
                    ),
                  ],
                ),
                leading: Icon(
                  isSelected ? Icons.music_note : Icons.audiotrack,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                selected: isSelected,
                selectedTileColor: Theme.of(context).cardColor.withOpacity(0.12),
                onTap: () => onSongTap(index),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                  onPressed: () => onRemove(index),
                  tooltip: 'Remove',
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
