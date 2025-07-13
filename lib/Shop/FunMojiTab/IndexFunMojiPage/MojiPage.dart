import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../XpSystem.dart';
import '../../../widgets/userStatutBar.dart';
import '../../Tools/_StarCounter.dart';
import '../../Tools/_TokenAndSection.dart';
import '../../Widgets/ImageAvatarGrid.dart';
import '../../Widgets/avatarGrid.dart';


class Moji extends StatelessWidget {
  const Moji({super.key});

  static const List<Map<String, dynamic>> _avatarItems = [
    {'emoji': '🐱', 'cost': 1},
    {'emoji': '🐻', 'cost': 15},
    {'emoji': '🐶', 'cost': 15},
    {'emoji': '🐥', 'cost': 20},
    {'emoji': '🐵', 'cost': 25},
    {'emoji': '🐸', 'cost': 30},
    {'emoji': '👽', 'cost': 30},
    {'emoji': '🦊', 'cost': 50},
    {'emoji': '🤖', 'cost': 50},
    {'emoji': '🐨', 'cost': 60},
    {'emoji': '🐷', 'cost': 80},
    {'emoji': '🐼', 'cost': 80},
    {'emoji': '🐓', 'cost': 80},
    {'emoji': '🐝', 'cost': 100},
    {'emoji': '🐰', 'cost': 200},
    {'emoji': '🐧', 'cost': 250},
    {'emoji': '🐢', 'cost': 300},
    {'emoji': '🦉', 'cost': 350},
    {'emoji': '🦖', 'cost': 400},
    {'emoji': '🐬', 'cost': 450},
    {'emoji': '🦦', 'cost': 500},
    {'emoji': '🐙', 'cost': 550},
    {'emoji': '🦥', 'cost': 600},
    {'emoji': '🦩', 'cost': 650},
    {'emoji': '🦜', 'cost': 700},
    {'emoji': '🐿️', 'cost': 750},
    {'emoji': '🧙‍♂️', 'cost': 750},
    {'emoji': '🦚', 'cost': 800},
    {'emoji': '🦇', 'cost': 850},
    {'emoji': '👻', 'cost': 900},
    {'emoji': '🤡', 'cost': 950},
    {'emoji': '🦄', 'cost': 1000},
    {'emoji': '🧛‍♂️', 'cost': 1200},
    {'emoji': '🧜‍♀️', 'cost': 1300},
    {'emoji': '🐯', 'cost': 1500},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFff9966), Color(0xFFff5e62)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(child: AvatarGrid(avatarItems: _avatarItems)),
            ],
          ),
        ),
      ),
    );
  }
}
