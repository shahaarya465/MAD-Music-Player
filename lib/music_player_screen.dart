import 'dart:io';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'song_list_widget.dart';
import 'mini_player.dart';
import 'theme_manager.dart';

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  _MusicPlayerScreenState createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  List<String> _songPaths = [];
  List<String> _songTitles = [];
  int? _currentSongIndex;

  @override
  void initState() {
    super.initState();
    _loadPlaylist();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          _duration = newDuration;
        });
      }
    });
    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          _position = newPosition;
        });
      }
    });
  }

  Future<void> _savePlaylist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('song_paths', _songPaths);
    await prefs.setStringList('song_titles', _songTitles);
    await prefs.setInt('last_index', _currentSongIndex ?? -1);
  }

  Future<void> _loadPlaylist() async {
    final prefs = await SharedPreferences.getInstance();
    final paths = prefs.getStringList('song_paths');
    final titles = prefs.getStringList('song_titles');
    final lastIndex = prefs.getInt('last_index');
    if (paths != null && titles != null) {
      setState(() {
        _songPaths = paths;
        _songTitles = titles;
        _currentSongIndex = (lastIndex != null && lastIndex != -1)
            ? lastIndex
            : null;
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty) {
      List<String> selectedPaths = result.files.map((f) => f.path!).toList();
      List<String> newPaths = selectedPaths
          .where((p) => !_songPaths.contains(p))
          .toList();
      List<String> newTitles = [];
      for (final path in newPaths) {
        String title = p.basename(path);
        try {
          final metadata = await MetadataRetriever.fromFile(File(path));
          if (metadata.trackName != null &&
              metadata.trackName!.trim().isNotEmpty) {
            title = metadata.trackName!;
          }
        } catch (e) {
          // ignore and use filename
        }
        final uuidRegex = RegExp(r'^[0-9a-fA-F\-]{32,}$');
        final isUuid = uuidRegex.hasMatch(
          title.replaceAll('.', '').replaceAll('-', ''),
        );
        if (title.trim().isEmpty || isUuid) {
          title = p.basenameWithoutExtension(path);
        }
        newTitles.add(title);
      }
      if (mounted) {
        setState(() {
          _songPaths.addAll(newPaths);
          _songTitles.addAll(newTitles);
          if (_currentSongIndex == null && _songPaths.isNotEmpty) {
            _currentSongIndex = 0;
            _play(_currentSongIndex!);
          }
        });
        _savePlaylist();
      }
    }
  }

  Future<void> _play(int index) async {
    if (index >= 0 && index < _songPaths.length) {
      await _audioPlayer.play(DeviceFileSource(_songPaths[index]));
      if (mounted) {
        setState(() {
          _currentSongIndex = index;
        });
        _savePlaylist();
      }
    }
  }

  Future<void> _resume() async {
    if (_currentSongIndex != null && _currentSongIndex! < _songPaths.length) {
      await _audioPlayer.resume();
    }
  }

  Future<void> _pause() async {
    await _audioPlayer.pause();
  }

  Future<void> _playNext() async {
    if (_currentSongIndex != null) {
      int nextIndex = _currentSongIndex! + 1;
      if (nextIndex >= _songPaths.length) {
        nextIndex = 0;
      }
      await _play(nextIndex);
    }
  }

  Future<void> _playPrevious() async {
    if (_currentSongIndex != null) {
      int prevIndex = _currentSongIndex! - 1;
      if (prevIndex < 0) {
        prevIndex = _songPaths.length - 1;
      }
      await _play(prevIndex);
    }
  }

  void _seekForward() {
    if (_duration == Duration.zero) return;
    final newPosition = _position + const Duration(seconds: 10);
    _audioPlayer.seek(newPosition > _duration ? _duration : newPosition);
  }

  void _seekBackward() {
    if (_duration == Duration.zero) return;
    final newPosition = _position - const Duration(seconds: 10);
    _audioPlayer.seek(
      newPosition < Duration.zero ? Duration.zero : newPosition,
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    // NEW: Get the ThemeManager from the provider
    final themeManager = Provider.of<ThemeManager>(context);

    // NEW: Define gradients for light and dark mode
    final lightGradient = [const Color(0xFF6D5DF6), const Color(0xFF38B6FF)];
    final darkGradient = [const Color(0xFF232A4E), const Color(0xFF171925)];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('MAD Music Player'),
        centerTitle: true,
        actions: [
          // NEW: Theme toggle button
          IconButton(
            icon: Icon(
              themeManager.themeMode == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            onPressed: () {
              themeManager.toggleTheme();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickFile,
        label: const Text('Import Songs'),
        icon: const Icon(Icons.library_music_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: _currentSongIndex != null && _songTitles.isNotEmpty
          ? MiniPlayer(
              songTitle: _songTitles[_currentSongIndex!],
              isPlaying: _isPlaying,
              position: _position,
              duration: _duration,
              onPlayPause: () {
                if (_isPlaying) {
                  _pause();
                } else {
                  _resume();
                }
              },
              onPrevious: _playPrevious,
              onNext: _playNext,
              onSeekBackward: _seekBackward,
              onSeekForward: _seekForward,
              onSeek: (value) {
                final newPosition = Duration(seconds: value.toInt());
                _audioPlayer.seek(newPosition);
              },
            )
          : null,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          // NEW: Dynamically change gradient based on theme
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: themeManager.themeMode == ThemeMode.dark
                ? darkGradient
                : lightGradient,
          ),
        ),
        child: SafeArea(
          child: SongListWidget(
            songPaths: _songPaths,
            songTitles: _songTitles,
            currentSongIndex: _currentSongIndex,
            onSongTap: (index) {
              _play(index);
            },
            onRemove: (index) async {
              bool isCurrent = index == _currentSongIndex;
              setState(() {
                _songPaths.removeAt(index);
                _songTitles.removeAt(index);
                if (_songPaths.isEmpty) {
                  _currentSongIndex = null;
                  _audioPlayer.stop();
                } else if (isCurrent) {
                  _currentSongIndex = index % _songPaths.length;
                  _play(_currentSongIndex!);
                } else if (_currentSongIndex != null &&
                    index < _currentSongIndex!) {
                  _currentSongIndex = _currentSongIndex! - 1;
                }
              });
              _savePlaylist();
            },
            onRename: (index, newName) {
              setState(() {
                _songTitles[index] = newName;
              });
              _savePlaylist();
            },
          ),
        ),
      ),
    );
  }
}
