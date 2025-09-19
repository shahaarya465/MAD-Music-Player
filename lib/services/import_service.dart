import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/song.dart'; // Make sure to import your Song model

class ImportService {
  final String _youtubeApiKey = dotenv.env['YOUTUBE_API_KEY']!;
  // final String _spotifyClientId = dotenv.env['SPOTIFY_CLIENT_ID']!;
  // final String _spotifyClientSecret = dotenv.env['SPOTIFY_CLIENT_SECRET']!;

  // ** FIX: This method's return type is now correctly Future<Map<String, List<Song>>> **
  Future<Map<String, List<Song>>> importPlaylist(String url) async {
    if (url.contains('youtube.com')) {
      return await _importFromYouTube(url);
    } else if (url.contains('spotify.com')) {
      // Note: Spotify import is more complex and not fully implemented here
      throw UnimplementedError('Spotify import requires searching YouTube for each track.');
    }
    throw Exception('Unsupported URL');
  }

  /// ** FIX: This method now constructs and returns a `List<Song>` instead of `List<String>` **
  Future<Map<String, List<Song>>> _importFromYouTube(String url) async {
    final playlistId = Uri.parse(url).queryParameters['list'];
    if (playlistId == null) throw Exception('Invalid YouTube Playlist URL');

    final List<Song> songObjects = [];
    String? nextPageToken;

    do {
      String pageTokenQuery = nextPageToken == null ? '' : '&pageToken=$nextPageToken';
      final response = await http.get(
        Uri.parse(
            'https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&maxResults=50&playlistId=$playlistId&key=$_youtubeApiKey$pageTokenQuery'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Loop through the API results and create Song objects
        for (var item in (data['items'] as List)) {
          final snippet = item['snippet'];
          final videoId = snippet['resourceId']['videoId'];
          if (videoId != null) {
            songObjects.add(
              Song(
                id: videoId, // Use the videoId as a unique identifier
                title: snippet['title'] ?? 'Unknown Title',
                videoId: videoId, // Store the videoId for streaming
                type: SongType.online, // Mark the song as an online track
              ),
            );
          }
        }
        
        nextPageToken = data['nextPageToken'];
      } else {
        throw Exception('Failed to load YouTube playlist. Status code: ${response.statusCode}');
      }
    } while (nextPageToken != null);
    return {'YouTube Playlist': songObjects};
  }

  // Spotify import is a much larger task and is left as a placeholder.
  // It would involve taking each Spotify track, searching for it on YouTube,
  // and then creating a Song object from the best search result.

  // Future<Map<String, List<Song>>> _importFromSpotify(String url) async {
  //   throw UnimplementedError('Spotify import is not fully implemented yet.');
  // }
}