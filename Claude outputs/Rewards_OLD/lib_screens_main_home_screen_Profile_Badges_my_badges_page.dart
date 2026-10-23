import 'package:mortaalim/widgets/KidScene/kid_toast.dart';
import 'package:mortaalim/widgets/KidScene/glossy_bar.dart';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:provider/provider.dart';

import 'badge_catalog.dart';

const Color _ink = Color(0xFF2A1366);
const Color _cream = Color(0xFFFFFCF4);
const Color _lavender = Color(0xFFEFEAFF);
const int _newBadgeGold = 10;

/// Tap a badge (anywhere in the app) → its story card.
Future<void> showBadgeStory(BuildContext context, AppBadge b, BadgeStats s) {
  Provider.of<AudioManager>(context, listen: false).playEventSound('clickButton2');
  final earned = b.earned(s);
  return showDialog(
    context: context,
    barrierColor: KidColors.purpleDeep.withOpacity(0.35),
    builder: (ctx) => KidDialog(
      headerAsset: b.asset,
      headerAspect: 1.1,
      title: b.name(ctx),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(b.story(ctx),
              textAlign: TextAlign.center, style: kidBodyStyle(15.5, color: KidColors.inkSoft, weight: FontWeight.w600)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            decoration: BoxDecoration(
              color: earned ? const Color(0xFFE3F9EC) : _lavender,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Image.asset(earned ? BadgeAssets.check : BadgeAssets.lock, width: 22, height: 22),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(earned ? badgeUi(ctx, 'earned') : b.how(ctx),
                      textAlign: TextAlign.center, style: kidBodyStyle(14.5, color: _ink, weight: FontWeight.w700)),
                ),
              ]),
              if (!earned) ...[
                const SizedBox(height: 8),
                _Bar(value: b.ratio(s), height: 12),
                const SizedBox(height: 4),
                Text('${b.progress(s)} / ${b.target}', style: kidBodyStyle(13, color: KidColors.purpleDeep, weight: FontWeight.w700)),
              ],
            ]),
          ),
        ],
      ),
      actions: [KidOutlineButton(label: tr(ctx).awesome, onTap: () => Navigator.pop(ctx))],
    ),
  );
}

class MyBadgesPage extends StatefulWidget {
  const MyBadgesPage({super.key});

  @override
  State<MyBadgesPage> createState() => _MyBadgesPageState();
}

enum _Filter { all, unlocked, locked }

class _MyBadgesPageState extends State<MyBadgesPage> with TickerProviderStateMixin {
  BadgeStats _s = BadgeStats.empty;
  bool _loaded = false;
  _Filter _filter = _Filter.all;
  Set<String> _fresh = {};
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  late final ConfettiController _confetti = ConfettiController(duration: const Duration(seconds: 2));

  AudioManager get _audio => Provider.of<AudioManager>(context, listen: false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final b in appBadges) {
      precacheImage(AssetImage(b.asset), context);
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    _intro.dispose();
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final xp = Provider.of<ExperienceManager>(context, listen: false);
    final s = await BadgeStats.load(level: xp.level);
    final fresh = await takeNewBadges(s);
    if (!mounted) return;
    setState(() {
      _s = s;
      _loaded = true;
      _fresh = fresh.map((b) => b.id).toSet();
    });
    _intro.forward(from: 0);
    for (final b in fresh.take(3)) {
      if (!mounted) return;
      await _celebrate(b);
    }
  }

  Future<void> _celebrate(AppBadge b) async {
    _confetti.play();
    _audio.playSfx('assets/audios/UI_Audio/SFX_Audio/victory2_SFX.mp3');
    final done = KidToast.show(KidToastKind.badge, subtitle: b.name(context), onTap: () => showBadgeStory(context, b, _s));
    Provider.of<ExperienceManager>(context, listen: false).addGold(context, _newBadgeGold);
    await done;
  }

  List<AppBadge> get _shown => switch (_filter) {
        _Filter.all => appBadges,
        _Filter.unlocked => appBadges.where((b) => b.earned(_s)).toList(),
        _Filter.locked => appBadges.where((b) => !b.earned(_s)).toList(),
      };

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = min(size.width, 600.0) - 28;
    final s = (w / 380).clamp(0.82, 1.4).toDouble();
    final earnedCount = appBadges.where((b) => b.earned(_s)).length;

    Widget step(int i, Widget child) =>
        KidIntro(intro: _intro, from: 0.08 * i, to: min(1.0, 0.45 + 0.08 * i), rise: 22, child: child);

