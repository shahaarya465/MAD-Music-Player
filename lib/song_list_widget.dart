import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

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
        child: Text(
          'No songs imported',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }
    return Column(
      children: [
        const Text('Song List:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        SizedBox(
          height: 120,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: songPaths.length,
            itemBuilder: (context, index) {
              final isSelected = index == currentSongIndex;
              return ListTile(
                title: Row(
                  children: [
                    Expanded(child: Text(songTitles[index])),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20),
                      tooltip: 'Rename',
                      onPressed: () async {
                        final controller = TextEditingController(text: songTitles[index]);
                        final newName = await showDialog<String>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Rename Song'),
                            content: TextField(
                              controller: controller,
                              autofocus: true,
                              decoration: const InputDecoration(hintText: 'Enter new name'),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, controller.text.trim()),
                                child: const Text('Save'),
                              ),
                            ],
                          ),
                        );
                        if (newName != null && newName.isNotEmpty && newName != songTitles[index]) {
                          onRename(index, newName);
                        }
                      },
                    ),
                  ],
                ),
                leading: Icon(isSelected ? Icons.music_note : Icons.audiotrack, color: isSelected ? Color(0xFF6D5DF6) : Colors.grey),
                selected: isSelected,
                onTap: () => onSongTap(index),
                trailing: IconButton(
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
