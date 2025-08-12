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
          /// HEADER
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: Colors.orange,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange.shade300, Colors.orange.shade700],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),

                  // Course title card
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
                      child: Material(
                        elevation: 6,
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            section.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 26,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bot
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: BotWithGreeting(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () {
                  audioManager.playEventSound('clickButton');
                  showDialog(
                    barrierDismissible: false,
                    context: context,
                    barrierColor: Colors.black.withOpacity(0.3),
                    builder: (BuildContext context) {
                      return const SettingsDialog();
                    },
                  );
                },
              ),
            ],
          ),

          /// ACTIVITIES SECTION
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                "Activities",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                  final sub = section.subsections[i];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 4,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => CourseNodePage(node: sub)),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.primaries[i % Colors.primaries.length].shade100,
                              radius: 28,
                              child: Icon(
                                Icons.menu_book,
                                size: 32,
                                color: Colors.primaries[i % Colors.primaries.length],
                              ),
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
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          ],
                        ),
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
