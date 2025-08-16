import 'package:flutter/material.dart';
import 'package:mortaalim/tools/audio_tool/audio_tool.dart';

import 'iT_data.dart';
import 'iT_grid.dart';


class ITTabs extends StatelessWidget {

  const ITTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return ITGrid(ITCourses: ITCourses);
  }
}