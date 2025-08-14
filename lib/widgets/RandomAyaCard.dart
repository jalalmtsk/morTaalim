import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mortaalim/main.dart';
import 'package:provider/provider.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';

import '../tools/SavingPreferencesTool_Helper/Preferences_Helper.dart';

class ExpandableAyatCard extends StatefulWidget {
  const ExpandableAyatCard({Key? key}) : super(key: key);

  @override
  State<ExpandableAyatCard> createState() => _ExpandableAyatCardState();
}

class _ExpandableAyatCardState extends State<ExpandableAyatCard> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Timer _timer;
  final _random = Random();


  final _ayatList = [
    {
      'text':
      'اقْرَأْ بِاسْمِ رَبِّكَ الَّذِي خَلَقَْ',
      'surah': 'العلق - 1-5',
      'audio': 'assets/audios/quranSourate/AlAlaq1-5.mp3',
      'tafsir':
      'هذه أول آيات نزلت تدعو إلى القراءة والتعلم باسم الله، وتشير إلى أهمية العلم الذي علمه الله للإنسان.',
      'translation':
      'Read in the name of your Lord who created — Created man from a clinging substance. Read, and your Lord is the most Generous — Who taught by the pen — Taught man that which he knew not.'
    },
    {
      'text':
      'وَقُل رَّبِّ زِدْنِي عِلْمًا',
      'surah': 'طه - 114',
      'audio': 'assets/audios/quranSourate/Taha114.mp3',
      'tafsir':
      'دعاء النبي محمد صلى الله عليه وسلم أن يطلب من الله أن يزيده علماً نافعا.',
      'translation':
      'And say, "My Lord, increase me in knowledge."'
    },
    {
      'text':
      'يَا أَيُّهَا الَّذِينَ آمَنُوا إِذَا قِيلَ لَكُمْ تَفَسَّحُوا فِي الْمَجَالِسِ فَافْسَحُوا يَفْسَحِ اللَّهُ لَكُمْ ۖ وَإِذَا قِيلَ انشُزُوا فَانشُزُوا يَرْفَعِ اللَّهُ الَّذِينَ آمَنُوا مِنكُمْ وَالَّذِينَ أُوتُوا الْعِلْمَ دَرَجَاتٍ ۚ وَاللَّهُ بِمَا تَعْمَلُونَ خَبِيرٌ',
      'surah': 'المجادلة - 11',
      'audio': 'assets/audios/quranSourate/AlMujadila11.mp3',
      'tafsir':
      'الله يرفع درجات الذين آمنوا والذين أوتوا العلم بين الناس تقديراً لهم.',
      'translation':
      'Allah will raise those who have believed among you and those who were given knowledge, by degrees.'
    },
    {
      'text':
      'قَالَ يَـٰقَوْمِ أَرَءَيْتُمْ إِن كُنتُ عَلَىٰ بَيِّنَةٍۢ مِّن رَّبِّى وَرَزَقَنِى مِنْهُ رِزْقًا حَسَنًۭا ۚ وَمَآ أُرِيدُ أَنْ أُخَالِفَكُمْ إِلَىٰ مَآ أَنْهَىٰكُمْ عَنْهُ ۚ إِنْ أُرِيدُ إِلَّا ٱلْإِصْلَـٰحَ مَا ٱسْتَطَعْتُ ۚ وَمَا تَوْفِيقِىٓ إِلَّا بِٱللَّهِ ۚ عَلَيْهِ تَوَكَّلْتُ وَإِلَيْهِ أُنِيبُ',
      'surah': 'سورة هود - الآية 88',
      'audio': 'assets/audios/quranSourate/RandomAyat/Hud88.mp3',
    },
    {
      'text':
      'وَوَصَّيْنَا الَّذِينَ أُوتُوا الْكِتَابَ مِن قَبْلِكُمْ وَإِيَّاكُمْ أَنِ اتَّقُوا اللَّهَ',
      'surah': 'النساء - 131',
      'audio': 'assets/audios/quranSourate/AnNisa131.mp3',
      'tafsir':
      'وصية الله بالتقوى لجميع الناس، خاصة أهل الكتاب، مما يؤكد أهمية التربية والتوجيه السليم.',
      'translation':
      'And We have instructed those who were given the Scripture before you and yourselves to fear Allah.'
    }
  ];

  late Map<String, String> _currentAyat;
  int _seconds = 60;
  bool _expanded = false;
  bool _isPlaying = false;  // Flag to prevent multiple audio overlapping
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeController.value = 1;
    _currentAyat = _ayatList[_random.nextInt(_ayatList.length)];
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (_seconds == 0) {
        await _fadeController.reverse();
        setState(() {
          _currentAyat = _ayatList[_random.nextInt(_ayatList.length)];
          _seconds = 60;
        });
        await _fadeController.forward();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  Future<void> _playAudio() async {
    if (_isPlaying) return; // If already playing, ignore tap
    _isPlaying = true;
    final audio = Provider.of<AudioManager>(context, listen: false);
    try {
      audioManager.toggleBgMute();
      await audio.playSfx(_currentAyat['audio']!);
    } catch (_) {}
    audioManager.toggleBgMute();
    _isPlaying = false;
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
    if (!cardVisibility.showCard) {
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
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      _currentAyat['text'] ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 0.8,
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