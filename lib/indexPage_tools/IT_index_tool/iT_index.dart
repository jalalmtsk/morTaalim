import 'package:flutter/material.dart';
import 'package:mortaalim/tools/audio_tool/audio_tool.dart';

import 'iT_data.dart';
import 'iT_grid.dart';


class ITTabs extends StatelessWidget {
  final MusicPlayer musicPlayer;

  const ITTabs({super.key, required this.musicPlayer});

  @override
  Widget build(BuildContext context) {
    return ITGrid(ITCourses: ITCourses, musicPlayer: musicPlayer);
  }
}