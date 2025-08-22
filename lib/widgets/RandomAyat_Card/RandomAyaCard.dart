import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mortaalim/Themes/ThemeManager.dart';
import 'package:provider/provider.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import '../../Manager/Services/CardVisibiltyManager.dart';
import 'Ayat_List.dart';

class ExpandableAyatCard extends StatefulWidget {
  const ExpandableAyatCard({Key? key}) : super(key: key);

  @override
  State<ExpandableAyatCard> createState() => _ExpandableAyatCardState();
}

class _ExpandableAyatCardState extends State<ExpandableAyatCard>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Timer _timer;
  final _random = Random();

  late Map<String, String> _currentAyat;
  int _seconds = 60;
  bool _expanded = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      lowerBound: 0.85,
      upperBound: 1.0,
      value: 1.0,
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
      lowerBound: 0.98,
      upperBound: 1.02,
    );

    _currentAyat = ayatList[_random.nextInt(ayatList.length)];
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (_seconds == 0) {
        await _fadeController.reverse();
        setState(() {
          _currentAyat = ayatList[_random.nextInt(ayatList.length)];
          _seconds = 60;
        });
        await _fadeController.forward();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  Future<void> _playAudio() async {
    if (_isPlaying) return;
    _isPlaying = true;

    final audioManager = Provider.of<AudioManager>(context, listen: false);

    try {
      if (!audioManager.isBgMuted) await audioManager.toggleBgMute();

      // Start both animations
      _scaleController.repeat(reverse: true);
      _fadeController.repeat(reverse: true);

      // Play audio
      await audioManager.playAlert(_currentAyat['audio']!);

      // Stop animations when audio ends
      _scaleController.stop();
      _scaleController.value = 1.0;
      _fadeController.stop();
      _fadeController.value = 1.0;
    } catch (e) {
      debugPrint("Error playing audio: $e");
      _scaleController.stop();
      _scaleController.value = 1.0;
      _fadeController.stop();
      _fadeController.value = 1.0;
    } finally {
      if (!audioManager.isBgMuted) await audioManager.toggleBgMute();
      _isPlaying = false;
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardVisibility = context.watch<CardVisibilityManager>();
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    final themeManager = Provider.of<ThemeManager>(context);
    if (!cardVisibility.showAyatCard) return const SizedBox.shrink();

    final progress = _seconds / 60;

    return ScaleTransition(
      scale: _scaleController,
      child: FadeTransition(
        opacity: _fadeController,
        child: Card(
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: themeManager.currentTheme.accentColor,
              width: 2,
            ),
          ),
          elevation: 12,
          shadowColor: Colors.orange.shade200,
          color: Colors.black.withOpacity(0.15),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _playAudio,
              child: Padding(
                padding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _currentAyat['text'] ?? '',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              wordSpacing: 4,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            strutStyle: const StrutStyle(
                              forceStrutHeight: true,
                              height: 1.2,
                              leading: 0.4,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            audioManager.playEventSound('toggleButton');
                            setState(() => _expanded = !_expanded);
                          },
                          child: AnimatedRotation(
                            turns: _expanded ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.expand_more_rounded,
                                color: themeManager.currentTheme.primaryColor,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_expanded) ...[
                      const SizedBox(height: 16),
                      Text(
                        'التالي بعد: $_seconds ثانية',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation(
                            Colors.orange.shade400.withOpacity(0.9),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _currentAyat['surah'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.orange.shade400.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
