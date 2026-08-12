import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import 'package:mortaalim/tools/Ads_Manager.dart';
import '../../XpSystem.dart';

// ═══════════════════════════════════════════════════════════════
//  🌟 WORD STAR QUEST
//  Theme : Outer-space word spelling adventure
//  Kids drag glowing star-letters into rocket launch slots.
//  Correct word → rocket blasts off with confetti.
//  Wrong / timeout → asteroid crashes.
//  Languages: English · Français · العربية
//  Difficulty auto-scales: more blanks per level.
// ═══════════════════════════════════════════════════════════════

// ── Palette ───────────────────────────────────────────────────
class _C {
  static const bg0   = Color(0xFF0B0B2A); // deep space
  static const bg1   = Color(0xFF1A1060);
  static const gold  = Color(0xFFFFD700);
  static const cyan  = Color(0xFF00F5FF);
  static const rose  = Color(0xFFFF6B9D);
  static const lime  = Color(0xFF39FF14);
  static const white = Color(0xFFFFFFFF);
  static const font  = 'Fredoka One';

  // letter tile colours — each letter gets a unique vivid colour
  static const List<Color> stars = [
    Color(0xFFFF6B35), Color(0xFF00F5FF), Color(0xFFFF6B9D),
    Color(0xFFFFD700), Color(0xFF39FF14), Color(0xFF8B5CF6),
    Color(0xFF3B82F6), Color(0xFF06B6D4), Color(0xFFEC4899),
    Color(0xFFF97316),
  ];
}

// ── Word bank ─────────────────────────────────────────────────
const Map<String, List<Map<String, String>>> _kWords = {
  'English': [
    {'word': 'CAT',    'emoji': '🐱', 'hint': 'A furry pet that meows!'},
    {'word': 'DOG',    'emoji': '🐶', 'hint': 'Man\'s best friend!'},
    {'word': 'SUN',    'emoji': '☀️',  'hint': 'It shines in the sky!'},
    {'word': 'MOON',   'emoji': '🌙', 'hint': 'It glows at night!'},
    {'word': 'STAR',   'emoji': '⭐', 'hint': 'You wish upon it!'},
    {'word': 'FISH',   'emoji': '🐠', 'hint': 'It lives in water!'},
    {'word': 'BIRD',   'emoji': '🐦', 'hint': 'It can fly high!'},
    {'word': 'FROG',   'emoji': '🐸', 'hint': 'It jumps and croaks!'},
    {'word': 'CAKE',   'emoji': '🎂', 'hint': 'Yummy birthday treat!'},
    {'word': 'RAIN',   'emoji': '🌧️', 'hint': 'Water falls from clouds!'},
    {'word': 'APPLE',  'emoji': '🍎', 'hint': 'A red or green fruit!'},
    {'word': 'BREAD',  'emoji': '🍞', 'hint': 'Great with butter!'},
    {'word': 'HEART',  'emoji': '❤️',  'hint': 'Symbol of love!'},
    {'word': 'LIGHT',  'emoji': '💡', 'hint': 'It helps you see!'},
    {'word': 'DREAM',  'emoji': '💭', 'hint': 'Happens when you sleep!'},
    {'word': 'GHOST',  'emoji': '👻', 'hint': 'Spooky and white!'},
    {'word': 'CHAIR',  'emoji': '🪑', 'hint': 'You sit on it!'},
    {'word': 'FLOOR',  'emoji': '🏠', 'hint': 'You walk on it!'},
    {'word': 'JELLY',  'emoji': '🫙', 'hint': 'Wobbly and sweet!'},
    {'word': 'KNIFE',  'emoji': '🔪', 'hint': 'Used for cutting!'},
  ],
  'Français': [
    {'word': 'CHAT',   'emoji': '🐱', 'hint': 'Un animal qui miaule!'},
    {'word': 'LUNE',   'emoji': '🌙', 'hint': 'Brille la nuit!'},
    {'word': 'PAIN',   'emoji': '🍞', 'hint': 'On le mange au repas!'},
    {'word': 'ROSE',   'emoji': '🌹', 'hint': 'Une belle fleur rouge!'},
    {'word': 'MONDE',  'emoji': '🌍', 'hint': 'Notre planète!'},
    {'word': 'LIVRE',  'emoji': '📚', 'hint': 'Pour lire des histoires!'},
    {'word': 'ÉCOLE',  'emoji': '🏫', 'hint': 'On apprend ici!'},
    {'word': 'VOYAGE', 'emoji': '✈️',  'hint': 'Un grand déplacement!'},
    {'word': 'JARDIN', 'emoji': '🌻', 'hint': 'Plein de fleurs!'},
    {'word': 'BOUTON', 'emoji': '🔘', 'hint': 'On appuie dessus!'},
  ],
  'العربية': [
    {'word': 'قمر',   'emoji': '🌙', 'hint': 'يضيء الليل!'},
    {'word': 'نجمة',  'emoji': '⭐', 'hint': 'تلمع في السماء!'},
    {'word': 'بيت',   'emoji': '🏠', 'hint': 'نسكن فيه!'},
    {'word': 'كتاب',  'emoji': '📚', 'hint': 'نقرأ فيه!'},
    {'word': 'شمس',   'emoji': '☀️',  'hint': 'تضيء النهار!'},
    {'word': 'قلب',   'emoji': '❤️',  'hint': 'رمز الحب!'},
    {'word': 'صورة',  'emoji': '🖼️',  'hint': 'نراها بالعين!'},
    {'word': 'مدرسة', 'emoji': '🏫', 'hint': 'نتعلم فيها!'},
    {'word': 'حديقة', 'emoji': '🌻', 'hint': 'مليئة بالأزهار!'},
    {'word': 'مطبخ',  'emoji': '🍳', 'hint': 'نطبخ فيه!'},
  ],
};

