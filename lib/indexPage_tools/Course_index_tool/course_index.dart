import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:mortaalim/indexPage_tools/Course_index_tool/course_data.dart';
import 'package:mortaalim/indexPage_tools/Course_index_tool/course_grid.dart';
import 'package:mortaalim/tools/audio_tool/audio_tool.dart';

class CourseTab extends StatelessWidget {
  const CourseTab({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr.chooseLevel, style: TextStyle(fontSize: 20, color: Colors.grey[700])),
        const SizedBox(height: 12),
        Expanded(
          child: CourseGrid(highCourses: highCourses),
        ),
      ],
    );
  }
}
