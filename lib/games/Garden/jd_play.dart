import 'dart:async';
import 'package:mortaalim/Manager/rewards.dart';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:provider/provider.dart';

import 'jd_data.dart';
import 'jd_menu.dart';
import 'package:mortaalim/tools/Ads_Manager.dart';
import 'package:mortaalim/tools/AD_Tools/double_reward_button.dart';

enum _Phase { intro, seed, plant, care, grow }

/// One level of Mon jardin vivant: intro → (seed) → plant → care → grow.
class GardenPlay extends StatefulWidget {
  final JdLevel level;
  const GardenPlay({super.key, required this.level});
  @override
  State<GardenPlay> createState() => _GardenPlayState();
}

class _GardenPlayState extends State<GardenPlay> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  late final AnimationController _act = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
  late final AnimationController _burst = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
  late final AnimationController _day = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
  late final AnimationController _growAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 7200));
  final Random _rng = Random();

  JdLevel get _lv => widget.level;
  JdPlant get _plant => _lv.plant;
  _Phase _phase = _Phase.intro;
  int _mistakes = 0, _hints = 0;
  bool _leaving = false, _over = false, _hintGlow = false;
  String _say = '';
  int _shakeId = -1; // what shakes: 0..5 packet, 10.. tools, 20 gauge, 30.. grow cards

  // seed
  String? _pick;
  // plant
  int _pstep = 0, _pcount = 0;
  bool _pdone = false;
  int _actTool = -1;
  late final List<int> _tray = [0, 1, 2]..shuffle(_rng);
  static const _need = [3, 1, 2];
  // care
  double _water = 0.16;
  JdLight? _light;
  int _dayN = 1;
  bool _pouring = false;
  // grow
  int _view = 1; // 0 above, 1 under the soil
  bool _watched = false, _growDone = false;
  int _stage = -1;
  List<String> _quiz = [];
  int _qi = 0;
  final Set<String> _found = {};
  List<int> _order = [0, 1, 2, 3];
  int _placed = 0;

  @override
  void initState() {
    super.initState();
    _water = 0.12 + _rng.nextDouble() * 0.1;
    _light = _lv.light ? null : _plant.light;
    _growAnim.addListener(() {
      final st = (_growAnim.value * 4).floor().clamp(0, 3);
      if (st != _stage && _growAnim.isAnimating) setState(() => _stage = st);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _speak(jdT(context, 'introSay'));
    });
  }

  @override
  void dispose() {
    JdVoice.stop();
    _idle.dispose();
    _shake.dispose();
    _act.dispose();
    _burst.dispose();
    _day.dispose();
    _growAnim.dispose();
    super.dispose();
  }

  void _speak(String text, {bool voice = true}) {
    setState(() => _say = text);
    if (voice) JdVoice.say(context, text);
  }

  void _shakeIt(int id) {
    setState(() => _shakeId = id);
    _shake.forward(from: 0);
  }

  void _mistake(String text, int shakeId) {
    _mistakes++;
    jdSound(context, 'clickButton2');
    _shakeIt(shakeId);
    _speak(text);
  }

  // ── navigation ────────────────────────────────────────────────────────────

  void _leave([int? result]) {
    if (_leaving) return;
    JdVoice.stop();
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(result);
    });
  }

  void _restart() {
    JdVoice.stop();
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => GardenPlay(level: _lv),
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
    ));
  }

  Future<void> _askQuit() async {
    jdSound(context, 'clickButton');
    final quit = await jdDialog<bool>(context, const _QuitDialog());
    if (quit == true && mounted) _leave();
  }

  Future<void> _pause() async {
    jdSound(context, 'clickButton');
    final r = await jdDialog<String>(context, const _PauseDialog());
    if (!mounted) return;
    if (r == 'restart') _restart();
    if (r == 'map') _leave();
  }

  void _goto(_Phase p) {
    jdSfx(context, 'CorrectAnwser_SFX.mp3');
    setState(() {
      _phase = p;
      _hintGlow = false;
    });
    final t = switch (p) {
      _Phase.intro => jdT(context, 'introSay'),
      _Phase.seed => _lv.seedPick == 2 ? jdT(context, 'seedSayPic') : jdT(context, 'seedSay', {'seed': _plant.seedOf(context)}),
      _Phase.plant => jdT(context, 'say0'),
      _Phase.care => jdT(context, _lv.light ? 'careSayLight' : 'careSay'),
      _Phase.grow => jdT(context, 'watchFirst'),
    };
    _speak(t);
  }

  void _afterIntro() => _goto(_lv.seedPick > 0 ? _Phase.seed : _Phase.plant);

  Future<void> _hint() async {
    jdSound(context, 'clickButton');
    _hints++;
    final (String msg, Widget? extra) = switch (_phase) {
      _Phase.seed => (jdT(context, 'hintSeed'), JdPot(plant: _plant, height: 90)),
      _Phase.plant => (jdT(context, 'hintPlant'), Image.asset(jd(['jd_trowel', 'jd_packet', 'jd_scoop'][_pstep]), height: 80)),
      _Phase.care => _water < 0.4 || _water > 0.67
          ? (jdT(context, 'hintWater'), Image.asset(jd('jd_gauge'), width: 200))
          : (jdT(context, _plant.light == JdLight.half ? 'hintHalf' : 'hintLight'), _LightRow(good: _plant.light, size: 62)),
      _ => (jdT(context, 'hintGrow'), null),
    };
    setState(() => _hintGlow = true);
    JdVoice.say(context, msg);
    await jdDialog(context, _HintDialog(message: msg, extra: extra));
  }

  // ── seed ──────────────────────────────────────────────────────────────────

  void _pickSeed(String id) {
    jdSound(context, 'PopButton');
    setState(() => _pick = id);
    if (_lv.seedPick == 1) JdVoice.say(context, jdPlant(id).name(context));
  }

  void _plantSeed() {
    if (_pick == null) return;
    if (_pick != _plant.id) {
      _mistake(jdT(context, 'seedWrong', {'seed': _plant.seedOf(context)}), jdPlants.indexWhere((p) => p.id == _pick));
      return;
    }
    jdCheer(context, jdT(context, 'stepDone'));
    _goto(_Phase.plant);
  }

  // ── plant ─────────────────────────────────────────────────────────────────

  void _useTool(int tool) {
    if (_pdone || _act.isAnimating) return;
    if (tool != _pstep) {
      _mistake(jdT(context, 'wrongTool'), 10 + tool);
      return;
    }
    jdSound(context, 'PopButton');
    setState(() => _actTool = tool);
    _act.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      _burst.forward(from: 0);
      setState(() {
        _pcount++;
        _actTool = -1;
      });
      if (_pcount >= _need[_pstep]) {
        jdSfx(context, 'CorrectAnwser_SFX.mp3');
        setState(() {
          _pdone = true;
          _hintGlow = false;
        });
        _speak(jdT(context, 'stepDone'));
        jdCheer(context, jdT(context, 'stepDone'), robot: ['jd_rb_thumb', 'jd_rb_wave', 'jd_rb_idea'][_pstep]);
      } else if (_pstep == 0) {
        _speak(jdT(context, 'dig'), voice: _pcount == 1);
      }
    });
  }

  void _nextStep() {
    if (!_pdone) return;
    jdSound(context, 'clickButton');
    if (_pstep == 2) {
      _goto(_Phase.care);
      return;
    }
    setState(() {
      _pstep++;
      _pcount = 0;
      _pdone = false;
    });
    _speak(jdT(context, 'say$_pstep'));
  }

  // ── care ──────────────────────────────────────────────────────────────────

  String _soil() => _water < 0.4 ? jdT(context, 'soilDry') : (_water <= 0.67 ? jdT(context, 'soilOk') : jdT(context, 'soilWet'));

  Future<void> _waterIt() async {
    if (_pouring || _day.isAnimating) return;
    jdSound(context, 'PopButton');
    setState(() => _pouring = true);
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() {
      _water = min(1.0, _water + 0.12);
      _pouring = false;
    });
    _speak(_soil(), voice: false);
  }

  void _setLight(JdLight l) {
    if (!_lv.light) {
      _speak(jdT(context, 'lightFixed'));
      return;
    }
    jdSound(context, 'PopButton');
    setState(() => _light = l);
  }

  Future<void> _observe() async {
    if (_day.isAnimating || _pouring) return;
    if (_water < 0.4) {
      _mistake(jdT(context, 'stillDry'), 20);
      return;
    }
    if (_water > 0.67) {
      _mistakes++;
      jdSound(context, 'clickButton2');
      JdVoice.say(context, jdT(context, 'tooWetSub'));
      final r = await jdDialog<String>(context, const _WetDialog());
      if (!mounted) return;
      setState(() => _water = 0.5);
      _speak(jdT(context, 'dried'), voice: false);
      if (r == 'hint') _hint();
      return;
    }
    if (_light == null) {
      _speak(jdT(context, 'chooseLight'));
      _shakeIt(21);
      return;
    }
    if (_light != _plant.light) {
      _mistakes++;
      jdSound(context, 'clickButton2');
      _shakeIt(21);
      final msg = jdT(context, _plant.light == JdLight.half ? 'hintHalf' : 'hintLight');
      JdVoice.say(context, msg);
      await jdDialog(context, _HintDialog(message: msg, extra: _LightRow(good: _plant.light, size: 62)));
      return;
    }
    // a day goes by
    jdSfx(context, 'CorrectAnwser_SFX.mp3');
    _speak(jdT(context, 'nextDay'));
    final dayRun = _day.forward(from: 0);
    setState(() {});
    await dayRun;
    if (!mounted) return;
    if (_dayN < _lv.days) {
      setState(() {
        _dayN++;
        _water = max(0.1, _water - 0.3 - _rng.nextDouble() * 0.06);
        if (_lv.light && _lv.days > 2) _light = null; // choose again on long levels
      });
      _speak(jdT(context, 'dried'));
      return;
    }
    JdVoice.say(context, jdT(context, 'justRight'));
    await jdDialog(context, _WellDoneDialog(plant: _plant));
    if (mounted) _goto(_Phase.grow);
  }

  // ── grow ──────────────────────────────────────────────────────────────────

  Future<void> _watchGrowth() async {
    if (_growAnim.isAnimating) return;
    jdSound(context, 'PopButton');
    final run = _growAnim.forward(from: 0);
    setState(() => _stage = 0);
    await run;
    if (!mounted) return;
    setState(() {
      _stage = 3;
      _watched = true;
    });
    switch (_lv.grow) {
      case JdGrow.watch:
        setState(() => _growDone = true);
        jdCheer(context, jdT(context, 'wellDone'), robot: 'jd_rb_wave');
        _speak(_plant.grown(context));
      case JdGrow.parts:
        if (_quiz.isEmpty) {
          _quiz = ['roots', 'leaves', 'stem']..shuffle(_rng);
          _qi = 0;
          _found.clear();
        }
        setState(() => _view = 1);
        _askPart();
      case JdGrow.order:
        if (_placed == 0) {
          do {
            _order.shuffle(_rng);
          } while (_order[0] == 0 && _order[1] == 1);
        }
        setState(() {});
        _speak(jdT(context, 'orderSay'));
    }
  }

  void _askPart() => _speak(jdT(context, 'touch', {'part': jdT(context, _quiz[_qi]).toLowerCase()}));

  void _tapPart(String part) {
    final info = jdT(context, switch (part) { 'leaves' => 'sayLeaves', 'stem' => 'sayStem', _ => 'sayRoots' });
    if (_lv.grow != JdGrow.parts || !_watched || _growDone) {
      _speak(info);
      return;
    }
    if (part != _quiz[_qi]) {
      _mistake(jdT(context, 'wrongPart'), 40 + ['leaves', 'stem', 'roots'].indexOf(part));
      return;
    }
    jdSfx(context, 'CorrectAnwser_SFX.mp3');
    _burst.forward(from: 0);
    setState(() => _found.add(part));
    _qi++;
    if (_qi >= _quiz.length) {
      setState(() => _growDone = true);
        jdCheer(context, jdT(context, 'wellDone'), robot: 'jd_rb_wave');
      _speak('${jdT(context, 'goodPart', {'part': jdT(context, part)})} ${_plant.grown(context)}');
    } else {
      _speak(info, voice: false);
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && !_growDone) _askPart();
      });
    }
  }

  void _tapStage(int pos) {
    if (_lv.grow != JdGrow.order || !_watched || _growDone) {
      _speak(jdT(context, 'st${_lv.grow == JdGrow.order && _watched ? _order[pos] : pos}'));
      return;
    }
    if (pos < _placed) return;
    final id = _order[pos];
    if (id != _placed) {
      _mistake(jdT(context, 'orderWrong'), 30 + pos);
      return;
    }
    jdSound(context, 'PopButton');
    setState(() {
      _order[pos] = _order[_placed];
      _order[_placed] = id;
      _placed++;
    });
    JdVoice.say(context, jdT(context, 'st$id'));
    if (_placed == 4) {
      jdSfx(context, 'CorrectAnwser_SFX.mp3');
      _burst.forward(from: 0);
      setState(() => _growDone = true);
        jdCheer(context, jdT(context, 'wellDone'), robot: 'jd_rb_wave');
      _speak(jdT(context, 'orderDone'));
    }
  }

  // ── win ───────────────────────────────────────────────────────────────────

  Future<void> _win() async {
    if (_over) return;
    _over = true;
    final stars = (_mistakes == 0 && _hints == 0) ? 3 : (_mistakes + _hints <= 2 ? 2 : 1);
    final (fresh, first, newPlant) = await JdStore.record(_lv.n, stars);
    if (!mounted) return;
    final rw = Rewards.levelFromGain(tier: _lv.world + 1, stars: stars, gained: first ? stars : fresh, bonusGems: newPlant ? 2 : 0);
    final gold = rw.gold, gems = rw.gems;
    jdSfx(context, 'MarimbaWin_SFX.mp3');
    try {
      Provider.of<ExperienceManager>(context, listen: false).grant(context, rw);
    } catch (_) {}
    JdVoice.say(context, '${jdT(context, 'bravo1')} ${jdT(context, 'bravo2')} ${_plant.grown(context)}');
    final r = await Navigator.of(context).push<String>(PageRouteBuilder<String>(
      opaque: false,
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, __, ___) => _EndPage(
        level: _lv,
        stars: stars,
        gold: gold,
        gems: gems,
        newPlant: newPlant,
        lightChosen: _lv.light,
      ),
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
    ));
    if (!mounted) return;
    // Fin de niveau = pause naturelle (AdHelper applique fréquence + écran « Publicité »).
    await AdHelper.showInterstitialAd(context: context);
    if (!mounted) return;
    switch (r) {
      case 'next':
        _leave(_lv.n < jdLevels.length ? _lv.n + 1 : null);
      case 'again':
        _restart();
      case 'garden':
        _leave(-1);
      default:
        _leave();
    }
  }

  // ═════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) => JdFrame(child: Builder(builder: _page));

  Widget _page(BuildContext context) {
    final s = jdScale(context);
    final size = MediaQuery.sizeOf(context);
    final w = min(size.width, 520.0);
    final (t1, t2, sub) = switch (_phase) {
      _Phase.intro => _split(_plant.my(context)),
      _Phase.seed => (jdT(context, 'seedT1'), jdT(context, 'seedT2'), null),
      _Phase.plant => (jdT(context, 'plantT1'), _plant.my(context), null),
      _Phase.care => (jdT(context, 'careT1'), jdT(context, 'careT2'), _plant.my(context)),
      _Phase.grow => (jdT(context, 'growT1'), jdT(context, 'growT2'), null),
    };
    final hintable = _phase != _Phase.intro;

    return PopScope(
      canPop: _leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _askQuit();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFCDE6A8),
        body: Stack(children: [
          const Positioned.fill(child: JdBg()),
          SafeArea(
            child: Center(
              child: SizedBox(
                width: w,
                child: Column(children: [
                  // header
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8 * s),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      jdRound(context, 'jd_back', 44 * s, _askQuit, flipRtl: true),
                      Expanded(
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            child: JdTitle(key: ValueKey('$t1$t2'), top: t1, bottom: t2, sub: sub, width: min(w * 0.64, 262 * s)),
                          ),
                        ),
                      ),
                      Column(children: [
                        jdRound(context, 'jd_pause', 44 * s, _pause),
                        if (hintable) ...[
                          SizedBox(height: 4 * s),
                          JdPress(
                            onTap: _hint,
                            label: jdT(context, 'hint'),
                            child: AnimatedBuilder(
                              animation: _idle,
                              builder: (_, c) => Transform.rotate(angle: sin(_idle.value * 2 * pi * 2) * 0.08, child: c),
                              child: Image.asset(jd('jd_bulb_btn'), width: 44 * s),
                            ),
                          ),
                        ],
                      ]),
                    ]),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 450),
                      transitionBuilder: (c, a) => FadeTransition(
                        opacity: a,
                        child: SlideTransition(position: Tween(begin: const Offset(0.12, 0), end: Offset.zero).animate(a), child: c),
                      ),
                      child: KeyedSubtree(
                        key: ValueKey(_phase),
                        child: switch (_phase) {
                          _Phase.intro => _introView(s, w),
                          _Phase.seed => _seedView(s, w),
                          _Phase.plant => _plantView(s, w),
                          _Phase.care => _careView(s, w),
                          _Phase.grow => _growView(s, w),
                        },
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
          // a day passes
          if (_day.isAnimating) Positioned.fill(child: _dayOverlay(s)),
        ]),
      ),
    );
  }

  (String, String, String?) _split(String t) {
    final i = t.indexOf(' ');
    if (i < 0) return (t, '', null);
    return (t.substring(0, i), t.substring(i + 1), null);
  }

  Widget _bob(Widget c, {double amp = 3, double speed = 2, double phase = 0}) => AnimatedBuilder(
        animation: _idle,
        builder: (_, child) => Transform.translate(offset: Offset(0, sin((_idle.value * speed + phase) * 2 * pi) * amp), child: child),
        child: c,
      );

  Widget _shaking(int id, Widget child) => AnimatedBuilder(
        animation: _shake,
        builder: (_, c) => Transform.translate(
          offset: Offset(_shakeId == id ? sin(_shake.value * pi * 6) * 8 * (1 - _shake.value) : 0, 0),
          child: c,
        ),
        child: child,
      );

  Widget _robotBubble(double s, String robot, double h, double bubbleW, {bool white = false, bool flipBubble = false}) => IgnorePointer(
        child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _bob(Transform.flip(flipX: jdRtl(context), child: Image.asset(jd(robot), height: h))),
          if (_say.isNotEmpty)
            Transform.translate(offset: Offset(-8 * s, 0), child: JdBubble(text: _say, width: bubbleW, white: white)),
        ]),
      );

  // ═════════════════════════════════════════════════════════════════════════
  // INTRO — "Mon premier haricot"
  // ═════════════════════════════════════════════════════════════════════════

  Widget _introView(double s, double w) => LayoutBuilder(builder: (_, c) {
        final h = c.maxHeight;
        final clipW = min(w * 0.44, (h - 170 * s) * 0.62 / 1.4765);
        final clipH = clipW * 1.4765;
        return Column(children: [
          Expanded(
            child: Stack(clipBehavior: Clip.none, children: [
              // level sign
              PositionedDirectional(
                start: 8 * s,
                top: 0,
                child: JdPopIn(
                  child: JdFloat(
                    amp: 0,
                    tilt: 0.04,
                    child: jdOnSprite('jd_tag', 112 * s, 0.525, Text(jdT(context, 'level', {'n': _lv.n}), style: jdText(16 * s, color: const Color(0xFF4A2408))),
                        area: const EdgeInsets.fromLTRB(0.14, 0.22, 0.2, 0.28)),
                  ),
                ),
              ),
              // robot + bubble
              PositionedDirectional(
                start: 0,
                top: 40 * s,
                child: _bob(Transform.flip(flipX: jdRtl(context), child: Image.asset(jd('jd_robot_point'), height: min(h * 0.36, 150 * s)))),
              ),
              PositionedDirectional(
                start: 6 * s,
                top: 40 * s + min(h * 0.36, 150 * s) - 10 * s,
                child: _bob(JdBubble(text: jdT(context, 'introSay'), width: min(w * 0.44, 170 * s)), phase: 0.3),
              ),
              // clipboard with the 3 steps
              PositionedDirectional(
                end: 8 * s,
                top: 4 * s,
                width: clipW,
                height: clipH,
                child: JdPopIn(
                  delayMs: 150,
                  child: Stack(children: [
                    Positioned.fill(child: Image.asset(jd('jd_clipboard'), fit: BoxFit.fill)),
                    for (var i = 0; i < 3; i++)
                      Positioned(
                        left: clipW * 0.1,
                        right: clipW * 0.08,
                        top: clipH * (0.15 + i * 0.26),
                        height: clipH * 0.24,
                        child: JdPopIn(
                          delayMs: 400 + i * 250,
                          child: Row(children: [
                            Stack(clipBehavior: Clip.none, children: [
                              JdFloat(amp: 1.5 * s, phase: i * 0.3, child: Image.asset(jd('jd_pic$i'), width: clipW * 0.36)),
                              Positioned(
                                left: -6 * s,
                                top: -6 * s,
                                child: CircleAvatar(radius: 10 * s, backgroundColor: jdOrange, child: Text('${i + 1}', style: jdText(12 * s, color: Colors.white))),
                              ),
                            ]),
                            SizedBox(width: 4 * s),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(jdT(context, 'introStep${i + 1}').replaceFirst(' ', '\n'),
                                    textAlign: TextAlign.center, style: jdText(clipW * 0.085, height: 1.05)),
                              ),
                            ),
                          ]),
                        ),
                      ),
                  ]),
                ),
              ),
              // pot with the sprouting seed, bag and can
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                  JdFloat(amp: 0, tilt: 0.04, phase: 0.2, child: Image.asset(jd('jd_bean_bag'), width: w * 0.26)),
                  JdFloat(amp: 3 * s, scale: 0.02, child: Image.asset(jd('jd_pot_root'), width: w * 0.4)),
                  JdFloat(amp: 0, tilt: 0.1, period: const Duration(milliseconds: 1800), child: Image.asset(jd('jd_can_blue'), width: w * 0.26)),
                ]),
              ),
            ]),
          ),
          SizedBox(height: 6 * s),
          jdOnSprite(
            'jd_pill_time',
            min(w * 0.86, 320 * s),
            0.2275,
            Text(jdT(context, 'fast'), style: jdText(13.5 * s, weight: FontWeight.w600)),
            area: const EdgeInsets.fromLTRB(0.2, 0.18, 0.1, 0.22),
          ),
          SizedBox(height: 6 * s),
          JdSpriteButton(
            sprite: 'jd_btn_play2',
            ratio: 0.265,
            start: 0.14,
            end: 0.14,
            label: jdT(context, 'toGarden'),
            onTap: _afterIntro,
            width: min(w * 0.76, 300 * s),
            pulse: _idle,
          ),
          SizedBox(height: 8 * s),
        ]);
      });

  // ═════════════════════════════════════════════════════════════════════════
  // SEED — "Choisis ta graine"
  // ═════════════════════════════════════════════════════════════════════════

  Widget _seedView(double s, double w) {
    final picked = _pick == null ? null : jdPlant(_pick!);
    return LayoutBuilder(builder: (_, c) {
      final h = c.maxHeight;
      final bottomH = min(150 * s, h * 0.3);
      final gridH = h - bottomH - 74 * s;
      final cellW = min((w - 36 * s) / 2, gridH / 3 / 0.94);
      return Column(children: [
        SizedBox(
          height: gridH,
          child: Center(
            child: SizedBox(
              width: cellW * 2 + 12 * s,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var r = 0; r < 3; r++)
                  Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
                    // wooden shelf board
                    Positioned(
                      left: -14 * s,
                      right: -14 * s,
                      bottom: -2 * s,
                      height: 12 * s,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFE2A66A), Color(0xFFB4743A), Color(0xFF8A5226)],
                          ),
                          borderRadius: BorderRadius.circular(6 * s),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 4 * s, offset: Offset(0, 3 * s))],
                        ),
                      ),
                    ),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      for (var k = 0; k < 2; k++) _packet(jdPlants[r * 2 + k], r * 2 + k, cellW, s),
                    ]),
                  ]),
              ]),
            ),
          ),
        ),
        SizedBox(height: 6 * s),
        SizedBox(
          height: bottomH,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            SizedBox(width: 4 * s),
            // robot + bubble
            SizedBox(
              width: w * 0.42,
              child: Stack(clipBehavior: Clip.none, children: [
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: _bob(Transform.flip(flipX: jdRtl(context), child: Image.asset(jd('jd_robot_point_s'), height: bottomH * 0.62))),
                ),
                Positioned(
                  left: w * 0.08,
                  top: 0,
                  child: _lv.seedPick == 2
                      ? Stack(clipBehavior: Clip.none, children: [
                          JdBubble(text: '', width: w * 0.33),
                          Positioned.fill(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(w * 0.03, 6 * s, w * 0.03, w * 0.33 * 0.58 * 0.32),
                              child: Center(child: JdPot(plant: _plant, height: w * 0.33 * 0.58 * 0.6)),
                            ),
                          ),
                        ])
                      : JdBubble(text: _say, width: w * 0.36),
                ),
              ]),
            ),
            // info panel
            Expanded(
              child: AspectRatio(
                aspectRatio: 1 / 0.5477,
                child: LayoutBuilder(builder: (_, b) {
                  final bw = b.maxWidth, bh = b.maxHeight;
                  return Stack(children: [
                    Positioned.fill(child: Image.asset(jd('jd_info_panel'), fit: BoxFit.fill)),
                    Positioned(
                      left: bw * 0.26,
                      right: bw * 0.26,
                      bottom: bh * 0.1,
                      height: bh * 0.18,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(picked == null ? '?' : (_lv.seedPick == 2 ? '?' : picked.the(context)), style: jdText(15 * s)),
                        ),
                      ),
                    ),
                    Positioned(
                      left: bw * 0.1,
                      right: bw * 0.1,
                      top: bh * 0.12,
                      bottom: bh * 0.32,
                      child: picked == null
                          ? Center(child: FittedBox(child: Text(jdT(context, 'seedPick'), style: jdText(13 * s, color: jdInkSoft))))
                          : Row(children: [
                              Expanded(flex: 3, child: JdSeed(plant: picked, size: bh * 0.4)),
                              Expanded(flex: 2, child: JdFloat(amp: 0, scale: 0.12, period: const Duration(milliseconds: 900), child: Image.asset(jd('jd_chev'), height: bh * 0.24))),
                              Expanded(flex: 4, child: JdFloat(amp: 2, tilt: 0.05, child: Image.asset(jd('jd_seed_sprout'), height: bh * 0.48))),
                              Expanded(
                                flex: 2,
                                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  JdFloat(amp: 2, child: Image.asset(jd('jd_ic_drop'), height: bh * 0.2)),
                                  SizedBox(height: 2 * s),
                                  JdFloat(amp: 0, tilt: 0.3, period: const Duration(seconds: 3), child: Image.asset(jd('jd_ic_sun'), height: bh * 0.2)),
                                ]),
                              ),
                            ]),
                    ),
                  ]);
                }),
              ),
            ),
            SizedBox(width: 6 * s),
          ]),
        ),
        SizedBox(height: 4 * s),
        JdSpriteButton(
          sprite: 'jd_btn_plant',
          ratio: 0.2812,
          start: 0.2,
          end: 0.14,
          label: jdT(context, 'plantThis'),
          onTap: _pick == null ? null : _plantSeed,
          width: min(w * 0.86, 340 * s),
          pulse: _idle,
        ),
        SizedBox(height: 6 * s),
      ]);
    });
  }

  Widget _packet(JdPlant p, int i, double cw, double s) {
    final sel = _pick == p.id;
    final glow = sel || (_hintGlow && p.id == _plant.id);
    final ph = cw * 0.89;
    return _shaking(
      i,
      JdPress(
        onTap: () => _pickSeed(p.id),
        label: _lv.seedPick == 2 ? null : p.name(context),
        child: AnimatedScale(
          scale: sel ? 1.06 : 1,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: SizedBox(
            width: cw,
            height: ph,
            child: Stack(clipBehavior: Clip.none, children: [
              if (glow)
                Positioned(
                  left: -cw * 0.06,
                  right: -cw * 0.06,
                  top: -ph * 0.07,
                  bottom: -ph * 0.07,
                  child: AnimatedBuilder(
                    animation: _idle,
                    builder: (_, c) => Opacity(opacity: sel ? 1 : 0.5 + 0.5 * sin(_idle.value * 2 * pi * 4).abs(), child: c),
                    child: Image.asset(jd('jd_glow'), fit: BoxFit.fill),
                  ),
                ),
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _idle,
                  builder: (_, c) => Transform.rotate(
                    alignment: Alignment.bottomCenter,
                    angle: sel ? sin(_idle.value * 2 * pi * 6) * 0.04 : sin((_idle.value * 2 + i * 0.17) * 2 * pi) * 0.015,
                    child: c,
                  ),
                  child: Image.asset(p.packet, fit: BoxFit.fill),
                ),
              ),
              Positioned(
                left: cw * 0.24,
                right: cw * 0.24,
                bottom: ph * 0.065,
                height: ph * 0.11,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(_lv.seedPick == 2 ? '?' : p.name(context), style: jdText(15 * s)),
                  ),
                ),
              ),
              if (sel) Positioned(right: -cw * 0.04, top: -ph * 0.08, child: Image.asset(jd('jd_check'), width: cw * 0.2)),
            ]),
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // PLANT — dig, sow, cover
  // ═════════════════════════════════════════════════════════════════════════

  Widget _plantView(double s, double w) => LayoutBuilder(builder: (_, c) {
        final h = c.maxHeight;
        final trayW = min(w - 24 * s, 380 * s);
        final trayH = trayW * 0.2885;
        return Column(children: [
          _stepBar(s, min(w - 24 * s, 370 * s)),
          SizedBox(height: 6 * s),
          JdSayPill(text: _say, width: min(w - 60 * s, 330 * s)),
          Expanded(child: _plantScene(s, w)),
          _toolTray(s, trayW, trayH),
          SizedBox(height: 6 * s),
          jdPlay(
            jdT(context, 'continue'),
            _pdone ? _nextStep : null,
            min(w * 0.8, 300 * s),
            pulse: _pdone ? _idle : null,
            sub: _pdone ? null : jdT(context, 'needStep$_pstep'),
          ),
          SizedBox(height: h > 600 ? 8 * s : 4 * s),
        ]);
      });

  Widget _stepBar(double s, double width) {
    Widget seg(int i) {
      final done = i < _pstep || (i == _pstep && _pdone);
      final cur = i == _pstep && !_pdone;
      final icon = switch (i) {
        0 => Image.asset(jd('jd_trowel'), height: 24 * s),
        1 => JdSeed(plant: _plant, size: 26 * s),
        _ => Image.asset(jd('jd_soil'), height: 18 * s),
      };
      return Expanded(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 2 * s),
          height: 40 * s,
          padding: EdgeInsets.symmetric(horizontal: 6 * s),
          decoration: BoxDecoration(
            color: cur ? const Color(0xFF2F7DE8) : (done ? const Color(0xFFFFF4DE) : const Color(0xFFE9E5DE)),
            borderRadius: BorderRadius.circular(12 * s),
            border: Border.all(color: cur ? const Color(0xFF7FE7FF) : Colors.white, width: cur ? 3 * s : 2 * s),
            boxShadow: cur ? [BoxShadow(color: const Color(0xFF55D8FF).withOpacity(0.7), blurRadius: 10 * s)] : null,
          ),
          child: Row(children: [
            icon,
            SizedBox(width: 4 * s),
            Container(
              width: 20 * s,
              height: 20 * s,
              decoration: BoxDecoration(shape: BoxShape.circle, color: cur ? const Color(0xFF1546B8) : (done ? const Color(0xFF8B5A2B) : Colors.grey)),
              child: Center(child: Text('${i + 1}', style: jdText(12 * s, color: Colors.white))),
            ),
            SizedBox(width: 4 * s),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(jdT(context, 'step$i'), style: jdText(14 * s, color: cur ? Colors.white : jdBrown)),
              ),
            ),
            if (done) Image.asset(jd('jd_check'), width: 20 * s),
          ]),
        ),
      );
    }

    return Container(
      width: width,
      padding: EdgeInsets.all(4 * s),
      decoration: BoxDecoration(
        color: const Color(0xFFB9783F),
        borderRadius: BorderRadius.circular(16 * s),
        border: Border.all(color: const Color(0xFF8A5226), width: 2 * s),
      ),
      child: Row(children: [seg(0), seg(1), seg(2)]),
    );
  }

  Widget _plantScene(double s, double w) => LayoutBuilder(builder: (_, c) {
        final h = c.maxHeight;
        final potW = min(w * 0.64, h * 0.95 / 0.7881);
        final potH = potW * 0.7881;
        // hole of the pot sprite
        final hx = potW * 0.52, hy = potH * 0.3;
        // soil mound: full at start, dug away, then back on top of the seed
        final mound = switch (_pstep) {
          0 => 1.0 - (_pcount / 3) * 0.95,
          1 => 0.05,
          _ => _pdone ? 1.0 : 0.05 + (_pcount / 2) * 0.95,
        };
        final seedIn = _pstep > 1 || (_pstep == 1 && _pdone);
        return Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
          PositionedDirectional(
            start: 0,
            bottom: 0,
            child: _bob(Transform.flip(flipX: jdRtl(context), child: Image.asset(jd('jd_robot_clasp'), height: min(h * 0.62, 150 * s)))),
          ),
          Positioned(
            bottom: 0,
            child: DragTarget<int>(
              onWillAcceptWithDetails: (_) => true,
              onAcceptWithDetails: (d) => _useTool(d.data),
              builder: (_, cand, __) => AnimatedScale(
                scale: cand.isNotEmpty ? 1.04 : 1,
                duration: const Duration(milliseconds: 150),
                child: SizedBox(
                  width: potW,
                  height: potH,
                  child: Stack(clipBehavior: Clip.none, children: [
                    Positioned.fill(child: Image.asset(jd('jd_pot_hole'), fit: BoxFit.fill)),
                    // seed in the hole
                    if (seedIn)
                      Positioned(
                        left: hx - potW * 0.08,
                        top: hy - potW * 0.06,
                        child: JdSeed(plant: _plant, size: potW * 0.16),
                      ),
                    // soil mound
                    Positioned(
                      left: hx - potW * 0.3,
                      top: hy - potW * 0.17,
                      width: potW * 0.6,
                      height: potW * 0.6 * 0.4423,
                      child: AnimatedScale(
                        scale: mound,
                        alignment: Alignment.bottomCenter,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutBack,
                        child: Image.asset(jd('jd_soil'), fit: BoxFit.contain),
                      ),
                    ),
                    // dashed target while sowing
                    if (_pstep == 1 && !_pdone)
                      Positioned(
                        left: hx - potW * 0.14,
                        top: hy - potW * 0.25,
                        child: _bob(Image.asset(jd('jd_target'), width: potW * 0.28), amp: 4, speed: 3),
                      ),
                    // dirt burst
                    Positioned(
                      left: hx - potW * 0.4,
                      top: hy - potW * 0.4,
                      width: potW * 0.8,
                      height: potW * 0.6,
                      child: IgnorePointer(
                        child: AnimatedBuilder(animation: _burst, builder: (_, __) => CustomPaint(painter: _DirtPainter(_burst.value))),
                      ),
                    ),
                    // tool in action
                    if (_actTool >= 0)
                      AnimatedBuilder(
                        animation: _act,
                        builder: (_, __) {
                          final t = _act.value;
                          final tool = _actTool;
                          final size = potW * (tool == 1 ? 0.2 : 0.42);
                          final dig = sin(t * pi * 4) * 0.35;
                          final dx = tool == 1 ? 0.0 : (tool == 0 ? potW * 0.05 : potW * 0.08);
                          final dy = tool == 1 ? -potW * 0.3 * (1 - Curves.easeIn.transform(t)) : -size * 0.6 + sin(t * pi * 4).abs() * 10 * s;
                          return Positioned(
                            left: hx - size / 2 + dx,
                            top: hy + dy - (tool == 1 ? size * 0.5 : 0),
                            child: Opacity(
                              opacity: (t < 0.85 ? 1.0 : (1 - t) / 0.15).clamp(0.0, 1.0),
                              child: Transform.rotate(
                                angle: tool == 0 ? 0.6 + dig : (tool == 2 ? -0.5 - t * 0.6 : t * pi),
                                child: tool == 1
                                    ? JdSeed(plant: _plant, size: size)
                                    : Image.asset(jd(tool == 0 ? 'jd_trowel' : 'jd_scoop'), width: size),
                              ),
                            ),
                          );
                        },
                      ),
                  ]),
                ),
              ),
            ),
          ),
        ]);
      });

  Widget _toolTray(double s, double tw, double th) => SizedBox(
        width: tw,
        height: th,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned.fill(child: Image.asset(jd('jd_tray3'), fit: BoxFit.fill)),
          for (var slot = 0; slot < 3; slot++)
            Positioned(
              left: tw * [0.05, 0.365, 0.675][slot],
              width: tw * 0.28,
              top: th * 0.12,
              bottom: th * 0.14,
              child: _tool(_tray[slot], tw * 0.28, th * 0.74, s),
            ),
        ]),
      );

  Widget _tool(int tool, double sw, double sh, double s) {
    final glow = _hintGlow && tool == _pstep && !_pdone;
    Widget art(double size) => switch (tool) {
          0 => Image.asset(jd('jd_trowel'), height: size),
          1 => SizedBox(
              height: size,
              width: size * 1.06,
              child: Stack(alignment: Alignment.center, children: [
                Image.asset(jd('jd_packet'), height: size),
                Positioned(top: size * 0.22, child: JdSeed(plant: _plant, size: size * 0.46)),
                Positioned(
                  bottom: size * 0.1,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 5 * s, vertical: 1 * s),
                    decoration: BoxDecoration(color: const Color(0xFFF3DFB4), borderRadius: BorderRadius.circular(6 * s)),
                    child: Text(_plant.name(context), style: jdText(size * 0.13)),
                  ),
                ),
              ]),
            ),
          _ => Image.asset(jd('jd_scoop'), height: size * 0.8),
        };
    final child = Center(child: JdFloat(amp: 2.5 * s, tilt: 0.05, phase: tool * 0.33, period: const Duration(milliseconds: 1900), child: art(sh * 0.9)));
    return _shaking(
      10 + tool,
      Stack(clipBehavior: Clip.none, children: [
        if (glow)
          Positioned(
            left: -sw * 0.08,
            right: -sw * 0.08,
            top: -sh * 0.1,
            bottom: -sh * 0.1,
            child: AnimatedBuilder(
              animation: _idle,
              builder: (_, c) => Opacity(opacity: 0.4 + 0.6 * sin(_idle.value * 2 * pi * 4).abs(), child: c),
              child: Image.asset(jd('jd_glow'), fit: BoxFit.fill),
            ),
          ),
        Positioned.fill(
          child: Draggable<int>(
            data: tool,
            maxSimultaneousDrags: _pdone ? 0 : 1,
            feedback: Material(type: MaterialType.transparency, child: Transform.scale(scale: 1.15, child: art(sh * 0.95))),
            childWhenDragging: Opacity(opacity: 0.3, child: child),
            child: JdPress(onTap: () => _useTool(tool), label: tool == 1 ? _plant.name(context) : jdT(context, tool == 0 ? 'trowel' : 'scoop'), child: child),
          ),
        ),
      ]),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // CARE — water & light
  // ═════════════════════════════════════════════════════════════════════════

  Widget _careView(double s, double w) => LayoutBuilder(builder: (_, c) {
        final h = c.maxHeight;
        final panelsW = w - 20 * s;
        final panelW = (panelsW - 8 * s) / 2;
        return Column(children: [
          JdSayPill(
            text: _soil(),
            width: min(w - 30 * s, 350 * s),
            trailing: JdFloat(amp: 2, scale: 0.06, child: Image.asset(jd(_water <= 0.67 && _water >= 0.4 ? 'jd_ic_drop' : 'jd_soil'), fit: BoxFit.contain)),
          ),
          Expanded(child: _careScene(s, w)),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _waterPanel(s, panelW),
            SizedBox(width: 8 * s),
            _shaking(21, _lightPanel(s, panelW)),
          ]),
          SizedBox(height: 6 * s),
          JdSpriteButton(
            sprite: 'jd_btn_hour',
            ratio: 0.325,
            start: 0.12,
            end: 0.12,
            label: jdT(context, 'observe'),
            onTap: _observe,
            width: min(w * 0.78, 300 * s),
            pulse: (_water >= 0.4 && _water <= 0.67 && _light != null) ? _idle : null,
          ),
          Text('🍃 ${jdT(context, 'fastNote')} 🍃', style: jdText(11 * s, color: jdBrown.withOpacity(0.8), weight: FontWeight.w600)),
          SizedBox(height: h > 600 ? 6 * s : 2 * s),
        ]);
      });

  // growth frame shown while caring: the seed sprouts a little more each day
  // (frames 1 → 4), then the grow phase plays the rest (4 → 11).
  static const _careEnd = 4 / (jdGrowFrames - 1);
  double get _careT {
    final d = (_dayN - 1 + (_day.isAnimating ? _day.value : 0)) / max(1, _lv.days);
    return (1 + 3 * d.clamp(0.0, 1.0)) / (jdGrowFrames - 1);
  }

  Widget _careScene(double s, double w) => LayoutBuilder(builder: (_, c) {
        final h = c.maxHeight;
        final potH = min(h * 0.92, 230 * s);
        final wet = _water.clamp(0.0, 1.0);
        return Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
          // robot + bubble
          PositionedDirectional(
            start: 0,
            top: 0,
            child: _robotBubble(s, 'jd_robot_up', min(h * 0.6, 130 * s), min(w * 0.36, 140 * s), white: true),
          ),
          // day pill
          PositionedDirectional(
            end: 10 * s,
            top: 4 * s,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 4 * s),
              decoration: BoxDecoration(
                color: jdCream,
                borderRadius: BorderRadius.circular(16 * s),
                border: Border.all(color: const Color(0xFFF2B33D), width: 2 * s),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                JdFloat(amp: 0, tilt: 0.4, period: const Duration(seconds: 4), child: Image.asset(jd('jd_ic_sun'), width: 20 * s)),
                SizedBox(width: 4 * s),
                Text(jdT(context, 'day', {'d': _dayN, 'n': _lv.days}), style: jdText(13 * s)),
              ]),
            ),
          ),
          // the plant (darker soil when wet)
          Positioned(
            bottom: 0,
            child: _shaking(
              20,
              AnimatedBuilder(
                animation: Listenable.merge([_idle, _day]),
                builder: (_, __) => Transform.scale(
                  alignment: Alignment.bottomCenter,
                  scaleY: 1 + sin(_idle.value * 2 * pi * 2) * 0.012,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Color.lerp(const Color(0x00FFFFFF), const Color(0x33203A80), (wet - 0.6).clamp(0.0, 0.4) / 0.4)!,
                      BlendMode.srcATop,
                    ),
                    child: JdGrowFlip(plant: _plant, t: _careT, height: potH),
                  ),
                ),
              ),
            ),
          ),
          // watering can pouring
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            right: _pouring ? w * 0.12 : -w * 0.4,
            bottom: potH * 0.72,
            child: Transform.rotate(
              angle: 0.45,
              child: Image.asset(jd('jd_can_blue'), width: min(w * 0.32, 120 * s)),
            ),
          ),
          if (_pouring)
            Positioned(
              bottom: potH * 0.55,
              right: w * 0.3,
              width: 70 * s,
              height: potH * 0.4,
              child: IgnorePointer(child: AnimatedBuilder(animation: _idle, builder: (_, __) => CustomPaint(painter: _RainPainter(_idle.value)))),
            ),
        ]);
      });

  Widget _waterPanel(double s, double pw) {
    final ph = pw * 0.9389;
    final gw = pw * 0.84;
    final gx = (_water.clamp(0.0, 1.0)) * gw * 0.94;
    return SizedBox(
      width: pw,
      height: ph,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(child: Image.asset(jd('jd_panel_water'), fit: BoxFit.fill)),
        Positioned(
          left: pw * 0.3,
          right: pw * 0.18,
          top: ph * 0.05,
          height: ph * 0.13,
          child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(jdT(context, 'water'), style: jdText(18 * s)))),
        ),
        // gauge
        Positioned(
          left: (pw - gw) / 2,
          top: ph * 0.3,
          width: gw,
          height: gw * 0.2175 + 14 * s,
          child: _shaking(
            20,
            Stack(clipBehavior: Clip.none, children: [
              Positioned(left: 0, right: 0, top: 10 * s, child: Image.asset(jd('jd_gauge'), width: gw)),
              // little shine moving along the gauge
              Positioned(
                left: 0,
                right: 0,
                top: 10 * s,
                height: gw * 0.2175,
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _idle,
                    builder: (_, __) => Align(
                      alignment: Alignment(-1 + 2 * ((_idle.value * 3) % 1.0), 0),
                      child: Container(
                        width: gw * 0.08,
                        height: gw * 0.12,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.35)),
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutBack,
                left: gx - 4 * s,
                top: 0,
                child: JdFloat(amp: 2, period: const Duration(milliseconds: 1200), child: Image.asset(jd('jd_gauge_drop'), height: gw * 0.2175 + 12 * s)),
              ),
            ]),
          ),
        ),
        Positioned(
          left: (pw - gw) / 2,
          width: gw,
          top: ph * 0.3 + gw * 0.2175 + 16 * s,
          child: Row(children: [
            Expanded(flex: 40, child: FittedBox(fit: BoxFit.scaleDown, child: Text(jdT(context, 'dry'), style: jdText(10 * s, color: jdOrange)))),
            Expanded(flex: 27, child: FittedBox(fit: BoxFit.scaleDown, child: Text(jdT(context, 'humid'), style: jdText(10 * s, color: jdGreen)))),
            Expanded(flex: 33, child: FittedBox(fit: BoxFit.scaleDown, child: Text(jdT(context, 'wet'), style: jdText(10 * s, color: jdBlue)))),
          ]),
        ),
        Positioned(
          left: pw * 0.07,
          right: pw * 0.07,
          bottom: ph * 0.08,
          child: JdSpriteButton(
            sprite: 'jd_btn_water',
            ratio: 0.405,
            start: 0.34,
            end: 0.06,
            label: jdT(context, 'waterBtn'),
            onTap: _waterIt,
            width: pw * 0.86,
            shadow: const Color(0xFF0D3F9C),
          ),
        ),
      ]),
    );
  }

  Widget _lightPanel(double s, double pw) {
    final ph = pw * 0.9583;
    return SizedBox(
      width: pw,
      height: ph,
      child: Stack(children: [
        Positioned.fill(child: Image.asset(jd('jd_panel_light'), fit: BoxFit.fill)),
        Positioned(
          left: pw * 0.3,
          right: pw * 0.18,
          top: ph * 0.05,
          height: ph * 0.13,
          child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(jdT(context, 'light'), style: jdText(18 * s)))),
        ),
        Positioned(
          left: pw * 0.07,
          right: pw * 0.07,
          top: ph * 0.25,
          bottom: ph * 0.09,
          child: Row(children: [
            for (final l in JdLight.values)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2 * s),
                  child: JdPress(
                    onTap: () => _setLight(l),
                    label: jdT(context, l.name),
                    child: _LightCard(light: l, selected: _light == l, dim: !_lv.light && _light != l, s: s),
                  ),
                ),
              ),
          ]),
        ),
      ]),
    );
  }

  Widget _dayOverlay(double s) => AnimatedBuilder(
        animation: _day,
        builder: (_, __) {
          final t = _day.value;
          final night = sin(t * pi);
          return IgnorePointer(
            child: Stack(fit: StackFit.expand, children: [
              ColoredBox(color: const Color(0xFF16204A).withOpacity(0.55 * night)),
              // sun going round
              Align(
                alignment: Alignment(cos(pi + t * pi) * 0.8, -0.3 - sin(t * pi) * 0.4),
                child: Opacity(opacity: (1 - night * 0.7).clamp(0.0, 1.0), child: Image.asset(jd('jd_sun'), width: 70 * s)),
              ),
              Center(
                child: Opacity(
                  opacity: night.clamp(0.0, 1.0),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Transform.rotate(angle: t * pi * 2, child: Text('⏳', style: TextStyle(fontSize: 54 * s))),
                    SizedBox(height: 8 * s),
                    jdOutlined(jdT(context, 'nextDay'), Colors.white, 30 * s, outline: const Color(0xFF2B2266)),
                  ]),
                ),
              ),
            ]),
          );
        },
      );

  // ═════════════════════════════════════════════════════════════════════════
  // GROW — "Regarde, ça pousse !"
  // ═════════════════════════════════════════════════════════════════════════

  Widget _growView(double s, double w) => LayoutBuilder(builder: (_, c) {
        final h = c.maxHeight;
        final stripW = min(w - 16 * s, 400 * s);
        return Column(children: [
          _toggle(s),
          SizedBox(height: 4 * s),
          Expanded(child: _growScene(s, w)),
          _stageStrip(s, stripW),
          SizedBox(height: 4 * s),
          if (!_watched || _lv.grow == JdGrow.watch)
            JdSpriteButton(
              sprite: 'jd_pill_play',
              ratio: 0.265,
              start: 0.2,
              end: 0.06,
              label: jdT(context, 'watchFast').split('\n').join(' '),
              onTap: _growAnim.isAnimating ? null : _watchGrowth,
              width: min(w * 0.7, 270 * s),
              shadow: Colors.transparent,
            ).inkLabel(context, s),
          SizedBox(height: 4 * s),
          JdSpriteButton(
            sprite: 'jd_btn_sprout',
            ratio: 0.2761,
            start: 0.12,
            end: 0.12,
            label: jdT(context, 'grew'),
            onTap: _growDone ? _win : null,
            width: min(w * 0.86, 330 * s),
            pulse: _growDone ? _idle : null,
          ),
          Padding(
            padding: EdgeInsets.only(top: 2 * s, bottom: h > 600 ? 6 * s : 2 * s),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('🍃 ${jdT(context, 'realDays')} 🍃', style: jdText(10.5 * s, color: jdBrown.withOpacity(0.85), weight: FontWeight.w600)),
            ),
          ),
        ]);
      });

  Widget _toggle(double s) {
    Widget half(int v) {
      final on = _view == v;
      return Expanded(
        child: JdPress(
          onTap: () {
            jdSound(context, 'toggleButton');
            setState(() => _view = v);
          },
          label: jdT(context, v == 0 ? 'above' : 'under'),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 4 * s),
            decoration: BoxDecoration(
              color: on ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(22 * s),
              border: on ? Border.all(color: const Color(0xFF39B8F2), width: 3 * s) : null,
              boxShadow: on ? [BoxShadow(color: const Color(0xFF39B8F2).withOpacity(0.5), blurRadius: 8 * s)] : null,
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Image.asset(jd(v == 0 ? 'jd_ic_leaf' : 'jd_ic_roots'), height: 24 * s),
              SizedBox(width: 6 * s),
              Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(jdT(context, v == 0 ? 'above' : 'under'), style: jdText(15 * s, color: on ? jdBlue : jdBrown)))),
            ]),
          ),
        ),
      );
    }

    return Container(
      width: 290 * s,
      padding: EdgeInsets.all(3 * s),
      decoration: BoxDecoration(
        color: const Color(0xFFF6E2C2),
        borderRadius: BorderRadius.circular(26 * s),
        border: Border.all(color: const Color(0xFFE2B77E), width: 2 * s),
      ),
      child: Row(children: [half(0), half(1)]),
    );
  }

  Widget _growScene(double s, double w) => LayoutBuilder(builder: (_, c) {
        final h = c.maxHeight;
        final playing = _growAnim.isAnimating;
        final asking = _lv.grow == JdGrow.parts && _watched && !_growDone;
        // the plant picture
        final labelW = 122 * s;
        final ratio = _view == 1 || playing || !_watched ? (jdGrowRatio[_plant.id] ?? 1.0) : 1.3;
        final marks = jdGrowMarks[_plant.id] ?? (0.5, const Offset(0.7, 0.2));
        final imgH = min(min(h * 0.94, 280 * s), (w - labelW - 70 * s) * ratio);
        final imgW = imgH / ratio;
        final ox = w - 6 * s - labelW - imgW - (_view == 1 ? 0 : 10 * s);
        // labels: (part, anchor point as fraction of the picture)
        final labels = _view == 1
            ? [('leaves', marks.$2), ('stem', Offset(0.5, marks.$1 - 0.05)), ('roots', Offset(0.5, marks.$1 + (1 - marks.$1) * 0.5))]
            : const [('leaves', Offset(0.66, 0.2)), ('stem', Offset(0.52, 0.56))];
        final showLabels = !playing && _watched;
        return Stack(clipBehavior: Clip.none, children: [
          Positioned(
            left: ox,
            bottom: 0,
            width: imgW,
            height: imgH,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (c, a) => FadeTransition(opacity: a, child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(a), child: c)),
              child: playing || !_watched || _view == 1
                  ? AnimatedBuilder(
                      key: const ValueKey('grow'),
                      animation: _growAnim,
                      builder: (_, __) => JdGrowFlip(
                        plant: _plant,
                        t: playing ? _careEnd + (1 - _careEnd) * _growAnim.value : (_watched ? 1.0 : _careEnd),
                        height: imgH,
                      ),
                    )
                  : JdPot(key: const ValueKey('pot'), plant: _plant, height: imgH),
            ),
          ),
          if (showLabels)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _LinesPainter([
                    for (final l in labels)
                      (Offset(ox + imgW * l.$2.dx, h - imgH + imgH * l.$2.dy), Offset(ox + imgW + 16 * s, h - imgH + imgH * l.$2.dy)),
                  ]),
                ),
              ),
            ),
          if (showLabels)
            for (final l in labels)
              Positioned(
                left: ox + imgW + 14 * s,
                top: h - imgH + imgH * l.$2.dy - 17 * s,
                child: _shaking(40 + ['leaves', 'stem', 'roots'].indexOf(l.$1), _partLabel(l.$1, s, asking)),
              ),
          // sparkles
          Positioned(
            left: ox,
            bottom: 0,
            width: imgW,
            height: imgH,
            child: IgnorePointer(child: AnimatedBuilder(animation: _burst, builder: (_, __) => CustomPaint(painter: JdBurst(_burst.value)))),
          ),
          // while it grows: the sun turns above and rain falls on the plant
          if (playing) ...[
            Positioned(
              left: ox + imgW * 0.62,
              top: max(0.0, h - imgH * 1.15),
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _idle,
                  builder: (_, c) => Transform.rotate(angle: _idle.value * 2 * pi * 2, child: Transform.scale(scale: 1 + 0.08 * sin(_idle.value * 2 * pi * 8), child: c)),
                  child: Image.asset(jd('jd_sun'), width: imgW * 0.34),
                ),
              ),
            ),
            Positioned(
              left: ox + imgW * 0.15,
              top: h - imgH,
              width: imgW * 0.5,
              height: imgH * 0.5,
              child: IgnorePointer(child: AnimatedBuilder(animation: _idle, builder: (_, __) => CustomPaint(painter: _RainPainter(_idle.value)))),
            ),
          ],
          // robot at the bottom, its words at the top
          Positioned(
            left: 0,
            bottom: 0,
            child: IgnorePointer(child: _bob(Transform.flip(flipX: jdRtl(context), child: Image.asset(jd('jd_robot_point'), height: min(h * 0.42, 115 * s))))),
          ),
          if (_say.isNotEmpty)
            Positioned(
              left: 0,
              top: 0,
              child: IgnorePointer(child: _bob(JdBubble(text: _say, width: min(w * 0.42, 160 * s), white: true), phase: 0.3)),
            ),
        ]);
      });

  Widget _partLabel(String part, double s, bool asking) {
    final found = _found.contains(part);
    const ratios = {'leaves': 0.2972, 'stem': 0.2639, 'roots': 0.2889};
    final lw = 120 * s, lh = lw * ratios[part]!;
    return JdPress(
      onTap: () => _tapPart(part),
      label: jdT(context, part),
      child: AnimatedBuilder(
        animation: _idle,
        builder: (_, c) => Transform.scale(scale: asking && !found ? 1 + 0.05 * sin(_idle.value * 2 * pi * 4) : 1, child: c),
        child: SizedBox(
          width: lw,
          height: lh,
          child: Stack(clipBehavior: Clip.none, children: [
            if (asking && !found)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(lh),
                    boxShadow: [BoxShadow(color: const Color(0xFF39B8F2).withOpacity(0.6), blurRadius: 10 * s)],
                  ),
                ),
              ),
            Positioned.fill(child: Image.asset(jd('jd_tag_$part'), fit: BoxFit.fill)),
            Positioned(
              left: lw * 0.33,
              right: lw * 0.07,
              top: lh * 0.1,
              bottom: lh * 0.1,
              child: Center(
                child: FittedBox(fit: BoxFit.scaleDown, child: Text(jdT(context, part), style: jdText(14 * s, color: const Color(0xFF2F5A12)))),
              ),
            ),
            if (found) Positioned(right: -6 * s, top: -8 * s, child: JdPopIn(child: Image.asset(jd('jd_check'), width: 22 * s))),
          ]),
        ),
      ),
    );
  }

  Widget _stageStrip(double s, double width) {
    final cw = (width - 3 * 16 * s - 14 * s) / 4;
    final ordering = _lv.grow == JdGrow.order && _watched;
    final ids = ordering ? _order : const [0, 1, 2, 3];
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(vertical: 5 * s),
      decoration: BoxDecoration(
        color: jdCream.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18 * s),
        border: Border.all(color: const Color(0xFFB9783F), width: 2.5 * s),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var pos = 0; pos < 4; pos++) ...[
          if (pos > 0) JdFloat(amp: 0, scale: 0.15, period: const Duration(milliseconds: 1000), phase: pos * 0.2, child: Image.asset(jd('jd_chev'), height: 16 * s)),
          _shaking(
            30 + pos,
            JdPress(
              onTap: () => _tapStage(pos),
              label: jdT(context, 'st${ids[pos]}'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: cw,
                padding: EdgeInsets.all(2 * s),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12 * s),
                  boxShadow: (!ordering && _stage == pos) || (ordering && pos < _placed)
                      ? [BoxShadow(color: (ordering ? jdGreen : const Color(0xFF39D2FF)).withOpacity(0.9), blurRadius: 10 * s, spreadRadius: 1 * s)]
                      : null,
                ),
                child: Stack(clipBehavior: Clip.none, children: [
                  AspectRatio(
                    aspectRatio: 1 / 0.8,
                    child: Stack(children: [
                      Positioned.fill(
                        child: AnimatedScale(
                          scale: !ordering && _stage == pos ? 1.1 : 1,
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.elasticOut,
                          child: Image.asset(jd('jd_stage${ids[pos]}'), fit: BoxFit.contain, alignment: Alignment.bottomCenter),
                        ),
                      ),
                      Positioned(
                        left: cw * 0.22,
                        right: cw * 0.22,
                        bottom: cw * 0.035,
                        height: cw * 0.11,
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(ordering && pos >= _placed ? '?' : jdT(context, 'st${ids[pos]}'), style: jdText(13 * s)),
                          ),
                        ),
                      ),
                    ]),
                  ),
                  if (ordering && pos < _placed)
                    Positioned(
                      top: -6 * s,
                      left: -4 * s,
                      child: CircleAvatar(radius: 10 * s, backgroundColor: jdGreen, child: Text('${pos + 1}', style: jdText(11 * s, color: Colors.white))),
                    ),
                ]),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

