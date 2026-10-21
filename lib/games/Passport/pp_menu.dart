import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:provider/provider.dart';

import 'pp_data.dart';
import 'pp_passport.dart';
import 'pp_play.dart';
import 'pp_strings.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Shared navigation helpers
// ═══════════════════════════════════════════════════════════════════════════

PageRoute<T> ppRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, c) => FadeTransition(
        opacity: a,
        child: ScaleTransition(scale: Tween(begin: 1.05, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)), child: c),
      ),
    );

Widget ppMute(BuildContext context, double size) => Consumer<AudioManager>(
      builder: (_, a, __) => Opacity(
        opacity: a.isBgMuted ? 0.5 : 1,
        child: ppRound(context, 'pp_sound', size, () {
          a.playEventSound('toggleButton');
          a.toggleBgMute();
        }),
      ),
    );

/// Plays a stage and keeps going with the next one when the child asks.
Future<void> ppOpenStage(BuildContext context, PpStage first) async {
  var stage = first;
  while (context.mounted) {
    final r = await Navigator.of(context).push<String>(PageRouteBuilder<String>(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, __, ___) => StagePlay(stage: stage),
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
    ));
    if (!context.mounted) return;
    if (r == 'passport') {
      await Navigator.of(context).push(ppRoute(MyPassportPage(highlight: stage.id)));
      return;
    }
    if (r != 'next') return;
    final prog = await PpStore.load();
    final land = stage.land;
    final i = land.stages.indexOf(stage);
    if (i + 1 < land.stages.length) {
      stage = land.stages[i + 1];
    } else {
      final n = prog.next;
      if (prog.done(n.id)) return; // everything finished
      stage = n;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Dialog frame
// ═══════════════════════════════════════════════════════════════════════════

class PpDialog extends StatelessWidget {
  final String title;
  final Widget child;
  final bool blue;
  const PpDialog({super.key, required this.title, required this.child, this.blue = false});
  @override
  Widget build(BuildContext context) => PpFrame(child: Builder(builder: _page));

  Widget _page(BuildContext context) {
    final s = ppScale(context);
    final w = min(MediaQuery.sizeOf(context).width - 30, 380.0);
    final rw = w * 0.86;
    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: SizedBox(
          width: w,
          child: Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
            Container(
              margin: EdgeInsets.only(top: rw * 0.17),
              padding: EdgeInsets.fromLTRB(18 * s, rw * 0.22, 18 * s, 18 * s),
              decoration: BoxDecoration(
                color: ppCream,
                borderRadius: BorderRadius.circular(28 * s),
                border: Border.all(color: const Color(0xFF5B2DBA), width: 5 * s),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFFFC94A).withOpacity(0.6), blurRadius: 24 * s, spreadRadius: 2 * s),
                  BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 14 * s, offset: Offset(0, 6 * s)),
                ],
              ),
              child: child,
            ),
            SizedBox(
              width: rw,
              child: ppOnSprite(
                blue ? 'pp_ribbon_blue' : 'pp_ribbon_purple',
                rw,
                blue ? 0.35 : 0.3389,
                Text(title, style: ppText(26 * s, color: Colors.white, weight: FontWeight.w800).copyWith(shadows: const [Shadow(color: Color(0x88000000), offset: Offset(0, 2))])),
                area: const EdgeInsets.fromLTRB(0.16, 0.1, 0.16, 0.36),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

Future<T?> ppDialog<T>(BuildContext context, Widget child, {bool dismissible = false}) => showGeneralDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      barrierLabel: 'pp',
      barrierColor: const Color(0x99251060),
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (_, __, ___) => child,
      transitionBuilder: (_, a, __, c) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: c),
    );

Widget ppNote(String text, double s) => Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 8 * s),
      decoration: BoxDecoration(color: const Color(0xFFEDE4FF), borderRadius: BorderRadius.circular(14 * s)),
      child: Text(text, textAlign: TextAlign.center, style: ppText(15 * s, color: ppInk, weight: FontWeight.w600)),
    );

Future<void> showPpHelp(BuildContext context) => ppDialog(context, const _HelpDialog(), dismissible: true);

