import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../../../XpSystem.dart';
import '../../../tools/Ads_Manager.dart';
import '../../../tools/audio_tool/Audio_Manager.dart';
import '../../../widgets/KidScene/kid_page_parts.dart';
import '../../../widgets/KidScene/kid_scene.dart';
import '../ModeSelectorPage.dart';
import 'quiz_magic_data.dart';
import 'quiz_magic_results.dart';
import 'quiz_magic_widgets.dart';

/// Solo "Quiz magique": 10 picture questions, a friendly robot, no timer.
class QuizMagicPage extends StatefulWidget {
  final QuizLanguage language;
  final String theme;
  const QuizMagicPage({super.key, required this.language, this.theme = 'surprise'});

  @override
  State<QuizMagicPage> createState() => _QuizMagicPageState();
}

class _QuizMagicPageState extends State<QuizMagicPage> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  late final AnimationController _pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  final ConfettiController _confetti = ConfettiController(duration: const Duration(milliseconds: 450));
  final FlutterTts _tts = FlutterTts();

  int _streak = 0;
  int _bestStreak = 0;
  bool _hintUsed = false;
  final Set<int> _hidden = {};

  List<QmItem> _items = const [];
  int _index = 0;
  bool _ready = false;
  bool _feedback = false;
  bool _voice = true;
  bool _precached = false;

  BannerAd? _banner;
  bool _bannerLoaded = false;

  String get _ui => qmUiLang(widget.language);
  bool get _isAr => widget.language == QuizLanguage.arabic;
  bool get _canSpeak => widget.language != QuizLanguage.amazigh;
  QmItem get _item => _items[_index];
  int get _good => _items.where((i) => i.answered && i.correct).length;
  AudioManager get _audio => Provider.of<AudioManager>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _banner = AdHelper.getBannerAd(() {
      if (mounted) setState(() => _bannerLoaded = true);
    });
    _start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    KidAssets.precache(context, qmAllImages);
  }

  Future<void> _start() async {
    await QmPrefs.init();
    _voice = QmPrefs.voice;
    await QmAssets.load();
    await _setupTts();
    if (!mounted) return;
    setState(() {
      _items = qmBuildRound(widget.language, theme: widget.theme);
      _ready = true;
    });
    _intro.forward(from: 0);
    if (_items.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted && _voice) _readQuestion();
      });
    }
  }

  Future<void> _setupTts() async {
    if (!_canSpeak) return;
    try {
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.05);
      const codes = {'en': 'en-US', 'fr': 'fr-FR', 'ar': 'ar-SA', 'de': 'de-DE', 'es': 'es-ES'};
      await _tts.setLanguage(codes[qmLang(widget.language)] ?? 'fr-FR');
    } catch (_) {}
  }

  @override
  void dispose() {
    _tts.stop();
    _intro.dispose();
    _idle.dispose();
    _shake.dispose();
    _pop.dispose();
    _confetti.dispose();
    _banner?.dispose();
    super.dispose();
  }

  // ── voice ────────────────────────────────────────────────────────────────

  Future<void> _readQuestion() async {
    if (!_ready || _items.isEmpty || !_canSpeak) return;
    await _tts.stop();
    if (_isAr) {
      _audio.playAlert('assets/audios/tts_female/arabic_Questions_QuizzGame/qst${_item.question.id}.mp3');
      return;
    }
    final letters = qmLetters(_ui);
    final q = _item.question;
    final b = StringBuffer(q.questionText);
    for (var i = 0; i < q.options.length && i < letters.length; i++) {
      b.write('  ${letters[i]}, ${q.options[i]}.');
    }
    try {
      await _tts.speak(b.toString());
    } catch (_) {}
  }

  Future<void> _say(String text) async {
    if (!_canSpeak) return;
    await _tts.stop();
    try {
      await _tts.speak(text);
    } catch (_) {}
  }

  // ── game flow ────────────────────────────────────────────────────────────

  void _pick(int i) {
    if (_feedback || _item.answered) return;
    _tts.stop();
    setState(() {
      _item.picked = i;
      _feedback = true;
    });
    if (_item.correct) {
      _streak++;
      _bestStreak = max(_bestStreak, _streak);
      _confetti.play();
      _pop.forward(from: 0);
      _audio.playSfx('assets/audios/UI_Audio/SFX_Audio/CorrectAnwser_SFX.mp3');
      if (_streak >= 3) _audio.playEventSound('starSound');
    } else {
      _streak = 0;
      _shake.forward(from: 0);
      _audio.playSfx('assets/audios/UI_Audio/SFX_Audio/WrongAnwser_SFX.mp3');
    }
  }

  /// Hint joker (once per round): hides wrong answers, keeps the right one + one other.
  void _useHint() {
    if (_hintUsed || _feedback) return;
    final q = _item.question;
    if (q.options.length <= 2) return;
    final wrong = [for (var i = 0; i < q.options.length; i++) if (i != q.correctIndex) i]..shuffle();
    setState(() {
      _hintUsed = true;
      _hidden.addAll(wrong.skip(1));
    });
    _audio.playEventSound('starSound');
  }

  String _cheer() {
    if (_streak >= 5) return qmText(_ui, 'genius');
    if (_streak >= 3) return qmText(_ui, 'onFire');
    const k = ['bravo', 'great', 'champion'];
    return qmText(_ui, k[_index % k.length]);
  }

  void _next() {
    _tts.stop();
    _audio.playEventSound('clickButton');
    if (_index + 1 >= _items.length) {
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => QuizMagicResultsPage(language: widget.language, items: _items, theme: widget.theme, bestStreak: _bestStreak),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      ));
      return;
    }
    setState(() {
      _index++;
      _feedback = false;
      _hidden.clear();
    });
    if (_voice) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) _readQuestion();
      });
    }
  }

  Future<void> _openSettings() async {
    _audio.playEventSound('clickButton');
    await qmOpenSettings(context, language: widget.language, onVoice: (v) {
      setState(() => _voice = v);
      if (!v) _tts.stop();
    });
  }

  // ── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final xp = context.watch<ExperienceManager>();
    final showAd = xp.adsEnabled && _banner != null && _bannerLoaded;
    return Directionality(
      textDirection: _isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: KidColors.sky,
        body: Stack(children: [
          const Positioned.fill(child: KidPageBackground(asset: qmImgBg, wash: 0)),
          SafeArea(
            bottom: !showAd,
            child: !_ready
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : LayoutBuilder(builder: (context, c) => _layout(c)),
          ),
          Align(
            alignment: const Alignment(0, 0.15),
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 16,
              emissionFrequency: 0.5,
              maxBlastForce: 22,
              minBlastForce: 8,
              gravity: 0.3,
              colors: const [Color(0xFF2FE3F0), Color(0xFF3CC85A), Color(0xFFFFC21A), Color(0xFFFF5FA8), Color(0xFF7B3FE4)],
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
      ),
    );
  }

  Widget _layout(BoxConstraints c) {
    final w = min(c.maxWidth, 560.0);
    final h = c.maxHeight;
    final s = min(w / 380, h / 790).clamp(0.66, 1.35).toDouble();
    Widget step(int i, Widget child) =>
        KidIntro(intro: _intro, from: 0.08 * i, to: min(1.0, 0.45 + 0.08 * i), rise: 18, child: child);

    if (_items.isEmpty) {
      return Column(children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12 * s),
          child: QmTopBar(scale: s, title: qmText(_ui, 'title'), onBack: () => Navigator.of(context).pop()),
        ),
      ]);
    }

    final item = _item;
    final q = item.question;
    final cat = qmCategory(item.category);
    final letters = qmLetters(_ui);
    final mood = !_feedback ? QmMood.idle : (item.correct ? QmMood.happy : QmMood.sad);
    final bubble = !_feedback ? qmText(_ui, 'yourTurn') : (item.correct ? _cheer() : qmText(_ui, 'learn'));

    return Stack(children: [
      // flowers in the corners
      PositionedDirectional(start: -10 * s, bottom: -6 * s, child: IgnorePointer(child: Image.asset(qmImgBush1, width: 110 * s))),
      PositionedDirectional(end: -8 * s, bottom: -6 * s, child: IgnorePointer(child: Image.asset(qmImgFlowers, width: 100 * s))),
      Center(
        child: SizedBox(
          width: w,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12 * s),
            child: Column(children: [
              step(0, QmTopBar(
                scale: s,
                title: qmText(_ui, 'title'),
                onBack: () {
                  _audio.playEventSound('cancelButton');
                  Navigator.of(context).pop();
                },
                onGear: _openSettings,
              )),
              SizedBox(height: 4 * s),
              step(1, QmProgress(
                scale: s,
                label: '${qmText(_ui, 'question')} ${_index + 1} / ${_items.length}',
                value: (_index + (_feedback ? 1 : 0)) / _items.length,
                stars: qmStars(_good, _items.length),
              )),
              SizedBox(height: 6 * s),
              step(1, _historyDots(s)),
              SizedBox(height: 2 * s),
              step(2, SizedBox(
                height: 100 * s,
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Flexible(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 8 * s),
                      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: QmCategoryPill(key: ValueKey(cat.id), scale: s, category: cat, lang: _ui, height: 36),
                        ),
                        SizedBox(height: 6 * s),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          _hintChip(s),
                          SizedBox(width: 6 * s),
                          Flexible(child: _streakChip(s)),
                        ]),
                      ]),
                    ),
                  ),
                  SizedBox(width: 6 * s),
                  QmRobot(scale: s, mood: mood, bubble: bubble, idle: _idle),
                ]),
              )),
              step(3, Transform.translate(
                offset: Offset(0, -4 * s),
                child: QmQuestionCard(
                  scale: s,
                  text: q.questionText,
                  onSpeak: _canSpeak ? _readQuestion : null,
                ),
              )),
              SizedBox(height: 8 * s),
              Expanded(
                child: step(4, LayoutBuilder(builder: (context, gc) {
                  final n = q.options.length;
                  final cols = n <= 2 ? n : 2;
                  final rows = (n / cols).ceil();
                  final gap = 12 * s;
                  final tileW = (gc.maxWidth - gap * (cols - 1)) / cols;
                  final tileH = min((gc.maxHeight - gap * (rows - 1) - 6 * s) / rows, tileW * 1.12);
                  return AnimatedBuilder(
                    animation: _shake,
                    builder: (_, ch) => Transform.translate(
                      offset: Offset(sin(_shake.value * pi * 6) * 10 * s * (1 - _shake.value), 0),
                      child: ch,
                    ),
                    child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
                    Align(
                    alignment: Alignment.topCenter,
                    child: Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      alignment: WrapAlignment.center,
                      children: [
                        for (var i = 0; i < n; i++)
                          SizedBox(
                            width: tileW,
                            height: max(60.0, tileH),
                            child: QmAnswerTile(
                              key: ValueKey('${_index}_$i'),
                              scale: s,
                              letter: i < letters.length ? letters[i] : '${i + 1}',
                              text: q.options[i],
                              artKey: item.keys[i],
                              state: _tileState(item, i),
                              hidden: _hidden.contains(i) && !_feedback,
                              onTap: _feedback ? null : () => _pick(i),
                            ),
                          ),
                      ],
                    ),
                  ),
                    _popReward(s),
                  ]),
                  );
                })),
              ),
              SizedBox(height: 8 * s),
            ]),
          ),
        ),
      ),
      // feedback slides up from the bottom
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: IgnorePointer(
          ignoring: !_feedback,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 380),
            curve: _feedback ? Curves.easeOutBack : Curves.easeIn,
            offset: _feedback ? Offset.zero : const Offset(0, 1.2),
            child: Center(
              child: SizedBox(
                width: w,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(14 * s, 0, 14 * s, 10 * s),
                  child: _feedbackPanel(s, item),
                ),
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _historyDots(double s) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      for (var i = 0; i < _items.length; i++)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.5 * s),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: (i == _index ? 22 : 16) * s,
            height: 16 * s,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8 * s),
              color: !_items[i].answered
                  ? (i == _index ? Colors.white : Colors.white.withOpacity(0.55))
                  : (_items[i].correct ? qmGreen : qmRed),
              border: Border.all(color: i == _index ? qmPurple : Colors.white, width: 2 * s),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 3 * s, offset: Offset(0, 1.5 * s))],
            ),
            child: _items[i].answered
                ? Icon(_items[i].correct ? Icons.check_rounded : Icons.close_rounded, size: 11 * s, color: Colors.white)
                : null,
          ),
        ),
    ]);
  }

  Widget _hintChip(double s) {
    final can = !_hintUsed && !_feedback && _item.question.options.length > 2;
    return Opacity(
      opacity: _hintUsed ? 0.45 : 1,
      child: KidPressable(
        onTap: can ? _useHint : null,
        child: Container(
          height: 32 * s,
          padding: EdgeInsets.symmetric(horizontal: 10 * s),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18 * s),
            gradient: const LinearGradient(colors: [Color(0xFFFFE66D), Color(0xFFFFB81F)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            border: Border.all(color: Colors.white, width: 2 * s),
            boxShadow: [if (can) BoxShadow(color: const Color(0xFFFFB81F).withOpacity(0.6), blurRadius: 8 * s)],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.lightbulb_rounded, color: const Color(0xFF8A4B00), size: 18 * s),
            SizedBox(width: 4 * s),
            Text(qmText(_ui, 'hint'), style: qmTitle(14 * s, color: const Color(0xFF6A3500))),
          ]),
        ),
      ),
    );
  }

  Widget _streakChip(double s) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.elasticOut), child: c),
      child: _streak < 2
          ? const SizedBox.shrink()
          : Container(
              key: ValueKey(_streak),
              height: 32 * s,
              padding: EdgeInsets.symmetric(horizontal: 10 * s),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18 * s),
                gradient: const LinearGradient(colors: [Color(0xFFFF8A3D), Color(0xFFFF3D6E)]),
                border: Border.all(color: Colors.white, width: 2 * s),
                boxShadow: [BoxShadow(color: const Color(0xFFFF5A3D).withOpacity(0.55), blurRadius: 10 * s)],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('🔥', style: TextStyle(fontSize: 15 * s)),
                  SizedBox(width: 3 * s),
                  Text(qmText(_ui, 'streakN', a: '$_streak'), style: qmTitle(14 * s, color: Colors.white)),
                ]),
              ),
            ),
    );
  }

  /// Big "+1 ⭐" that pops over the answers on a right answer.
  Widget _popReward(double s) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _pop,
        builder: (_, __) {
          final t = _pop.value;
          if (t <= 0 || t >= 1) return const SizedBox.shrink();
          final scale = Curves.elasticOut.transform(min(1.0, t * 1.6));
          final fade = t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.3);
          return Opacity(
            opacity: fade.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, -40 * s * t),
              child: Transform.scale(
                scale: scale,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Image.asset(qmImgBigStar, width: 64 * s),
                  SizedBox(width: 6 * s),
                  QmOutlinedText('+1', size: 54 * s, stroke: const Color(0xFF6A1FB8), gradient: const [Color(0xFFFFF27A), Color(0xFFFFA51F)]),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }

  QmTileState _tileState(QmItem item, int i) {
    if (!item.answered) return QmTileState.idle;
    if (i == item.question.correctIndex) return QmTileState.correct;
    if (i == item.picked) return QmTileState.wrong;
    return QmTileState.faded;
  }

  Widget _feedbackPanel(double s, QmItem item) {
    final ok = item.answered && item.correct;
    final line = qmText(_ui, ok ? 'correctLine' : 'wrongLine', a: item.answerText);
    return QmFeedbackPanel(
      scale: s,
      correct: ok,
      title: qmText(_ui, ok ? 'correct' : 'wrong'),
      line: line,
      artKey: item.answerKey,
      answerText: item.answerText,
      continueLabel: qmText(_ui, 'continue'),
      onSpeak: _canSpeak ? () => _say(line) : null,
      onContinue: _next,
    );
  }
}
