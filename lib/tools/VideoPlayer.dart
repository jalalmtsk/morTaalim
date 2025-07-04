import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:path_provider/path_provider.dart';

class SectionVideoPlayer extends StatefulWidget {
  final String videoPath;

  const SectionVideoPlayer({super.key, required this.videoPath});

  @override
  State<SectionVideoPlayer> createState() => _SectionVideoPlayerState();
}

class _SectionVideoPlayerState extends State<SectionVideoPlayer> {
  VlcPlayerController? _vlcController;
  bool _isPlaying = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    try {
      String path = widget.videoPath;

      if (path.startsWith('assets/')) {
        path = await _copyAssetToFile(path);
        _vlcController = VlcPlayerController.file(
          File(path),
          autoPlay: true, // ✅ autoplay when built
          hwAcc: HwAcc.full,
        );
      } else if (path.startsWith('http')) {
        _vlcController = VlcPlayerController.network(
          path,
          autoPlay: true,
          hwAcc: HwAcc.full,
        );
      } else {
        _vlcController = VlcPlayerController.file(
          File(path),
          autoPlay: true,
          hwAcc: HwAcc.full,
        );
      }

      _vlcController!.addListener(() {
        if (mounted) {
          setState(() {
            _isPlaying = _vlcController!.value.isPlaying ?? false;
          });
        }
      });

      setState(() {}); // refresh the UI
    } catch (e) {
      debugPrint('❌ Error initializing VLC: $e');
      setState(() {
        _hasError = true;
      });
    }
  }

  Future<String> _copyAssetToFile(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/${assetPath.split('/').last}');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file.path;
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _vlcController?.pause();
    } else {
      _vlcController?.play();
    }
  }

  @override
  void dispose() {
    print('🎥 Disposing video: ${widget.videoPath}');
    _vlcController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          "فشل في تحميل الفيديو",
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    if (_vlcController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: VlcPlayer(
                controller: _vlcController!,
                aspectRatio: 16 / 9,
                placeholder: const Center(child: CircularProgressIndicator()),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: IconButton(
                iconSize: 36,
                color: Colors.orangeAccent,
                icon: Icon(
                    _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
                onPressed: _togglePlayPause,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
