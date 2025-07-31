import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/Settings/setting_Page.dart';
import 'package:mortaalim/tools/Ads_Manager.dart';
import 'package:mortaalim/Settings/SettingPanelInGame.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/tools/loading_page.dart';
import 'package:mortaalim/widgets/ComingSoonNotPage.dart';
import 'package:mortaalim/widgets/profile_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'XpSystem.dart';
import 'indexPage_tools/Course_index_tool/course_index.dart';
import 'indexPage_tools/Game_index_tool/game_index.dart';
import 'indexPage_tools/language_menu.dart';
import 'main.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

class Index extends StatefulWidget {
  final void Function(Locale) onChangeLocale;
  const Index({super.key, required this.onChangeLocale});

  @override
  State<Index> createState() => _IndexState();
}

class _IndexState extends State<Index>
    with TickerProviderStateMixin, WidgetsBindingObserver, RouteAware {

  BannerAd? _bannerAd;

  bool _isBannerAdLoaded = false;

  late TabController _tabController;
  String childName = "Player";

  late final AnimationController _profileAnimController;
  late final Animation<Offset> _profileSlideAnimation;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    WidgetsBinding.instance.addObserver(this);
    final xpManager = Provider.of<ExperienceManager>(context, listen: false);
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    audioManager.playBackgroundMusic("assets/audios/BackGround_Audio/IndexBackGroundMusic_BCG.mp3");
    xpManager.init(context);

    _tabController = TabController(length: 4, vsync: this);

    _loadProfile();

    _profileAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _profileSlideAnimation = Tween<Offset>(
      begin: const Offset(-2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _profileAnimController,
      curve: Curves.easeOut,
    ));


    _profileAnimController.forward();
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
    if (state == AppLifecycleState.resumed) {
      _loadBannerAd();
    }
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


  void _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      childName = prefs.getString('name') ?? "Player";
    });
  }

  Widget _buildAvatar(String avatarPath) {
    if (avatarPath.endsWith('.json')) {
      return SizedBox(
        width: 85,
        height: 85,
        child: Lottie.asset(
          avatarPath,
          fit: BoxFit.cover,
          repeat: true,
        ),
      );
    } else if (avatarPath.contains('assets/')) {
      return Image.asset(
        avatarPath,
        width: 85,
        height: 85,
        fit: BoxFit.cover,
      );
    } else {
      return Center(
        child: Text(
          avatarPath,
          style: const TextStyle(fontSize: 36),
        ),
      );
    }
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
    final avatarEmoji = xpManager.selectedAvatar;
    final stars = xpManager.stars;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepOrangeAccent.withAlpha(220),
        leading: LanguageMenu(
          onChangeLocale: widget.onChangeLocale,
          colorButton: Colors.white,
        ),
        title: Text(tr(context).welcome, style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
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
            icon: const Icon(Icons.storefront_outlined, color: Colors.white),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              audioManager.playEventSound('clickButton');
              showDialog(
                barrierDismissible: false,
                context: context,
                barrierColor: Colors.black.withOpacity(0.3), // Semi-transparent overlay
                builder: (BuildContext context) {
                  return const SettingsDialog();
                },
              );
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          unselectedLabelColor: Colors.white30,
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: [
            Tab(icon: const Icon(Icons.school_outlined), text: tr(context).courses),
            Tab(icon: const Icon(Icons.videogame_asset), text: tr(context).games),
            Tab(icon: Icon(Icons.computer), text: "IT"),
            Tab(icon: Icon(Icons.menu_book), text: "Islam"),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: Column(
            children: [
              SlideTransition(
                position: _profileSlideAnimation,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        xpManager.selectedBannerImage,
                        width: double.infinity,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.black.withValues(alpha: 0.15),
                      ),
                    ),
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Material(
                              color: Colors.orange.withValues(alpha: 0.1),
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () {
                                  audioManager.playEventSound('clickButton');
                                  Navigator.of(context)
                                      .push(createFadeRoute(ProfilePage(
                                    initialName: childName,
                                    initialAvatar: avatarEmoji,
                                    initialAge: 13,
                                    initialColor: Colors.red,
                                    initialMood: "Happy",
                                  )))
                                      .then((_) => _loadProfile());
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(1.0),
                                  child: ClipOval(child: _buildAvatar(avatarEmoji)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              flex: 2,
                              child: InkWell(
                                onTap: () {
                                  audioManager.playEventSound('clickButton');
                                  Navigator.of(context)
                                      .pushNamed('Profile')
                                      .then((_) => _loadProfile());
                                },
                                child: Text(
                                  (childName == "Player" || childName.isEmpty)
                                      ? "${tr(context).enterName} ✏️"
                                      : childName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(blurRadius: 3, color: Colors.black)
                                    ],
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
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.star, color: Colors.amber),
                                          const SizedBox(width: 2),
                                          Text(
                                            "$stars",
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.generating_tokens_rounded, color: Colors.greenAccent),
                                          const SizedBox(width: 2),
                                          Text(
                                            "${xpManager.saveTokenCount}",
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                  const SizedBox(width: 10),

                                  Column(
                                    children: [
                                   IconButton(
                                       onPressed: () {
                                         audioManager.playEventSound('clickButton');
                                         Navigator.of(context)
                                             .pushNamed('Profile')
                                             .then((_) => _loadProfile());
                                       },
                                       icon: Icon(Icons.edit_note,
                                         color: Colors.white,)),
                                   IconButton(
                                       onPressed: () {
                                         audioManager.playEventSound('clickButton');
                                        AdHelper.showRewardedAdWithLoading(context, ()  {
                                         Provider.of<ExperienceManager>(context, listen: false).addStarBanner(context,1);
                                       });
                                        },
                                       icon: Icon(Icons.card_giftcard_outlined,
                                         color: Colors.white,)),

                                    ],
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
              (context.watch<ExperienceManager>().adsEnabled && _bannerAd != null && _isBannerAdLoaded)
                  ? SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
                ),
              )
                  : const SizedBox.shrink(),

            ],
          ),
        ),
      ),

    );
  }
}
