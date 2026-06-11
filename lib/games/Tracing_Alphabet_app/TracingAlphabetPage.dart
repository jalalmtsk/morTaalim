import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import 'package:provider/provider.dart';
import '../../XpSystem.dart';
import '../../main.dart';
import '../../tools/Ads_Manager.dart';
import '../../tools/Reysable_Tools/Info_First_Intro_Info_Dialog.dart';

// ─────────────────────────────────────────────────────────────
// BRUSH THEME  – kids choose one before tracing
// ─────────────────────────────────────────────────────────────
class BrushTheme {
  final String label;
  final String emoji;
  final List<Color> colors; // cycles as the stroke grows
  final double strokeWidth;

  const BrushTheme({
    required this.label,
    required this.emoji,
    required this.colors,
    this.strokeWidth = 9.0,
  });
}

const List<BrushTheme> kBrushThemes = [
  BrushTheme(
    label: 'Fire',
    emoji: '🔥',
    colors: [Color(0xFFFF6B35), Color(0xFFFF9F1C), Color(0xFFFFD700)],
    strokeWidth: 10,
  ),
  BrushTheme(
    label: 'Ocean',
    emoji: '🌊',
    colors: [Color(0xFF0077B6), Color(0xFF00B4D8), Color(0xFF90E0EF)],
    strokeWidth: 9,
  ),
  BrushTheme(
    label: 'Rainbow',
    emoji: '🌈',
    colors: [
      Color(0xFFFF595E),
      Color(0xFFFF924C),
      Color(0xFFFFCA3A),
      Color(0xFF8AC926),
      Color(0xFF1982C4),
      Color(0xFF6A4C93),
    ],
    strokeWidth: 9,
  ),
  BrushTheme(
    label: 'Galaxy',
    emoji: '✨',
    colors: [Color(0xFF7B2FBE), Color(0xFF9D4EDD), Color(0xFFE0AAFF)],
    strokeWidth: 8,
  ),
  BrushTheme(
    label: 'Nature',
    emoji: '🌿',
    colors: [Color(0xFF2D6A4F), Color(0xFF52B788), Color(0xFFB7E4C7)],
    strokeWidth: 9,
  ),
];

// ─────────────────────────────────────────────────────────────
// MASCOT STATE
// ─────────────────────────────────────────────────────────────
enum MascotMood { idle, happy, cheer, encourage }

// ─────────────────────────────────────────────────────────────
// MAIN PAGE
// ─────────────────────────────────────────────────────────────
class AlphabetTracingPage extends StatefulWidget {
  final String language;
  const AlphabetTracingPage({super.key, required this.language});

  @override
  State<AlphabetTracingPage> createState() => _AlphabetTracingPageState();
}

