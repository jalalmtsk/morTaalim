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
    {'emoji': '🐱', 'cost': 0},
    {'emoji': '🐻', 'cost': 20},
    {'emoji': '🐶', 'cost': 45},
    {'emoji': '🐥', 'cost': 600},
    {'emoji': '🐵', 'cost': 120},
    {'emoji': '🐸', 'cost': 160},
    {'emoji': '👽', 'cost': 200},
    {'emoji': '🦊', 'cost': 250},
    {'emoji': '🤖', 'cost': 350},
    {'emoji': '🐨', 'cost': 400},
    {'emoji': '🐷', 'cost': 460},
    {'emoji': '🐼', 'cost': 495},
    {'emoji': '🧙‍♂️', 'cost': 640},
    {'emoji': '🦄', 'cost': 800},
    {'emoji': '🐯', 'cost': 1000},
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
              const SizedBox(height: 12),
              Consumer<ExperienceManager>(
                builder: (context, xpManager, _) => StarCounter(stars: xpManager.stars),
              ),
              const SizedBox(height: 12),
              const TokenAndAdSection(),
              const SizedBox(height: 12),
              Expanded(child: AvatarGrid(avatarItems: _avatarItems)),
            ],
          ),
        ),
      ),
    );
  }
}
