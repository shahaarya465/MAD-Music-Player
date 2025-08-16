import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'theme_manager.dart';
import 'playlist_detail_screen.dart';

class Playlist {
  final String name;
  final List<String> songPaths;
  final File file;

  Playlist({required this.name, required this.songPaths, required this.file});

  static Future<Playlist> fromFile(File file) async {
    final content = await file.readAsString();
    final json = jsonDecode(content);
    return Playlist(
      name: json['name'],
      songPaths: List<String>.from(json['songPaths']),
      file: file,
    );
  }
}

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  _MusicPlayerScreenState createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
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
    final lightGradient = [const Color(0xFF6D5DF6), const Color(0xFF38B6FF)];
    final darkGradient = [const Color(0xFF232A4E), const Color(0xFF171925)];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Playlists'),
        // ... (rest of AppBar is the same)
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode ? darkGradient : lightGradient,
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
            trailing: const Icon(Icons.more_vert, color: Colors.white70),
            // UPDATED: onTap now navigates to the detail screen
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PlaylistDetailScreen(playlist: playlist),
                ),
              );
              // After returning, reload playlists to reflect any changes in song count
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
            // UPDATED: onTap now navigates to the detail screen
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PlaylistDetailScreen(playlist: playlist),
                ),
              );
              // After returning, reload playlists to reflect any changes in song count
              _initDirectoriesAndLoadPlaylists();
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
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
          ),
        );
      },
    );
  }
}
