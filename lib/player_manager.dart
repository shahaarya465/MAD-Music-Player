import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path/path.dart' as p;

class PlayerManager with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  List<String> _currentPlaylist = [];
  int? _currentIndex;

  bool get isPlaying => _playerState == PlayerState.playing;
  Duration get duration => _duration;
  Duration get position => _position;
  String? get currentSongTitle {
    if (_currentIndex != null && _currentPlaylist.isNotEmpty) {
      return p.basenameWithoutExtension(_currentPlaylist[_currentIndex!]);
    }
    return null;
  }

  PlayerManager() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _playerState = state;
      notifyListeners();
    });
    _audioPlayer.onDurationChanged.listen((newDuration) {
      _duration = newDuration;
      notifyListeners();
    });
    _audioPlayer.onPositionChanged.listen((newPosition) {
      _position = newPosition;
      notifyListeners();
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      playNext();
    });
  }

  Future<void> play(List<String> playlist, int startIndex) async {
    _currentPlaylist = playlist;
    _currentIndex = startIndex;
    if (_currentIndex != null) {
      await _audioPlayer.play(
        DeviceFileSource(_currentPlaylist[_currentIndex!]),
      );
    }
  }

  Future<void> pause() async => await _audioPlayer.pause();
  Future<void> resume() async => await _audioPlayer.resume();
  Future<void> seek(Duration newPosition) async =>
      await _audioPlayer.seek(newPosition);

  Future<void> playNext() async {
    if (_currentIndex != null && _currentPlaylist.isNotEmpty) {
      _currentIndex = (_currentIndex! + 1) % _currentPlaylist.length;
      await play(_currentPlaylist, _currentIndex!);
    }
  }

  Future<void> playPrevious() async {
    if (_currentIndex != null && _currentPlaylist.isNotEmpty) {
      _currentIndex =
          (_currentIndex! - 1 + _currentPlaylist.length) %
          _currentPlaylist.length;
      await play(_currentPlaylist, _currentIndex!);
    }
  }

  void seekForward10() {
    if (_duration == Duration.zero) return;
    final newPosition = _position + const Duration(seconds: 10);
    seek(newPosition > _duration ? _duration : newPosition);
  }

  void seekBackward10() {
    if (_duration == Duration.zero) return;
    final newPosition = _position - const Duration(seconds: 10);
    seek(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
