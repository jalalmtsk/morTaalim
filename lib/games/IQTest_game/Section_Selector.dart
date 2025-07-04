import 'package:flutter/material.dart';
import 'package:mortaalim/games/IQTest_game/progressGraph.dart';
import 'package:mortaalim/games/IQTest_game/IQ_Quizz_Page.dart';


import 'iqGame_data.dart';
import 'leaderBoard_Page.dart';

class SectionSelector extends StatelessWidget {
  const SectionSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🧠 IQ Test Game')),
      body: ListView.builder(
        itemCount: sections.length + 1, // Extra for Leaderboard & Progress
        itemBuilder: (context, index) {
          if (index == sections.length) {
            // Leaderboard & Progress buttons
            return Column(
              children: [
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.leaderboard, color: Colors.deepPurple),
                  title: const Text('Leaderboard'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LeaderboardPage()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.show_chart, color: Colors.deepPurple),
                  title: const Text('Progress Graph'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProgressGraphPage()),
                  ),
                ),
              ],
            );
          }
          final section = sections[index];
          return ListTile(
            leading: Icon(section.icon, color: Colors.deepPurple),
            title: Text(section.title, style: const TextStyle(fontSize: 20)),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuizPage(section: section),
                ),
              );
            },
          );
        },
      ),
    );
  }
}