extension on JdSpriteButton {
  /// Cream pill with purple text instead of white.
  Widget inkLabel(BuildContext context, double s) {
    final h = width * ratio;
    return Opacity(
      opacity: onTap == null ? 0.6 : 1,
      child: JdPress(
        onTap: onTap,
        label: label,
        child: SizedBox(
          width: width,
          height: h,
          child: Stack(children: [
            Positioned.fill(child: Image.asset(jd(sprite), fit: BoxFit.fill)),
            PositionedDirectional(
              start: width * start,
              end: width * end,
              top: h * 0.1,
              bottom: h * 0.14,
              child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: jdText(h * 0.34, color: jdInk)))),
            ),
          ]),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// small pieces
// ═════════════════════════════════════════════════════════════════════════════

class _LightCard extends StatelessWidget {
  final JdLight light;
  final bool selected, dim;
  final double s;
  const _LightCard({required this.light, required this.selected, required this.s, this.dim = false});
  @override
  Widget build(BuildContext context) => Opacity(
        opacity: dim ? 0.45 : 1,
        child: Center(
          child: AspectRatio(
            aspectRatio: 1 / 0.99,
            child: AnimatedScale(
              scale: selected ? 1.08 : 1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              child: LayoutBuilder(builder: (_, b) {
                final cw = b.maxWidth, ch = b.maxHeight;
                return Stack(clipBehavior: Clip.none, children: [
                  if (selected)
                    Positioned(
                      left: -4 * s,
                      right: -4 * s,
                      top: -4 * s,
                      bottom: -4 * s,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14 * s),
                          boxShadow: [BoxShadow(color: const Color(0xFF39D2FF).withOpacity(0.9), blurRadius: 12 * s, spreadRadius: 2 * s)],
                        ),
                      ),
                    ),
                  Positioned.fill(child: Image.asset(jd('jd_lc${light.index}'), fit: BoxFit.fill)),
                  Positioned(
                    left: cw * 0.12,
                    right: cw * 0.12,
                    bottom: ch * 0.06,
                    height: ch * 0.15,
                    child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(jdT(context, light.name), style: jdText(12 * s)))),
                  ),
                  if (selected) Positioned(right: -6 * s, top: -6 * s, child: JdPopIn(child: Image.asset(jd('jd_check'), width: 22 * s))),
                ]);
              }),
            ),
          ),
        ),
      );
}

