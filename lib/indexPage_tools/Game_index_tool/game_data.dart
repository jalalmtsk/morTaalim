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
    'locked': false,
    'cost': 0,
    'unlockType': 'logic',
  },
  {
    'title': 'appStories',
    'icon': Icons.menu_book,
    'routeName': 'AppStories',
    'image': 'assets/images/GameGridImages/StoriesGame.png', // ✅ New key
    'locked': true,
    'cost': 80,
    'unlockType': 'reading',
  },

  {
    'title': 'MagicPainting',
    'icon': Icons.format_paint,
    'routeName': 'MagicPainting',
    'image': 'assets/images/GameGridImages/Painting.png', // ✅ New key
    'locked': true,
    'cost': 100,
    'unlockType': 'iq',
  },

  {
    'title': 'AnimalSounds',
    'icon': Icons.surround_sound,
    'routeName': 'AnimalSounds',
    'image': 'assets/images/GameGridImages/AnimalSounds.png', // ✅ New key
    'locked': true,
    'cost': 150,
    'unlockType': 'Animal',
  },

  {
    'title': 'MemoryFlip',
    'icon': Icons.flip,
    'routeName': 'MemoryFlip',
    'image': 'assets/images/GameGridImages/MemoryFlip.png', // ✅ New key
    'locked': true,
    'cost': 180,
    'unlockType': 'MemoryFlip',
  },

  /*{
    'title': 'BreakingWalls',
    'icon': Icons.square_foot_outlined,
    'routeName': 'BreakingWalls',
    'image': 'assets/images/GameGridImages/BreakingWalls.png', // ✅ New key
    'locked': true,
    'cost': 180,
    'unlockType': 'puzzle',
  },

  {
    'title': 'SugarSmash',
    'icon': Icons.square_foot_outlined,
    'routeName': 'SugarSmash',
    'image': 'assets/images/GameGridImages/Shape.png', // ✅ New key
    'locked': true,
    'cost': 150,
    'unlockType': 'puzzle',
  },

  {
    'title': 'shapeSorter',
    'icon': Icons.square_foot_outlined,
    'routeName': 'ShapeSorter',
    'image': 'assets/images/GameGridImages/Shape.png', // ✅ New key
    'locked': true,
    'cost': 150,
    'unlockType': 'puzzle',
  },
  {
    'title': 'PlaneDestroyer',
    'icon': Icons.dashboard_outlined,
    'routeName': 'PlaneDestroyer',
    'image': 'assets/images/GameGridImages/PlaneDestoyer.png', // ✅ New key
    'locked': true,
    'cost': 180,
    'unlockType': 'strategy',
  },

  {
    'title': 'WordLink',
    'icon': Icons.sort_by_alpha_outlined,
    'routeName': 'WordLink',
    'image': 'assets/images/GameGridImages/WordLink.png', // ✅ New key
    'locked': true,
    'cost': 220,
    'unlockType': 'language',
  },
  {
    'title': 'IQGame',
    'icon': Icons.smart_toy_outlined,
    'routeName': 'IQGame',
    'image': 'assets/images/GameGridImages/IQTest.png', // ✅ New key
    'locked': true,
    'cost': 250,
    'unlockType': 'iq',
  },

  {
    'title': 'JumpingBoard',
    'icon': Icons.attractions,
    'routeName': 'JumpingBoard',
    'image': 'assets/images/GameGridImages/JumpingSquare.png', // ✅ New key
    'locked': true,
    'cost': 250,
    'unlockType': 'iq',
  },

  {
    'title': 'WordExplorer',
    'icon': Icons.swipe_left,
    'routeName': 'WordExplorer',
    'image': 'assets/images/GameGridImages/BookOfWords.png', // ✅ New key
    'locked': true,
    'cost': 300,
    'unlockType': 'iq',
  },

  {
    'title': 'Piano',
    'icon': Icons.piano,
    'routeName': 'Piano',
    'image': 'assets/images/GameGridImages/Piano.png', // ✅ New key
    'locked': true,
    'cost': 500,
    'unlockType': 'music',
  },

   */

];
