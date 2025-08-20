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
  List<Playlist> _playlists = [];
  late Directory _playlistsDir;
  late Directory _songsDir;

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
              isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            onPressed: () => themeManager.toggleTheme(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _importSongsToLibrary,
        label: const Text('Import Songs'),
        icon: const Icon(Icons.add_to_photos_rounded),
      ),
      // ADDED: MiniPlayer is back
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
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SearchBarWidget(
                  controller: _searchController,
                  hintText: 'Search songs, playlists...',
                  onChanged: _searchLibrary,
                ),
              ),
              if (_searchController.text.isNotEmpty)
                _buildSliverSearchResults()
              else ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Playlists',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                _buildPlaylistsGrid(),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      'Recently Played',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                _buildRecentsGrid(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistsGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 12.0,
          // UPDATED: Aspect ratio changed to make items shorter
          childAspectRatio: 6.0,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final playlist = _playlists[index];
          return Card(
            clipBehavior: Clip.antiAlias,
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
              child: Row(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      color: Colors.grey.withOpacity(0.3),
                      child: const Icon(Icons.music_note, size: 30),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      playlist.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }, childCount: _playlists.length),
      ),
    );
  }

  Widget _buildRecentsGrid() {
    return Consumer<PlayerManager>(
      builder: (context, playerManager, child) {
        final recentSongIDs = playerManager.recentlyPlayedSongIDs;
        final recentSongs = recentSongIDs
            .map(
              (id) => _allSongs.firstWhere(
                (song) => song.id == id,
                orElse: () => Song(id: '', title: '', path: ''),
              ),
            )
            .where((song) => song.id.isNotEmpty)
            .toList();

        if (recentSongs.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              // UPDATED: Aspect ratio changed to make items shorter
              childAspectRatio: 6.0,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final song = recentSongs[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    playerManager.play(recentSongs, index);
                  },
                  child: Row(
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          color: Colors.grey.withOpacity(0.3),
                          child: const Icon(Icons.play_arrow, size: 30),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          song.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }, childCount: recentSongs.length),
          ),
        );
      },
    );
  }

  Widget _buildSliverSearchResults() {
    final playerManager = Provider.of<PlayerManager>(context, listen: false);
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final song = _searchResults[index];
        return ListTile(
          leading: const Icon(Icons.music_note, color: Colors.white),
          title: Text(song.title, style: const TextStyle(color: Colors.white)),
          onTap: () {
            playerManager.play(_searchResults, index);
          },
        );
      }, childCount: _searchResults.length),
    );
  }
}
