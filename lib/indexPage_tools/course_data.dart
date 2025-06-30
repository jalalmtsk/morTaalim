import 'package:flutter/material.dart';
import 'package:mortaalim/courses/primaire1Page/index_1PrimairePage.dart';
import 'package:mortaalim/courses/primaire2Page/index_2PrimairePage.dart';
import 'package:mortaalim/courses/primaire3Page/3_primaire.dart';
import 'package:mortaalim/courses/primaire4Page/4_primaire.dart';
import 'package:mortaalim/courses/primaire5Page/5_primaire.dart';
import 'package:mortaalim/courses/primaire6Page/6_primaire.dart';

final List<Map<String, dynamic>> highCourses = [
  {
    'titleKey': 'class1',
    'widget': index1Primaire(),
    'icon': Icons.looks_one,
    'color': Colors.orangeAccent,
  },
  {
    'titleKey': 'class2',
    'widget': index2Primaire(),
    'icon': Icons.looks_two,
    'color': Colors.teal,
  },
  {
    'titleKey': 'class3',
    'widget': primaire3(),
    'icon': Icons.looks_3,
    'color': Colors.pinkAccent,
  },
  {
    'titleKey': 'class4',
    'widget': primaire4(),
    'icon': Icons.looks_4,
    'color': Colors.cyan,
  },
  {
    'titleKey': 'class5',
    'widget': primaire5(),
    'icon': Icons.looks_5,
    'color': Colors.indigo,
  },
  {
    'titleKey': 'class6',
    'widget': primaire6(),
    'icon': Icons.looks_6,
    'color': Colors.deepPurple,
  },
];