/// The three light pictures with the right one highlighted (used in hints).
class _LightRow extends StatelessWidget {
  final JdLight good;
  final double size;
  const _LightRow({required this.good, required this.size});
  @override
  Widget build(BuildContext context) {
    final s = jdScale(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (final l in JdLight.values)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 3 * s),
          child: SizedBox(width: size * s, height: size * s * 1.25, child: _LightCard(light: l, selected: l == good, s: s * 0.8)),
        ),
    ]);
  }
}

class _DirtPainter extends CustomPainter {
  final double t;
  _DirtPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final r = Random(5);
    final c = Offset(size.width / 2, size.height * 0.6);
    for (var i = 0; i < 16; i++) {
      final a = -pi * (0.1 + r.nextDouble() * 0.8);
      final v = (0.25 + r.nextDouble() * 0.5) * size.width;
      final p = c + Offset(cos(a) * v * t, sin(a) * v * t + 300 * t * t * 0.6);
      final rad = 3 + r.nextDouble() * 5;
      canvas.drawCircle(p, rad * (1 - t * 0.4), Paint()..color = Color.lerp(const Color(0xFF5A3418), const Color(0xFF8A5A30), r.nextDouble())!.withOpacity(1 - t));
    }
  }

  @override
  bool shouldRepaint(_DirtPainter o) => o.t != t;
}

