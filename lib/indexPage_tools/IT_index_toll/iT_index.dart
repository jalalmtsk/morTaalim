import 'package:flutter/material.dart';
import 'package:mortaalim/indexPage_tools/IT_index_toll/iT_data.dart';
import 'package:mortaalim/indexPage_tools/IT_index_toll/iT_grid.dart';
import 'package:mortaalim/tools/audio_tool/audio_tool.dart';


class ITTabs extends StatelessWidget {
  final MusicPlayer musicPlayer;

  const ITTabs({super.key, required this.musicPlayer});

  @override
  Widget build(BuildContext context) {
    return ITGrid(ITCourses: ITCourses, musicPlayer: musicPlayer);
  }
}