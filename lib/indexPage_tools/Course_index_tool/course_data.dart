import 'package:flutter/material.dart';
import 'package:mortaalim/courses/primaire1Page/index_1PrimairePage.dart';
import 'package:mortaalim/courses/primaire2Page/index_2PrimairePage.dart';
import 'package:mortaalim/widgets/ComingSoon.dart';

final List<Map<String, dynamic>> highCourses = [
  {
    'titleKey': 'class1',
    'widget': Index1Primaire(),
    'icon': Icons.looks_one,
    'color': Colors.orangeAccent,
  },
  {
    'titleKey': 'class2',
    'widget': Index2Primaire(),
    'icon': Icons.looks_two,
    'color': Colors.teal,
  },
  {
    'titleKey': 'class3',
    'widget': ComingSoonPage(),
    'icon': Icons.looks_3,
    'color': Colors.pinkAccent,
  },
  {
    'titleKey': 'class4',
    'widget': ComingSoonPage(),
    'icon': Icons.looks_4,
    'color': Colors.cyan,
  },
  {
    'titleKey': 'class5',
    'widget': ComingSoonPage(),
    'icon': Icons.looks_5,
    'color': Colors.indigo,
  },
  {
    'titleKey': 'class6',
    'widget': ComingSoonPage(),
    'icon': Icons.looks_6,
    'color': Colors.deepPurple,
  },
];
