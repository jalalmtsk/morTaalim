import 'package:flutter/material.dart';
import 'package:mortaalim/tools/audio_tool.dart';

import 'game_data.dart';
import 'game_grid.dart';

class GamesTab extends StatelessWidget {
  final MusicPlayer musicPlayer;

  const GamesTab({super.key, required this.musicPlayer});

  @override
  Widget build(BuildContext context) {
    return GameGrid(games: games, musicPlayer: musicPlayer);
  }
}