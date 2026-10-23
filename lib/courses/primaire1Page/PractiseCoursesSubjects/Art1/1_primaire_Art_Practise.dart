import 'package:flutter/material.dart';
import 'package:mortaalim/games/Math1/art_games.dart';
import 'package:mortaalim/games/Math1/m1_home.dart';

/// Éducation artistique — 1re année primaire.
/// Le jardin des couleurs · Les chemins du dessin · Ma maison de papier · Les motifs enchantés · La ronde des rythmes
class IndexArt1Practise extends StatelessWidget {
  const IndexArt1Practise({super.key});

  @override
  Widget build(BuildContext context) => const M1Home(world: artWorld);
}
