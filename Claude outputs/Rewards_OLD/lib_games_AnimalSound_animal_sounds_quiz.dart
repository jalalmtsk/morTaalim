import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../XpSystem.dart';
import '../../main.dart';
import '../../tools/audio_tool/Audio_Manager.dart';
import '../../widgets/KidScene/kid_page_parts.dart';
import '../../widgets/KidScene/kid_scene.dart';
import 'animal_sounds_data.dart';
import 'animal_sounds_widgets.dart';

/// "Guess the sound": hear an animal, pick it among four. 8 questions a round,
/// 1 gold per right answer.
class AnimalSoundsQuiz extends StatefulWidget {
  const AnimalSoundsQuiz({super.key});

  @override
  State<AnimalSoundsQuiz> createState() => _AnimalSoundsQuizState();
}

class _AnimalSoundsQuizState extends State<AnimalSoundsQuiz> with TickerProviderStateMixin {
  static const int _rounds = 8;
  static const String _starOn = '${asDir}games_star_on.webp';
  static const String _starOff = '${asDir}games_star_off.webp';

  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  final AsVoice _voice = AsVoice();
  final Random _rnd = Random();

  List<AsAnimal> _questions = [];
  List<AsAnimal> _options = [];
  int _q = 0;
  int _correct = 0;
  String? _picked;
  bool _locked = false;
  bool _speaking = false;
  Timer? _speakTimer;
  Timer? _startTimer;

  AudioManager get _audio => Provider.of<AudioManager>(context, listen: false);
  AsAnimal get _answer => _questions[_q];

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  @override
  void dispose() {
    _speakTimer?.cancel();
    _startTimer?.cancel();
    _voice.dispose();
    _intro.dispose();
    _idle.dispose();
    super.dispose();
  }

  void _newGame() {
    _questions = ([...asAnimals]..shuffle(_rnd)).take(_rounds).toList();
    _q = 0;
    _correct = 0;
    _setupQuestion();
  }

  void _setupQuestion() {
    final others = asAnimals.where((a) => a.id != _answer.id).toList()..shuffle(_rnd);
    _options = [_answer, ...others.take(3)]..shuffle(_rnd);
    _picked = null;
    _locked = false;
    _startTimer?.cancel();
    _startTimer = Timer(const Duration(milliseconds: 550), () {
      if (mounted) _listen();
    });
  }

  Future<void> _listen() async {
    if (_picked != null) return;
    setState(() => _speaking = true);
    final len = await _voice.play(_answer.sound, _audio);
    _speakTimer?.cancel();
    _speakTimer = Timer(len, () {
      if (mounted) setState(() => _speaking = false);
    });
  }

  Future<void> _pick(AsAnimal a) async {
    if (_locked) return;
    _locked = true;
    _startTimer?.cancel();
    _speakTimer?.cancel();
    await _voice.stop();
    final ok = a.id == _answer.id;
    setState(() {
      _picked = a.id;
      _speaking = false;
      if (ok) _correct++;
    });
    if (ok) {
      _audio.playSfx('assets/audios/UI_Audio/SFX_Audio/MarimbaWin_SFX.mp3');
    } else {
      _audio.playEventSound('invalid');
    }
    await Future.delayed(Duration(milliseconds: ok ? 1300 : 2000));
    if (!mounted) return;
    if (_q + 1 >= _rounds) return _finish();
    setState(() {
      _q++;
      _setupQuestion();
    });
  }

