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
import '../services/import_service.dart';

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

  final ImportService _importService = ImportService();

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

  Future<File> _getLibraryFile() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final madMusicPlayerDir =
        Directory('${documentsDir.path}/MAD Music Player');
    return File('${madMusicPlayerDir.path}/library.json');
  }

  Future<void> _refreshPlaylist() async {
    if (widget.playlist.url == null) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Refreshing playlist...')),
    );

    try {
      final Map<String, List<Song>> importedData =
          await _importService.importPlaylist(widget.playlist.url!);
      final onlineSongs = importedData.values.first;
      final newSongIds = onlineSongs.map((s) => s.id).toSet();

      final libraryFile = await _getLibraryFile();
      final libraryContent = jsonDecode(await libraryFile.readAsString());

      for (final song in onlineSongs) {
        if (!libraryContent.containsKey(song.id)) {
          libraryContent[song.id] = {
            'title': song.title,
            'videoId': song.videoId,
            'type': 'online',
          };
        }
      }
      await libraryFile.writeAsString(jsonEncode(libraryContent));

      final playlistJson = {
        "name": widget.playlist.name,
        "songIDs": newSongIds.toList(),
        "url": widget.playlist.url,
      };
      await widget.playlist.file.writeAsString(jsonEncode(playlistJson));

      await _loadSongs();

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Playlist refreshed!')),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

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

    final freshPlaylist = await Playlist.fromFile(widget.playlist.file);

    final songIdsToLoad = widget.isAllSongsPlaylist
        ? _musicLibrary.keys.toList()
        : freshPlaylist.songIDs;

    final songList = <Song>[];
    for (String songId in songIdsToLoad) {
      if (_musicLibrary.containsKey(songId)) {
        final details = _musicLibrary[songId];
        if (details['type'] == 'online') {
          songList.add(
            Song(
              id: songId,
              title: details['title'],
              videoId: details['videoId'],
              type: SongType.online,
            ),
          );
        } else {
          songList.add(
            Song(
              id: songId,
              title: details['title'],
              path: details['path'],
              type: SongType.local,
            ),
          );
        }
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
        "url": widget.playlist.url,
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
      "url": widget.playlist.url,
    };
    await widget.playlist.file.writeAsString(jsonEncode(playlistJson));
    await _loadSongs();
  }

  @override
  Widget build(BuildContext context) {
    final playerManager = Provider.of<PlayerManager>(context, listen: false);
    final themeManager = Provider.of<ThemeManager>(context);

    final bool showAddButton =
        !widget.isAllSongsPlaylist && widget.playlist.url == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlist.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (widget.playlist.url != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshPlaylist,
              tooltip: 'Refresh Playlist',
            ),
        ],
      ),
      floatingActionButton: showAddButton
          ? FloatingActionButton.extended(
              onPressed: _addSongsToPlaylist,
              label: Icon(
                Icons.add,
                color: Theme.of(
                  context,
                ).floatingActionButtonTheme.foregroundColor,
              ),
              shape: const CircleBorder(),
            )
          : null,
      bottomNavigationBar: Consumer<PlayerManager>(
        builder: (context, pm, child) {
          if (pm.currentSongTitle == null) return const SizedBox.shrink();
          return const MiniPlayer();
        },
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppThemes.gradientData[themeManager.appTheme] ??
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
                          "This playlist is empty.",
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
                            leading: Icon(
                              song.type == SongType.local
                                  ? Icons.music_note
                                  : Icons.cloud_queue,
                              color: Theme.of(context).iconTheme.color,
                            ),
                            title: Text(song.title),
                            onTap: () {
                              playerManager.play(_filteredSongs, index);
                            },
                            trailing: PopupMenuButton<String>(
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
                              },
                              itemBuilder: (context) =>
                                  <PopupMenuEntry<String>>[
                                const PopupMenuItem(
                                  value: 'addToQueue',
                                  child: Text('Add to Queue'),
                                ),
                                if (!widget.isAllSongsPlaylist &&
                                    widget.playlist.url == null)
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
