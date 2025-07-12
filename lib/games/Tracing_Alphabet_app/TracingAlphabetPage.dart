import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mortaalim/tools/audio_tool/audio_tool.dart';

import '../../main.dart';
import '../../tools/Ads_Manager.dart';


class AlphabetTracingPage extends StatefulWidget {
  final String language; // 'french' or 'arabic'

  const AlphabetTracingPage({super.key, required this.language});

  @override
  State<AlphabetTracingPage> createState() => _AlphabetTracingPageState();
}

class _AlphabetTracingPageState extends State<AlphabetTracingPage> {
  BannerAd? _bannerAd;
  late List<String> _letters;
  late Map<String, Map<String, String>> _letterDetails;
  int _currentLetterIndex = 0;
  final MusicPlayer _drawingSound = new MusicPlayer();

  @override
  void initState() {
    super.initState();

    // Load letters based on language...
    switch (widget.language) {
    // your existing switch cases...
    }
    // ✅ Load banner ad
    _bannerAd = AdHelper.getBannerAd(() {
      if (mounted) setState(() {});
    });

    switch (widget.language) {
      case 'arabic':
        _letters = ['ا', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ'];
        _letterDetails = {
          'ا': {'pronunciation': 'Alif', 'example': 'أسد (Asad) – Lion'},
          'ب': {'pronunciation': 'Ba', 'example': 'بيت (Bayt) – House'},
          'ت': {'pronunciation': 'Ta', 'example': 'تفاح (Tuffāḥ) – Apple'},
          'ث': {'pronunciation': 'Tha', 'example': 'ثعلب (Tha‘lab) – Fox'},
          'ج': {'pronunciation': 'Jim', 'example': 'جمل (Jamal) – Camel'},
          'ح': {'pronunciation': 'Ha', 'example': 'حصان (Ḥiṣān) – Horse'},
          'خ': {'pronunciation': 'Kha', 'example': 'خبز (Khubz) – Bread'},
        };
        break;

      case 'japanese':
        _letters = ['あ', 'い', 'う', 'え', 'お', 'か', 'き', 'く', 'け', 'こ'];
        _letterDetails = {
          'あ': {'pronunciation': 'a', 'example': 'あめ (ame) – Rain'},
          'い': {'pronunciation': 'i', 'example': 'いぬ (inu) – Dog'},
          'う': {'pronunciation': 'u', 'example': 'うま (uma) – Horse'},
          'え': {'pronunciation': 'e', 'example': 'えんぴつ (enpitsu) – Pencil'},
          'お': {'pronunciation': 'o', 'example': 'おにぎり (onigiri) – Rice ball'},
          'か': {'pronunciation': 'ka', 'example': 'かさ (kasa) – Umbrella'},
          'き': {'pronunciation': 'ki', 'example': 'きつね (kitsune) – Fox'},
          'く': {'pronunciation': 'ku', 'example': 'くるま (kuruma) – Car'},
          'け': {'pronunciation': 'ke', 'example': 'けむし (kemushi) – Caterpillar'},
          'こ': {'pronunciation': 'ko', 'example': 'こども (kodomo) – Child'},
        };
        break;

      case 'korean':
        _letters = ['ㄱ', 'ㄴ', 'ㄷ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅅ', 'ㅇ', 'ㅈ', 'ㅊ'];
        _letterDetails = {
          'ㄱ': {'pronunciation': 'G/K (giyeok)', 'example': '고양이 (goyangi) – Cat'},
          'ㄴ': {'pronunciation': 'N (nieun)', 'example': '나무 (namu) – Tree'},
          'ㄷ': {'pronunciation': 'D/T (digeut)', 'example': '다리 (dari) – Leg/Bridge'},
          'ㄹ': {'pronunciation': 'R/L (rieul)', 'example': '라면 (ramyeon) – Ramen'},
          'ㅁ': {'pronunciation': 'M (mieum)', 'example': '물 (mul) – Water'},
          'ㅂ': {'pronunciation': 'B/P (bieup)', 'example': '바다 (bada) – Sea'},
          'ㅅ': {'pronunciation': 'S (siot)', 'example': '사과 (sagwa) – Apple'},
          'ㅇ': {'pronunciation': 'Silent/ng (ieung)', 'example': '아이 (ai) – Child'},
          'ㅈ': {'pronunciation': 'J (jieut)', 'example': '자동차 (jadongcha) – Car'},
          'ㅊ': {'pronunciation': 'Ch (chieut)', 'example': '책 (chaek) – Book'},
        };
        break;
      case 'chinese':
        _letters = ['一', '二', '三', '人', '大', '口', '日', '月', '山', '水'];
        _letterDetails = {
          '一': {'pronunciation': 'yī', 'example': '一人 (yī rén) – One person'},
          '二': {'pronunciation': 'èr', 'example': '二月 (èr yuè) – February'},
          '三': {'pronunciation': 'sān', 'example': '三本书 (sān běn shū) – Three books'},
          '人': {'pronunciation': 'rén', 'example': '中国人 (zhōng guó rén) – Chinese person'},
          '大': {'pronunciation': 'dà', 'example': '大学 (dà xué) – University'},
          '口': {'pronunciation': 'kǒu', 'example': '人口 (rén kǒu) – Population'},
          '日': {'pronunciation': 'rì', 'example': '生日 (shēng rì) – Birthday'},
          '月': {'pronunciation': 'yuè', 'example': '月亮 (yuè liàng) – Moon'},
          '山': {'pronunciation': 'shān', 'example': '山水 (shān shuǐ) – Landscape'},
          '水': {'pronunciation': 'shuǐ', 'example': '水果 (shuǐ guǒ) – Fruit'},
        };
        break;
      case 'russian':
        _letters = ['А', 'Б', 'В', 'Г', 'Д', 'Е', 'Ё', 'Ж', 'З', 'И'];
        _letterDetails = {
          'А': {'pronunciation': 'A', 'example': 'Арбуз (Arbuz) – Watermelon'},
          'Б': {'pronunciation': 'B', 'example': 'Банан (Banan) – Banana'},
          'В': {'pronunciation': 'V', 'example': 'Волк (Volk) – Wolf'},
          'Г': {'pronunciation': 'G', 'example': 'Груша (Grusha) – Pear'},
          'Д': {'pronunciation': 'D', 'example': 'Дом (Dom) – House'},
          'Е': {'pronunciation': 'Ye', 'example': 'Ель (Yel) – Fir tree'},
          'Ё': {'pronunciation': 'Yo', 'example': 'Ёж (Yozh) – Hedgehog'},
          'Ж': {'pronunciation': 'Zh', 'example': 'Жук (Zhuk) – Beetle'},
          'З': {'pronunciation': 'Z', 'example': 'Звезда (Zvezda) – Star'},
          'И': {'pronunciation': 'Ee', 'example': 'Игла (Igla) – Needle'},
        };
        break;

      case 'french':
        _letters = List.generate(26, (i) => String.fromCharCode(65 + i)); // A–Z
        _letterDetails = {
          'A': {'pronunciation': 'ah', 'example': 'Avion – Plane'},
          'B': {'pronunciation': 'bay', 'example': 'Banane – Banana'},
          'C': {'pronunciation': 'say', 'example': 'Chat – Cat'},
          'D': {'pronunciation': 'day', 'example': 'Dauphin – Dolphin'},
          'E': {'pronunciation': 'uh', 'example': 'Étoile – Star'},
          'F': {'pronunciation': 'eff', 'example': 'Fromage – Cheese'},
          'G': {'pronunciation': 'zhay', 'example': 'Gâteau – Cake'},
          'H': {'pronunciation': 'ahsh', 'example': 'Hôpital – Hospital'},
          'I': {'pronunciation': 'ee', 'example': 'Île – Island'},
          'J': {'pronunciation': 'zhee', 'example': 'Jardin – Garden'},
          'K': {'pronunciation': 'kah', 'example': 'Koala – Koala'},
          'L': {'pronunciation': 'ell', 'example': 'Lait – Milk'},
          'M': {'pronunciation': 'emm', 'example': 'Montagne – Mountain'},
          'N': {'pronunciation': 'enn', 'example': 'Nez – Nose'},
          'O': {'pronunciation': 'oh', 'example': 'Orange – Orange'},
          'P': {'pronunciation': 'pay', 'example': 'Poisson – Fish'},
          'Q': {'pronunciation': 'ku', 'example': 'Quiche – Quiche'},
          'R': {'pronunciation': 'air', 'example': 'Rivière – River'},
          'S': {'pronunciation': 'ess', 'example': 'Soleil – Sun'},
          'T': {'pronunciation': 'tay', 'example': 'Tigre – Tiger'},
          'U': {'pronunciation': 'u', 'example': 'Usine – Factory'},
          'V': {'pronunciation': 'vay', 'example': 'Voiture – Car'},
          'W': {'pronunciation': 'doo-bluh-vay', 'example': 'Wagon – Wagon'},
          'X': {'pronunciation': 'eeks', 'example': 'Xylophone – Xylophone'},
          'Y': {'pronunciation': 'ee-grek', 'example': 'Yaourt – Yogurt'},
          'Z': {'pronunciation': 'zed', 'example': 'Zèbre – Zebra'},
        };
        break;

      case 'french':
      default:
        _letters = List.generate(26, (i) => String.fromCharCode(65 + i)); // A–Z
    }
  }




  final GlobalKey _paintKey = GlobalKey();
  List<Offset?> _points = [];


  void _clearCanvas() {
    setState(() {
      _points.clear();
    });
  }

  void _nextLetter() {
    setState(() {
      _currentLetterIndex = (_currentLetterIndex + 1) % _letters.length;
      _points.clear();
    });
  }
@override
  void dispose() {
  _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentLetter = _letters[_currentLetterIndex];
    final details = _letterDetails[currentLetter];
    final pronunciation = details?['pronunciation'] ?? '';
    final example = details?['example'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title:  Text(tr(context).alphabetTracing),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 300,
              height: 300,
              child: Stack(
                children: [
                  // Big letter in background
                  Center(
                    child: Text(
                      currentLetter,
                      style: TextStyle(
                        fontSize: 200,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade200,
                        fontFamily: 'NotoSansJP', // or 'NotoSansKR', 'NotoSansSC'
                      ),
                    ),
                  ),


                  // Drawing canvas on top
                  GestureDetector(

                    onPanStart: (_) {
                      _drawingSound.play("audios/writting.mp3");
                    },
                    onPanUpdate: (details) {
                      final box = _paintKey.currentContext?.findRenderObject() as RenderBox?;
                      if (box != null) {
                        final localPosition = box.globalToLocal(details.globalPosition);
                        setState(() {
                          _points = List.from(_points)..add(localPosition);
                        });
                      }
                    },
                    onPanEnd: (_) {
                      _drawingSound.stop();
                      setState(() {
                        _points = List.from(_points)..add(null); // Stroke separator
                      });
                    },
                    child: CustomPaint(
                      key: _paintKey,
                      painter: TracingPainter(points: _points),
                      size: const Size(300, 300),
                    ),
                  ),


                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _clearCanvas,
                  icon: const Icon(Icons.clear),
                  label:  Text(tr(context).clear),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),


                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: _nextLetter,
                  icon: const Icon(Icons.arrow_forward),
                  label:  Text(tr(context).nextLetter),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),

            Text(
              'Pronunciation: $pronunciation',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),


            Text(
              'Example: $example',
              style: const TextStyle(fontSize: 22, color: Colors.black54),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: _bannerAd != null
          ? SizedBox(
        height: _bannerAd!.size.height.toDouble(),
        width: _bannerAd!.size.width.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      )
          : null,
    );

  }
}

class TracingPainter extends CustomPainter {
  final List<Offset?> points;

  TracingPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.deepOrange
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant TracingPainter oldDelegate) => oldDelegate.points != points;
}
