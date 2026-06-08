import 'package:cloud_firestore/cloud_firestore.dart' hide Index;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mortaalim/Authentification/Auth.dart';
import 'package:mortaalim/Manager/models/LearningPrefrences.dart';

import 'package:mortaalim/games/AnimalSound/AnimalSound_Index.dart';
import 'package:mortaalim/games/MemoryFlipGame/MemoryFlip_index.dart';
import 'package:mortaalim/games/PianoTiles_game/piano_tiles.dart';
import 'package:mortaalim/screens/main_home_screen/Settings/setting_Page.dart';
import 'package:mortaalim/screens/main_home_screen/indexPage_tools/IT_index_tool/IT_exercices/computerPart.dart';
import 'package:mortaalim/screens/main_home_screen/indexPage_tools/IT_index_tool/IT_exercices/it_input_output.dart';
import 'package:mortaalim/screens/main_home_screen/indexPage_tools/IT_index_tool/IT_exercices/it_binary_numbers.dart';
import 'package:mortaalim/screens/main_home_screen/indexPage_tools/IT_index_tool/IT_exercices/mousePractise.dart';
import 'package:mortaalim/screens/main_home_screen/indexPage_tools/IT_index_tool/IT_exercices/whatComputer.dart';
import 'package:mortaalim/screens/main_shop_screen/MainShopPageIndex.dart';
import 'package:mortaalim/tools/appConfig/BanChecker/BannerChecker.dart';
import 'package:mortaalim/tools/appConfig/UpdateChecker/update_Checker.dart';
import 'package:mortaalim/widgets/ComingSoonNotPage.dart';
import 'package:mortaalim/widgets/ProfileSetup_Widget/BannerAndAvatarProfilePage/BannerAvatarProfile.dart';

import 'package:mortaalim/courses/primaire1Page/index_1PrimairePage.dart';
import 'package:mortaalim/firebase_options.dart';
import 'package:mortaalim/games/BreakingWalls/main_Qoridor.dart';
import 'package:mortaalim/games/SugarSmash/SugraSmash.dart';

import 'package:mortaalim/tools/Ads_Manager.dart';

import 'package:mortaalim/games/App_stories/Story_Grid_Main_Page.dart';
import 'package:mortaalim/games/App_stories/favorite_Word/favorite_Page.dart';
import 'package:mortaalim/games/App_stories/story_data.dart';
import 'package:mortaalim/games/IQTest_game/iqGame_data.dart';
import 'package:mortaalim/games/Piano_Game/Piano_main_page.dart';

import 'package:mortaalim/games/Quiz_Game/quiz_Page.dart';
import 'package:mortaalim/games/Shapes_game/Shapes_main.dart';
import 'package:mortaalim/games/SpeedBombGame/speedBomb.dart';
import 'package:mortaalim/games/Tracing_Alphabet_app/language_selector.dart';
import 'package:mortaalim/games/WordExplorer/WordExplorerPage.dart';
import 'package:mortaalim/games/WordLink/Word_Link_boardGame.dart';
import 'package:mortaalim/games/paitingGame/indexDrawingPage.dart';
import 'package:mortaalim/tools/ConnectivityManager/Connectivity_Manager.dart';
import 'package:mortaalim/tools/LifeCycleManager.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/tools/audio_tool/MusicRouteObserver.dart';
import 'package:mortaalim/widgets/AIChatbot/ChatBotScreen.dart';
import 'package:mortaalim/widgets/ComingSoon.dart';
import 'package:mortaalim/widgets/CreditPage/CreditsPage.dart';
import 'package:mortaalim/widgets/SplashPage/splashScreen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../l10n/app_localizations.dart';

import 'IndexPage.dart';
import 'Manager/Services/CardVisibiltyManager.dart';
import 'Themes/AppTheme.dart';
import 'Themes/ThemeManager.dart';
import 'XpSystem.dart';
import 'games/JumpingBoard/JumpingBoard.dart';
import 'l10n/amazigh_localizations.dart';

final String appVersion = "1.0.0 (Build 1)";

