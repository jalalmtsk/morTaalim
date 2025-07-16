import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/tools/Ads_Manager.dart';
import 'package:mortaalim/tools/SettingPanelInGame.dart';
import 'package:mortaalim/tools/loading_page.dart';
import 'package:mortaalim/widgets/profile_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
import 'XpSystem.dart';
import 'indexPage_tools/Course_index_tool/course_index.dart';
import 'indexPage_tools/Game_index_tool/game_index.dart';
import 'indexPage_tools/language_menu.dart';
import 'tools/audio_tool/audio_tool.dart';

class Index extends StatefulWidget {
  final void Function(Locale) onChangeLocale;
  const Index({super.key, required this.onChangeLocale});

  @override
  State<Index> createState() => _IndexState();
}

class _IndexState extends State<Index>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final MusicPlayer _musicPlayer = MusicPlayer();
  final MusicPlayer _clickButton = MusicPlayer();

  late TabController _tabController;
  String childName = "Player";

  late final AnimationController _profileAnimController;
  late final Animation<Offset> _profileSlideAnimation;
  late final Animation<double> _profileFadeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _tabController = TabController(length: 2, vsync: this);

    _loadProfile();

    final xpManager = Provider.of<ExperienceManager>(context, listen: false);

    if (xpManager.musicEnabled) {
      _musicPlayer.play("assets/audios/sound_track/backGroundMusic8bit.mp3", loop: true);
      _musicPlayer.setVolume(xpManager.musicVolume);
    }

    // Listen to music state & volume changes in ExperienceManager
    xpManager.addListener(() {
      if (xpManager.musicEnabled) {
        _musicPlayer.setVolume(xpManager.musicVolume);
        if (!_musicPlayer.isPlaying) {
          _musicPlayer.play("assets/audios/sound_track/backGroundMusic8bit.mp3", loop: true);
        }
      } else {
        _musicPlayer.stop();
      }
    });

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

    _profileFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _profileAnimController, curve: Curves.easeIn),
    );

    _profileAnimController.forward();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _musicPlayer.pause();
    } else if (state == AppLifecycleState.resumed) {
      final musicIsOn = Provider.of<ExperienceManager>(context, listen: false).musicEnabled;
      if (musicIsOn) {
        _musicPlayer.resume();
        final xpManager = Provider.of<ExperienceManager>(context, listen: false);
        _musicPlayer.setVolume(xpManager.musicVolume);
      }
    }
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _musicPlayer.dispose();
    _clickButton.dispose();
    _profileAnimController.dispose();
    super.dispose();
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
    final xpManager = Provider.of<ExperienceManager>(context);
    final tr = AppLocalizations.of(context)!;
    final avatarEmoji = xpManager.selectedAvatar;
    final stars = xpManager.stars;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepOrangeAccent.withAlpha(220),
        leading:    LanguageMenu(
          onChangeLocale: widget.onChangeLocale,
          colorButton: Colors.white,
        ),
        // Removed the leading MusicButton here
        title: Text(tr.welcome, style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [

          IconButton(
            onPressed: () {
              _clickButton.play("assets/audios/pop.mp3");
              Navigator.of(context).push(createFadeRoute(
                LoadingPage(
                  loadingFuture: simulateLoading(),
                  nextRouteName: 'Shop',
                ),
              ));
            },
            icon: const Icon(Icons.storefront_outlined, color: Colors.white),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white,),
            onPressed: () {
              _clickButton.play("assets/audios/pop.mp3");
              showDialog(
                context: context,
                builder: (_) => const SettingsDialog(),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          labelStyle:
          const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          unselectedLabelColor: Colors.white30,
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: [
            Tab(icon: const Icon(Icons.school), text: tr.courses),
            Tab(icon: const Icon(Icons.videogame_asset), text: tr.games),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Background image (optional)
          // Positioned.fill(
          //   child: Image.asset(
          //     'assets/images/Untitled design-2.png',
          //     fit: BoxFit.cover,
          //   ),
          // ),

          Padding(
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
                            color: Colors.black.withOpacity(0.15),
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
                                      _clickButton.play("assets/audios/pop.mp3");
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
                                      Navigator.of(context)
                                          .pushNamed('Profile')
                                          .then((_) => _loadProfile());
                                    },
                                    child: Text(
                                      (childName == "Player" || childName.isEmpty)
                                          ? "${tr.enterName} ✏️"
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
                                              const Icon(Icons.star,
                                                  color: Colors.amber),
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
                                              const Icon(
                                                  Icons.generating_tokens_rounded,
                                                  color: Colors.greenAccent),
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
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.mode_edit_sharp,
                                          color: Colors.white),
                                      onPressed: () {
                                        _clickButton.play("assets/audios/pop.mp3");
                                        Navigator.of(context)
                                            .pushNamed('Profile')
                                            .then((_) => _loadProfile());
                                      },
                                    ),

                                    IconButton(
                                      icon: const Icon(Icons.ads_click_outlined,
                                          color: Colors.white),
                                      onPressed:() => AdHelper.showRewardedAdWithLoading(context, 1),
                                    ),

                                  ],
                                ),
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
                        CourseTab(musicPlayer: _musicPlayer),
                        GamesTab(musicPlayer: _musicPlayer),
                      ],
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
