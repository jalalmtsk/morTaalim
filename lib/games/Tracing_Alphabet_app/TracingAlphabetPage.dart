import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mortaalim/tools/audio_tool/audio_tool.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import 'package:provider/provider.dart';
import '../../XpSystem.dart';
import '../../main.dart';
import '../../tools/Ads_Manager.dart';

class AlphabetTracingPage extends StatefulWidget {
  final String language;

  const AlphabetTracingPage({super.key, required this.language});

  @override
  State<AlphabetTracingPage> createState() => _AlphabetTracingPageState();
}

class _AlphabetTracingPageState extends State<AlphabetTracingPage> {
  BannerAd? _bannerAd;
  late List<String> _letters;
  late Map<String, Map<String, String>> _letterDetails;
  int _currentLetterIndex = 0;
  final MusicPlayer _drawingSound = MusicPlayer();
  final GlobalKey _paintKey = GlobalKey();
  List<Offset?> _points = [];
  Set<int> _rewardedLetterIndexes = {};

  int xp = 0;
  int Tolims = 0;
  bool _isBannerAdLoaded = false;
  @override
  void initState() {
    super.initState();

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


      case 'russian':
        _letters = [
          'А', 'Б', 'В', 'Г', 'Д', 'Е', 'Ё', 'Ж', 'З', 'И', 'Й',
          'К', 'Л', 'М', 'Н', 'О', 'П', 'Р', 'С', 'Т', 'У', 'Ф',
          'Х', 'Ц', 'Ч', 'Ш', 'Щ', 'Ъ', 'Ы', 'Ь', 'Э', 'Ю', 'Я'
        ];
        _letterDetails = {
          'А': {'pronunciation': 'A', 'example': 'Арбуз (Arbuz) – Watermelon'},
          'Б': {'pronunciation': 'B', 'example': 'Бабочка (Babochka) – Butterfly'},
          'В': {'pronunciation': 'V', 'example': 'Волк (Volk) – Wolf'},
          'Г': {'pronunciation': 'G', 'example': 'Гриб (Grib) – Mushroom'},
          'Д': {'pronunciation': 'D', 'example': 'Дом (Dom) – House'},
          'Е': {'pronunciation': 'Ye', 'example': 'Ель (Yelʹ) – Fir Tree'},
          'Ё': {'pronunciation': 'Yo', 'example': 'Ёж (Yozh) – Hedgehog'},
          'Ж': {'pronunciation': 'Zh', 'example': 'Жираф (Zhiraf) – Giraffe'},
          'З': {'pronunciation': 'Z', 'example': 'Зонт (Zont) – Umbrella'},
          'И': {'pronunciation': 'I', 'example': 'Игра (Igra) – Game'},
          'Й': {'pronunciation': 'Y', 'example': 'Йогурт (Yogurt) – Yogurt'},
          'К': {'pronunciation': 'K', 'example': 'Кот (Kot) – Cat'},
          'Л': {'pronunciation': 'L', 'example': 'Лес (Les) – Forest'},
          'М': {'pronunciation': 'M', 'example': 'Машина (Mashina) – Car'},
          'Н': {'pronunciation': 'N', 'example': 'Нос (Nos) – Nose'},
          'О': {'pronunciation': 'O', 'example': 'Окно (Okno) – Window'},
          'П': {'pronunciation': 'P', 'example': 'Птица (Ptitsa) – Bird'},
          'Р': {'pronunciation': 'R', 'example': 'Рыба (Ryba) – Fish'},
          'С': {'pronunciation': 'S', 'example': 'Собака (Sobaka) – Dog'},
          'Т': {'pronunciation': 'T', 'example': 'Тигр (Tigr) – Tiger'},
          'У': {'pronunciation': 'U', 'example': 'Утка (Utka) – Duck'},
          'Ф': {'pronunciation': 'F', 'example': 'Флаг (Flag) – Flag'},
          'Х': {'pronunciation': 'Kh', 'example': 'Хлеб (Khleb) – Bread'},
          'Ц': {'pronunciation': 'Ts', 'example': 'Цветок (Tsvetok) – Flower'},
          'Ч': {'pronunciation': 'Ch', 'example': 'Чашка (Chashka) – Cup'},
          'Ш': {'pronunciation': 'Sh', 'example': 'Шар (Shar) – Ball'},
          'Щ': {'pronunciation': 'Shch', 'example': 'Щука (Shchuka) – Pike (fish)'},
          'Ъ': {'pronunciation': 'Hard sign', 'example': 'Твёрдый знак (Tvyordy znak) – Silent'},
          'Ы': {'pronunciation': 'Y', 'example': 'Сыры (Syry) – Cheeses'},
          'Ь': {'pronunciation': 'Soft sign', 'example': 'Мягкий знак (Myagkiy znak) – Silent'},
          'Э': {'pronunciation': 'E', 'example': 'Это (Eto) – This'},
          'Ю': {'pronunciation': 'Yu', 'example': 'Юла (Yula) – Spinning Top'},
          'Я': {'pronunciation': 'Ya', 'example': 'Яблоко (Yabloko) – Apple'},
        };
        break;

      case 'chinese':
        _letters = ['人', '口', '大', '小', '日', '月', '山', '水', '火', '木'];
        _letterDetails = {
          '人': {'pronunciation': 'rén', 'example': '人 (rén) – Person'},
          '口': {'pronunciation': 'kǒu', 'example': '口 (kǒu) – Mouth'},
          '大': {'pronunciation': 'dà', 'example': '大人 (dàrén) – Adult'},
          '小': {'pronunciation': 'xiǎo', 'example': '小孩 (xiǎohái) – Child'},
          '日': {'pronunciation': 'rì', 'example': '日出 (rìchū) – Sunrise'},
          '月': {'pronunciation': 'yuè', 'example': '月亮 (yuèliang) – Moon'},
          '山': {'pronunciation': 'shān', 'example': '高山 (gāoshān) – Mountain'},
          '水': {'pronunciation': 'shuǐ', 'example': '喝水 (hē shuǐ) – Drink water'},
          '火': {'pronunciation': 'huǒ', 'example': '火车 (huǒchē) – Train'},
          '木': {'pronunciation': 'mù', 'example': '木头 (mùtou) – Wood'},
        };
        break;

      case 'japanese':
        _letters = [
          'あ', 'い', 'う', 'え', 'お',
          'か', 'き', 'く', 'け', 'こ',
          'さ', 'し', 'す', 'せ', 'そ',
          'た', 'ち', 'つ', 'て', 'と'
        ];

        _letterDetails = {
          // A row
          'あ': {'pronunciation': 'a', 'example': 'あめ (ame) – Rain / Candy'},
          'い': {'pronunciation': 'i', 'example': 'いぬ (inu) – Dog'},
          'う': {'pronunciation': 'u', 'example': 'うみ (umi) – Sea'},
          'え': {'pronunciation': 'e', 'example': 'えんぴつ (enpitsu) – Pencil'},
          'お': {'pronunciation': 'o', 'example': 'おちゃ (ocha) – Tea'},

          // Ka row
          'か': {'pronunciation': 'ka', 'example': 'かさ (kasa) – Umbrella'},
          'き': {'pronunciation': 'ki', 'example': 'き (ki) – Tree'},
          'く': {'pronunciation': 'ku', 'example': 'くるま (kuruma) – Car'},
          'け': {'pronunciation': 'ke', 'example': 'けむし (kemushi) – Caterpillar'},
          'こ': {'pronunciation': 'ko', 'example': 'こども (kodomo) – Child'},

          // Sa row
          'さ': {'pronunciation': 'sa', 'example': 'さかな (sakana) – Fish'},
          'し': {'pronunciation': 'shi', 'example': 'しろ (shiro) – White / Castle'},
          'す': {'pronunciation': 'su', 'example': 'すいか (suika) – Watermelon'},
          'せ': {'pronunciation': 'se', 'example': 'せみ (semi) – Cicada'},
          'そ': {'pronunciation': 'so', 'example': 'そら (sora) – Sky'},

          // Ta row
          'た': {'pronunciation': 'ta', 'example': 'たまご (tamago) – Egg'},
          'ち': {'pronunciation': 'chi', 'example': 'ちず (chizu) – Map'},
          'つ': {'pronunciation': 'tsu', 'example': 'つき (tsuki) – Moon'},
          'て': {'pronunciation': 'te', 'example': 'てがみ (tegami) – Letter'},
          'と': {'pronunciation': 'to', 'example': 'とけい (tokei) – Clock'},
        };
        break;


      case 'korean':
        _letters = [
          'ㄱ', 'ㄴ', 'ㄷ', 'ㄹ', 'ㅁ',
          'ㅂ', 'ㅅ', 'ㅇ', 'ㅈ', 'ㅊ',
          'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ',
          'ㅏ', 'ㅑ', 'ㅓ', 'ㅕ', 'ㅗ',
          'ㅛ', 'ㅜ', 'ㅠ', 'ㅡ', 'ㅣ'
        ];

        _letterDetails = {
          'ㄱ': {'pronunciation': 'g/k', 'example': '가방 (gabang) – Bag'},
          'ㄴ': {'pronunciation': 'n', 'example': '나무 (namu) – Tree'},
          'ㄷ': {'pronunciation': 'd/t', 'example': '달 (dal) – Moon'},
          'ㄹ': {'pronunciation': 'r/l', 'example': '라면 (ramyeon) – Ramen'},
          'ㅁ': {'pronunciation': 'm', 'example': '물 (mul) – Water'},

          'ㅂ': {'pronunciation': 'b/p', 'example': '바다 (bada) – Sea'},
          'ㅅ': {'pronunciation': 's', 'example': '사과 (sagwa) – Apple'},
          'ㅇ': {'pronunciation': 'ng/silent', 'example': '아이 (ai) – Child'},
          'ㅈ': {'pronunciation': 'j', 'example': '자전거 (jajeongeo) – Bicycle'},
          'ㅊ': {'pronunciation': 'ch', 'example': '치마 (chima) – Skirt'},

          'ㅋ': {'pronunciation': 'k', 'example': '코 (ko) – Nose'},
          'ㅌ': {'pronunciation': 't', 'example': '토끼 (tokki) – Rabbit'},
          'ㅍ': {'pronunciation': 'p', 'example': '피자 (pija) – Pizza'},
          'ㅎ': {'pronunciation': 'h', 'example': '하늘 (haneul) – Sky'},

          'ㅏ': {'pronunciation': 'a', 'example': '아기 (agi) – Baby'},
          'ㅑ': {'pronunciation': 'ya', 'example': '야구 (yagu) – Baseball'},
          'ㅓ': {'pronunciation': 'eo', 'example': '어서 (eoseo) – Quickly'},
          'ㅕ': {'pronunciation': 'yeo', 'example': '여우 (yeou) – Fox'},
          'ㅗ': {'pronunciation': 'o', 'example': '오이 (oi) – Cucumber'},

          'ㅛ': {'pronunciation': 'yo', 'example': '요리 (yori) – Cooking'},
          'ㅜ': {'pronunciation': 'u', 'example': '우산 (usan) – Umbrella'},
          'ㅠ': {'pronunciation': 'yu', 'example': '유리 (yuri) – Glass'},
          'ㅡ': {'pronunciation': 'eu', 'example': '음악 (eumak) – Music'},
          'ㅣ': {'pronunciation': 'i', 'example': '이름 (ireum) – Name'},
        };
        break;


      case 'french':
      default:
        _letters = List.generate(26, (i) => String.fromCharCode(65 + i));
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
    }

