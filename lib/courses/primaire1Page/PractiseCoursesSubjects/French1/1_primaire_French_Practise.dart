import 'package:flutter/material.dart';
import 'package:mortaalim/games/Math1/fr_games.dart';
import 'package:mortaalim/games/Math1/m1_home.dart';

/// Français — 1re année primaire.
/// La forêt des lettres · Le détective des sons · Le train des syllabes · Les mots en images · Ma première phrase
class IndexFrench1Practise extends StatelessWidget {
  const IndexFrench1Practise({super.key});

  @override
  Widget build(BuildContext context) => const M1Home(world: frWorld);
}
