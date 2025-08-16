import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AddSongsFromLibraryScreen extends StatefulWidget {
  final Set<String> existingSongPaths;

  const AddSongsFromLibraryScreen({super.key, required this.existingSongPaths});

  @override
  _AddSongsFromLibraryScreenState createState() =>
      _AddSongsFromLibraryScreenState();
}

class _AddSongsFromLibraryScreenState extends State<AddSongsFromLibraryScreen> {
  List<String> _allSongs = [];
  Set<String> _selectedSongs = {};

  @override
  void initState() {
    super.initState();
    _loadLibrarySongs();
  }

  Future<void> _loadLibrarySongs() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final songsDir = Directory('${documentsDir.path}/MAD Music Player/Songs');
    if (await songsDir.exists()) {
      final songFiles = songsDir.listSync().whereType<File>().toList();
      setState(() {
        _allSongs = songFiles.map((f) => f.path).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add from Library'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(_selectedSongs);
            },
            child: Text(
              'Done',
              style: TextStyle(
                color: Theme.of(context).appBarTheme.titleTextStyle?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [const Color(0xFF36373B), const Color(0xFF1E1F24)]
                : [const Color(0xFF6D5DF6), const Color(0xFF38B6FF)],
          ),
        ),
        child: ListView.builder(
          itemCount: _allSongs.length,
          itemBuilder: (context, index) {
            final songPath = _allSongs[index];
            final songTitle = p.basenameWithoutExtension(songPath);
            final alreadyExists = widget.existingSongPaths.contains(songPath);
            final isSelected = _selectedSongs.contains(songPath);

            return CheckboxListTile(
              title: Text(
                songTitle,
                style: TextStyle(
                  color: alreadyExists ? Colors.grey : Colors.white,
                ),
              ),
              subtitle: alreadyExists
                  ? const Text(
                      "Already in playlist",
                      style: TextStyle(color: Colors.grey),
                    )
                  : null,
              value: isSelected,
              activeColor: Theme.of(context).colorScheme.primary,
              // Disable the checkbox if the song is already in the playlist
              onChanged: alreadyExists
                  ? null
                  : (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedSongs.add(songPath);
                        } else {
                          _selectedSongs.remove(songPath);
                        }
                      });
                    },
            );
          },
        ),
      ),
    );
  }
}
