import 'dart:async';
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

class AlphabetTracingPage extends StatefulWidget {
  final String language;

  const AlphabetTracingPage({super.key, required this.language});

  @override
  State<AlphabetTracingPage> createState() => _AlphabetTracingPageState();
}

class _AlphabetTracingPageState extends State<AlphabetTracingPage> with SingleTickerProviderStateMixin {
  BannerAd? _bannerAd;
  late List<String> _letters;
  late Map<String, Map<String, String>> _letterDetails;
  int _currentLetterIndex = 0;
  final GlobalKey _paintKey = GlobalKey();
  List<Offset?> _points = [];
  Set<int> _rewardedLetterIndexes = {};

  int score = 0;
  bool _isBannerAdLoaded = false;

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  bool _showGlow = false;

  late FlutterTts flutterTts;

  @override
  void initState() {
    super.initState();
    _setupLetters();
    _loadBannerAd();

    flutterTts = FlutterTts();
    _configureTtsLanguage();

    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _glowAnimation = Tween<double>(begin: 0.0, end: 12.0).animate(
        CurvedAnimation(parent: _glowController, curve: Curves.easeInOut)
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) _glowController.reverse();
      else if (status == AnimationStatus.dismissed) _glowController.forward();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => InfoDialog(
          title: 'How to Play',
          message:
          'Trace each letter to earn 1 XP.\nCollect 10 XP to earn 1 Tolim token.',
          lottieAssetPath: 'assets/animations/UI_Animations/WakiBot.json',
          buttonText: 'Start',
        ),
      );
    });
  }

  void _setupLetters() {
    switch (widget.language) {
      case 'arabic':
        _letters = ["ا", "ب", "ت", "ث", "ج", "ح", "خ", "د", "ذ", "ر", "ز", "س", "ش", "ص", "ض", "ط", "ظ", "ع", "غ", "ف", "ق", "ك", "ل", "م", "ن", "ه", "و", "ي"];
        _letterDetails = {
            'ا': {'pronunciation': 'Alif', 'example': 'أسد (Asad) – Lion'},
            'ب': {'pronunciation': 'Ba', 'example': 'بيت (Bayt) – House'},
            'ت': {'pronunciation': 'Ta', 'example': 'تفاح (Tuffāḥ) – Apple'},
            'ث': {'pronunciation': 'Tha', 'example': 'ثعلب (Tha‘lab) – Fox'},
            'ج': {'pronunciation': 'Jim', 'example': 'جمل (Jamal) – Camel'},
            'ح': {'pronunciation': 'Ha', 'example': 'حصان (Ḥiṣān) – Horse'},
            'خ': {'pronunciation': 'Kha', 'example': 'خبز (Khubz) – Bread'},
            'د': {'pronunciation': 'Dal', 'example': 'دجاجة (Dajājah) – Chicken'},
            'ذ': {'pronunciation': 'Dhal', 'example': 'ذهب (Dhahab) – Gold'},
            'ر': {'pronunciation': 'Ra', 'example': 'رمان (Rummān) – Pomegranate'},
            'ز': {'pronunciation': 'Zay', 'example': 'زيتون (Zaytūn) – Olive'},
            'س': {'pronunciation': 'Sin', 'example': 'سمك (Samak) – Fish'},
            'ش': {'pronunciation': 'Shin', 'example': 'شمس (Shams) – Sun'},
            'ص': {'pronunciation': 'Sad', 'example': 'صقر (Ṣaqr) – Falcon'},
            'ض': {'pronunciation': 'Dad', 'example': 'ضوء (Ḍawʼ) – Light'},
            'ط': {'pronunciation': 'Taʼ', 'example': 'طائرة (Ṭāʼirah) – Airplane'},
            'ظ': {'pronunciation': 'Zaʼ', 'example': 'ظرف (Ẓarf) – Envelope'},
            'ع': {'pronunciation': 'Ayn', 'example': 'عنب (ʿInab) – Grapes'},
            'غ': {'pronunciation': 'Ghayn', 'example': 'غزال (Ghazāl) – Gazelle'},
            'ف': {'pronunciation': 'Fa', 'example': 'فيل (Fīl) – Elephant'},
            'ق': {'pronunciation': 'Qaf', 'example': 'قلم (Qalam) – Pen'},
            'ك': {'pronunciation': 'Kaf', 'example': 'كتاب (Kitāb) – Book'},
            'ل': {'pronunciation': 'Lam', 'example': 'ليمون (Laymūn) – Lemon'},
            'م': {'pronunciation': 'Mim', 'example': 'مدينة (Madīnah) – City'},
            'ن': {'pronunciation': 'Nun', 'example': 'نمر (Namir) – Tiger'},
            'هـ': {'pronunciation': 'Haʼ', 'example': 'هاتف (Hātif) – Phone'},
            'و': {'pronunciation': 'Waw', 'example': 'وردة (Wardah) – Rose'},
            'ي': {'pronunciation': 'Ya', 'example': 'يد (Yad) – Hand'}
        };
        break;

      case 'amazigh':
        _letters = [
          "ⴰ", "ⴱ", "ⴲ", "ⴳ", "ⴴ", "ⴵ", "ⴶ", "ⴷ", "ⴸ", "ⴹ",
          "ⴺ", "ⴻ", "ⴼ", "ⴽ", "ⴾ", "ⴿ", "ⵀ", "ⵁ", "ⵂ", "ⵃ",
          "ⵄ", "ⵅ", "ⵆ", "ⵇ", "ⵈ", "ⵉ", "ⵊ", "ⵋ", "ⵌ", "ⵍ",
          "ⵎ", "ⵏ", "ⵐ", "ⵑ", "ⵒ", "ⵓ", "ⵔ", "ⵕ", "ⵖ", "ⵗ",
          "ⵘ", "ⵙ", "ⵚ", "ⵛ", "ⵜ", "ⵝ", "ⵞ", "ⵟ", "ⵠ", "ⵡ",
          "ⵢ", "ⵣ", "ⵤ", "ⵥ"
        ];

        _letterDetails = {
          'ⴰ': {'pronunciation': 'A', 'example': 'ⴰⵙⴷ (Asd) – Lion'},
          'ⴱ': {'pronunciation': 'B', 'example': 'ⴱⵉⵜ (Bit) – House'},
          'ⴲ': {'pronunciation': 'P', 'example': 'ⴲⵓⵙ (Pus) – Water'},
          'ⴳ': {'pronunciation': 'G', 'example': 'ⴳⴰⵎⴰⵍ (Gamal) – Camel'},
          'ⴴ': {'pronunciation': 'Ḡ', 'example': 'ⴴⴰⵣⴰⵍ (Ḡazal) – Gazelle'},
          'ⴵ': {'pronunciation': 'J', 'example': 'ⴵⴰⵎⴰⵍ (Jamal) – Camel'},
          'ⴶ': {'pronunciation': 'V', 'example': 'ⴶⴰⵣ (Vaz) – Flower'},
          'ⴷ': {'pronunciation': 'D', 'example': 'ⴷⴰⵊⴰ (Daja) – Chicken'},
          'ⴸ': {'pronunciation': 'Ḍ', 'example': 'ⴸⴰⵡ (Ḍaw) – Light'},
          'ⴹ': {'pronunciation': 'Ḍh', 'example': 'ⴹⴰⵣⴰⵍ (Ḍhazal) – Sun'},
          'ⴺ': {'pronunciation': 'DJ', 'example': 'ⴺⴰⴹⵉ (DJadi) – Eagle'},
          'ⴻ': {'pronunciation': 'E', 'example': 'ⴻⵍⵍⴰⵎ (Ellam) – Water'},
          'ⴼ': {'pronunciation': 'F', 'example': 'ⴼⵉⵍ (Fil) – Elephant'},
          'ⴽ': {'pronunciation': 'K', 'example': 'ⴽⵉⵜⴰⴱ (Kitab) – Book'},
          'ⴾ': {'pronunciation': 'KH', 'example': 'ⴾⴰⵣ (Khaz) – Tree'},
          'ⴿ': {'pronunciation': 'KHʼ', 'example': 'ⴿⴰⵡ (Khʼaw) – Mountain'},
          'ⵀ': {'pronunciation': 'H', 'example': 'ⵀⴰⵡⴰ (Hawa) – Wind'},
          'ⵁ': {'pronunciation': 'HH', 'example': 'ⵁⴰⵣⴰ (Hhaza) – Sun'},
          'ⵂ': {'pronunciation': 'Ɣ', 'example': 'ⵂⴰⵣⴰⵍ (Ɣazal) – Gazelle'},
          'ⵃ': {'pronunciation': 'Ḥ', 'example': 'ⵃⴰⵎⵎⴰⵍ (Ḥammal) – Worker'},
          'ⵄ': {'pronunciation': 'ʿ', 'example': 'ⵄⴰⵎⴰⵍ (ʿAmal) – Hope'},
          'ⵅ': {'pronunciation': 'KH', 'example': 'ⵅⴰⵣⴰⵍ (Khazal) – Plant'},
          'ⵆ': {'pronunciation': 'GH', 'example': 'ⵆⴰⵎⴰⵍ (Ghamal) – Camel'},
          'ⵇ': {'pronunciation': 'Q', 'example': 'ⵇⴰⵎ (Qam) – Leader'},
          'ⵈ': {'pronunciation': 'KHʼ', 'example': 'ⵈⴰⵣ (Khʼaz) – Hill'},
          'ⵉ': {'pronunciation': 'I', 'example': 'ⵉⵣⵓⵍ (Izul) – Moon'},
          'ⵊ': {'pronunciation': 'J', 'example': 'ⵊⴰⵎⴰⵍ (Jamal) – Camel'},
          'ⵋ': {'pronunciation': 'CH', 'example': 'ⵋⴰⵎⴰⵍ (Chamal) – Road'},
          'ⵌ': {'pronunciation': 'CHʼ', 'example': 'ⵌⴰⵣ (Chʼaz) – Tree'},
          'ⵍ': {'pronunciation': 'L', 'example': 'ⵍⴰⵢⵎⵓⵏ (Laymun) – Lemon'},
          'ⵎ': {'pronunciation': 'M', 'example': 'ⵎⴰⴷⵉⵏⴰ (Madina) – City'},
          'ⵏ': {'pronunciation': 'N', 'example': 'ⵏⴰⵎⵉⵔ (Namir) – Tiger'},
          'ⵐ': {'pronunciation': 'NY', 'example': 'ⵐⴰⵣⴰⵍ (Nyazal) – Flower'},
          'ⵑ': {'pronunciation': 'NG', 'example': 'ⵑⴰⵎⴰⵍ (Ngamal) – Camel'},
          'ⵒ': {'pronunciation': 'QH', 'example': 'ⵒⴰⵣⴰⵍ (Qhazal) – Gazelle'},
          'ⵓ': {'pronunciation': 'U', 'example': 'ⵓⵔⴷⴰ (Urda) – Rose'},
          'ⵔ': {'pronunciation': 'R', 'example': 'ⵔⵓⵎⵎⴰⵏ (Rumman) – Pomegranate'},
          'ⵕ': {'pronunciation': 'Ḍ', 'example': 'ⵕⴰⵎⵎⴰⵍ (Ḍammal) – Worker'},
          'ⵖ': {'pronunciation': 'GH', 'example': 'ⵖⴰⵣⴰⵍ (Ghazal) – Gazelle'},
          'ⵗ': {'pronunciation': 'TH', 'example': 'ⵗⴰⵣ (Thaz) – Hill'},
          'ⵘ': {'pronunciation': 'TCH', 'example': 'ⵘⴰⵎⴰⵍ (Tchamal) – Road'},
          'ⵙ': {'pronunciation': 'S', 'example': 'ⵙⴰⵎⴰⵍ (Samal) – Sun'},
          'ⵚ': {'pronunciation': 'Ṣ', 'example': 'ⵚⴰⵎⴰⵍ (Ṣamal) – Sand'},
          'ⵛ': {'pronunciation': 'CH', 'example': 'ⵛⴰⵎⴰⵍ (Chamal) – Road'},
          'ⵜ': {'pronunciation': 'T', 'example': 'ⵜⴰⵢⵢⴰⵔⴰ (Tayyara) – Airplane'},
          'ⵝ': {'pronunciation': 'Ṭ', 'example': 'ⵝⴰⵎⴰⵍ (Ṭamal) – Worker'},
          'ⵞ': {'pronunciation': 'TS', 'example': 'ⵞⴰⵎⴰⵍ (Tsamal) – Path'},
          'ⵟ': {'pronunciation': 'ḌH', 'example': 'ⵟⴰⵣ (Ḍhaz) – Sun'},
          'ⵠ': {'pronunciation': 'V', 'example': 'ⵠⴰⵎⴰⵍ (Vamal) – Worker'},
          'ⵡ': {'pronunciation': 'W', 'example': 'ⵡⴰⵡ (Waw) – Hand'},
          'ⵢ': {'pronunciation': 'Y', 'example': 'ⵢⴰⴷ (Yad) – Hand'},
          'ⵣ': {'pronunciation': 'Z', 'example': 'ⵣⴰⵢⵜⵓⵏ (Zaytun) – Olive'},
          'ⵤ': {'pronunciation': 'ZH', 'example': 'ⵤⴰⵎⴰⵍ (Zhamal) – Camel'},
          'ⵥ': {'pronunciation': 'DH', 'example': 'ⵥⴰⵎⴰⵍ (Dhamal) – Worker'},
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

      case 'greek':
        _letters = [
          'Α', 'Β', 'Γ', 'Δ', 'Ε', 'Ζ', 'Η', 'Θ', 'Ι', 'Κ', 'Λ', 'Μ',
          'Ν', 'Ξ', 'Ο', 'Π', 'Ρ', 'Σ', 'Τ', 'Υ', 'Φ', 'Χ', 'Ψ', 'Ω'
        ];
        _letterDetails = {
          'Α': {'pronunciation': 'A', 'example': 'Αθήνα (Athína) – Athens'},
          'Β': {'pronunciation': 'V', 'example': 'Βιβλίο (Vivlío) – Book'},
          'Γ': {'pronunciation': 'G', 'example': 'Γάτα (Gáta) – Cat'},
          'Δ': {'pronunciation': 'D', 'example': 'Δέντρο (Déntro) – Tree'},
          'Ε': {'pronunciation': 'E', 'example': 'Ελέφαντας (Eléfántas) – Elephant'},
          'Ζ': {'pronunciation': 'Z', 'example': 'Ζάρι (Zári) – Dice'},
          'Η': {'pronunciation': 'I', 'example': 'Ημέρα (Iméra) – Day'},
          'Θ': {'pronunciation': 'Th', 'example': 'Θάλασσα (Thálassa) – Sea'},
          'Ι': {'pronunciation': 'I', 'example': 'Ιπποπόταμος (Ippopótamos) – Hippopotamus'},
          'Κ': {'pronunciation': 'K', 'example': 'Καράβι (Karávi) – Ship'},
          'Λ': {'pronunciation': 'L', 'example': 'Λεμόνι (Lemóni) – Lemon'},
          'Μ': {'pronunciation': 'M', 'example': 'Μήλο (Mílo) – Apple'},
          'Ν': {'pronunciation': 'N', 'example': 'Νερό (Neró) – Water'},
          'Ξ': {'pronunciation': 'X', 'example': 'Ξενοδοχείο (Xenodocheío) – Hotel'},
          'Ο': {'pronunciation': 'O', 'example': 'Όνομα (Ónoma) – Name'},
          'Π': {'pronunciation': 'P', 'example': 'Ποδήλατο (Podílato) – Bicycle'},
          'Ρ': {'pronunciation': 'R', 'example': 'Ρολόι (Rolói) – Clock'},
          'Σ': {'pronunciation': 'S', 'example': 'Σπίτι (Spíti) – House'},
          'Τ': {'pronunciation': 'T', 'example': 'Τραπέζι (Trapézi) – Table'},
          'Υ': {'pronunciation': 'Y', 'example': 'Υπόστεγο (Ypóstego) – Shelter'},
          'Φ': {'pronunciation': 'F', 'example': 'Φως (Fos) – Light'},
          'Χ': {'pronunciation': 'Ch', 'example': 'Χέρι (Chéri) – Hand'},
          'Ψ': {'pronunciation': 'Ps', 'example': 'Ψάρι (Psári) – Fish'},
          'Ω': {'pronunciation': 'O', 'example': 'Ωκεανός (Okeanós) – Ocean'},
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

          'ㅏ': {'pronunciation': 'a', 'example': '아버지 (abeoji) – Father'},
          'ㅑ': {'pronunciation': 'ya', 'example': '야구 (yagu) – Baseball'},
          'ㅓ': {'pronunciation': 'eo', 'example': '어머니 (eomeoni) – Mother'},
          'ㅕ': {'pronunciation': 'yeo', 'example': '여자 (yeoja) – Woman'},
          'ㅗ': {'pronunciation': 'o', 'example': '오리 (ori) – Duck'},

          'ㅛ': {'pronunciation': 'yo', 'example': '요리 (yori) – Cooking'},
          'ㅜ': {'pronunciation': 'u', 'example': '우유 (uyu) – Milk'},
          'ㅠ': {'pronunciation': 'yu', 'example': '유리 (yuri) – Glass'},
          'ㅡ': {'pronunciation': 'eu', 'example': '으르렁 (eureureong) – Growl'},
          'ㅣ': {'pronunciation': 'i', 'example': '이 (i) – Tooth'},
        };
        break;

      default:
        _letters = [
          'A', 'B', 'C', 'D', 'E', 'F', 'G',
          'H', 'I', 'J', 'K', 'L', 'M', 'N',
          'O', 'P', 'Q', 'R', 'S', 'T', 'U',
          'V', 'W', 'X', 'Y', 'Z'
        ];

        _letterDetails = {
          'A': {'pronunciation': 'A', 'example': 'Apple'},
          'B': {'pronunciation': 'B', 'example': 'Banana'},
          'C': {'pronunciation': 'C', 'example': 'Cat'},
          'D': {'pronunciation': 'D', 'example': 'Dog'},
          'E': {'pronunciation': 'E', 'example': 'Elephant'},
          'F': {'pronunciation': 'F', 'example': 'Fish'},
          'G': {'pronunciation': 'G', 'example': 'Giraffe'},
          'H': {'pronunciation': 'H', 'example': 'Hat'},
          'I': {'pronunciation': 'I', 'example': 'Ice'},
          'J': {'pronunciation': 'J', 'example': 'Juice'},
          'K': {'pronunciation': 'K', 'example': 'Kite'},
          'L': {'pronunciation': 'L', 'example': 'Lion'},
          'M': {'pronunciation': 'M', 'example': 'Monkey'},
          'N': {'pronunciation': 'N', 'example': 'Nest'},
          'O': {'pronunciation': 'O', 'example': 'Orange'},
          'P': {'pronunciation': 'P', 'example': 'Panda'},
          'Q': {'pronunciation': 'Q', 'example': 'Queen'},
          'R': {'pronunciation': 'R', 'example': 'Rabbit'},
          'S': {'pronunciation': 'S', 'example': 'Sun'},
          'T': {'pronunciation': 'T', 'example': 'Tiger'},
          'U': {'pronunciation': 'U', 'example': 'Umbrella'},
          'V': {'pronunciation': 'V', 'example': 'Violin'},
          'W': {'pronunciation': 'W', 'example': 'Whale'},
          'X': {'pronunciation': 'X', 'example': 'Xylophone'},
          'Y': {'pronunciation': 'Y', 'example': 'Yak'},
          'Z': {'pronunciation': 'Z', 'example': 'Zebra'},
        };

    }
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

  @override
  void dispose() {
    _bannerAd?.dispose();
    _glowController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  void _configureTtsLanguage() async {
    String languageCode;

    switch (widget.language.toLowerCase()) {
      case 'arabic':
        languageCode = 'ar-SA'; // Arabic (Saudi Arabia)
        break;
      case 'russian':
        languageCode = 'ru-RU'; // Russian
        break;
      case 'chinese':
        languageCode = 'zh-CN'; // Chinese Mandarin
        break;
      case 'japanese':
        languageCode = 'ja-JP'; // Japanese
        break;
      case 'korean':
        languageCode = 'ko-KR'; // Korean
        break;
      default:
        languageCode = 'en-US'; // English fallback
    }

    await flutterTts.setLanguage(languageCode);
  }

  void _speakCurrentLetter() async {
    final details = _letterDetails[_letters[_currentLetterIndex]];
    if (details != null) {
      final pronunciation = details['pronunciation'] ?? '';
      await flutterTts.stop();
      await flutterTts.speak(pronunciation);
    }
  }


  void _clearCanvas() {
    Provider.of<AudioManager>(context, listen: false).playEventSound('cancelButton');
    setState(() {
      _points = [];
    });
  }

  void _nextLetter() {
    Provider.of<AudioManager>(context, listen: false).playEventSound('clickButton');
    setState(() {
      _currentLetterIndex = (_currentLetterIndex + 1) % _letters.length;
      _points.clear();
      _showGlow = false;
    });
    _speakCurrentLetter();

  }

  void _showConfetti() {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final entry = OverlayEntry(
      builder: (context) => Center(
        child: Lottie.asset(
          "assets/animations/UI_Animations/Confetti1.json",
          width: 500,
          height: 500,
          repeat: false,
        ),
      ),
    );

    overlay.insert(entry);

    // Remove after animation completes (3s for example)
    Future.delayed(const Duration(seconds: 3), () {
      entry.remove();
    });
  }

  void _showConfettiTolim() {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final entry = OverlayEntry(
      builder: (context) => Center(
        child: Lottie.asset(
          "assets/animations/UI_Animations/Confetti2.json",
          width: 500,
          height: 500,
          repeat: false,
        ),
      ),
    );

    overlay.insert(entry);

    // Remove after animation completes (3s for example)
    Future.delayed(const Duration(seconds: 3), () {
      entry.remove();
    });
  }

  void _giveTolimAndXP() {
    final xpManager = Provider.of<ExperienceManager>(context, listen: false);
    xpManager.addXP(1, context: context);
    setState(() {
      score += 1;
    });
    _showConfetti();
    _showConfettiTolim();
    _showGlow = true;
    _glowController.forward();

    Provider.of<AudioManager>(context, listen: false).playSfx("assets/audios/UI_Audio/SFX_Audio/MarimbaWin_SFX.mp3");
    Provider.of<AudioManager>(context, listen: false).playSfx("assets/audios/UI_Audio/SFX_Audio/victory2_SFX.mp3");

    Future.delayed(const Duration(milliseconds: 2500) ,()
    {

      if (score >= 10) {
        xpManager.addTokenBanner(context, 1);
        Provider.of<AudioManager>(context, listen: false).playSfx("assets/audios/UI_Audio/SFX_Audio/victory1_SFX.mp3");
        _showConfettiTolim;
        setState(() {
          score = 0;
        });
      }
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
  Widget build(BuildContext context) {
    final audioManager = Provider.of<AudioManager>(context);
    final currentLetter = _letters[_currentLetterIndex];
    final details = _letterDetails[currentLetter];
    final pronunciation = details?['pronunciation'] ?? '';
    final example = details?['example'] ?? '';

    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            colors: [
              Color(0xFFFFE0B2),
              Color(0xFFFFCCBC),
              Color(0xFFFFAB91),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: NeverScrollableScrollPhysics(),
            child: Column(
              children: [
                const Userstatutbar(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(12),
                          backgroundColor: Colors.deepOrange,
                        ),
                        onPressed: () {
                          audioManager.playEventSound('cancelButton');
                          Navigator.of(context).pop();
                        },
                        child: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      Text(
                        '${tr(context).letter} ${_currentLetterIndex + 1}/${_letters.length}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),
                      const SizedBox(width: 48), // For alignment
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    return Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.7),
                            blurRadius: _showGlow ? _glowAnimation.value : 0,
                            spreadRadius: _showGlow ? _glowAnimation.value / 2 : 0,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          currentLetter,
                          style: TextStyle(
                            fontSize: 200,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade100.withOpacity(0.3),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onPanStart: (_) {
                          audioManager.playSfx("assets/audios/writting.mp3");
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
                          setState(() {
                            _points = List.from(_points)..add(null);
                          });

                          final drawnDistance = _calculateTotalDrawnDistance(_points);

                          if (drawnDistance > 500 && !_rewardedLetterIndexes.contains(_currentLetterIndex)) {
                            _rewardedLetterIndexes.add(_currentLetterIndex);
                            _giveTolimAndXP();
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

                const SizedBox(height: 10),
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
                          "🔤 ${tr(context).pronunciation}: $pronunciation",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "📘 ${tr(context).example}: $example",
                          style: const TextStyle(fontSize: 17),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _clearCanvas,
                        icon: const Icon(Icons.refresh),
                        label: Text(tr(context).retry),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange.shade300,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 6,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _nextLetter,
                        icon: const Icon(Icons.navigate_next),
                        label: Text(tr(context).next),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent.shade200,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 6,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [BoxShadow(color: Colors.orange.shade100, blurRadius: 12)],
                  ),
                  child: Text(
                    "🎯 ${tr(context).score}: $score",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: context.watch<ExperienceManager>().adsEnabled && _bannerAd != null && _isBannerAdLoaded
          ? SafeArea(
        child: Container(
          height: _bannerAd!.size.height.toDouble(),
          width: _bannerAd!.size.width.toDouble(),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              colors: [
                Color(0xFFFFE0B2),
                Color(0xFFFFCCBC),
                Color(0xFFFFAB91),
              ],
            ),
          ),
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
  bool shouldRepaint(TracingPainter oldDelegate) => oldDelegate.points != points;
}
