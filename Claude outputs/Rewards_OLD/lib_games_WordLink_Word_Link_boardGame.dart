import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../../XpSystem.dart';
import '../../tools/Ads_Manager.dart';
import '../../tools/audio_tool/Audio_Manager.dart';
import '../../widgets/KidScene/kid_page_parts.dart';
import '../../widgets/KidScene/kid_scene.dart';
import 'word_link_data.dart';

// ── art ─────────────────────────────────────────────────────────────────────
const String _imgBack = '${wlDir}wl_back.webp';
const String _imgGear = '${wlDir}wl_gear.webp';
const String _imgCat = '${wlDir}wl_cat.webp';
const String _imgBubble = '${wlDir}wl_bubble.webp';
const String _imgRobot = '${wlDir}wl_robot.webp';
const String _imgTeal = '${wlDir}wl_tile_teal.webp';
const String _imgGreen = '${wlDir}wl_tile_green.webp';
const String _imgSlot = '${wlDir}wl_tile_slot.webp';
const String _imgSlotHl = '${wlDir}wl_tile_slot_hl.webp';
const String _imgLetter = '${wlDir}wl_letter.webp';
const String _imgShuffle = '${wlDir}wl_shuffle.webp';
const String _imgBulb = '${wlDir}wl_bulb.webp';
const String _imgSpeaker = '${wlDir}wl_speaker.webp';
const String _imgSprout = '${wlDir}wl_sprout.webp';
const String _imgBg = '${wlDir}it_page_bg.webp';
const String _imgStarOn = '${wlDir}games_star_on.webp';
const String _imgStarOff = '${wlDir}games_star_off.webp';

const int _hintCost = 10; // gold per revealed letter
const int _winGold = 3; // gold for finishing a level

const Color _ink = Color(0xFF2D0B57);
const Color _okGreen = Color(0xFF2FB344);
const Color _badRed = Color(0xFFFF4D4D);
const Color _warnOrange = Color(0xFFFF8A00);

/// Word Link: swipe across the letters on the wheel to spell the words that
/// fill the little crossword. Hints cost gold, "Hear" says a missing word.
class WordBoardGame extends StatefulWidget {
  const WordBoardGame({super.key});

  @override
  State<WordBoardGame> createState() => _WordBoardGameState();
}

class _WordBoardGameState extends State<WordBoardGame> with TickerProviderStateMixin {
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  final ConfettiController _confetti = ConfettiController(duration: const Duration(seconds: 2));
  final FlutterTts _tts = FlutterTts();

  bool _ready = false;
  bool _precached = false;
  String _lang = 'en';
  int _levelIdx = 0;

  late WlLevel _level;
  Map<int, String> _solution = {};
  List<String> _chars = []; // wheel letters, by letter id
  List<int> _slotOf = []; // letter id → position on the wheel
  final Set<String> _found = {};
  final List<String> _foundOrder = [];
  final Set<int> _revealed = {};
  int _hintsUsed = 0;
  bool _won = false;

  // swipe
  List<int> _path = []; // letter ids
  Offset? _finger;
  int? _pointer;
  List<Offset> _centers = []; // by slot
  double _letterR = 0;

  // feedback
  String _bubbleKey = 'start';
  int _bubbleTick = 0;
  String? _flashWord;
  Color _flashColor = _ink;

  BannerAd? _banner;
  bool _bannerLoaded = false;

