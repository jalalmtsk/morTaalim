import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  List<int> globalScores = [];

  @override
  void initState() {
    super.initState();
    loadScores();
  }

  Future<void> loadScores() async {
    final prefs = await SharedPreferences.getInstance();
    final scores = prefs.getStringList('global_scores') ?? [];
    setState(() {
      globalScores = scores.map(int.parse).toList()..sort((b, a) => a.compareTo(b)); // Descending
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: globalScores.isEmpty
          ? const Center(child: Text('No scores recorded yet.'))
          : ListView.builder(
        itemCount: globalScores.length,
        itemBuilder: (context, index) {
          final rank = index + 1;
          final score = globalScores[index];
          return ListTile(
            leading: CircleAvatar(child: Text('$rank')),
            title: Text('Score: $score'),
          );
        },
      ),
    );
  }
}
