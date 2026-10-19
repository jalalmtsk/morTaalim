import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../../XpSystem.dart';
import '../../main.dart';
import '../../tools/Ads_Manager.dart';
import '../../tools/audio_tool/Audio_Manager.dart';
import '../../widgets/KidScene/kid_page_parts.dart';
import '../../widgets/KidScene/kid_scene.dart';
import 'animal_sounds_data.dart';
import 'animal_sounds_quiz.dart';
import 'animal_sounds_widgets.dart';

/// Animal Sounds home: browse the animals by habitat, tap one to hear it,
/// then play "Guess the sound".
class AnimalsoundIndex extends StatefulWidget {
  const AnimalsoundIndex({super.key});

  @override
  State<AnimalsoundIndex> createState() => _AnimalsoundIndexState();
}

class _AnimalsoundIndexState extends State<AnimalsoundIndex> with TickerProviderStateMixin {
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..forward();
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  final AsVoice _voice = AsVoice();

  int _tab = 0; // 0 = all, then AsGroup order
  String? _playing;
  int _bounce = 0;
  Set<String> _found = {};
  Timer? _playTimer;
  bool _precached = false;

  BannerAd? _banner;
  bool _bannerLoaded = false;

  AudioManager get _audio => Provider.of<AudioManager>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _banner = AdHelper.getBannerAd(() {
      if (mounted) setState(() => _bannerLoaded = true);
    });
    AsStore.found().then((f) {
      if (mounted) setState(() => _found = f);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    KidAssets.precache(context, [
      ...asUiAssets,
      kidCoinAsset,
      kidGemAsset,
      for (final a in asAnimals) ...[a.sprite, a.scene],
    ]);
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    _voice.dispose();
    _intro.dispose();
    _idle.dispose();
    _banner?.dispose();
    super.dispose();
  }

  List<AsAnimal> get _shown =>
      _tab == 0 ? asAnimals : asAnimals.where((a) => a.group == AsGroup.values[_tab - 1]).toList();

  Future<void> _tapAnimal(AsAnimal a) async {
    setState(() {
      _playing = a.id;
      _bounce++;
    });
    final len = await _voice.play(a.sound, _audio);
    _playTimer?.cancel();
    _playTimer = Timer(len + const Duration(milliseconds: 250), () {
      if (mounted && _playing == a.id) setState(() => _playing = null);
    });

    if (_found.contains(a.id)) return;
    setState(() => _found = {..._found, a.id});
    await AsStore.saveFound(_found);
    if (_found.length == asAnimals.length && await AsStore.claimAllFoundBonus() && mounted) {
      Provider.of<ExperienceManager>(context, listen: false).addGold(context, 10);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: KidColors.purpleDeep,
        content: Text('🎉 ${asText(context, 'allFound')}',
            style: kidBodyStyle(15, color: Colors.white, weight: FontWeight.w600)),
      ));
    }
  }

  void _selectTab(int i) {
    if (i == _tab) return;
    _audio.playEventSound('clickButton2');
    setState(() => _tab = i);
  }

  Future<void> _startQuiz() async {
    _audio.playEventSound('PopButton');
    _playTimer?.cancel();
    await _voice.stop();
    setState(() => _playing = null);
    if (!mounted) return;
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AnimalSoundsQuiz(),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
  }

  // ── build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final w = min(size.width, 640.0) - 24;
    // fit both width and height so short phones keep room for the grid
    final s = min(w / 380, (size.height - pad.vertical) / 800).clamp(0.74, 1.3).toDouble();
    final cols = w > 540 ? 3 : 2;
    final xp = context.watch<ExperienceManager>();
    final showAd = xp.adsEnabled && _banner != null && _bannerLoaded;
    Widget step(int i, Widget c) =>
        KidIntro(intro: _intro, from: 0.06 * i, to: min(1.0, 0.5 + 0.06 * i), rise: 22, child: c);

    return Scaffold(
      backgroundColor: KidColors.sky,
      body: Stack(children: [
        const Positioned.fill(child: KidPageBackground(asset: asPageBg, wash: 0)),
        SafeArea(
          bottom: false,
          child: Center(
            child: SizedBox(
              width: w,
              child: Column(children: [
                SizedBox(height: 6 * s),
                step(0, _header(s, xp)),
                SizedBox(height: 2 * s),
                step(1, SizedBox(height: 56 * s, child: Center(child: AsTitle(asText(context, 'title'), size: 46 * s)))),
                step(1, _subtitle(s, w)),
                SizedBox(height: 10 * s),
                step(2, AsTabs(
                  s: s,
                  index: _tab,
                  onTap: _selectTab,
                  labels: [for (final k in const ['all', 'home', 'wild', 'sea', 'sky']) asText(context, k)],
                )),
                SizedBox(height: 10 * s),
                Expanded(child: step(3, _panel(s, cols))),
                SizedBox(height: 16 * s),
                step(4, _playBanner(s)),
                SizedBox(height: 10 * s),
                step(5, AsProgressPill(
                  s: s,
                  label: '${asText(context, 'found')}   ${_found.length} / ${asAnimals.length}',
                  value: _found.length / asAnimals.length,
                )),
                SizedBox(height: 10 * s + (showAd ? 0 : pad.bottom)),
              ]),
            ),
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
    );
  }

  Widget _header(double s, ExperienceManager xp) => SizedBox(
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
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: 150 * s,
                height: 150 * s * 146 / 433,
                child: Stack(fit: StackFit.expand, children: [
                  Image.asset(asSign, fit: BoxFit.fill),
                  Padding(
                    padding: EdgeInsets.fromLTRB(24 * s, 17 * s, 24 * s, 5 * s),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('MoorTaalim', style: kidTitleStyle(19 * s).copyWith(shadows: const [])),
                    ),
                  ),
                ]),
              ),
            ),
          ),
          SizedBox(width: 6 * s),
          KidCurrencyPill(scale: s * 0.92, icon: kidCoinAsset, value: xp.gold, label: tr(context).goldLabel),
          SizedBox(width: 5 * s),
          KidCurrencyPill(scale: s * 0.92, icon: kidGemAsset, value: xp.gems, label: tr(context).gemsLabel),
        ]),
      );

  Widget _subtitle(double s, double w) => Container(
        height: 34 * s,
        constraints: BoxConstraints(maxWidth: w * 0.88),
        padding: EdgeInsets.symmetric(horizontal: 18 * s),
        decoration: asPill(20 * s),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(asText(context, 'sub'),
              maxLines: 1, style: kidBodyStyle(15 * s, color: KidColors.ink, weight: FontWeight.w600)),
        ),
      );

  Widget _panel(double s, int cols) {
    final list = _shown;
    return Container(
      decoration: BoxDecoration(
        color: asCream.withOpacity(0.88),
        borderRadius: BorderRadius.circular(28 * s),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [BoxShadow(color: KidColors.purpleDeep.withOpacity(0.18), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25 * s),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (c, a) => FadeTransition(
            opacity: a,
            child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(a), child: c),
          ),
          child: GridView.builder(
            key: ValueKey(_tab),
            // extra bottom room: the robot peeks over the panel's lower edge
            padding: EdgeInsets.fromLTRB(10 * s, 12 * s, 10 * s, 34 * s),
            physics: const BouncingScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: 12 * s,
              crossAxisSpacing: 10 * s,
              childAspectRatio: 1.22,
            ),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final a = list[i];
              final on = _playing == a.id;
              return AsCard(
                key: ValueKey(a.id),
                animal: a,
                s: s,
                active: on,
                bounce: on ? _bounce : 0,
                onTap: () => _tapAnimal(a),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _playBanner(double s) {
    final h = 116 * s;
    return SizedBox(
      height: h,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(child: Image.asset(asBanner, fit: BoxFit.fill)),
        // robot steps out of the banner
        PositionedDirectional(
          start: -2 * s,
          bottom: 2 * s,
          height: h * 1.28,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _idle,
              builder: (_, c) => Transform.translate(offset: Offset(0, sin(_idle.value * 4 * pi) * 3 * s), child: c),
              child: Image.asset(asRobot, fit: BoxFit.contain),
            ),
          ),
        ),
        PositionedDirectional(start: h * 1.08, top: -12 * s, child: AsFloaty(asset: asNoteYellow, size: 26 * s, idle: _idle)),
        PositionedDirectional(start: h * 1.22, top: 14 * s, child: AsFloaty(asset: asNoteBlue, size: 19 * s, idle: _idle, phase: 0.4)),
        PositionedDirectional(end: 10 * s, top: -10 * s, child: AsFloaty(asset: asSparkle, size: 22 * s, idle: _idle, phase: 0.7)),
        PositionedDirectional(
          start: h * 1.25,
          end: 12 * s,
          top: 0,
          bottom: 0,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(asText(context, 'guess'),
                  maxLines: 1,
                  style: kidTitleStyle(24 * s, color: Colors.white).copyWith(shadows: [
                    Shadow(color: KidColors.purpleDeep.withOpacity(0.7), blurRadius: 6, offset: const Offset(0, 2)),
                  ])),
            ),
            SizedBox(height: 2 * s),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(asText(context, 'guessSub'),
                  maxLines: 1,
                  style: kidBodyStyle(13 * s, color: Colors.white.withOpacity(0.92), weight: FontWeight.w600)),
            ),
            SizedBox(height: 8 * s),
            KidButton(
              label: asText(context, 'play'),
              onPressed: _startQuiz,
              width: 150 * s,
              height: 46 * s,
              showArrow: false,
            ),
          ]),
        ),
      ]),
    );
  }
}