// ── Language meta ─────────────────────────────────────────────
const Map<String, Map<String, dynamic>> _kLangMeta = {
  'English':  {'flag': '🇬🇧', 'rtl': false, 'hint_btn': 'Hint 💡',
    'correct': 'Amazing! 🚀', 'wrong': 'Try Again! 💫',
    'drag_tip': 'Drag the star letters!'},
  'Français': {'flag': '🇫🇷', 'rtl': false, 'hint_btn': 'Indice 💡',
    'correct': 'Bravo! 🚀', 'wrong': 'Réessaie! 💫',
    'drag_tip': 'Glisse les étoiles!'},
  'العربية':  {'flag': '🇸🇦', 'rtl': true,  'hint_btn': 'تلميح 💡',
    'correct': 'رائع! 🚀', 'wrong': 'حاول مجدداً! 💫',
    'drag_tip': 'اسحب النجوم!'},
};

// ═══════════════════════════════════════════════════════════════
//  ENTRY
// ═══════════════════════════════════════════════════════════════
class WordExplorer extends StatelessWidget {
  const WordExplorer({super.key});
  @override
  Widget build(BuildContext context) => const _LanguageSelectPage();
}

// ═══════════════════════════════════════════════════════════════
//  LANGUAGE SELECT
// ═══════════════════════════════════════════════════════════════
class _LanguageSelectPage extends StatefulWidget {
  const _LanguageSelectPage();
  @override State<_LanguageSelectPage> createState() => _LanguageSelectState();
}
class _LanguageSelectState extends State<_LanguageSelectPage>
    with TickerProviderStateMixin {

  late final AnimationController _bgCtrl;
  late final AnimationController _floatCtrl;

  // Fixed star positions
  late final List<_Star> _stars;

  // ── Ads ─────────────────────────────────────────────────────
  BannerAd? _bannerAd;
  bool      _bannerLoaded = false;

  @override
  void initState() {
    super.initState();
    final rng = Random(7);
    _stars = List.generate(70, (_) => _Star(
      x: rng.nextDouble(), y: rng.nextDouble(),
      r: 0.5 + rng.nextDouble() * 1.8,
      phase: rng.nextDouble() * 2 * pi,
    ));
    _bgCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 8))..repeat();
    _floatCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 3))..repeat(reverse: true);
  }
  @override void dispose() {
    _bgCtrl.dispose(); _floatCtrl.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg0,
      body: Stack(children: [
        // Star field
        AnimatedBuilder(animation: _bgCtrl,
            builder: (_, __) => CustomPaint(
                painter: _StarFieldPainter(_stars, _bgCtrl.value),
                size: MediaQuery.of(context).size)),
        // Nebula glows
        _glow(top: -80,  left: -80,  color: _C.rose,  size: 280),
        _glow(top: 300,  right: -60, color: _C.cyan,  size: 220),
        _glow(bottom: -60, left: 60, color: _C.gold,  size: 180),

        SafeArea(child: Column(children: [
          const SizedBox(height: 20),
          // Back button row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () { HapticFeedback.selectionClick(); Navigator.pop(context); },
                child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.22), width: 1.2)),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: Colors.white)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Title
          AnimatedBuilder(animation: _floatCtrl, builder: (_, __) =>
              Transform.translate(
                offset: Offset(0, sin(_floatCtrl.value * pi) * 6),
                child: Column(children: [
                  const Text('🌟', style: TextStyle(fontSize: 60)),
                  const SizedBox(height: 8),
                  const Text('Word Star Quest',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: _C.font, fontSize: 32,
                          color: _C.gold,
                          shadows: [Shadow(color: Color(0xFFFFD700),
                              blurRadius: 20)])),
                  const SizedBox(height: 6),
                  Text('Pick a language to start!',
                      style: TextStyle(fontFamily: _C.font, fontSize: 16,
                          color: Colors.white.withOpacity(0.65))),
                ]),
              )),
          const SizedBox(height: 40),
          // Language cards
          ..._kWords.keys.map((lang) {
            final meta = _kLangMeta[lang]!;
            return _LangCard(
              lang: lang,
              flag: meta['flag'] as String,
              wordCount: _kWords[lang]!.length,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => _WordGamePage(language: lang))),
            );
          }),
        ])),
      ]),
    );
  }

  Widget _glow({double? top, double? bottom, double? left, double? right,
    required Color color, required double size}) =>
      Positioned(top: top, bottom: bottom, left: left, right: right,
          child: Container(width: size, height: size,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    color.withOpacity(0.18), Colors.transparent]))));
}

