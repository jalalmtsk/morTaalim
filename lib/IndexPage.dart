import 'package:flutter/material.dart';
import 'package:mortaalim/loading_page.dart';
import 'package:mortaalim/profile_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';

import 'XpSystem.dart';
import 'indexPage_tools/Course_index_tool/course_index.dart';
import 'indexPage_tools/Game_index_tool/game_index.dart';
import 'indexPage_tools/language_menu.dart';
import 'indexPage_tools/music_button.dart';
import 'tools/audio_tool/audio_tool.dart';

class Index extends StatefulWidget {
  final void Function(Locale) onChangeLocale;
  const Index({super.key, required this.onChangeLocale});

  @override
  State<Index> createState() => _IndexState();
}

bool musicisOn = true;

class _IndexState extends State<Index> with TickerProviderStateMixin, WidgetsBindingObserver {
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

    _musicPlayer.play("assets/audios/sound_track/backGroundMusic8bit.mp3", loop: true);

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
      if (musicisOn) {
        _musicPlayer.resume();
      }
    }
  }

  void toggleMusic() {
    setState(() => musicisOn = !musicisOn);
    musicisOn
        ? _musicPlayer.play("assets/audios/sound_track/backGroundMusic8bit.mp3", loop: true)
        : _musicPlayer.stop();
  }

  void _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      childName = prefs.getString('name') ?? "Player";
    });
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
    final tr = AppLocalizations.of(context)!;
    final xpManager = Provider.of<ExperienceManager>(context);
    final avatarEmoji = xpManager.selectedAvatar;
    final stars = xpManager.stars;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepOrangeAccent.withAlpha(220),
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: MusicButton(isOn: musicisOn, onPressed: toggleMusic),
        ),
        title: Text(tr.welcome, style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          LanguageMenu(onChangeLocale: widget.onChangeLocale, colorButton: Colors.white),
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
            icon: const Icon(Icons.local_convenience_store_outlined, color: Colors.white),
          ),
          IconButton(
            onPressed: () {
              _clickButton.play("assets/audios/pop.mp3");
              Navigator.of(context).pushNamed('Setting');
            },
            icon: const Icon(Icons.settings, color: Colors.white),
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
            Tab(icon: const Icon(Icons.school), text: tr.courses),
            Tab(icon: const Icon(Icons.videogame_asset), text: tr.games),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xfff8fafc), Color(0xfffcefe6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: Column(
            children: [
              SlideTransition(
                position: _profileSlideAnimation,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepOrange.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
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
                          child: Tooltip(
                            message: "Edit Profile",
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Text(
                                avatarEmoji,
                                style: const TextStyle(fontSize: 36),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
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
                              fontWeight: FontWeight.w600,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => LoadingPage(
                                  loadingFuture: simulateLoading(),
                                  nextRouteName: "Shop"))),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Icon(Icons.star, color: Colors.amber),
                              const SizedBox(width: 3),
                              Text(
                                "$stars",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(Icons.generating_tokens_rounded, color: Colors.green),
                              const SizedBox(width: 3),
                              Text(
                                "${xpManager.saveTokens}",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.mode_edit_sharp, color: Colors.deepOrangeAccent),
                        onPressed: () {
                          _clickButton.play("assets/audios/pop.mp3");
                          Navigator.of(context)
                              .pushNamed('Profile')
                              .then((_) => _loadProfile());
                        },
                      ),
                    ],
                  ),
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
    );
  }
}
