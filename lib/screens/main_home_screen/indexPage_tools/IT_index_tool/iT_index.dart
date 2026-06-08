import 'package:flutter/material.dart';
import 'iT_data.dart';
import 'iT_grid.dart';

class ITTabs extends StatelessWidget {
  const ITTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return ITGrid(ITCourses: itCourses);
  }
}