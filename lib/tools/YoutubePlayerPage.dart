import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:provider/provider.dart';
import '../Manager/Services/YoutubeProgressManager.dart';
import 'ConnectivityManager/ConexionWidget.dart';
import 'ConnectivityManager/Connectivity_Manager.dart';

class YouTubeSectionPlayer extends StatefulWidget {
  final String videoUrl;
  final VoidCallback? onVideoFinished;

  const YouTubeSectionPlayer({
    required this.videoUrl,
    this.onVideoFinished,
    Key? key,
  }) : super(key: key);

  @override
  _YouTubeSectionPlayerState createState() => _YouTubeSectionPlayerState();
}

class _YouTubeSectionPlayerState extends State<YouTubeSectionPlayer>
    with SingleTickerProviderStateMixin {
  YoutubePlayerController? _ytController;
  late AnimationController _popController;

  bool _isLeaving = false;
  bool _hasFinished = false;
  bool _showLottie = false;

  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  String? _videoId;

  @override
  void initState() {
    super.initState();

    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      lowerBound: 0.7,
      upperBound: 1.2,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _initPlayer());
  }

  void _initPlayer() {
    _videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
    if (_videoId == null) return;

    final xpManager = Provider.of<ExperienceManager>(context, listen: false);
    final progressManager = xpManager.youtubeProgressManager;

    setState(() {
      _hasFinished = progressManager.isVideoCompleted(_videoId!);
      _ytController = YoutubePlayerController(
        initialVideoId: _videoId!,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: false,
        ),
      )..addListener(_ytListener);
    });

    // Listen for changes in progressManager if needed
    xpManager.addListener(_onProgressChanged);
  }

  void _ytListener() {
    if (_ytController == null) return;
    final value = _ytController!.value;

    if (!value.isReady) return;

    setState(() {
      _currentPosition = value.position;
      _totalDuration = value.metaData.duration;
    });

    if (value.playerState == PlayerState.ended) {
      _onVideoFinished();
    }

    // Optional: Prevent fullscreen mode
    if (value.isFullScreen) {
      _ytController!.toggleFullScreenMode();
    }
  }

  void _onProgressChanged() {
    if (_videoId == null) return;
    final xpManager = Provider.of<ExperienceManager>(context, listen: false);
    final isCompleted = xpManager.youtubeProgressManager.isVideoCompleted(_videoId!);
    if (isCompleted != _hasFinished) {
      setState(() => _hasFinished = isCompleted);
    }
  }

  @override
  void dispose() {
    _ytController?.removeListener(_ytListener);
    final xpManager = Provider.of<ExperienceManager>(context, listen: false);
    xpManager.removeListener(_onProgressChanged);

    _ytController?.dispose();
    _popController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    _ytController?.pause();
    setState(() => _isLeaving = true);
    await Future.delayed(const Duration(milliseconds: 100));
    return true;
  }

  void _onVideoFinished() {
    if (_hasFinished || _videoId == null) return;

    setState(() => _hasFinished = true);
    final xpManager = Provider.of<ExperienceManager>(context, listen: false);

    xpManager.addXP(context: context, 2);
    xpManager.markVideoCompleted(videoId: _videoId!);
    widget.onVideoFinished?.call();

    _popController.forward(from: 0.7);
    setState(() => _showLottie = true);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showLottie = false);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🎉 You finished the video!')),
    );
  }

  void _showNoFullscreenMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fullscreen mode is not supported.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatTime(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  Widget _buildNoConnection() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: 220,
      color: Colors.grey.withAlpha(50),
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Lottie.asset("assets/animations/FirstTouchAnimations/NoCon.json", fit: BoxFit.contain),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '📡 No internet connection.\nYou need WiFi to watch the video.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = Provider.of<ConnectivityService>(context);

    if (!connectivity.isConnected) {
      return _buildNoConnection();
    }

    if (_ytController == null) {
      return SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: 220,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final progress = _totalDuration.inMilliseconds > 0
        ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
        : 0.0;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
          ),
          Container(
            color: Colors.pink.shade50,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                ScaleTransition(
                  scale: _popController,
                  child: Icon(
                    _hasFinished ? Icons.check_circle : Icons.star_border,
                    color: _hasFinished ? Colors.green : Colors.amber,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _hasFinished
                        ? "Rewards earned: +2 XP, +1 Tolim"
                        : "Complete to earn: +2 XP, +1 Tolim",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          if (_showLottie)
            SizedBox(
              height: 120,
              child: Lottie.asset("assets/animations/QuizzGame_Animation/Champion.json", repeat: false),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            alignment: Alignment.centerRight,
            child: Text(
              "${_formatTime(_currentPosition)} / ${_formatTime(_totalDuration)}",
              style: const TextStyle(fontSize: 14, color: Colors.deepPurple),
            ),
          ),
          YoutubePlayerBuilder(
            player: YoutubePlayer(
              controller: _ytController!,
              showVideoProgressIndicator: true,
            ),
            builder: (context, player) {
              return Stack(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: 220,
                    child: _isLeaving ? Container(color: Colors.black) : player,
                  ),
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: ConnectivityIndicator(),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: _showNoFullscreenMessage,
                      behavior: HitTestBehavior.opaque,
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
