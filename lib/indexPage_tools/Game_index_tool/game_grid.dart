import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/tools/audio_tool.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../loading_page.dart';

class GameGrid extends StatefulWidget {
  final List<Map<String, dynamic>> games;
  final MusicPlayer musicPlayer;

  const GameGrid({super.key, required this.games, required this.musicPlayer});

  @override
  State<GameGrid> createState() => _GameGridState();
}

class _GameGridState extends State<GameGrid> with TickerProviderStateMixin {
  Future<void> simulateLoading() async {
    await Future.delayed(const Duration(seconds: 2));
  }

  void showUnlockAnimation(BuildContext context) {
    final overlay = Overlay.of(context);
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    final animation = Tween(begin: 0.0, end: 1.5)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(controller);

    final entry = OverlayEntry(
      builder: (_) => Positioned(
        top: MediaQuery.of(context).size.height * 0.3,
        left: MediaQuery.of(context).size.width * 0.3,
        child: ScaleTransition(
          scale: animation,
          child: const Icon(Icons.lock_open, size: 60, color: Colors.amber),
        ),
      ),
    );

    overlay.insert(entry);
    controller.forward();

    Future.delayed(const Duration(milliseconds: 1000), () {
      entry.remove();
      controller.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final xpManager = Provider.of<ExperienceManager>(context);
    final tr = AppLocalizations.of(context)!;

    return Column(
      children: [
        Row(
          children: [
            Text(
              textAlign: TextAlign.start,
              tr.chooseGame,
              style: TextStyle(fontSize: 20, color: Colors.grey[700]),
            ),
          ],
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: widget.games.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
              childAspectRatio: 4 / 3,
            ),
            itemBuilder: (context, index) {
              final game = widget.games[index];
              final isUnlocked = !game['locked'] ||
                  xpManager.isCourseUnlocked(game['title']);
              final cost = game['cost'] ?? 10;
              final isLocked = game['locked'] && !isUnlocked;

              return GestureDetector(
                onTap: () {
                  if (isUnlocked) {
                    widget.musicPlayer.stop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LoadingPage(
                          loadingFuture: simulateLoading(),
                          nextRouteName: game['routeName'],
                        ),
                      ),
                    );
                  } else {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Course Locked"),
                        content: Text("Unlock this course for $cost ⭐?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if (xpManager.stars >= cost) {
                                xpManager.unlockCourse(game['title'], cost);
                                Navigator.pop(context);
                                if (mounted) {
                                  showUnlockAnimation(context);
                                }
                              } else {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Not enough stars!")),
                                );
                              }
                            },
                            child: const Text("Unlock"),
                          )
                        ],
                      ),
                    );
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isLocked
                        ? Colors.grey.shade700
                        : game['color'].withOpacity(0.9),
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
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(game['icon'], size: 48, color: Colors.white),
                          if (isLocked)
                            const Positioned(
                              bottom: 0,
                              right: 0,
                              child: Icon(Icons.lock,
                                  size: 20, color: Colors.white),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _getCourseTitle(tr, game['title']),
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isLocked)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.star,
                                  size: 18, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                "$cost",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!isLocked && cost == 0)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "FREE!",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        )
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
        return tr.piano;
      case 'WordLink':
        return tr.linkWordgame;
      case 'IQGame':
        return tr.linkWordgame;
      default:
        return key;
    }
  }
}