class _RainPainter extends CustomPainter {
  final double t;
  _RainPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(9);
    final p = Paint()..color = const Color(0xFF6CC8FF);
    for (var i = 0; i < 14; i++) {
      final x = r.nextDouble() * size.width;
      final y = ((t * 12 + r.nextDouble()) % 1.0) * size.height;
      canvas.drawOval(Rect.fromCenter(center: Offset(x - y * 0.25, y), width: 4, height: 9), p);
    }
  }

  @override
  bool shouldRepaint(_RainPainter o) => true;
}

class _LinesPainter extends CustomPainter {
  final List<(Offset, Offset)> lines;
  _LinesPainter(this.lines);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final l in lines) {
      canvas.drawLine(l.$1, l.$2, p..color = Colors.black26);
      canvas.drawLine(l.$1 - const Offset(0, 1), l.$2 - const Offset(0, 1), p..color = Colors.white);
      canvas.drawCircle(l.$1, 5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_LinesPainter o) => true;
}

// ═════════════════════════════════════════════════════════════════════════════
// Dialogs
// ═════════════════════════════════════════════════════════════════════════════

class _WellDoneDialog extends StatelessWidget {
  final JdPlant plant;
  const _WellDoneDialog({required this.plant});
  @override
  Widget build(BuildContext context) => JdFrame(child: Builder(builder: _page));
  Widget _page(BuildContext context) {
    final s = jdScale(context);
    return JdDialogFrame(
      title: jdT(context, 'wellDone'),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          JdPopIn(delayMs: 150, child: Image.asset(jd('jd_pot_ok'), height: 110 * s)),
          SizedBox(width: 10 * s),
          JdFloat(amp: 4 * s, tilt: 0.04, child: Image.asset(jd('jd_rb_thumb'), height: 120 * s)),
        ]),
        SizedBox(height: 8 * s),
        jdNote(jdT(context, 'justRight'), s),
        SizedBox(height: 12 * s),
        JdFlatButton(label: jdT(context, 'continue'), onTap: () => Navigator.pop(context), width: 230 * s),
      ]),
    );
  }
}

