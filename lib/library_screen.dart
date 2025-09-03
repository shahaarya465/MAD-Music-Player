import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'playlist.dart';
import 'playlist_detail_screen.dart';
import 'search_bar_widget.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  _LibraryScreenState createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _isGridView = false;
  List<Playlist> _playlists = [];
  late Directory _playlistsDir;
  late Directory _songsDir;

  // REMOVED: _allSongIDs is no longer needed in this screen's state
  // List<String> _allSongIDs = [];

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

    // REMOVED: Logic for loading all song IDs

    setState(() {
      _playlists = loadedPlaylists;
      _filteredPlaylists = loadedPlaylists;
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
    // REMOVED: The allSongsPlaylist object is no longer created here.

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
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
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePlaylistDialog,
        label: Text(
          'New Playlist',
          style: TextStyle(
            color: Theme.of(context).floatingActionButtonTheme.foregroundColor,
          ),
        ),
        icon: Icon(
          Icons.playlist_add,
          color: Theme.of(context).floatingActionButtonTheme.foregroundColor,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            SearchBarWidget(
              controller: _searchController,
              hintText: 'Search playlists...',
              onChanged: _filterPlaylists,
            ),
            Expanded(
              child: _playlists.isEmpty
                  ? Center(
                      child: Text(
                        "No playlists created yet.\nTap the button below to create one!",
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(fontSize: 18),
                      ),
                    )
                  // CHANGED: Removed the check for _allSongIDs
                  : _isGridView
                  ? _buildGridView()
                  : _buildListView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    // CHANGED: The list now only contains the filtered playlists.
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _filteredPlaylists.length,
      itemBuilder: (context, index) {
        final playlist = _filteredPlaylists[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          color: Theme.of(context).cardColor.withOpacity(0.08),
          margin: const EdgeInsets.only(bottom: 12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          child: ListTile(
            tileColor: Colors.transparent,
            // CHANGED: Removed conditional icon logic
            leading: Icon(
              Icons.music_note_rounded,
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
            // CHANGED: Removed conditional trailing logic
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
              icon: Icon(
                Icons.more_vert,
                color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
              ),
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
    // CHANGED: The list now only contains the filtered playlists.
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200.0,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 1.0,
      ),
      itemCount: _filteredPlaylists.length,
      itemBuilder: (context, index) {
        final playlist = _filteredPlaylists[index];
        return Card(
          color: Theme.of(context).cardColor.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
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
            borderRadius: BorderRadius.circular(24.0),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // CHANGED: Removed conditional icon logic
                      Icon(
                        Icons.queue_music_rounded,
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
                // CHANGED: Removed conditional logic for the popup menu
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
