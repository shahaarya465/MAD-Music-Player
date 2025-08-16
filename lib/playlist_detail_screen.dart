import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:uuid/uuid.dart';
import 'playlist.dart';
import 'player_manager.dart';
import 'mini_player.dart';
import 'add_songs_from_library_screen.dart';
import 'theme.dart';

// NEW: A simple class to represent a fully loaded song
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

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    // Load the central music library
    final documentsDir = await getApplicationDocumentsDirectory();
    final madMusicPlayerDir = Directory(
      '${documentsDir.path}/MAD Music Player',
    );
    _libraryFile = File('${madMusicPlayerDir.path}/library.json');

    if (await _libraryFile.exists()) {
      _musicLibrary = jsonDecode(await _libraryFile.readAsString());
    }

    // Get the song objects for the current playlist
    final songList = <Song>[];
    for (String songId in widget.playlist.songIDs) {
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
    });
  }

  Future<void> _addSongsToPlaylist() async {
    // Navigate to the new screen and wait for the result (a Set of song IDs)
    final selectedSongIDs = await Navigator.push<Set<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => AddSongsFromLibraryScreen(
          existingSongIDs: _songs.map((s) => s.id).toSet(),
        ),
      ),
    );

    if (selectedSongIDs != null && selectedSongIDs.isNotEmpty) {
      // Update the playlist's JSON file with the new song IDs
      final updatedSongIDs = List<String>.from(widget.playlist.songIDs)
        ..addAll(selectedSongIDs);
      final playlistJson = {
        "name": widget.playlist.name,
        "songIDs": updatedSongIDs,
      };
      await widget.playlist.file.writeAsString(jsonEncode(playlistJson));

      // Reload the songs to update the UI
      await _loadSongs();
    }
  }

  // NEW: Rename a song globally
  Future<void> _renameSong(Song song, String newTitle) async {
    if (newTitle.trim().isEmpty || newTitle.trim() == song.title) return;

    // Update the title in our central library
    if (_musicLibrary.containsKey(song.id)) {
      _musicLibrary[song.id]['title'] = newTitle.trim();
      await _libraryFile.writeAsString(jsonEncode(_musicLibrary));
      await _loadSongs(); // Refresh the screen
    }
  }

  // NEW: Remove a song from this specific playlist
  Future<void> _removeSongFromPlaylist(Song song) async {
    final updatedSongIDs = List<String>.from(widget.playlist.songIDs)
      ..remove(song.id);
    final playlistJson = {
      "name": widget.playlist.name,
      "songIDs": updatedSongIDs,
    };
    await widget.playlist.file.writeAsString(jsonEncode(playlistJson));
    await _loadSongs(); // Refresh the screen
  }

  Future<void> _showRenameDialog(Song song) async {
    final controller = TextEditingController(text: song.title);
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Song'),
        content: TextField(controller: controller, autofocus: true),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            _addSongsToPlaylist, // We'll update this workflow in the next step
        label: const Text("Add Songs"),
        icon: const Icon(Icons.add_rounded),
      ),
      bottomNavigationBar: Consumer<PlayerManager>(
        // ... (bottomNavigationBar code is the same)
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
        child: _songs.isEmpty
            ? const Center(/* ... child remains the same ... */)
            : ListView.builder(
                itemCount: _songs.length,
                itemBuilder: (context, index) {
                  final song = _songs[index];
                  return ListTile(
                    leading: const Icon(Icons.music_note, color: Colors.white),
                    title: Text(
                      song.title,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      // Pass the list of file paths to the player
                      final songPathsToPlay = _songs
                          .map((s) => s.path)
                          .toList();
                      playerManager.play(songPathsToPlay, index);
                    },
                    // NEW: Menu for each song
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'rename') {
                          _showRenameDialog(song);
                        } else if (value == 'remove') {
                          // This is where the logic splits
                          if (widget.isAllSongsPlaylist) {
                            // TODO: Implement global delete confirmation
                            print("Global delete not implemented yet.");
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
                      icon: const Icon(Icons.more_vert, color: Colors.white70),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
