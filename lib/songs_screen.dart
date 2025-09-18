import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'player_manager.dart';
import 'playlist_detail_screen.dart';
import 'search_bar_widget.dart';

class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});

  @override
  _SongsScreenState createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  List<Song> _allSongs = [];
  List<Song> _filteredSongs = [];
  late Directory _songsDir;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeDirectoriesAndLoad();
    _searchController.addListener(() {
      _filterSongs(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _initializeDirectoriesAndLoad() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final madMusicPlayerDir = Directory(
      '${documentsDir.path}/MAD Music Player',
    );
    _songsDir = Directory('${madMusicPlayerDir.path}/Songs');
    if (!await _songsDir.exists()) await _songsDir.create();

    _loadAllSongs();
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
        songList.add(
          Song(id: songId, title: details['title'], path: details['path']),
        );
      });
      if (mounted) {
        setState(() {
          _allSongs = songList;
          _filteredSongs = songList;
        });
      }
    }
  }

  Future<void> _importSongsToLibrary() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final madMusicPlayerDir = Directory(
        '${(await getApplicationDocumentsDirectory()).path}/MAD Music Player',
      );
      final libraryFile = File('${madMusicPlayerDir.path}/library.json');
      final Map<String, dynamic> libraryContent = Map<String, dynamic>.from(
        jsonDecode(await libraryFile.readAsString()),
      );
      int importCount = 0;

      for (var file in result.files) {
        if (file.path != null) {
          final destPath = p.join(_songsDir.path, p.basename(file.path!));
          if (!await File(destPath).exists()) {
            await File(file.path!).copy(destPath);
            const uuid = Uuid();
            final songId = uuid.v4();
            final songTitle = p.basenameWithoutExtension(destPath);
            libraryContent[songId] = {'title': songTitle, 'path': destPath};
            importCount++;
          }
        }
      }

      await libraryFile.writeAsString(jsonEncode(libraryContent));
      await _loadAllSongs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported $importCount new songs to your library.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerManager = Provider.of<PlayerManager>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Songs'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "songs_fab", // Unique hero tag
        onPressed: _importSongsToLibrary,
        label: Text(
          'Import Songs',
          style: TextStyle(
            color: Theme.of(context).floatingActionButtonTheme.foregroundColor,
          ),
        ),
        icon: Icon(
          Icons.add_to_photos_rounded,
          color: Theme.of(context).floatingActionButtonTheme.foregroundColor,
        ),
      ),
      body: Column(
        children: [
          SearchBarWidget(
            controller: _searchController,
            hintText: 'Search all songs...',
            onChanged: _filterSongs,
          ),
          Expanded(
            child: _filteredSongs.isEmpty
                ? const Center(
                    child: Text('No songs found.', textAlign: TextAlign.center),
                  )
                : ListView.builder(
                    itemCount: _filteredSongs.length,
                    itemBuilder: (context, index) {
                      final song = _filteredSongs[index];
                      return ListTile(
                        leading: const Icon(Icons.music_note),
                        title: Text(song.title),
                        onTap: () {
                          playerManager.play(_filteredSongs, index);
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
