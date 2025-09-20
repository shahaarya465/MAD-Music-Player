import 'dart:io';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';

import '../models/playlist.dart';
import '../models/song.dart';
import '../providers/player_manager.dart';
import '../widgets/mini_player.dart';
import 'add_songs_from_library_screen.dart';
import '../widgets/search_bar_widget.dart';
import '../services/import_service.dart';

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

  final ImportService _importService = ImportService();

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

  Future<File> _getLibraryFile() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final madMusicPlayerDir =
        Directory('${documentsDir.path}/MAD Music Player');
    return File('${madMusicPlayerDir.path}/library.json');
  }

  Future<void> _refreshPlaylist() async {
    if (widget.playlist.url == null) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Refreshing playlist...')),
    );

    try {
      final Map<String, List<Song>> importedData =
          await _importService.importPlaylist(widget.playlist.url!);
      final onlineSongs = importedData.values.first;
      final newSongIds = onlineSongs.map((s) => s.id).toSet();

      final libraryFile = await _getLibraryFile();
      final libraryContent = jsonDecode(await libraryFile.readAsString());

      for (final song in onlineSongs) {
        if (!libraryContent.containsKey(song.id)) {
          libraryContent[song.id] = {
            'title': song.title,
            'videoId': song.videoId,
            'type': 'online',
          };
        }
      }
      await libraryFile.writeAsString(jsonEncode(libraryContent));

      final playlistJson = {
        "name": widget.playlist.name,
        "songIDs": newSongIds.toList(),
        "url": widget.playlist.url,
      };
      await widget.playlist.file.writeAsString(jsonEncode(playlistJson));

      await _loadSongs();

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Playlist refreshed!')),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
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

    final freshPlaylist = await Playlist.fromFile(widget.playlist.file);

    final songIdsToLoad = widget.isAllSongsPlaylist
        ? _musicLibrary.keys.toList()
        : freshPlaylist.songIDs;

    final songList = <Song>[];
    for (String songId in songIdsToLoad) {
      if (_musicLibrary.containsKey(songId)) {
        final details = _musicLibrary[songId];
        if (details['type'] == 'online') {
          songList.add(
            Song(
              id: songId,
              title: details['title'],
              videoId: details['videoId'],
              type: SongType.online,
            ),
          );
        } else {
          songList.add(
            Song(
              id: songId,
              title: details['title'],
              path: details['path'],
              type: SongType.local,
            ),
          );
        }
      }
    }

    if (mounted) {
      setState(() {
        _songs = songList;
        _filteredSongs = songList;
      });
    }
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
        "url": widget.playlist.url,
      };
      await widget.playlist.file.writeAsString(jsonEncode(playlistJson));
      await _loadSongs();
    }
  }

  Future<void> _removeSongFromPlaylist(Song song) async {
    widget.playlist.songIDs.remove(song.id);
    final playlistJson = {
      "name": widget.playlist.name,
      "songIDs": widget.playlist.songIDs,
      "url": widget.playlist.url,
    };
    await widget.playlist.file.writeAsString(jsonEncode(playlistJson));
    await _loadSongs();
  }

  @override
  Widget build(BuildContext context) {
    final playerManager = Provider.of<PlayerManager>(context, listen: false);
    final theme = Theme.of(context);
    final bool showAddButton =
        !widget.isAllSongsPlaylist && widget.playlist.url == null;

    return Scaffold(
      bottomNavigationBar: Consumer<PlayerManager>(
        builder: (context, pm, child) {
          if (pm.currentSongTitle == null) return const SizedBox.shrink();
          return const MiniPlayer();
        },
      ),
      floatingActionButton: showAddButton
          ? FloatingActionButton(
              onPressed: _addSongsToPlaylist,
              child: const Icon(Icons.add),
            )
          : null,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 300.0,
            backgroundColor: theme.scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Blurred Background
                  Image.asset(
                    'assets/icon/icon.png',
                    fit: BoxFit.cover,
                  ),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ),
                  // Centered Album Art with Scaling
                  Center(
                    child: Transform.scale(
                      scale: 2.0, // This makes the logo 2x bigger
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: const DecorationImage(
                            image: AssetImage('assets/icon/icon.png'),
                            fit: BoxFit.cover,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (widget.playlist.url != null)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshPlaylist,
                  tooltip: 'Refresh Playlist',
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    widget.playlist.name,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Playlist • ${_songs.length} Songs',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          playerManager.toggleShuffle();
                          if (_filteredSongs.isNotEmpty) {
                            playerManager.play(_filteredSongs, 0);
                          }
                        },
                        icon: const Icon(Icons.shuffle),
                        tooltip: 'Shuffle Play',
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (_filteredSongs.isNotEmpty) {
                            playerManager.play(_filteredSongs, 0);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(16),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                        child: const Icon(Icons.play_arrow),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  SearchBarWidget(
                    controller: _searchController,
                    hintText: 'Search in playlist...',
                    onChanged: _filterSongs,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final song = _filteredSongs[index];
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.asset(
                      'assets/icon/icon.png',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(song.title),
                  subtitle: Text(
                    song.type == SongType.local ? "Local Song" : "Online",
                  ),
                  onTap: () {
                    playerManager.play(_filteredSongs, index);
                  },
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'remove') {
                        _removeSongFromPlaylist(song);
                      } else if (value == 'addToQueue') {
                        playerManager.addToQueue(song);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${song.title} added to queue.'),
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem(
                        value: 'addToQueue',
                        child: Text('Add to Queue'),
                      ),
                      if (!widget.isAllSongsPlaylist &&
                          widget.playlist.url == null)
                        const PopupMenuItem(
                          value: 'remove',
                          child: Text('Remove from Playlist'),
                        ),
                    ],
                  ),
                );
              },
              childCount: _filteredSongs.length,
            ),
          ),
        ],
      ),
    );
  }
}
