import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mortaalim/tools/audio_tool.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class GameGrid extends StatelessWidget {
  final List<Map<String, dynamic>> games;
  final MusicPlayer musicPlayer;

  const GameGrid({super.key, required this.games, required this.musicPlayer});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    return Column(
      children: [

        Row(
          children: [
            Text(textAlign: TextAlign.start, tr.chooseGame, style: TextStyle(fontSize: 20, color: Colors.grey[700])),
          ],
        ),

        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: games.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
              childAspectRatio: 4 / 3,
            ),
            itemBuilder: (context, index) {
              final game = games[index];
              return GestureDetector(
                onTap: () {
                  musicPlayer.stop();
                  // You might want to update musicisOn too if necessary
                  Navigator.pushNamed(context, game['routeName']);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: game['color'].withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: game['color'].withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(2, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(game['icon'], size: 48, color: Colors.white),
                      const SizedBox(height: 10),
                      Text(
                        _getCourseTitle(tr, game['title']),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getCourseTitle(AppLocalizations tr, String key) {
    switch (key) {
      case 'drawingAlphabet':
        return tr.drawingAlphabet;
      case 'quizGame':
        return tr.quizGame;
      case 'appStories':
        return tr.appStories;
      case 'shapeSorter':
        return tr.shapeSorter;
      case 'boardGame':
        return tr.boardGame;
      case 'piano':
      default:
        return tr.piano;
    }
  }
}
