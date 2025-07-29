import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mortaalim/PractiseGames/HeavyLight/HeavyLight.dart';
import 'package:mortaalim/PractiseGames/PlayTheWord/PlayTheWord.dart';
import 'package:mortaalim/games/BreakingWalls/main_Qoridor.dart';
import 'package:mortaalim/games/SugarSmash/SugraSmash.dart';
import 'package:mortaalim/tools/Ads_Manager.dart';

import 'package:mortaalim/Settings/setting_Page.dart';
import 'package:mortaalim/Shop/MainShopPageIndex.dart';
import 'package:mortaalim/games/App_stories/Story_Grid_Main_Page.dart';
import 'package:mortaalim/games/App_stories/favorite_Word/favorite_Page.dart';
import 'package:mortaalim/games/App_stories/story_data.dart';  // Import your story list here
import 'package:mortaalim/games/IQTest_game/Section_Selector.dart';
import 'package:mortaalim/games/IQTest_game/iqGame_data.dart';
import 'package:mortaalim/games/Piano_Game/Piano_main_page.dart';
import 'package:mortaalim/games/Quiz_Game/general_culture_game.dart';
import 'package:mortaalim/games/Shapes_game/Shapes_main.dart';
import 'package:mortaalim/games/SpeedBombGame/speedBomb.dart';
import 'package:mortaalim/games/Tracing_Alphabet_app/language_selector.dart';
import 'package:mortaalim/games/WordExplorer/WordExplorerPage.dart';
import 'package:mortaalim/games/WordLink/Word_Link_boardGame.dart';
import 'package:mortaalim/games/paitingGame/indexDrawingPage.dart';
import 'package:mortaalim/profileSetupPage.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/tools/splashScreen.dart';
import 'package:mortaalim/testing.dart';
import 'package:mortaalim/widgets/ComingSoon.dart';
import 'package:mortaalim/widgets/CreditsPage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../../l10n/app_localizations.dart';
import 'IndexPage.dart';
import 'XpSystem.dart';
import 'games/JumpingBoard/JumpingBoard.dart';

Locale _locale = const Locale('fr'); // default locale
late SharedPreferences prefs;
AppLocalizations tr(BuildContext context) => AppLocalizations.of(context)!;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 🔒 Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Hide Navigation Bar
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

  prefs = await SharedPreferences.getInstance();
  AdHelper.initializeAds();

  runApp(
    MultiProvider(providers:
[
    ChangeNotifierProvider(
      create: (_) => ExperienceManager()),
    ChangeNotifierProvider(create: (_) => AudioManager()),

],
        child:  MyApp(),));
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<void> _loadSavedLocale() async {
    final savedCode = prefs.getString('locale_code');
    if (savedCode != null) {
      setState(() {
        _locale = Locale(savedCode);
      });
    }
  }

  void _changeLanguage(Locale locale) async {
    await prefs.setString('locale_code', locale.languageCode);
    setState(() {
      _locale = locale;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadSavedLocale();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      theme: ThemeData(
        primaryColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.orangeAccent.shade100.withAlpha(80),
        ),
        cardColor: Colors.orangeAccent.withAlpha(230),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
        ),
      ),
      debugShowCheckedModeBanner: true,


      routes: {
        'Index': (context) => Index(onChangeLocale: _changeLanguage),

        //Game Routes
        'DrawingAlphabet': (context) => LanguageSelectorPage(onChangeLocale: _changeLanguage,),
        'QuizGameApp': (context) => const QuizGameApp(),
        'AppStories': (context) => StoriesGridPage(stories: stories), // Pass real story list here
        'ShapeSorter': (context) => const ShapeSorterApp(),
        'Piano' : (context) => const PianoModeSelector(),
        'PlaneDestroyer': (context) => const SpeedBomb(),
        'WordLink': (context) => const WordBoardGame(),
        'IQGame' : (context) => const IQTestApp(),
        "MagicPainting" : (context) =>  DrawingIndex(),
        "JumpingBoard": (context) => const JumpingBoard(),
        "WordExplorer" : (context) =>  WordExplorer(),
        'FavoriteWords': (context) => const FavoriteWordsPage(),
        "SugarSmash" : (context) => const Sugrasmash(),
        "BreakingWalls" : (context) => BreakingWalls(),
        'Profile': (context) => const ProfileSetupPage(),


        'Shop' : (context) => MainShopPageIndex(),
        'Credits' : (context) =>  CreditsPage(),



        'ComingSoon' : (context) => ComingSoonPage(),
        'Setting' : (context) => SettingsPage(onChangeLocale: _changeLanguage),
        'Splash' : (context) => SplashPage(onChangeLocale: _changeLanguage),
        "Testing" : (context) => TestApp(),
      },

      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale("fr"),
        Locale("ar"),
        Locale("en"),
        Locale("it"),
      ],
      locale: _locale,
     initialRoute: 'Splash',
    );
  }
}
