import 'package:flutter/material.dart';
import 'package:mortaalim/games/Math1/m1_home.dart';
import 'package:mortaalim/games/Math1/sc_games.dart';

/// Sciences — 1re année primaire.
/// Opens the science world: the five senses, the growing seed, who lives
/// where, Waki's weather and the materials lab.
/// (The previous exercise grid is kept in "Claude outputs/Science1_OLD".)
class IndexScience1Practise extends StatelessWidget {
  const IndexScience1Practise({super.key});

  @override
  Widget build(BuildContext context) => const M1Home(world: scWorld);
}