    _loadBannerAd();
  }

  void _clearCanvas() {
    setState(() {
      _points = []; // assign new list, not just _points.clear()
    });
  }

  void _nextLetter() {
    setState(() {
      _currentLetterIndex = (_currentLetterIndex + 1) % _letters.length;
      _points.clear();
    });
  }

  void giveTolimAndXP() {
    setState(() {
      xp += 10;
      Tolims += 1;
    });
  }

  void _showRewardToast(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final entry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.deepOrangeAccent.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), () => entry.remove());
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


  double _calculateTotalDrawnDistance(List<Offset?> points) {
    double distance = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      if (p1 != null && p2 != null) {
        distance += (p1 - p2).distance;
      }
    }
    return distance;
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final xpManager = Provider.of<ExperienceManager>(context);
    final currentLetter = _letters[_currentLetterIndex];
    final details = _letterDetails[currentLetter];
    final pronunciation = details?['pronunciation'] ?? '';
    final example = details?['example'] ?? '';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFE0B2),
              Color(0xFFFFCCBC),
              Color(0xFFFFAB91),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Userstatutbar(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(12),
                        backgroundColor: Colors.deepOrange,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Text(
                      'Letter ${_currentLetterIndex + 1}/${_letters.length}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown,
                      ),
                    ),
                    const SizedBox(width: 48), // Empty for alignment
                  ],
                ),
              ),

              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(4, 4),
                      )
                    ],
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          currentLetter,
                          style: TextStyle(
                            fontSize: 200,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade100,
                          ),
                        ),
                      ),
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
                            _points = List.from(_points)..add(null);
                          });

                          final drawnDistance = _calculateTotalDrawnDistance(_points);

                          if (drawnDistance > 500 && !_rewardedLetterIndexes.contains(_currentLetterIndex)) {
                            _rewardedLetterIndexes.add(_currentLetterIndex);
                            giveTolimAndXP();
                            xpManager.addTokens(1);
                            xpManager.addXP(2, context: context);
                          }
                        },
                        child: CustomPaint(
                          key: _paintKey,
                          painter: TracingPainter(points: _points),
                          size: const Size(320, 320),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Card(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                color: Colors.white.withOpacity(0.9),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        "🔤 Pronunciation: $pronunciation",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "📘 Example: $example",
                        style: const TextStyle(fontSize: 17),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _clearCanvas,
                            icon: const Icon(Icons.refresh),
                            label: const Text("Retry"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange.shade300,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _nextLetter,
                            icon: const Icon(Icons.navigate_next),
                            label: const Text("Next"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orangeAccent.shade200,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [BoxShadow(color: Colors.orange.shade100, blurRadius: 10)],
                        ),
                        child: Text(
                          "🎯 Score: $Tolims",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
      bottomNavigationBar: context.watch<ExperienceManager>().adsEnabled && _bannerAd != null && _isBannerAdLoaded
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
