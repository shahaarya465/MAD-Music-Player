import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../screens/playlist_detail_screen.dart'; // For the Song class

enum RepeatMode { none, one, all }

class PlayerManager with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  List<Song> _currentPlaylist = [];
  List<Song> _originalPlaylist = [];
  int? _currentIndex;
  bool _isShuffle = false;
  RepeatMode _repeatMode = RepeatMode.none;

  // NEW: For tracking recently played songs
  List<String> _recentlyPlayedSongIDs = [];
  List<String> get recentlyPlayedSongIDs => _recentlyPlayedSongIDs;

  bool get isPlaying => _playerState == PlayerState.playing;
  Duration get duration => _duration;
  Duration get position => _position;
  List<Song> get currentPlaylist => _currentPlaylist;
  int? get currentIndex => _currentIndex;
  bool get isShuffle => _isShuffle;
  RepeatMode get repeatMode => _repeatMode;

  String? get currentSongTitle {
    if (_currentIndex != null && _currentIndex! < _currentPlaylist.length) {
      return _currentPlaylist[_currentIndex!].title;
    }
    return null;
  }

  PlayerManager() {
    _loadRecents(); // Load history on startup
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

  Future<void> play(List<Song> playlist, int startIndex) async {
    _originalPlaylist = List.from(playlist); // Store the original order
    _currentPlaylist = List.from(playlist);
    _currentIndex = startIndex;

    if (_isShuffle) {
      _currentPlaylist.shuffle();
      _currentIndex = _currentPlaylist.indexWhere(
        (s) => s.id == playlist[startIndex].id,
      );
    }

    if (_currentIndex != null) {
      final song = _currentPlaylist[_currentIndex!];
      await _audioPlayer.play(DeviceFileSource(song.path));
      _addSongToRecents(song.id);
    }
  }

  // Add this method to play a song by its index
  Future<void> playAtIndex(int index) async {
    if (index >= 0 && index < _currentPlaylist.length) {
      _currentIndex = index;
      final song = _currentPlaylist[index];
      await _audioPlayer.play(DeviceFileSource(song.path));
      _addSongToRecents(song.id);
    }
  }

  void addToQueue(Song song) {
    if (!_currentPlaylist.any((s) => s.id == song.id)) {
      _currentPlaylist.add(song);
      notifyListeners();
    }
  }

  void reorderPlaylist(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final song = _currentPlaylist.removeAt(oldIndex);
    _currentPlaylist.insert(newIndex, song);

    if (_currentIndex == oldIndex) {
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex! && newIndex >= _currentIndex!) {
      _currentIndex = _currentIndex! - 1;
    } else if (oldIndex > _currentIndex! && newIndex <= _currentIndex!) {
      _currentIndex = _currentIndex! + 1;
    }

    notifyListeners();
  }

  Future<void> pause() async => await _audioPlayer.pause();
  Future<void> resume() async => await _audioPlayer.resume();
  Future<void> seek(Duration newPosition) async =>
      await _audioPlayer.seek(newPosition);

  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentPlaylist = [];
    _currentIndex = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    notifyListeners();
  }

  Future<void> playNext() async {
    if (_currentIndex != null && _currentPlaylist.isNotEmpty) {
      if (_repeatMode == RepeatMode.one) {
        // repeat current song
      } else if (_isShuffle) {
        _currentIndex = Random().nextInt(_currentPlaylist.length);
      } else {
        _currentIndex = (_currentIndex! + 1);
        if (_currentIndex! >= _currentPlaylist.length) {
          if (_repeatMode == RepeatMode.all) {
            _currentIndex = 0;
          } else {
            stop();
            return;
          }
        }
      }
      await play(_currentPlaylist, _currentIndex!);
    }
  }

  Future<void> playPrevious() async {
    if (_currentIndex != null && _currentPlaylist.isNotEmpty) {
      if (_isShuffle) {
        _currentIndex = Random().nextInt(_currentPlaylist.length);
      } else {
        _currentIndex =
            (_currentIndex! - 1 + _currentPlaylist.length) %
            _currentPlaylist.length;
      }
      await play(_currentPlaylist, _currentIndex!);
    }
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;

    if (_currentPlaylist.isNotEmpty && _currentIndex != null) {
      final currentSongId = _currentPlaylist[_currentIndex!].id;

      if (_isShuffle) {
        _currentPlaylist.shuffle();
      } else {
        _currentPlaylist = List.from(_originalPlaylist);
      }

      _currentIndex = _currentPlaylist.indexWhere((s) => s.id == currentSongId);
    }

    notifyListeners();
  }

  void toggleRepeat() {
    if (_repeatMode == RepeatMode.none) {
      _repeatMode = RepeatMode.all;
    } else if (_repeatMode == RepeatMode.all) {
      _repeatMode = RepeatMode.one;
    } else {
      _repeatMode = RepeatMode.none;
    }
    notifyListeners();
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

  Future<void> _addSongToRecents(String songId) async {
    _recentlyPlayedSongIDs.remove(songId);
    _recentlyPlayedSongIDs.insert(0, songId);
    if (_recentlyPlayedSongIDs.length > 20) {
      _recentlyPlayedSongIDs = _recentlyPlayedSongIDs.sublist(0, 20);
    }
    await _saveRecents();
    notifyListeners();
  }

  Future<void> _saveRecents() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final recentsFile = File(
      '${documentsDir.path}/MAD Music Player/recents.json',
    );
    await recentsFile.writeAsString(jsonEncode(_recentlyPlayedSongIDs));
  }

  Future<void> _loadRecents() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final recentsFile = File(
        '${documentsDir.path}/MAD Music Player/recents.json',
      );
      if (await recentsFile.exists()) {
        final content = await recentsFile.readAsString();
        _recentlyPlayedSongIDs = List<String>.from(jsonDecode(content));
        notifyListeners();
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
