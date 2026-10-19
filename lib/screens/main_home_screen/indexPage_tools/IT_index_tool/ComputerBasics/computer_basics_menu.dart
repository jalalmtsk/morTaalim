import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/Manager/lesson_progress.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/KidScene/kid_page_parts.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:provider/provider.dart';

import 'computer_basics_lesson.dart';
import 'computer_basics_texts.dart';

/// "Computer Basics" lesson map: 8 lessons, each unlocked by finishing the one before.
class ComputerBasicsMenuPage extends StatefulWidget {
  const ComputerBasicsMenuPage({super.key});

  @override
  State<ComputerBasicsMenuPage> createState() => _ComputerBasicsMenuPageState();
}

class _ComputerBasicsMenuPageState extends State<ComputerBasicsMenuPage> with TickerProviderStateMixin {
  static const String _dir = 'assets/images/UI/KidScene/';
  static String _icon(int n) => '${_dir}itm_$n.webp';
  static const _lock = '${_dir}itm_lock.webp';
  static const _check = '${_dir}itm_check.webp';
  static const _star = '${_dir}itm_star.webp';
  static const _chest = '${_dir}quest_chest.webp';

  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
  late final AnimationController _idle =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  Map<int, int> _stars = {};
  bool _precached = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      KidAssets.precache(context, [
        CBAssets.bg, CBAssets.laptop, CBAssets.robotPoint, CBAssets.sound, _lock, _check, _star, _chest,
        for (int i = 1; i <= 8; i++) _icon(i),
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

  Future<void> _refresh() async {
    final s = await CBProgress.load();
    if (mounted) setState(() => _stars = s);
  }

  int get _completed => _stars.values.where((v) => v > 0).length;
  bool _unlocked(int n) => n == 1 || (_stars[n - 1] ?? 0) > 0;

  /// First unlocked lesson not finished yet (or the last one).
  int get _current {
    for (int n = 1; n <= 8; n++) {
      if ((_stars[n] ?? 0) == 0) return n;
    }
    return 8;
  }

  AudioManager get _audio => Provider.of<AudioManager>(context, listen: false);

  Future<void> _open(int n) async {
    if (!_unlocked(n)) {
      _audio.playEventSound('invalid');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: KidColors.purpleDeep,
        duration: const Duration(milliseconds: 1600),
        content: Text(cbText(context, 'locked', args: {'n': '${n - 1}'}),
            style: kidBodyStyle(15, color: Colors.white, weight: FontWeight.w600)),
      ));
      return;
    }
    if (_busy) return;
    _busy = true;
    _audio.playEventSound('PopButton');
    await LessonProgress.it.record('basics', n - 1);
    if (!mounted) return;
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ComputerBasicsLessonPage(index: n - 1),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
    _busy = false;
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final w = min(size.width, 600.0) - 28;
    final s = (w / 380).clamp(0.8, 1.4);
    final t = tr(context);
    final cols = size.width >= 700 ? 3 : 2;
    final cur = _current;

    Widget step(int i, Widget child) =>
        KidIntro(intro: _intro, from: 0.05 * i, to: min(1.0, 0.45 + 0.05 * i), rise: 22, child: child);

    return Scaffold(
      backgroundColor: KidColors.sky,
      body: Stack(children: [
        const Positioned.fill(child: KidPageBackground(asset: CBAssets.bg, wash: 0.04)),
        SafeArea(
          bottom: false,
          child: Center(
            child: SizedBox(
              width: w,
              child: Column(children: [
                const SizedBox(height: 4),
                step(0, _header(s)),
                SizedBox(height: 6 * s),
                Expanded(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: step(1, _progressCard(s))),
                      SliverToBoxAdapter(child: SizedBox(height: 12 * s)),
                      SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          mainAxisSpacing: 12 * s,
                          crossAxisSpacing: 12 * s,
                          childAspectRatio: 1.62,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => step(2 + min(i, 6), _lessonCard(s, i + 1, cur)),
                          childCount: 8,
                        ),
                      ),
                      SliverToBoxAdapter(child: SizedBox(height: 12 * s)),
                      SliverToBoxAdapter(child: step(9, _rewardPill(s))),
                      SliverToBoxAdapter(child: SizedBox(height: 90 * s + pad.bottom)),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: pad.bottom + 10,
          child: Center(
            child: KidIntro(
              intro: _intro,
              from: 0.5,
              to: 1,
              rise: 40,
              child: _continueButton(s, _completed == 8 ? t.mmReplay : cbText(context, 'continueN', args: {'n': '$cur'}), () => _open(cur)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _header(double s) {
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
              child: Text(tr(context).itBasics,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w700,
                    fontSize: 32 * s,
                    height: 1.0,
                    color: const Color(0xFF5B21C9),
                    shadows: const [
                      Shadow(color: Colors.white, offset: Offset(0, -2)),
                      Shadow(color: Colors.white, offset: Offset(2, 0)),
                      Shadow(color: Colors.white, offset: Offset(-2, 0)),
                      Shadow(color: Colors.white, offset: Offset(0, 2)),
                      Shadow(color: Color(0xFFFFC94A), offset: Offset(0, 4.5)),
                      Shadow(color: Color(0x55000000), blurRadius: 8, offset: Offset(0, 5)),
                    ],
                  )),
            ),
          ]),
        ),
        SizedBox(width: 50 * s),
      ]),
    );
  }

  Widget _progressCard(double s) {
    final done = _completed;
    return SizedBox(
      height: 112 * s,
      child: Stack(clipBehavior: Clip.none, children: [
        PositionedDirectional(
          start: 0,
          end: 92 * s,
          top: 8 * s,
          bottom: 4 * s,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 10 * s),
            decoration: kidCardDecoration(30 * s, shadow: 0.18),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(cbText(context, 'adventure'), style: kidBodyStyle(18 * s, color: KidColors.ink, weight: FontWeight.w700)),
              ),
              Text(cbText(context, 'completedN', args: {'n': '$done'}),
                  style: kidBodyStyle(13 * s, color: KidColors.purpleDeep, weight: FontWeight.w700)),
              SizedBox(height: 8 * s),
              SizedBox(
                height: 14 * s,
                child: LayoutBuilder(builder: (context, c) {
                  final seg = c.maxWidth / 7;
                  return Stack(alignment: Alignment.centerLeft, children: [
                    Container(height: 6 * s, decoration: BoxDecoration(color: const Color(0xFFE3DDD0), borderRadius: BorderRadius.circular(6))),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      height: 10 * s,
                      width: max(16 * s, seg * max(0, done - 1) + (done > 0 ? 16 * s : 0)),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(colors: [Color(0xFFFFD84A), Color(0xFFFFB21A)]),
                      ),
                    ),
                    for (int i = 0; i < 8; i++)
                      Positioned(
                        left: (seg * i - 6 * s).clamp(0.0, c.maxWidth - 12 * s),
                        child: Container(
                          width: 12 * s,
                          height: 12 * s,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < done ? const Color(0xFFFFC21A) : const Color(0xFFD9D3C6),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ]);
                }),
              ),
            ]),
          ),
        ),
        PositionedDirectional(
          end: -6 * s,
          top: -14 * s,
          child: AnimatedBuilder(
            animation: _idle,
            builder: (_, c) => Transform.translate(offset: Offset(0, sin(_idle.value * 4 * pi) * 3 * s), child: c),
            child: Image.asset(CBAssets.robotPoint, width: 116 * s, height: 116 * s * 1.0465),
          ),
        ),
      ]),
    );
  }

  Widget _lessonCard(double s, int n, int cur) {
    final unlocked = _unlocked(n);
    final stars = _stars[n] ?? 0;
    final isCurrent = n == cur && unlocked && stars == 0;
    final r = 24 * s;
    final title = cbLessonTitle(context, n);
    return KidPressable(
      onTap: () => _open(n),
      pressedScale: 0.95,
      semanticLabel: title,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(r),
          gradient: isCurrent
              ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF1E8FF), Color(0xFFDCCBFF)])
              : null,
          color: isCurrent ? null : kidCardCream,
          border: Border.all(color: isCurrent ? KidColors.purple : const Color(0xFFFFE08A), width: isCurrent ? 3 : 2.5),
          boxShadow: [
            BoxShadow(
                color: (isCurrent ? KidColors.purple : KidColors.purpleDeep).withOpacity(isCurrent ? 0.35 : 0.15),
                blurRadius: isCurrent ? 16 : 12,
                offset: const Offset(0, 5)),
          ],
        ),
        child: Stack(children: [
          // picture
          Positioned(
            left: 14 * s,
            right: 14 * s,
            top: 8 * s,
            bottom: 38 * s,
            child: Opacity(
              opacity: unlocked ? 1 : 0.75,
              child: isCurrent
                  ? AnimatedBuilder(
                      animation: _idle,
                      builder: (_, c) => Transform.scale(scale: 1 + 0.04 * sin(_idle.value * 8 * pi), child: c),
                      child: Image.asset(_icon(n), fit: BoxFit.contain),
                    )
                  : Image.asset(_icon(n), fit: BoxFit.contain),
            ),
          ),
          // number badge
          PositionedDirectional(
            top: 8 * s,
            start: 8 * s,
            child: Container(
              width: 34 * s,
              height: 34 * s,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF4F9BFF), Color(0xFF1D5FE0)]),
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Text('$n', style: kidBodyStyle(17 * s, color: Colors.white, weight: FontWeight.w700).copyWith(height: 1.0)),
            ),
          ),
          // status (top end)
          if (stars > 0)
            PositionedDirectional(
              top: 6 * s,
              end: 6 * s,
              child: Column(children: [
                Image.asset(_check, width: 30 * s, height: 30 * s),
                SizedBox(height: 2 * s),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  for (int i = 0; i < 3; i++)
                    Opacity(opacity: i < stars ? 1 : 0.25, child: Image.asset(_star, width: 15 * s, height: 15 * s)),
                ]),
              ]),
            ),
          // title strip
          PositionedDirectional(
            start: 12 * s,
            end: 8 * s,
            bottom: 6 * s,
            height: 30 * s,
            child: Row(children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(title, maxLines: 1, style: kidBodyStyle(15.5 * s, color: KidColors.ink, weight: FontWeight.w700)),
                ),
              ),
              if (!unlocked) Image.asset(_lock, width: 22 * s, height: 22 * s * 1.28),
              if (isCurrent)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 3 * s),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFE45C), Color(0xFFFFC21A)]),
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [BoxShadow(color: const Color(0xFFD08A00), offset: Offset(0, 2 * s))],
                  ),
                  child: Text(cbText(context, 'play'), style: kidBodyStyle(12.5 * s, color: KidColors.ink, weight: FontWeight.w700)),
                ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _rewardPill(double s) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 6 * s),
      decoration: kidCardDecoration(30 * s, shadow: 0.14),
      child: Row(children: [
        Image.asset(_chest, width: 52 * s, height: 52 * s * 0.64),
        SizedBox(width: 10 * s),
        Expanded(
          child: Text(cbText(context, 'earnStars'),
              style: kidBodyStyle(15 * s, color: KidColors.purpleDeep, weight: FontWeight.w700)),
        ),
        Image.asset(_star, width: 22 * s, height: 22 * s),
      ]),
    );
  }

  Widget _continueButton(double s, String label, VoidCallback onTap) {
    final h = 62 * s;
    return KidPressable(
      onTap: onTap,
      pressedScale: 0.95,
      child: AnimatedBuilder(
        animation: _idle,
        builder: (_, c) => Transform.scale(scale: 1 + 0.02 * sin(_idle.value * 8 * pi), child: c),
        child: Container(
          height: h,
          constraints: BoxConstraints(minWidth: 240 * s, maxWidth: 340 * s),
          padding: EdgeInsets.symmetric(horizontal: 20 * s),
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
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, style: kidTitleStyle(25 * s, color: const Color(0xFF3B1C8C)).copyWith(shadows: const [])),
              ),
            ),
            SizedBox(width: 10 * s),
            Container(
              width: 36 * s,
              height: 36 * s,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF9B5CFF), Color(0xFF6A2BE0)])),
              child: Transform.flip(
                flipX: Directionality.of(context) == TextDirection.rtl,
                child: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22 * s),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
