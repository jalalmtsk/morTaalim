import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lottie/lottie.dart';
import 'package:marquee/marquee.dart';
import 'package:mortaalim/Settings/setting_Page.dart';
import 'package:mortaalim/Themes/AppTheme.dart';
import 'package:mortaalim/Themes/ThemeManager.dart';
import 'package:mortaalim/Themes/ThemeSelectorPage.dart';
import 'package:mortaalim/tools/Ads_Manager.dart';
import 'package:mortaalim/Settings/SettingPanelInGame.dart';
import 'package:mortaalim/tools/AnimatedGrid.dart';
import 'package:mortaalim/tools/Reysable_Tools/SmartDuaaMorningNight_Dialog.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/tools/loading_page.dart';
import 'package:mortaalim/widgets/Collection/Collection.dart';
import 'package:mortaalim/widgets/ComingSoonNotPage.dart';
import 'package:mortaalim/widgets/ProfileSetup_Widget/MainProfile_Page/MainProfile_page.dart';
import 'package:provider/provider.dart';

import 'Manager/Services/CardVisibiltyManager.dart';
import 'XpSystem.dart';
import 'indexPage_tools/Course_index_tool/course_index.dart';
import 'indexPage_tools/Game_index_tool/game_index.dart';
import 'indexPage_tools/language_menu.dart';
import 'main.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

class Index extends StatefulWidget {
  const Index({super.key});

  @override
  State<Index> createState() => _IndexState();
}