class _HelpDialog extends StatelessWidget {
  const _HelpDialog();
  @override
  Widget build(BuildContext context) => PpFrame(child: Builder(builder: _page));
  Widget _page(BuildContext context) {
    final s = ppScale(context);
    Widget step(int n, String art) => Expanded(
          child: Column(children: [
            Stack(clipBehavior: Clip.none, children: [
              Container(
                height: 76 * s,
                width: double.infinity,
                padding: EdgeInsets.all(6 * s),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16 * s), border: Border.all(color: const Color(0xFFF0D9A8), width: 2 * s)),
                child: Image.asset(pp(art), fit: BoxFit.contain),
              ),
              Positioned(
                left: -4 * s,
                top: -6 * s,
                child: CircleAvatar(radius: 12 * s, backgroundColor: ppOrange, child: Text('$n', style: ppText(13 * s, color: Colors.white))),
              ),
            ]),
            SizedBox(height: 4 * s),
            SizedBox(height: 34 * s, child: Center(child: Text(ppT(context, 'help$n'), textAlign: TextAlign.center, style: ppText(12.5 * s, height: 1.1)))),
          ]),
        );
    return PpDialog(
      title: ppT(context, 'how'),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Image.asset(pp('pp_robot_point'), height: 86 * s),
          SizedBox(width: 6 * s),
          Expanded(child: Text(ppT(context, 'helpIntro'), style: ppText(14 * s, color: ppInkSoft, weight: FontWeight.w600))),
        ]),
        SizedBox(height: 10 * s),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          step(1, 'pp_pin'),
          SizedBox(width: 8 * s),
          step(2, 'pp_magnif_photo'),
          SizedBox(width: 8 * s),
          step(3, 'pp_stamp_camel'),
        ]),
        SizedBox(height: 12 * s),
        ppFlat(ppT(context, 'letsGo'), () => Navigator.pop(context), 230 * s),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Home — "Le passeport magique"
// ═══════════════════════════════════════════════════════════════════════════

class PassportMenu extends StatefulWidget {
  const PassportMenu({super.key});
  @override
  State<PassportMenu> createState() => _PassportMenuState();
}