class _AlphabetTracingPageState extends State<AlphabetTracingPage>
    with TickerProviderStateMixin {
  // ── Ads ──────────────────────────────────────────────────────
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  // ── Letter data ───────────────────────────────────────────────
  late List<String> _letters;
  late Map<String, Map<String, String>> _letterDetails;
  int _currentLetterIndex = 0;

  // ── Drawing ───────────────────────────────────────────────────
  final GlobalKey _paintKey = GlobalKey();
  List<Offset?> _points = [];
  Set<int> _rewardedLetterIndexes = {};
  int _selectedBrushIndex = 0;
  int _strokeColorStep = 0; // cycles through brush colors

  // ── Score & streak ────────────────────────────────────────────
  int score = 0;
  int _streak = 0;
  bool _letterJustCompleted = false; // drives mini-trophy splash

  // ── Glow animation ────────────────────────────────────────────
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  bool _showGlow = false;

  // ── Progress bar pulse ────────────────────────────────────────
  late AnimationController _progressPulseController;
  late Animation<double> _progressPulseAnim;

  // ── Mascot bounce ─────────────────────────────────────────────
  late AnimationController _mascotController;
  late Animation<double> _mascotBounce;
  MascotMood _mascotMood = MascotMood.idle;

  // ── Letter completion trophy ──────────────────────────────────
  late AnimationController _trophyController;
  late Animation<double> _trophyScale;

  // ── TTS ───────────────────────────────────────────────────────
  late FlutterTts flutterTts;

  // ── Quiz mini-game every 5 letters ───────────────────────────
  bool _showQuiz = false;
  List<String> _quizOptions = [];
  String _quizAnswer = '';
  bool? _quizCorrect;

  // ── Letter fill animation ─────────────────────────────────────
  late AnimationController _fillController;
  late Animation<double> _fillAnim;
  bool _showFill = false;

  @override
  void initState() {
    super.initState();
    _setupLetters();
    _loadBannerAd();

    flutterTts = FlutterTts();
    _configureTtsLanguage();

    // Glow
    _glowController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _glowAnimation =
    Tween<double>(begin: 0.0, end: 16.0).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _glowController.reverse();
        else if (s == AnimationStatus.dismissed) _glowController.forward();
      });

    // Progress pulse
    _progressPulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _progressPulseAnim =
        Tween<double>(begin: 1.0, end: 1.08).animate(CurvedAnimation(
          parent: _progressPulseController,
          curve: Curves.easeOut,
        ));

    // Mascot
    _mascotController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _mascotBounce =
        Tween<double>(begin: 0.0, end: -14.0).animate(CurvedAnimation(
          parent: _mascotController,
          curve: Curves.easeOut,
        ));
    _mascotController.addStatusListener((s) {
      if (s == AnimationStatus.completed) _mascotController.reverse();
    });

    // Trophy
    _trophyController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _trophyScale = CurvedAnimation(
        parent: _trophyController, curve: Curves.elasticOut);

    // Fill
    _fillController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _fillAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fillController, curve: Curves.easeIn));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showBrushPicker(firstTime: true);
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _progressPulseController.dispose();
    _mascotController.dispose();
    _trophyController.dispose();
    _fillController.dispose();
    _bannerAd?.dispose();
    flutterTts.stop();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // LETTER DATA  (unchanged – all your original data preserved)
  // ─────────────────────────────────────────────────────────────
  void _setupLetters() {
    switch (widget.language) {
      case 'arabic':
        _letters = ["ا","ب","ت","ث","ج","ح","خ","د","ذ","ر","ز","س","ش","ص","ض","ط","ظ","ع","غ","ف","ق","ك","ل","م","ن","ه","و","ي"];
        _letterDetails = {
          'ا': {'pronunciation': 'Alif', 'example': 'أسد (Asad) – Lion'},
          'ب': {'pronunciation': 'Ba',   'example': 'بيت (Bayt) – House'},
          'ت': {'pronunciation': 'Ta',   'example': 'تفاح (Tuffāḥ) – Apple'},
          'ث': {'pronunciation': 'Tha',  'example': 'ثعلب (Tha\'lab) – Fox'},
          'ج': {'pronunciation': 'Jim',  'example': 'جمل (Jamal) – Camel'},
          'ح': {'pronunciation': 'Ha',   'example': 'حصان (Ḥiṣān) – Horse'},
          'خ': {'pronunciation': 'Kha',  'example': 'خبز (Khubz) – Bread'},
          'د': {'pronunciation': 'Dal',  'example': 'دجاجة (Dajājah) – Chicken'},
          'ذ': {'pronunciation': 'Dhal', 'example': 'ذهب (Dhahab) – Gold'},
          'ر': {'pronunciation': 'Ra',   'example': 'رمان (Rummān) – Pomegranate'},
          'ز': {'pronunciation': 'Zay',  'example': 'زيتون (Zaytūn) – Olive'},
          'س': {'pronunciation': 'Sin',  'example': 'سمك (Samak) – Fish'},
          'ش': {'pronunciation': 'Shin', 'example': 'شمس (Shams) – Sun'},
          'ص': {'pronunciation': 'Sad',  'example': 'صقر (Ṣaqr) – Falcon'},
          'ض': {'pronunciation': 'Dad',  'example': 'ضوء (Ḍawʼ) – Light'},
          'ط': {'pronunciation': 'Taʼ',  'example': 'طائرة (Ṭāʼirah) – Airplane'},
          'ظ': {'pronunciation': 'Zaʼ',  'example': 'ظرف (Ẓarf) – Envelope'},
          'ع': {'pronunciation': 'Ayn',  'example': 'عنب (ʿInab) – Grapes'},
          'غ': {'pronunciation': 'Ghayn','example': 'غزال (Ghazāl) – Gazelle'},
          'ف': {'pronunciation': 'Fa',   'example': 'فيل (Fīl) – Elephant'},
          'ق': {'pronunciation': 'Qaf',  'example': 'قلم (Qalam) – Pen'},
          'ك': {'pronunciation': 'Kaf',  'example': 'كتاب (Kitāb) – Book'},
          'ل': {'pronunciation': 'Lam',  'example': 'ليمون (Laymūn) – Lemon'},
          'م': {'pronunciation': 'Mim',  'example': 'مدينة (Madīnah) – City'},
          'ن': {'pronunciation': 'Nun',  'example': 'نمر (Namir) – Tiger'},
          'هـ': {'pronunciation': 'Haʼ', 'example': 'هاتف (Hātif) – Phone'},
          'و': {'pronunciation': 'Waw',  'example': 'وردة (Wardah) – Rose'},
          'ي': {'pronunciation': 'Ya',   'example': 'يد (Yad) – Hand'},
        };
        break;

      case 'amazigh':
        _letters = ["ⴰ","ⴱ","ⴲ","ⴳ","ⴴ","ⴵ","ⴶ","ⴷ","ⴸ","ⴹ","ⴺ","ⴻ","ⴼ","ⴽ","ⴾ","ⴿ","ⵀ","ⵁ","ⵂ","ⵃ","ⵄ","ⵅ","ⵆ","ⵇ","ⵈ","ⵉ","ⵊ","ⵋ","ⵌ","ⵍ","ⵎ","ⵏ","ⵐ","ⵑ","ⵒ","ⵓ","ⵔ","ⵕ","ⵖ","ⵗ","ⵘ","ⵙ","ⵚ","ⵛ","ⵜ","ⵝ","ⵞ","ⵟ","ⵠ","ⵡ","ⵢ","ⵣ","ⵤ","ⵥ"];
        _letterDetails = {
          'ⴰ': {'pronunciation': 'A',    'example': 'ⴰⵙⴷ (Asd) – Lion'},
          'ⴱ': {'pronunciation': 'B',    'example': 'ⴱⵉⵜ (Bit) – House'},
          'ⴲ': {'pronunciation': 'P',    'example': 'ⴲⵓⵙ (Pus) – Water'},
          'ⴳ': {'pronunciation': 'G',    'example': 'ⴳⴰⵎⴰⵍ (Gamal) – Camel'},
          'ⴴ': {'pronunciation': 'Ḡ',    'example': 'ⴴⴰⵣⴰⵍ (Ḡazal) – Gazelle'},
          'ⴵ': {'pronunciation': 'J',    'example': 'ⴵⴰⵎⴰⵍ (Jamal) – Camel'},
          'ⴶ': {'pronunciation': 'V',    'example': 'ⴶⴰⵣ (Vaz) – Flower'},
          'ⴷ': {'pronunciation': 'D',    'example': 'ⴷⴰⵊⴰ (Daja) – Chicken'},
          'ⴸ': {'pronunciation': 'Ḍ',    'example': 'ⴸⴰⵡ (Ḍaw) – Light'},
          'ⴹ': {'pronunciation': 'Ḍh',   'example': 'ⴹⴰⵣⴰⵍ (Ḍhazal) – Sun'},
          'ⴺ': {'pronunciation': 'DJ',   'example': 'ⴺⴰⴹⵉ (DJadi) – Eagle'},
          'ⴻ': {'pronunciation': 'E',    'example': 'ⴻⵍⵍⴰⵎ (Ellam) – Water'},
          'ⴼ': {'pronunciation': 'F',    'example': 'ⴼⵉⵍ (Fil) – Elephant'},
          'ⴽ': {'pronunciation': 'K',    'example': 'ⴽⵉⵜⴰⴱ (Kitab) – Book'},
          'ⴾ': {'pronunciation': 'KH',   'example': 'ⴾⴰⵣ (Khaz) – Tree'},
          'ⴿ': {'pronunciation': 'KHʼ',  'example': 'ⴿⴰⵡ (Khʼaw) – Mountain'},
          'ⵀ': {'pronunciation': 'H',    'example': 'ⵀⴰⵡⴰ (Hawa) – Wind'},
          'ⵁ': {'pronunciation': 'HH',   'example': 'ⵁⴰⵣⴰ (Hhaza) – Sun'},
          'ⵂ': {'pronunciation': 'Ɣ',    'example': 'ⵂⴰⵣⴰⵍ (Ɣazal) – Gazelle'},
          'ⵃ': {'pronunciation': 'Ḥ',    'example': 'ⵃⴰⵎⵎⴰⵍ (Ḥammal) – Worker'},
          'ⵄ': {'pronunciation': 'ʿ',    'example': 'ⵄⴰⵎⴰⵍ (ʿAmal) – Hope'},
          'ⵅ': {'pronunciation': 'KH',   'example': 'ⵅⴰⵣⴰⵍ (Khazal) – Plant'},
          'ⵆ': {'pronunciation': 'GH',   'example': 'ⵆⴰⵎⴰⵍ (Ghamal) – Camel'},
          'ⵇ': {'pronunciation': 'Q',    'example': 'ⵇⴰⵎ (Qam) – Leader'},
          'ⵈ': {'pronunciation': 'KHʼ',  'example': 'ⵈⴰⵣ (Khʼaz) – Hill'},
          'ⵉ': {'pronunciation': 'I',    'example': 'ⵉⵣⵓⵍ (Izul) – Moon'},
          'ⵊ': {'pronunciation': 'J',    'example': 'ⵊⴰⵎⴰⵍ (Jamal) – Camel'},
          'ⵋ': {'pronunciation': 'CH',   'example': 'ⵋⴰⵎⴰⵍ (Chamal) – Road'},
          'ⵌ': {'pronunciation': 'CHʼ',  'example': 'ⵌⴰⵣ (Chʼaz) – Tree'},
          'ⵍ': {'pronunciation': 'L',    'example': 'ⵍⴰⵢⵎⵓⵏ (Laymun) – Lemon'},
          'ⵎ': {'pronunciation': 'M',    'example': 'ⵎⴰⴷⵉⵏⴰ (Madina) – City'},
          'ⵏ': {'pronunciation': 'N',    'example': 'ⵏⴰⵎⵉⵔ (Namir) – Tiger'},
          'ⵐ': {'pronunciation': 'NY',   'example': 'ⵐⴰⵣⴰⵍ (Nyazal) – Flower'},
          'ⵑ': {'pronunciation': 'NG',   'example': 'ⵑⴰⵎⴰⵍ (Ngamal) – Camel'},
          'ⵒ': {'pronunciation': 'QH',   'example': 'ⵒⴰⵣⴰⵍ (Qhazal) – Gazelle'},
          'ⵓ': {'pronunciation': 'U',    'example': 'ⵓⵔⴷⴰ (Urda) – Rose'},
          'ⵔ': {'pronunciation': 'R',    'example': 'ⵔⵓⵎⵎⴰⵏ (Rumman) – Pomegranate'},
          'ⵕ': {'pronunciation': 'Ḍ',    'example': 'ⵕⴰⵎⵎⴰⵍ (Ḍammal) – Worker'},
          'ⵖ': {'pronunciation': 'GH',   'example': 'ⵖⴰⵣⴰⵍ (Ghazal) – Gazelle'},
          'ⵗ': {'pronunciation': 'TH',   'example': 'ⵗⴰⵣ (Thaz) – Hill'},
          'ⵘ': {'pronunciation': 'TCH',  'example': 'ⵘⴰⵎⴰⵍ (Tchamal) – Road'},
          'ⵙ': {'pronunciation': 'S',    'example': 'ⵙⴰⵎⴰⵍ (Samal) – Sun'},
          'ⵚ': {'pronunciation': 'Ṣ',    'example': 'ⵚⴰⵎⴰⵍ (Ṣamal) – Sand'},
          'ⵛ': {'pronunciation': 'CH',   'example': 'ⵛⴰⵎⴰⵍ (Chamal) – Road'},
          'ⵜ': {'pronunciation': 'T',    'example': 'ⵜⴰⵢⵢⴰⵔⴰ (Tayyara) – Airplane'},
          'ⵝ': {'pronunciation': 'Ṭ',    'example': 'ⵝⴰⵎⴰⵍ (Ṭamal) – Worker'},
          'ⵞ': {'pronunciation': 'TS',   'example': 'ⵞⴰⵎⴰⵍ (Tsamal) – Path'},
          'ⵟ': {'pronunciation': 'ḌH',   'example': 'ⵟⴰⵣ (Ḍhaz) – Sun'},
          'ⵠ': {'pronunciation': 'V',    'example': 'ⵠⴰⵎⴰⵍ (Vamal) – Worker'},
          'ⵡ': {'pronunciation': 'W',    'example': 'ⵡⴰⵡ (Waw) – Hand'},
          'ⵢ': {'pronunciation': 'Y',    'example': 'ⵢⴰⴷ (Yad) – Hand'},
          'ⵣ': {'pronunciation': 'Z',    'example': 'ⵣⴰⵢⵜⵓⵏ (Zaytun) – Olive'},
          'ⵤ': {'pronunciation': 'ZH',   'example': 'ⵤⴰⵎⴰⵍ (Zhamal) – Camel'},
          'ⵥ': {'pronunciation': 'DH',   'example': 'ⵥⴰⵎⴰⵍ (Dhamal) – Worker'},
        };
        break;

      case 'russian':
        _letters = ['А','Б','В','Г','Д','Е','Ё','Ж','З','И','Й','К','Л','М','Н','О','П','Р','С','Т','У','Ф','Х','Ц','Ч','Ш','Щ','Ъ','Ы','Ь','Э','Ю','Я'];
        _letterDetails = {
          'А': {'pronunciation': 'A',         'example': 'Арбуз (Arbuz) – Watermelon'},
          'Б': {'pronunciation': 'B',         'example': 'Бабочка (Babochka) – Butterfly'},
          'В': {'pronunciation': 'V',         'example': 'Волк (Volk) – Wolf'},
          'Г': {'pronunciation': 'G',         'example': 'Гриб (Grib) – Mushroom'},
          'Д': {'pronunciation': 'D',         'example': 'Дом (Dom) – House'},
          'Е': {'pronunciation': 'Ye',        'example': 'Ель (Yelʹ) – Fir Tree'},
          'Ё': {'pronunciation': 'Yo',        'example': 'Ёж (Yozh) – Hedgehog'},
          'Ж': {'pronunciation': 'Zh',        'example': 'Жираф (Zhiraf) – Giraffe'},
          'З': {'pronunciation': 'Z',         'example': 'Зонт (Zont) – Umbrella'},
          'И': {'pronunciation': 'I',         'example': 'Игра (Igra) – Game'},
          'Й': {'pronunciation': 'Y',         'example': 'Йогурт (Yogurt) – Yogurt'},
          'К': {'pronunciation': 'K',         'example': 'Кот (Kot) – Cat'},
          'Л': {'pronunciation': 'L',         'example': 'Лес (Les) – Forest'},
          'М': {'pronunciation': 'M',         'example': 'Машина (Mashina) – Car'},
          'Н': {'pronunciation': 'N',         'example': 'Нос (Nos) – Nose'},
          'О': {'pronunciation': 'O',         'example': 'Окно (Okno) – Window'},
          'П': {'pronunciation': 'P',         'example': 'Птица (Ptitsa) – Bird'},
          'Р': {'pronunciation': 'R',         'example': 'Рыба (Ryba) – Fish'},
          'С': {'pronunciation': 'S',         'example': 'Собака (Sobaka) – Dog'},
          'Т': {'pronunciation': 'T',         'example': 'Тигр (Tigr) – Tiger'},
          'У': {'pronunciation': 'U',         'example': 'Утка (Utka) – Duck'},
          'Ф': {'pronunciation': 'F',         'example': 'Флаг (Flag) – Flag'},
          'Х': {'pronunciation': 'Kh',        'example': 'Хлеб (Khleb) – Bread'},
          'Ц': {'pronunciation': 'Ts',        'example': 'Цветок (Tsvetok) – Flower'},
          'Ч': {'pronunciation': 'Ch',        'example': 'Чашка (Chashka) – Cup'},
          'Ш': {'pronunciation': 'Sh',        'example': 'Шар (Shar) – Ball'},
          'Щ': {'pronunciation': 'Shch',      'example': 'Щука (Shchuka) – Pike (fish)'},
          'Ъ': {'pronunciation': 'Hard sign', 'example': 'Твёрдый знак – Silent'},
          'Ы': {'pronunciation': 'Y',         'example': 'Сыры (Syry) – Cheeses'},
          'Ь': {'pronunciation': 'Soft sign', 'example': 'Мягкий знак – Silent'},
          'Э': {'pronunciation': 'E',         'example': 'Это (Eto) – This'},
          'Ю': {'pronunciation': 'Yu',        'example': 'Юла (Yula) – Spinning Top'},
          'Я': {'pronunciation': 'Ya',        'example': 'Яблоко (Yabloko) – Apple'},
        };
        break;

      case 'greek':
        _letters = ['Α','Β','Γ','Δ','Ε','Ζ','Η','Θ','Ι','Κ','Λ','Μ','Ν','Ξ','Ο','Π','Ρ','Σ','Τ','Υ','Φ','Χ','Ψ','Ω'];
        _letterDetails = {
          'Α': {'pronunciation': 'A',  'example': 'Αθήνα (Athína) – Athens'},
          'Β': {'pronunciation': 'V',  'example': 'Βιβλίο (Vivlío) – Book'},
          'Γ': {'pronunciation': 'G',  'example': 'Γάτα (Gáta) – Cat'},
          'Δ': {'pronunciation': 'D',  'example': 'Δέντρο (Déntro) – Tree'},
          'Ε': {'pronunciation': 'E',  'example': 'Ελέφαντας – Elephant'},
          'Ζ': {'pronunciation': 'Z',  'example': 'Ζάρι (Zári) – Dice'},
          'Η': {'pronunciation': 'I',  'example': 'Ημέρα (Iméra) – Day'},
          'Θ': {'pronunciation': 'Th', 'example': 'Θάλασσα (Thálassa) – Sea'},
          'Ι': {'pronunciation': 'I',  'example': 'Ιπποπόταμος – Hippopotamus'},
          'Κ': {'pronunciation': 'K',  'example': 'Καράβι (Karávi) – Ship'},
          'Λ': {'pronunciation': 'L',  'example': 'Λεμόνι (Lemóni) – Lemon'},
          'Μ': {'pronunciation': 'M',  'example': 'Μήλο (Mílo) – Apple'},
          'Ν': {'pronunciation': 'N',  'example': 'Νερό (Neró) – Water'},
          'Ξ': {'pronunciation': 'X',  'example': 'Ξενοδοχείο – Hotel'},
          'Ο': {'pronunciation': 'O',  'example': 'Όνομα (Ónoma) – Name'},
          'Π': {'pronunciation': 'P',  'example': 'Ποδήλατο – Bicycle'},
          'Ρ': {'pronunciation': 'R',  'example': 'Ρολόι (Rolói) – Clock'},
          'Σ': {'pronunciation': 'S',  'example': 'Σπίτι (Spíti) – House'},
          'Τ': {'pronunciation': 'T',  'example': 'Τραπέζι (Trapézi) – Table'},
          'Υ': {'pronunciation': 'Y',  'example': 'Υπόστεγο – Shelter'},
          'Φ': {'pronunciation': 'F',  'example': 'Φως (Fos) – Light'},
          'Χ': {'pronunciation': 'Ch', 'example': 'Χέρι (Chéri) – Hand'},
          'Ψ': {'pronunciation': 'Ps', 'example': 'Ψάρι (Psári) – Fish'},
          'Ω': {'pronunciation': 'O',  'example': 'Ωκεανός – Ocean'},
        };
        break;

      case 'chinese':
        _letters = ['人','口','大','小','日','月','山','水','火','木'];
        _letterDetails = {
          '人': {'pronunciation': 'rén',   'example': '人 (rén) – Person'},
          '口': {'pronunciation': 'kǒu',   'example': '口 (kǒu) – Mouth'},
          '大': {'pronunciation': 'dà',    'example': '大人 (dàrén) – Adult'},
          '小': {'pronunciation': 'xiǎo',  'example': '小孩 (xiǎohái) – Child'},
          '日': {'pronunciation': 'rì',    'example': '日出 (rìchū) – Sunrise'},
          '月': {'pronunciation': 'yuè',   'example': '月亮 (yuèliang) – Moon'},
          '山': {'pronunciation': 'shān',  'example': '高山 (gāoshān) – Mountain'},
          '水': {'pronunciation': 'shuǐ',  'example': '喝水 (hē shuǐ) – Drink water'},
          '火': {'pronunciation': 'huǒ',   'example': '火车 (huǒchē) – Train'},
          '木': {'pronunciation': 'mù',    'example': '木头 (mùtou) – Wood'},
        };
        break;

      case 'japanese':
        _letters = ['あ','い','う','え','お','か','き','く','け','こ','さ','し','す','せ','そ','た','ち','つ','て','と'];
        _letterDetails = {
          'あ': {'pronunciation': 'a',   'example': 'あめ (ame) – Rain / Candy'},
          'い': {'pronunciation': 'i',   'example': 'いぬ (inu) – Dog'},
          'う': {'pronunciation': 'u',   'example': 'うみ (umi) – Sea'},
          'え': {'pronunciation': 'e',   'example': 'えんぴつ (enpitsu) – Pencil'},
          'お': {'pronunciation': 'o',   'example': 'おちゃ (ocha) – Tea'},
          'か': {'pronunciation': 'ka',  'example': 'かさ (kasa) – Umbrella'},
          'き': {'pronunciation': 'ki',  'example': 'き (ki) – Tree'},
          'く': {'pronunciation': 'ku',  'example': 'くるま (kuruma) – Car'},
          'け': {'pronunciation': 'ke',  'example': 'けむし (kemushi) – Caterpillar'},
          'こ': {'pronunciation': 'ko',  'example': 'こども (kodomo) – Child'},
          'さ': {'pronunciation': 'sa',  'example': 'さかな (sakana) – Fish'},
          'し': {'pronunciation': 'shi', 'example': 'しろ (shiro) – White / Castle'},
          'す': {'pronunciation': 'su',  'example': 'すいか (suika) – Watermelon'},
          'せ': {'pronunciation': 'se',  'example': 'せみ (semi) – Cicada'},
          'そ': {'pronunciation': 'so',  'example': 'そら (sora) – Sky'},
          'た': {'pronunciation': 'ta',  'example': 'たまご (tamago) – Egg'},
          'ち': {'pronunciation': 'chi', 'example': 'ちず (chizu) – Map'},
          'つ': {'pronunciation': 'tsu', 'example': 'つき (tsuki) – Moon'},
          'て': {'pronunciation': 'te',  'example': 'てがみ (tegami) – Letter'},
          'と': {'pronunciation': 'to',  'example': 'とけい (tokei) – Clock'},
        };
        break;

      case 'korean':
        _letters = ['ㄱ','ㄴ','ㄷ','ㄹ','ㅁ','ㅂ','ㅅ','ㅇ','ㅈ','ㅊ','ㅋ','ㅌ','ㅍ','ㅎ','ㅏ','ㅑ','ㅓ','ㅕ','ㅗ','ㅛ','ㅜ','ㅠ','ㅡ','ㅣ'];
        _letterDetails = {
          'ㄱ': {'pronunciation': 'g/k',    'example': '가방 (gabang) – Bag'},
          'ㄴ': {'pronunciation': 'n',      'example': '나무 (namu) – Tree'},
          'ㄷ': {'pronunciation': 'd/t',    'example': '달 (dal) – Moon'},
          'ㄹ': {'pronunciation': 'r/l',    'example': '라면 (ramyeon) – Ramen'},
          'ㅁ': {'pronunciation': 'm',      'example': '물 (mul) – Water'},
          'ㅂ': {'pronunciation': 'b/p',    'example': '바다 (bada) – Sea'},
          'ㅅ': {'pronunciation': 's',      'example': '사과 (sagwa) – Apple'},
          'ㅇ': {'pronunciation': 'ng',     'example': '아이 (ai) – Child'},
          'ㅈ': {'pronunciation': 'j',      'example': '자전거 (jajeongeo) – Bicycle'},
          'ㅊ': {'pronunciation': 'ch',     'example': '치마 (chima) – Skirt'},
          'ㅋ': {'pronunciation': 'k',      'example': '코 (ko) – Nose'},
          'ㅌ': {'pronunciation': 't',      'example': '토끼 (tokki) – Rabbit'},
          'ㅍ': {'pronunciation': 'p',      'example': '피자 (pija) – Pizza'},
          'ㅎ': {'pronunciation': 'h',      'example': '하늘 (haneul) – Sky'},
          'ㅏ': {'pronunciation': 'a',      'example': '아버지 (abeoji) – Father'},
          'ㅑ': {'pronunciation': 'ya',     'example': '야구 (yagu) – Baseball'},
          'ㅓ': {'pronunciation': 'eo',     'example': '어머니 (eomeoni) – Mother'},
          'ㅕ': {'pronunciation': 'yeo',    'example': '여자 (yeoja) – Woman'},
          'ㅗ': {'pronunciation': 'o',      'example': '오리 (ori) – Duck'},
          'ㅛ': {'pronunciation': 'yo',     'example': '요리 (yori) – Cooking'},
          'ㅜ': {'pronunciation': 'u',      'example': '우유 (uyu) – Milk'},
          'ㅠ': {'pronunciation': 'yu',     'example': '유리 (yuri) – Glass'},
          'ㅡ': {'pronunciation': 'eu',     'example': '으르렁 (eureureong) – Growl'},
          'ㅣ': {'pronunciation': 'i',      'example': '이 (i) – Tooth'},
        };
        break;

      default: // French / English
        _letters = ['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'];
        _letterDetails = {
          'A': {'pronunciation': 'A', 'example': 'Apple 🍎'},
          'B': {'pronunciation': 'B', 'example': 'Banana 🍌'},
          'C': {'pronunciation': 'C', 'example': 'Cat 🐱'},
          'D': {'pronunciation': 'D', 'example': 'Dog 🐶'},
          'E': {'pronunciation': 'E', 'example': 'Elephant 🐘'},
          'F': {'pronunciation': 'F', 'example': 'Fish 🐟'},
          'G': {'pronunciation': 'G', 'example': 'Giraffe 🦒'},
          'H': {'pronunciation': 'H', 'example': 'Hat 🎩'},
          'I': {'pronunciation': 'I', 'example': 'Ice Cream 🍦'},
          'J': {'pronunciation': 'J', 'example': 'Juice 🧃'},
          'K': {'pronunciation': 'K', 'example': 'Kite 🪁'},
          'L': {'pronunciation': 'L', 'example': 'Lion 🦁'},
          'M': {'pronunciation': 'M', 'example': 'Monkey 🐒'},
          'N': {'pronunciation': 'N', 'example': 'Nest 🪺'},
          'O': {'pronunciation': 'O', 'example': 'Orange 🍊'},
          'P': {'pronunciation': 'P', 'example': 'Panda 🐼'},
          'Q': {'pronunciation': 'Q', 'example': 'Queen 👑'},
          'R': {'pronunciation': 'R', 'example': 'Rabbit 🐰'},
          'S': {'pronunciation': 'S', 'example': 'Sun ☀️'},
          'T': {'pronunciation': 'T', 'example': 'Tiger 🐯'},
          'U': {'pronunciation': 'U', 'example': 'Umbrella ☂️'},
          'V': {'pronunciation': 'V', 'example': 'Violin 🎻'},
          'W': {'pronunciation': 'W', 'example': 'Whale 🐋'},
          'X': {'pronunciation': 'X', 'example': 'Xylophone 🎵'},
          'Y': {'pronunciation': 'Y', 'example': 'Yak 🐂'},
          'Z': {'pronunciation': 'Z', 'example': 'Zebra 🦓'},
        };
    }
  }

  // ─────────────────────────────────────────────────────────────
  // ADS
  // ─────────────────────────────────────────────────────────────
  void _loadBannerAd() {
    _bannerAd?.dispose();
    _isBannerAdLoaded = false;
    _bannerAd = AdHelper.getBannerAd(() {
      setState(() => _isBannerAdLoaded = true);
    });
  }

  // ─────────────────────────────────────────────────────────────
  // TTS
  // ─────────────────────────────────────────────────────────────
  void _configureTtsLanguage() async {
    final code = switch (widget.language.toLowerCase()) {
      'arabic'   => 'ar-SA',
      'russian'  => 'ru-RU',
      'chinese'  => 'zh-CN',
      'japanese' => 'ja-JP',
      'korean'   => 'ko-KR',
      _          => 'en-US',
    };
    await flutterTts.setLanguage(code);
    await flutterTts.setSpeechRate(0.45);
    await flutterTts.setPitch(1.2); // slightly higher – friendlier for kids
  }

  void _speakCurrentLetter() async {
    final details = _letterDetails[_letters[_currentLetterIndex]];
    if (details != null) {
      await flutterTts.stop();
      await flutterTts.speak(details['pronunciation'] ?? '');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // BRUSH PICKER DIALOG
  // ─────────────────────────────────────────────────────────────
  void _showBrushPicker({bool firstTime = false}) {
    showDialog(
      context: context,
      barrierDismissible: !firstTime,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: const Color(0xFFFFF8F0),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (firstTime) ...[
                Lottie.asset('assets/animations/UI_Animations/WakiBot.json',
                    width: 100, height: 100, repeat: false),
                const SizedBox(height: 8),
                Text(
                  tr(context).howToPlay,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5C3317)),
                ),
                const SizedBox(height: 6),
                Text(
                  '${tr(context).traceEachLetterToEarnOneXp}.\n'
                      '${tr(context).collectTenXpToEarnOneTolimToken}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 18),
              ],
              const Text('🖌️ Pick your brush!',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5C3317))),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: List.generate(kBrushThemes.length, (i) {
                  final theme = kBrushThemes[i];
                  final selected = _selectedBrushIndex == i;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedBrushIndex = i);
                      Navigator.pop(context);
                      if (firstTime) _speakCurrentLetter();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          colors: theme.colors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: selected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: selected
                            ? [BoxShadow(color: theme.colors.first.withOpacity(0.6), blurRadius: 12)]
                            : [],
                      ),
                      child: Center(
                        child: Text(theme.emoji,
                            style: const TextStyle(fontSize: 28)),
                      ),
                    ),
                  );
                }),
              ),
              if (!firstTime) ...[
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(tr(context).cancel),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CANVAS ACTIONS
  // ─────────────────────────────────────────────────────────────
  void _clearCanvas() {
    Provider.of<AudioManager>(context, listen: false)
        .playEventSound('cancelButton');
    setState(() {
      _points = [];
      _strokeColorStep = 0;
      _showFill = false;
      _showGlow = false;
    });
    _fillController.reset();
  }

  void _nextLetter() {
    Provider.of<AudioManager>(context, listen: false)
        .playEventSound('clickButton');
    setState(() {
      _currentLetterIndex = (_currentLetterIndex + 1) % _letters.length;
      _points.clear();
      _strokeColorStep = 0;
      _showGlow = false;
      _showFill = false;
      _letterJustCompleted = false;
    });
    _fillController.reset();
    _speakCurrentLetter();
    _triggerMascot(MascotMood.idle);

    // Every 5 letters → quiz
    if (_currentLetterIndex != 0 && _currentLetterIndex % 5 == 0) {
      Future.delayed(const Duration(milliseconds: 300), _launchQuiz);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // REWARD
  // ─────────────────────────────────────────────────────────────
  void _giveTolimAndXP() async {
    final xpManager = Provider.of<ExperienceManager>(context, listen: false);
    final audioManager = Provider.of<AudioManager>(context, listen: false);

    xpManager.addXP(1, context: context);
    setState(() {
      score += 1;
      _streak += 1;
      _showFill = true;
      _letterJustCompleted = true;
    });

    // Fill animation
    _fillController.forward(from: 0);

    // Glow
    _showGlow = true;
    _glowController.forward();

    // Mascot
    _triggerMascot(_streak >= 3 ? MascotMood.cheer : MascotMood.happy);

    // Progress bar pulse
    _progressPulseController.forward(from: 0);

    // Trophy splash
    _trophyController.forward(from: 0);

    // Confetti overlay
    _showConfettiOverlay();

    audioManager.playSfx(
        "assets/audios/UI_Audio/SFX_Audio/MarimbaWin_SFX.mp3");
    audioManager.playSfx(
        "assets/audios/UI_Audio/SFX_Audio/victory2_SFX.mp3");

    await Future.delayed(const Duration(milliseconds: 2500));

    if (score >= 10) {
      xpManager.addTokenBanner(context, 1);
      audioManager.playSfx(
          "assets/audios/UI_Audio/SFX_Audio/victory1_SFX.mp3");
      setState(() => score = 0);
    }
  }

  double _calculateTotalDrawnDistance(List<Offset?> pts) {
    double dist = 0;
    for (int i = 0; i < pts.length - 1; i++) {
      final p1 = pts[i], p2 = pts[i + 1];
      if (p1 != null && p2 != null) dist += (p1 - p2).distance;
    }
    return dist;
  }

  // ─────────────────────────────────────────────────────────────
  // MASCOT
  // ─────────────────────────────────────────────────────────────
  void _triggerMascot(MascotMood mood) {
    setState(() => _mascotMood = mood);
    _mascotController.forward(from: 0);
  }

  String get _mascotLottie {
    return switch (_mascotMood) {
      MascotMood.cheer     => 'assets/animations/UI_Animations/WakiBot.json',
      MascotMood.happy     => 'assets/animations/UI_Animations/WakiBot.json',
      MascotMood.encourage => 'assets/animations/UI_Animations/WakiBot.json',
      MascotMood.idle      => 'assets/animations/UI_Animations/WakiBot.json',
    };
  }

  String get _mascotMessage {
    return switch (_mascotMood) {
      MascotMood.cheer     => '🔥 ${_streak} in a row! Amazing!',
      MascotMood.happy     => '⭐ Great job!',
      MascotMood.encourage => '💪 Keep going!',
      MascotMood.idle      => '',
    };
  }

  // ─────────────────────────────────────────────────────────────
  // CONFETTI OVERLAY
  // ─────────────────────────────────────────────────────────────
  void _showConfettiOverlay() {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: Center(
          child: Lottie.asset(
            "assets/animations/UI_Animations/Confetti1.json",
            width: 500,
            height: 500,
            repeat: false,
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), entry.remove);
  }

  // ─────────────────────────────────────────────────────────────
  // MINI-QUIZ  (every 5 letters)
  // ─────────────────────────────────────────────────────────────
  void _launchQuiz() {
    final rng = Random();
    final answerIdx = _currentLetterIndex > 0 ? _currentLetterIndex - 1 : 0;
    _quizAnswer = _letters[answerIdx];

    final pool = List<String>.from(_letters)..remove(_quizAnswer);
    pool.shuffle(rng);
    final wrongOptions = pool.take(2).toList();
    _quizOptions = [_quizAnswer, ...wrongOptions]..shuffle(rng);
    _quizCorrect = null;

    setState(() => _showQuiz = true);

    // Speak the answer letter so child hears which one to find
    flutterTts.speak(
        _letterDetails[_quizAnswer]?['pronunciation'] ?? _quizAnswer);
  }

  void _onQuizTap(String picked) async {
    final correct = picked == _quizAnswer;
    setState(() => _quizCorrect = correct);

    final audioManager =
    Provider.of<AudioManager>(context, listen: false);
    if (correct) {
      audioManager.playSfx(
          "assets/audios/UI_Audio/SFX_Audio/MarimbaWin_SFX.mp3");
      _triggerMascot(MascotMood.cheer);
      Provider.of<ExperienceManager>(context, listen: false)
          .addXP(2, context: context);
    } else {
      audioManager.playEventSound('invalid');
      _triggerMascot(MascotMood.encourage);
    }

    await Future.delayed(const Duration(milliseconds: 1400));
    setState(() => _showQuiz = false);
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final audioManager = Provider.of<AudioManager>(context);
    final xpManager = Provider.of<ExperienceManager>(context);
    final currentLetter = _letters[_currentLetterIndex];
    final details = _letterDetails[currentLetter];
    final pronunciation = details?['pronunciation'] ?? '';
    final example = details?['example'] ?? '';
    final brush = kBrushThemes[_selectedBrushIndex];
    final progress = (_currentLetterIndex + 1) / _letters.length;

    return Scaffold(
      body: Stack(
        children: [
          // ── Background gradient ──────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFF0D9),
                  Color(0xFFFFDDB5),
                  Color(0xFFFFBC78),
                ],
              ),
            ),
          ),

          // ── Decorative bubbles ───────────────────────────────
          ..._buildBubbles(),

          // ── Main content ─────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                const Userstatutbar(),

                // ── Top row ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      // Back button
                      _CircleBtn(
                        icon: Icons.arrow_back,
                        color: const Color(0xFFE05A00),
                        onTap: () {
                          audioManager.playEventSound('cancelButton');
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 8),

                      // Animated progress bar
                      Expanded(
                        child: ScaleTransition(
                          scale: _progressPulseAnim,
                          child: _ProgressBar(
                            progress: progress,
                            current: _currentLetterIndex + 1,
                            total: _letters.length,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Brush picker
                      GestureDetector(
                        onTap: () => _showBrushPicker(),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: brush.colors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: brush.colors.first.withOpacity(0.5),
                                blurRadius: 8,
                              )
                            ],
                          ),
                          child: Center(
                            child: Text(brush.emoji,
                                style: const TextStyle(fontSize: 22)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Streak banner ────────────────────────────────
                if (_streak >= 3)
                  _StreakBanner(streak: _streak),

                // ── Mascot ───────────────────────────────────────
                _buildMascot(),

                // ── Canvas ───────────────────────────────────────
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (_, child) => Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: _showGlow
                              ? brush.colors.first.withOpacity(0.7)
                              : Colors.orange.withOpacity(0.15),
                          blurRadius: _showGlow
                              ? _glowAnimation.value + 10
                              : 10,
                          spreadRadius: _showGlow
                              ? _glowAnimation.value / 2
                              : 2,
                        ),
                      ],
                    ),
                    child: child,
                  ),
                  child: Stack(
                    children: [
                      // Ghost letter
                      Center(
                        child: Text(
                          currentLetter,
                          style: TextStyle(
                            fontSize: 180,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade100.withOpacity(0.35),
                          ),
                        ),
                      ),

                      // Fill overlay (letter fills with brush color on completion)
                      if (_showFill)
                        AnimatedBuilder(
                          animation: _fillAnim,
                          builder: (_, __) => ClipRect(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              heightFactor: _fillAnim.value,
                              child: Center(
                                child: Text(
                                  currentLetter,
                                  style: TextStyle(
                                    fontSize: 180,
                                    fontWeight: FontWeight.bold,
                                    foreground: Paint()
                                      ..shader = LinearGradient(
                                        colors: brush.colors,
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                      ).createShader(
                                          const Rect.fromLTWH(0, 0, 300, 300)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Drawing surface
                      GestureDetector(
                        onPanStart: (_) => audioManager
                            .playSfx("assets/audios/writting.mp3"),
                        onPanUpdate: (d) {
                          final box = _paintKey.currentContext
                              ?.findRenderObject() as RenderBox?;
                          if (box == null) return;
                          setState(() {
                            _points = List.from(_points)
                              ..add(box.globalToLocal(
                                  d.globalPosition));
                            _strokeColorStep++;
                          });
                        },
                        onPanEnd: (_) {
                          setState(() =>
                          _points = List.from(_points)..add(null));
                          final dist =
                          _calculateTotalDrawnDistance(_points);
                          if (dist > 500 &&
                              !_rewardedLetterIndexes
                                  .contains(_currentLetterIndex)) {
                            _rewardedLetterIndexes
                                .add(_currentLetterIndex);
                            _giveTolimAndXP();
                          }
                        },
                        child: CustomPaint(
                          key: _paintKey,
                          painter: TracingPainter(
                            points: _points,
                            brushColors: brush.colors,
                            strokeWidth: brush.strokeWidth,
                            colorStep: _strokeColorStep,
                          ),
                          size: const Size(300, 300),
                        ),
                      ),

                      // Trophy pop-up
                      if (_letterJustCompleted)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: ScaleTransition(
                            scale: _trophyScale,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                      Colors.orange.withOpacity(0.4),
                                      blurRadius: 8)
                                ],
                              ),
                              child: const Text('⭐ Done!',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.brown)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Info card ────────────────────────────────────
                _InfoCard(
                  pronunciation: pronunciation,
                  example: example,
                  onSpeak: _speakCurrentLetter,
                ),

                const SizedBox(height: 10),

                // ── Action buttons ───────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ActionButton(
                        icon: Icons.refresh_rounded,
                        label: tr(context).retry,
                        color: const Color(0xFFE05A00),
                        onTap: _clearCanvas,
                      ),
                      _ActionButton(
                        icon: Icons.navigate_next_rounded,
                        label: tr(context).next,
                        color: const Color(0xFFFF9500),
                        onTap: _nextLetter,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // ── Score pill ───────────────────────────────────
                _ScorePill(score: score),

                const SizedBox(height: 8),
              ],
            ),
          ),

          // ── QUIZ OVERLAY ─────────────────────────────────────
          if (_showQuiz)
            _QuizOverlay(
              options: _quizOptions,
              answer: _quizAnswer,
              correct: _quizCorrect,
              onTap: _onQuizTap,
              brushColors: brush.colors,
            ),
        ],
      ),

      // ── Banner ad ────────────────────────────────────────────
      bottomNavigationBar:
      xpManager.adsEnabled && _bannerAd != null && _isBannerAdLoaded
          ? SafeArea(
        child: SizedBox(
          height: _bannerAd!.size.height.toDouble(),
          width: _bannerAd!.size.width.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
      )
          : null,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // MASCOT WIDGET
  // ─────────────────────────────────────────────────────────────
  Widget _buildMascot() {
    final msg = _mascotMessage;
    return AnimatedBuilder(
      animation: _mascotBounce,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _mascotBounce.value),
        child: child,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: Lottie.asset(_mascotLottie, repeat: _mascotMood != MascotMood.idle),
          ),
          if (msg.isNotEmpty)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey(msg),
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.orange.withOpacity(0.2),
                        blurRadius: 8)
                  ],
                ),
                child: Text(msg,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF5C3317))),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // DECORATIVE BACKGROUND BUBBLES
  // ─────────────────────────────────────────────────────────────
  List<Widget> _buildBubbles() {
    final spots = [
      const Offset(0.05, 0.08),
      const Offset(0.88, 0.12),
      const Offset(0.92, 0.55),
      const Offset(0.03, 0.72),
      const Offset(0.5, 0.95),
    ];
    final sizes = [60.0, 80.0, 50.0, 70.0, 55.0];
    final colors = [
      Colors.orangeAccent.withOpacity(0.15),
      Colors.pink.withOpacity(0.10),
      Colors.purple.withOpacity(0.10),
      Colors.teal.withOpacity(0.10),
      Colors.amber.withOpacity(0.12),
    ];
    return List.generate(spots.length, (i) {
      return Positioned(
        left: MediaQuery.of(context).size.width * spots[i].dx,
        top: MediaQuery.of(context).size.height * spots[i].dy,
        child: Container(
          width: sizes[i],
          height: sizes[i],
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors[i],
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────
// TRACING PAINTER  – multi-color cycling brush
// ─────────────────────────────────────────────────────────────
class TracingPainter extends CustomPainter {
  final List<Offset?> points;
  final List<Color> brushColors;
  final double strokeWidth;
  final int colorStep;

  TracingPainter({
    required this.points,
    required this.brushColors,
    required this.strokeWidth,
    required this.colorStep,
  });

  @override
  void paint(Canvas canvas, Size size) {
    int segmentIndex = 0;
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      if (p1 == null || p2 == null) {
        segmentIndex++;
        continue;
      }
      final color = brushColors[segmentIndex % brushColors.length];
      final paint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawLine(p1, p2, paint);
      segmentIndex++;
    }
  }

  @override
  bool shouldRepaint(TracingPainter old) =>
      old.points != points || old.colorStep != colorStep;
}

// ─────────────────────────────────────────────────────────────
// PROGRESS BAR
// ─────────────────────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final double progress;
  final int current;
  final int total;
  const _ProgressBar(
      {required this.progress, required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Letter $current / $total',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7B4000))),
            Text('${(progress * 100).toInt()}%',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7B4000))),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Container(height: 14, color: Colors.white.withOpacity(0.5)),
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                widthFactor: progress,
                child: Container(
                  height: 14,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFFFD700)],
                    ),
                  ),
                ),
              ),
              // Stars along the bar
              Positioned.fill(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(
                    5,
                        (i) => Text(
                      progress >= (i + 1) / 5 ? '⭐' : '·',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STREAK BANNER
// ─────────────────────────────────────────────────────────────
class _StreakBanner extends StatelessWidget {
  final int streak;
  const _StreakBanner({required this.streak});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Container(
        key: ValueKey(streak),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFFF9500)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
                color: Colors.orange.withOpacity(0.4), blurRadius: 8)
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              '$streak Letter Streak! Keep it up!',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// INFO CARD  – pronunciation + example + speaker button
// ─────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final String pronunciation;
  final String example;
  final VoidCallback onSpeak;
  const _InfoCard(
      {required this.pronunciation,
        required this.example,
        required this.onSpeak});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.orange.withOpacity(0.12), blurRadius: 10)
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🔤 ', style: TextStyle(fontSize: 16)),
                    Text(
                      pronunciation,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5C3317)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('📘 ', style: TextStyle(fontSize: 14)),
                    Expanded(
                      child: Text(
                        example,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Speaker button
          GestureDetector(
            onTap: onSpeak,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9500), Color(0xFFFFD700)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.orange.withOpacity(0.4),
                      blurRadius: 8)
                ],
              ),
              child: const Icon(Icons.volume_up_rounded,
                  color: Colors.white, size: 26),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ACTION BUTTON
// ─────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon,
        required this.label,
        required this.color,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SCORE PILL
// ─────────────────────────────────────────────────────────────
class _ScorePill extends StatelessWidget {
  final int score;
  const _ScorePill({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
              color: Colors.orange.withOpacity(0.15), blurRadius: 12)
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎯 Score: ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('$score / 10',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE05A00))),
          const SizedBox(width: 6),
          ...List.generate(
            10,
                (i) => Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(i < score ? '⭐' : '·',
                  style: const TextStyle(fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CIRCLE BUTTON helper
// ─────────────────────────────────────────────────────────────
class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _CircleBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.4), blurRadius: 8)
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// QUIZ OVERLAY
// ─────────────────────────────────────────────────────────────
class _QuizOverlay extends StatelessWidget {
  final List<String> options;
  final String answer;
  final bool? correct;
  final void Function(String) onTap;
  final List<Color> brushColors;

  const _QuizOverlay({
    required this.options,
    required this.answer,
    required this.correct,
    required this.onTap,
    required this.brushColors,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.65),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8F0),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                    color: Colors.orange.withOpacity(0.3), blurRadius: 20)
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎮 Quick Quiz!',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5C3317))),
                const SizedBox(height: 8),
                const Text(
                  'Tap the letter you just heard! 👂',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: options.map((opt) {
                    Color bg = const Color(0xFFFFE0B2);
                    if (correct != null) {
                      if (opt == answer)
                        bg = Colors.green.shade300;
                      else if (correct == false)
                        bg = Colors.red.shade200;
                    }
                    return GestureDetector(
                      onTap: correct == null ? () => onTap(opt) : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.orange.withOpacity(0.2),
                                blurRadius: 8)
                          ],
                        ),
                        child: Center(
                          child: Text(opt,
                              style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF5C3317))),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (correct != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    correct! ? '🎉 Correct! +2 XP' : '😅 The answer was $answer',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                        correct! ? Colors.green.shade700 : Colors.red.shade700),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
