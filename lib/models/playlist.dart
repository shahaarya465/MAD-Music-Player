import 'dart:io';
import 'dart:convert';

class Playlist {
  final String name;
  List<String> songIDs;
  final File file;
  final String? url;

  Playlist({
    required this.name,
    required this.songIDs,
    required this.file,
    this.url,
  });

  static Future<Playlist> fromFile(File file) async {
    final content = await file.readAsString();
    final json = jsonDecode(content);
    return Playlist(
      name: json['name'],
      songIDs: List<String>.from(json['songIDs'] ?? []),
      file: file,
      url: json['url'],
    );
  }
}