class _WetDialog extends StatelessWidget {
  const _WetDialog();
  @override
  Widget build(BuildContext context) => JdFrame(child: Builder(builder: _page));
  Widget _page(BuildContext context) {
    final s = jdScale(context);
    return JdDialogFrame(
      title: jdT(context, 'tooWet'),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          JdPopIn(delayMs: 150, child: Image.asset(jd('jd_pot_wet'), height: 110 * s)),
          SizedBox(width: 10 * s),
          JdFloat(amp: 4 * s, tilt: 0.04, child: Image.asset(jd('jd_rb_wave'), height: 120 * s)),
        ]),
        SizedBox(height: 8 * s),
        jdNote(jdT(context, 'tooWetSub'), s),
        SizedBox(height: 12 * s),
        Row(children: [
          Expanded(child: JdFlatButton(label: jdT(context, 'watch'), onTap: () => Navigator.pop(context, 'ok'), width: 150 * s)),
          SizedBox(width: 8 * s),
          Expanded(child: JdFlatButton(label: jdT(context, 'hint'), teal: true, onTap: () => Navigator.pop(context, 'hint'), width: 150 * s)),
        ]),
      ]),
    );
  }
}

class _HintDialog extends StatelessWidget {
  final String message;
  final Widget? extra;
  const _HintDialog({required this.message, this.extra});
  @override
  Widget build(BuildContext context) => JdFrame(child: Builder(builder: _page));
  Widget _page(BuildContext context) {
    final s = jdScale(context);
    return JdDialogFrame(
      title: jdT(context, 'hintTitle'),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          if (extra != null) Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: extra!)),
          SizedBox(width: 8 * s),
          JdFloat(amp: 4 * s, tilt: 0.04, child: Image.asset(jd('jd_rb_idea'), height: 120 * s)),
        ]),
        SizedBox(height: 8 * s),
        jdNote(message, s),
        SizedBox(height: 12 * s),
        JdFlatButton(label: jdT(context, 'understood'), onTap: () => Navigator.pop(context), width: 230 * s),
      ]),
    );
  }
}

