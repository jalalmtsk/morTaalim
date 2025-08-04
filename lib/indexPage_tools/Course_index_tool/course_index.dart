import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import 'package:mortaalim/indexPage_tools/Course_index_tool/course_data.dart';
import 'package:mortaalim/indexPage_tools/Course_index_tool/course_grid.dart';
import 'package:mortaalim/tools/audio_tool/audio_tool.dart';

import '../../tools/ConnectivityManager/Connectivity_Manager.dart';
import '../../tools/ConnectivityManager/ConexionWidget.dart';

class CourseTab extends StatefulWidget {
  const CourseTab({super.key});

  @override
  State<CourseTab> createState() => _CourseTabState();
}

class _CourseTabState extends State<CourseTab> {

  @override
  void dispose() {
    Provider.of<ConnectivityService>(context, listen: false).pauseMonitoring();
    super.dispose();
  }

// And when widget is back in view
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Provider.of<ConnectivityService>(context, listen: false).resumeMonitoring();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final connectivity = Provider.of<ConnectivityService>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row( mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(tr.chooseLevel, style: TextStyle(fontSize: 20, color: Colors.grey[700])),
            const ConnectivityIndicator(), // Use the separate widget here
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: CourseGrid(highCourses: highCourses),
        ),
      ],
    );
  }
}
