import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'playlist.dart';
import 'theme_manager.dart';
import 'player_manager.dart';
import 'mini_player.dart';
import 'playlist_detail_screen.dart';
import 'search_bar_widget.dart';
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

  // State for search
  final TextEditingController _searchController = TextEditingController();
  List<Song> _allSongs = [];
  List<Song> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _initAndLoad();
    _searchController.addListener(() {
      _searchLibrary(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initAndLoad() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final madMusicPlayerDir = Directory(
      '${documentsDir.path}/MAD Music Player',
    );
    if (!await madMusicPlayerDir.exists()) await madMusicPlayerDir.create();

    _playlistsDir = Directory('${madMusicPlayerDir.path}/Playlists');
    _songsDir = Directory('${madMusicPlayerDir.path}/Songs');
    final libraryFile = File('${madMusicPlayerDir.path}/library.json');

    if (!await _playlistsDir.exists()) await _playlistsDir.create();
    if (!await _songsDir.exists()) await _songsDir.create();
    if (!await libraryFile.exists()) await libraryFile.writeAsString('{}');

    final List<Playlist> loadedPlaylists = [];
    final entities = _playlistsDir.listSync();
    for (var entity in entities) {
      if (entity is File && entity.path.endsWith('.json')) {
        loadedPlaylists.add(await Playlist.fromFile(entity));
      }
    }

    final libraryContent = jsonDecode(await libraryFile.readAsString());
    final List<Song> allSongsList = [];
    libraryContent.forEach((id, details) {
      allSongsList.add(
        Song(id: id, title: details['title'], path: details['path']),
      );
    });

    setState(() {
      _playlists = loadedPlaylists;
      _allSongs = allSongsList;
    });
  }

  // UPDATED: This function now searches the entire song library
  void _searchLibrary(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }
    final results = _allSongs.where((song) {
      return song.title.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      _searchResults = results;
    });
  }

  Future<void> _importSongsToLibrary() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final madMusicPlayerDir = Directory(
        (await getApplicationDocumentsDirectory()).path + '/MAD Music Player',
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
      await _initAndLoad();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported $importCount new songs to your library.'),
          ),
        );
      }
    }
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
    final initialContent = {"name": trimmedName, "songIDs": []};
    await newPlaylistFile.writeAsString(jsonEncode(initialContent));
    await _initAndLoad();
  }

  Future<void> _deletePlaylist(Playlist playlist) async {
    await playlist.file.delete();
    await _initAndLoad();
  }

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
    final updatedContent = {"name": trimmedName, "songIDs": playlist.songIDs};
    await playlist.file.rename(newFile.path);
    await newFile.writeAsString(jsonEncode(updatedContent));

    await _initAndLoad();
  }

  Future<void> _showCreatePlaylistDialog() async {
    final controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Playlist'),
          content: Container(
            width: double.maxFinite,
            child: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: "Enter playlist name",
              ),
            ),
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

  Widget _buildSearchResults() {
    final playerManager = Provider.of<PlayerManager>(context, listen: false);
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final song = _searchResults[index];
        return ListTile(
          leading: const Icon(Icons.music_note, color: Colors.white),
          title: Text(song.title, style: const TextStyle(color: Colors.white)),
          onTap: () {
            final searchPaths = _searchResults.map((s) => s.path).toList();
            playerManager.play(searchPaths, index);
          },
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
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: 'New Playlist',
            onPressed: _showCreatePlaylistDialog,
          ),
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
      // NEW: Added the Drawer (sidebar menu)
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6D5DF6), Color(0xFF38B6FF)],
                ),
              ),
              child: Text(
                'MAD Music Player',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.library_music_rounded),
              title: const Text('All Songs'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                final allSongsPlaylist = Playlist(
                  name: "All Songs",
                  songIDs: _allSongs.map((s) => s.id).toList(),
                  file: File(''),
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlaylistDetailScreen(
                      playlist: allSongsPlaylist,
                      isAllSongsPlaylist: true,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _importSongsToLibrary,
        label: const Text('Import Songs'),
        icon: const Icon(Icons.add_to_photos_rounded),
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
          child: Column(
            children: [
              SearchBarWidget(
                controller: _searchController,
                hintText: 'Search your library...',
                onChanged: _searchLibrary,
              ),
              Expanded(
                child: _searchController.text.isNotEmpty
                    ? _buildSearchResults()
                    : _playlists.isEmpty
                    ? const Center(
                        child: Text(
                          "No playlists created yet.\nUse the '+' icon to create one!",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 18),
                        ),
                      )
                    : _isGridView
                    ? _buildGridView()
                    : _buildListView(),
              ),
            ],
          ),
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
              '${playlist.songIDs.length} songs',
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'rename')
                  _showRenameDialog(playlist);
                else if (value == 'delete')
                  _showDeleteConfirmationDialog(playlist);
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
              _initAndLoad();
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
              _initAndLoad();
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
                        '${playlist.songIDs.length} songs',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'rename')
                        _showRenameDialog(playlist);
                      else if (value == 'delete')
                        _showDeleteConfirmationDialog(playlist);
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
