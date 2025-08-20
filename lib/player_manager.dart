import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'playlist_detail_screen.dart'; // For the Song class

class PlayerManager with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  List<Song> _currentPlaylist = [];
  int? _currentIndex;

  // NEW: For tracking recently played songs
  List<String> _recentlyPlayedSongIDs = [];
  List<String> get recentlyPlayedSongIDs => _recentlyPlayedSongIDs;

  bool get isPlaying => _playerState == PlayerState.playing;
  Duration get duration => _duration;
  Duration get position => _position;
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

  // UPDATED: Now accepts a list of Song objects
  Future<void> play(List<Song> playlist, int startIndex) async {
    _currentPlaylist = playlist;
    _currentIndex = startIndex;
    if (_currentIndex != null) {
      final song = _currentPlaylist[_currentIndex!];
      await _audioPlayer.play(DeviceFileSource(song.path));
      _addSongToRecents(song.id); // Add to history
    }
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

  // NEW: Logic to manage the recently played list
  Future<void> _addSongToRecents(String songId) async {
    _recentlyPlayedSongIDs.remove(songId); // Remove if it already exists
    _recentlyPlayedSongIDs.insert(0, songId); // Add to the top
    if (_recentlyPlayedSongIDs.length > 20) {
      // Keep the list to a max of 20 songs
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
    final documentsDir = await getApplicationDocumentsDirectory();
    final recentsFile = File(
      '${documentsDir.path}/MAD Music Player/recents.json',
    );
    if (await recentsFile.exists()) {
      final content = await recentsFile.readAsString();
      _recentlyPlayedSongIDs = List<String>.from(jsonDecode(content));
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
