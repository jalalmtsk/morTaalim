import 'package:flutter/material.dart';
import 'package:mortaalim/games/Math1/ar_games.dart';
import 'package:mortaalim/games/Math1/m1_home.dart';

/// اللغة العربية — السنة الأولى ابتدائي.
/// حديقة الحروف · أسمع وأكتشف · قطار الحركات · كلمتي وصورتي · جملتي الأولى
class IndexArabic1Practise extends StatelessWidget {
  const IndexArabic1Practise({super.key});

  @override
  Widget build(BuildContext context) => const M1Home(world: arWorld);
}
