import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mortaalim/indexPage_tools/Course_index_tool/course_data.dart';
import 'package:mortaalim/indexPage_tools/Course_index_tool/course_grid.dart';
import 'package:mortaalim/tools/audio_tool.dart';

class CourseTab extends StatelessWidget {
  final MusicPlayer musicPlayer;
  const CourseTab({super.key, required this.musicPlayer});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr.chooseLevel, style: TextStyle(fontSize: 20, color: Colors.grey[700])),
        const SizedBox(height: 12),
        Expanded(
          child: CourseGrid(highCourses: highCourses, musicPlayer: musicPlayer),
        ),
      ],
    );
  }
}
