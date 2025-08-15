import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'song_list_widget.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'dart:io';

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
      if (mounted) { // Check if the widget is still in the tree
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
      List<String> newPaths = selectedPaths.where((p) => !_songPaths.contains(p)).toList();
      List<String> newTitles = [];
      for (final path in newPaths) {
        String title = p.basename(path);
        try {
          final metadata = await MetadataRetriever.fromFile(File(path));
          if (metadata.trackName != null && metadata.trackName!.trim().isNotEmpty) {
            title = metadata.trackName!;
          }
        } catch (e) {
          // ignore and use filename
        }
        // If title is missing, empty, or looks like a UUID, use filename without extension
        final uuidRegex = RegExp(r'^[0-9a-fA-F\-]{32,}$');
        final isUuid = uuidRegex.hasMatch(title.replaceAll('.', '').replaceAll('-', ''));
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
          }
        });
      }
      if (_currentSongIndex != null) {
        await _audioPlayer.stop();
        if (mounted) {
          setState(() {
            _position = Duration.zero;
          });
        }
        _play(_currentSongIndex!);
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
        title: const Text('Flutter Music Player', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
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
        child: Center(
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            color: Colors.white.withOpacity(0.95),
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SongListWidget(
                    songPaths: _songPaths,
                    songTitles: _songTitles,
                    currentSongIndex: _currentSongIndex,
                    onSongTap: (index) async {
                      await _audioPlayer.stop();
                      setState(() {
                        _position = Duration.zero;
                      });
                      _play(index);
                    },
                    onRemove: (index) async {
                      bool isCurrent = index == _currentSongIndex;
                      setState(() {
                        _songPaths.removeAt(index);
                        _songTitles.removeAt(index);
                        if (_songPaths.isEmpty) {
                          _currentSongIndex = null;
                        } else if (isCurrent) {
                          _currentSongIndex = 0;
                        } else if (_currentSongIndex != null && index < _currentSongIndex!) {
                          _currentSongIndex = _currentSongIndex! - 1;
                        }
                      });
                      if (isCurrent) {
                        await _audioPlayer.stop();
                        setState(() {
                          _position = Duration.zero;
                        });
                        if (_songPaths.isNotEmpty) {
                          _play(_currentSongIndex!);
                        }
                      }
                    },
                    onRename: (index, newName) {
                      setState(() {
                        _songTitles[index] = newName;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_currentSongIndex != null && _songTitles.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Now Playing:\n${_songTitles[_currentSongIndex!]}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 24),
                  Slider(
                    min: 0,
                    max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 0.0,
                    value: _position.inSeconds.toDouble().clamp(0.0, _duration.inSeconds.toDouble()),
                    activeColor: Color(0xFF6D5DF6),
                    inactiveColor: Color(0xFFB2A9F7),
                    onChanged: (value) async {
                      final newPosition = Duration(seconds: value.toInt());
                      if (mounted) {
                        setState(() {
                          _position = newPosition;
                        });
                      }
                      await _audioPlayer.seek(newPosition);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(_position), style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text(_formatDuration(_duration - _position), style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6D5DF6), Color(0xFF38B6FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                          color: Colors.white,
                          iconSize: 64.0,
                          onPressed: () {
                            if (_isPlaying) {
                              _pause();
                            } else {
                              if (_currentSongIndex == null) {
                                _pickFile();
                              } else {
                                _resume();
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6D5DF6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      elevation: 4,
                    ),
                    onPressed: _pickFile,
                    icon: const Icon(Icons.library_music_rounded),
                    label: const Text('Import Songs'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}