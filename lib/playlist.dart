import 'dart:io';
import 'dart:convert';

class Playlist {
  final String name;
  List<String> songIDs;
  final File file;

  Playlist({required this.name, required this.songIDs, required this.file});

  static Future<Playlist> fromFile(File file) async {
    final content = await file.readAsString();
    final json = jsonDecode(content);
    return Playlist(
      name: json['name'],
      songIDs: List<String>.from(json['songIDs'] ?? []),
      file: file,
    );
  }
}
