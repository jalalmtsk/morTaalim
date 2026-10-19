import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mortaalim/Manager/lesson_progress.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/KidScene/kid_page_parts.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'computer_basics_texts.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Assets
// ═══════════════════════════════════════════════════════════════════════════

class CBAssets {
  CBAssets._();
  static const String dir = 'assets/images/UI/KidScene/';
  static const String bg = '${dir}it_page_bg.webp';
  static const String laptop = '${dir}itb_laptop.webp';
  static const String robotPoint = '${dir}itb_robot_point.webp';
  static const String robotPresent = '${dir}itb_robot_present.webp';
  static const String robotMonitor = '${dir}itb_robot_monitor.webp';
  static const String bulb = '${dir}itb_bulb.webp';
  static const String sound = '${dir}mm_sound.webp';
  static const String star = '${dir}mm_star.webp';
  static String scene(int n) => '${dir}itb_scene$n.webp';
  static String item(String id) => '${dir}itb_${_file[id] ?? id}.webp';
  static const Map<String, String> _file = {
    'letters': 'abc',
    'draw': 'app_draw',
    'music': 'app_music',
    'numbers': 'app_numbers',
    'colors': 'palette',
    'name': 'pencil',
    'quiet': 'vol_quiet',
    'medium': 'vol_medium',
    'loud': 'vol_loud',
    'breaks': 'clock',
  };
  static const List<String> notes = ['${dir}itb_note0.webp', '${dir}itb_note1.webp', '${dir}itb_note2.webp', '${dir}itb_note3.webp'];
}

// ═══════════════════════════════════════════════════════════════════════════
// Lesson data
// ═══════════════════════════════════════════════════════════════════════════

enum CBStepType { choice, type, draw, volume }

class CBStep {
  final CBStepType type;
  final List<String> options; // item ids shown as cards
  final String answer; // correct item (choice)
  final String target; // 'name' / 'word' (type) · 'down' / 'mid' (volume)
  const CBStep.choice(this.options, this.answer)
      : type = CBStepType.choice,
        target = '';
  const CBStep.type(this.target)
      : type = CBStepType.type,
        options = const ['letters', 'space', 'delete'],
        answer = '';
  const CBStep.draw()
      : type = CBStepType.draw,
        options = const ['brush', 'colors', 'eraser'],
        answer = '',
        target = '';
  const CBStep.volume(this.target)
      : type = CBStepType.volume,
        options = const ['quiet', 'medium', 'loud'],
        answer = '';
}

class CBLesson {
  final int number; // 1..8
  final int? scene; // illustrated scene, or null = built from sprites
  final List<CBStep> steps;
  const CBLesson(this.number, this.scene, this.steps);
  String get thumb => scene != null ? CBAssets.scene(scene!) : (number == 1 ? CBAssets.item('keyboard') : CBAssets.item('hands'));
}

const _pc = ['monitor', 'keyboard', 'mouse'];
const _shapes = ['star', 'heart', 'circle'];
const _apps = ['draw', 'music', 'numbers'];
const _keys = ['letters', 'space', 'delete'];
const _tools = ['brush', 'colors', 'eraser'];
const _files = ['name', 'folder', 'save'];
const _vols = ['quiet', 'medium', 'loud'];
const _care = ['hands', 'nodrink', 'breaks'];

const List<CBLesson> computerBasicsLessons = [
  CBLesson(1, null, [
    CBStep.choice(_pc, 'keyboard'),
    CBStep.choice(_pc, 'monitor'),
    CBStep.choice(_pc, 'mouse'),
    CBStep.choice(_pc, 'keyboard'),
    CBStep.choice(_pc, 'monitor'),
  ]),
  CBLesson(2, 2, [
    CBStep.choice(_shapes, 'star'),
    CBStep.choice(_shapes, 'heart'),
    CBStep.choice(_shapes, 'circle'),
    CBStep.choice(_shapes, 'star'),
    CBStep.choice(_shapes, 'circle'),
  ]),
  CBLesson(3, 3, [
    CBStep.type('name'),
    CBStep.choice(_keys, 'letters'),
    CBStep.choice(_keys, 'space'),
    CBStep.choice(_keys, 'delete'),
    CBStep.type('word'),
  ]),
  CBLesson(4, 4, [
    CBStep.choice(_apps, 'draw'),
    CBStep.choice(_apps, 'music'),
    CBStep.choice(_apps, 'numbers'),
    CBStep.choice(_apps, 'draw'),
    CBStep.choice(_apps, 'numbers'),
  ]),
  CBLesson(5, 5, [
    CBStep.draw(),
    CBStep.choice(_tools, 'brush'),
    CBStep.choice(_tools, 'colors'),
    CBStep.choice(_tools, 'eraser'),
    CBStep.draw(),
  ]),
  CBLesson(6, 6, [
    CBStep.choice(_files, 'name'),
    CBStep.choice(_files, 'folder'),
    CBStep.choice(_files, 'save'),
    CBStep.choice(_files, 'save'),
    CBStep.choice(_files, 'folder'),
  ]),
  CBLesson(7, 7, [
    CBStep.volume('down'),
    CBStep.volume('mid'),
    CBStep.choice(_vols, 'medium'),
    CBStep.choice(_vols, 'quiet'),
    CBStep.choice(_vols, 'loud'),
  ]),
  CBLesson(8, null, [
    CBStep.choice(_care, 'hands'),
    CBStep.choice(_care, 'nodrink'),
    CBStep.choice(_care, 'breaks'),
    CBStep.choice(['hands', 'nofood', 'breaks'], 'nofood'),
    CBStep.choice(_care, 'hands'),
  ]),
];

