import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

import '../../../tools/audio_tool/Audio_Manager.dart';
import '../../../widgets/KidScene/kid_page_parts.dart';
import '../../../widgets/KidScene/kid_scene.dart';
import '../ModeSelectorPage.dart';
import 'quiz_magic_data.dart';
import 'quiz_magic_duel_end.dart';
import 'quiz_magic_widgets.dart';

/// Duel 1 vs 1: two players (or a player and the robot) answer in turn.
class QuizMagicDuelPage extends StatefulWidget {
  final QuizLanguage language;
  final String theme;
  final List<QmPlayer> players; // exactly two
  final int robotLevel;
  final int choices;
  const QuizMagicDuelPage({
    super.key,
    required this.language,
    required this.theme,
    required this.players,
    required this.robotLevel,
    required this.choices,
  });

  @override
  State<QuizMagicDuelPage> createState() => _QuizMagicDuelPageState();
}

class _QuizMagicDuelPageState extends State<QuizMagicDuelPage> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  final FlutterTts _tts = FlutterTts();
  final Random _rnd = Random();

  List<QmItem> _items = const [];
  int _index = 0;
  int? _selected;
  bool _revealed = false;
  bool _ready = false;
  bool _voice = true;
  Timer? _robotTimer;
  Timer? _handoffTimer;
  bool _handoff = false; // big "whose turn" screen

  bool get _vsRobot => widget.players.any((p) => p.robot);
  static const List<Color> _pColors = [Color(0xFF29B6F6), Color(0xFFF06BC6)];
  static const List<Color> _pDeep = [Color(0xFF1C7FD8), Color(0xFFE0329C)];
  Color get _col => _pColors[_turn];

  String get _ui => qmUiLang(widget.language);
  bool get _isAr => widget.language == QuizLanguage.arabic;
  bool get _canSpeak => widget.language != QuizLanguage.amazigh;
  QmItem get _item => _items[_index];
  int get _turn => _index % 2;
  QmPlayer get _player => widget.players[_turn];
  AudioManager get _audio => Provider.of<AudioManager>(context, listen: false);

  int _score(int p) {
    var n = 0;
    for (var i = p; i < _items.length; i += 2) {
      if (_items[i].answered && _items[i].correct) n++;
    }
    return n;
  }

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await QmPrefs.init();
    _voice = QmPrefs.voice;
    await QmAssets.load();
    if (_canSpeak) {
      try {
        const codes = {'en': 'en-US', 'fr': 'fr-FR', 'ar': 'ar-SA', 'de': 'de-DE', 'es': 'es-ES'};
        await _tts.setSpeechRate(0.45);
        await _tts.setLanguage(codes[qmLang(widget.language)] ?? 'fr-FR');
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _items = qmBuildRound(widget.language, theme: widget.theme, choices: widget.choices);
      _ready = true;
    });
    _intro.forward(from: 0);
    _beginTurn();
  }

  @override
  void dispose() {
    _robotTimer?.cancel();
    _handoffTimer?.cancel();
    _tts.stop();
    _intro.dispose();
    _idle.dispose();
    super.dispose();
  }

  // ── turns ────────────────────────────────────────────────────────────────

  /// Every turn starts with a big screen showing whose turn it is.
  /// Two children: they tap "Je suis prêt !". Against the robot it goes by itself.
  void _beginTurn() {
    if (_items.isEmpty) return;
    _handoffTimer?.cancel();
    setState(() => _handoff = true);
    _audio.playEventSound('PopButton');
    if (_vsRobot) {
      _handoffTimer = Timer(Duration(milliseconds: _player.robot ? 1200 : 1400), _startTurn);
    }
  }

  void _startTurn() {
    _handoffTimer?.cancel();
    if (!mounted || !_handoff) return;
    setState(() => _handoff = false);
    if (_player.robot) {
      // the robot "thinks", picks, then checks its answer
      _robotTimer = Timer(Duration(milliseconds: 1300 + _rnd.nextInt(700)), () {
        if (!mounted) return;
        final q = _item.question;
        final right = _rnd.nextDouble() < qmRobotSkill[widget.robotLevel];
        int pick = q.correctIndex;
        if (!right && q.options.length > 1) {
          final wrong = [for (var i = 0; i < q.options.length; i++) if (i != q.correctIndex) i];
          pick = wrong[_rnd.nextInt(wrong.length)];
        }
        setState(() => _selected = pick);
        _audio.playEventSound('clickButton');
        _robotTimer = Timer(const Duration(milliseconds: 800), () {
          if (mounted) _validate();
        });
      });
    } else if (_voice) {
      Future.delayed(const Duration(milliseconds: 450), () {
        if (mounted && !_revealed) _readQuestion();
      });
    }
  }

  Future<void> _readQuestion() async {
    if (!_canSpeak || _items.isEmpty) return;
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

  void _select(int i) {
    if (_revealed || _player.robot) return;
    _audio.playEventSound('clickButton');
    setState(() => _selected = i);
  }

  void _validate() {
    if (_selected == null || _revealed) return;
    _tts.stop();
    setState(() {
      _item.picked = _selected;
      _revealed = true;
    });
    _audio.playSfx(_item.correct
        ? 'assets/audios/UI_Audio/SFX_Audio/CorrectAnwser_SFX.mp3'
        : 'assets/audios/UI_Audio/SFX_Audio/WrongAnwser_SFX.mp3');
  }

  void _next() {
    _audio.playEventSound('clickButton');
    if (_index + 1 >= _items.length) {
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => QuizMagicDuelEndPage(
          language: widget.language,
          theme: widget.theme,
          players: widget.players,
          robotLevel: widget.robotLevel,
          choices: widget.choices,
          items: _items,
        ),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      ));
      return;
    }
    setState(() {
      _index++;
      _selected = null;
      _revealed = false;
    });
    _beginTurn();
  }

  // ── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: KidColors.sky,
        body: Stack(children: [
          const Positioned.fill(child: KidPageBackground(asset: qmImgBg, wash: 0)),
          SafeArea(
            child: !_ready
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : LayoutBuilder(builder: (context, c) => _layout(c)),
          ),
        ]),
      ),
    );
  }

  Widget _layout(BoxConstraints c) {
    final w = min(c.maxWidth, 560.0);
    final h = c.maxHeight;
    final s = min(w / 380, h / 800).clamp(0.64, 1.3).toDouble();
    Widget step(int i, Widget child) =>
        KidIntro(intro: _intro, from: 0.07 * i, to: min(1.0, 0.45 + 0.07 * i), rise: 18, child: child);
    final back = QmTopBar(
      scale: s,
      title: qmText(_ui, 'title'),
      subtitle: qmText(_ui, 'duel1v1'),
      onBack: () {
        _audio.playEventSound('cancelButton');
        Navigator.of(context).pop();
      },
      onGear: () => qmOpenSettings(context, language: widget.language, onVoice: (v) {
        _voice = v;
        if (!v) _tts.stop();
      }),
    );
    if (_items.isEmpty) {
      return Padding(padding: EdgeInsets.symmetric(horizontal: 12 * s), child: back);
    }

    final item = _item;
    final q = item.question;
    final letters = qmLetters(_ui);
    final theme = qmTheme(widget.theme);
    final cat = widget.theme == 'surprise' ? qmCategory(item.category) : qmThemeCategory(theme);

    return Stack(children: [
      // the whole screen glows in the colour of the player whose turn it is
      Positioned.fill(
        child: IgnorePointer(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            decoration: BoxDecoration(
              border: Border.all(color: _col.withOpacity(0.9), width: 6 * s),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_col.withOpacity(0.28), _col.withOpacity(0.0), _col.withOpacity(0.0), _col.withOpacity(0.22)],
                stops: const [0, 0.25, 0.75, 1],
              ),
            ),
          ),
        ),
      ),
      PositionedDirectional(start: -12 * s, bottom: -8 * s, child: IgnorePointer(child: Image.asset(qmImgBush1, width: 100 * s))),
      PositionedDirectional(end: -10 * s, bottom: -8 * s, child: IgnorePointer(child: Image.asset(qmImgFlowers, width: 90 * s))),
      Center(
        child: SizedBox(
          width: w,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12 * s),
            child: Column(children: [
              step(0, back),
              SizedBox(height: 14 * s),
              step(1, _scoreboard(s)),
              SizedBox(height: 8 * s),
              step(2, Row(children: [
                Expanded(
                  flex: 11,
                  child: QmProgress(
                    scale: s,
                    label: '${qmText(_ui, 'round')} ${_index + 1} / ${_items.length}',
                    value: (_index + (_revealed ? 1 : 0)) / _items.length,
                    stars: 0,
                    showStars: false,
                  ),
                ),
                SizedBox(width: 8 * s),
                Flexible(flex: 9, child: QmCategoryPill(scale: s, category: cat, lang: _ui, height: 38)),
              ])),
              SizedBox(height: 8 * s),
              step(3, _turnBanner(s)),
              SizedBox(height: 8 * s),
              step(4, QmQuestionCard(scale: s, text: q.questionText, onSpeak: _canSpeak ? _readQuestion : null)),
              SizedBox(height: 10 * s),
              Expanded(
                child: step(5, LayoutBuilder(builder: (context, gc) {
                  final n = q.options.length;
                  final cols = n <= 2 ? n : 2;
                  final rows = (n / cols).ceil();
                  final gap = 10 * s;
                  final tileW = (gc.maxWidth - gap * (cols - 1)) / cols;
                  final tileH = min((gc.maxHeight - gap * (rows - 1)) / rows, tileW * 1.05);
                  return Align(
                    alignment: Alignment.topCenter,
                    child: Wrap(spacing: gap, runSpacing: gap, alignment: WrapAlignment.center, children: [
                      for (var i = 0; i < n; i++)
                        SizedBox(
                          width: tileW,
                          height: max(56.0, tileH),
                          child: QmAnswerTile(
                            key: ValueKey('${_index}_$i'),
                            scale: s,
                            letter: i < letters.length ? letters[i] : '${i + 1}',
                            text: q.options[i],
                            artKey: item.keys[i],
                            state: _tileState(i),
                            selected: !_revealed && _selected == i,
                            selectedColor: _col,
                            onTap: _revealed || _player.robot ? null : () => _select(i),
                          ),
                        ),
                    ]),
                  );
                })),
              ),
              SizedBox(height: 8 * s),
              _bottom(s),
              SizedBox(height: 8 * s),
            ]),
          ),
        ),
      ),
      Positioned.fill(child: _handoffLayer(s)),
    ]);
  }

  Widget _handoffLayer(double s) {
    final pl = _player;
    final col = _col;
    final deep = _pDeep[_turn];
    String sub;
    if (pl.robot) {
      sub = qmText(_ui, 'robotTurn');
    } else if (!_vsRobot && _index > 0) {
      sub = qmText(_ui, 'passTo', a: pl.name);
    } else {
      sub = qmText(_ui, 'getReady');
    }
    return IgnorePointer(
      ignoring: !_handoff,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 280),
        opacity: _handoff ? 1 : 0,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _vsRobot ? _startTurn : null,
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.2),
                radius: 1.1,
                colors: [Color.lerp(col, Colors.white, 0.35)!.withOpacity(0.97), col.withOpacity(0.97), deep.withOpacity(0.97)],
                stops: const [0, 0.55, 1],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: TweenAnimationBuilder<double>(
                  key: ValueKey('handoff_$_index'),
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.elasticOut,
                  builder: (_, v, c) => Transform.scale(scale: 0.6 + 0.4 * v, child: c),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24 * s),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 6 * s),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(20 * s),
                        ),
                        child: Text('${qmText(_ui, 'round')} ${_index + 1} / ${_items.length}', style: qmTitle(18 * s, color: deep)),
                      ),
                      SizedBox(height: 18 * s),
                      AnimatedBuilder(
                        animation: _idle,
                        builder: (_, c) => Transform.scale(scale: 1 + sin(_idle.value * 8 * pi) * 0.04, child: c),
                        child: Container(
                          padding: EdgeInsets.all(8 * s),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.7), blurRadius: 40 * s, spreadRadius: 8 * s)],
                          ),
                          child: QmAvatar(avatar: pl.avatar, size: 170 * s),
                        ),
                      ),
                      SizedBox(height: 18 * s),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: QmOutlinedText(
                          pl.robot ? qmText(_ui, 'robotName') : qmText(_ui, 'yourTurnName', a: pl.name),
                          size: 44 * s,
                          stroke: deep,
                          gradient: const [Color(0xFFFFFFFF), Color(0xFFFFF3B0)],
                        ),
                      ),
                      SizedBox(height: 10 * s),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 8 * s),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.15), borderRadius: BorderRadius.circular(18 * s)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          if (!_vsRobot && _index > 0) ...[
                            Image.asset(qmImgHandsTablet, height: 34 * s),
                            SizedBox(width: 10 * s),
                          ],
                          Flexible(child: Text(sub, textAlign: TextAlign.center, style: qmTitle(18 * s, color: Colors.white))),
                        ]),
                      ),
                      SizedBox(height: 24 * s),
                      if (!_vsRobot)
                        KidButton(label: qmText(_ui, 'ready'), onPressed: _startTurn, width: 280 * s, height: 62 * s, showArrow: false)
                      else
                        Text(qmText(_ui, 'tapToStart'), style: qmTitle(15 * s, color: Colors.white.withOpacity(0.85))),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  QmTileState _tileState(int i) {
    if (!_revealed) return QmTileState.idle;
    if (i == _item.question.correctIndex) return QmTileState.correct;
    if (i == _item.picked) return QmTileState.wrong;
    return QmTileState.faded;
  }

  Widget _scoreboard(double s) {
    Widget card(int p) {
      final pl = widget.players[p];
      final active = _turn == p && !_revealed;
      final col = p == 0 ? const Color(0xFF29B6F6) : const Color(0xFFF06BC6);
      final pts = _score(p);
      final avatar = QmAvatar(avatar: pl.avatar, size: 66 * s, ring: active ? col : null);
      final info = Expanded(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          FittedBox(fit: BoxFit.scaleDown, child: Text(pl.name, style: qmTitle(17 * s))),
          SizedBox(height: 3 * s),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 2 * s),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16 * s),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4 * s, offset: Offset(0, 2 * s))],
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: pts.toDouble()),
              duration: const Duration(milliseconds: 500),
              builder: (_, v, __) => FittedBox(
                fit: BoxFit.scaleDown,
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: '${v.round()} ', style: qmTitle(22 * s, color: p == 0 ? const Color(0xFF1C7FD8) : const Color(0xFFE0329C))),
                  TextSpan(text: qmText(_ui, pts == 1 ? 'pt' : 'pts'), style: qmTitle(14 * s, color: p == 0 ? const Color(0xFF1C7FD8) : const Color(0xFFE0329C))),
                ])),
              ),
            ),
          ),
        ]),
      );
      return Expanded(
        child: AnimatedScale(
          duration: const Duration(milliseconds: 250),
          scale: active ? 1.0 : 0.92,
          child: AnimatedOpacity(
           duration: const Duration(milliseconds: 250),
           opacity: active || _revealed ? 1 : 0.6,
           child: Stack(clipBehavior: Clip.none, children: [
           AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 82 * s,
            padding: EdgeInsets.symmetric(horizontal: 6 * s),
            decoration: qmCard(s, border: active ? col : col.withOpacity(0.45), radius: 26, glow: active ? col : null),
            child: Row(children: p == 0 ? [avatar, SizedBox(width: 4 * s), info, SizedBox(width: 18 * s)] : [SizedBox(width: 18 * s), info, SizedBox(width: 4 * s), avatar]),
          ),
           if (active)
             Positioned(
               top: -14 * s,
               left: p == 0 ? 10 * s : null,
               right: p == 1 ? 10 * s : null,
               child: AnimatedBuilder(
                 animation: _idle,
                 builder: (_, c) => Transform.translate(offset: Offset(0, sin(_idle.value * 8 * pi) * 2.5 * s), child: c),
                 child: Container(
                   padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 3 * s),
                   decoration: BoxDecoration(
                     color: col,
                     borderRadius: BorderRadius.circular(12 * s),
                     border: Border.all(color: Colors.white, width: 2 * s),
                     boxShadow: [BoxShadow(color: col.withOpacity(0.6), blurRadius: 8 * s)],
                   ),
                   child: Text(qmText(_ui, 'yourTurnTag'), style: qmTitle(13 * s, color: Colors.white)),
                 ),
               ),
             ),
           ]),
          ),
        ),
      );
    }

    return Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
      Row(children: [card(0), SizedBox(width: 8 * s), card(1)]),
      AnimatedBuilder(
        animation: _idle,
        builder: (_, ch) => Transform.rotate(angle: sin(_idle.value * 2 * pi) * 0.05, child: ch),
        child: QmVsBadge(width: 78 * s),
      ),
    ]);
  }

  Widget _turnBanner(double s) {
    String text;
    Color fill = const Color(0xFFBDF1FF);
    Color border = const Color(0xFF39C6F0);
    if (!_revealed) {
      fill = Color.lerp(_col, Colors.white, 0.75)!;
      border = _col;
      text = _player.robot ? qmText(_ui, 'robotThinking') : qmText(_ui, 'yourTurnName', a: _player.name);
    } else if (_item.correct) {
      text = qmText(_ui, 'pointFor', a: _player.name);
      fill = const Color(0xFFD5F9D5);
      border = qmGreen;
    } else {
      text = qmText(_ui, 'wrongLine', a: _item.answerText);
      fill = const Color(0xFFFFE1E6);
      border = const Color(0xFFFF8FA3);
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      height: 44 * s,
      margin: EdgeInsets.symmetric(horizontal: 20 * s),
      padding: EdgeInsets.symmetric(horizontal: 14 * s),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(24 * s),
        border: Border.all(color: border, width: 2.5 * s),
        boxShadow: [BoxShadow(color: border.withOpacity(0.35), blurRadius: 10 * s)],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: FittedBox(
          key: ValueKey(text),
          fit: BoxFit.scaleDown,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (!_revealed)
              Padding(
                padding: EdgeInsetsDirectional.only(end: 8 * s),
                child: QmAvatar(avatar: _player.avatar, size: 34 * s),
              ),
            Text(text, style: qmTitle(20 * s, color: qmInk)),
          ]),
        ),
      ),
    );
  }

  Widget _bottom(double s) {
    final last = _index + 1 >= _items.length;
    final nextName = widget.players[(_index + 1) % 2].name;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 4 * s),
        decoration: BoxDecoration(
          color: qmCream,
          borderRadius: BorderRadius.circular(18 * s),
          border: Border.all(color: const Color(0xFFF1D9A8), width: 2 * s),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Image.asset(qmImgTwoPlayers, height: 22 * s),
          SizedBox(width: 8 * s),
          Text(qmText(_ui, 'onePoint'), style: qmTitle(14 * s)),
        ]),
      ),
      SizedBox(height: 8 * s),
      if (_revealed)
        KidButton(
          label: last ? qmText(_ui, 'seeResults') : qmText(_ui, 'nextTurn', a: nextName),
          onPressed: _next,
          width: 300 * s,
          height: 54 * s,
        )
      else
        Opacity(
          opacity: _selected == null || _player.robot ? 0.55 : 1,
          child: IgnorePointer(
            ignoring: _selected == null || _player.robot,
            child: KidButton(
              label: qmText(_ui, 'validate'),
              onPressed: _validate,
              width: 300 * s,
              height: 54 * s,
              showArrow: false,
            ),
          ),
        ),
      if (!_revealed && _selected == null && !_player.robot)
        Padding(
          padding: EdgeInsets.only(top: 3 * s),
          child: Text(qmText(_ui, 'pickAnswer'), style: qmTitle(13 * s)),
        ),
    ]);
  }
}
