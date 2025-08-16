import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'player_manager.dart';
import 'mini_player.dart';
import 'playlist.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

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

  // This function handles copying songs to /Songs and updating the JSON
  Future<void> _addSongsToPlaylist() async {
    // Let the user pick multiple audio files
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final documentsDir = await getApplicationDocumentsDirectory();

      // UPDATED: Correctly point to the 'MAD Music Player/Songs' folder
      final madMusicPlayerDir = Directory(
        '${documentsDir.path}/MAD Music Player',
      );
      final songsDir = Directory('${madMusicPlayerDir.path}/Songs');

      List<String> newPathsToAdd = [];

      for (var file in result.files) {
        if (file.path != null) {
          final sourceFile = File(file.path!);
          final destPath = p.join(songsDir.path, p.basename(file.path!));

          // Copy the file to the central /Songs directory
          await sourceFile.copy(destPath);

          // Add the *new* path (the pointer) to our list
          newPathsToAdd.add(destPath);
        }
      }

      // Update the playlist's JSON file
      final updatedSongPaths = List<String>.from(_songPaths)
        ..addAll(newPathsToAdd);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlist.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSongsToPlaylist,
        label: const Text("Add Songs"),
        icon: const Icon(Icons.add_rounded),
      ),
      bottomNavigationBar: Consumer<PlayerManager>(
        builder: (context, playerManager, child) {
          if (playerManager.currentSongTitle == null) {
            return const SizedBox.shrink();
          }
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
            // UPDATED: Corrected onSeek logic and hooked up seek buttons
            onSeek: (value) {
              final newPosition = Duration(seconds: value.toInt());
              playerManager.seek(newPosition);
            },
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
                ? [const Color(0xFF232A4E), const Color(0xFF171925)]
                : [const Color(0xFF6D5DF6), const Color(0xFF38B6FF)],
          ),
        ),
        child: _songPaths.isEmpty
            ? const Center(
                child: Text(
                  "This playlist is empty.\nAdd some songs to get started!",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
              )
            : ListView.builder(
                itemCount: _songPaths.length,
                itemBuilder: (context, index) {
                  final songPath = _songPaths[index];
                  final songTitle = p.basenameWithoutExtension(songPath);
                  final playerManager = Provider.of<PlayerManager>(
                    context,
                    listen: false,
                  );
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