  Future<void> _finish() async {
    final stars = _correct >= 7 ? 3 : _correct >= 5 ? 2 : _correct >= 3 ? 1 : 0;
    final xp = Provider.of<ExperienceManager>(context, listen: false);
    if (_correct > 0) xp.addGold(context, _correct);
    if (_correct > 0) xp.addXP(_correct * 2, context: context);
    if (stars >= 2) _audio.playSfx('assets/audios/UI_Audio/SFX_Audio/victory2_SFX.mp3');

    final again = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: KidColors.purpleDeep.withOpacity(0.35),
      builder: (ctx) => KidDialog(
        headerAsset: asRobot,
        headerAspect: 286 / 264,
        title: asText(ctx, 'done'),
        message: asText(ctx, 'score').replaceAll('{C}', '$_correct').replaceAll('{T}', '$_rounds'),
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
                  child: Image.asset(i < stars ? _starOn : _starOff, width: i == 1 ? 58 : 46, height: i == 1 ? 58 : 46),
                ),
              ),
          ]),
          if (_correct > 0) ...[
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Image.asset(kidCoinAsset, width: 28, height: 28),
              const SizedBox(width: 6),
              Text('+$_correct ${tr(ctx).goldLabel}', style: kidBodyStyle(18, color: KidColors.ink, weight: FontWeight.w700)),
            ]),
          ],
        ]),
        actions: [
          KidOutlineButton(label: asText(ctx, 'animals'), onTap: () => Navigator.pop(ctx, false)),
          KidButton(
            label: asText(ctx, 'replay'),
            onPressed: () => Navigator.pop(ctx, true),
            width: double.infinity,
            height: 54,
            showArrow: false,
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (again == true) {
      setState(_newGame);
    } else {
      Navigator.of(context).pop();
    }
  }

  // ── build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final w = min(size.width, 640.0) - 24;
    final s = min(w / 380, (size.height - pad.vertical) / 780).clamp(0.74, 1.3).toDouble();
    final xp = context.watch<ExperienceManager>();
    Widget step(int i, Widget c) =>
        KidIntro(intro: _intro, from: 0.07 * i, to: min(1.0, 0.5 + 0.07 * i), rise: 20, child: c);

    return Scaffold(
      backgroundColor: KidColors.sky,
      body: Stack(children: [
        const Positioned.fill(child: KidPageBackground(asset: asPageBg, wash: 0)),
        SafeArea(
          child: Center(
            child: SizedBox(
              width: w,
              child: Column(children: [
                SizedBox(height: 6 * s),
                step(0, SizedBox(
                  height: 56 * s,
                  child: Row(children: [
                    KidBackButton(
                      size: 46 * s,
                      onTap: () {
                        _audio.playEventSound('cancelButton');
                        Navigator.of(context).maybePop();
                      },
                    ),
                    SizedBox(width: 6 * s),
                    Expanded(child: Center(child: AsTitle(asText(context, 'guess'), size: 30 * s))),
                    SizedBox(width: 6 * s),
                    KidCurrencyPill(scale: s * 0.92, icon: kidCoinAsset, value: xp.gold, label: tr(context).goldLabel),
                    SizedBox(width: 5 * s),
                    KidCurrencyPill(scale: s * 0.92, icon: kidGemAsset, value: xp.gems, label: tr(context).gemsLabel),
                  ]),
                )),
                SizedBox(height: 8 * s),
                step(1, AsProgressPill(
                  s: s,
                  label: '${_q + 1} / $_rounds',
                  value: (_q + (_picked != null ? 1 : 0)) / _rounds,
                )),
                SizedBox(height: 8 * s),
                step(2, SizedBox(height: 176 * s, child: _listenZone(s))),
                SizedBox(height: 4 * s),
                SizedBox(height: 40 * s, child: _feedback(s)),
                SizedBox(height: 6 * s),
                Expanded(child: step(3, _answers(s))),
                SizedBox(height: 12 * s),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  /// Robot · "Who makes this sound?" · big speaker button.
  Widget _listenZone(double s) {
    final btn = 108 * s;
    return Stack(clipBehavior: Clip.none, children: [
      PositionedDirectional(
        start: -6 * s,
        bottom: 0,
        height: 168 * s,
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _idle,
            builder: (_, c) => Transform.translate(offset: Offset(0, sin(_idle.value * 4 * pi) * 3 * s), child: c),
            child: Image.asset(asRobot, fit: BoxFit.contain),
          ),
        ),
      ),
      // speech bubble
      PositionedDirectional(
        start: 132 * s,
        end: btn + 22 * s,
        top: 4 * s,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 10 * s),
          decoration: asPill(18 * s, color: Colors.white),
          child: Text(asText(context, 'who'),
              textAlign: TextAlign.center,
              style: kidBodyStyle(16 * s, color: KidColors.ink, weight: FontWeight.w700)),
        ),
      ),
      PositionedDirectional(start: 128 * s, bottom: 18 * s, child: AsFloaty(asset: asNoteYellow, size: 26 * s, idle: _idle)),
      PositionedDirectional(start: 168 * s, bottom: 6 * s, child: AsFloaty(asset: asNoteBlue, size: 20 * s, idle: _idle, phase: 0.45)),
      // speaker
      PositionedDirectional(
        end: 8 * s,
        top: 8 * s,
        child: Column(children: [
          KidPressable(
            onTap: _listen,
            semanticLabel: asText(context, 'again'),
            child: AnimatedBuilder(
              animation: _idle,
              builder: (_, c) {
                final k = _speaking ? 1 + sin(_idle.value * 2 * pi * 12) * 0.06 : 1.0;
                return Transform.scale(scale: k, child: c);
              },
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _speaking ? 1 : 0,
                  child: Transform.flip(flipX: true, child: Image.asset(asWaves, height: btn * 0.5)),
                ),
                Image.asset(asSoundOn, width: btn, height: btn),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _speaking ? 1 : 0,
                  child: Image.asset(asWaves, height: btn * 0.5),
                ),
              ]),
            ),
          ),
          SizedBox(height: 2 * s),
          Text(asText(context, 'again'), style: kidBodyStyle(12 * s, color: KidColors.ink, weight: FontWeight.w600)),
        ]),
      ),
    ]);
  }

  Widget _feedback(double s) {
    String? text;
    Color color = asGreen;
    if (_picked != null) {
      if (_picked == _answer.id) {
        text = '${asText(context, 'bravo')}  ${_answer.bubble(context)}';
      } else {
        text = asText(context, 'itWas').replaceAll('{N}', _answer.name(context));
        color = const Color(0xFFFF7A1A);
      }
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
      child: text == null
          ? const SizedBox.shrink()
          : Container(
              key: ValueKey('$_q$text'),
              padding: EdgeInsets.symmetric(horizontal: 20 * s),
              decoration: asPill(20 * s),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(text, maxLines: 1, style: kidTitleStyle(20 * s, color: color).copyWith(shadows: const [])),
              ),
            ),
    );
  }

  /// 2 × 2 answer cards, sized to whatever room is left.
  Widget _answers(double s) {
    return LayoutBuilder(builder: (context, c) {
      final gap = 12 * s;
      final cw = (c.maxWidth - gap) / 2;
      final ch = (c.maxHeight - gap) / 2;
      const aspect = 1.18;
      final cardW = min(cw, ch * aspect);
      final cardH = cardW / aspect;
      Widget card(AsAnimal a) {
        final picked = _picked != null;
        final isAnswer = a.id == _answer.id;
        final mark = !picked
            ? AsMark.none
            : isAnswer
                ? AsMark.right
                : a.id == _picked
                    ? AsMark.wrong
                    : AsMark.none;
        Widget tile = AsCard(
          animal: a,
          s: s,
          showSound: false,
          showBubble: false,
          mark: mark,
          active: picked && isAnswer,
          bounce: picked && isAnswer ? _q + 1 : 0,
          dim: picked && mark == AsMark.none,
          onTap: () => _pick(a),
        );
        if (mark == AsMark.wrong) {
          tile = TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 480),
            builder: (_, v, child) =>
                Transform.translate(offset: Offset(sin(v * pi * 6) * 9 * s * (1 - v), 0), child: child),
            child: tile,
          );
        }
        return SizedBox(width: cardW, height: cardH, child: tile);
      }

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        transitionBuilder: (child, a) => FadeTransition(
          opacity: a,
          child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(a), child: child),
        ),
        child: Center(
          key: ValueKey(_q * 1000 + _questions.hashCode % 1000),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [card(_options[0]), SizedBox(width: gap), card(_options[1])]),
            SizedBox(height: gap),
            Row(mainAxisSize: MainAxisSize.min, children: [card(_options[2]), SizedBox(width: gap), card(_options[3])]),
          ]),
        ),
      );
    });
  }
}
