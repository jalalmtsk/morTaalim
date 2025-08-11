import 'package:flutter/material.dart';

final List<Map<String, dynamic>> ITCourses = [
  {
    'title': 'Basic Computer Skills',
    'icon': Icons.brush,
    'routeName': 'ComingSoon',
    'image': 'assets/images/GameGridImages/TrailingLetters.png', // ✅ New key
    'locked': false,
    'cost': 0,
    'unlockType': 'creative',
  },
  {
    'title': 'Intro to Coding with Blocks',
    'icon': Icons.quiz,
    'routeName': 'ComingSoon',
    'image': 'assets/images/GameGridImages/QuizzMe.png', // ✅ New key
    'locked': false,
    'cost': 0,
    'unlockType': 'logic',
  },
  {
    'title': 'Scratch Programming',
    'icon': Icons.menu_book,
    'routeName': 'ComingSoon',
    'image': 'assets/images/GameGridImages/StoriesGame.png', // ✅ New key
    'locked': true,
    'cost': 100,
    'unlockType': 'reading',
  },

  {
    'title': 'Cyber Safety for Kids',
    'icon': Icons.format_paint,
    'routeName': 'ComingSoon',
    'image': 'assets/images/GameGridImages/Painting.png', // ✅ New key
    'locked': true,
    'cost': 120,
    'unlockType': 'iq',
  },

];
