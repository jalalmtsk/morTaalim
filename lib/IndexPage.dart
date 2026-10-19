import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/screens/main_home_screen/Settings/SettingPanelInGame.dart';
import 'package:mortaalim/screens/main_home_screen/indexPage_tools/Course_index_tool/courses_page.dart';
import 'package:mortaalim/screens/main_home_screen/indexPage_tools/Game_index_tool/games_page.dart';
import 'package:mortaalim/screens/main_home_screen/indexPage_tools/IT_index_tool/it_page.dart';
import 'package:mortaalim/screens/main_home_screen/indexPage_tools/animated_reward_fab.dart';
import 'package:mortaalim/tools/Ads_Manager.dart';
import 'package:mortaalim/tools/Reysable_Tools/SmartDuaaMorningNight_Dialog.dart';
import 'package:mortaalim/tools/appConfig/AppNotificationDialog/notificationManager.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/tools/loading_page.dart';
import 'package:mortaalim/widgets/Collection/Collection.dart';
import 'package:mortaalim/screens/main_home_screen/indexPage_tools/Religion_index_tool/religion_page.dart';
import 'package:mortaalim/screens/main_home_screen/Quests/quests_page.dart';
import 'package:mortaalim/screens/main_home_screen/Profile/profile_page.dart';
import 'package:mortaalim/screens/main_home_screen/Settings/settings_page.dart';
import 'package:mortaalim/screens/main_shop_screen/MainShopPageIndex.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:mortaalim/widgets/ProfileSetup_Widget/MainProfile_Page/MainProfile_page.dart';
import 'package:mortaalim/widgets/RandomAyat_Card/Ayat_List.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Manager/Services/CardVisibiltyManager.dart';
import 'XpSystem.dart';
import 'main.dart';

/// Kept for files that subscribe to it (the app-level navigator observer
/// in main.dart is a music observer, not a RouteObserver).
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

/// Home assets (sliced from the home design sheet).
class HomeAssets {
  HomeAssets._();
  static const String dir = 'assets/images/UI/KidScene/';
  static const String coin = '${dir}home_coin.webp';
  static const String gem = '${dir}home_gem.webp';
  static const String plusOrange = '${dir}home_plus_orange.webp';
  static const String plusBlue = '${dir}home_plus_blue.webp';
  static const String gear = '${dir}home_gear.webp';
  static const String star = '${dir}home_star_big.webp';
  static const String heroBg = '${dir}home_hero_bg.webp';
  static const String verseArt = '${dir}home_verse_art.webp';
  static const String tileCourses = '${dir}home_tile_courses.webp';
  static const String tileGames = '${dir}home_tile_games.webp';
  static const String tileIt = '${dir}home_tile_it.webp';
  static const String tileReligion = '${dir}home_tile_religion.webp';
  static const String arrowOrange = '${dir}home_arrow_orange.webp';
  static const String arrowPink = '${dir}home_arrow_pink.webp';
  static const String arrowBlue = '${dir}home_arrow_blue.webp';
  static const String arrowGreen = '${dir}home_arrow_green.webp';
  static const String chest = '${dir}home_chest.webp';
  static const String shopBg = '${dir}home_shop_bg.webp';
  static const String navHome = '${dir}home_nav_home.webp';
  static const String navQuests = '${dir}home_nav_quests.webp';
  static const String navCollections = '${dir}home_nav_collections.webp';
  static const String navShop = '${dir}home_nav_shop.webp';

  static const all = [
    coin, gem, plusOrange, plusBlue, gear, star, heroBg, verseArt, tileCourses, tileGames,
    tileIt, tileReligion, arrowOrange, arrowPink, arrowBlue, arrowGreen, chest, shopBg,
    navHome, navQuests, navCollections, navShop,
  ];
}

/// Daily adventure: open 3 different sections today → +30 gold, once a day.
class DailyAdventure {
  static const int goal = 3;
  static const int reward = 30;
  static const _kDate = 'daily_adv_date';
  static const _kDone = 'daily_adv_done';
  static const _kClaimed = 'daily_adv_claimed';

  static String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  static Future<(Set<String>, bool)> load() async {
    final p = await SharedPreferences.getInstance();
    if (p.getString(_kDate) != _today()) return (<String>{}, false);
    return ((p.getStringList(_kDone) ?? const []).toSet(), p.getBool(_kClaimed) ?? false);
  }

