import 'package:flutter/material.dart';
import 'package:mortaalim/loading_page.dart';
import 'package:mortaalim/profile_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'XpSystem.dart';
import 'indexPage_tools/Course_index_tool/course_index.dart';
import 'indexPage_tools/Game_index_tool/game_index.dart';
import 'indexPage_tools/language_menu.dart';
import 'indexPage_tools/music_button.dart';
import 'tools/audio_tool.dart';

class Index extends StatefulWidget {
  final void Function(Locale) onChangeLocale;
  const Index({super.key, required this.onChangeLocale});

  @override
  State<Index> createState() => _IndexState();
}

bool musicisOn = true;

class _IndexState extends State<Index> with TickerProviderStateMixin {
  final MusicPlayer _musicPlayer = MusicPlayer();
  late TabController _tabController;

  final List<String> tabMusicPaths = [
    "assets/audios/intro_music.mp3",
    "assets/audios/into.mp3",
  ];

  int _currentIndex = 0;
  String avatarEmoji = "🐱";
  String childName = "Player";

  // Animation controllers for profile card
  late final AnimationController _profileAnimController;
  late final Animation<Offset> _profileSlideAnimation;
  late final Animation<double> _profileFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Tab controller for tab navigation
    _tabController = TabController(length: tabMusicPaths.length, vsync: this);
    _tabController.addListener(_handleTabChange);

    _loadProfile();
    _musicPlayer.play(tabMusicPaths[0], loop: true);

    // Setup animation controller for profile card
    _profileAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Slide animation from left (-0.5 means half width to the left)
    _profileSlideAnimation = Tween<Offset>(
      begin: const Offset(-0.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _profileAnimController,
      curve: Curves.easeOut,
    ));

    // Fade animation from transparent to opaque
    _profileFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _profileAnimController, curve: Curves.easeIn),
    );

    // Start the animation
    _profileAnimController.forward();
  }

  void _handleTabChange() {
    if (_tabController.index != _currentIndex) {
      _currentIndex = _tabController.index;
      _musicPlayer.stop();
      if (musicisOn) {
        _musicPlayer.play(tabMusicPaths[_currentIndex], loop: true);
      }
    }
  }

  void toggleMusic() {
    setState(() => musicisOn = !musicisOn);
    musicisOn
        ? _musicPlayer.play(tabMusicPaths[_tabController.index], loop: true)
        : _musicPlayer.stop();
  }

  void _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      avatarEmoji = prefs.getString('avatar') ?? "🐱";
      childName = prefs.getString('name') ?? "Player";
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _musicPlayer.dispose();
    _tabController.dispose();
    _profileAnimController.dispose();
    super.dispose();
  }

  Future<void> simulateLoading() async {
    await Future.delayed(const Duration(seconds: 3));
  }

  // Helper to create fade transition route for smooth page change
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
            onPressed: () => Navigator.of(context).push(createFadeRoute(
              LoadingPage(
                loadingFuture: simulateLoading(),
                nextRouteName: 'Shop',
              ),
            )),
            icon: const Icon(Icons.local_convenience_store_outlined, color: Colors.white),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('Setting'),
            icon: const Icon(Icons.settings, color: Colors.white),
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          unselectedLabelStyle: TextStyle(fontSize: 13),
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          unselectedLabelColor: Colors.white30,
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
              // Animated Profile card: slides in from left and fades in
              SlideTransition(
                position: _profileSlideAnimation,
                child: FadeTransition(
                  opacity: _profileFadeAnimation,
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
                          child: Text(
                            childName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
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
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.deepOrangeAccent),
                          onPressed: () {
                            Navigator.of(context)
                                .pushNamed('Profile')
                                .then((_) => _loadProfile());
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Tab section for courses and games
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
