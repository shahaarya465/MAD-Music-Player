import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/player_manager.dart';

class OnlinePlaylistScreen extends StatelessWidget {
  final String playlistName;
  final List<Song> songs;

  const OnlinePlaylistScreen({
    super.key,
    required this.playlistName,
    required this.songs,
  });

  @override
  Widget build(BuildContext context) {
    final playerManager = Provider.of<PlayerManager>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(playlistName),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: songs.isEmpty
          ? const Center(child: Text('No songs found in this playlist.'))
          : ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return ListTile(
                  leading: const Icon(
                    Icons.ondemand_video,
                  ), // Icon to show it's a video/stream
                  title: Text(song.title),
                  onTap: () {
                    // Play the list of online songs
                    playerManager.play(songs, index);
                  },
                );
              },
            ),
    );
  }
}