// Language card
class _LangCard extends StatefulWidget {
  final String lang, flag;
  final int wordCount;
  final VoidCallback onTap;
  const _LangCard({required this.lang, required this.flag,
    required this.wordCount, required this.onTap});
  @override State<_LangCard> createState() => _LangCardState();
}
class _LangCardState extends State<_LangCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double>   _scale;
  @override void initState() {
    super.initState();
    _press = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 80));
    _scale = Tween(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _press, curve: Curves.easeOut));
  }
  @override void dispose() { _press.dispose(); super.dispose(); }

  static const Map<String, List<Color>> _gradients = {
    'English':  [Color(0xFF3B82F6), Color(0xFF06B6D4)],
    'Français': [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    'العربية':  [Color(0xFF22C55E), Color(0xFF06B6D4)],
  };

  @override
  Widget build(BuildContext context) {
    final colors = _gradients[widget.lang] ?? [_C.cyan, _C.rose];
    return GestureDetector(
      onTapDown:   (_) => _press.forward(),
      onTapUp:     (_) => _press.reverse(),
      onTapCancel: ()  => _press.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors,
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(
                color: colors[0].withOpacity(0.50),
                blurRadius: 20, offset: const Offset(0, 6))],
          ),
          child: Row(children: [
            Text(widget.flag, style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 16),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.lang, style: const TextStyle(fontFamily: _C.font,
                  fontSize: 22, color: _C.white)),
              Text('${widget.wordCount} words to discover 🌟',
                  style: TextStyle(fontSize: 13,
                      color: Colors.white.withOpacity(0.75))),
            ])),
            Container(width: 42, height: 42,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow_rounded,
                    color: _C.white, size: 26)),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  GAME PAGE
// ═══════════════════════════════════════════════════════════════
class _WordGamePage extends StatefulWidget {
  final String language;
  const _WordGamePage({required this.language});
  @override State<_WordGamePage> createState() => _WordGamePageState();
}

class _WordGamePageState extends State<_WordGamePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {

  final Random _rng = Random();

  // ── Word state ───────────────────────────────────────────────
  late List<Map<String, String>> _wordPool;
  late String  _word;      // full word
  late String  _emoji;
  late String  _hint;
  late int     _blanks;    // how many letters to fill (grows with level)
  late List<int>    _blankIndices;  // which positions are blanks
  late List<String> _placed;        // filled letters ('' = empty)
  late List<String> _choices;       // letter tiles available
  late List<String> _remaining;     // not yet dragged

  int  _level = 1;
  int  _score = 0;
  int  _timeLeft = 0;
  int  _streak = 0;
  Timer? _timer;
  bool _showHint = false;

  // ── Animations ───────────────────────────────────────────────
  late final AnimationController _bgCtrl;
  late final AnimationController _rocketCtrl;  // launch animation
  late final AnimationController _shakeCtrl;
  late final Animation<double>   _shakeAnim;
  late final AnimationController _correctCtrl;
  late final Animation<double>   _correctScale;
  late final AnimationController _streakCtrl;  // streak fire flicker
  bool _showRocket   = false;
  bool _showCrash    = false;
  bool _showCorrect  = false;

  late final List<_Star> _stars;

  // ── Ads ─────────────────────────────────────────────────────
  BannerAd? _bannerAd;
  bool      _bannerLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final rng2 = Random(13);
    _stars = List.generate(55, (_) => _Star(
      x: rng2.nextDouble(), y: rng2.nextDouble(),
      r: 0.4 + rng2.nextDouble() * 1.5,
      phase: rng2.nextDouble() * 2 * pi,
    ));