  AudioManager get _audio => Provider.of<AudioManager>(context, listen: false);
  ExperienceManager get _xp => Provider.of<ExperienceManager>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _banner = AdHelper.getBannerAd(() {
      if (mounted) setState(() => _bannerLoaded = true);
    });
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    KidAssets.precache(context, [
      _imgBack, _imgGear, _imgCat, _imgBubble, _imgRobot, _imgTeal, _imgGreen, _imgSlot, _imgSlotHl,
      _imgLetter, _imgShuffle, _imgBulb, _imgSpeaker, _imgSprout, _imgBg, kidCoinAsset, kidGemAsset,
    ]);
  }

  @override
  void dispose() {
    _tts.stop();
    _intro.dispose();
    _idle.dispose();
    _shake.dispose();
    _spin.dispose();
    _confetti.dispose();
    _banner?.dispose();
    super.dispose();
  }

  // ── setup ────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    final saved = await WlStore.lang();
    if (!mounted) return;
    final ui = wlUiLang(context);
    _lang = saved ?? (ui == 'en' || ui == 'de' ? 'en' : 'fr');
    _levelIdx = await WlStore.level(_lang);
    try {
      await _tts.setSpeechRate(0.42);
      await _tts.setPitch(1.1);
    } catch (_) {}
    await _setTtsLang();
    if (!mounted) return;
    setState(() {
      _startLevel();
      _ready = true;
    });
    _intro.forward(from: 0);
  }

  Future<void> _setTtsLang() async {
    try {
      await _tts.setLanguage(_lang == 'fr' ? 'fr-FR' : 'en-US');
    } catch (_) {}
  }

  void _startLevel() {
    final list = wlLevels(_lang);
    _level = list[_levelIdx % list.length];
    _solution = _level.solution;
    _chars = _level.letters.split('');
    _slotOf = List<int>.generate(_chars.length, (i) => i)..shuffle();
    // never show the long word already spelled clockwise from the top
    if (_isIdentity(_slotOf) && _chars.length > 1) {
      _slotOf = [..._slotOf.skip(1), _slotOf.first];
    }
    _found.clear();
    _foundOrder.clear();
    _revealed.clear();
    _hintsUsed = 0;
    _won = false;
    _path = [];
    _finger = null;
    _pointer = null;
    _flashWord = null;
    _bubbleKey = 'start';
    _bubbleTick++;
  }

  static bool _isIdentity(List<int> l) {
    for (int i = 0; i < l.length; i++) {
      if (l[i] != i) return false;
    }
    return true;
  }

  // ── state helpers ────────────────────────────────────────────────────────

  int get _remaining => _level.words.where((w) => !_found.contains(w.text)).length;

  /// Unfound words, shortest first — what "Hear" says and the hint fills.
  List<WlWord> get _open =>
      _level.words.where((w) => !_found.contains(w.text)).toList()..sort((a, b) => a.text.length.compareTo(b.text.length));

  WlWord? get _nextWord {
    final o = _open;
    return o.isEmpty ? null : o.first;
  }

  bool _visible(int cell) =>
      _revealed.contains(cell) || _level.words.any((w) => _found.contains(w.text) && w.cells.contains(cell));

  void _say(String key) => setState(() {
        _bubbleKey = key;
        _bubbleTick++;
      });

  Future<void> _speak(String word) async {
    try {
      await _tts.stop();
      await _tts.speak(word.toLowerCase());
    } catch (_) {}
  }

  void _flash(String word, Color color) {
    setState(() {
      _flashWord = word;
      _flashColor = color;
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted && _flashWord == word) setState(() => _flashWord = null);
    });
  }

  // ── swipe on the wheel ───────────────────────────────────────────────────

  int? _hit(Offset p, double factor) {
    for (int id = 0; id < _chars.length; id++) {
      final c = _centers[_slotOf[id]];
      if ((p - c).distance <= _letterR * factor) return id;
    }
    return null;
  }

  void _down(PointerDownEvent e) {
    if (_won || _pointer != null || _centers.isEmpty) return;
    final id = _hit(e.localPosition, 1.05);
    if (id == null) return;
    _pointer = e.pointer;
    HapticFeedback.selectionClick();
    _audio.playEventSound('PopClick');
    setState(() {
      _path = [id];
      _finger = e.localPosition;
      _flashWord = null;
    });
  }

  void _move(PointerMoveEvent e) {
    if (e.pointer != _pointer) return;
    final p = e.localPosition;
    final id = _hit(p, 0.82);
    setState(() {
      _finger = p;
      if (id == null) return;
      if (_path.length >= 2 && id == _path[_path.length - 2]) {
        _path.removeLast(); // slide back to undo
      } else if (!_path.contains(id)) {
        _path.add(id);
        HapticFeedback.selectionClick();
        _audio.playEventSound('PopClick');
      }
    });
  }

  void _up(PointerEvent e) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    final word = _path.map((id) => _chars[id]).join();
    setState(() {
      _path = [];
      _finger = null;
    });
    if (word.length >= 2) _submit(word);
  }

  void _submit(String word) {
    if (!_level.words.any((w) => w.text == word)) {
      _flash(word, _badRed);
      _shake.forward(from: 0);
      _audio.playSfx('assets/audios/QuizGame_Sounds/incorrect.mp3');
      HapticFeedback.mediumImpact();
      _say('tryAgain');
      return;
    }
    if (_found.contains(word)) {
      _flash(word, _warnOrange);
      _shake.forward(from: 0);
      _say('already');
      return;
    }
    _markFound(word);
  }

  void _markFound(String word) {
    setState(() {
      _found.add(word);
      _foundOrder.add(word);
    });
    _flash(word, _okGreen);
    _audio.playSfx('assets/audios/QuizGame_Sounds/correct.mp3');
    HapticFeedback.lightImpact();
    _speak(word);
    if (_remaining == 0) {
      _onWin();
    } else {
      _say(_remaining == 1 ? 'oneMore' : 'great');
    }
  }

  // ── buttons ──────────────────────────────────────────────────────────────

  void _shuffle() {
    if (_won) return;
    _audio.playEventSound('clickButton2');
    final next = List<int>.of(_slotOf);
    if (next.length > 1) {
      do {
        next.shuffle();
      } while (_sameOrder(next, _slotOf));
    }
    setState(() => _slotOf = next);
    _spin.forward(from: 0);
  }

  static bool _sameOrder(List<int> a, List<int> b) {
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _hint() {
    if (_won) return;
    WlWord? target;
    for (final w in _open) {
      if (w.cells.any((c) => !_visible(c))) {
        target = w;
        break;
      }
    }
    if (target == null) return;
    if (_xp.gold < _hintCost) {
      _audio.playEventSound('invalid');
      _say('needGold');
      return;
    }
    _xp.spendGold(context, _hintCost);
    _audio.playEventSound('clickButton2');
    final cell = target.cells.firstWhere((c) => !_visible(c));
    setState(() {
      _revealed.add(cell);
      _hintsUsed++;
    });
    _say('hintMsg');
    // a word whose letters are now all showing counts as found
    for (final w in _level.words) {
      if (!_found.contains(w.text) && w.cells.every(_visible)) _markFound(w.text);
    }
  }

  void _hear() {
    final w = _nextWord;
    if (w == null || _won) return;
    _audio.playEventSound('clickButton2');
    _speak(w.text);
    _say('listen');
  }

  Future<void> _onWin() async {
    if (_won) return;
    setState(() => _won = true);
    final stars = _hintsUsed == 0 ? 3 : _hintsUsed == 1 ? 2 : 1;
    final nextIdx = _levelIdx + 1;
    WlStore.setLevel(_lang, nextIdx);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    _confetti.play();
    _audio.playSfx('assets/audios/UI_Audio/SFX_Audio/victory2_SFX.mp3');
    _xp.addGold(context, _winGold);
    _xp.addXP(10, context: context);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: KidColors.purpleDeep.withOpacity(0.35),
      builder: (ctx) => KidDialog(
        headerAsset: _imgRobot,
        headerAspect: 392 / 318,
        title: wlText(ctx, 'win'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (int i = 0; i < 3; i++)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 500 + 220 * i),
                curve: Curves.elasticOut,
                builder: (_, v, c) => Transform.scale(scale: v, child: c),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Image.asset(i < stars ? _imgStarOn : _imgStarOff, width: i == 1 ? 58 : 46, height: i == 1 ? 58 : 46),
                ),
              ),
          ]),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Image.asset(kidCoinAsset, width: 28, height: 28),
            const SizedBox(width: 6),
            Text('+$_winGold', style: kidBodyStyle(20, color: _ink, weight: FontWeight.w700)),
          ]),
        ]),
        actions: [
          KidButton(
            label: wlText(ctx, 'next'),
            onPressed: () => Navigator.pop(ctx),
            width: double.infinity,
            height: 54,
            showArrow: true,
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() {
      _levelIdx = nextIdx;
      _startLevel();
    });
  }

  Future<void> _openSettings() async {
    _audio.playEventSound('clickButton2');
    final choice = await showDialog<String>(
      context: context,
      barrierColor: KidColors.purpleDeep.withOpacity(0.35),
      builder: (ctx) => KidDialog(
        title: wlText(ctx, 'settings'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(wlText(ctx, 'wordsIn'), style: kidBodyStyle(16, color: _ink, weight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(children: [
            for (final l in wlWordLangs)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: KidPressable(
                    onTap: () => Navigator.pop(ctx, l),
                    child: Container(
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: l == _lang ? const Color(0xFFE3F7FF) : kidCardCream,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: l == _lang ? const Color(0xFF19C2C9) : KidColors.lavender, width: 2.5),
                      ),
                      child: Text(l == 'fr' ? 'Français' : 'English',
                          style: kidBodyStyle(17, color: _ink, weight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 14),
          KidOutlineButton(label: wlText(ctx, 'restart'), onTap: () => Navigator.pop(ctx, 'restart')),
        ]),
        actions: [
          KidButton(
            label: wlText(ctx, 'close'),
            onPressed: () => Navigator.pop(ctx),
            width: double.infinity,
            height: 52,
            showArrow: false,
          ),
        ],
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'restart') {
      setState(_startLevel);
      return;
    }
    if (choice == _lang) return;
    _lang = choice;
    await WlStore.setLang(choice);
    _levelIdx = await WlStore.level(choice);
    await _setTtsLang();
    if (!mounted) return;
    setState(_startLevel);
  }

  // ── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final xp = context.watch<ExperienceManager>();
    final showAd = xp.adsEnabled && _banner != null && _bannerLoaded;
    return Scaffold(
      backgroundColor: KidColors.sky,
      body: Stack(children: [
        const Positioned.fill(child: KidPageBackground(asset: _imgBg, wash: 0)),
        SafeArea(
          bottom: !showAd,
          child: !_ready
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : LayoutBuilder(builder: (context, c) => _layout(c, xp)),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 30,
            emissionFrequency: 0.06,
            gravity: 0.25,
            colors: const [Color(0xFF19C2C9), Color(0xFF3CC85A), Color(0xFFFFC21A), Color(0xFFFF5FA8), Color(0xFF7B3FE4)],
          ),
        ),
      ]),
      bottomNavigationBar: showAd
          ? SafeArea(
              child: SizedBox(
                height: _banner!.size.height.toDouble(),
                width: _banner!.size.width.toDouble(),
                child: FamilyAdBanner(bannerAd: _banner, isLoaded: _bannerLoaded),
              ),
            )
          : null,
    );
  }

  /// Every block is sized from the real screen: the wheel and the board share
  /// whatever height is left, so short phones, tall phones and tablets all fit.
  Widget _layout(BoxConstraints c, ExperienceManager xp) {
    final w = min(c.maxWidth, 600.0) - 24;
    final h = c.maxHeight;
    final s = min(w / 380, h / 760).clamp(0.68, 1.35).toDouble();
    final tall = h / s > 720;
    final headerH = 54 * s, levelH = 40 * s, pillH = 46 * s, btnH = 62 * s, footH = tall ? 30 * s : 0.0;
    final gaps = (6 + 8 + 8 + 6 + 2 + 12 + 8) * s;
    final rest = h - headerH - levelH - pillH - btnH - footH - gaps;
    final wheelD = (rest * 0.47).clamp(140 * s, min(w * 0.76, 300 * s)).toDouble();
    Widget step(int i, Widget child) =>
        KidIntro(intro: _intro, from: 0.06 * i, to: min(1.0, 0.5 + 0.06 * i), rise: 20, child: child);

    return Center(
      child: SizedBox(
        width: w,
        child: Column(children: [
          SizedBox(height: 6 * s),
          step(0, SizedBox(height: headerH, child: _header(s, xp))),
          SizedBox(height: 8 * s),
          step(1, SizedBox(height: levelH, child: _levelBar(s))),
          SizedBox(height: 8 * s),
          Expanded(child: step(2, _boardArea(s))),
          SizedBox(height: 6 * s),
          step(3, SizedBox(height: pillH, child: _wordPill(s, pillH))),
          SizedBox(height: 2 * s),
          step(3, SizedBox(width: wheelD, height: wheelD, child: _wheel(wheelD))),
          SizedBox(height: 12 * s),
          step(4, SizedBox(height: btnH, child: _buttons(s))),
          if (tall) step(5, SizedBox(height: footH, child: _footer(s))),
          SizedBox(height: 8 * s),
        ]),
      ),
    );
  }

  BoxDecoration _pill(double r, {Color color = const Color(0xFFFFF4E0)}) => BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: const Color(0xFFF3DDB5), width: 2),
        boxShadow: [BoxShadow(color: KidColors.purpleDeep.withOpacity(0.18), blurRadius: 10, offset: const Offset(0, 4))],
      );

  Widget _header(double s, ExperienceManager xp) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    Widget num(int v) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
          child: Text('$v', key: ValueKey(v), style: kidBodyStyle(17 * s, color: _ink, weight: FontWeight.w700)),
        );
    return Row(children: [
      KidPressable(
        onTap: () {
          _audio.playEventSound('cancelButton');
          Navigator.of(context).maybePop();
        },
        semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
        child: Transform.flip(flipX: rtl, child: Image.asset(_imgBack, width: 48 * s, height: 48 * s * 127 / 125)),
      ),
      SizedBox(width: 8 * s),
      Expanded(
        child: Container(
          height: 48 * s,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 12 * s),
          decoration: _pill(26 * s),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(wlText(context, 'title'), maxLines: 1, style: kidTitleStyle(28 * s, color: _ink).copyWith(shadows: const [])),
          ),
        ),
      ),
      SizedBox(width: 8 * s),
      Container(
        height: 44 * s,
        padding: EdgeInsetsDirectional.fromSTEB(4 * s, 0, 12 * s, 0),
        decoration: _pill(24 * s),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Image.asset(kidCoinAsset, width: 34 * s, height: 34 * s),
          SizedBox(width: 3 * s),
          num(xp.gold),
          SizedBox(width: 10 * s),
          Image.asset(kidGemAsset, width: 30 * s, height: 30 * s),
          SizedBox(width: 3 * s),
          num(xp.gems),
        ]),
      ),
      SizedBox(width: 8 * s),
      KidPressable(
        onTap: _openSettings,
        semanticLabel: wlText(context, 'settings'),
        child: Image.asset(_imgGear, width: 46 * s, height: 46 * s * 112 / 109),
      ),
    ]);
  }

  Widget _levelBar(double s) {
    final total = _level.words.length;
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: 330 * s),
        padding: EdgeInsets.symmetric(horizontal: 16 * s),
        decoration: _pill(22 * s),
        child: Row(children: [
          Text(wlText(context, 'level').replaceAll('{N}', '${_levelIdx + 1}'),
              style: kidBodyStyle(17 * s, color: _ink, weight: FontWeight.w700)),
          SizedBox(width: 12 * s),
          Expanded(child: _StarBar(value: _found.length / total, s: s)),
        ]),
      ),
    );
  }

  /// The cat peeks over the board, the robot stands on its corner and talks.
  Widget _boardArea(double s) => LayoutBuilder(builder: (context, c) {
        final bw = c.maxWidth;
        final catW = min(118 * s, bw * 0.34);
        final catH = catW * 233 / 337;
        final top = catH - 2 * s;
        final robotH = min(100 * s, catH * 1.22);
        final robotW = robotH * 318 / 392;
        return Stack(clipBehavior: Clip.none, children: [
          Positioned(left: 0, right: 0, top: top, bottom: 0, child: _board(s)),
          PositionedDirectional(
            start: bw * 0.05,
            top: 0,
            width: catW,
            height: catH,
            child: IgnorePointer(child: Image.asset(_imgCat, fit: BoxFit.fill)),
          ),
          PositionedDirectional(
            end: -4 * s,
            top: top - robotH + 8 * s,
            width: robotW,
            height: robotH,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _idle,
                builder: (_, ch) => Transform.translate(offset: Offset(0, sin(_idle.value * 4 * pi) * 3 * s), child: ch),
                child: Image.asset(_imgRobot, fit: BoxFit.contain),
              ),
            ),
          ),
          PositionedDirectional(
            start: bw * 0.05 + catW + 2 * s,
            end: robotW - 10 * s,
            top: -4 * s,
            height: top - 2 * s,
            child: _bubble(s),
          ),
        ]);
      });

  Widget _bubble(double s) => LayoutBuilder(builder: (context, c) {
        var text = wlText(context, _bubbleKey);
        if (_bubbleKey == 'needGold') text = text.replaceAll('{C}', '$_hintCost');
        return Stack(fit: StackFit.expand, children: [
          Image.asset(_imgBubble, fit: BoxFit.fill),
          Padding(
            padding: EdgeInsets.fromLTRB(c.maxWidth * 0.09, c.maxHeight * 0.08, c.maxWidth * 0.09, c.maxHeight * 0.3),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (ch, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: ch),
                child: Text(
                  text,
                  key: ValueKey(_bubbleTick),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: kidBodyStyle(min(15 * s, c.maxHeight * 0.2), color: _ink, weight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ]);
      });

  Widget _board(double s) {
    final total = _level.words.length;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF6E7), Color(0xFFFCE9CB)],
        ),
        borderRadius: BorderRadius.circular(26 * s),
        border: Border.all(color: const Color(0xFFF1D6A4), width: 3 * s),
        boxShadow: [
          BoxShadow(color: KidColors.purpleDeep.withOpacity(0.22), blurRadius: 18, offset: const Offset(0, 6)),
        ],
      ),
      padding: EdgeInsets.fromLTRB(12 * s, 14 * s, 12 * s, 10 * s),
      child: Column(children: [
        Expanded(child: Directionality(textDirection: TextDirection.ltr, child: _grid(s))),
        SizedBox(height: 6 * s),
        Container(
          height: 30 * s,
          padding: EdgeInsets.symmetric(horizontal: 18 * s),
          decoration: BoxDecoration(
            color: const Color(0xFFF8E6C6),
            borderRadius: BorderRadius.circular(16 * s),
            border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.5),
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              wlText(context, 'found').replaceAll('{F}', '${_found.length}').replaceAll('{T}', '$total'),
              style: kidBodyStyle(14 * s, color: _ink, weight: FontWeight.w700),
            ),
          ),
        ),
      ]),
    );
  }

  /// The crossword, scaled so the largest grid still fits the board.
  Widget _grid(double s) => LayoutBuilder(builder: (context, c) {
        const gap = 0.1; // of a tile
        final cols = _level.cols, rows = _level.rows;
        final t = min(
          min(c.maxWidth / (cols + (cols - 1) * gap), c.maxHeight / (rows + (rows - 1) * gap)),
          62 * s,
        );
        final stepPx = t * (1 + gap);
        final gw = t * cols + t * gap * (cols - 1);
        final gh = t * rows + t * gap * (rows - 1);
        final next = _nextWord?.cells.toSet() ?? const <int>{};
        return Center(
          child: SizedBox(
            width: gw,
            height: gh,
            child: Stack(children: [
              for (final e in _solution.entries)
                Positioned(
                  left: (e.key % 16) * stepPx,
                  top: (e.key ~/ 16) * stepPx,
                  width: t,
                  height: t,
                  child: _tile(e.key, e.value, t, next.contains(e.key)),
                ),
            ]),
          ),
        );
      });

  Widget _tile(int cell, String ch, double t, bool highlight) {
    // which found word coloured this cell first (keeps crossings stable)
    int owner = -1;
    WlWord? ownerWord;
    for (int i = 0; i < _foundOrder.length; i++) {
      final w = _level.words.firstWhere((x) => x.text == _foundOrder[i]);
      if (w.cells.contains(cell)) {
        owner = i;
        ownerWord = w;
        break;
      }
    }
    if (owner >= 0) {
      final k = ownerWord!.cells.indexOf(cell);
      final ms = 450 + 90 * k;
      return TweenAnimationBuilder<double>(
        key: ValueKey('f$cell-${ownerWord.text}'),
        tween: Tween(begin: 0.3, end: 1),
        duration: Duration(milliseconds: ms),
        curve: Interval(90 * k / ms, 1, curve: Curves.elasticOut),
        builder: (_, v, child) => Transform.scale(scale: v, child: child),
        child: _letterTile(owner.isEven ? _imgTeal : _imgGreen, ch, t),
      );
    }
    final revealed = _revealed.contains(cell);
    return Stack(fit: StackFit.expand, children: [
      Image.asset(highlight ? _imgSlotHl : _imgSlot, fit: BoxFit.fill),
      if (revealed)
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 420),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Text(ch,
                style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w700,
                    fontSize: t * 0.52,
                    height: 1,
                    color: KidColors.purpleDeep.withOpacity(0.7))),
          ),
        ),
    ]);
  }

  Widget _letterTile(String img, String ch, double t) => Stack(fit: StackFit.expand, children: [
        Image.asset(img, fit: BoxFit.fill),
        Padding(
          padding: EdgeInsets.only(bottom: t * 0.06),
          child: Center(
            child: Text(ch,
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w700,
                  fontSize: t * 0.56,
                  height: 1,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black.withOpacity(0.28), offset: Offset(0, t * 0.03), blurRadius: t * 0.05)],
                )),
          ),
        ),
      ]);

  /// The word being spelled (or the last one tried, coloured by the result).
  Widget _wordPill(double s, double pillH) {
    final building = _path.isNotEmpty;
    final text = building ? _path.map((id) => _chars[id]).join() : (_flashWord ?? '');
    final color = building ? _ink : _flashColor;
    return AnimatedBuilder(
      animation: _shake,
      builder: (_, child) => Transform.translate(
        offset: Offset(sin(_shake.value * pi * 6) * 10 * s * (1 - _shake.value), 0),
        child: child,
      ),
      child: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: text.isEmpty ? 0 : 1,
          child: Container(
            height: pillH,
            constraints: BoxConstraints(minWidth: 120 * s),
            padding: EdgeInsets.symmetric(horizontal: 26 * s),
            decoration: _pill(24 * s, color: building ? const Color(0xFFFFF4E0) : Colors.white),
            alignment: Alignment.center,
            child: Text(text.isEmpty ? ' ' : text,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w700,
                    fontSize: 30 * s,
                    letterSpacing: 2 * s,
                    height: 1,
                    color: color)),
          ),
        ),
      ),
    );
  }

  Widget _wheel(double d) {
    final n = _chars.length;
    final letterSize = d * (n <= 3 ? 0.30 : n == 4 ? 0.29 : n == 5 ? 0.27 : 0.25);
    final ring = d / 2 - letterSize / 2 - d * 0.055;
    final center = Offset(d / 2, d / 2);
    _letterR = letterSize / 2;
    _centers = [
      for (int i = 0; i < n; i++) center + Offset(cos(-pi / 2 + 2 * pi * i / n), sin(-pi / 2 + 2 * pi * i / n)) * ring,
    ];
    final shuffleSize = d * 0.24;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _down,
        onPointerMove: _move,
        onPointerUp: _up,
        onPointerCancel: _up,
        child: Stack(clipBehavior: Clip.none, children: [
          // the purple disc
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(-0.25, -0.35),
                  radius: 0.95,
                  colors: [Color(0xFF7E63FF), Color(0xFF5636E0), Color(0xFF3F22B8)],
                  stops: [0, 0.6, 1],
                ),
                border: Border.all(color: const Color(0xFF9473FF), width: d * 0.025),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF2A1380).withOpacity(0.45), blurRadius: 20, offset: const Offset(0, 8)),
                  BoxShadow(color: const Color(0xFF9C7CFF).withOpacity(0.45), blurRadius: 24, spreadRadius: 2),
                ],
              ),
            ),
          ),
          // glowing link
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _LinkPainter(
                  points: [for (final id in _path) _centers[_slotOf[id]]],
                  finger: _finger,
                  width: letterSize * 0.2,
                ),
              ),
            ),
          ),
          // letters (slide to their new place on shuffle)
          for (int id = 0; id < n; id++)
            AnimatedPositioned(
              key: ValueKey('l$id'),
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeInOutBack,
              left: _centers[_slotOf[id]].dx - letterSize / 2,
              top: _centers[_slotOf[id]].dy - letterSize / 2,
              width: letterSize,
              height: letterSize,
              child: IgnorePointer(child: _wheelLetter(id, letterSize)),
            ),
          // shuffle
          Positioned(
            left: center.dx - shuffleSize / 2,
            top: center.dy - shuffleSize / 2,
            width: shuffleSize,
            height: shuffleSize,
            child: KidPressable(
              onTap: _shuffle,
              child: AnimatedBuilder(
                animation: _spin,
                builder: (_, ch) => Transform.rotate(angle: Curves.easeOutBack.transform(_spin.value) * pi, child: ch),
                child: Image.asset(_imgShuffle, fit: BoxFit.contain),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _wheelLetter(int id, double size) {
    final on = _path.contains(id);
    return AnimatedScale(
      scale: on ? 1.1 : 1,
      duration: const Duration(milliseconds: 120),
      child: Stack(fit: StackFit.expand, children: [
        Image.asset(_imgLetter, fit: BoxFit.contain),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          opacity: on ? 1 : 0,
          child: Padding(
            padding: EdgeInsets.all(size * 0.04),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2FE3F0), width: size * 0.06),
                boxShadow: [BoxShadow(color: const Color(0xFF2FE3F0).withOpacity(0.6), blurRadius: size * 0.25)],
              ),
            ),
          ),
        ),
        Center(
          child: Text(_chars[id],
              style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w700, fontSize: size * 0.5, height: 1, color: _ink)),
        ),
      ]),
    );
  }

  Widget _buttons(double s) => Row(children: [
        Expanded(
          child: _YellowButton(
            s: s,
            icon: _imgBulb,
            iconAspect: 112 / 75,
            label: wlText(context, 'hint'),
            sub: Row(mainAxisSize: MainAxisSize.min, children: [
              Image.asset(kidCoinAsset, width: 18 * s, height: 18 * s),
              SizedBox(width: 3 * s),
              Text('$_hintCost', style: kidBodyStyle(15 * s, color: _ink, weight: FontWeight.w700)),
            ]),
            onTap: _hint,
          ),
        ),
        SizedBox(width: 12 * s),
        Expanded(
          child: _YellowButton(
            s: s,
            icon: _imgSpeaker,
            iconAspect: 94 / 104,
            label: wlText(context, 'hear'),
            onTap: _hear,
          ),
        ),
      ]);

  Widget _footer(double s) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Image.asset(_imgSprout, height: 24 * s, width: 24 * s * 84 / 135),
        SizedBox(width: 8 * s),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(wlText(context, 'footer'),
                maxLines: 1,
                style: kidBodyStyle(15 * s, color: _ink, weight: FontWeight.w700).copyWith(shadows: [
                  Shadow(color: Colors.white.withOpacity(0.95), blurRadius: 6),
                  Shadow(color: Colors.white.withOpacity(0.7), blurRadius: 12),
                ])),
          ),
        ),
        SizedBox(width: 8 * s),
        Image.asset(_imgSprout, height: 24 * s, width: 24 * s * 84 / 135),
      ]);
}

