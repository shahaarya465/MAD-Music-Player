import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'playlist_detail_screen.dart'; // We need the Song class

class AddSongsFromLibraryScreen extends StatefulWidget {
  final Set<String> existingSongIDs;

  const AddSongsFromLibraryScreen({super.key, required this.existingSongIDs});

  @override
  _AddSongsFromLibraryScreenState createState() =>
      _AddSongsFromLibraryScreenState();
}

class _AddSongsFromLibraryScreenState extends State<AddSongsFromLibraryScreen> {
  List<Song> _allSongs = [];
  Set<String> _selectedSongIDs = {};

  @override
  void initState() {
    super.initState();
    _loadLibrarySongs();
  }

  Future<void> _loadLibrarySongs() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final madMusicPlayerDir = Directory(
      '${documentsDir.path}/MAD Music Player',
    );
    final libraryFile = File('${madMusicPlayerDir.path}/library.json');

    if (await libraryFile.exists()) {
      final libraryContent = jsonDecode(await libraryFile.readAsString());
      final List<Song> songList = [];
      libraryContent.forEach((id, details) {
        songList.add(
          Song(id: id, title: details['title'], path: details['path']),
        );
      });
      setState(() {
        _allSongs = songList;
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
            onPressed: () => Navigator.of(context).pop(_selectedSongIDs),
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
            final song = _allSongs[index];
            final alreadyExists = widget.existingSongIDs.contains(song.id);
            final isSelected = _selectedSongIDs.contains(song.id);

            return CheckboxListTile(
              title: Text(
                song.title,
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
              onChanged: alreadyExists
                  ? null
                  : (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedSongIDs.add(song.id);
                        } else {
                          _selectedSongIDs.remove(song.id);
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