    _bgCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 6))..repeat();

    _rocketCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900));
    _shakeCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 380));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0,  end: 14.0),  weight: 20),
      TweenSequenceItem(tween: Tween(begin: 14.0, end: -14.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: -14.0, end: 0.0),  weight: 40),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _correctCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 500));
    _correctScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.25), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0),  weight: 55),
    ]).animate(CurvedAnimation(parent: _correctCtrl, curve: Curves.easeOut));

    _streakCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 500))..repeat(reverse: true);

    _wordPool = List.of(_kWords[widget.language]!)..shuffle(_rng);
    _loadBannerAd();
    _loadWord();
  }

  @override void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _bgCtrl.dispose(); _rocketCtrl.dispose(); _shakeCtrl.dispose();
    _correctCtrl.dispose(); _streakCtrl.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd?.dispose(); _bannerLoaded = false;
    if (!mounted) return;
    if (!Provider.of<ExperienceManager>(context, listen: false).adsEnabled) return;
    _bannerAd = AdHelper.getBannerAd(
            () { if (mounted) setState(() => _bannerLoaded = true); });
  }

  // ── Load next word ────────────────────────────────────────────
  void _loadWord() {
    _timer?.cancel();
    if (_wordPool.isEmpty) {
      _wordPool = List.of(_kWords[widget.language]!)..shuffle(_rng);
    }
    final entry = _wordPool.removeLast();
    _word  = entry['word']!.toUpperCase();
    _emoji = entry['emoji']!;
    _hint  = entry['hint']!;

    // blanks scale with level: 1=1 blank, 2=2, 3=3, max = word.length-2
    _blanks = (_level).clamp(1, max(1, _word.length - 1));

    // Pick which indices to blank (never first for short words)
    final allIdx = List.generate(_word.length, (i) => i);
    allIdx.shuffle(_rng);
    _blankIndices = allIdx.take(_blanks).toList()..sort();
    _placed = List.filled(_blanks, '');

    // Build choice pool: the correct letters + random distractors
    final correctLetters = _blankIndices.map((i) => _word[i]).toList();
    final extras = <String>[];
    while (extras.length < max(4, _blanks + 3)) {
      final c = String.fromCharCode(_rng.nextInt(26) + 65);
      if (!correctLetters.contains(c) || extras.contains(c)) extras.add(c);
    }
    _choices   = [...correctLetters, ...extras.take(max(4, _blanks + 2))]
      ..shuffle(_rng);
    _remaining = List.of(_choices);
    _showHint  = false;
    _showRocket = _showCrash = _showCorrect = false;

    // Timer: longer for easier levels
    final maxTime = max(12, 30 - (_level * 4));
    _timeLeft = maxTime;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) { _timer?.cancel(); _onTimeUp(); }
    });

    setState(() {});
  }

  // ── Check answer ─────────────────────────────────────────────
  void _checkAnswer() {
    if (_placed.any((l) => l.isEmpty)) return; // not all filled
    // Reconstruct full word with placed letters
    String built = '';
    int blankIdx = 0;
    for (int i = 0; i < _word.length; i++) {
      if (_blankIndices.contains(i)) {
        built += _placed[blankIdx++];
      } else {
        built += _word[i];
      }
    }
    if (built == _word) {
      _onCorrect();
    } else {
      _onWrong();
    }
  }

  void _onCorrect() {
    HapticFeedback.lightImpact();
    _timer?.cancel();
    _streak++;
    final bonus = _streak >= 3 ? (_streak * 5) : 0;
    _score += _level * 10 + bonus;
    // Award XP
    Provider.of<ExperienceManager>(context, listen: false)
        .addXP(_level, context: context);
    _correctCtrl.reset(); _correctCtrl.forward();
    setState(() { _showCorrect = true; });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() { _showRocket = true; });
      _rocketCtrl.reset(); _rocketCtrl.forward();
    });

    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      setState(() { _showRocket = false; _showCorrect = false; });
      _level = _level < 5 ? _level + 1 : _level;
      _loadWord();
    });
  }

  void _onWrong() {
    HapticFeedback.heavyImpact();
    _streak = 0;
    _shakeCtrl.reset(); _shakeCtrl.forward();
    setState(() { _showCrash = true; });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() {
        _showCrash = false;
        // clear placed letters so kid can retry
        _placed = List.filled(_blanks, '');
        _remaining = List.of(_choices);
      });
    });
  }

  void _onTimeUp() {
    _streak = 0;
    _showDialog(title: '⏰ Time\'s up!', subtitle: 'The answer was: $_word',
        isWin: false);
  }

  void _revealHint() {
    // Find first empty blank and fill it
    for (int i = 0; i < _blanks; i++) {
      if (_placed[i].isEmpty) {
        final correct = _word[_blankIndices[i]];
        setState(() {
          _placed[i] = correct;
          _remaining.remove(correct);
        });
        break;
      }
    }
    _checkAnswer();
  }

  void _showDialog({required String title, required String subtitle,
    required bool isWin}) {
    _timer?.cancel();
    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: isWin
                    ? [const Color(0xFF1A1060), const Color(0xFF0B0B2A)]
                    : [const Color(0xFF2A0A0A), const Color(0xFF1A0505)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
                color: isWin ? _C.gold : _C.rose, width: 2.5),
            boxShadow: [BoxShadow(
                color: (isWin ? _C.gold : _C.rose).withOpacity(0.40),
                blurRadius: 28)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(isWin ? '🚀' : '💥',
                style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center,
                style: TextStyle(fontFamily: _C.font, fontSize: 24,
                    color: isWin ? _C.gold : _C.rose)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center,
                style: TextStyle(fontFamily: _C.font, fontSize: 15,
                    color: Colors.white.withOpacity(0.75))),
            const SizedBox(height: 6),
            Text('Score: $_score',
                style: const TextStyle(fontFamily: _C.font,
                    fontSize: 18, color: _C.cyan)),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(child: _SpaceBtn(
                label: 'Next Word ▶',
                color: isWin ? _C.gold : _C.cyan,
                textColor: isWin ? _C.bg0 : _C.white,
                onTap: () {
                  Navigator.pop(context);
                  AdHelper.showInterstitialAd(
                    context: context,
                    onDismissed: _loadWord,
                  );
                },
              )),
              const SizedBox(width: 10),
              Expanded(child: _SpaceBtn(
                label: '🏠 Home',
                color: Colors.white.withOpacity(0.10),
                textColor: Colors.white70,
                borderColor: Colors.white.withOpacity(0.25),
                onTap: () { Navigator.pop(context); Navigator.pop(context); },
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  Future<bool> _confirmQuit() async {
    _timer?.cancel(); // pause timer while dialog shows
    final quit = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF1A1060), Color(0xFF0B0B2A)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: _C.rose.withOpacity(0.60), width: 2),
            boxShadow: [BoxShadow(
                color: _C.rose.withOpacity(0.30), blurRadius: 26)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🛸', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 10),
            const Text('Quit this mission?',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: _C.font,
                    fontSize: 22, color: _C.white)),
            const SizedBox(height: 6),
            Text('Your progress will be lost!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13,
                    color: Colors.white.withOpacity(0.55))),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(child: _SpaceBtn(
                label: '▶ Keep Playing',
                color: _C.cyan,
                textColor: _C.bg0,
                onTap: () => Navigator.pop(context, false),
              )),
              const SizedBox(width: 10),
              Expanded(child: _SpaceBtn(
                label: '🏠 Quit',
                color: _C.rose.withOpacity(0.90),
                textColor: _C.white,
                onTap: () => Navigator.pop(context, true),
              )),
            ]),
          ]),
        ),
      ),
    );
    // If they chose to keep playing, restart the timer
    if (quit != true && mounted) {
      final maxTime = max(12, 30 - (_level * 4));
      if (_timeLeft > 0) {
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted) return;
          setState(() => _timeLeft--);
          if (_timeLeft <= 0) { _timer?.cancel(); _onTimeUp(); }
        });
      }
    }
    return quit ?? false;
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final meta   = _kLangMeta[widget.language]!;
    final isRtl  = meta['rtl'] as bool;
    final size   = MediaQuery.of(context).size;

    final adsOn = context.watch<ExperienceManager>().adsEnabled;
    return WillPopScope(
        onWillPop: _confirmQuit,
        child: Scaffold(
          backgroundColor: _C.bg0,
          bottomNavigationBar: adsOn
              ? FamilyAdBanner(bannerAd: _bannerAd, isLoaded: _bannerLoaded)
              : null,
          body: Stack(children: [
            // Star field BG
            AnimatedBuilder(animation: _bgCtrl,
                builder: (_, __) => CustomPaint(
                    painter: _StarFieldPainter(_stars, _bgCtrl.value), size: size)),
            // Nebula
            Positioned(top: -60, right: -60,
                child: Container(width: 200, height: 200,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [_C.rose.withOpacity(0.18), Colors.transparent])))),
            Positioned(bottom: 80, left: -40,
                child: Container(width: 160, height: 160,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [_C.cyan.withOpacity(0.14), Colors.transparent])))),

            // Main content
            SafeArea(child: Column(children: [
              _buildHUD(meta),
              const Padding(
                  padding: EdgeInsets.fromLTRB(12, 6, 12, 0),
                  child: Userstatutbar()),
              const SizedBox(height: 4),
              _buildTimerBar(),
              const SizedBox(height: 12),
              // Word display
              _buildWordDisplay(isRtl),
              const SizedBox(height: 10),
              // Hint text
              if (_showHint)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    decoration: BoxDecoration(
                        color: _C.gold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _C.gold.withOpacity(0.50), width: 1.5)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Text('💡 ', style: TextStyle(fontSize: 18)),
                      Flexible(child: Text(_hint,
                          style: const TextStyle(fontFamily: _C.font,
                              fontSize: 14, color: _C.gold))),
                    ]),
                  ),
                ),
              const SizedBox(height: 8),
              // Emoji big display
              ScaleTransition(
                  scale: _showCorrect ? _correctScale : const AlwaysStoppedAnimation(1.0),
                  child: Text(_emoji, style: const TextStyle(fontSize: 64))),
              const SizedBox(height: 10),
              // Letter tiles
              Expanded(child: _buildLetterPad(meta)),
              // Buttons row
              _buildButtons(meta),
              const SizedBox(height: 8),
            ])),

            // Rocket launch overlay
            if (_showRocket)
              _RocketLaunch(ctrl: _rocketCtrl),

            // Crash overlay
            if (_showCrash)
              _CrashBurst(),

            // Streak indicator
            if (_streak >= 3)
              Positioned(top: 100, right: 12,
                  child: _StreakBadge(streak: _streak, ctrl: _streakCtrl)),
          ]),
        )); // closes Scaffold + WillPopScope
  }

  Widget _nebula(double? top, double? bottom, Color color, double size) =>
      Positioned(top: top, bottom: bottom,
          child: Container(width: size, height: size,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  gradient: RadialGradient(
                      colors: [color.withOpacity(0.18), Colors.transparent]))));

  // ── HUD ─────────────────────────────────────────────────────
  Widget _buildHUD(Map<String, dynamic> meta) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () async {
            HapticFeedback.selectionClick();
            final quit = await _confirmQuit();
            if (quit && mounted) Navigator.pop(context);
          },
          child: Container(width: 38, height: 38,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.18), width: 1)),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: Colors.white)),
        ),
        const SizedBox(width: 8),
        Text(meta['flag'] as String, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 6),
        Text('Level $_level',
            style: const TextStyle(fontFamily: _C.font,
                fontSize: 14, color: _C.cyan)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
              color: _C.gold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.gold.withOpacity(0.45), width: 1.2)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('⭐', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text('$_score',
                style: const TextStyle(fontFamily: _C.font,
                    fontSize: 14, color: _C.gold)),
          ]),
        ),
      ]),
    );
  }

  // ── TIMER BAR ────────────────────────────────────────────────
  Widget _buildTimerBar() {
    final maxTime = max(12, 30 - (_level * 4));
    final pct     = (_timeLeft / maxTime).clamp(0.0, 1.0);
    final color   = pct > 0.5 ? _C.lime
        : pct > 0.25 ? _C.gold
        : _C.rose;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: [
        const Text('⏱️', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Expanded(child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(children: [
            Container(height: 10,
                color: Colors.white.withOpacity(0.08)),
            AnimatedFractionallySizedBox(
              widthFactor: pct,
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOut,
              child: Container(height: 10,
                  decoration: BoxDecoration(color: color,
                      boxShadow: [BoxShadow(
                          color: color.withOpacity(0.80), blurRadius: 8)])),
            ),
          ]),
        )),
        const SizedBox(width: 6),
        Text('${_timeLeft}s',
            style: TextStyle(fontFamily: _C.font,
                fontSize: 13, color: color)),
      ]),
    );
  }

  // ── WORD DISPLAY ─────────────────────────────────────────────
  Widget _buildWordDisplay(bool isRtl) {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (_, child) => Transform.translate(
          offset: Offset(_shakeAnim.value, 0), child: child),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _C.cyan.withOpacity(0.28), width: 1.5),
          boxShadow: [BoxShadow(
              color: _C.cyan.withOpacity(0.10), blurRadius: 16)],
        ),
        child: Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 6, runSpacing: 6,
            children: _buildLetterSlots(),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLetterSlots() {
    final slots = <Widget>[];
    int blankCounter = 0;
    for (int i = 0; i < _word.length; i++) {
      if (_blankIndices.contains(i)) {
        final idx = blankCounter++;
        slots.add(_DropSlot(
          index: idx,
          placed: _placed[idx],
          onAccept: (letter) {
            if (_placed[idx].isNotEmpty) return; // already filled
            setState(() {
              _placed[idx] = letter;
              _remaining.remove(letter);
            });
            _checkAnswer();
          },
          onTap: () {
            // tap to remove placed letter back to pool
            if (_placed[idx].isNotEmpty) {
              setState(() {
                _remaining.add(_placed[idx]);
                _placed[idx] = '';
              });
            }
          },
        ));
      } else {
        // Fixed letter
        slots.add(_FixedLetter(letter: _word[i]));
      }
    }
    return slots;
  }

  // ── LETTER PAD ───────────────────────────────────────────────
  Widget _buildLetterPad(Map<String, dynamic> meta) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(meta['drag_tip'] as String,
            style: TextStyle(fontFamily: _C.font, fontSize: 13,
                color: Colors.white.withOpacity(0.45))),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          alignment: WrapAlignment.center,
          children: _remaining.asMap().entries.map((e) {
            final color = _C.stars[e.key % _C.stars.length];
            return Draggable<String>(
              data: e.value,
              onDragStarted: () => HapticFeedback.selectionClick(),
              feedback: Material(color: Colors.transparent,
                  child: _StarTile(letter: e.value, color: color, size: 60)),
              childWhenDragging: _StarTile(
                  letter: e.value, color: color, size: 54, faded: true),
              child: _StarTile(letter: e.value, color: color, size: 54),
            );
          }).toList(),
        ),
      ]),
    );
  }

  // ── BUTTONS ─────────────────────────────────────────────────
  Widget _buildButtons(Map<String, dynamic> meta) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: [
        // Hint
        Expanded(child: GestureDetector(
          onTap: () {
            setState(() => _showHint = true);
            _revealHint();
          },
          child: Container(
            height: 42,
            decoration: BoxDecoration(
                color: _C.gold.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _C.gold.withOpacity(0.50), width: 1.5)),
            alignment: Alignment.center,
            child: Text(meta['hint_btn'] as String,
                style: const TextStyle(fontFamily: _C.font,
                    fontSize: 14, color: _C.gold)),
          ),
        )),
        const SizedBox(width: 10),
        // Clear
        Expanded(child: GestureDetector(
          onTap: () => setState(() {
            _placed = List.filled(_blanks, '');
            _remaining = List.of(_choices);
          }),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
                color: _C.rose.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _C.rose.withOpacity(0.50), width: 1.5)),
            alignment: Alignment.center,
            child: const Text('🔄 Clear',
                style: TextStyle(fontFamily: _C.font,
                    fontSize: 14, color: _C.rose)),
          ),
        )),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  DROP SLOT  (blank letter box)
