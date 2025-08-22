import 'package:flutter/material.dart';
import 'package:mortaalim/widgets/RandomAyat_Card/RandomAyaCard.dart';
import 'package:provider/provider.dart';

import 'package:mortaalim/indexPage_tools/Course_index_tool/course_data.dart';
import 'package:mortaalim/indexPage_tools/Course_index_tool/course_grid.dart';

import '../../tools/ConnectivityManager/Connectivity_Manager.dart';

class CourseTab extends StatefulWidget {
  const CourseTab({super.key});
  @override
  State<CourseTab> createState() => _CourseTabState();
}

class _CourseTabState extends State<CourseTab> {
  late ConnectivityService _connectivityService; // store reference

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _connectivityService = Provider.of<ConnectivityService>(context, listen: false);
    _connectivityService.resumeMonitoring();
  }
  @override
  void dispose() {
    _connectivityService.pauseMonitoring(); // safe: no context lookup
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = Provider.of<ConnectivityService>(context); // UI can still listen
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: ExpandableAyatCard ()),
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
