import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

import 'HomeCourse.dart';
class SectionVlcPlayer extends StatefulWidget {
  final String videoPath;

  const SectionVlcPlayer({required this.videoPath});

  @override
  _SectionVlcPlayerState createState() => _SectionVlcPlayerState();
}

class _SectionVlcPlayerState extends State<SectionVlcPlayer> {
  late VlcPlayerController _controller;
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();

    final assetPath = 'assets/videos/${widget.videoPath}';

    _controller = VlcPlayerController.asset(
      assetPath,
      hwAcc: HwAcc.full,
      autoPlay: false,
      options: VlcPlayerOptions(),
    );

    setState(() {
      isInitialized = true;
    });
  }

  @override
  void dispose() {
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                if (_controller.value.isPlaying) {
                  _controller.pause();
                } else {
                  _controller.play();
                }
              });
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: VlcPlayer(
                  controller: _controller,
                  placeholder: const Center(child: CircularProgressIndicator()),
                  aspectRatio: 1,
                ),
              ),
            ),
          ),
          IconButton(
            iconSize: 36,
            icon: Icon(
              _controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
              color: Colors.orangeAccent,
            ),
            onPressed: () {
              setState(() {
                if (_controller.value.isPlaying) {
                  _controller.pause();
                } else {
                  _controller.play();
                }
              });
            },
          ),
        ],
      ),
    );
  }
}