// ═══════════════════════════════════════════════════════════════
class _DropSlot extends StatelessWidget {
  final int     index;
  final String  placed;
  final void Function(String) onAccept;
  final VoidCallback onTap;
  const _DropSlot({required this.index, required this.placed,
    required this.onAccept, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final filled = placed.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: DragTarget<String>(
        onWillAccept: (_) => !filled,
        onAccept: onAccept,
        builder: (_, candidates, __) {
          final hovering = candidates.isNotEmpty && !filled;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 52, height: 56,
            decoration: BoxDecoration(
              gradient: filled ? LinearGradient(colors: [
                _C.cyan.withOpacity(0.30), _C.cyan.withOpacity(0.15),
              ]) : null,
              color: filled ? null
                  : hovering
                  ? _C.gold.withOpacity(0.18)
                  : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: filled ? _C.cyan
                      : hovering ? _C.gold
                      : Colors.white.withOpacity(0.35),
                  width: filled ? 2.5 : hovering ? 3.0 : 2.0),
              boxShadow: filled ? [BoxShadow(
                  color: _C.cyan.withOpacity(0.50), blurRadius: 14)] : null,
            ),
            alignment: Alignment.center,
            child: filled
                ? Text(placed,
                style: const TextStyle(fontFamily: _C.font,
                    fontSize: 26, color: _C.white,
                    shadows: [Shadow(color: _C.cyan, blurRadius: 8)]))
                : Text('_', style: TextStyle(
                fontSize: 28, color: Colors.white.withOpacity(0.35),
                fontWeight: FontWeight.bold)),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  FIXED LETTER  (shown but not interactive)
// ═══════════════════════════════════════════════════════════════
class _FixedLetter extends StatelessWidget {
  final String letter;
  const _FixedLetter({required this.letter});
  @override
  Widget build(BuildContext context) => Container(
    width: 52, height: 56,
    decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5)),
    alignment: Alignment.center,
    child: Text(letter,
        style: const TextStyle(fontFamily: _C.font,
            fontSize: 26, color: _C.white)),
  );
}

// ═══════════════════════════════════════════════════════════════
//  STAR LETTER TILE  (draggable)
// ═══════════════════════════════════════════════════════════════
class _StarTile extends StatelessWidget {
  final String letter;
  final Color  color;
  final double size;
  final bool   faded;
  const _StarTile({required this.letter, required this.color,
    required this.size, this.faded = false});

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity: faded ? 0.25 : 1.0,
    duration: const Duration(milliseconds: 200),
    child: Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
            center: const Alignment(-0.3, -0.3),
            radius: 0.85,
            colors: [
              Color.lerp(color, Colors.white, 0.35)!,
              color,
              Color.lerp(color, Colors.black, 0.22)!,
            ], stops: const [0.0, 0.55, 1.0]),
        boxShadow: faded ? null : [
          BoxShadow(color: color.withOpacity(0.65),
              blurRadius: 10, offset: const Offset(0, 4)),
          BoxShadow(color: color.withOpacity(0.28),
              blurRadius: 18, spreadRadius: 1),
        ],
      ),
      alignment: Alignment.center,
      child: Text(letter,
          style: const TextStyle(fontFamily: _C.font,
              fontSize: 22, color: _C.white,
              shadows: [Shadow(color: Colors.black38,
                  blurRadius: 5, offset: Offset(0, 2))])),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
//  ROCKET LAUNCH OVERLAY
// ═══════════════════════════════════════════════════════════════
class _RocketLaunch extends StatelessWidget {
  final AnimationController ctrl;
  const _RocketLaunch({required this.ctrl});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final t = ctrl.value;
        final dy = -t * MediaQuery.of(context).size.height * 0.8;
        return IgnorePointer(child: Align(
          alignment: Alignment.bottomCenter,
          child: Transform.translate(
            offset: Offset(0, dy),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Opacity(opacity: (1 - t * 1.5).clamp(0.0, 1.0),
                  child: const Text('🚀', style: TextStyle(fontSize: 72))),
              Opacity(opacity: (1 - t * 2).clamp(0.0, 1.0),
                  child: const Text('🔥', style: TextStyle(fontSize: 40))),
            ]),
          ),
        ));
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  CRASH BURST
// ═══════════════════════════════════════════════════════════════
class _CrashBurst extends StatefulWidget {
  @override State<_CrashBurst> createState() => _CrashBurstState();
}
class _CrashBurstState extends State<_CrashBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600))..forward();
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _c, builder: (_, __) {
      final t = _c.value;
      return IgnorePointer(child: Container(
        color: Colors.red.withOpacity((0.25 - t * 0.25).clamp(0, 1)),
        alignment: Alignment.center,
        child: Transform.scale(scale: 1 + t * 1.5,
            child: Opacity(opacity: (1 - t).clamp(0, 1),
                child: const Text('💥', style: TextStyle(fontSize: 80)))),
      ));
    });
  }
}

