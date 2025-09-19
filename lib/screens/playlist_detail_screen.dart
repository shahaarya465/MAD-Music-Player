import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';

import '../models/playlist.dart';
import '../models/song.dart';
import '../providers/player_manager.dart';
import '../widgets/mini_player.dart';
import 'add_songs_from_library_screen.dart';
import '../theme/theme.dart';
import '../widgets/search_bar_widget.dart';
import '../providers/theme_manager.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;
  final bool isAllSongsPlaylist;

  const PlaylistDetailScreen({
    super.key,
    required this.playlist,
    this.isAllSongsPlaylist = false,
  });

  @override
  _PlaylistDetailScreenState createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  List<Song> _songs = [];
  Map<String, dynamic> _musicLibrary = {};
  late File _libraryFile;

  final TextEditingController _searchController = TextEditingController();
  List<Song> _filteredSongs = [];

  @override
  void initState() {
    super.initState();
    _loadSongs();
    _searchController.addListener(() {
      _filterSongs(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// This function now correctly creates `Song` objects with the `SongType.local`
  Future<void> _loadSongs() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final madMusicPlayerDir = Directory(
      '${documentsDir.path}/MAD Music Player',
    );
    _libraryFile = File('${madMusicPlayerDir.path}/library.json');

    if (await _libraryFile.exists()) {
      _musicLibrary = jsonDecode(await _libraryFile.readAsString());
    } else {
      await _libraryFile.writeAsString('{}');
      _musicLibrary = {};
    }

    final songIdsToLoad = widget.isAllSongsPlaylist
        ? _musicLibrary.keys.toList()
        : widget.playlist.songIDs;

    final songList = <Song>[];
    for (String songId in songIdsToLoad) {
      if (_musicLibrary.containsKey(songId)) {
        final details = _musicLibrary[songId];
        songList.add(
          Song(
            id: songId,
            title: details['title'],
            path: details['path'],
            type: SongType.local, // Correctly assigning the type
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _songs = songList;
        _filteredSongs = songList;
      });
    }
  }

  void _filterSongs(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredSongs = _songs;
      });
      return;
    }
    final results = _songs.where((song) {
      return song.title.toLowerCase().contains(query.toLowerCase());
    }).toList();
    setState(() {
      _filteredSongs = results;
    });
  }

  Future<void> _addSongsToPlaylist() async {
    final selectedSongIDs = await Navigator.push<Set<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => AddSongsFromLibraryScreen(
          existingSongIDs: _songs.map((s) => s.id).toSet(),
        ),
      ),
    );

    if (selectedSongIDs != null && selectedSongIDs.isNotEmpty) {
      widget.playlist.songIDs.addAll(selectedSongIDs);
      final playlistJson = {
        "name": widget.playlist.name,
        "songIDs": widget.playlist.songIDs,
      };
      await widget.playlist.file.writeAsString(jsonEncode(playlistJson));
      await _loadSongs();
    }
  }

  Future<void> _removeSongFromPlaylist(Song song) async {
    widget.playlist.songIDs.remove(song.id);
    final playlistJson = {
      "name": widget.playlist.name,
      "songIDs": widget.playlist.songIDs,
    };
    await widget.playlist.file.writeAsString(jsonEncode(playlistJson));
    await _loadSongs();
  }

  // This and other helper methods like _renameSong, _deleteSongGlobally, etc.
  // can be kept exactly as you had them. For brevity, I'll omit them here but you should
  // add them back in if you need them.

  @override
  Widget build(BuildContext context) {
    final playerManager = Provider.of<PlayerManager>(context, listen: false);
    final themeManager = Provider.of<ThemeManager>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlist.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: widget.isAllSongsPlaylist
          ? null
          : FloatingActionButton.extended(
              onPressed: _addSongsToPlaylist,
              label: Icon(
                Icons.add,
                color: Theme.of(
                  context,
                ).floatingActionButtonTheme.foregroundColor,
              ),
              shape: const CircleBorder(),
            ),
      bottomNavigationBar: Consumer<PlayerManager>(
        builder: (context, pm, child) {
          if (pm.currentSongTitle == null) return const SizedBox.shrink();
          return const MiniPlayer();
        },
      ),
      body: Container(
        // ** UI RESTORED **
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                AppThemes.gradientData[themeManager.appTheme] ??
                AppThemes.darkGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SearchBarWidget(
                controller: _searchController,
                hintText: 'Search in playlist...',
                onChanged: _filterSongs,
              ),
              Expanded(
                child: _songs.isEmpty
                    ? Center(
                        child: Text(
                          "This playlist is empty.\nAdd some songs!",
                          textAlign: TextAlign.center,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(fontSize: 18),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredSongs.length,
                        itemBuilder: (context, index) {
                          final song = _filteredSongs[index];
                          return ListTile(
                            leading: const Icon(Icons.music_note),
                            title: Text(song.title),
                            onTap: () {
                              // This now passes the correct List<Song> type
                              playerManager.play(_filteredSongs, index);
                            },
                            trailing: PopupMenuButton<String>(
                              // ** UI RESTORED **
                              onSelected: (value) {
                                if (value == 'remove') {
                                  _removeSongFromPlaylist(song);
                                } else if (value == 'addToQueue') {
                                  playerManager.addToQueue(song);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${song.title} added to queue.',
                                      ),
                                    ),
                                  );
                                }
                                // Add other options like rename here if needed
                              },
                              itemBuilder: (context) =>
                                  <PopupMenuEntry<String>>[
                                    const PopupMenuItem(
                                      value: 'addToQueue',
                                      child: Text('Add to Queue'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'remove',
                                      child: Text('Remove from Playlist'),
                                    ),
                                  ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
