import 'dart:io';
import 'dart:convert';

class Playlist {
  final String name;
  final List<String> songPaths;
  final File file; // A reference to the actual .json file

  Playlist({required this.name, required this.songPaths, required this.file});

  // A factory constructor to create a Playlist object from a JSON file
  static Future<Playlist> fromFile(File file) async {
    final content = await file.readAsString();
    final json = jsonDecode(content);
    return Playlist(
      name: json['name'],
      songPaths: List<String>.from(json['songPaths']),
      file: file,
    );
  }
}
