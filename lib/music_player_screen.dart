import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';

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
  String? _filePath;

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
    );

    if (result != null) {
      if (mounted) {
        setState(() {
          _filePath = result.files.single.path;
        });
      }
      await _audioPlayer.stop();
      if (mounted) {
        setState(() {
          _position = Duration.zero; // Reset position for the new file
        });
      }
      _play();
    }
  }

  Future<void> _play() async {
    if (_filePath != null) {
      await _audioPlayer.play(DeviceFileSource(_filePath!));
    }
  }

  Future<void> _resume() async {
    if (_filePath != null) {
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
      appBar: AppBar(
        title: const Text('Flutter Music Player'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_filePath != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Now Playing: ${_filePath!.split('/').last}',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 20),
            Slider(
              min: 0,
              max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 0.0,
              value: _position.inSeconds.toDouble().clamp(0.0, _duration.inSeconds.toDouble()),
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(_position)),
                  Text(_formatDuration(_duration - _position)),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  iconSize: 64.0,
                  onPressed: () {
                    if (_isPlaying) {
                      _pause();
                    } else {
                      if (_filePath == null) {
                        _pickFile();
                      } else {
                        _resume();
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickFile,
              child: const Text('Pick an Audio File'),
            ),
          ],
        ),
      ),
    );
  }
}