class _IndexState extends State<Index>
    with TickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  late TabController _tabController;

  late final AnimationController _profileAnimController;
  late final Animation<Offset> _profileSlideAnimation;

  @override
  void initState() {
    super.initState();

    _loadBannerAd();
    WidgetsBinding.instance.addObserver(this);

    _tabController = TabController(length: 4, vsync: this);

    _profileAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400), // reduced duration
    );

    _profileSlideAnimation = Tween<Offset>(
      begin: const Offset(-1.5, 0), // smaller offset
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _profileAnimController,
        curve: Curves.easeOut,
      ),
    );

    _profileAnimController.forward();

    final audioManager = Provider.of<AudioManager>(context, listen: false);
    final xpManager = Provider.of<ExperienceManager>(context, listen: false);
    xpManager.init(context);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      audioManager.playAlert("assets/audios/HappyIntranceIndex.mp3");
      audioManager.playBackgroundMusic(
        "assets/audios/BackGround_Audio/IndexBackGroundMusic_BCG.mp3",
      );

      final cardManager = context.read<CardVisibilityManager>();
      await Future.doWhile(() async {
        if (cardManager.showDuaaDialog != null) return false;
        await Future.delayed(const Duration(milliseconds: 50));
        return true;
      });

      _showDuaaDialog();
    });

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        audioManager.playEventSound('clickButton');
      }
    });
  }

  void _loadBannerAd() {
    _bannerAd?.dispose();
    _isBannerAdLoaded = false;

    _bannerAd = AdHelper.getBannerAd(() {
      setState(() {
        _isBannerAdLoaded = true;
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadBannerAd();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    _tabController.dispose();
    _profileAnimController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  Widget _buildAvatar(String avatarPath) {
    if (avatarPath.endsWith('.json')) {
      return SizedBox(
        width: 70, // slightly smaller
        height: 70,
        child: Lottie.asset(
          avatarPath,
          fit: BoxFit.cover,
          repeat: true,
        ),
      );
    } else if (avatarPath.contains('assets/')) {
      return Image.asset(
        avatarPath,
        width: 70,
        height: 70,
        fit: BoxFit.cover,
      );
    } else {
      return Center(
        child: Text(
          avatarPath,
          style: const TextStyle(fontSize: 28),
        ),
      );
    }
  }

  void _showDuaaDialog() {
    if (!context.read<CardVisibilityManager>().showDuaaDialog) return;

    showDialog(
      context: context,
      builder: (_) => const DuaaDialog(),
    );
  }

  Future<void> simulateLoading() async {
    await Future.delayed(const Duration(seconds: 3));
  }

  Route createFadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    final xpManager = Provider.of<ExperienceManager>(context);
    final user = xpManager.userProfile;
    final avatarEmoji = xpManager.selectedAvatar;
    final stars = xpManager.stars;
    final themeManager = Provider.of<ThemeManager>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background
          SizedBox.expand(
            child: Image.asset(
              themeManager.currentTheme.backgroundImage,
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Fake AppBar with reduced blur
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2), // optimized blur
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        color: Colors.black.withOpacity(0.15),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            LanguageMenu(colorButton: Colors.white),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                tr(context).welcome,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                                ),
                              ),
                            ),


                            IconButton(onPressed: (){
                              Navigator.push(context, MaterialPageRoute(builder: (_) => CollectionPagePremium()));
                            },
                                icon: Icon(Icons.collections, color: themeManager.currentTheme.accentColor,)),

                            IconButton(
                              onPressed: () {
                                audioManager.playEventSound('clickButton');
                                Navigator.of(context).push(createFadeRoute(
                                  LoadingPage(
                                    loadingFuture: simulateLoading(),
                                    nextRouteName: 'Shop',
                                  ),
                                ));
                              },
                              tooltip: 'Shop',
                              icon: Icon(Icons.storefront_outlined,
                                  color: themeManager.currentTheme.primaryColor),
                            ),
                            IconButton(
                              icon: Icon(Icons.settings,
                                  color: themeManager.currentTheme.accentColor),
                              onPressed: () {
                                audioManager.playEventSound('clickButton');
                                showDialog(
                                  barrierDismissible: false,
                                  context: context,
                                  barrierColor: Colors.black.withOpacity(0.3),
                                  builder: (BuildContext context) {
                                    return const SettingsDialog();
                                  },
                                );
                              },
                            ),

                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Slide-in profile card
                  SlideTransition(
                    position: _profileSlideAnimation,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            xpManager.selectedBannerImage,
                            width: double.infinity,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Container(
                          height: 90,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.black.withOpacity(0.12),
                          ),
                        ),
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Material(
                                  color: Colors.orange.withOpacity(0.1),
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () {
                                      audioManager.playEventSound('clickButton');
                                      Navigator.of(context)
                                          .push(createFadeRoute(MainProfilePage()));
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(1.0),
                                      child: ClipOval(child: _buildAvatar(avatarEmoji)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  flex: 2,
                                  child: InkWell(
                                    onTap: () {
                                      audioManager.playEventSound('clickButton');
                                      Navigator.of(context).pushNamed('Profile');
                                    },
                                    child: Text(
                                      (user.fullName.isEmpty || user.fullName == "Player")
                                          ? "${tr(context).enterName} ✏️"
                                          : user.fullName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.star, color: Colors.amber),
                                              const SizedBox(width: 2),
                                              Text(
                                                "$stars",
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              const Icon(Icons.generating_tokens_rounded,
                                                  color: Colors.greenAccent),
                                              const SizedBox(width: 2),
                                              Text(
                                                "${xpManager.saveTokenCount}",
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                      const SizedBox(width: 8),
                                      Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: IconButton(
                                                onPressed: () {
                                                  audioManager.playEventSound('clickButton');
                                                  Navigator.of(context).pushNamed('Profile');
                                                },
                                                icon: const Icon(Icons.edit_note,
                                                    color: Colors.white, size: 28),
                                              ),
                                            ),
                                            Expanded(
                                              child: IconButton(
                                                onPressed: () {
                                                  audioManager.playEventSound('clickButton');
                                                  AdHelper.showRewardedAdWithLoading(context, () {
                                                    Provider.of<ExperienceManager>(context,
                                                        listen: false)
                                                        .addTokenBanner(context, 2);
                                                  });
                                                },
                                                icon: const Icon(Icons.ads_click,
                                                    color: Colors.white, size: 30),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 2),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // TabBar with optimized blur
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        color: Colors.black.withOpacity(0.18),
                        child: TabBar(
                          controller: _tabController,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white.withOpacity(0.2),
                            border: Border.all(color: themeManager.currentTheme.accentColor, width: 0.4)
                          ),
                          indicatorWeight: 2,
                          labelColor: Colors.white,
                          labelStyle:
                          const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          unselectedLabelColor: Colors.white54,
                          unselectedLabelStyle: const TextStyle(fontSize: 14),
                          tabs: [
                            Tab(
                                icon: const Icon(Icons.school_outlined),
                                text: tr(context).courses),
                            Tab(
                                icon: const Icon(Icons.videogame_asset),
                                text: tr(context).games),
                            Tab(
                              icon: const Icon(Icons.computer),
                              child: SizedBox(
                                height: 20, // prevent layout jump
                                child: Marquee(
                                  text: tr(context).informationTechnology,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                  scrollAxis: Axis.horizontal,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  blankSpace: 30.0,
                                  velocity: 30.0,
                                  pauseAfterRound: Duration(milliseconds: 800),
                                  startPadding: 10.0,
                                  accelerationDuration: Duration(seconds: 1),
                                  accelerationCurve: Curves.linear,
                                  decelerationDuration: Duration(milliseconds: 500),
                                  decelerationCurve: Curves.easeOut,
                                ),
                              ),
                            ),
                            Tab(icon: Icon(Icons.menu_book), text: tr(context).islam),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // TabBarView
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        CourseTab(),
                        GamesTab(),
                        ComingSoonNotPage(),
                        ComingSoonNotPage(),
                      ],
                    ),
                  ),

                  // Banner Ad
                  if (context.watch<ExperienceManager>().adsEnabled &&
                      _bannerAd != null &&
                      _isBannerAdLoaded)
                    SafeArea(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: SizedBox(
                          width: _bannerAd!.size.width.toDouble(),
                          height: _bannerAd!.size.height.toDouble(),
                          child: AdWidget(ad: _bannerAd!),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
