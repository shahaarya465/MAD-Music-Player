import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/song.dart';

enum RepeatMode { none, one, all }

class PlayerManager with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final YoutubeExplode _youtubeExplode = YoutubeExplode();

  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  List<Song> _currentPlaylist = [];
  List<Song> _originalPlaylist = [];
  int? _currentIndex;
  bool _isShuffle = false;
  RepeatMode _repeatMode = RepeatMode.none;

  List<String> _recentlyPlayedSongIDs = [];
  List<String> get recentlyPlayedSongIDs => _recentlyPlayedSongIDs;

  bool get isPlaying => _playerState == PlayerState.playing;
  Duration get duration => _duration;
  Duration get position => _position;
  List<Song> get currentPlaylist => _currentPlaylist;
  int? get currentIndex => _currentIndex;
  bool get isShuffle => _isShuffle;
  RepeatMode get repeatMode => _repeatMode;

  Song? get currentSong {
    if (_currentIndex != null && _currentIndex! < _currentPlaylist.length) {
      return _currentPlaylist[_currentIndex!];
    }
    return null;
  }

  String? get currentSongTitle => currentSong?.title;

  PlayerManager() {
    _loadRecents();
    _setupAudioPlayerListeners();
  }

  void _setupAudioPlayerListeners() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _playerState = state;
      notifyListeners();
    });

    _audioPlayer.onDurationChanged.listen((d) {
      _duration = d;
      notifyListeners();
    });

    _audioPlayer.onPositionChanged.listen((p) {
      _position = p;
      notifyListeners();
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (_repeatMode != RepeatMode.one) {
        playNext();
      }
    });
  }

  Future<void> play(List<Song> playlist, int startIndex) async {
    _originalPlaylist = List.from(playlist);
    _currentPlaylist = List.from(playlist);
    _currentIndex = startIndex;

    if (_isShuffle) {
      _currentPlaylist.shuffle();
      _currentIndex = _currentPlaylist.indexWhere(
        (s) => s.id == playlist[startIndex].id,
      );
    }

    await _playCurrentSong();
  }

  Future<void> _playCurrentSong() async {
    final song = currentSong;
    if (song == null) return;

    try {
      Source? source;
      if (song.type == SongType.local) {
        source = DeviceFileSource(song.path!);
      } else {
        var manifest = await _youtubeExplode.videos.streamsClient
            .getManifest(song.videoId!);
        var streamInfo = manifest.audioOnly.withHighestBitrate();
        source = UrlSource(streamInfo.url.toString());
      }

      await _audioPlayer.play(source);
      _addSongToRecents(song.id);
    } catch (e) {
      print("Error playing song: $e");
      playNext();
    }
  }

  Future<void> playAtIndex(int index) async {
    if (index >= 0 && index < _currentPlaylist.length) {
      _currentIndex = index;
      await _playCurrentSong();
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
    if (_currentIndex == null || _currentPlaylist.isEmpty) return;

    if (_isShuffle) {
      _currentIndex = Random().nextInt(_currentPlaylist.length);
    } else {
      _currentIndex = _currentIndex! + 1;
    }

    if (_currentIndex! >= _currentPlaylist.length) {
      if (_repeatMode == RepeatMode.all) {
        _currentIndex = 0;
      } else {
        await stop();
        return;
      }
    }
    await _playCurrentSong();
  }

  Future<void> playPrevious() async {
    if (_currentIndex == null || _currentPlaylist.isEmpty) return;

    if (_isShuffle) {
      _currentIndex = Random().nextInt(_currentPlaylist.length);
    } else {
      _currentIndex = (_currentIndex! - 1 + _currentPlaylist.length) %
          _currentPlaylist.length;
    }
    await _playCurrentSong();
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;

    if (_currentPlaylist.isNotEmpty && _currentIndex != null) {
      final currentSongId = currentSong!.id;

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
      _audioPlayer.setReleaseMode(ReleaseMode.release);
    } else if (_repeatMode == RepeatMode.all) {
      _repeatMode = RepeatMode.one;
      _audioPlayer.setReleaseMode(ReleaseMode.loop);
    } else {
      _repeatMode = RepeatMode.none;
      _audioPlayer.setReleaseMode(ReleaseMode.release);
    }
    notifyListeners();
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
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final recentsFile =
          File('${documentsDir.path}/MAD Music Player/recents.json');
      await recentsFile.writeAsString(jsonEncode(_recentlyPlayedSongIDs));
    } catch (e) {
      print("Error saving recents: $e");
    }
  }

  Future<void> _loadRecents() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final recentsFile =
          File('${documentsDir.path}/MAD Music Player/recents.json');
      if (await recentsFile.exists()) {
        final content = await recentsFile.readAsString();
        _recentlyPlayedSongIDs = List<String>.from(jsonDecode(content));
        notifyListeners();
      }
    } catch (e) {
      print("Error loading recents: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _youtubeExplode.close();
    super.dispose();
  }
}
