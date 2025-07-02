import 'package:flutter/material.dart';
import 'package:mortaalim/profile_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'XpSystem.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'indexPage_tools/Course_index_tool/course_index.dart';
import 'indexPage_tools/Game_index_tool/game_index.dart';
import 'indexPage_tools/language_menu.dart';
import 'indexPage_tools/music_button.dart';
import 'package:mortaalim/tools/audio_tool.dart';

class Index extends StatefulWidget {
  final void Function(Locale) onChangeLocale;
  const Index({super.key, required this.onChangeLocale});

  @override
  State<Index> createState() => _IndexState();
}

bool musicisOn = true;

class _IndexState extends State<Index> with SingleTickerProviderStateMixin {
  final MusicPlayer _musicPlayer = MusicPlayer();
  late TabController _tabController;

  final List<String> tabMusicPaths = [
    "assets/audios/intro_music.mp3",
    "assets/audios/into.mp3",
  ];

  int _currentIndex = 0;
  String avatarEmoji = "🐱";
  String childName = "Player";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabMusicPaths.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadProfile();
    _musicPlayer.play(tabMusicPaths[0], loop: true);
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

  void toggleMusic() async {
    setState(() {
      musicisOn = !musicisOn;
    });
    if (musicisOn) {
      _musicPlayer.play(tabMusicPaths[_tabController.index], loop: true);
    } else {
      _musicPlayer.stop();
    }
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    final xpManager = Provider.of<ExperienceManager>(context);
    final xp = xpManager.xp;
    final level = xpManager.level;
    final stars = xpManager.stars;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepOrangeAccent.withAlpha(200),
        leading: MusicButton(isOn: musicisOn, onPressed: toggleMusic),
        actions: [

          LanguageMenu(onChangeLocale: widget.onChangeLocale),
          IconButton(onPressed: (){}, icon: Icon(Icons.settings, color: Colors.white,)),
          IconButton(onPressed: (){Navigator.pushNamed(context, "Shop");}, icon: Icon(Icons.shop, color: Colors.white,)),
          IconButton(onPressed: (){Navigator.pushNamed(context, "Credits");}, icon: Icon(Icons.info_outline, color: Colors.white,))

        ],

        title: Text(tr.welcome, style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
             Tab(icon: const Icon(Icons.school), text: tr.courses),
            Tab(icon: Icon(Icons.videogame_asset), text: tr.games),
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
              // 👤 Profile section
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepOrange.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                            MaterialPageRoute(builder: (_)
                            => ProfilePage(initialName: childName, initialAvatar: avatarEmoji, initialAge: 13, initialColor: Colors.red, initialMood: "Happy")
                            )).then((_) => _loadProfile());
                      },
                      child: Text(avatarEmoji, style: const TextStyle(fontSize: 36)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        childName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "⭐ $stars",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ),

                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.deepOrange),
                      onPressed: () {
                        Navigator.pushNamed(context, 'Profile').then((_) => _loadProfile());
                      },
                    ),
                  ],
                ),

              ),

              // 🧠 TabBarView section
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
