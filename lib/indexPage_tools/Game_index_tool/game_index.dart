import 'package:flutter/material.dart';

import 'game_data.dart';
import 'game_grid.dart';

class GamesTab extends StatelessWidget {

  const GamesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return GameGrid(games: games);
  }
}