import 'package:flutter/material.dart';
import 'package:mortaalim/tools/audio_tool/audio_tool.dart';

class MusicSelectionPage extends StatelessWidget {
  final MusicPlayer musicPlayer;
  final List<String> musicPaths;
  final String currentSong;

  const MusicSelectionPage({
    Key? key,
    required this.musicPlayer,
    required this.musicPaths,
    required this.currentSong,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Music'),
        backgroundColor: Colors.deepOrange,
      ),
      body: ListView.builder(
        itemCount: musicPaths.length,
        itemBuilder: (context, index) {
          final songPath = musicPaths[index];
          final isSelected = songPath == currentSong;
          final songName = songPath.split('/').last; // get file name

          return ListTile(
            leading: Icon(Icons.music_note, color: isSelected ? Colors.deepOrange : null),
            title: Text(songName),
            trailing: isSelected ? const Icon(Icons.check, color: Colors.deepOrange) : null,
            onTap: () {
              musicPlayer.stop();
              musicPlayer.play(songPath, loop: true);
              Navigator.pop(context, songPath);
            },
          );
        },
      ),
    );
  }
}