late SharedPreferences prefs;
AppLocalizations tr(BuildContext context) => AppLocalizations.of(context)!;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final MusicRouteObserver routeObserver = MusicRouteObserver();
final AudioManager audioManager = AudioManager();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore.instance.settings =
  const Settings(persistenceEnabled: true);

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
        ChangeNotifierProvider(create: (_) => CardVisibilityManager()),
        ChangeNotifierProvider(create: (_) => LearningPreferences()),
        ChangeNotifierProvider(create: (_) => ThemeManager(themes: appThemes)),
      ],
      child: AppLifecycleManager(child: MyApp()),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid != null) {
        final bool isBanned = await BannerChecker().checkAndShowBanner(
          navigatorKey.currentContext!,
          uid,
        );
        if (!isBanned) {
          await UpdateChecker().checkForUpdate(navigatorKey.currentContext!);
        }
      } else {
        await UpdateChecker().checkForUpdate(navigatorKey.currentContext!);
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════
  //  Fredoka TextTheme helper
  //  Maps every standard Flutter text role to Fredoka with the
  //  appropriate weight so the entire widget tree inherits it.
  // ═══════════════════════════════════════════════════════════════
  static TextTheme _fredokaTextTheme() {
    // weight guide:
    //   displayLarge/Medium/Small  → Bold    (700) — big splash numbers
    //   headlineLarge/Medium/Small → SemiBold(600) — section titles
    //   titleLarge/Medium/Small    → Medium  (500) — card/dialog titles
    //   bodyLarge/Medium/Small     → Regular (400) — body copy
    //   labelLarge/Medium/Small    → Medium  (500) — buttons, chips
    return const TextTheme(
      // Display
      displayLarge:  TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w700),
      displayMedium: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w700),
      displaySmall:  TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w700),
      // Headline
      headlineLarge:  TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600),
      headlineMedium: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600),
      headlineSmall:  TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600),
      // Title
      titleLarge:  TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w500, fontSize: 35),
      titleMedium: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w500, fontSize: 30),
      titleSmall:  TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w500),
      // Body
      bodyLarge:  TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w400),
      bodySmall:  TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w400),
      // Label (buttons, chips, tabs)
      labelLarge:  TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w500),
      labelMedium: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w500),
      labelSmall:  TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w400),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ExperienceManager, ThemeManager>(
      builder: (context, xpManager, themeManager, child) {
        final currentLocale = Locale(xpManager.userProfile.preferredLanguage);
        final appTheme = themeManager.currentTheme;

        return MaterialApp(
          navigatorKey: navigatorKey,
          theme: ThemeData(
            // ── Global Fredoka font ────────────────────────────
            fontFamily: 'Fredoka',
            textTheme: _fredokaTextTheme(),
            // ── Colours driven by ThemeManager ────────────────
            primaryColor: appTheme.primaryColor,
            scaffoldBackgroundColor: appTheme.backgroundColor,
            colorScheme: ColorScheme.fromSeed(
              seedColor: appTheme.primaryColor,
              primary: appTheme.primaryColor,
              secondary: appTheme.accentColor,
              background: appTheme.backgroundColor,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: appTheme.primaryColor.withOpacity(0.85),
              titleTextStyle: TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: appTheme.textColor,
              ),
            ),
            cardColor: appTheme.accentColor.withAlpha(230),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: appTheme.buttonStyle,
            ),
            tabBarTheme: const TabBarThemeData(
              labelStyle: TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w400,
                fontSize: 13,
              ),
            ),
            inputDecorationTheme: const InputDecorationTheme(
              hintStyle: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w400),
              labelStyle: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w500),
            ),
            snackBarTheme: const SnackBarThemeData(
              contentTextStyle: TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
          debugShowCheckedModeBanner: false,
          navigatorObservers: [routeObserver],
          routes: {
            'Index': (context) => Index(),

            // ── existing games ─────────────────────────────────────────
            'DrawingAlphabet': (context) => LanguageSelectorPage(onChangeLocale: _changeLanguage),
            'QuizGameApp':     (context) => const QuizGameApp(),
            'AppStories':      (context) => StoriesGridPage(stories: stories),
            'AnimalSounds':    (context) => AnimalsoundIndex(),
            'ShapeSorter':     (context) => const ShapeSorterApp(),
            'Piano':           (context) => const PianoTilesBoard(),
            'PlaneDestroyer':  (context) => const SpeedBomb(),
            'WordLink':        (context) => const WordBoardGame(),
            'IQGame':          (context) => const IQTestApp(),
            'MagicPainting':   (context) => DrawingIndex(),
            'JumpingBoard':    (context) => const JumpingBoard(),
            'WordExplorer':    (context) => WordExplorer(),
            'FavoriteWords':   (context) => const FavoriteWordsPage(),
            'SugarSmash':      (context) => const Sugrasmash(),
            'BreakingWalls':   (context) => BreakingWalls(),
            'MemoryFlip':      (context) => MFIndexPage(),

            // ── IT courses — Tier 1 (Grade 1–2, free) ─────────────────
            'IT_WhatIsComputer': (context) => WhatIsComputerExercise(),
            'IT_ComputerParts':  (context) => const ComputerPartsExercise(),
            'IT_MousePractice':  (context) => const MousePracticeExercise(),
            'IT_InputOutput':    (context) => const IT_InputOutput(),

            // ── IT courses — Tier 2 (Grade 2–3) ───────────────────────
           // 'IT_InternetBasics': (context) => const IT_InternetBasics(),
           // 'IT_OnlineSafety':   (context) => const IT_OnlineSafety(),
           // 'IT_FileFolders':    (context) => const IT_FileFolders(),
           // 'IT_TypingFingers':  (context) => const IT_TypingFingers(),

            // ── IT courses — Tier 3 (Grade 3–4) ───────────────────────
          /*
            'IT_Algorithm':      (context) => const IT_Algorithm(),
            'IT_LoopsConditions':(context) => const IT_LoopsConditions(),
            'IT_PasswordSafety': (context) => const IT_PasswordSafety(),
            'IT_FileTypes':      (context) => const IT_FileTypes(),


           */
            // ── IT courses — Tier 4 (Grade 4–5) ───────────────────────
            'IT_BinaryNumbers':  (context) => const IT_BinaryNumbers(),
/*
            'IT_HowInternet':    (context) => const IT_HowInternet(),
            'IT_ScratchCoding':  (context) => const IT_ScratchCoding(),
            'IT_CyberThreats':   (context) => const IT_CyberThreats(),

            // ── IT courses — Tier 5 (Grade 5–6) ───────────────────────
            'IT_IntroPython':    (context) => const IT_IntroPython(),
            'IT_Databases':      (context) => const IT_Databases(),
            'IT_HtmlBasics':     (context) => const IT_HtmlBasics(),
            'IT_AiRobots':       (context) => const IT_AiRobots(),

 */
            // ── app screens ────────────────────────────────────────────
            'index1Primaire':    (context) => Index1Primaire(),
            'Profile':           (context) => const BannerAvatarProfile(),
            'Shop':              (context) => MainShopPageIndex(),
            'Credits':           (context) => CreditsPage(),
            'ComingSoon':        (context) => ComingSoonPage(),
            'ComingSoonNotPage': (context) => ComingSoonNotPage(),
            'Setting':           (context) => SettingsPage(onChangeLocale: _changeLanguage),
            'Splash':            (context) => SplashPage(),
            'Auth':              (context) => AuthGate(),
          },
          localizationsDelegates: [
            AppLocalizations.delegate,
            AmazighMaterialLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            DefaultMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          localeResolutionCallback: (locale, supportedLocales) {
            if (locale == null) return const Locale('en');
            for (var supported in supportedLocales) {
              if (supported.languageCode == locale.languageCode &&
                  supported.countryCode == locale.countryCode) {
                return supported;
              }
            }
            if (locale.languageCode == 'zgh') return const Locale('en');
            return supportedLocales.first;
          },
          supportedLocales: const [
            Locale("fr"),
            Locale("ar"),
            Locale("en"),
            Locale("de"),
            Locale("zgh"),
            Locale('ber'),
          ],
          locale: currentLocale,
          showPerformanceOverlay: false,
          showSemanticsDebugger: false,
          initialRoute: 'Auth',
        );
      },
    );
  }

  void _changeLanguage(Locale locale) {
    Provider.of<ExperienceManager>(
      navigatorKey.currentContext!,
      listen: false,
    ).setPreferredLanguage(locale.languageCode);
  }
}

class LocalizationOverrideWidget extends StatelessWidget {
  final Widget child;
  const LocalizationOverrideWidget({required this.child});

  @override
  Widget build(BuildContext context) {
    return Localizations(
      locale: Localizations.localeOf(context),
      delegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      child: child,
    );
  }
}

class MyAppStateHelper {
  static void changeLanguage(BuildContext context, Locale locale) {
    final state = context.findAncestorStateOfType<_MyAppState>();
    state?._changeLanguage(locale);
  }
}