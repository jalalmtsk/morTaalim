import 'package:flutter/material.dart';
import 'package:mortaalim/games/App_stories/Story_Grid_Main_Page.dart';
import 'package:mortaalim/games/App_stories/favorite_Word/favorite_Page.dart';
import 'package:mortaalim/games/App_stories/story_data.dart';  // Import your story list here
import 'package:mortaalim/games/Quiz_Game/general_culture_game.dart';
import 'package:mortaalim/games/Shapes_game/Shapes_main.dart';
import 'package:mortaalim/games/Tracing_Alphabet_app/language_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'IndexPage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Locale _locale = const Locale('fr'); // default locale
late SharedPreferences prefs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  prefs = await SharedPreferences.getInstance();
  runApp(MyApp());
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
        'DrawingAlphabet': (context) => LanguageSelectorPage(),
        'QuizGameApp': (context) => const QuizGameApp(),
        'AppStories': (context) => StoriesGridPage(stories: stories), // Pass real story list here
        'FavoriteWords': (context) => const FavoriteWordsPage(),
        'SpotTheDifference': (context) => const ShapeSorterApp()

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
      home: Index(onChangeLocale: _changeLanguage),
    );
  }
}