class _PauseDialog extends StatelessWidget {
  const _PauseDialog();
  @override
  Widget build(BuildContext context) => JdFrame(child: Builder(builder: _page));
  Widget _page(BuildContext context) {
    final s = jdScale(context);
    return JdDialogFrame(
      title: jdT(context, 'pause'),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        JdFloat(amp: 4 * s, tilt: 0.04, child: Image.asset(jd('jd_rb_sleep'), height: 120 * s)),
        SizedBox(height: 6 * s),
        jdNote(jdT(context, 'pauseSub'), s),
        SizedBox(height: 12 * s),
        Row(children: [
          Expanded(child: JdFlatButton(label: jdT(context, 'resume'), onTap: () => Navigator.pop(context, 'resume'), width: 150 * s)),
          SizedBox(width: 8 * s),
          Expanded(child: JdFlatButton(label: jdT(context, 'restart'), teal: true, onTap: () => Navigator.pop(context, 'restart'), width: 150 * s)),
        ]),
        SizedBox(height: 8 * s),
        Row(children: [
          Expanded(
            child: TextButton.icon(
              onPressed: () => Navigator.pop(context, 'map'),
              icon: Image.asset(jd('jd_ic_map'), height: 24 * s),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(jdT(context, 'map'), style: jdText(14 * s, color: jdInk).copyWith(decoration: TextDecoration.underline)),
              ),
            ),
          ),
          Image.asset(jd('jd_ic_music'), height: 24 * s),
          SizedBox(width: 4 * s),
          Consumer<AudioManager>(
            builder: (_, a, __) => GestureDetector(
              onTap: () {
                a.playEventSound('toggleButton');
                a.toggleBgMute();
              },
              child: Image.asset(jd(a.isBgMuted ? 'jd_tog_off' : 'jd_tog_on'), height: 30 * s),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _QuitDialog extends StatelessWidget {
  const _QuitDialog();
  @override
  Widget build(BuildContext context) => JdFrame(child: Builder(builder: _page));
  Widget _page(BuildContext context) {
    final s = jdScale(context);
    return JdDialogFrame(
      title: jdT(context, 'quitQ'),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Image.asset(jd('jd_mapscroll'), height: 120 * s),
        SizedBox(height: 6 * s),
        jdNote(jdT(context, 'quitSub'), s),
        SizedBox(height: 12 * s),
        JdFlatButton(label: jdT(context, 'keep'), onTap: () => Navigator.pop(context, false), width: 250 * s),
        SizedBox(height: 6 * s),
        JdFlatButton(label: jdT(context, 'quit'), teal: true, onTap: () => Navigator.pop(context, true), width: 250 * s),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// End screen — "Bravo, petit jardinier !"
// ═════════════════════════════════════════════════════════════════════════════

class _EndPage extends StatefulWidget {
  final JdLevel level;
  final int stars, gold, gems;
  final bool newPlant, lightChosen;
  const _EndPage({required this.level, required this.stars, required this.gold, required this.gems, required this.newPlant, required this.lightChosen});
  @override
  State<_EndPage> createState() => _EndPageState();
}

class _EndPageState extends State<_EndPage> with TickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..forward();
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();

  @override
  void dispose() {
    _a.dispose();
    _idle.dispose();
    super.dispose();
  }

  Animation<double> _seg(double a, double b, [Curve c = Curves.easeOutBack]) => CurvedAnimation(parent: _a, curve: Interval(a, b, curve: c));

  Widget _pop(double a, double b, Widget child) {
    final an = _seg(a, b);
    return AnimatedBuilder(
      animation: an,
      builder: (_, c) => Opacity(opacity: an.value.clamp(0.0, 1.0), child: Transform.scale(scale: 0.4 + 0.6 * an.value, child: c)),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) => JdFrame(child: Builder(builder: _page));

  Widget _page(BuildContext context) {
    final s = jdScale(context);
    final size = MediaQuery.sizeOf(context);
    final w = min(size.width, 520.0);
    final plant = widget.level.plant;
    final last = widget.level.n == jdLevels.length;
    final checkW = min(w * 0.8, 300 * s);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFCDE6A8),
        body: Stack(children: [
          const Positioned.fill(child: JdBg(asset: 'jd_bg_win')),
          Positioned.fill(child: IgnorePointer(child: AnimatedBuilder(animation: _idle, builder: (_, __) => CustomPaint(painter: JdLeafRain(_idle.value))))),
          SafeArea(
            child: Center(
              child: SizedBox(
                width: w,
                child: Column(children: [
                  SizedBox(height: 4 * s),
                  // title
                  _pop(
                    0,
                    0.3,
                    jdOnSprite(
                      'jd_plank_leafy',
                      min(w * 0.9, 360 * s),
                      0.35,
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        jdOutlined(jdT(context, 'bravo1'), const Color(0xFF7A2BE0), 34 * s),
                        Transform.translate(offset: Offset(0, -6 * s), child: jdOutlined(jdT(context, 'bravo2'), const Color(0xFF14A7D8), 28 * s)),
                      ]),
                      area: const EdgeInsets.fromLTRB(0.12, 0.16, 0.12, 0.16),
                    ),
                  ),
                  _pop(
                    0.1,
                    0.35,
                    jdOnSprite('jd_pill_leafy', min(w * 0.84, 330 * s), 0.1773, Text(plant.grown(context), style: jdText(16 * s)),
                        area: const EdgeInsets.fromLTRB(0.12, 0.14, 0.12, 0.14)),
                  ),
                  SizedBox(height: 4 * s),
                  // stars
                  _pop(0.25, 0.55, _stars(s, min(w * 0.6, 220 * s))),
                  // celebration
                  Expanded(
                    child: LayoutBuilder(builder: (_, c) {
                      final h = c.maxHeight;
                      return Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
                        Positioned(
                          bottom: 0,
                          child: _pop(0.3, 0.6, JdFloat(amp: 3 * s, tilt: 0.03, child: JdPot(plant: plant, height: min(h * 0.95, 220 * s)))),
                        ),
                        PositionedDirectional(
                          start: 0,
                          bottom: 0,
                          child: AnimatedBuilder(
                            animation: _idle,
                            builder: (_, ch) => Transform.translate(offset: Offset(0, -sin(_idle.value * 2 * pi * 3).abs() * 10 * s), child: ch),
                            child: Image.asset(jd('jd_robot_jump'), height: min(h * 0.75, 150 * s)),
                          ),
                        ),
                        PositionedDirectional(
                          end: 0,
                          bottom: 0,
                          child: AnimatedBuilder(
                            animation: _idle,
                            builder: (_, ch) => Transform.translate(offset: Offset(0, -sin(_idle.value * 2 * pi * 3 + 1).abs() * 10 * s), child: ch),
                            child: Image.asset(jd('jd_kid_jump'), height: min(h * 0.9, 180 * s)),
                          ),
                        ),
                      ]);
                    }),
                  ),
                  // checklist + rewards/badge
                  _pop(
                    0.45,
                    0.75,
                    SizedBox(
                      width: checkW,
                      height: checkW * 0.4019,
                      child: Stack(children: [
                        Positioned.fill(child: Image.asset(jd('jd_checklist'), fit: BoxFit.fill)),
                        for (var i = 0; i < 3; i++) ...[
                          // little icon in the round slot
                          Positioned(
                            left: checkW * 0.075,
                            top: checkW * 0.4019 * ([0.22, 0.5, 0.78][i]) - checkW * 0.035,
                            width: checkW * 0.07,
                            height: checkW * 0.07,
                            child: Image.asset(jd(['jd_seed_icon', 'jd_ic_drop', 'jd_ic_sun'][i]), fit: BoxFit.contain),
                          ),
                          Positioned(
                            left: checkW * 0.2,
                            right: checkW * 0.16,
                            top: checkW * 0.4019 * ([0.22, 0.5, 0.78][i] - 0.1),
                            height: checkW * 0.4019 * 0.2,
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: FittedBox(fit: BoxFit.scaleDown, child: Text(jdT(context, 'c$i'), style: jdText(14 * s))),
                            ),
                          ),
                          // check mark pops in the square slot, one after the other
                          Positioned(
                            right: checkW * 0.055,
                            top: checkW * 0.4019 * ([0.22, 0.5, 0.78][i]) - checkW * 0.04,
                            width: checkW * 0.08,
                            height: checkW * 0.08,
                            child: _pop(0.55 + i * 0.1, 0.75 + i * 0.1, Image.asset(jd('jd_check_sq'), fit: BoxFit.contain)),
                          ),
                        ],
                      ]),
                    ),
                  ),
                  SizedBox(height: 6 * s),
                  _pop(
                    0.55,
                    0.85,
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _rewards(s, min(w * (widget.newPlant ? 0.58 : 0.8), 300 * s)),
                      if (widget.newPlant) ...[
                        SizedBox(width: 6 * s),
                        _badge(s, min(w * 0.34, 130 * s)),
                      ],
                    ]),
                  ),
                  SizedBox(height: 8 * s),
                  // Optionnel : pub choisie par l'enfant pour doubler ses pièces
                  if (widget.gold > 0) ...[
                    DoubleRewardButton(gold: widget.gold, width: min(w * 0.82, 320 * s), height: 40 * s),
                    SizedBox(height: 8 * s),
                  ],
                  _pop(
                    0.7,
                    1.0,
                    Column(children: [
                      JdSpriteButton(
                        sprite: 'jd_btn_next',
                        ratio: 0.275,
                        start: 0.2,
                        end: 0.16,
                        label: last ? jdT(context, 'allDone') : jdT(context, 'next'),
                        onTap: () => Navigator.pop(context, last ? 'garden' : 'next'),
                        width: min(w * 0.82, 320 * s),
                        pulse: _idle,
                      ),
                      SizedBox(height: 6 * s),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        JdPill(
                          label: jdT(context, 'seeGarden'),
                          icon: Image.asset(jd('jd_seed_sprout'), height: 22 * s),
                          onTap: () => Navigator.pop(context, 'garden'),
                          s: s,
                          border: const Color(0xFFE2A04A),
                        ),
                        SizedBox(width: 8 * s),
                        JdPill(
                          label: jdT(context, 'again'),
                          icon: Icon(Icons.replay_rounded, color: const Color(0xFF7A2BE0), size: 22 * s),
                          onTap: () => Navigator.pop(context, 'again'),
                          s: s,
                          border: const Color(0xFFE2A04A),
                        ),
                      ]),
                    ]),
                  ),
                  SizedBox(height: 8 * s),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _stars(double s, double width) {
    final h = width * 0.4059;
    final img = Image.asset(jd('jd_stars3'), width: width, height: h, fit: BoxFit.fill);
    return AnimatedBuilder(
      animation: _idle,
      builder: (_, c) => Transform.scale(scale: 1 + 0.03 * sin(_idle.value * 2 * pi * 2), child: c),
      child: SizedBox(
        width: width,
        height: h,
        child: Stack(children: [
          // grey stars underneath, gold ones clipped to the score
          ColorFiltered(colorFilter: const ColorFilter.mode(Color(0xFFBDB6A6), BlendMode.srcIn), child: Opacity(opacity: 0.55, child: img)),
          ClipRect(child: Align(alignment: Alignment.centerLeft, widthFactor: widget.stars / 3, child: img)),
        ]),
      ),
    );
  }

  Widget _rewards(double s, double width) {
    final h = width * 0.2712;
    return SizedBox(
      width: width,
      height: h,
      child: Stack(children: [
        Positioned.fill(child: Image.asset(jd('jd_rewards'), fit: BoxFit.fill)),
        Positioned(
          left: width * 0.27,
          width: width * 0.2,
          top: h * 0.28,
          bottom: h * 0.26,
          child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text('+${widget.gold}', style: jdText(22 * s, color: const Color(0xFF8A5200))))),
        ),
        Positioned(
          left: width * 0.62,
          width: width * 0.22,
          top: h * 0.28,
          bottom: h * 0.26,
          child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text('+${widget.gems}', style: jdText(22 * s, color: const Color(0xFF1C4FA8))))),
        ),
      ]),
    );
  }

  Widget _badge(double s, double width) => AnimatedBuilder(
        animation: _idle,
        builder: (_, c) => Transform.rotate(angle: sin(_idle.value * 2 * pi * 2) * 0.05, child: c),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          FittedBox(fit: BoxFit.scaleDown, child: Text(jdT(context, 'newPlant'), style: jdText(13 * s, color: jdInk))),
          SizedBox(
            width: width,
            height: width * 0.7063,
            child: Stack(children: [
              Positioned.fill(child: Image.asset(jd('jd_badge'), fit: BoxFit.fill)),
              Positioned(
                left: width * 0.18,
                right: width * 0.18,
                bottom: width * 0.7063 * 0.1,
                height: width * 0.7063 * 0.16,
                child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(jdT(context, 'badgeName'), style: jdText(13 * s, color: Colors.white)))),
              ),
            ]),
          ),
        ]),
      );
}
