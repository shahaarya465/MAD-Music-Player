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
    if (songPaths.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Text(
            'No songs imported. Tap button below to start!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ),
      );
    }
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Song List:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
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
                          color: Colors.white,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    IconButton(
                      // UPDATED: Icon color changed to black
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.black,
                        size: 20,
                      ),
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
                  color: Colors.white,
                ),
                selected: isSelected,
                selectedTileColor: Colors.white.withOpacity(0.2),
                onTap: () => onSongTap(index),
                trailing: IconButton(
                  // UPDATED: Icon color changed back to red
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
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
