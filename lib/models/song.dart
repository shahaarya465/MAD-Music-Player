enum SongType { local, online }

class Song {
  final String id;
  final String title;
  final String? path;
  final String? videoId;
  final SongType type;

  Song({
    required this.id,
    required this.title,
    this.path,
    this.videoId,
    required this.type,
  }) : assert(
         (type == SongType.local && path != null) ||
             (type == SongType.online && videoId != null),
         'Local songs must have a path, and online songs must have a videoId.',
       );
}