    return Scaffold(
      backgroundColor: KidColors.sky,
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset(KidAssets.valleyBg, fit: BoxFit.cover)),
          Positioned.fill(child: ColoredBox(color: Colors.white.withOpacity(0.08))),
          SafeArea(
            bottom: false,
            child: Center(
              child: SizedBox(
                width: w + 28,
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(14, 6 * s, 14, 6 * s),
                      child: Row(children: [
                        KidBackButton(
                          size: 52 * s,
                          onTap: () {
                            _audio.playEventSound('cancelButton');
                            Navigator.maybePop(context);
                          },
                        ),
                        SizedBox(width: 12 * s),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(badgeUi(context, 'title'), style: kidTitleStyle(36 * s, color: _ink)),
                          ),
                        ),
                      ]),
                    ),
                    Expanded(
                      child: !_loaded
                          ? const Center(child: CircularProgressIndicator(color: KidColors.purple))
                          : ListView(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(14, 4, 14, MediaQuery.paddingOf(context).bottom + 20),
                              children: [
                                step(0, _hero(s, earnedCount)),
                                SizedBox(height: 10 * s),
                                step(1, _tabs(s)),
                                SizedBox(height: 10 * s),
                                step(2, _grid(s)),
                                SizedBox(height: 12 * s),
                                step(3, _next(s)),
                                SizedBox(height: 10 * s),
                                step(4, _footer(s)),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              gravity: 0.25,
              colors: const [Color(0xFFFFC93C), Color(0xFF7B3FE4), Color(0xFF34D2F5), Color(0xFFFF6FB5), Color(0xFF4ADE80)],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _card({Color color = _cream, double r = 26}) => BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [BoxShadow(color: KidColors.purpleDeep.withOpacity(0.16), blurRadius: 14, offset: const Offset(0, 6))],
      );

  Widget _hero(double s, int earned) {
    final total = appBadges.length;
    return Container(
      decoration: _card(r: 28 * s),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25 * s),
        child: Stack(
          children: [
            Positioned.fill(child: Image.asset(BadgeAssets.sparkle, fit: BoxFit.fill)),
            Padding(
              padding: EdgeInsets.fromLTRB(10 * s, 12 * s, 16 * s, 14 * s),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _idle,
                    builder: (_, c) => Transform.scale(scale: 1 + 0.04 * sin(_idle.value * 4 * pi), child: c),
                    child: Container(
                      decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
                        BoxShadow(color: const Color(0xFFFFD447).withOpacity(0.55), blurRadius: 30 * s, spreadRadius: 2),
                      ]),
                      child: Image.asset(BadgeAssets.hero, width: 128 * s, height: 113 * s, fit: BoxFit.contain),
                    ),
                  ),
                  SizedBox(width: 10 * s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(badgeUi(context, 'hero'),
                            style: kidBodyStyle(22 * s, color: _ink, weight: FontWeight.w700).copyWith(height: 1.1)),
                        SizedBox(height: 12 * s),
                        _Bar(value: earned / total, height: 16 * s),
                        SizedBox(height: 8 * s),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Text(badgeUi(context, 'unlockedN', {'n': earned, 't': total}),
                              style: kidBodyStyle(15 * s, color: KidColors.purpleDeep, weight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabs(double s) {
    Widget tab(_Filter f, String label) {
      final on = _filter == f;
      return Expanded(
        child: KidPressable(
          onTap: () {
            if (on) return;
            _audio.playEventSound('toggleButton');
            setState(() => _filter = f);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 46 * s,
            alignment: Alignment.center,
            margin: EdgeInsets.symmetric(horizontal: 3 * s),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: on ? null : _lavender,
              gradient: on
                  ? const LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8B5BFF), Color(0xFF5B21C9)])
                  : null,
              boxShadow: on ? [BoxShadow(color: KidColors.purpleDeep.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 4))] : null,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label,
                  style: kidBodyStyle(17 * s, color: on ? Colors.white : const Color(0xFF4A2B91), weight: FontWeight.w700)),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(5 * s),
      decoration: _card(r: 34),
      child: Row(children: [
        tab(_Filter.all, badgeUi(context, 'all')),
        tab(_Filter.unlocked, badgeUi(context, 'unlocked')),
        tab(_Filter.locked, badgeUi(context, 'locked')),
      ]),
    );
  }

  Widget _grid(double s) {
    final list = _shown;
    return Container(
      padding: EdgeInsets.all(10 * s),
      decoration: _card(color: _cream.withOpacity(0.94), r: 28 * s),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        child: list.isEmpty
            ? Padding(
                key: const ValueKey('empty'),
                padding: EdgeInsets.symmetric(vertical: 40 * s),
                child: Center(
                  child: Text(badgeUi(context, 'none'), style: kidBodyStyle(16 * s, color: KidColors.muted, weight: FontWeight.w600)),
                ),
              )
            : GridView.builder(
                key: ValueKey(_filter),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10 * s,
                  crossAxisSpacing: 10 * s,
                  childAspectRatio: 0.84,
                ),
                itemBuilder: (_, i) => _BadgeCard(
                  badge: list[i],
                  stats: _s,
                  scale: s,
                  idle: _idle,
                  phase: i * 0.37,
                  fresh: _fresh.contains(list[i].id),
                  onTap: () => showBadgeStory(context, list[i], _s),
                ),
              ),
      ),
    );
  }

  Widget _next(double s) {
    final b = nextBadge(_s);
    return Container(
      padding: EdgeInsets.fromLTRB(10 * s, 10 * s, 16 * s, 12 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26 * s),
        gradient: const LinearGradient(colors: [Color(0xFFE6FBFF), Color(0xFFD3F4FB)]),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [BoxShadow(color: const Color(0xFF0EA5C6).withOpacity(0.2), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Stack(alignment: Alignment.center, children: [
            Container(
              width: 96 * s,
              height: 96 * s,
              decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
                BoxShadow(color: const Color(0xFFFFF3B0).withOpacity(0.9), blurRadius: 26 * s, spreadRadius: 4 * s),
              ]),
            ),
            KidPressable(
              onTap: b == null ? null : () => showBadgeStory(context, b, _s),
              child: Image.asset(b?.asset ?? BadgeAssets.hero, width: 110 * s, height: 100 * s, fit: BoxFit.contain),
            ),
          ]),
          SizedBox(width: 12 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b == null ? badgeUi(context, 'allDone') : badgeUi(context, 'next'),
                    style: kidBodyStyle(20 * s, color: _ink, weight: FontWeight.w700)),
                if (b == null)
                  Text(badgeUi(context, 'allDoneSub'),
                      style: kidBodyStyle(14 * s, color: const Color(0xFF6D3FE0), weight: FontWeight.w600))
                else ...[
                  Text(b.name(context), style: kidBodyStyle(16 * s, color: _ink, weight: FontWeight.w700)),
                  Text(b.how(context),
                      maxLines: 2, style: kidBodyStyle(13.5 * s, color: const Color(0xFF6D3FE0), weight: FontWeight.w600)),
                  SizedBox(height: 8 * s),
                  Row(children: [
                    Expanded(child: _Bar(value: b.ratio(_s), height: 13 * s)),
                    SizedBox(width: 10 * s),
                    Text('${b.progress(_s)} / ${b.target}',
                        style: kidBodyStyle(15 * s, color: KidColors.purpleDeep, weight: FontWeight.w700)),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(double s) {
    final spark = Icon(Icons.auto_awesome_rounded, color: const Color(0xFFFFC21A), size: 20 * s);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 11 * s),
      decoration: _card(color: _lavender, r: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          spark,
          SizedBox(width: 8 * s),
          Flexible(
            child: Text(badgeUi(context, 'tap'),
                textAlign: TextAlign.center, style: kidBodyStyle(15 * s, color: KidColors.purpleDeep, weight: FontWeight.w700)),
          ),
          SizedBox(width: 8 * s),
          spark,
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final AppBadge badge;
  final BadgeStats stats;
  final double scale, phase;
  final Animation<double> idle;
  final bool fresh;
  final VoidCallback onTap;
  const _BadgeCard({
    required this.badge,
    required this.stats,
    required this.scale,
    required this.idle,
    required this.phase,
    required this.fresh,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final earned = badge.earned(stats);
    Widget art = Image.asset(badge.asset, fit: BoxFit.contain);
    if (earned) {
      art = AnimatedBuilder(
        animation: idle,
        builder: (_, c) => Transform.translate(offset: Offset(0, sin(idle.value * 4 * pi + phase * 2 * pi) * 2.5 * s), child: c),
        child: art,
      );
    } else {
      art = Opacity(opacity: 0.88, child: art);
    }
    return KidPressable(
      onTap: onTap,
      pressedScale: 0.94,
      semanticLabel: badge.name(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20 * s),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: earned ? const [Color(0xFFFFFBEA), Color(0xFFFFF3D6)] : const [Color(0xFFF4F0FF), Color(0xFFE9E2FF)],
          ),
          border: Border.all(color: fresh ? const Color(0xFFFFC21A) : Colors.white, width: fresh ? 3 : 2),
          boxShadow: [BoxShadow(color: KidColors.purpleDeep.withOpacity(0.10), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                Expanded(
                  child: Padding(padding: EdgeInsets.fromLTRB(6 * s, 8 * s, 6 * s, 0), child: art),
                ),
                if (!earned)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 3 * s),
                    child: _Bar(value: badge.ratio(stats), height: 6 * s),
                  ),
                Container(
                  margin: EdgeInsets.fromLTRB(6 * s, 2 * s, 6 * s, 6 * s),
                  padding: EdgeInsets.symmetric(horizontal: 6 * s, vertical: 4 * s),
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(badge.name(context),
                        maxLines: 1,
                        style: kidBodyStyle(13.5 * s, color: earned ? _ink : const Color(0xFF4A3B78), weight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
            PositionedDirectional(
              top: 4 * s,
              end: 4 * s,
              child: Image.asset(earned ? BadgeAssets.check : BadgeAssets.lock, width: 26 * s, height: 26 * s),
            ),
            if (fresh)
              PositionedDirectional(
                top: -6 * s,
                start: -4 * s,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 7 * s, vertical: 2 * s),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4D8D),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text('NEW', style: kidBodyStyle(10.5 * s, color: Colors.white, weight: FontWeight.w700)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Cyan glossy progress bar.
class _Bar extends StatelessWidget {
  final double value, height;
  const _Bar({required this.value, required this.height});

  @override
  Widget build(BuildContext context) => GlossyBar(value: value, height: height * 1.3, color: 'cyan');
}
