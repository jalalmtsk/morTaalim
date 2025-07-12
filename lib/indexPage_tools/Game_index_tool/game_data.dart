import 'package:flutter/material.dart';

final List<Map<String, dynamic>> games = [
  {
    'title': 'drawingAlphabet',
    'icon': Icons.brush,
    'routeName': 'DrawingAlphabet',
    'image': 'assets/images/GameGridImages/TrailingLetters.png', // ✅ New key
    'locked': false,
    'cost': 0,
    'unlockType': 'creative',
  },
  {
    'title': 'quizGame',
    'icon': Icons.quiz,
    'routeName': 'QuizGameApp',
    'image': 'assets/images/GameGridImages/QuizzMe.png', // ✅ New key
    'locked': true,
    'cost': 10,
    'unlockType': 'logic',
  },
  {
    'title': 'appStories',
    'icon': Icons.menu_book,
    'routeName': 'AppStories',
    'image': 'assets/images/GameGridImages/StoriesGame.png', // ✅ New key
    'locked': true,
    'cost': 15,
    'unlockType': 'reading',
  },

  {
    'title': 'MagicPainting',
    'icon': Icons.format_paint,
    'routeName': 'MagicPainting',
    'image': 'assets/images/GameGridImages/Painting.png', // ✅ New key
    'locked': true,
    'cost': 50,
    'unlockType': 'iq',
  },

  {
    'title': 'shapeSorter',
    'icon': Icons.square_foot_outlined,
    'routeName': 'ShapeSorter',
    'image': 'assets/images/GameGridImages/Shape.png', // ✅ New key
    'locked': true,
    'cost': 15,
    'unlockType': 'puzzle',
  },
  {
    'title': 'PlaneDestroyer',
    'icon': Icons.dashboard_outlined,
    'routeName': 'PlaneDestroyer',
    'image': 'assets/images/GameGridImages/PlaneDestoyer.png', // ✅ New key
    'locked': false,
    'cost': 15,
    'unlockType': 'strategy',
  },
  {
    'title': 'piano',
    'icon': Icons.piano,
    'routeName': 'Piano',
    'image': 'assets/images/GameGridImages/Piano.png', // ✅ New key
    'locked': true,
    'cost': 15,
    'unlockType': 'music',
  },
  {
    'title': 'WordLink',
    'icon': Icons.sort_by_alpha_outlined,
    'routeName': 'WordLink',
    'image': 'assets/images/GameGridImages/WordLink.png', // ✅ New key
    'locked': true,
    'cost': 10,
    'unlockType': 'language',
  },
  {
    'title': 'IQGame',
    'icon': Icons.smart_toy_outlined,
    'routeName': 'IQGame',
    'image': 'assets/images/GameGridImages/IQTest.png', // ✅ New key
    'locked': true,
    'cost': 10,
    'unlockType': 'iq',
  },

  {
    'title': 'JumpingBoard',
    'icon': Icons.attractions,
    'routeName': 'JumpingBoard',
    'image': 'assets/images/GameGridImages/JumpingSquare.png', // ✅ New key
    'locked': true,
    'cost': 10,
    'unlockType': 'iq',
  },

  {
    'title': 'WordExplorer',
    'icon': Icons.swipe_left,
    'routeName': 'WordExplorer',
    'image': 'assets/images/GameGridImages/BookOfWords.png', // ✅ New key
    'locked': true,
    'cost': 50,
    'unlockType': 'iq',
  },
];