class _PassportMenuState extends State<PassportMenu> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..forward();
  PpProgress _p = const PpProgress({}, null);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await PpStore.load();
    if (mounted) setState(() => _p = p);
  }

  @override
  void dispose() {
    PpVoice.stop();
    _idle.dispose();
    _intro.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    ppSound(context, 'PopButton');
    if (!await PpStore.seenHelp()) {
      if (!mounted) return;
      await showPpHelp(context);
      await PpStore.setSeenHelp();
    }
    if (!mounted) return;
    final next = _p.next;
    await Navigator.of(context).push(ppRoute(CountryMapPage(country: next.land, focus: next)));
    _load();
  }

  Future<void> _dest() async {
    ppSound(context, 'clickButton');
    await Navigator.of(context).push(ppRoute(const DestinationsPage()));
    _load();
  }

  Future<void> _passport() async {
    ppSound(context, 'clickButton');
    await Navigator.of(context).push(ppRoute(const MyPassportPage()));
    _load();
  }

  Widget _step(int i, Widget c) {
    final a = CurvedAnimation(parent: _intro, curve: Interval(min(0.1 * i, 0.6), min(0.5 + 0.1 * i, 1.0), curve: Curves.easeOutBack));
    return AnimatedBuilder(
      animation: a,
      builder: (_, child) => Opacity(opacity: a.value.clamp(0.0, 1.0), child: Transform.translate(offset: Offset(0, (1 - a.value) * 30), child: child)),
      child: c,
    );
  }

  @override
  Widget build(BuildContext context) => PpFrame(child: Builder(builder: _page));

  Widget _page(BuildContext context) {
    final s = ppScale(context);
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final w = min(size.width, 520.0);
    return Scaffold(
      backgroundColor: const Color(0xFF8FD3F5),
      body: Stack(children: [
        const Positioned.fill(child: PpBg()),
        // the hero picture fills the top
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: size.height * 0.62,
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (r) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black, Colors.black, Colors.transparent],
              stops: [0, 0.82, 1],
            ).createShader(r),
            child: Image.asset(pp('pp_hero'), fit: BoxFit.cover, alignment: const Alignment(0, 0.3)),
          ),
        ),
        // plane & balloon drifting
        AnimatedBuilder(
          animation: _idle,
          builder: (_, __) {
            final t = _idle.value;
            return Stack(children: [
              Positioned(
                left: -80 * s + (w + 160 * s) * t,
                top: pad.top + 150 * s + sin(t * 2 * pi) * 10 * s,
                child: IgnorePointer(child: Image.asset(pp('pp_plane'), width: 70 * s)),
              ),
              PositionedDirectional(
                end: 14 * s,
                top: pad.top + 92 * s + sin(t * 2 * pi * 2) * 8 * s,
                child: IgnorePointer(child: Image.asset(pp('pp_balloon'), width: 44 * s)),
              ),
            ]);
          },
        ),
        SafeArea(
          child: Center(
            child: SizedBox(
              width: w,
              child: Column(children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 4 * s),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ppRound(context, 'pp_back', 46 * s, () {
                      ppSound(context, 'cancelButton');
                      Navigator.of(context).maybePop();
                    }, flipRtl: true),
                    Expanded(child: _step(0, _title(s, w))),
                    ppMute(context, 46 * s),
                  ]),
                ),
                const Spacer(),
                _step(2, _panel(s, w)),
                SizedBox(height: 8 * s),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _title(double s, double w) => AnimatedBuilder(
        animation: _idle,
        builder: (_, c) => Transform.translate(offset: Offset(0, sin(_idle.value * 2 * pi * 2) * 3 * s), child: c),
        child: Column(children: [
          FittedBox(fit: BoxFit.scaleDown, child: ppOutlined(ppT(context, 't1'), ppGold, 42 * s, gradient: ppGoldText, outline: ppInk, stroke: 0.22)),
          Transform.translate(
            offset: Offset(0, -8 * s),
            child: FittedBox(fit: BoxFit.scaleDown, child: ppOutlined(ppT(context, 't2'), ppGold, 46 * s, gradient: ppGoldText, outline: ppInk, stroke: 0.22)),
          ),
          Transform.translate(
            offset: Offset(0, -10 * s),
            child: ppOnSprite('pp_pill_compass', min(w * 0.6, 230 * s), 0.2, Text(ppT(context, 'tag'), style: ppText(15 * s)),
                area: const EdgeInsets.fromLTRB(0.15, 0.12, 0.15, 0.16)),
          ),
        ]),
      );

  Widget _panel(double s, double w) {
    final stamps = _p.stamps;
    Widget feature(int i, String art) => Expanded(
          child: PpPress(
            onTap: i == 2 ? _passport : (i == 1 ? _dest : _go),
            label: ppT(context, 'f${i + 1}'),
            child: Container(
              height: 104 * s,
              margin: EdgeInsets.symmetric(horizontal: 4 * s),
              padding: EdgeInsets.fromLTRB(6 * s, 6 * s, 6 * s, 4 * s),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3DC),
                borderRadius: BorderRadius.circular(18 * s),
                border: Border.all(color: const Color(0xFFF1D7A6), width: 2 * s),
              ),
              child: Column(children: [
                Expanded(
                  child: AnimatedBuilder(
                    animation: _idle,
                    builder: (_, c) => Transform.translate(offset: Offset(0, sin((_idle.value * 3 + i * 0.3) * 2 * pi) * 2.5 * s), child: c),
                    child: Image.asset(pp(art), fit: BoxFit.contain),
                  ),
                ),
                FittedBox(fit: BoxFit.scaleDown, child: Text('· ${ppT(context, 'f${i + 1}')} ·', style: ppText(14 * s))),
              ]),
            ),
          ),
        );
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12 * s),
      padding: EdgeInsets.fromLTRB(10 * s, 12 * s, 10 * s, 10 * s),
      decoration: BoxDecoration(
        color: ppCream.withOpacity(0.97),
        borderRadius: BorderRadius.circular(30 * s),
        border: Border.all(color: Colors.white, width: 3 * s),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 18 * s, offset: Offset(0, 6 * s))],
      ),
      child: Column(children: [
        Row(children: [feature(0, 'pp_globe_cloud'), feature(1, 'pp_magnif_map'), feature(2, 'pp_passport_open')]),
        SizedBox(height: 10 * s),
        PpButton.plane(ppT(context, 'go'), _go, min(w * 0.82, 320 * s), pulse: _idle),
        SizedBox(height: 8 * s),
        PpPill(
          label: ppT(context, 'choose'),
          icon: Image.asset(pp('pp_pin'), height: 22 * s),
          onTap: _dest,
          s: s,
          border: const Color(0xFF2B3FA8),
        ),
        TextButton.icon(
          onPressed: () {
            ppSound(context, 'clickButton');
            showPpHelp(context);
          },
          icon: Image.asset(pp('pp_help'), height: 22 * s),
          label: Text(ppT(context, 'how'), style: ppText(13.5 * s).copyWith(decoration: TextDecoration.underline)),
        ),
        // stamps bar
        PpPress(
          onTap: _passport,
          label: ppT(context, 'myPassport'),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 6 * s),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18 * s), border: Border.all(color: const Color(0xFFF1D7A6), width: 2 * s)),
            child: Row(children: [
              Image.asset(pp('pp_passport_book'), height: 40 * s),
              SizedBox(width: 8 * s),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(ppT(context, 'stampsN', {'n': stamps}), style: ppText(15 * s)),
                ),
              ),
              for (final seal in ['pp_seal_MA', 'pp_seal_FR', 'pp_seal_EG'])
                Padding(
                  padding: EdgeInsets.only(left: 4 * s),
                  child: Opacity(
                    opacity: _p.doneIn(ppCountry(seal.substring(8))) > 0 ? 1 : 0.35,
                    child: Image.asset(pp(seal), height: 34 * s),
                  ),
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Destinations — "Où partons-nous ?"
// ═══════════════════════════════════════════════════════════════════════════

class DestinationsPage extends StatefulWidget {
  const DestinationsPage({super.key});
  @override
  State<DestinationsPage> createState() => _DestinationsPageState();
}

class _DestinationsPageState extends State<DestinationsPage> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  PpProgress _p = const PpProgress({}, null);
  String _sel = 'MA';
  String _shakeId = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await PpStore.load();
    if (mounted) setState(() => _p = p);
  }

  @override
  void dispose() {
    PpVoice.stop();
    _idle.dispose();
    _intro.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _tap(PpCountry c) {
    if (!_p.countryOpen(c)) {
      ppSound(context, 'clickButton2');
      setState(() => _shakeId = c.id);
      _shake.forward(from: 0);
      final msg = ppT(context, 'locked', {'n': c.need});
      PpVoice.say(context, msg);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: ppInk,
          duration: const Duration(milliseconds: 1600),
          content: Text(msg, style: ppText(15, color: Colors.white, weight: FontWeight.w600)),
        ));
      return;
    }
    ppSound(context, 'PopButton');
    setState(() => _sel = c.id);
    PpVoice.say(context, '${c.name(context)}. ${c.desc(context)}');
  }

  Future<void> _explore() async {
    ppSound(context, 'PopButton');
    final c = ppCountry(_sel);
    await Navigator.of(context).push(ppRoute(CountryMapPage(country: c, focus: _p.nextIn(c))));
    _load();
  }

  @override
  Widget build(BuildContext context) => PpFrame(child: Builder(builder: _page));

  Widget _page(BuildContext context) {
    final s = ppScale(context);
    final size = MediaQuery.sizeOf(context);
    final w = min(size.width, 520.0);
    final c = ppCountry(_sel);
    return Scaffold(
      backgroundColor: const Color(0xFF8FD3F5),
      body: Stack(children: [
        const Positioned.fill(child: PpBg(asset: 'pp_bg_dest')),
        SafeArea(
          child: Center(
            child: SizedBox(
              width: w,
              child: Column(children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 4 * s),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ppRound(context, 'pp_back', 44 * s, () {
                      ppSound(context, 'cancelButton');
                      Navigator.of(context).maybePop();
                    }, flipRtl: true),
                    Expanded(
                      child: Column(children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            ppOutlined(ppT(context, 'destA'), ppInk, 34 * s, gradient: ppPurpleText),
                            SizedBox(width: 6 * s),
                            ppOutlined(ppT(context, 'destB'), ppGold, 34 * s, gradient: ppGoldText, outline: ppInk),
                          ]),
                        ),
                      ]),
                    ),
                    ppMute(context, 44 * s),
                  ]),
                ),
                SizedBox(height: 6 * s),
                Expanded(child: _grid(s, w)),
                SizedBox(height: 6 * s),
                _info(s, w, c),
                SizedBox(height: 8 * s),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Flexible(child: PpButton.plane(ppT(context, 'explore', {'c': c.name(context)}), _explore, min(w * 0.64, 250 * s), pulse: _idle)),
                  SizedBox(width: 8 * s),
                  PpPress(
                    onTap: () async {
                      ppSound(context, 'clickButton');
                      await Navigator.of(context).push(ppRoute(const MyPassportPage()));
                      _load();
                    },
                    label: ppT(context, 'myPassport'),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 6 * s),
                      decoration: BoxDecoration(
                        color: ppCream,
                        borderRadius: BorderRadius.circular(16 * s),
                        border: Border.all(color: const Color(0xFF2B3FA8), width: 2 * s),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Image.asset(pp('pp_passport_book'), height: 34 * s),
                        SizedBox(width: 4 * s),
                        Text(ppT(context, 'myPassport').replaceFirst(' ', '\n'), style: ppText(12 * s, height: 1.05)),
                      ]),
                    ),
                  ),
                ]),
                SizedBox(height: 10 * s),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _grid(double s, double w) => LayoutBuilder(builder: (_, b) {
        final cw = min((w - 34 * s) / 2, (b.maxHeight - 16 * s) / 3 * 1.7374);
        final ch = cw / 1.7374;
        return Center(
          child: Wrap(spacing: 10 * s, runSpacing: 8 * s, children: [
            for (var i = 0; i < ppCountries.length; i++) _card(ppCountries[i], i, cw, ch, s),
          ]),
        );
      });

  Widget _card(PpCountry c, int i, double cw, double ch, double s) {
    final open = _p.countryOpen(c);
    final sel = _sel == c.id;
    final a = CurvedAnimation(parent: _intro, curve: Interval(min(0.08 * i, 0.6), min(0.45 + 0.08 * i, 1.0), curve: Curves.easeOutBack));
    final done = _p.doneIn(c);
    return AnimatedBuilder(
      animation: Listenable.merge([a, _shake]),
      builder: (_, child) => Transform.translate(
        offset: Offset(_shakeId == c.id ? sin(_shake.value * pi * 6) * 7 * (1 - _shake.value) : 0, 0),
        child: Transform.scale(scale: a.value.clamp(0.0, 1.2), child: child),
      ),
      child: PpPress(
        onTap: () => _tap(c),
        label: c.name(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: cw,
          height: ch,
          padding: EdgeInsets.all(3 * s),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFF5EE7FF) : const Color(0xFFFFF0C8),
            borderRadius: BorderRadius.circular(18 * s),
            boxShadow: [
              if (sel) BoxShadow(color: const Color(0xFF38D7FF).withOpacity(0.8), blurRadius: 14 * s, spreadRadius: 2 * s),
              BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 6 * s, offset: Offset(0, 3 * s)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15 * s),
            child: Stack(fit: StackFit.expand, children: [
              open
                  ? Image.asset(pp(c.card), fit: BoxFit.cover)
                  : ColorFiltered(
                      colorFilter: const ColorFilter.matrix(<double>[
                        0.35, 0.45, 0.1, 0, 30, //
                        0.35, 0.45, 0.1, 0, 30,
                        0.35, 0.45, 0.1, 0, 30,
                        0, 0, 0, 1, 0,
                      ]),
                      child: Image.asset(pp(c.card), fit: BoxFit.cover),
                    ),
              // name on the painted pill
              Positioned(
                left: cw * 0.27,
                right: cw * 0.27,
                bottom: ch * 0.05,
                height: ch * 0.15,
                child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(c.name(context), style: ppText(16 * s)))),
              ),
              if (c.seal != null && open)
                Positioned(right: 5 * s, top: 5 * s, child: Image.asset(pp(c.seal!), width: cw * 0.2)),
              if (!open) Positioned(right: 6 * s, top: 6 * s, child: Image.asset(pp('pp_lock'), width: cw * 0.15)),
              if (open && done > 0)
                Positioned(
                  left: 6 * s,
                  top: 6 * s,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6 * s, vertical: 2 * s),
                    decoration: BoxDecoration(color: ppCream, borderRadius: BorderRadius.circular(10 * s)),
                    child: Text('★ $done/${c.stages.length}', style: ppText(11 * s, color: const Color(0xFFE09A00))),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _info(double s, double w, PpCountry c) => Container(
        margin: EdgeInsets.symmetric(horizontal: 12 * s),
        height: 112 * s,
        decoration: BoxDecoration(
          color: ppCream,
          borderRadius: BorderRadius.circular(24 * s),
          border: Border.all(color: Colors.white, width: 3 * s),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10 * s, offset: Offset(0, 4 * s))],
        ),
        child: Row(children: [
          SizedBox(width: 4 * s),
          Image.asset(pp('pp_rb_duo'), height: 106 * s),
          Image.asset(pp('pp_kid_duo'), height: 92 * s),
          SizedBox(width: 6 * s),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Column(key: ValueKey(c.id), mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                FittedBox(fit: BoxFit.scaleDown, child: Text('✦ ${c.name(context)} ✦', style: ppText(26 * s, weight: FontWeight.w800))),
                Text(c.desc(context), maxLines: 3, style: ppText(12.5 * s, color: ppInkSoft, weight: FontWeight.w600, height: 1.15)),
              ]),
            ),
          ),
          SizedBox(width: 10 * s),
        ]),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// Country map — "Mon aventure au Maroc"
