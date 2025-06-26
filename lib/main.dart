import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:mortaalim/courses/primaire1Page/1_primairePage.dart';
import 'package:mortaalim/tools/HomeCourse.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'IndexPage.dart';

void main() {
  runApp(MyApp());
}


class MyApp extends  StatelessWidget{
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
        home: Index());
  }
}