  /// Marks [section] as done today. Returns true if this completed the goal
  /// (the caller then grants the reward).
  static Future<bool> mark(String section) async {
    final p = await SharedPreferences.getInstance();
    final today = _today();
    if (p.getString(_kDate) != today) {
      await p.setString(_kDate, today);
      await p.setStringList(_kDone, const []);
      await p.setBool(_kClaimed, false);
    }
    final done = (p.getStringList(_kDone) ?? const []).toSet()..add(section);
    await p.setStringList(_kDone, done.toList());
    final claimed = p.getBool(_kClaimed) ?? false;
    if (!claimed && done.length >= goal) {
      await p.setBool(_kClaimed, true);
      return true;
    }
    return false;
  }
}

class Index extends StatefulWidget {
  const Index({super.key});

  @override
  State<Index> createState() => _IndexState();
}

class _IndexState extends State<Index> with TickerProviderStateMixin, WidgetsBindingObserver {
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));
  late final AnimationController _idle =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();

  /// Bottom-bar tab: 0 home, 1 quests, 2 collections, 3 shop, 4 profile.
  int _tab = 0;
  Set<String> _dailyDone = {};
  bool _dailyClaimed = false;
  bool _versePlaying = false;
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    WidgetsBinding.instance.addObserver(this);

    final audioManager = Provider.of<AudioManager>(context, listen: false);
    final xpManager = Provider.of<ExperienceManager>(context, listen: false);
    xpManager.init(context);
    _refreshDaily();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      audioManager.playAlert("assets/audios/HappyIntranceIndex.mp3");
      audioManager.playBackgroundMusic("assets/audios/BackGround_Audio/IndexBackGroundMusic_BCG.mp3");

      final cardManager = context.read<CardVisibilityManager>();
      await Future.doWhile(() async {
        if (cardManager.showDuaaDialog != null) return false;
        await Future.delayed(const Duration(milliseconds: 50));
        return true;
      });
      _showDuaaDialog();

      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      final locale = Localizations.localeOf(context).languageCode;
      await NotificationManager().showNotificationIfAllowed(context, locale);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      KidAssets.precache(context, [...HomeAssets.all, KidAssets.valleyBg, KidAssets.wordmark]);
      _intro.forward();
    }
  }

  Future<void> _refreshDaily() async {
    final (done, claimed) = await DailyAdventure.load();
    if (mounted) setState(() {
      _dailyDone = done;
      _dailyClaimed = claimed;
    });
  }

  void _loadBannerAd() {
    _bannerAd?.dispose();
    _isBannerAdLoaded = false;
    _bannerAd = AdHelper.getBannerAd(() {
      if (mounted) setState(() => _isBannerAdLoaded = true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadBannerAd();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _intro.dispose();
    _idle.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  void _showDuaaDialog() {
    if (!context.read<CardVisibilityManager>().showDuaaDialog) return;
    showDialog(context: context, builder: (_) => const DuaaDialog());
  }

  Route _fade(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 380),
      );

  // ─── Actions ──────────────────────────────────────────────────────────────
  AudioManager get _audio => Provider.of<AudioManager>(context, listen: false);

  void _selectTab(int i) {
    if (i == _tab) return;
    _audio.playEventSound('clickButton');
    setState(() => _tab = i);
    if (i == 0) _refreshDaily();
  }

  void _openShop() => _selectTab(3);
  void _openProfile() => _selectTab(4);
  void _openCollections() => _selectTab(2);

  Future<void> _openSettings() async {
    _audio.playEventSound('clickButton');
    await Navigator.of(context).push(_fade(const SettingsPage()));
  }

  Future<void> _openSection(String key, String title, Widget child, Color accent, {bool fullPage = false}) async {
    _audio.playEventSound('clickButton');
    final completed = await DailyAdventure.mark(key);
    if (!mounted) return;
    if (completed) {
      Provider.of<ExperienceManager>(context, listen: false).addTokenBanner(context, DailyAdventure.reward);
    }
    _refreshDaily();
    await Navigator.of(context).push(_fade(fullPage ? child : _SectionPage(title: title, accent: accent, child: child)));
    if (mounted) _refreshDaily();
  }

  Future<void> _buyGem() async {
    _audio.playEventSound('clickButton');
    final xp = Provider.of<ExperienceManager>(context, listen: false);
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: KidColors.purpleDeep.withOpacity(0.35),
      builder: (ctx) => KidDialog(
        headerAsset: HomeAssets.gem,
        headerAspect: 0.9196,
        title: tr(ctx).getAGem,
        message: tr(ctx).tradeGoldForGem(3),
        actions: [
          KidOutlineButton(label: tr(ctx).cancel, onTap: () => Navigator.pop(ctx, false)),
          KidButton(
            label: tr(ctx).confirm,
            width: double.infinity,
            height: 50,
            showArrow: false,
            onPressed: xp.saveTokenCount >= 3 ? () => Navigator.pop(ctx, true) : null,
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      if (xp.buySaveTokens(amount: 3)) {
        _audio.playEventSound('clickButton2');
      }
    }
  }

  Future<void> _playVerse(String audio) async {
    if (_versePlaying) return;
    setState(() => _versePlaying = true);
    try {
      await _audio.playAlert(audio).timeout(const Duration(seconds: 45), onTimeout: () {});
    } finally {
      if (mounted) setState(() => _versePlaying = false);
    }
  }

  void _openQuests() => _selectTab(1);

  Widget _tabPage() => switch (_tab) {
        1 => const QuestsPage(embedded: true),
        2 => const CollectionPagePremium(embedded: true),
        3 => const MainShopPageIndex(embedded: true),
        _ => const ProfilePage(embedded: true),
      };

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final xp = Provider.of<ExperienceManager>(context);
    final size = MediaQuery.sizeOf(context);
    final w = min(size.width, 560.0) - 28; // content width
    final s = w / 380; // scale vs a 380dp-wide design
    final ayat = ayatList[DateTime.now().difference(DateTime(2024)).inDays % ayatList.length];

    Widget step(int i, Widget child) =>
        KidIntro(intro: _intro, from: 0.08 * i, to: min(1.0, 0.45 + 0.08 * i), rise: 26, child: child);

    final showVerse = context.watch<CardVisibilityManager>().showAyatCard;
    final home = _homeBody(context, xp, w, s, ayat, step, showVerse);
    return PopScope(
      canPop: _tab == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _tab = 0); // system back on a tab → home
      },
      child: Scaffold(
      backgroundColor: KidColors.sky,
      floatingActionButton: _tab == 0 ? const AnimatedRewardFAB() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BottomNav(
            scale: s,
            avatar: xp.selectedAvatar,
            current: _tab,
            onHome: () => _selectTab(0),
            onQuests: _openQuests,
            onCollections: _openCollections,
            onShop: _openShop,
            onProfile: _openProfile,
            questBadge: !_dailyClaimed,
          ),
          if (context.watch<ExperienceManager>().adsEnabled)
            FamilyAdBanner(bannerAd: _bannerAd, isLoaded: _isBannerAdLoaded),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
        child: KeyedSubtree(key: ValueKey(_tab), child: _tab == 0 ? home : _tabPage()),
      ),
    ),
    );
  }

  Widget _homeBody(BuildContext context, ExperienceManager xp, double w, double s, Map<String, String> ayat,
      Widget Function(int, Widget) step, bool showVerse) {
    return Stack(
        children: [
          Positioned.fill(child: Image.asset(KidAssets.valleyBg, fit: BoxFit.cover)),
          Positioned.fill(child: ColoredBox(color: Colors.white.withOpacity(0.12))),
          SafeArea(
            bottom: false,
            child: Center(
              child: SizedBox(
                width: w,
                child: Column(
                  children: [
                    const SizedBox(height: 6),
                    step(0, _Header(scale: s, gold: xp.saveTokenCount, gems: xp.stars,
                        onAddGold: _openShop, onAddGems: _buyGem)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 90),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          step(1, _HeroCard(
                            scale: s,
                            name: xp.userProfile.fullName,
                            avatar: xp.selectedAvatar,
                            level: xp.level,
                            xpNow: xp.currentLevelXP,
                            xpNeed: xp.requiredXPForNextLevel,
                            idle: _idle,
                            onAvatar: _openProfile,
                            onSettings: _openSettings,
                          )),
                          if (showVerse) ...[
                          SizedBox(height: 12 * s),
                          step(2, _VerseCard(
                            scale: s,
                            text: ayat['text']!,
                            surah: ayat['surah']!,
                            playing: _versePlaying,
                            idle: _idle,
                            onPlay: () => _playVerse(ayat['audio']!),
                          )),
                          ],
                          SizedBox(height: 12 * s),
                          step(3, Row(children: [
                            Expanded(child: _SectionTile(scale: s, image: HomeAssets.tileCourses, arrow: HomeAssets.arrowOrange,
                                label: tr(context).courses, done: _dailyDone.contains('courses'),
                                onTap: () => _openSection('courses', tr(context).courses, const CoursesPage(), KidColors.orange, fullPage: true))),
                            SizedBox(width: 12 * s),
                            Expanded(child: _SectionTile(scale: s, image: HomeAssets.tileGames, arrow: HomeAssets.arrowPink,
                                label: tr(context).games, done: _dailyDone.contains('games'),
                                onTap: () => _openSection('games', tr(context).games, const GamesPage(), const Color(0xFFEC4899), fullPage: true))),
                          ])),
                          SizedBox(height: 12 * s),
                          step(4, Row(children: [
                            Expanded(child: _SectionTile(scale: s, image: HomeAssets.tileIt, arrow: HomeAssets.arrowBlue,
                                label: tr(context).homeIT, done: _dailyDone.contains('it'),
                                onTap: () => _openSection('it', tr(context).informationTechnology, const ITPage(), const Color(0xFF3B82F6), fullPage: true))),
                            SizedBox(width: 12 * s),
                            Expanded(child: _SectionTile(scale: s, image: HomeAssets.tileReligion, arrow: HomeAssets.arrowGreen,
                                label: tr(context).homeReligion, done: _dailyDone.contains('religion'),
                                onTap: () => _openSection('religion', tr(context).homeReligion, const ReligionPage(), const Color(0xFF16A34A), fullPage: true))),
                          ])),
                          SizedBox(height: 12 * s),
                          step(5, _DailyCard(scale: s, done: _dailyDone.length, claimed: _dailyClaimed, onTap: _openQuests)),
                          SizedBox(height: 12 * s),
                          step(6, _ShopCard(scale: s, idle: _idle, onTap: _openShop)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Pieces
// ═══════════════════════════════════════════════════════════════════════════

const _ink = KidColors.ink;

BoxDecoration _cardDeco(double r, {Color border = const Color(0xFFE4DAF8)}) => BoxDecoration(
      color: const Color(0xFFFFFCF6),
      borderRadius: BorderRadius.circular(r),
      border: Border.all(color: border, width: 2.5),
      boxShadow: [
        BoxShadow(color: KidColors.purpleDeep.withOpacity(0.14), blurRadius: 14, offset: const Offset(0, 6)),
      ],
    );

Widget homeAvatar(String avatar, double size) {
  if (avatar.endsWith('.json')) return Lottie.asset(avatar, width: size, height: size, fit: BoxFit.cover);
  if (avatar.startsWith('assets/')) {
    return Image.asset(avatar, width: size, height: size, fit: BoxFit.cover, filterQuality: FilterQuality.medium);
  }
  return SizedBox(
      width: size, height: size, child: Center(child: Text(avatar.isEmpty ? '🙂' : avatar, style: TextStyle(fontSize: size * 0.5))));
}

class _Header extends StatelessWidget {
  final double scale;
  final int gold, gems;
  final VoidCallback onAddGold, onAddGems;
  const _Header({required this.scale, required this.gold, required this.gems, required this.onAddGold, required this.onAddGems});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return SizedBox(
      height: 46 * s,
      child: Row(
        children: [
          Image.asset(KidAssets.wordmark, height: 40 * s, fit: BoxFit.contain),
          const Spacer(),
          _CurrencyPill(scale: s, icon: HomeAssets.coin, plus: HomeAssets.plusOrange, value: gold,
              semantic: tr(context).goldLabel, onPlus: onAddGold),
          SizedBox(width: 6 * s),
          _CurrencyPill(scale: s, icon: HomeAssets.gem, plus: HomeAssets.plusBlue, value: gems,
              semantic: tr(context).gemsLabel, onPlus: onAddGems),
        ],
      ),
    );
  }
}

class _CurrencyPill extends StatelessWidget {
  final double scale;
  final String icon, plus, semantic;
  final int value;
  final VoidCallback onPlus;
  const _CurrencyPill({required this.scale, required this.icon, required this.plus, required this.value,
      required this.semantic, required this.onPlus});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final h = 38 * s;
    return Semantics(
      label: '$semantic $value',
      child: Container(
        height: h,
        padding: EdgeInsets.symmetric(horizontal: 3 * s),
        decoration: BoxDecoration(
          color: KidColors.cream,
          borderRadius: BorderRadius.circular(h),
          boxShadow: [BoxShadow(color: KidColors.purpleDeep.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(icon, width: h * 0.9, height: h * 0.9),
            SizedBox(width: 4 * s),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: Text('$value',
                  key: ValueKey(value),
                  style: kidBodyStyle(17 * s, color: _ink, weight: FontWeight.w700)),
            ),
            SizedBox(width: 5 * s),
            KidPressable(onTap: onPlus, child: Image.asset(plus, width: h * 0.82, height: h * 0.82)),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final double scale;
  final String name, avatar;
  final int level, xpNow, xpNeed;
  final Animation<double> idle;
  final VoidCallback onAvatar, onSettings;

  const _HeroCard({
    required this.scale, required this.name, required this.avatar, required this.level,
    required this.xpNow, required this.xpNeed, required this.idle, required this.onAvatar, required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final h = 168 * s;
    final r = 26 * s;
    final av = 104 * s;
    final displayName = (name.isEmpty || name == 'Player') ? '' : name.split(' ').first;
    final progress = xpNeed <= 0 ? 0.0 : (xpNow / xpNeed).clamp(0.0, 1.0);
    return Container(
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: const Color(0xFFD7C8FA), width: 3),
        boxShadow: [BoxShadow(color: KidColors.purpleDeep.withOpacity(0.25), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r - 3),
        child: Stack(
          children: [
            Positioned.fill(child: Image.asset(HomeAssets.heroBg, fit: BoxFit.cover, alignment: Alignment.centerRight)),
            // darken the left side a touch so the white text pops
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    const Color(0xFF1B1464).withOpacity(0.45),
                    const Color(0xFF1B1464).withOpacity(0.0),
                  ], stops: const [0.25, 0.8]),
                ),
              ),
            ),
            // Avatar
            PositionedDirectional(
              start: 12 * s,
              top: 12 * s,
              child: KidPressable(
                onTap: onAvatar,
                child: AnimatedBuilder(
                  animation: idle,
                  builder: (_, c) => Transform.translate(offset: Offset(0, sin(idle.value * 4 * pi) * 2.5 * s), child: c),
                  child: Container(
                    width: av,
                    height: av,
                    padding: EdgeInsets.all(av * 0.05),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [Color(0xFFFFE27A), Color(0xFFFFB627)]),
                      boxShadow: [BoxShadow(color: const Color(0xFFFFC93C).withOpacity(0.6), blurRadius: 14)],
                    ),
                    child: ClipOval(child: ColoredBox(color: const Color(0xFFFFE9A8), child: homeAvatar(avatar, av))),
                  ),
                ),
              ),
            ),
            // Greeting
            PositionedDirectional(
              start: av + 24 * s,
              end: 46 * s,
              top: 26 * s,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(text: displayName.isEmpty ? tr(context).homeHiNoName : tr(context).homeHi),
                        if (displayName.isNotEmpty)
                          TextSpan(text: ' $displayName!', style: const TextStyle(color: Color(0xFFFFD447))),
                      ]),
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Fredoka', fontWeight: FontWeight.w700, fontSize: 30 * s, color: Colors.white,
                        shadows: const [Shadow(color: Color(0x99000000), blurRadius: 6, offset: Offset(0, 2))],
                      ),
                    ),
                  ),
                  SizedBox(height: 2 * s),
                  Text(tr(context).homeReady,
                      maxLines: 2,
                      style: kidBodyStyle(14 * s, color: Colors.white, weight: FontWeight.w600).copyWith(
                          shadows: const [Shadow(color: Color(0x99000000), blurRadius: 4)])),
                ],
              ),
            ),
            // Settings
            PositionedDirectional(
              top: 8 * s,
              end: 8 * s,
              child: KidPressable(
                onTap: onSettings,
                semanticLabel: tr(context).settings,
                child: Image.asset(HomeAssets.gear, width: 38 * s, height: 38 * s),
              ),
            ),
            // Level bar
            PositionedDirectional(
              start: 14 * s,
              end: 14 * s,
              bottom: 10 * s,
              child: Container(
                height: 34 * s,
                padding: EdgeInsetsDirectional.only(start: 2 * s, end: 12 * s),
                decoration: BoxDecoration(
                  color: KidColors.cream.withOpacity(0.96),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Row(
                  children: [
                    Transform.translate(
                      offset: Offset(0, -2 * s),
                      child: Image.asset(HomeAssets.star, width: 38 * s, height: 38 * s),
                    ),
                    SizedBox(width: 4 * s),
                    Text(tr(context).levelN(level), style: kidBodyStyle(14 * s, color: _ink, weight: FontWeight.w700)),
                    SizedBox(width: 10 * s),
                    Expanded(
                      child: Container(
                        height: 12 * s,
                        decoration: BoxDecoration(color: const Color(0xFFD9D0F5), borderRadius: BorderRadius.circular(20)),
                        alignment: AlignmentDirectional.centerStart,
                        child: FractionallySizedBox(
                          widthFactor: max(0.04, progress),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: const LinearGradient(colors: [Color(0xFFFFC23A), Color(0xFFFFA514)]),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10 * s),
                    Text('$xpNow / $xpNeed XP', style: kidBodyStyle(12 * s, color: _ink, weight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerseCard extends StatelessWidget {
  final double scale;
  final String text, surah;
  final bool playing;
  final Animation<double> idle;
  final VoidCallback onPlay;

  const _VerseCard({required this.scale, required this.text, required this.surah, required this.playing,
      required this.idle, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final h = 128 * s;
    final r = 24 * s;
    return Container(
      height: h,
      decoration: _cardDeco(r, border: const Color(0xFFCDEBD9)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r - 2.5),
        child: Row(
          textDirection: TextDirection.ltr,
          children: [
            Image.asset(HomeAssets.verseArt, height: h, width: h * 1.0, fit: BoxFit.cover, alignment: Alignment.centerLeft),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 8 * s),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 3 * s),
                      decoration: BoxDecoration(color: const Color(0xFFE0F5E8), borderRadius: BorderRadius.circular(30)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('🌙', style: TextStyle(fontSize: 12 * s)),
                        SizedBox(width: 4 * s),
                        Flexible(
                          child: Text(tr(context).verseOfTheDay,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: kidBodyStyle(12 * s, color: const Color(0xFF14532D), weight: FontWeight.w700)),
                        ),
                      ]),
                    ),
                    Expanded(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 190 * s),
                            child: Text(
                              text,
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              maxLines: 3,
                              style: TextStyle(fontSize: 17 * s, height: 1.5, color: const Color(0xFF0F3D24), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(surah,
                        textDirection: TextDirection.rtl,
                        style: kidBodyStyle(11 * s, color: const Color(0xFF15803D), weight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.only(end: 10 * s),
              child: KidPressable(
                onTap: onPlay,
                semanticLabel: tr(context).tapToListen,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: idle,
                      builder: (_, c) => Transform.scale(
                          scale: playing ? 1.0 + 0.06 * sin(idle.value * 24 * pi) : 1.0, child: c),
                      child: Container(
                        width: 58 * s,
                        height: 58 * s,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                              begin: Alignment.topCenter, end: Alignment.bottomCenter,
                              colors: [Color(0xFF34D27A), Color(0xFF14984A)]),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [BoxShadow(color: const Color(0xFF16A34A).withOpacity(0.45), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: Icon(playing ? Icons.graphic_eq_rounded : Icons.play_arrow_rounded,
                            color: Colors.white, size: 36 * s),
                      ),
                    ),
                    SizedBox(height: 4 * s),
                    Text(tr(context).tapToListen, style: kidBodyStyle(10 * s, color: const Color(0xFF14532D), weight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  final double scale;
  final String image, arrow, label;
  final bool done;
  final VoidCallback onTap;

  const _SectionTile({required this.scale, required this.image, required this.arrow, required this.label,
      required this.done, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final r = 22 * s;
    return KidPressable(
      onTap: onTap,
      pressedScale: 0.95,
      semanticLabel: label,
      child: Container(
        decoration: _cardDeco(r, border: Colors.white),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(r - 2.5),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 1.42,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(image, fit: BoxFit.cover, filterQuality: FilterQuality.medium),
                    if (done)
                      PositionedDirectional(
                        top: 8 * s,
                        start: 8 * s,
                        child: Container(
                          padding: EdgeInsets.all(3 * s),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: Icon(Icons.check_circle_rounded, color: const Color(0xFF16A34A), size: 20 * s),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                height: 46 * s,
                color: const Color(0xFFFFFCF6),
                padding: EdgeInsets.symmetric(horizontal: 12 * s),
                child: Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(label, maxLines: 1, style: kidTitleStyle(22 * s, color: _ink).copyWith(shadows: const [])),
                      ),
                    ),
                    Transform.flip(
                      flipX: Directionality.of(context) == TextDirection.rtl,
                      child: Image.asset(arrow, width: 34 * s, height: 34 * s),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyCard extends StatelessWidget {
  final double scale;
  final int done;
  final bool claimed;
  final VoidCallback onTap;
  const _DailyCard({required this.scale, required this.done, required this.claimed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return KidPressable(
      onTap: onTap,
      pressedScale: 0.97,
      child: Container(
        height: 62 * s,
        padding: EdgeInsets.symmetric(horizontal: 12 * s),
        decoration: _cardDeco(22 * s),
        child: Row(
          children: [
            Image.asset(HomeAssets.star, width: 40 * s, height: 40 * s),
            SizedBox(width: 10 * s),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(tr(context).dailyAdventure, style: kidBodyStyle(17 * s, color: _ink, weight: FontWeight.w700)),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(claimed ? tr(context).dailyDoneMsg : tr(context).dailyGoalMsg(DailyAdventure.goal),
                        style: kidBodyStyle(12 * s, color: KidColors.purpleDeep, weight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            for (int i = 0; i < DailyAdventure.goal; i++)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 2 * s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 22 * s,
                  height: 22 * s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < done ? const Color(0xFFFFD54A) : const Color(0xFFDCD3F7),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: i < done ? Icon(Icons.star_rounded, size: 15 * s, color: const Color(0xFFB45309)) : null,
                ),
              ),
            Container(width: 1.5, height: 30 * s, margin: EdgeInsets.symmetric(horizontal: 8 * s), color: const Color(0xFFE6DDF7)),
            claimed
                ? Icon(Icons.check_circle_rounded, color: const Color(0xFF16A34A), size: 30 * s)
                : Row(children: [
                    Image.asset(HomeAssets.coin, width: 28 * s, height: 28 * s),
                    SizedBox(width: 3 * s),
                    Text('+${DailyAdventure.reward}', style: kidBodyStyle(17 * s, color: _ink, weight: FontWeight.w700)),
                  ]),
          ],
        ),
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  final double scale;
  final Animation<double> idle;
  final VoidCallback onTap;
  const _ShopCard({required this.scale, required this.idle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final h = 88 * s;
    final r = 22 * s;
    return KidPressable(
      onTap: onTap,
      pressedScale: 0.97,
      child: SizedBox(
        height: h + 10 * s,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: h,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(r),
                  border: Border.all(color: const Color(0xFFD7C8FA), width: 2.5),
                  boxShadow: [BoxShadow(color: KidColors.purpleDeep.withOpacity(0.25), blurRadius: 14, offset: const Offset(0, 6))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(r - 2.5),
                  child: Image.asset(HomeAssets.shopBg, fit: BoxFit.cover),
                ),
              ),
            ),
            PositionedDirectional(
              start: 4 * s,
              bottom: 2 * s,
              child: AnimatedBuilder(
                animation: idle,
                builder: (_, c) => Transform.translate(offset: Offset(0, sin(idle.value * 4 * pi) * 2 * s), child: c),
                child: Image.asset(HomeAssets.chest, width: 118 * s, height: 118 * s * 0.5463),
              ),
            ),
            PositionedDirectional(
              start: 128 * s,
              end: 116 * s,
              bottom: 0,
              height: h,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(tr(context).magicShop,
                        style: TextStyle(
                            fontFamily: 'Fredoka', fontWeight: FontWeight.w700, fontSize: 24 * s, color: Colors.white,
                            shadows: const [Shadow(color: Color(0x88000000), blurRadius: 4, offset: Offset(0, 2))])),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(tr(context).magicShopSub,
                        style: kidBodyStyle(12 * s, color: Colors.white, weight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            PositionedDirectional(
              end: 12 * s,
              bottom: (h - 40 * s) / 2,
              child: Container(
                height: 40 * s,
                padding: EdgeInsets.symmetric(horizontal: 14 * s),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  gradient: const LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFE066), Color(0xFFFFC21A)]),
                  boxShadow: [BoxShadow(color: const Color(0xFFB45309).withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(tr(context).exploreLabel, style: kidBodyStyle(15 * s, color: _ink, weight: FontWeight.w700)),
                  SizedBox(width: 2 * s),
                  Icon(Icons.chevron_right_rounded, color: _ink, size: 22 * s),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final double scale;
  final String avatar;
  final bool questBadge;
  final int current;
  final VoidCallback onHome, onQuests, onCollections, onShop, onProfile;

  const _BottomNav({
    required this.scale, required this.avatar, required this.questBadge, required this.current, required this.onHome,
    required this.onQuests, required this.onCollections, required this.onShop, required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    final s = min(scale, 1.15);
    Widget item(Widget icon, String label, VoidCallback onTap, {bool active = false}) => Expanded(
          child: KidPressable(
            onTap: onTap,
            semanticLabel: label,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: EdgeInsets.symmetric(horizontal: 3 * s, vertical: 6 * s),
              decoration: BoxDecoration(
                color: active ? const Color(0xFFE6DCFF) : Colors.transparent,
                borderRadius: BorderRadius.circular(18 * s),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 32 * s, child: Center(child: icon)),
                  SizedBox(height: 2 * s),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(label,
                        style: kidBodyStyle(12 * s,
                            color: active ? KidColors.purpleDeep : const Color(0xFF5B5478),
                            weight: active ? FontWeight.w700 : FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        );
    return Container(
      decoration: BoxDecoration(
        color: KidColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26 * s)),
        boxShadow: [BoxShadow(color: KidColors.purpleDeep.withOpacity(0.18), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70 * s,
          child: Row(
            children: [
              item(Image.asset(HomeAssets.navHome, height: 30 * s), tr(context).navHome, onHome, active: current == 0),
              item(
                  Stack(clipBehavior: Clip.none, children: [
                    Image.asset(HomeAssets.navQuests, height: 30 * s),
                    // the sprite has a red dot baked in; hide it once today's quest is done
                    if (!questBadge)
                      Positioned(
                        right: 0, top: 0,
                        child: Container(width: 11 * s, height: 11 * s, color: KidColors.cream),
                      ),
                  ]),
                  tr(context).navQuests,
                  onQuests,
                  active: current == 1),
              item(Image.asset(HomeAssets.navCollections, height: 30 * s), tr(context).navCollections, onCollections, active: current == 2),
              item(Image.asset(HomeAssets.navShop, height: 30 * s), tr(context).navShop, onShop, active: current == 3),
              item(ClipOval(child: SizedBox(width: 30 * s, height: 30 * s, child: homeAvatar(avatar, 30 * s))),
                  tr(context).navProfile, onProfile, active: current == 4),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen wrapper for a section (Courses, Games, IT, Religion).
class _SectionPage extends StatelessWidget {
  final String title;
  final Color accent;
  final Widget child;
  const _SectionPage({required this.title, required this.accent, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KidColors.sky,
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset(KidAssets.valleyBg, fit: BoxFit.cover)),
          Positioned.fill(child: ColoredBox(color: Colors.white.withOpacity(0.18))),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                  child: Row(
                    children: [
                      KidBackButton(
                        size: 44,
                        onTap: () {
                          Provider.of<AudioManager>(context, listen: false).playEventSound('cancelButton');
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(title, style: kidTitleStyle(30)),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestSheet extends StatelessWidget {
  final Set<String> done;
  final bool claimed;
  const _QuestSheet({required this.done, required this.claimed});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('courses', tr(context).courses, HomeAssets.tileCourses),
      ('games', tr(context).games, HomeAssets.tileGames),
      ('it', tr(context).homeIT, HomeAssets.tileIt),
      ('religion', tr(context).homeReligion, HomeAssets.tileReligion),
    ];
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        decoration: BoxDecoration(
          color: KidColors.cream,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: KidColors.lavender, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 46, height: 5, decoration: BoxDecoration(color: KidColors.lavender, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 12),
            Row(children: [
              Image.asset(HomeAssets.star, width: 40, height: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tr(context).dailyAdventure, style: kidBodyStyle(20, color: _ink, weight: FontWeight.w700)),
                  Text(claimed ? tr(context).dailyDoneMsg : tr(context).dailyGoalMsg(DailyAdventure.goal),
                      style: kidBodyStyle(13, color: KidColors.purpleDeep)),
                ]),
              ),
              Image.asset(HomeAssets.coin, width: 30, height: 30),
              Text(' +${DailyAdventure.reward}', style: kidBodyStyle(18, color: _ink, weight: FontWeight.w700)),
            ]),
            const SizedBox(height: 14),
            for (final it in items)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: done.contains(it.$1) ? const Color(0xFF86EFAC) : const Color(0xFFE6DDF7), width: 2),
                ),
                child: Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(it.$3, width: 64, height: 44, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(it.$2, style: kidBodyStyle(16, color: _ink, weight: FontWeight.w700))),
                  Icon(done.contains(it.$1) ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      color: done.contains(it.$1) ? const Color(0xFF16A34A) : KidColors.lavender, size: 26),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}
