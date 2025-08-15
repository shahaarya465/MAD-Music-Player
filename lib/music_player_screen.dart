import 'dart:io';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_media_metadata/flutter_media_metadata.dart';

import 'song_list_widget.dart';
import 'mini_player.dart';

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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'MAD Music Player',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickFile,
        label: const Text('Import Songs'),
        icon: const Icon(Icons.library_music_rounded),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF6D5DF6),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: _currentSongIndex != null
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
              onPrevious: _playPrevious, // <-- ARGUMENT ADDED
              onNext: _playNext, // <-- ARGUMENT ADDED
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6D5DF6), Color(0xFF38B6FF)],
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
            },
            onRename: (index, newName) {
              setState(() {
                _songTitles[index] = newName;
              });
            },
          ),
        ),
      ),
    );
  }
}