String cbLessonTitle(BuildContext c, int number) => cbText(c, 'l$number');

/// Best stars per lesson (0 = not finished yet).
class CBProgress {
  static String _k(int n) => 'cb_stars_$n';
  static Future<Map<int, int>> load() async {
    final p = await SharedPreferences.getInstance();
    return {for (final l in computerBasicsLessons) l.number: p.getInt(_k(l.number)) ?? 0};
  }

  static Future<void> save(int n, int stars) async {
    final p = await SharedPreferences.getInstance();
    if ((p.getInt(_k(n)) ?? 0) < stars) await p.setInt(_k(n), stars);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Lesson page
// ═══════════════════════════════════════════════════════════════════════════

const _ink = KidColors.ink;
const LessonTracker _itTracker = LessonProgress.it;
const List<Color> _paint = [
  Color(0xFFEF4444), Color(0xFFF97316), Color(0xFFFACC15), Color(0xFF22C55E), Color(0xFF3B82F6), Color(0xFF8B5CF6),
];

class ComputerBasicsLessonPage extends StatefulWidget {
  final int index; // 0-based in computerBasicsLessons
  const ComputerBasicsLessonPage({super.key, required this.index});

  @override
  State<ComputerBasicsLessonPage> createState() => _ComputerBasicsLessonPageState();
}

class _Stroke {
  final Color color;
  final List<Offset> points; // in 0..1 canvas space
  _Stroke(this.color) : points = [];
}

class _ComputerBasicsLessonPageState extends State<ComputerBasicsLessonPage> with TickerProviderStateMixin {
  static const _kVoice = 'cb_auto_voice';

  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final AnimationController _idle =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  late final AnimationController _blink =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
  final FlutterTts _tts = FlutterTts();
  final _rnd = Random();

  int _step = 0;
  int _mistakes = 0;
  bool _solved = false;
  String? _picked; // last tapped option
  String? _wrong; // option to shake
  bool _showTryAgain = false;
  bool _autoVoice = true;
  List<String> _order = [];
  bool _precached = false;

  // typing
  String _typed = '';
  // drawing
  final List<_Stroke> _strokes = [];
  int _colorIndex = 0;
  bool _erasing = false;
  // volume
  double _volume = 0.85;

  CBLesson get _lesson => computerBasicsLessons[widget.index];
  CBStep get _cur => _lesson.steps[_step];
  AudioManager get _audio => Provider.of<AudioManager>(context, listen: false);

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      _autoVoice = p.getBool(_kVoice) ?? true;
      if (mounted) _enterStep(0);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      KidAssets.precache(context, [
        CBAssets.bg, CBAssets.laptop, CBAssets.robotPoint, CBAssets.robotPresent, CBAssets.bulb, CBAssets.sound, CBAssets.star,
        if (_lesson.scene != null) CBAssets.scene(_lesson.scene!) else ...[CBAssets.robotMonitor, CBAssets.item('monitor')],
        for (final s in _lesson.steps) for (final o in s.options) CBAssets.item(o),
      ]);
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _intro.dispose();
    _idle.dispose();
    _blink.dispose();
    super.dispose();
  }

  // ── Speech ────────────────────────────────────────────────────────────────
  Future<void> _speak(String text) async {
    final lang = Localizations.localeOf(context).languageCode;
    final code = switch (lang) { 'fr' => 'fr-FR', 'ar' => 'ar-SA', 'de' => 'de-DE', 'zgh' => 'fr-FR', _ => 'en-US' };
    try {
      await _tts.stop();
      await _tts.setLanguage(code);
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.15);
      await _tts.speak(text.replaceAll('!', '.'));
    } catch (_) {}
  }

  String _instruction(BuildContext c) {
    final key = '${_lesson.number}.${_step + 1}';
    return cbText(c, key, args: {'w': cbText(c, 'word')});
  }

  String get _typeTarget {
    if (_cur.target == 'word') return cbText(context, 'word');
    final raw = Provider.of<ExperienceManager>(context, listen: false).userProfile.fullName.trim().split(' ').first.toUpperCase();
    final latin = raw.replaceAll(RegExp(r'[^A-Z]'), '');
    return (latin.length >= 2 && latin.length <= 10) ? latin : 'SAM';
  }

