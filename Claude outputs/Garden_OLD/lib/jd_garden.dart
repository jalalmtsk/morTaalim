import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'jd_data.dart';
import 'jd_menu.dart';

/// "Mon jardin" — the plants the child has grown, on a wooden shelf.
class MyGardenPage extends StatefulWidget {
  const MyGardenPage({super.key});
  @override
  State<MyGardenPage> createState() => _MyGardenPageState();
}

class _MyGardenPageState extends State<MyGardenPage> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();
  List<int> _stars = List.filled(jdLevels.length, 0);
  Set<String> _found = {};
  String? _newest;
  String _sel = 'bean';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final st = await JdStore.stars();
    final nw = await JdStore.newest();
    if (!mounted) return;
    setState(() {
      _stars = st;
      _found = JdStore.discoveredFrom(st);
      _newest = nw != null && _found.contains(nw) ? nw : null;
      _sel = _newest ?? (_found.isNotEmpty ? jdPlants.firstWhere((p) => _found.contains(p.id)).id : 'bean');
    });
  }

  @override
  void dispose() {
    JdVoice.stop();
    _idle.dispose();
    _intro.dispose();
    super.dispose();
  }

  void _tap(JdPlant p) {
    if (!_found.contains(p.id)) {
      jdSound(context, 'clickButton2');
      JdVoice.say(context, jdT(context, 'lockedPlant'));
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: jdInk,
          duration: const Duration(milliseconds: 1400),
          content: Text(jdT(context, 'lockedPlant'), style: jdText(15, color: Colors.white, weight: FontWeight.w600)),
        ));
      return;
    }
    jdSound(context, 'PopButton');
    setState(() => _sel = p.id);
    JdVoice.say(context, '${p.name(context)}. ${p.fact(context)}');
  }

  Future<void> _plantNew() async {
    jdSound(context, 'PopButton');
    await jdOpenLevel(context, JdStore.next(_stars));
    _load();
  }

  @override
  Widget build(BuildContext context) => JdFrame(child: Builder(builder: _page));

  Widget _page(BuildContext context) {
    final s = jdScale(context);
    final size = MediaQuery.sizeOf(context);
    final w = min(size.width, 520.0);
    final plant = jdPlant(_sel);
    final known = _found.contains(_sel);

    return Scaffold(
      backgroundColor: const Color(0xFFCDE6A8),
      body: Stack(children: [
        const Positioned.fill(child: JdBg()),
        SafeArea(
          child: Center(
            child: SizedBox(
              width: w,
              child: Column(children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10 * s),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    jdRound(context, 'jd_back', 46 * s, () {
                      jdSound(context, 'cancelButton');
                      Navigator.of(context).maybePop();
                    }, flipRtl: true),
                    Expanded(
                      child: Column(children: [
                        JdTitle(top: jdT(context, 'gardenT1'), bottom: jdT(context, 'gardenT2'), width: min(w * 0.58, 230 * s)),
                        Transform.translate(
                          offset: Offset(0, -8 * s),
                          child: jdOnSprite(
                            'jd_pill_leafy',
                            min(w * 0.6, 240 * s),
                            0.15,
                            Text(jdT(context, 'gardenCount', {'n': _found.length}), style: jdText(14 * s)),
                            area: const EdgeInsets.fromLTRB(0.13, 0.1, 0.13, 0.1),
                          ),
                        ),
                      ]),
                    ),
                    jdMuteButton(context, 46 * s),
                  ]),
                ),
                Expanded(child: _shelf(s, w)),
                SizedBox(height: 4 * s),
                _info(s, min(w - 20 * s, 400 * s), plant, known),
                SizedBox(height: 6 * s),
                JdSpriteButton(
                  sprite: 'jd_btn_newseed',
                  ratio: 0.2021,
                  start: 0.22,
                  end: 0.16,
                  label: jdT(context, 'plantNew'),
                  onTap: _plantNew,
                  width: min(w * 0.9, 360 * s),
                  pulse: _idle,
                ),
                SizedBox(height: 8 * s),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _shelf(double s, double w) => LayoutBuilder(builder: (_, c) {
        final h = c.maxHeight;
        final shelfW = min(w * 0.74, h / 0.8548 * 1.0);
        final shelfH = shelfW * 0.8548;
        final potH = shelfH * 0.29;
        // the three boards of the shelf sprite (fraction of its height)
        const boards = [0.355, 0.64, 0.86];
        return Stack(clipBehavior: Clip.none, children: [
          // kid + robot cheering on the side
          PositionedDirectional(
            end: 0,
            bottom: 0,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AnimatedBuilder(
                animation: _idle,
                builder: (_, ch) => Transform.translate(offset: Offset(0, -sin(_idle.value * 2 * pi * 2).abs() * 5 * s), child: ch),
                child: Image.asset(jd('jd_kid_robot'), height: min(h * 0.62, 170 * s)),
              ),
            ]),
          ),
          PositionedDirectional(
            end: 0,
            top: 0,
            width: min(w * 0.3, 120 * s),
            child: jdOnSprite(
              'jd_plank_flower',
              min(w * 0.3, 120 * s),
              0.42,
              Text(jdT(context, 'gardenGrows'), textAlign: TextAlign.center, style: jdText(12 * s, height: 1.1)),
              area: const EdgeInsets.fromLTRB(0.15, 0.22, 0.15, 0.18),
            ),
          ),
          PositionedDirectional(
            start: 6 * s,
            top: (h - shelfH) / 2 + potH * 0.2,
            width: shelfW,
            height: shelfH,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned.fill(child: Image.asset(jd('jd_shelf_tall'), fit: BoxFit.fill)),
              for (var r = 0; r < 3; r++)
                for (var k = 0; k < 2; k++) _slot(jdPlants[r * 2 + k], r * 2 + k, Offset(shelfW * (k == 0 ? 0.3 : 0.7), shelfH * boards[r]), potH, s),
            ]),
          ),
        ]);
      });

  Widget _slot(JdPlant p, int i, Offset base, double potH, double s) {
    final known = _found.contains(p.id);
    final sel = _sel == p.id;
    final a = CurvedAnimation(parent: _intro, curve: Interval(min(0.1 * i, 0.6), min(0.4 + 0.1 * i, 1.0), curve: Curves.easeOutBack));
    final boxW = potH * 1.05;
    return Positioned(
      left: base.dx - boxW / 2,
      top: base.dy - potH * 1.0,
      width: boxW,
      height: potH * 1.28,
      child: AnimatedBuilder(
        animation: a,
        builder: (_, c) => Transform.scale(scale: a.value.clamp(0.0, 1.2), child: c),
        child: JdPress(
          onTap: () => _tap(p),
          label: known ? p.name(context) : null,
          child: Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
            if (sel && known)
              Positioned(
                top: potH * 0.0,
                child: AnimatedBuilder(
                  animation: _idle,
                  builder: (_, c) => Opacity(opacity: 0.5 + 0.5 * sin(_idle.value * 2 * pi * 2).abs(), child: c),
                  child: Container(
                    width: boxW * 1.05,
                    height: potH * 1.02,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [const Color(0xFF8BF7FF).withOpacity(0.75), const Color(0x0039D2FF)]),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 0,
              child: AnimatedBuilder(
                animation: _idle,
                builder: (_, c) => Transform.rotate(
                  alignment: Alignment.bottomCenter,
                  angle: known ? sin((_idle.value * 2 + i * 0.17) * 2 * pi) * 0.025 : 0,
                  child: c,
                ),
                child: JdPot(plant: p, height: potH, locked: !known),
              ),
            ),
            // name plate on the board
            Positioned(
              top: potH * 0.98,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 1 * s),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1D2),
                  borderRadius: BorderRadius.circular(10 * s),
                  border: Border.all(color: sel ? const Color(0xFF39D2FF) : const Color(0xFFD9A55E), width: (sel ? 2.4 : 1.6) * s),
                ),
                child: Text(known ? p.name(context) : '?', style: jdText(11.5 * s, color: const Color(0xFF3F6B12))),
              ),
            ),
            if (known)
              Positioned(right: -boxW * 0.02, top: potH * 0.55, child: Image.asset(jd('jd_check2'), width: potH * 0.24)),
            if (known && p.id == _newest)
              Positioned(
                left: -boxW * 0.18,
                top: potH * 0.02,
                child: Transform.rotate(
                  angle: -0.15,
                  child: jdOnSprite('jd_ribbon', potH * 0.62, 0.6467, Text(jdT(context, 'new'), style: jdText(11 * s, color: Colors.white)),
                      area: const EdgeInsets.fromLTRB(0.18, 0.1, 0.06, 0.38)),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _info(double s, double width, JdPlant p, bool known) {
    final h = width * 0.4537;
    return SizedBox(
      width: width,
      height: h,
      child: Stack(children: [
        Positioned.fill(child: Image.asset(jd('jd_info_big'), fit: BoxFit.fill)),
        // round picture: cover the painted sprout with the selected plant
        Positioned(
          left: width * 0.085,
          top: h * 0.19,
          width: width * 0.31,
          height: width * 0.31,
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [Color(0xFFF4FFE6), Color(0xFFCDEFA9)]),
            ),
            child: Padding(
              padding: EdgeInsets.all(width * 0.03),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                child: JdPot(key: ValueKey('${p.id}$known'), plant: p, height: width * 0.25, locked: !known),
              ),
            ),
          ),
        ),
        Positioned(
          left: width * 0.42,
          right: width * 0.22,
          top: h * 0.14,
          height: h * 0.24,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FittedBox(fit: BoxFit.scaleDown, child: Text(known ? p.my(context) : '?', style: jdText(24 * s, color: jdInk, weight: FontWeight.w800))),
          ),
        ),
        // speaker painted on the card
        Positioned(
          left: width * 0.78,
          width: width * 0.15,
          top: h * 0.14,
          height: h * 0.3,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => JdVoice.say(context, known ? '${p.my(context)}. ${p.fact(context)}' : jdT(context, 'lockedPlant')),
          ),
        ),
        Positioned(
          left: width * 0.42,
          right: width * 0.08,
          top: h * 0.4,
          height: h * 0.22,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: width * 0.5),
                child: Text(known ? p.fact(context) : jdT(context, 'lockedPlant'),
                    textAlign: TextAlign.center, maxLines: 2, style: jdText(13 * s, height: 1.15)),
              ),
            ),
          ),
        ),
        // "watch it grow again" pill painted on the card
        Positioned(
          left: width * 0.42,
          right: width * 0.1,
          top: h * 0.62,
          height: h * 0.24,
          child: JdPress(
            onTap: known
                ? () {
                    jdSound(context, 'clickButton');
                    jdDialog(context, GrowReplay(plant: p), dismissible: true);
                  }
                : null,
            label: jdT(context, 'replayGrow'),
            child: Opacity(
              opacity: known ? 1 : 0.5,
              child: Row(children: [
                SizedBox(width: width * 0.1),
                Expanded(
                  child: FittedBox(fit: BoxFit.scaleDown, child: Text(jdT(context, 'replayGrow'), style: jdText(13.5 * s, color: const Color(0xFF7A3E12)))),
                ),
                SizedBox(width: width * 0.07),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Short animated replay: seed → root → sprout → leaves → the plant.
class GrowReplay extends StatefulWidget {
  final JdPlant plant;
  const GrowReplay({super.key, required this.plant});
  @override
  State<GrowReplay> createState() => _GrowReplayState();
}

class _GrowReplayState extends State<GrowReplay> {
  int _i = 0;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 1100), (_) {
      if (!mounted) return;
      setState(() => _i = (_i + 1) % 6);
      if (_i < 4) JdVoice.say(context, jdT(context, 'st$_i'));
      if (_i == 4) JdVoice.say(context, widget.plant.my(context));
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    JdVoice.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => JdFrame(child: Builder(builder: _page));

  Widget _page(BuildContext context) {
    final s = jdScale(context);
    final stage = min(_i, 4);
    return JdDialogFrame(
      title: jdT(context, 'replayGrow'),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          height: 170 * s,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            transitionBuilder: (c, a) => FadeTransition(opacity: a, child: ScaleTransition(scale: Tween(begin: 0.85, end: 1.0).animate(a), child: c)),
            child: stage < 4
                ? Image.asset(jd('jd_stage$stage'), key: ValueKey(stage), height: 160 * s)
                : JdPot(key: const ValueKey('pot'), plant: widget.plant, height: 165 * s),
          ),
        ),
        SizedBox(height: 8 * s),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var k = 0; k < 4; k++) ...[
            if (k > 0) Icon(Icons.chevron_right_rounded, color: jdGreen, size: 18 * s),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 4 * s),
              decoration: BoxDecoration(
                color: k <= stage ? const Color(0xFFDDF7D4) : const Color(0xFFF1EBDD),
                borderRadius: BorderRadius.circular(12 * s),
                border: Border.all(color: k == stage ? jdGreen : Colors.transparent, width: 2 * s),
              ),
              child: Text(jdT(context, 'st$k'), style: jdText(12 * s, color: k <= stage ? const Color(0xFF2F5A12) : jdInkSoft)),
            ),
          ],
        ]),
        SizedBox(height: 10 * s),
        jdNote(widget.plant.fact(context), s),
        SizedBox(height: 12 * s),
        JdFlatButton(label: jdT(context, 'understood'), onTap: () => Navigator.pop(context), width: 220 * s),
      ]),
    );
  }
}