/// Thin golden bar with three stars that light up as words are found.
class _StarBar extends StatelessWidget {
  final double value;
  final double s;
  const _StarBar({required this.value, required this.s});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final bw = c.maxWidth;
        final star = 24 * s;
        final track = 14 * s;
        return SizedBox(
          height: star,
          child: Stack(clipBehavior: Clip.none, alignment: Alignment.centerLeft, children: [
            Container(
              height: track,
              decoration: BoxDecoration(color: const Color(0xFFDCCFB8), borderRadius: BorderRadius.circular(track)),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              height: track,
              width: max(track, bw * value.clamp(0.0, 1.0)),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(track),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: value > 0
                      ? const [Color(0xFFFFE066), Color(0xFFFFB21A)]
                      : const [Color(0x00FFE066), Color(0x00FFB21A)],
                ),
              ),
            ),
            for (int k = 1; k <= 3; k++)
              Positioned(
                left: (bw * k / 3 - star * (k == 3 ? 1.0 : 0.5)).clamp(0.0, bw - star),
                top: 0,
                child: AnimatedScale(
                  scale: value >= k / 3 - 0.001 ? 1.15 : 1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  child: Image.asset(value >= k / 3 - 0.001 ? _imgStarOn : _imgStarOff, width: star, height: star),
                ),
              ),
          ]),
        );
      });
}

