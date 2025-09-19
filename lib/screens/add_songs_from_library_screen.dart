import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../models/song.dart';
import '../widgets/search_bar_widget.dart';

class AddSongsFromLibraryScreen extends StatefulWidget {
  final Set<String> existingSongIDs;

  const AddSongsFromLibraryScreen({super.key, required this.existingSongIDs});

  @override
  _AddSongsFromLibraryScreenState createState() =>
      _AddSongsFromLibraryScreenState();
}

class _AddSongsFromLibraryScreenState extends State<AddSongsFromLibraryScreen> {
  List<Song> _allSongs = [];
  List<Song> _filteredSongs = [];
  final Set<String> _selectedSongIDs = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllSongs();
    _searchController.addListener(() {
      _filterSongs(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllSongs() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final libraryFile = File(
      '${documentsDir.path}/MAD Music Player/library.json',
    );

    if (await libraryFile.exists()) {
      final musicLibrary = jsonDecode(await libraryFile.readAsString());
      final songList = <Song>[];
      musicLibrary.forEach((songId, details) {
        if (!widget.existingSongIDs.contains(songId)) {
          songList.add(
            Song(
              id: songId,
              title: details['title'],
              path: details['path'],
              type: SongType.local,
            ),
          );
        }
      });
      if (mounted) {
        setState(() {
          _allSongs = songList;
          _filteredSongs = songList;
        });
      }
    }
  }

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

  void _toggleSelection(String songId) {
    setState(() {
      if (_selectedSongIDs.contains(songId)) {
        _selectedSongIDs.remove(songId);
      } else {
        _selectedSongIDs.add(songId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Songs from Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.of(context).pop(_selectedSongIDs);
            },
          ),
        ],
      ),
      body: Column(
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
                final isSelected = _selectedSongIDs.contains(song.id);
                return CheckboxListTile(
                  title: Text(song.title),
                  value: isSelected,
                  onChanged: (bool? value) {
                    _toggleSelection(song.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
