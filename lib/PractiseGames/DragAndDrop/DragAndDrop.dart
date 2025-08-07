import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mortaalim/tools/audio_tool.dart';
import 'package:provider/provider.dart';
import '../../XpSystem.dart';
import '../../tools/Ads_Manager.dart';
import '../practiseWords.dart';

class DragDropGame extends StatefulWidget {
  final List<PractiseWords> items;
  final int difficulty;

  const DragDropGame({super.key, required this.items, this.difficulty = 4});

  @override
  State<DragDropGame> createState() => _DragDropGameState();
}

class _DragDropGameState extends State<DragDropGame>
    with TickerProviderStateMixin {
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  final Map<String, String> matched = {};
  late List<PractiseWords> currentItems;
  final MusicPlayer _audioPlayer = MusicPlayer();
  final MusicPlayer _backgroundMusic = MusicPlayer();

  Stopwatch stopwatch = Stopwatch();
  Timer? _timer;
  Duration bestTime = Duration.zero;

  @override
  void initState() {
    super.initState();
   _backgroundMusic.play("assets/audios/sound_track/SakuraGirl_bkG.mp3",
        loop: true);
   _backgroundMusic.setVolume(0.2);
    _startGame();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd?.dispose();
    _isBannerAdLoaded = false;
    _bannerAd = AdHelper.getBannerAd(() {
      setState(() {
        _isBannerAdLoaded = true;
      });
    });
  }

  void _startGame() async {
    matched.clear();

    final shuffled = [...widget.items]..shuffle();
    currentItems = shuffled.take(widget.difficulty).toList();

    await _backgroundMusic.play("assets/audios/sound_track/SakuraGirl_bkG.mp3",
        loop: true);
    await _backgroundMusic.setVolume(0.2);

    stopwatch.reset();
    stopwatch.start();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() {});
    });

    setState(() {});
  }

  Future<void> _playAudio(bool correct) async {
    await _audioPlayer.stop();
    await _audioPlayer.setVolume(0.8);
    await _audioPlayer.play(
      correct
          ? 'assets/audios/QuizGame_Sounds/correct.mp3'
          : 'assets/audios/QuizGame_Sounds/incorrect.mp3',
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _backgroundMusic.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _checkCompletion() {
    if (matched.length == currentItems.length) {
      stopwatch.stop();
      _timer?.cancel();

      final current = stopwatch.elapsed;
      if (bestTime == Duration.zero || current < bestTime) {
        bestTime = current;
      }

      Future.delayed(const Duration(milliseconds: 400), _showCompletionDialog);
    }
  }

  void _showCompletionDialog() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('🎉 Bravo!'),
        content: Text(
          'You matched all the words!\nTime: ${_formatDuration(stopwatch.elapsed)}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Future.delayed(const Duration(milliseconds: 200), _startGame);
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    return "${duration.inSeconds}.${(duration.inMilliseconds % 1000 ~/ 100)}s";
  }

  @override
  Widget build(BuildContext context) {
    final total = currentItems.length;
    final done = matched.length;

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F7),
      appBar: AppBar(
        title: const Text('🧩 Match the Words!'),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("✅ $done / $total"),
                Text("⏱ ${_formatDuration(stopwatch.elapsed)}"),
                Text("🏆 ${_formatDuration(bestTime)}"),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: done / total,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              minHeight: 8,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 4 / 5,
                children: currentItems.map((item) {
                  final isMatched = matched[item.imagePath] == item.word;
                  return DragTarget<String>(
                    onWillAccept: (_) => !isMatched,
                    onAccept: (word) async {
                      if (word == item.word) {
                        matched[item.imagePath] = word;
                        await _playAudio(true);
                      } else {
                        await _playAudio(false);
                      }
                      setState(() {});
                      _checkCompletion();
                    },
                    builder: (context, candidateData, _) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: isMatched
                              ? Colors.green.shade100
                              : candidateData.isNotEmpty
                              ? Colors.purple.shade50
                              : Colors.white,
                          border: Border.all(
                            color: isMatched
                                ? Colors.green
                                : Colors.grey.shade400,
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            )
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 500),
                                opacity: isMatched ? 1.0 : 0.8,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    item.imagePath,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                isMatched ? item.word : '_______',
                                key: ValueKey(isMatched ? item.word : '_______'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isMatched ? Colors.green : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: currentItems.map((item) {
                final alreadyMatched = matched.containsValue(item.word);
                return alreadyMatched
                    ? const SizedBox.shrink()
                    : Draggable<String>(
                  data: item.word,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Chip(
                      label: Text(item.word),
                      backgroundColor: Colors.deepPurple,
                      labelStyle: const TextStyle(color: Colors.white),
                      elevation: 6,
                    ),
                  ),
                  childWhenDragging: Chip(
                    label: Text(item.word),
                    backgroundColor: Colors.grey.shade300,
                  ),
                  child: Chip(
                    label: Text(item.word),
                    backgroundColor: Colors.deepPurple.shade100,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar:
      context.watch<ExperienceManager>().adsEnabled && _bannerAd != null && _isBannerAdLoaded
          ? SafeArea(
        child: Container(
          height: _bannerAd!.size.height.toDouble(),
          width: _bannerAd!.size.width.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
      )
          : null,
    );
  }
}
