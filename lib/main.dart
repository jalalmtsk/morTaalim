import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'IndexPage.dart';
import 'package:mortaalim/IndexPage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Locale _locale = const Locale('fr'); // default
late SharedPreferences prefs;
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.getInstance();
  runApp(MyApp());
}


class MyApp extends  StatefulWidget{

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    String? code = prefs.getString('locale_code');
    if (code != null) {
      setState(() {
        _locale = Locale(code);
      });
    }
  }

  void _changeLanguage(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale_code', locale.languageCode);
    setState(() {
      _locale = locale;
    });
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadSavedLocale();
  }

  @override
  Widget build(BuildContext context){
    return MaterialApp(
        theme: ThemeData(
          primaryColor: Colors.white,
          appBarTheme: AppBarTheme(backgroundColor: Colors.orangeAccent.shade100.withValues(alpha: 0.3),),
          cardColor: Colors.orangeAccent.withValues(alpha: 0.9),
          textTheme: TextTheme(
              titleLarge: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
              titleMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              titleSmall: TextStyle()
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent)
          ),
        ),

        debugShowCheckedModeBanner: true,
        initialRoute: 'Index',
        routes: {
          //'Index' : (context) => Index(),

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
          Locale("it")
        ],
        locale: _locale,
        home: Index(onChangeLocale: _changeLanguage,));
  }
}



