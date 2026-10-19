import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/KidScene/kid_page_parts.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:provider/provider.dart';

import 'alpha_draw_data.dart';
import 'alpha_draw_page.dart';
import 'alpha_draw_ui.dart';

/// Alpha Draw home: pick a language and a mode, then start writing.
class AlphaDrawMenuPage extends StatefulWidget {
  const AlphaDrawMenuPage({super.key});
  @override
  State<AlphaDrawMenuPage> createState() => _AlphaDrawMenuPageState();
}

class _AlphaDrawMenuPageState extends State<AlphaDrawMenuPage> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  String _selected = 'french';
  AdMode _mode = AdMode.trace;
  Map<String, int> _done = {};
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final last = await AdStore.lastLanguage();
    final mode = await AdStore.lastMode();
    final done = await AdStore.doneCounts();
    if (!mounted) return;
    final locale = Localizations.localeOf(context).languageCode;
    setState(() {
      _selected = last ?? (locale == 'ar' ? 'arabic' : locale == 'en' ? 'english' : 'french');
      if (!_unlocked(adLanguage(_selected))) _selected = 'french';
      _mode = mode;
      _done = done;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      KidAssets.precache(context, [
        '${adDir}it_page_bg.webp', '${adDir}ad_robot_pencil.webp', '${adDir}ad_hero_tiles.webp',
        for (final l in adLanguages) l.tile,
        '${adDir}ad_robot_point.webp', '${adDir}ad_pencil.webp', '${adDir}ad_plane.webp',
      ]);
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _idle.dispose();
    super.dispose();
  }

  AudioManager get _audio => Provider.of<AudioManager>(context, listen: false);
  ExperienceManager get _xp => Provider.of<ExperienceManager>(context, listen: false);

  bool _unlocked(AdLanguage l) => l.cost == 0 || _xp.isLanguageUnlocked(l.code);

  Future<void> _tapLanguage(AdLanguage l) async {
    if (!_unlocked(l)) {
      _audio.playEventSound('clickButton2');
      final ok = await _askUnlock(l);
      if (ok != true || !mounted) return;
      if (!_xp.unlockLanguage(l.code, l.cost)) return;
      try {
        await _audio.playSfx('assets/audios/sound_effects/unlock_sound.mp3');
      } catch (_) {}
    } else {
      _audio.playEventSound('PopButton');
    }
    setState(() => _selected = l.code);
    AdStore.setLastLanguage(l.code);
  }

  Future<bool?> _askUnlock(AdLanguage l) {
    final enough = _xp.gold >= l.cost;
    final name = l.names[adLang(context)] ?? l.native;
    return showDialog<bool>(
      context: context,
      barrierColor: KidColors.purpleDeep.withOpacity(0.35),
      builder: (ctx) => KidDialog(
        title: adText(ctx, 'unlockTitle').replaceAll('{N}', name),
        message: adText(ctx, enough ? 'unlockMsg' : 'notEnough').replaceAll('{C}', '${l.cost}'),
        content: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Image.asset(l.tile, width: 70, height: 70 * l.tileAspect),
          const SizedBox(width: 14),
          Image.asset(kidCoinAsset, width: 34, height: 34),
          Text(' ${l.cost}', style: kidTitleStyle(26, color: adInk).copyWith(shadows: const [])),
        ]),
        actions: [
          if (enough)
            KidButton(label: adText(ctx, 'unlock'), onPressed: () => Navigator.pop(ctx, true), width: 220, height: 56, showArrow: false),
          KidOutlineButton(label: adText(ctx, enough ? 'later' : 'ok'), onTap: () => Navigator.pop(ctx, false)),
        ],
      ),
    );
  }

  Future<void> _start() async {
    final l = adLanguage(_selected);
    if (!_unlocked(l)) return _tapLanguage(l);
    _audio.playEventSound('PopButton');
    AdStore.setLastLanguage(l.code);
    AdStore.setLastMode(_mode);
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => AlphaDrawPage(language: l.code, mode: _mode),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
    final done = await AdStore.doneCounts();
    if (mounted) setState(() => _done = done);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final w = min(size.width, 600.0) - 28;
    final s = (w / 380).clamp(0.8, 1.4).toDouble();
    Widget step(int i, Widget c) => KidIntro(intro: _intro, from: 0.05 * i, to: min(1.0, 0.45 + 0.05 * i), rise: 22, child: c);
    context.watch<ExperienceManager>(); // unlocks / gold

    final grid = adLanguages.take(6).toList();
    final more = adLanguages.skip(6).toList();

    return Scaffold(
      backgroundColor: KidColors.sky,
      body: Stack(children: [
        const Positioned.fill(child: KidPageBackground(asset: '${adDir}it_page_bg.webp', wash: 0.03)),
        SafeArea(
          bottom: false,
          child: Center(
            child: SizedBox(
              width: w,
              child: Column(children: [
                const SizedBox(height: 6),
                step(0, AdHeader(s: s)),
                Expanded(
                  child: CustomScrollView(physics: const BouncingScrollPhysics(), slivers: [
                    SliverToBoxAdapter(child: step(1, _hero(s))),
                    SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12 * s,
                        crossAxisSpacing: 12 * s,
                        childAspectRatio: 1.78,
                      ),
                      delegate: SliverChildBuilderDelegate((c, i) => step(2 + i ~/ 2, _gridCard(s, grid[i])), childCount: grid.length),
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: 12 * s)),
                    SliverList.separated(
                      itemCount: more.length,
                      separatorBuilder: (_, __) => SizedBox(height: 12 * s),
                      itemBuilder: (_, i) => step(5 + i, _wideCard(s, more[i])),
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: 18 * s)),
                  ]),
                ),
                step(8, _bottomBar(s, pad.bottom)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _hero(double s) => SizedBox(
        height: 220 * s,
        child: Stack(clipBehavior: Clip.none, children: [
          PositionedDirectional(
            start: -4 * s,
            bottom: 0,
            height: 214 * s,
            child: AnimatedBuilder(
              animation: _idle,
              builder: (_, c) => Transform.translate(offset: Offset(0, sin(_idle.value * 2 * pi) * 4 * s), child: c),
              child: Image.asset('${adDir}ad_robot_pencil.webp', fit: BoxFit.contain),
            ),
          ),
          PositionedDirectional(
            start: 128 * s,
            end: 0,
            top: 6 * s,
            child: AdBubble(
              tail: AdTail.left,
              sparks: true,
              padding: EdgeInsets.fromLTRB(26 * s, 10 * s, 26 * s, 10 * s),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(adText(context, 'heroTitle'),
                    textAlign: TextAlign.center, maxLines: 2, style: kidTitleStyle(21 * s, color: adInk).copyWith(shadows: const [], height: 1.05)),
                SizedBox(height: 4 * s),
                Text(adText(context, 'heroSub'),
                    textAlign: TextAlign.center, maxLines: 2, style: kidBodyStyle(12.5 * s, color: adInk, weight: FontWeight.w600)),
              ]),
            ),
          ),
          PositionedDirectional(
            end: 8 * s,
            bottom: 8 * s,
            width: 196 * s,
            child: AnimatedBuilder(
              animation: _idle,
              builder: (_, c) => Transform.rotate(angle: sin(_idle.value * 2 * pi + 1) * 0.025, child: c),
              child: Image.asset('${adDir}ad_hero_tiles.webp', fit: BoxFit.contain),
            ),
          ),
        ]),
      );

  Widget _lockChip(double s, AdLanguage l) => Container(
        padding: EdgeInsets.symmetric(horizontal: 7 * s, vertical: 2 * s),
        decoration: BoxDecoration(
          color: adInk.withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.lock_rounded, color: Colors.white, size: 13 * s),
          SizedBox(width: 2 * s),
          Image.asset(kidCoinAsset, width: 14 * s, height: 14 * s),
          Text('${l.cost}', style: kidBodyStyle(12 * s, color: Colors.white, weight: FontWeight.w700)),
        ]),
      );

  Widget _tile(double s, AdLanguage l, double width) {
    final locked = !_unlocked(l);
    final img = Image.asset(l.tile, width: width, height: width * l.tileAspect, fit: BoxFit.contain);
    return Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
      locked
          ? ColorFiltered(
              colorFilter: const ColorFilter.matrix([
                0.5, 0.4, 0.1, 0, 20, //
                0.3, 0.6, 0.1, 0, 20,
                0.3, 0.4, 0.3, 0, 20,
                0, 0, 0, 0.85, 0,
              ]),
              child: img)
          : img,
      if (locked) Positioned(bottom: -4 * s, child: _lockChip(s, l)),
    ]);
  }

  String _progress(AdLanguage l) =>
      adText(context, 'lettersDone').replaceAll('{D}', '${_done[l.code] ?? 0}').replaceAll('{T}', '${l.letters.length * (l.hasCase ? 2 : 1)}');

  Widget _names(double s, AdLanguage l, double big, {CrossAxisAlignment align = CrossAxisAlignment.center}) {
    final ui = l.names[adLang(context)] ?? l.native;
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: align, children: [
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(l.native, maxLines: 1, style: kidTitleStyle(big * s, color: adInk).copyWith(shadows: const [], height: 1.1)),
      ),
      if (ui != l.native)
        FittedBox(fit: BoxFit.scaleDown, child: Text(ui, maxLines: 1, style: kidBodyStyle(14 * s, color: adInk, weight: FontWeight.w600))),
      if ((_done[l.code] ?? 0) > 0)
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(_progress(l), maxLines: 1, style: kidBodyStyle(11 * s, color: adGreen, weight: FontWeight.w700)),
        ),
    ]);
  }

  Widget _selectedBadge(double s) => Container(
        width: 30 * s,
        height: 30 * s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(colors: [Color(0xFFA06BFF), adPurpleDeep]),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [BoxShadow(color: adPurple.withOpacity(0.4), blurRadius: 6)],
        ),
        child: Icon(Icons.check_rounded, color: Colors.white, size: 19 * s),
      );

  Widget _gridCard(double s, AdLanguage l) {
    final sel = l.code == _selected;
    return KidPressable(
      onTap: () => _tapLanguage(l),
      pressedScale: 0.95,
      child: Stack(clipBehavior: Clip.none, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: EdgeInsets.all(8 * s),
          decoration: adPillDecoration(20 * s, selected: sel),
          child: Row(children: [
            _tile(s, l, 66 * s),
            SizedBox(width: 6 * s),
            Expanded(child: _names(s, l, 20)),
          ]),
        ),
        if (sel) PositionedDirectional(top: -8 * s, end: -6 * s, child: _selectedBadge(s)),
      ]),
    );
  }

  Widget _wideCard(double s, AdLanguage l) {
    final sel = l.code == _selected;
    return KidPressable(
      onTap: () => _tapLanguage(l),
      pressedScale: 0.96,
      child: Stack(clipBehavior: Clip.none, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 92 * s,
          padding: EdgeInsetsDirectional.fromSTEB(10 * s, 8 * s, 12 * s, 8 * s),
          decoration: adPillDecoration(22 * s, selected: sel),
          child: Row(children: [
            _tile(s, l, 92 * s),
            SizedBox(width: 14 * s),
            Expanded(child: _names(s, l, 26, align: CrossAxisAlignment.start)),
            adRoundBtn(40 * s, Icons.chevron_right_rounded, () => _tapLanguage(l), flipRtl: true, context: context),
          ]),
        ),
        if (sel) PositionedDirectional(top: -8 * s, end: -6 * s, child: _selectedBadge(s)),
      ]),
    );
  }

  Widget _modeChip(double s, AdMode m, IconData icon, String label) {
    final sel = m == _mode;
    return Expanded(
      child: KidPressable(
        onTap: () {
          _audio.playEventSound('toggleButton');
          setState(() => _mode = m);
          AdStore.setLastMode(m);
        },
        pressedScale: 0.94,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 46 * s,
          padding: EdgeInsets.symmetric(horizontal: 6 * s),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: sel ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF9D63FF), adPurpleDeep]) : null,
            color: sel ? null : adCream,
            border: Border.all(color: sel ? Colors.white : const Color(0xFFE6DCF8), width: 2),
            boxShadow: sel ? [BoxShadow(color: adPurple.withOpacity(0.4), blurRadius: 10)] : const [],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: sel ? Colors.white : adPurpleDeep, size: 20 * s),
            SizedBox(width: 4 * s),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, maxLines: 1, style: kidBodyStyle(15 * s, color: sel ? Colors.white : adInk, weight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _bottomBar(double s, double bottomPad) => Padding(
        padding: EdgeInsets.only(bottom: 10 * s + bottomPad),
        child: Column(children: [
          Container(
            padding: EdgeInsets.all(5 * s),
            decoration: adPillDecoration(30 * s, border: const Color(0xFFE6DCF8)),
            child: Row(children: [
              _modeChip(s, AdMode.trace, Icons.edit_rounded, adText(context, 'trace')),
              SizedBox(width: 5 * s),
              _modeChip(s, AdMode.practice, Icons.crop_free_rounded, adText(context, 'practice')),
              SizedBox(width: 5 * s),
              _modeChip(s, AdMode.free, Icons.gesture_rounded, adText(context, 'free')),
            ]),
          ),
          SizedBox(height: 10 * s),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24 * s),
            child: AdYellowButton(
              s: s,
              label: adText(context, 'letsWrite'),
              leading: Transform.rotate(angle: 0, child: Image.asset('${adDir}ad_crayon.webp', height: 42 * s)),
              onTap: _start,
            ),
          ),
        ]),
      );
}