// ═══════════════════════════════════════════════════════════════
//  STREAK BADGE
// ═══════════════════════════════════════════════════════════════
class _StreakBadge extends StatelessWidget {
  final int streak; final AnimationController ctrl;
  const _StreakBadge({required this.streak, required this.ctrl});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: ctrl,
        builder: (_, __) => Transform.scale(
          scale: 0.92 + ctrl.value * 0.08,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFFD700)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                    color: const Color(0xFFFF6B35).withOpacity(0.60),
                    blurRadius: 12)]),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('🔥', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text('×$streak', style: const TextStyle(
                  fontFamily: _C.font, fontSize: 16, color: _C.white)),
            ]),
          ),
        ));
  }
}

// ═══════════════════════════════════════════════════════════════
//  SPACE BUTTON
// ═══════════════════════════════════════════════════════════════
class _SpaceBtn extends StatelessWidget {
  final String label; final Color color, textColor;
  final Color? borderColor; final VoidCallback onTap;
  const _SpaceBtn({required this.label, required this.color,
    required this.textColor, required this.onTap, this.borderColor});
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(color: color,
              borderRadius: BorderRadius.circular(18),
              border: borderColor != null
                  ? Border.all(color: borderColor!, width: 1.5) : null,
              boxShadow: [BoxShadow(color: color.withOpacity(0.40),
                  blurRadius: 10, offset: const Offset(0, 4))]),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontFamily: _C.font,
              fontSize: 15, color: textColor))));
}

// ═══════════════════════════════════════════════════════════════
//  STAR FIELD
// ═══════════════════════════════════════════════════════════════
class _Star { final double x, y, r, phase;
_Star({required this.x, required this.y,
  required this.r, required this.phase}); }

class _StarFieldPainter extends CustomPainter {
  final List<_Star> stars; final double t;
  _StarFieldPainter(this.stars, this.t);
  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      final a = ((0.25 + 0.75 * sin(t * 2 * pi * 3 + s.phase)) * 255)
          .round().clamp(0, 255);
      canvas.drawCircle(Offset(s.x * size.width, s.y * size.height), s.r,
          Paint()..color = Color.fromARGB(a, 255, 255, 255));
    }
  }
  @override bool shouldRepaint(_StarFieldPainter o) => o.t != t;
}