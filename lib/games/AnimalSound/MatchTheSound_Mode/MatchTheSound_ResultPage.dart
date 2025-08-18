import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/games/AnimalSound/MatchTheSound_Mode/AnimalSound_MatchAndDrop.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:provider/provider.dart';
import 'package:mortaalim/tools/Ads_Manager.dart';

class MatchResultPage extends StatefulWidget {
  const MatchResultPage({
    required this.score,
    required this.maxScore,
    required this.failed,
    required this.onPlayAgain,
    super.key,
  });

  final int score, maxScore;
  final bool failed;
  final VoidCallback onPlayAgain;

  @override
  State<MatchResultPage> createState() => _MatchResultPageState();
}

class _MatchResultPageState extends State<MatchResultPage> {
  bool _isAdLoading = false;

  @override
  void initState() {
    super.initState();
    _playResultSound();
  }

  Future<void> _playResultSound() async {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    try {
      final asset = widget.failed
          ? 'assets/audios/UI_Audio/SFX_Audio/FailMeme_SFX.mp3'
          : 'assets/audios/QuizGame_Sounds/crowd-cheering-6229.mp3';

      final asset2 = widget.failed
          ? 'assets/audios/UI_Audio/SFX_Audio/victory1_SFX.mp3'
          : 'assets/audios/UI_Audio/SFX_Audio/VictoryEpic_SFX.mp3';
      audioManager.playSfx(asset);
      audioManager.playSfx(asset2);
    } catch (e) {
      debugPrint("Error playing result sound: $e");
    }
  }

  Future<void> _showAdAndRestart() async {
    if (_isAdLoading) return;
    setState(() => _isAdLoading = true);

    await AdHelper.showInterstitialAd(onDismissed: () {
      setState(() => _isAdLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AS_MatchDrop()),
      );
    });
  }

  Future<bool> _onWillPop() async {
    if (_isAdLoading) return false;

    setState(() => _isAdLoading = true);

    await AdHelper.showInterstitialAd(onDismissed: () {
      setState(() => _isAdLoading = false);
      Navigator.of(context).pop();
    });

    return false; // prevent default back action
  }

  @override
  Widget build(BuildContext context) {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    final message = widget.failed
        ? 'Don’t worry! You can try again.\nTolim rewarded: 0'
        : 'Amazing! You finished with ${widget.score}/${widget.maxScore}.\nTolim rewarded: 1';

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.lightBlue.shade50,
        body: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 180,
                  child: Lottie.asset(
                    widget.failed
                        ? "assets/animations/FirstTouchAnimations/Thinking.json"
                        : "assets/animations/QuizzGame_Animation/Champion.json",
                    repeat: true,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.failed ? 'Game Over' : 'Great Job!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: widget.failed ? Colors.redAccent : Colors.green,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, height: 1.4),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  children: [
                    _resultChip(Icons.star, Colors.amber,
                        'Score: ${widget.score}/${widget.maxScore}'),
                  ],
                ),
                const SizedBox(height: 22),
                ElevatedButton.icon(
                  onPressed: _isAdLoading ? null : _showAdAndRestart,
                  icon: _isAdLoading
                      ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                      : const Icon(Icons.replay),
                  label: const Text('Play Again'),
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    backgroundColor: widget.failed ? Colors.redAccent : Colors.green,
                    textStyle:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _resultChip(IconData icon, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
