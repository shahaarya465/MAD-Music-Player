import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'playlist.dart';
import 'player_manager.dart';
import 'mini_player.dart';
import 'add_songs_from_library_screen.dart';
import 'theme.dart';
import 'search_bar_widget.dart';

class Song {
  final String id;
  final String title;
  final String path;
  Song({required this.id, required this.title, required this.path});
}

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
        songList.add(
          Song(
            id: songId,
            title: _musicLibrary[songId]['title'],
            path: _musicLibrary[songId]['path'],
          ),
        );
      }
    }

    setState(() {
      _songs = songList;
      _filteredSongs = songList;
    });
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

  Future<void> _renameSong(Song song, String newTitle) async {
    if (newTitle.trim().isEmpty || newTitle.trim() == song.title) return;
    if (_musicLibrary.containsKey(song.id)) {
      _musicLibrary[song.id]['title'] = newTitle.trim();
      await _libraryFile.writeAsString(jsonEncode(_musicLibrary));
      await _loadSongs();
    }
  }

  Future<void> _removeSongFromPlaylist(Song song) async {
    final updatedSongIDs = List<String>.from(widget.playlist.songIDs)
      ..remove(song.id);
    final playlistJson = {
      "name": widget.playlist.name,
      "songIDs": updatedSongIDs,
    };
    await widget.playlist.file.writeAsString(jsonEncode(playlistJson));
    setState(() {
      _songs.removeWhere((s) => s.id == song.id);
      _filteredSongs.removeWhere((s) => s.id == song.id);
      widget.playlist.songIDs.remove(song.id);
    });
  }

  Future<void> _deleteSongGlobally(Song songToDelete) async {
    final songFile = File(songToDelete.path);
    if (await songFile.exists()) {
      await songFile.delete();
    }

    _musicLibrary.remove(songToDelete.id);
    await _libraryFile.writeAsString(jsonEncode(_musicLibrary));

    final documentsDir = await getApplicationDocumentsDirectory();
    final playlistsDir = Directory(
      '${documentsDir.path}/MAD Music Player/Playlists',
    );
    final playlistFiles = playlistsDir.listSync().whereType<File>().toList();

    for (var file in playlistFiles) {
      final playlist = await Playlist.fromFile(file);
      if (playlist.songIDs.contains(songToDelete.id)) {
        final updatedIDs = List<String>.from(playlist.songIDs)
          ..remove(songToDelete.id);
        final playlistJson = {"name": playlist.name, "songIDs": updatedIDs};
        await file.writeAsString(jsonEncode(playlistJson));
      }
    }

    await _loadSongs();
  }

  Future<void> _showGlobalDeleteConfirmationDialog(Song song) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete from Library?'),
          content: Text(
            'Are you sure you want to permanently delete "${song.title}"? It will be removed from all playlists.',
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text(
                'Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteSongGlobally(song);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRenameDialog(Song song) async {
    final controller = TextEditingController(text: song.title);
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Song'),
        content: Container(
          width: double.maxFinite,
          child: TextField(controller: controller, autofocus: true),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Rename'),
            onPressed: () {
              _renameSong(song, controller.text);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerManager = Provider.of<PlayerManager>(context, listen: false);

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
              label: const Text("Add Songs"),
              icon: const Icon(Icons.add_rounded),
            ),
      bottomNavigationBar: Consumer<PlayerManager>(
        builder: (context, playerManager, child) {
          if (playerManager.currentSongTitle == null)
            return const SizedBox.shrink();
          return MiniPlayer(
            songTitle: playerManager.currentSongTitle!,
            isPlaying: playerManager.isPlaying,
            position: playerManager.position,
            duration: playerManager.duration,
            onPlayPause: () => playerManager.isPlaying
                ? playerManager.pause()
                : playerManager.resume(),
            onPrevious: playerManager.playPrevious,
            onNext: playerManager.playNext,
            onSeek: (value) =>
                playerManager.seek(Duration(seconds: value.toInt())),
            onSeekBackward: playerManager.seekBackward10,
            onSeekForward: playerManager.seekForward10,
          );
        },
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
              hintText: 'Search in playlist...',
              onChanged: _filterSongs,
            ),
            Expanded(
              child: _songs.isEmpty
                  ? Center(
                      child: Text(
                        widget.isAllSongsPlaylist
                            ? "Your library is empty.\nImport songs from the main screen!"
                            : "This playlist is empty.\nAdd some songs!",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredSongs.length,
                      itemBuilder: (context, index) {
                        final song = _filteredSongs[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.music_note,
                            color: Colors.white,
                          ),
                          title: Text(
                            song.title,
                            style: const TextStyle(color: Colors.white),
                          ),
                          onTap: () {
                            final songPathsToPlay = _filteredSongs
                                .map((s) => s.path)
                                .toList();
                            playerManager.play(songPathsToPlay, index);
                          },
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'rename') {
                                _showRenameDialog(song);
                              } else if (value == 'remove') {
                                if (widget.isAllSongsPlaylist) {
                                  _showGlobalDeleteConfirmationDialog(song);
                                } else {
                                  _removeSongFromPlaylist(song);
                                }
                              }
                            },
                            itemBuilder: (context) => <PopupMenuEntry<String>>[
                              const PopupMenuItem(
                                value: 'rename',
                                child: Text('Rename'),
                              ),
                              PopupMenuItem(
                                value: 'remove',
                                child: Text(
                                  widget.isAllSongsPlaylist
                                      ? 'Delete from Library'
                                      : 'Remove from Playlist',
                                ),
                              ),
                            ],
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.white70,
                            ),
                          ),
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
