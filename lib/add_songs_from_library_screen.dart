import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'playlist_detail_screen.dart';
import 'search_bar_widget.dart';
import 'theme.dart';

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

  final TextEditingController _searchController = TextEditingController();
  List<Song> _filteredSongs = [];

  @override
  void initState() {
    super.initState();
    _loadLibrarySongs();
    _searchController.addListener(() {
      _filterSongs(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        _filteredSongs = songList; // Initialize filtered list with all songs
      });
    }
  }

  // NEW: Function to filter songs based on search query
  void _filterSongs(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredSongs = _allSongs;
      });
      return;
    }
    final results = _allSongs.where((song) {
      return song.title.toLowerCase().contains(query.toLowerCase());
    }).toList();
    setState(() {
      _filteredSongs = results;
    });
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
                color: Theme.of(context).textTheme.bodyLarge?.color,
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
                ? AppThemes.darkGradient
                : AppThemes.lightGradient,
          ),
        ),
        child: Column(
          children: [
            SearchBarWidget(
              controller: _searchController,
              hintText: 'Search your library...',
              onChanged: _filterSongs,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredSongs.length,
                itemBuilder: (context, index) {
                  final song = _filteredSongs[index];
                  final alreadyExists = widget.existingSongIDs.contains(
                    song.id,
                  );
                  final isSelected = _selectedSongIDs.contains(song.id);

                  return CheckboxListTile(
                    title: Text(
                      song.title,
                      style: TextStyle(
                        color: alreadyExists ? Colors.grey : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    subtitle: alreadyExists
                        ? Text(
                            "Already in playlist",
                            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
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
          ],
        ),
      ),
    );
  }
}
