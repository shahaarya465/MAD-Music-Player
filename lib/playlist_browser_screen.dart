import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'playlist.dart';
import 'theme_manager.dart';
import 'player_manager.dart';
import 'mini_player.dart';
import 'playlist_detail_screen.dart';
import 'theme.dart';

class PlaylistBrowserScreen extends StatefulWidget {
  const PlaylistBrowserScreen({super.key});

  @override
  _PlaylistBrowserScreenState createState() => _PlaylistBrowserScreenState();
}

class _PlaylistBrowserScreenState extends State<PlaylistBrowserScreen> {
  bool _isGridView = false;
  List<Playlist> _playlists = [];
  late Directory _playlistsDir;
  late Directory _songsDir;

  @override
  void initState() {
    super.initState();
    _initDirectoriesAndLoadPlaylists();
  }

  Future<void> _initDirectoriesAndLoadPlaylists() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final madMusicPlayerDir = Directory(
      '${documentsDir.path}/MAD Music Player',
    );
    if (!await madMusicPlayerDir.exists()) {
      await madMusicPlayerDir.create();
    }
    _playlistsDir = Directory('${madMusicPlayerDir.path}/Playlists');
    _songsDir = Directory('${madMusicPlayerDir.path}/Songs');
    if (!await _playlistsDir.exists()) await _playlistsDir.create();
    if (!await _songsDir.exists()) await _songsDir.create();
    final List<Playlist> loadedPlaylists = [];
    final entities = _playlistsDir.listSync();
    for (var entity in entities) {
      if (entity is File && entity.path.endsWith('.json')) {
        loadedPlaylists.add(await Playlist.fromFile(entity));
      }
    }
    setState(() {
      _playlists = loadedPlaylists;
    });
  }

  Future<void> _createPlaylist(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;
    final newPlaylistFile = File('${_playlistsDir.path}/$trimmedName.json');
    if (await newPlaylistFile.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('A playlist named "$trimmedName" already exists.'),
          ),
        );
      }
      return;
    }
    final initialContent = {"name": trimmedName, "songPaths": []};
    await newPlaylistFile.writeAsString(jsonEncode(initialContent));
    await _initDirectoriesAndLoadPlaylists();
  }

  // NEW: Function to handle deleting a playlist
  Future<void> _deletePlaylist(Playlist playlist) async {
    await playlist.file.delete();
    // Note: This only deletes the playlist file, not the songs in the /Songs folder.
    await _initDirectoriesAndLoadPlaylists();
  }

  // NEW: Function to handle renaming a playlist
  Future<void> _renamePlaylist(Playlist playlist, String newName) async {
    final trimmedName = newName.trim();
    if (trimmedName.isEmpty || trimmedName == playlist.name) return;

    final newFile = File('${_playlistsDir.path}/$trimmedName.json');
    if (await newFile.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('A playlist named "$trimmedName" already exists.'),
          ),
        );
      }
      return;
    }

    // Update the content and move the file
    final updatedContent = {
      "name": trimmedName,
      "songPaths": playlist.songPaths,
    };
    await playlist.file.rename(newFile.path);
    await newFile.writeAsString(jsonEncode(updatedContent));

    await _initDirectoriesAndLoadPlaylists();
  }

  // NEW: Dialog for renaming a playlist
  Future<void> _showRenameDialog(Playlist playlist) async {
    final controller = TextEditingController(text: playlist.name);
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Playlist'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: "Enter new name"),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Rename'),
              onPressed: () {
                _renamePlaylist(playlist, controller.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // NEW: Confirmation dialog for deleting a playlist
  Future<void> _showDeleteConfirmationDialog(Playlist playlist) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Playlist?'),
          content: Text(
            'Are you sure you want to delete the playlist "${playlist.name}"? This cannot be undone.',
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
                _deletePlaylist(playlist);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCreatePlaylistDialog() async {
    final controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Playlist'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: "Enter playlist name"),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Create'),
              onPressed: () {
                _createPlaylist(controller.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDarkMode = themeManager.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MAD Music Player'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
            ),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            onPressed: () => themeManager.toggleTheme(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePlaylistDialog,
        label: const Text('New Playlist'),
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
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? AppThemes.darkGradient
                : AppThemes.lightGradient,
          ),
        ),
        child: SafeArea(
          child: _playlists.isEmpty
              ? const Center(
                  child: Text(
                    "No playlists found.\nCreate one to get started!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                )
              : _isGridView
              ? _buildGridView()
              : _buildListView(),
        ),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _playlists.length,
      itemBuilder: (context, index) {
        final playlist = _playlists[index];
        return Card(
          color: Colors.white.withOpacity(0.1),
          margin: const EdgeInsets.only(bottom: 12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const Icon(
              Icons.music_note_rounded,
              color: Colors.white,
              size: 30,
            ),
            title: Text(
              playlist.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${playlist.songPaths.length} songs',
              style: const TextStyle(color: Colors.white70),
            ),
            // UPDATED: Replaced Icon with a PopupMenuButton
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'rename') {
                  _showRenameDialog(playlist);
                } else if (value == 'delete') {
                  _showDeleteConfirmationDialog(playlist);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'rename',
                  child: Text('Rename'),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
              icon: const Icon(Icons.more_vert, color: Colors.white70),
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PlaylistDetailScreen(playlist: playlist),
                ),
              );
              _initDirectoriesAndLoadPlaylists();
            },
          ),
        );
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      ),
      itemCount: _playlists.length,
      itemBuilder: (context, index) {
        final playlist = _playlists[index];
        return Card(
          color: Colors.white.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PlaylistDetailScreen(playlist: playlist),
                ),
              );
              _initDirectoriesAndLoadPlaylists();
            },
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.queue_music_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                      const Spacer(),
                      Text(
                        playlist.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${playlist.songPaths.length} songs',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                // UPDATED: Added a PopupMenuButton to the grid view as well
                Positioned(
                  top: 4,
                  right: 4,
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'rename') {
                        _showRenameDialog(playlist);
                      } else if (value == 'delete') {
                        _showDeleteConfirmationDialog(playlist);
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'rename',
                            child: Text('Rename'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                    icon: const Icon(Icons.more_vert, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