/// Glossy yellow pill with an icon (Hint / Hear).
class _YellowButton extends StatelessWidget {
  final double s;
  final String icon;
  final double iconAspect; // height / width
  final String label;
  final Widget? sub;
  final VoidCallback onTap;
  const _YellowButton({
    required this.s,
    required this.icon,
    required this.iconAspect,
    required this.label,
    this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => KidPressable(
        onTap: onTap,
        semanticLabel: label,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30 * s),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFE36E), Color(0xFFFFC21A), Color(0xFFFFAD0A)],
              stops: [0, 0.55, 1],
            ),
            border: Border.all(color: const Color(0xFFFFF1B8), width: 2.5 * s),
            boxShadow: [
              BoxShadow(color: const Color(0xFFD98A00), offset: Offset(0, 4 * s)),
              BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 10, offset: Offset(0, 6 * s)),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: 14 * s),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Image.asset(icon, height: 40 * s, width: 40 * s / iconAspect),
            SizedBox(width: 10 * s),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(label, maxLines: 1, style: kidTitleStyle(22 * s, color: _ink).copyWith(shadows: const [])),
                  if (sub != null) sub!,
                ]),
              ),
            ),
          ]),
        ),
      );
}

/// Glowing cyan line through the chosen letters, ending at the finger.
class _LinkPainter extends CustomPainter {
  final List<Offset> points;
  final Offset? finger;
  final double width;
  _LinkPainter({required this.points, required this.finger, required this.width});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    if (finger != null) path.lineTo(finger!.dx, finger!.dy);
    Paint stroke(Color c, double w) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, stroke(const Color(0xFF22E4FF).withOpacity(0.5), width * 2.4)..maskFilter = MaskFilter.blur(BlurStyle.normal, width));
    canvas.drawPath(path, stroke(const Color(0xFF7FF3FF), width));
    canvas.drawPath(path, stroke(Colors.white.withOpacity(0.9), width * 0.35));
  }

  @override
  bool shouldRepaint(covariant _LinkPainter old) => true;
}
