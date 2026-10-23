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
    'title': 'BrainBuilder',
    'icon': Icons.psychology_alt_rounded,
    'routeName': 'BrainBuilder',
    'image': 'assets/images/GameGridImages/BrainBuilder.png',
    'locked': false,
    'cost': 0,
    'unlockType': 'logic',
  },
  {
    'title': 'LittleMarket',
    'icon': Icons.storefront_rounded,
    'routeName': 'LittleMarket',
    'image': 'assets/images/GameGridImages/LittleMarket.png',
    'locked': false,
    'cost': 0,
    'unlockType': 'logic',
  },
  // Magic Passport — hidden for now
  // {
  //   'title': 'MagicPassport',
  //   'icon': Icons.travel_explore_rounded,
  //   'routeName': 'MagicPassport',
  //   'image': 'assets/images/GameGridImages/MagicPassport.png',
  //   'locked': false,
  //   'cost': 0,
  //   'unlockType': 'logic',
  // },
  {
    'title': 'MonJardin',
    'icon': Icons.local_florist_rounded,
    'routeName': 'MonJardin',
    'image': 'assets/images/GameGridImages/MonJardin.png',
    'locked': false,
    'cost': 0,
    'unlockType': 'logic',
  },
  {
    'title': 'MysteryQuest',
    'icon': Icons.search_rounded,
    'routeName': 'MysteryQuest',
    'image': 'assets/images/GameGridImages/MysteryQuest.png',
    'locked': false,
    'cost': 0,
    'unlockType': 'logic',
  },
  {
    'title': 'PuzzleLand',
    'icon': Icons.extension_rounded,
    'routeName': 'PuzzleLand',
    'image': 'assets/images/GameGridImages/PuzzleLand.png',
    'locked': false,
    'cost': 0,
    'unlockType': 'puzzle',
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

  // Shape Pop — hidden for now
  // {
  //   'title': 'shapeSorter',
  //   'icon': Icons.square_foot_outlined,
  //   'routeName': 'ShapeSorter',
  //   'image': 'assets/images/GameGridImages/Shape.png', // ✅ New key
  //   'locked': true,
  //   'cost': 0,
  //   'unlockType': 'puzzle',
  // },

  // Story Land — hidden for now
  // {
  //   'title': 'appStories',
  //   'icon': Icons.menu_book,
  //   'routeName': 'AppStories',
  //   'image': 'assets/images/GameGridImages/StoriesGame.png', // ✅ New key
  //   'locked': true,
  //   'cost': 0,
  //   'unlockType': 'reading',
  // },

  {
    'title': 'MagicPainting',
    'icon': Icons.format_paint,
    'routeName': 'MagicPainting',
    'image': 'assets/images/GameGridImages/Painting.png', // ✅ New key
    'locked': true,
    'cost': 15,
    'unlockType': 'iq',
  },



  {
    'title': 'AnimalSounds',
    'icon': Icons.surround_sound,
    'routeName': 'AnimalSounds',
    'image': 'assets/images/GameGridImages/AnimalSounds.png', // ✅ New key
    'locked': true,
    'cost': 15,
    'unlockType': 'Animal',
  },

  {
    'title': 'MemoryFlip',
    'icon': Icons.flip,
    'routeName': 'MemoryFlip',
    'image': 'assets/images/GameGridImages/MemoryFlip.png', // ✅ New key
    'locked': true,
    'cost': 20,
    'unlockType': 'MemoryFlip',
  },


  {
    'title': 'WordLink',
    'icon': Icons.sort_by_alpha_outlined,
    'routeName': 'WordLink',
    'image': 'assets/images/GameGridImages/WordLink.png', // ✅ New key
    'locked': true,
    'cost': 25,
    'unlockType': 'language',
  },

  // Word Explorer — hidden for now
  // {
  //   'title': 'WordExplorer',
  //   'icon': Icons.swipe_left,
  //   'routeName': 'WordExplorer',
  //   'image': 'assets/images/GameGridImages/BookOfWords.png', // ✅ New key
  //   'locked': true,
  //   'cost': 30,
  //   'unlockType': 'iq',
  // },

  {
    'title': 'Piano',
    'icon': Icons.piano,
    'routeName': 'Piano',
    'image': 'assets/images/GameGridImages/Piano.png', // ✅ New key
    'locked': true,
    'cost': 50,
    'unlockType': 'music',
  },

  /*

  {
    'title': 'BreakingWalls',
    'icon': Icons.square_foot_outlined,
    'routeName': 'BreakingWalls',
    'image': 'assets/images/GameGridImages/BreakingWalls.png', // ✅ New key
    'locked': true,
    'cost': 20,
    'unlockType': 'puzzle',
  },

  {
    'title': 'SugarSmash',
    'icon': Icons.square_foot_outlined,
    'routeName': 'SugarSmash',
    'image': 'assets/images/GameGridImages/Shape.png', // ✅ New key
    'locked': true,
    'cost': 20,
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


   */
];
