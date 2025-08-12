import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../Settings/SettingPanelInGame.dart';
import '../../main.dart';
import '../../widgets/AIChatbot/BotFeatures/BotWithGreeting.dart';
import '../HomeCourse.dart';
import '../nestedCourse.dart';

class CourseDetailPage extends StatelessWidget {
  final GamifiedSection section;
  final int index;
  final VoidCallback onComplete;

  const CourseDetailPage({
    Key? key,
    required this.section,
    required this.index,
    required this.onComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.orange,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 120.0, right: 20, left: 20),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Text(
                        section.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              blurRadius: 4,
                              offset: Offset(1, 1),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),

                  Align(
                    alignment: Alignment.bottomCenter,
                    child: BotWithGreeting()
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.black),
                onPressed: () {
                  audioManager.playEventSound('clickButton');
                  showDialog(
                    barrierDismissible: false,
                    context: context,
                    barrierColor: Colors.black.withValues(alpha: 0.3),
                    builder: (BuildContext context) {
                      return const SettingsDialog();
                    },
                  );
                },
              ),
              ]
          ),

          // Subsections
          SliverPadding(
            padding: const EdgeInsets.all(12.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                  final sub = section.subsections[i];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CourseNodePage(node: sub)),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.primaries[i % Colors.primaries.length].shade100,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 28,
                            child: Icon(Icons.disc_full_rounded,
                                size: 36,
                                color: Colors.primaries[i % Colors.primaries.length]),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sub['title'] ?? 'Activity',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  sub['description'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: section.subsections.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}