// ═══════════════════════════════════════════════════════════════════════════

class CountryMapPage extends StatefulWidget {
  final PpCountry country;
  final PpStage? focus;
  const CountryMapPage({super.key, required this.country, this.focus});
  @override
  State<CountryMapPage> createState() => _CountryMapPageState();
}

class _CountryMapPageState extends State<CountryMapPage> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  late final AnimationController _walk = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..value = 1;
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  PpProgress _p = const PpProgress({}, null);
  late PpStage _sel = widget.focus ?? widget.country.stages.first;
  late PpStage _from = _sel;
  String _shakeId = '';

  PpCountry get _c => widget.country;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await PpStore.load();
    if (!mounted) return;
    setState(() {
      _p = p;
      if (!p.stageOpen(_sel)) _sel = p.nextIn(_c);
    });
  }

  @override
  void dispose() {
    PpVoice.stop();
    _idle.dispose();
    _walk.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _tap(PpStage st) {
    if (!_p.stageOpen(st)) {
      ppSound(context, 'clickButton2');
      setState(() => _shakeId = st.id);
      _shake.forward(from: 0);
      PpVoice.say(context, ppT(context, 'lockedStage'));
      return;
    }
    ppSound(context, 'PopButton');
    setState(() {
      _from = _sel;
      _sel = st;
    });
    _walk.forward(from: 0);
    PpVoice.say(context, '${st.title(context)}, ${st.city(context)}');
  }

  Future<void> _start() async {
    ppSound(context, 'PopButton');
    await ppOpenStage(context, _sel);
    await _load();
    if (!mounted) return;
    setState(() {
      _from = _sel;
      final nx = _p.nextIn(_c);
      if (_p.stageOpen(nx)) _sel = nx;
    });
  }

  @override
  Widget build(BuildContext context) => PpFrame(child: Builder(builder: _page));

  Widget _page(BuildContext context) {
    final s = ppScale(context);
    final size = MediaQuery.sizeOf(context);
    final w = min(size.width, 520.0);
    return Scaffold(
      backgroundColor: const Color(0xFF8FD3F5),
      body: Stack(children: [
        const Positioned.fill(child: PpBg(asset: 'pp_bg_map')),
        SafeArea(
          child: Center(
            child: SizedBox(
              width: w,
              child: Column(children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 4 * s),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ppRound(context, 'pp_back', 44 * s, () {
                      ppSound(context, 'cancelButton');
                      Navigator.of(context).maybePop();
                    }, flipRtl: true),
                    Expanded(
                      child: Center(
                        child: Stack(clipBehavior: Clip.none, children: [
                          PpHeader(a: ppT(context, 'advA'), b: _c.name(context), width: min(w * 0.68, 270 * s), ribbon: true),
                          if (_c.id == 'MA')
                            Positioned(left: -6 * s, top: 0, child: Image.asset(pp('pp_flag'), width: 52 * s)),
                        ]),
                      ),
                    ),
                    ppMute(context, 44 * s),
                  ]),
                ),
                Expanded(child: LayoutBuilder(builder: (_, b) => _map(s, b.maxWidth, b.maxHeight))),
                _card(s, w),
                SizedBox(height: 8 * s),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  /// Positions of the stage nodes (fractions of the map box), zig-zag downwards.
  List<Offset> _layout(int n) {
    if (n == 1) return const [Offset(0.5, 0.5)];
    return [
      for (var i = 0; i < n; i++)
        Offset(
          0.5 + (i.isEven ? -1 : 1) * (0.22 + 0.08 * sin(i * 1.3)),
          0.1 + 0.8 * i / (n - 1),
        ),
    ];
  }

  Widget _map(double s, double mw, double mh) {
    final stages = _c.stages;
    final pts = [for (final o in _layout(stages.length)) Offset(o.dx * mw, o.dy * mh)];
    final node = min(64 * s, mh / max(4, stages.length) * 0.85);
    final thumb = node * 1.05;
    return AnimatedBuilder(
      animation: Listenable.merge([_idle, _walk, _shake]),
      builder: (_, __) {
        final a = pts[stages.indexOf(_from)], b = pts[stages.indexOf(_sel)];
        final t = Curves.easeInOut.transform(_walk.value);
        final hop = _walk.isAnimating ? sin(t * pi * 4).abs() * 10 * s : 0.0;
        final rp = Offset.lerp(a, b, t)! + Offset(0, -hop);
        return Stack(clipBehavior: Clip.none, children: [
          Positioned.fill(child: CustomPaint(painter: _TrailPainter(pts, s, _idle.value))),
          for (var i = 0; i < stages.length; i++) ...[
            // picture of the place next to its node
            Positioned(
              left: pts[i].dx + (pts[i].dx < mw / 2 ? node * 0.55 : -node * 0.55 - thumb * 1.4),
              top: pts[i].dy - thumb * 0.5,
              width: thumb * 1.4,
              height: thumb,
              child: IgnorePointer(
                child: Opacity(
                  opacity: _p.stageOpen(stages[i]) ? 1 : 0.55,
                  child: Container(
                    padding: EdgeInsets.all(2.5 * s),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10 * s),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4 * s, offset: Offset(0, 2 * s))],
                    ),
                    child: ClipRRect(borderRadius: BorderRadius.circular(8 * s), child: Image.asset(stages[i].scene, fit: BoxFit.cover)),
                  ),
                ),
              ),
            ),
            _node(stages[i], i, pts[i], node, s),
          ],
          // Waki walks to the selected stage
          Positioned(
            left: rp.dx - node * 1.25,
            top: rp.dy - node * 1.25,
            child: IgnorePointer(
              child: Transform.translate(
                offset: Offset(0, sin(_idle.value * 2 * pi * 2) * 2 * s),
                child: Transform.flip(flipX: b.dx < a.dx, child: Image.asset(pp('pp_robot_wave'), height: node * 1.2)),
              ),
            ),
          ),
        ]);
      },
    );
  }

  Widget _node(PpStage st, int i, Offset c, double size, double s) {
    final open = _p.stageOpen(st);
    final done = _p.done(st.id);
    final sel = st == _sel;
    final sprite = !open ? 'pp_node_lock' : (sel ? 'pp_node_now' : (done ? 'pp_node_done' : 'pp_node_cyan'));
    final ratio = switch (sprite) { 'pp_node_lock' => 1.3, 'pp_node_done' => 1.0412, _ => 1.2067 };
    final w = size * (sprite == 'pp_node_done' ? 1.15 : 0.95);
    final h = w * ratio;
    final shake = _shakeId == st.id ? sin(_shake.value * pi * 6) * 6 * (1 - _shake.value) : 0.0;
    final pulse = sel ? 1.06 + 0.05 * sin(_idle.value * 2 * pi * 3) : 1.0;
    final stars = _p.of(st.id);
    return Positioned(
      left: c.dx - w / 2 + shake,
      top: c.dy - h * 0.42,
      width: w,
      height: h,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _tap(st),
        child: Transform.scale(
          scale: pulse,
          child: Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
            if (sel)
              Positioned(
                top: -h * 0.12,
                child: Container(
                  width: w * 1.1,
                  height: w * 1.1,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [const Color(0xFFFFE27A).withOpacity(0.8), const Color(0x00FFE27A)]),
                  ),
                ),
              ),
            Positioned.fill(child: Image.asset(pp(sprite), fit: BoxFit.fill)),
            Positioned(
              top: h * (sprite == 'pp_node_done' ? 0.12 : 0.16),
              child: Text('${i + 1}',
                  style: ppText(w * 0.42, color: open ? Colors.white : const Color(0xFF5B5B66), weight: FontWeight.w800)
                      .copyWith(shadows: [Shadow(color: Colors.black.withOpacity(0.35), offset: const Offset(0, 2), blurRadius: 2)])),
            ),
            // the "done" sprite always shows 3 stars: hide the ones not won
            if (sprite == 'pp_node_done' && stars < 3)
              Positioned(
                bottom: 0,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  for (var k = 0; k < 3; k++)
                    Icon(Icons.star_rounded, size: w * 0.3, color: k < stars ? const Color(0xFFFFC21A) : const Color(0xFFE9E1CF)),
                ]),
              ),
            if (sel && done)
              Positioned(
                bottom: -w * 0.2,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  for (var k = 0; k < 3; k++)
                    Icon(Icons.star_rounded, size: w * 0.28, color: k < stars ? const Color(0xFFFFC21A) : Colors.white.withOpacity(0.8)),
                ]),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _card(double s, double w) {
    final st = _sel;
    final i = st.index;
    final done = _p.done(st.id);
    Widget mini(String art, String key) => Column(mainAxisSize: MainAxisSize.min, children: [
          Image.asset(pp(art), height: 34 * s),
          SizedBox(height: 2 * s),
          FittedBox(fit: BoxFit.scaleDown, child: Text(ppT(context, key), style: ppText(10.5 * s, weight: FontWeight.w600))),
        ]);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10 * s),
      padding: EdgeInsets.fromLTRB(8 * s, 8 * s, 10 * s, 10 * s),
      decoration: BoxDecoration(
        color: ppCream,
        borderRadius: BorderRadius.circular(24 * s),
        border: Border.all(color: const Color(0xFFF1D7A6), width: 3 * s),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12 * s, offset: Offset(0, 4 * s))],
      ),
      child: Row(children: [
        PpPress(
          onTap: () async {
            ppSound(context, 'clickButton');
            await Navigator.of(context).push(ppRoute(MyPassportPage(highlight: st.id)));
            _load();
          },
          label: ppT(context, 'myPassport'),
          child: Image.asset(pp('pp_passport_book'), height: 92 * s),
        ),
        SizedBox(width: 8 * s),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: Column(key: ValueKey(st.id), crossAxisAlignment: CrossAxisAlignment.start, children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: '${ppT(context, 'step', {'n': i + 1})} · ', style: ppText(19 * s, color: ppOrange, weight: FontWeight.w800)),
                  TextSpan(text: st.title(context), style: ppText(19 * s, weight: FontWeight.w800)),
                ])),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text('📍 ${st.city(context)}', style: ppText(13 * s, color: ppInkSoft, weight: FontWeight.w600)),
              ),
              SizedBox(height: 6 * s),
              Row(children: [
                Expanded(child: mini('pp_eye', 'obs')),
                Expanded(child: mini('pp_puzzle', 'solve')),
                Expanded(child: mini('pp_stamp_camel', 'collect')),
                SizedBox(width: 4 * s),
                Expanded(
                  flex: 4,
                  child: FittedBox(fit: BoxFit.scaleDown, child: PpButton.main(ppT(context, done ? 'replayStage' : 'start'), _start, 150 * s, pulse: _idle)),
                ),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// Glowing dotted trail between the stages.
class _TrailPainter extends CustomPainter {
  final List<Offset> pts;
  final double s, t;
  _TrailPainter(this.pts, this.s, this.t);
  @override
  void paint(Canvas canvas, Size size) {
    if (pts.length < 2) return;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1], b = pts[i];
      path.cubicTo(a.dx, (a.dy + b.dy) / 2, b.dx, (a.dy + b.dy) / 2, b.dx, b.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 30 * s
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFFFD86B).withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20 * s
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFFFF4D6),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * s
        ..color = const Color(0xFFF2C14E),
    );
    for (final m in path.computeMetrics()) {
      final step = 26 * s;
      for (double d = (t * step * 3) % step; d < m.length; d += step) {
        final tg = m.getTangentForOffset(d);
        if (tg == null) continue;
        canvas.drawCircle(tg.position, 4.2 * s, Paint()..color = const Color(0xFF2FC6E8));
        canvas.drawCircle(tg.position - Offset(1.2 * s, 1.2 * s), 1.4 * s, Paint()..color = Colors.white.withOpacity(0.9));
      }
    }
  }

  @override
  bool shouldRepaint(_TrailPainter o) => true;
}
