

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YouTubeSectionPlayer extends StatefulWidget {
  final String videoUrl;

  const YouTubeSectionPlayer({required this.videoUrl});

  @override
  _YouTubeSectionPlayerState createState() => _YouTubeSectionPlayerState();
}

class _YouTubeSectionPlayerState extends State<YouTubeSectionPlayer> {
  YoutubePlayerController? _ytController;
  bool hasInternet = false;
  bool checkedConnectivity = false;

  @override
  void initState() {
    super.initState();
    _checkInternetAndInitPlayer();
  }

  Future<void> _checkInternetAndInitPlayer() async {

      String? videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
      if (videoId != null) {
        _ytController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
            enableCaption: false,
          ),
        );
        setState(() {
          hasInternet = true;
          checkedConnectivity = true;
        });
        return;
      }


    // No internet or invalid video URL
    setState(() {
      hasInternet = false;
      checkedConnectivity = true;
    });
  }

  @override
  void dispose() {
    _ytController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!checkedConnectivity) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!hasInternet || _ytController == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Text(
          '📡 لا يوجد اتصال بالإنترنت. فيديو YouTube غير متاح حالياً.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _ytController!,
        showVideoProgressIndicator: true,
      ),
      builder: (context, player) {
        return Column(
          children: [
            player,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  onPressed: () {
                    _ytController!.toggleFullScreenMode();
                  },
                )
              ],
            )
          ],
        );
      },
    );
  }
}
