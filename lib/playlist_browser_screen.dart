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
  List<String> _allSongIDs = [];

  final TextEditingController _searchController = TextEditingController();
  List<Playlist> _filteredPlaylists = [];

  @override
  void initState() {
    super.initState();
    _initAndLoad();
    _searchController.addListener(() {
      _filterPlaylists(_searchController.text);
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

    setState(() {
      _playlists = loadedPlaylists;
      _filteredPlaylists = loadedPlaylists;
      _allSongIDs = libraryContent.keys.toList().cast<String>();
    });
  }

  void _filterPlaylists(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredPlaylists = _playlists;
      });
      return;
    }
    final results = _playlists.where((playlist) {
      return playlist.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
    setState(() {
      _filteredPlaylists = results;
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

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDarkMode = themeManager.themeMode == ThemeMode.dark;

    final allSongsPlaylist = Playlist(
      name: "All Songs",
      songIDs: _allSongIDs,
      file: File(''),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('MAD Music'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.create_new_folder_outlined,
              color: Theme.of(context).iconTheme.color,
            ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _importSongsToLibrary,
        label: Text(
          'Import Songs',
          style: TextStyle(
            color: Theme.of(context).floatingActionButtonTheme.foregroundColor,
          ),
        ),
        icon: Icon(
          Icons.add_to_photos_rounded,
          color: Theme.of(context).floatingActionButtonTheme.foregroundColor,
        ),
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
                hintText: 'Search playlists...',
                onChanged: _filterPlaylists,
              ),
              Expanded(
                child: _playlists.isEmpty && _allSongIDs.isEmpty
                    ? Center(
                        child: Text(
                          "Your library is empty.\nUse the Import button to get started!",
                          textAlign: TextAlign.center,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(fontSize: 18),
                        ),
                      )
                    : _isGridView
                        ? _buildGridView(allSongsPlaylist)
                        : _buildListView(allSongsPlaylist),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListView(Playlist allSongsPlaylist) {
    final fullList = [allSongsPlaylist, ..._filteredPlaylists];
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: fullList.length,
      itemBuilder: (context, index) {
        final playlist = fullList[index];
        final isAllSongs = index == 0;
        return Card(
          color: Theme.of(context).cardColor.withOpacity(0.08),
          margin: const EdgeInsets.only(bottom: 12.0),
          // THIS CONTROLS THE ROUNDED CORNERS FOR LIST VIEW
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Icon(
              isAllSongs
                  ? Icons.library_music_rounded
                  : Icons.music_note_rounded,
              color: Theme.of(context).iconTheme.color,
              size: 30,
            ),
            title: Text(
              playlist.name,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${playlist.songIDs.length} songs',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            trailing: isAllSongs
                ? null
                : PopupMenuButton<String>(
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
                    icon: Icon(
                      Icons.more_vert,
                      color: Theme.of(
                        context,
                      ).iconTheme.color?.withOpacity(0.7),
                    ),
                  ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlaylistDetailScreen(
                    playlist: playlist,
                    isAllSongsPlaylist: isAllSongs,
                  ),
                ),
              );
              _initAndLoad();
            },
          ),
        );
      },
    );
  }

  Widget _buildGridView(Playlist allSongsPlaylist) {
    final fullList = [allSongsPlaylist, ..._filteredPlaylists];
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 1.8, // Previous fix for the overflow
      ),
      itemCount: fullList.length,
      itemBuilder: (context, index) {
        final playlist = fullList[index];
        final isAllSongs = index == 0;
        return Card(
          color: Theme.of(context).cardColor.withOpacity(0.08),
          // THIS CONTROLS THE ROUNDED CORNERS FOR GRID VIEW
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlaylistDetailScreen(
                    playlist: playlist,
                    isAllSongsPlaylist: isAllSongs,
                  ),
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
                      Icon(
                        isAllSongs
                            ? Icons.library_music_rounded
                            : Icons.queue_music_rounded,
                        color: Theme.of(context).iconTheme.color,
                        size: 40,
                      ),
                      const Spacer(),
                      Text(
                        playlist.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${playlist.songIDs.length} songs',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (!isAllSongs)
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
                      icon: Icon(
                        Icons.more_vert,
                        color: Theme.of(
                          context,
                        ).iconTheme.color?.withOpacity(0.7),
                      ),
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