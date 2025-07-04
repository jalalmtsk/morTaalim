import 'package:flutter/material.dart';

final List<Map<String, dynamic>> games = [
  {
    'title': 'drawingAlphabet',
    'icon': Icons.brush,
    'routeName': 'DrawingAlphabet',
    'color': Colors.deepPurple,
    'locked': false,
    'cost': 0,
  },
  {
    'title': 'quizGame',
    'icon': Icons.quiz,
    'routeName': 'QuizGameApp',
    'color': Colors.deepOrange,
    'locked': true,
    'cost': 10,
  },
  {
    'title': 'appStories',
    'icon': Icons.menu_book,
    'routeName': 'AppStories',
    'color': Colors.blue,
    'locked': true,
    'cost': 15,
  },
  // etc...



{
    'title': 'shapeSorter',
    'icon': Icons.square_foot_outlined,
    'routeName': 'ShapeSorter',
    'color': Colors.green,
  'locked': true,
  'cost': 15,
  },
  {
    'title': 'boardGame',
    'icon': Icons.dashboard_outlined,
    'routeName': 'Board',
    'color': Colors.teal,
    'locked': false,
    'cost': 15,
  },
  {
    'title': 'piano',
    'icon': Icons.piano,
    'routeName': 'Piano',
    'color': Colors.black.withValues(alpha: 0.6),
    'locked': true,
    'cost': 15,
  },

  {
    'title': 'WordLink',
    'icon': Icons.sort_by_alpha_outlined,
    'routeName': 'WordLink',
    'color': Colors.indigo,
    'locked': true,
    'cost': 10,
  },

  {
    'title': 'IQGame',
    'icon': Icons.smart_toy_outlined,
    'routeName': 'IQGame',
    'color': Colors.pinkAccent,
    'locked': true,
    'cost': 10,
  },


];
