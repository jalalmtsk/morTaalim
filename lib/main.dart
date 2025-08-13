import 'package:cloud_firestore/cloud_firestore.dart' hide Index;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mortaalim/Authentification/Auth.dart';
import 'package:mortaalim/Authentification/BackUp/BackUpPage.dart';
import 'package:mortaalim/Manager/Services/YoutubeProgressManager.dart';
import 'package:mortaalim/Pet/pet_home_page.dart';
import 'package:mortaalim/PractiseGames/MemoryFlipGame/LevelSeletor.dart';
import 'package:mortaalim/PractiseGames/MemoryFlipGame/MemoryFlip.dart';
import 'package:mortaalim/tools/SavingPreferencesTool_Helper/Preferences_Helper.dart';
import 'package:mortaalim/widgets/ProfileSetup_Widget/UserDataProfileEntering.dart';
import 'package:mortaalim/User_Input_Info_DataForm/User_Info_FirstCon/UserInfoForm_Introduction.dart';
import 'package:mortaalim/courses/primaire1Page/index_1PrimairePage.dart';
import 'package:mortaalim/firebase_options.dart';
import 'package:mortaalim/games/BreakingWalls/main_Qoridor.dart';
import 'package:mortaalim/games/PuzzzleGame/Puzzle_Game.dart';
import 'package:mortaalim/games/SugarSmash/SugraSmash.dart';
import 'package:mortaalim/indexPage_tools/Dashboard_Index_tool/Home_Page.dart';
import 'package:mortaalim/tasbiheTest.dart';
import 'package:mortaalim/tools/Ads_Manager.dart';

import 'package:mortaalim/Settings/setting_Page.dart';
import 'package:mortaalim/Shop/MainShopPageIndex.dart';
import 'package:mortaalim/games/App_stories/Story_Grid_Main_Page.dart';
import 'package:mortaalim/games/App_stories/favorite_Word/favorite_Page.dart';
import 'package:mortaalim/games/App_stories/story_data.dart';  // Import your story list here
import 'package:mortaalim/games/IQTest_game/iqGame_data.dart';
import 'package:mortaalim/games/Piano_Game/Piano_main_page.dart';
import 'package:mortaalim/games/Quiz_Game/quiz_Page.dart';
import 'package:mortaalim/games/Shapes_game/Shapes_main.dart';
import 'package:mortaalim/games/SpeedBombGame/speedBomb.dart';
import 'package:mortaalim/games/Tracing_Alphabet_app/language_selector.dart';
import 'package:mortaalim/games/WordExplorer/WordExplorerPage.dart';
import 'package:mortaalim/games/WordLink/Word_Link_boardGame.dart';
import 'package:mortaalim/games/paitingGame/indexDrawingPage.dart';
import 'package:mortaalim/widgets/ProfileSetup_Widget/profileSetupPage.dart';
import 'package:mortaalim/tools/ConnectivityManager/Connectivity_Manager.dart';
import 'package:mortaalim/tools/LifeCycleManager.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/tools/audio_tool/MusicRouteObserver.dart';
import 'package:mortaalim/tools/SplashPage/splashScreen.dart';
import 'package:mortaalim/widgets/AIChatbot/ChatBotScreen.dart';
import 'package:mortaalim/widgets/ComingSoon.dart';
import 'package:mortaalim/widgets/CreditsPage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../../l10n/app_localizations.dart';

import 'IndexPage.dart';
import 'XpSystem.dart';
import 'games/JumpingBoard/JumpingBoard.dart';


final String appVersion = "1.0.0 (Build 1)";

late SharedPreferences prefs;
AppLocalizations tr(BuildContext context) => AppLocalizations.of(context)!;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final MusicRouteObserver routeObserver = MusicRouteObserver();

// Create ONE AudioManager instance here, globally:
final AudioManager  audioManager = AudioManager();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  // Firebase Initialisation
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  // Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Hide Navigation Bar
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

  prefs = await SharedPreferences.getInstance();
  AdHelper.initializeAds();

  final xpManager = ExperienceManager();
  await xpManager.loadData();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: xpManager),
        ChangeNotifierProvider.value(value: audioManager),
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
        ChangeNotifierProvider(create: (_) => CardVisibilityManager(),
        )
      ],
        child: AppLifecycleManager( child: MyApp(),
        )
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {



  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final experienceManager = Provider.of<ExperienceManager>(context, listen: false);
    return Consumer<ExperienceManager>(
      builder: (context, xpManager, child) {
        final currentLocale = Locale(xpManager.userProfile.preferredLanguage);

        return MaterialApp(
          navigatorKey: navigatorKey,
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
          navigatorObservers: [routeObserver],
          routes: {
            'Index': (context) => Index(),
            'DrawingAlphabet': (context) => LanguageSelectorPage(onChangeLocale: _changeLanguage),
            'QuizGameApp': (context) => const QuizGameApp(),
            'AppStories': (context) => StoriesGridPage(stories: stories),
            'ShapeSorter': (context) => const ShapeSorterApp(),
            'Piano': (context) => const PianoModeSelector(),
            'PlaneDestroyer': (context) => const SpeedBomb(),
            'WordLink': (context) => const WordBoardGame(),
            'IQGame': (context) => const IQTestApp(),
            "MagicPainting": (context) => DrawingIndex(),
            "JumpingBoard": (context) => const JumpingBoard(),
            "WordExplorer": (context) => WordExplorer(),
            'FavoriteWords': (context) => const FavoriteWordsPage(),
            "SugarSmash": (context) => const Sugrasmash(),
            "BreakingWalls": (context) => BreakingWalls(),
            'index1Primaire': (context) => Index1Primaire(),
            'Profile': (context) => const ProfileSetupPage(),

            'Shop': (context) => PetHomePage(),
            'Credits': (context) => CreditsPage(),
            'ComingSoon': (context) => ComingSoonPage(),
            'Setting': (context) => SettingsPage(onChangeLocale: _changeLanguage),
            'Splash': (context) => SplashPage(),
            "Auth": (context) => AuthGate(),
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
            Locale("de"),
          ],
          locale: currentLocale,
          initialRoute: 'Auth',
        );
      },
    );
  }

  void _changeLanguage(Locale locale) {
    Provider.of<ExperienceManager>(navigatorKey.currentContext!, listen: false)
        .setPreferredLanguage(locale.languageCode);
  }

}