  void _enterStep(int i) {
    setState(() {
      _step = i;
      _solved = false;
      _picked = null;
      _wrong = null;
      _showTryAgain = false;
      _order = [..._lesson.steps[i].options];
      if (_lesson.steps[i].type == CBStepType.choice) _order.shuffle(_rnd);
      _typed = '';
      _strokes.clear();
      _erasing = false;
      _volume = _lesson.steps[i].target == 'mid' ? 0.08 : 0.85;
    });
    if (_autoVoice) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) _speak(_instruction(context));
      });
    }
  }

  void _success() {
    if (_solved) return;
    _audio.playSfx('assets/audios/UI_Audio/SFX_Audio/victory1_SFX.mp3');
    setState(() {
      _solved = true;
      _showTryAgain = false;
    });
  }

  void _miss(String? option) {
    _mistakes++;
    _audio.playEventSound('invalid');
    setState(() {
      _wrong = option;
      _showTryAgain = true;
    });
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) setState(() => _wrong = null);
    });
  }

  // ── Step interactions ─────────────────────────────────────────────────────
  void _tapOption(String id) {
    if (_solved && _cur.type == CBStepType.choice) return;
    switch (_cur.type) {
      case CBStepType.choice:
        _picked = id;
        if (id == _cur.answer) {
          _success();
        } else {
          _miss(id);
        }
      case CBStepType.type:
        if (id == 'space') _key(' ');
        if (id == 'delete') _key('⌫');
        if (id == 'letters') _audio.playEventSound('clickButton2');
      case CBStepType.draw:
        _audio.playEventSound('clickButton2');
        setState(() {
          _picked = id;
          if (id == 'brush') _erasing = false;
          if (id == 'colors') {
            _erasing = false;
            _colorIndex = (_colorIndex + 1) % _paint.length;
          }
          if (id == 'eraser') {
            _erasing = true;
            _strokes.clear();
          }
        });
      case CBStepType.volume:
        _setVolume(switch (id) { 'quiet' => 0.15, 'medium' => 0.5, _ => 0.9 }, tapped: id);
    }
  }

  void _key(String k) {
    if (_solved) return;
    final target = _typeTarget;
    setState(() {
      if (k == '⌫') {
        if (_typed.isNotEmpty) _typed = _typed.substring(0, _typed.length - 1);
      } else if (_typed.length < 14) {
        _typed += k;
      }
      _showTryAgain = false;
    });
    _audio.playEventSound('clickButton2');
    if (_typed == target) {
      _success();
    } else if (k != '⌫' && !target.startsWith(_typed)) {
      setState(() => _showTryAgain = true);
    }
  }

  void _setVolume(double v, {String? tapped}) {
    setState(() {
      _volume = v;
      _picked = tapped ?? (v < 0.33 ? 'quiet' : (v < 0.67 ? 'medium' : 'loud'));
    });
    final ok = _cur.target == 'down' ? v <= 0.3 : (v >= 0.35 && v <= 0.65);
    if (ok) _success();
  }

  double get _inkAmount => _strokes.fold(0.0, (a, s) {
        var d = 0.0;
        for (int i = 1; i < s.points.length; i++) {
          d += (s.points[i] - s.points[i - 1]).distance;
        }
        return a + d;
      });

  void _drawEnd() {
    if (!_solved && _inkAmount > 2.2) _success();
  }

  Future<void> _continue() async {
    if (!_solved) return;
    _audio.playEventSound('clickButton');
    if (_step < _lesson.steps.length - 1) {
      _enterStep(_step + 1);
      return;
    }
    await _finish();
  }

  Future<void> _finish() async {
    final stars = _mistakes <= 1 ? 3 : (_mistakes <= 3 ? 2 : 1);
    const reward = 15;
    await CBProgress.save(_lesson.number, stars);
    if (!mounted) return;
    final xp = Provider.of<ExperienceManager>(context, listen: false);
    xp.addTokenBanner(context, reward);
    xp.addXP(10, context: context);
    _audio.playSfx('assets/audios/UI_Audio/SFX_Audio/victory2_SFX.mp3');
    final last = widget.index == computerBasicsLessons.length - 1;
    final next = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: KidColors.purpleDeep.withOpacity(0.4),
      builder: (ctx) => KidDialog(
        headerAsset: CBAssets.robotPoint,
        headerAspect: 1.0465,
        title: last ? cbText(ctx, 'allDone') : cbText(ctx, 'complete'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(cbLessonTitle(ctx, _lesson.number),
              textAlign: TextAlign.center, style: kidBodyStyle(16, color: KidColors.purpleDeep, weight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (int i = 0; i < 3; i++)
              Padding(
                padding: EdgeInsets.only(left: 4, right: 4, bottom: i == 1 ? 14 : 0),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 400 + i * 250),
                  curve: Curves.easeOutBack,
                  builder: (_, v, c) => Transform.scale(scale: v, child: c),
                  child: Opacity(
                    opacity: i < stars ? 1 : 0.25,
                    child: Image.asset(CBAssets.star, width: i == 1 ? 62 : 48, height: i == 1 ? 62 : 48),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Image.asset(kidCoinAsset, width: 30, height: 30),
            const SizedBox(width: 6),
            Text('+$reward', style: kidBodyStyle(22, color: KidColors.ink, weight: FontWeight.w700)),
          ]),
        ]),
        actions: [
          KidOutlineButton(label: cbText(ctx, 'backLessons'), onTap: () => Navigator.pop(ctx, false)),
          if (!last)
            KidButton(
              label: cbText(ctx, 'nextLesson'),
              width: double.infinity,
              height: 54,
              showArrow: false,
              onPressed: () => Navigator.pop(ctx, true),
            ),
        ],
      ),
    );
    if (!mounted) return;
    if (next == true) {
      await _itTracker.record('basics', widget.index + 1);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        pageBuilder: (_, __, ___) => ComputerBasicsLessonPage(index: widget.index + 1),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 350),
      ));
    } else {
      Navigator.of(context).pop();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = min(size.width, 560.0) - 28;
    final s = (w / 380).clamp(0.78, 1.35);
    final instruction = _instruction(context);

    Widget step(int i, Widget child) =>
        KidIntro(intro: _intro, from: 0.08 * i, to: min(1.0, 0.5 + 0.08 * i), rise: 18, child: child);

    return Scaffold(
      backgroundColor: KidColors.sky,
      body: Stack(children: [
        const Positioned.fill(child: KidPageBackground(asset: CBAssets.bg, wash: 0.04)),
        SafeArea(
          child: Center(
            child: SizedBox(
              width: w,
              child: Column(children: [
                const SizedBox(height: 4),
                step(0, _header(s)),
                SizedBox(height: 6 * s),
                step(1, _lessonPill(s)),
                SizedBox(height: 8 * s),
                step(2, _instructionPill(s, instruction)),
                SizedBox(height: 10 * s),
                Expanded(child: step(3, Center(child: _sceneCard(s)))),
                SizedBox(height: 10 * s),
                step(4, _bottomControls(s)),
                SizedBox(height: 8 * s),
                step(5, _hintPill(s)),
                SizedBox(height: 10 * s),
                step(6, _continueButton(s)),
                SizedBox(height: 8 * s),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _header(double s) {
    final t = tr(context);
    return SizedBox(
      height: 84 * s,
      child: Row(children: [
        KidBackButton(
          size: 50 * s,
          onTap: () {
            _audio.playEventSound('cancelButton');
            Navigator.of(context).maybePop();
          },
        ),
        Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            AnimatedBuilder(
              animation: _idle,
              builder: (_, c) => Transform.translate(offset: Offset(0, sin(_idle.value * 4 * pi) * 2 * s), child: c),
              child: Image.asset(CBAssets.laptop, height: 30 * s, width: 30 * s / 0.37),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                t.itBasics,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w700,
                  fontSize: 32 * s,
                  height: 1.0,
                  color: const Color(0xFF5B21C9),
                  shadows: const [
                    Shadow(color: Colors.white, blurRadius: 0, offset: Offset(0, -2)),
                    Shadow(color: Colors.white, blurRadius: 0, offset: Offset(2, 0)),
                    Shadow(color: Colors.white, blurRadius: 0, offset: Offset(-2, 0)),
                    Shadow(color: Colors.white, blurRadius: 0, offset: Offset(0, 2)),
                    Shadow(color: Color(0xFFFFC94A), blurRadius: 0, offset: Offset(0, 4.5)),
                    Shadow(color: Color(0x55000000), blurRadius: 8, offset: Offset(0, 5)),
                  ],
                ),
              ),
            ),
          ]),
        ),
        KidPressable(
          onTap: () async {
            setState(() => _autoVoice = !_autoVoice);
            _audio.playEventSound('toggleButton');
            if (!_autoVoice) _tts.stop();
            (await SharedPreferences.getInstance()).setBool(_kVoice, _autoVoice);
          },
          child: Stack(alignment: Alignment.center, children: [
            Opacity(opacity: _autoVoice ? 1 : 0.5, child: Image.asset(CBAssets.sound, width: 50 * s, height: 50 * s)),
            if (!_autoVoice)
              Transform.rotate(
                angle: -0.8,
                child: Container(
                    width: 42 * s,
                    height: 4 * s,
                    decoration: BoxDecoration(color: const Color(0xFFE11D48), borderRadius: BorderRadius.circular(4))),
              ),
          ]),
        ),
      ]),
    );
  }

  Widget _lessonPill(double s) {
    final t = tr(context);
    final total = _lesson.steps.length;
    return Container(
      padding: EdgeInsets.fromLTRB(16 * s, 8 * s, 12 * s, 10 * s),
      decoration: kidCardDecoration(30 * s, shadow: 0.15),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text('${t.lessonN(_lesson.number)} · ${cbLessonTitle(context, _lesson.number)}',
                  maxLines: 1, style: kidBodyStyle(15 * s, color: KidColors.purpleDeep, weight: FontWeight.w700)),
            ),
          ),
          SizedBox(width: 8 * s),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 3 * s),
            decoration: BoxDecoration(color: const Color(0xFFEDE6FF), borderRadius: BorderRadius.circular(20)),
            child: Text('${_step + 1} / $total',
                textDirection: TextDirection.ltr, style: kidBodyStyle(14 * s, color: _ink, weight: FontWeight.w700)),
          ),
        ]),
        SizedBox(height: 6 * s),
        SizedBox(
          height: 14 * s,
          child: LayoutBuilder(builder: (context, c) {
            final segW = c.maxWidth / (total - 1);
            return Stack(alignment: Alignment.centerLeft, children: [
              Container(height: 6 * s, decoration: BoxDecoration(color: const Color(0xFFE3DDD0), borderRadius: BorderRadius.circular(6))),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                height: 10 * s,
                width: max(14 * s, segW * (_step + (_solved ? 1.0 : 0.35)).clamp(0.0, (total - 1).toDouble())),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(colors: [Color(0xFFFFD84A), Color(0xFFFFB21A)]),
                ),
              ),
              for (int i = 1; i < total; i++)
                Positioned(
                  left: segW * i - 6 * s,
                  child: Container(
                    width: 12 * s,
                    height: 12 * s,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i <= _step ? const Color(0xFFFFC21A) : const Color(0xFFD9D3C6),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ]);
          }),
        ),
      ]),
    );
  }

  Widget _instructionPill(double s, String text) {
    return Container(
      constraints: BoxConstraints(minHeight: 60 * s),
      padding: EdgeInsetsDirectional.fromSTEB(8 * s, 6 * s, 16 * s, 6 * s),
      decoration: kidCardDecoration(34 * s, shadow: 0.15),
      child: Row(children: [
        KidPressable(
          onTap: () => _speak(text),
          semanticLabel: tr(context).tapToListen,
          child: Image.asset(CBAssets.sound, width: 46 * s, height: 46 * s),
        ),
        SizedBox(width: 10 * s),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (c, a) => FadeTransition(
                opacity: a, child: SlideTransition(position: Tween(begin: const Offset(0.05, 0), end: Offset.zero).animate(a), child: c)),
            child: Text(text,
                key: ValueKey(text),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: kidTitleStyle(23 * s, color: _ink).copyWith(shadows: const [])),
          ),
        ),
      ]),
    );
  }

  // ── Scene ─────────────────────────────────────────────────────────────────
  Widget _sceneCard(double s) {
    return AspectRatio(
      aspectRatio: 792 / 609,
      child: Container(
        padding: EdgeInsets.all(8 * s),
        decoration: BoxDecoration(
          color: KidColors.cream,
          borderRadius: BorderRadius.circular(28 * s),
          border: Border.all(color: const Color(0xFFFFE6A8), width: 2.5),
          boxShadow: [BoxShadow(color: KidColors.purpleDeep.withOpacity(0.22), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22 * s),
          child: LayoutBuilder(builder: (context, c) {
            final W = c.maxWidth, H = c.maxHeight;
            Rect rel(double l, double t, double w, double h) => Rect.fromLTWH(l * W, t * H, w * W, h * H);
            return Stack(children: [
              Positioned.fill(child: _sceneArt(W, H)),
              if (_cur.type == CBStepType.type) Positioned.fromRect(rect: rel(0.115, 0.115, 0.45, 0.37), child: _typingWindow(H)),
              if (_cur.type == CBStepType.draw) Positioned.fromRect(rect: rel(0.155, 0.11, 0.44, 0.48), child: _drawCanvas()),
              if (_cur.type == CBStepType.volume) Positioned.fromRect(rect: rel(0.14, 0.29, 0.52, 0.2), child: _volumeSlider(H)),
              // robot's fact bubble
              PositionedDirectional(
                top: H * 0.04,
                end: W * 0.03,
                child: AnimatedScale(
                  scale: _solved ? 1 : 0,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutBack,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: W * 0.42),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 8 * s),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18 * s),
                        border: Border.all(color: const Color(0xFFFFD447), width: 2.5),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: Text(_fact(context),
                          textAlign: TextAlign.center,
                          style: kidBodyStyle(13.5 * s, color: KidColors.purpleDeep, weight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
            ]);
          }),
        ),
      ),
    );
  }

  String _fact(BuildContext c) {
    switch (_cur.type) {
      case CBStepType.type:
        return cbText(c, 'typed');
      case CBStepType.draw:
        return cbText(c, 'drawn');
      case CBStepType.volume:
        return cbText(c, 'volumeOk');
      case CBStepType.choice:
        final a = _cur.answer;
        return _lesson.number == 2 ? cbText(c, 'f.click') : cbText(c, 'f.$a');
    }
  }

  Widget _sceneArt(double W, double H) {
    if (_lesson.scene != null) return Image.asset(CBAssets.scene(_lesson.scene!), fit: BoxFit.cover);
    // Built scenes for lessons 1 and 8: sky, desk and sprites.
    final desk = Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: H * 0.3,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF7FE0EA), Color(0xFF3FB8D0)]),
        ),
      ),
    );
    final sky = Positioned.fill(
      child: Stack(fit: StackFit.expand, children: [
        Image.asset(CBAssets.bg, fit: BoxFit.cover, alignment: const Alignment(0, -0.6)),
        ColoredBox(color: Colors.white.withOpacity(0.18)),
      ]),
    );
    bool glow(String id) => _solved && _cur.answer == id;
    Widget part(String id, Widget img) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _tapOption(id),
          child: AnimatedScale(
            scale: glow(id) ? 1.08 : 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            child: Container(
              decoration: glow(id)
                  ? BoxDecoration(boxShadow: [BoxShadow(color: const Color(0xFFFFE066).withOpacity(0.9), blurRadius: 28, spreadRadius: 4)])
                  : null,
              child: img,
            ),
          ),
        );
    if (_lesson.number == 1) {
      return Stack(children: [
        sky,
        desk,
        Positioned(left: W * 0.06, top: H * 0.1, width: W * 0.5, child: part('monitor', Image.asset(CBAssets.item('monitor')))),
        Positioned(left: W * 0.08, bottom: H * 0.05, width: W * 0.46, child: part('keyboard', Image.asset(CBAssets.item('keyboard')))),
        Positioned(left: W * 0.57, bottom: H * 0.06, width: W * 0.17, child: part('mouse', Image.asset(CBAssets.item('mouse')))),
        Positioned(
          right: -W * 0.02,
          bottom: H * 0.04,
          width: W * 0.36,
          child: AnimatedBuilder(
            animation: _idle,
            builder: (_, c) => Transform.translate(offset: Offset(0, sin(_idle.value * 4 * pi) * 3), child: c),
            child: Transform.flip(flipX: true, child: Image.asset(CBAssets.robotPoint)),
          ),
        ),
      ]);
    }
    // Lesson 8: robot by the monitor, care icons floating
    return Stack(children: [
      sky,
      desk,
      Positioned(
        left: W * 0.06,
        bottom: H * 0.06,
        width: W * 0.64,
        child: AnimatedBuilder(
          animation: _idle,
          builder: (_, c) => Transform.translate(offset: Offset(0, sin(_idle.value * 4 * pi) * 2), child: c),
          child: Image.asset(CBAssets.robotMonitor),
        ),
      ),
      for (final (i, id) in const [(0, 'hands'), (1, 'nodrink'), (2, 'breaks')].indexed)
        Positioned(
          right: W * 0.04,
          top: H * (0.08 + i * 0.29),
          width: W * 0.2,
          child: AnimatedBuilder(
            animation: _idle,
            builder: (_, c) => Transform.translate(offset: Offset(0, sin((_idle.value * 4 + i * 0.3) * pi) * 4), child: c),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _solved && _cur.answer == id.$2 ? 1 : 0.85,
              child: Image.asset(CBAssets.item(id.$2)),
            ),
          ),
        ),
    ]);
  }

  Widget _typingWindow(double H) {
    final target = _typeTarget;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(H * 0.03),
        border: Border.all(color: const Color(0xFF5AA9FF), width: 3),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6)],
      ),
      child: Column(children: [
        Container(
          height: H * 0.06,
          padding: EdgeInsets.symmetric(horizontal: H * 0.02),
          decoration: BoxDecoration(
            color: const Color(0xFFD8EBFF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(H * 0.025)),
          ),
          child: Row(children: [
            for (final c in const [Color(0xFFEF4444), Color(0xFFFACC15), Color(0xFF22C55E)])
              Container(
                width: H * 0.025,
                height: H * 0.025,
                margin: EdgeInsets.only(right: H * 0.01),
                decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              ),
            const Spacer(),
            Text(target, style: kidBodyStyle(H * 0.035, color: const Color(0xFF6B8DB5), weight: FontWeight.w700)),
          ]),
        ),
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: H * 0.03),
                child: Row(mainAxisSize: MainAxisSize.min, textDirection: TextDirection.ltr, children: [
                  Text(_typed.isEmpty ? ' ' : _typed,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontWeight: FontWeight.w700,
                        fontSize: H * 0.13,
                        color: _showTryAgain ? const Color(0xFFE11D48) : const Color(0xFF1E2A78),
                        letterSpacing: 2,
                      )),
                  FadeTransition(
                    opacity: _blink,
                    child: Container(width: 3, height: H * 0.13, color: const Color(0xFF6B7280)),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _drawCanvas() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD5DEEA), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LayoutBuilder(builder: (context, c) {
          final sz = Size(c.maxWidth, c.maxHeight);
          Offset norm(Offset p) => Offset((p.dx / sz.width).clamp(0.0, 1.0), (p.dy / sz.height).clamp(0.0, 1.0));
          return GestureDetector(
            onPanStart: (d) {
              if (_erasing) setState(() => _erasing = false);
              setState(() => _strokes.add(_Stroke(_paint[_colorIndex])..points.add(norm(d.localPosition))));
            },
            onPanUpdate: (d) => setState(() => _strokes.last.points.add(norm(d.localPosition))),
            onPanEnd: (_) => _drawEnd(),
            child: CustomPaint(
              size: sz,
              painter: _StrokePainter(_strokes),
              child: _strokes.isEmpty
                  ? Center(
                      child: Icon(Icons.gesture_rounded, color: const Color(0xFFCBD5E1), size: sz.shortestSide * 0.4),
                    )
                  : null,
            ),
          );
        }),
      ),
    );
  }

  Widget _volumeSlider(double H) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: H * 0.03),
      decoration: BoxDecoration(
        color: KidColors.cream,
        borderRadius: BorderRadius.circular(H),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        Icon(_volume < 0.05 ? Icons.volume_mute_rounded : (_volume < 0.5 ? Icons.volume_down_rounded : Icons.volume_up_rounded),
            color: const Color(0xFF4338CA), size: H * 0.1),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: H * 0.04,
              activeTrackColor: const Color(0xFF3B82F6),
              inactiveTrackColor: const Color(0xFFD1D5DB),
              thumbColor: Colors.white,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: H * 0.04, elevation: 4),
              overlayColor: const Color(0x223B82F6),
            ),
            child: Slider(value: _volume, onChanged: _solved ? null : (v) => _setVolume(v)),
          ),
        ),
      ]),
    );
  }

  // ── Bottom controls ───────────────────────────────────────────────────────
  Widget _bottomControls(double s) {
    final cards = Container(
      padding: EdgeInsets.all(6 * s),
      decoration: BoxDecoration(
        color: KidColors.cream.withOpacity(0.95),
        borderRadius: BorderRadius.circular(26 * s),
        border: Border.all(color: const Color(0xFFFFE6A8), width: 2),
        boxShadow: [BoxShadow(color: KidColors.purpleDeep.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: Row(children: [
        for (int i = 0; i < _order.length; i++) ...[
          if (i > 0) SizedBox(width: 6 * s),
          Expanded(child: _optionCard(s, _order[i])),
        ],
      ]),
    );
    if (_cur.type != CBStepType.type) return cards;
    return _Keyboard(scale: s, onKey: _key, enabled: !_solved);
  }

  Widget _optionCard(double s, String id) {
    final st = _cur;
    final selected = switch (st.type) {
      CBStepType.choice => _solved && id == st.answer,
      CBStepType.draw => id == 'colors' ? false : (_erasing ? id == 'eraser' : id == 'brush'),
      CBStepType.volume => _picked == id,
      CBStepType.type => false,
    };
    final wrong = _wrong == id;
    return KidPressable(
      onTap: () => _tapOption(id),
      pressedScale: 0.93,
      semanticLabel: cbText(context, 'i.$id'),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: wrong ? 1 : 0),
        duration: const Duration(milliseconds: 420),
        builder: (_, v, child) => Transform.translate(offset: Offset(sin(v * pi * 6) * 6 * v, 0), child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 104 * s,
          padding: EdgeInsets.fromLTRB(6 * s, 8 * s, 6 * s, 6 * s),
          decoration: BoxDecoration(
            color: wrong ? const Color(0xFFFFE4E6) : (selected ? const Color(0xFFEDE4FF) : const Color(0xFFFFFBF2)),
            borderRadius: BorderRadius.circular(20 * s),
            border: Border.all(
              color: wrong ? const Color(0xFFF43F5E) : (selected ? KidColors.purple : const Color(0xFFF1E4C8)),
              width: selected || wrong ? 3 : 1.5,
            ),
            boxShadow: selected ? [BoxShadow(color: KidColors.purple.withOpacity(0.3), blurRadius: 12)] : null,
          ),
          child: Column(children: [
            Expanded(
              child: Stack(alignment: Alignment.center, children: [
                Image.asset(CBAssets.item(id), fit: BoxFit.contain),
                if (st.type == CBStepType.draw && id == 'colors')
                  Positioned(
                    right: 0,
                    top: 0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 20 * s,
                      height: 20 * s,
                      decoration: BoxDecoration(
                        color: _paint[_colorIndex],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 3)],
                      ),
                    ),
                  ),
                if (st.type == CBStepType.choice && _solved && id == st.answer)
                  PositionedDirectional(
                    top: 0,
                    end: 0,
                    child: Image.asset(CBAssets.item('check'), width: 24 * s, height: 24 * s),
                  ),
              ]),
            ),
            SizedBox(height: 4 * s),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(cbText(context, 'i.$id'),
                  maxLines: 1, style: kidBodyStyle(16 * s, color: _ink, weight: FontWeight.w700)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _hintPill(double s) {
    final text = _showTryAgain
        ? cbText(context, 'tryAgain')
        : (_cur.type == CBStepType.draw && !_solved && _strokes.isNotEmpty)
            ? cbText(context, 'keepDrawing')
            : cbText(context, 'h${_lesson.number}');
    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(8 * s, 6 * s, 14 * s, 6 * s),
      decoration: kidCardDecoration(30 * s, shadow: 0.12).copyWith(
        color: _showTryAgain ? const Color(0xFFFFF1F2) : null,
      ),
      child: Row(children: [
        AnimatedBuilder(
          animation: _idle,
          builder: (_, c) => Transform.rotate(angle: sin(_idle.value * 6 * pi) * 0.1, child: c),
          child: Image.asset(CBAssets.bulb, width: 26 * s, height: 26 * s * 1.35),
        ),
        SizedBox(width: 8 * s),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Text(text,
                key: ValueKey(text),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: kidBodyStyle(14 * s,
                    color: _showTryAgain ? const Color(0xFFBE123C) : _ink, weight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }

  Widget _continueButton(double s) {
    final on = _solved;
    final h = 62 * s;
    return KidPressable(
      onTap: on ? _continue : null,
      pressedScale: 0.95,
      semanticLabel: tr(context).continueLabel,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: on ? 1 : 0.5,
        child: AnimatedBuilder(
          animation: _idle,
          builder: (_, c) => Transform.scale(scale: on ? 1 + 0.025 * sin(_idle.value * 8 * pi) : 1, child: c),
          child: Container(
            height: h,
            width: min(320 * s, double.infinity),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(h),
              gradient: const LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFE45C), Color(0xFFFFC21A)]),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(color: const Color(0xFFD08A00), offset: Offset(0, 4 * s)),
                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: Offset(0, 7 * s)),
              ],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(tr(context).continueLabel,
                      style: kidTitleStyle(28 * s, color: const Color(0xFF3B1C8C)).copyWith(shadows: const [])),
                ),
              ),
              SizedBox(width: 10 * s),
              Container(
                width: 38 * s,
                height: 38 * s,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Color(0xFF9B5CFF), Color(0xFF6A2BE0)]),
                ),
                child: Transform.flip(
                  flipX: Directionality.of(context) == TextDirection.rtl,
                  child: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24 * s),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _StrokePainter extends CustomPainter {
  final List<_Stroke> strokes;
  _StrokePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      if (s.points.isEmpty) continue;
      final p = Paint()
        ..color = s.color
        ..strokeWidth = size.shortestSide * 0.07
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final path = Path()..moveTo(s.points.first.dx * size.width, s.points.first.dy * size.height);
      for (final pt in s.points.skip(1)) {
        path.lineTo(pt.dx * size.width, pt.dy * size.height);
      }
      if (s.points.length == 1) {
        canvas.drawCircle(Offset(s.points.first.dx * size.width, s.points.first.dy * size.height), p.strokeWidth / 2,
            p..style = PaintingStyle.fill);
      } else {
        canvas.drawPath(path, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StrokePainter old) => true;
}

/// Rainbow on-screen keyboard (Latin letters).
class _Keyboard extends StatelessWidget {
  final double scale;
  final ValueChanged<String> onKey;
  final bool enabled;
  const _Keyboard({required this.scale, required this.onKey, required this.enabled});

  static const _rows = ['QWERTYUIOP', 'ASDFGHJKL', 'ZXCVBNM'];
  static const _colors = [
    Color(0xFFFF5FA2), Color(0xFFFF8A3D), Color(0xFFFFC93C), Color(0xFF7ED957), Color(0xFF3DD6C9),
    Color(0xFF4FA8FF), Color(0xFF8B7CFF), Color(0xFFC06BFF),
  ];

  @override
  Widget build(BuildContext context) {
    final s = scale;
    Widget key(String label, Color c, {int flex = 1, IconData? icon, String? value}) => Expanded(
          flex: flex,
          child: Padding(
            padding: EdgeInsets.all(2.2 * s),
            child: KidPressable(
              onTap: enabled ? () => onKey(value ?? label) : null,
              pressedScale: 0.88,
              child: Container(
                height: 38 * s,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9 * s),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color.lerp(c, Colors.white, 0.25)!, c],
                  ),
                  boxShadow: [BoxShadow(color: Color.lerp(c, Colors.black, 0.35)!, offset: Offset(0, 2.5 * s))],
                ),
                child: icon != null
                    ? Icon(icon, color: Colors.white, size: 20 * s)
                    : Text(label,
                        style: kidBodyStyle(15 * s, color: const Color(0xFF2D0B57), weight: FontWeight.w700).copyWith(height: 1.0)),
              ),
            ),
          ),
        );
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        padding: EdgeInsets.fromLTRB(6 * s, 6 * s, 6 * s, 8 * s),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7E6),
          borderRadius: BorderRadius.circular(22 * s),
          border: Border.all(color: const Color(0xFFF1DFB6), width: 2),
          boxShadow: [BoxShadow(color: KidColors.purpleDeep.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (int r = 0; r < _rows.length; r++)
            Row(children: [
              if (r == 1) const Spacer(flex: 1),
              if (r == 2) const Spacer(flex: 3),
              for (int i = 0; i < _rows[r].length; i++) key(_rows[r][i], _colors[(i + r) % _colors.length], flex: 2),
              if (r == 1) const Spacer(flex: 1),
              if (r == 2) const Spacer(flex: 3),
            ]),
          Row(children: [
            const Spacer(flex: 2),
            key(' ', const Color(0xFF8B5CF6), flex: 10, value: ' '),
            key('', const Color(0xFFFF4D8D), flex: 4, icon: Icons.backspace_rounded, value: '⌫'),
            const Spacer(flex: 1),
          ]),
        ]),
      ),
    );
  }
}
