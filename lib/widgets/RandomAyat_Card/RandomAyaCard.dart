import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mortaalim/main.dart';
import 'package:provider/provider.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';

import '../../tools/SavingPreferencesTool_Helper/Preferences_Helper.dart';
import 'Ayat_List.dart';

class ExpandableAyatCard extends StatefulWidget {
  const ExpandableAyatCard({Key? key}) : super(key: key);

  @override
  State<ExpandableAyatCard> createState() => _ExpandableAyatCardState();
}

class _ExpandableAyatCardState extends State<ExpandableAyatCard> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Timer _timer;
  final _random = Random();




  late Map<String, String> _currentAyat;
  int _seconds = 60;
  bool _expanded = false;
  bool _isPlaying = false;  // Flag to prevent multiple audio overlapping
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeController.value = 1;
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
      // Mute background music if needed
      if (!audioManager.isBgMuted) await audioManager.toggleBgMute();

      // Play a fresh instance of the audio
      await audioManager.playAlert(_currentAyat['audio']!);

    } catch (e, st) {
      debugPrint("Error playing audio: $e\n$st");
    } finally {
      // Restore background music state
      if (!audioManager.isBgMuted) await audioManager.toggleBgMute();
      _isPlaying = false;
    }
  }


  @override
  void dispose() {
    _timer.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardVisibility = context.watch<CardVisibilityManager>();
    if (!cardVisibility.showAyatCard) {
      return const SizedBox.shrink();
    }
    final progress = _seconds / 60;
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      shadowColor: Colors.orange.shade100,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _playAudio,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
            child: Column(mainAxisSize: MainAxisSize.max, children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      _currentAyat['text'] ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        wordSpacing: 4,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      strutStyle: const StrutStyle(
                        forceStrutHeight: true,
                        height: 1.2, // exact line spacing factor
                        leading: 0.4, // extra space above/below
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        _expanded ? Icons.expand_less_rounded : Icons.expand_more,
                        color: Colors.orange.shade400,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),

              if (_expanded) ...[
                const SizedBox(height: 16),
                Text(
                  'التالي بعد: $_seconds ثانية',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation(Colors.orange.shade400),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _currentAyat['surah'] ?? '',
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.orange.shade400),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}