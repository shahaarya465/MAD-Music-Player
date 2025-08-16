import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import 'playlist.dart';
import 'player_manager.dart';
import 'mini_player.dart';
import 'add_songs_from_library_screen.dart'; // NEW import
import 'theme.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;
  final bool isAllSongsPlaylist; // To know if this is the special playlist

  const PlaylistDetailScreen({
    super.key,
    required this.playlist,
    this.isAllSongsPlaylist = false,
  });

  @override
  _PlaylistDetailScreenState createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  late List<String> _songPaths;

  @override
  void initState() {
    super.initState();
    _songPaths = List.from(widget.playlist.songPaths);
  }

  // UPDATED: This function now opens the library screen to add songs
  Future<void> _addSongsToPlaylist() async {
    // Navigate to the new screen and wait for the result
    final selectedSongs = await Navigator.push<Set<String>>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddSongsFromLibraryScreen(existingSongPaths: _songPaths.toSet()),
      ),
    );

    if (selectedSongs != null && selectedSongs.isNotEmpty) {
      // Update the playlist's JSON file
      final updatedSongPaths = List<String>.from(_songPaths)
        ..addAll(selectedSongs);
      final playlistJson = {
        "name": widget.playlist.name,
        "songPaths": updatedSongPaths,
      };
      await widget.playlist.file.writeAsString(jsonEncode(playlistJson));

      // Update the UI
      setState(() {
        _songPaths = updatedSongPaths;
      });
    }
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
      // Only show the "Add Songs" button for user-created playlists
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
        child: _songPaths.isEmpty
            ? Center(
                child: Text(
                  widget.isAllSongsPlaylist
                      ? "Your library is empty.\nImport songs from the main screen!"
                      : "This playlist is empty.\nAdd some songs!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
              )
            : ListView.builder(
                itemCount: _songPaths.length,
                itemBuilder: (context, index) {
                  final songPath = _songPaths[index];
                  final songTitle = p.basenameWithoutExtension(songPath);
                  return ListTile(
                    leading: const Icon(Icons.music_note, color: Colors.white),
                    title: Text(
                      songTitle,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      playerManager.play(_songPaths, index);
                    },
                  );
                },
              ),
      ),
    );
  }
}
