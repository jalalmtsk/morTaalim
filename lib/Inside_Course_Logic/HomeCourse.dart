import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mortaalim/tools/VideoPlayer.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../l10n/app_localizations.dart';

import 'nestedCourse.dart';

class CoursePage extends StatefulWidget {
  final String jsonFilePath;
  final String courseId;
  final String progressPrefix;

  const CoursePage({
    super.key,
    required this.jsonFilePath,
    required this.courseId,
    this.progressPrefix = "progress",
  });

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> with TickerProviderStateMixin {
  String courseTitle = '';
  List<dynamic> sections = [];
  Set<int> completedSections = {};
  bool isLoading = true;
  late SharedPreferences prefs;
  late ConfettiController _confettiController;
  late AnimationController _breathController;
  final FlutterTts tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    loadData();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _breathController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    final String data = await rootBundle.loadString(widget.jsonFilePath);
    final jsonResult = jsonDecode(data);
    prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_progressKey()) ?? [];

    setState(() {
      courseTitle = jsonResult['title'];
      sections = jsonResult['sections'];
      completedSections = saved.map((e) => int.tryParse(e) ?? -1).where((i) => i >= 0).toSet();
      isLoading = false;
    });
  }

  String _progressKey() => '${widget.progressPrefix}_${widget.courseId}';

  Future<void> saveProgress() async {
    await prefs.setStringList(_progressKey(), completedSections.map((e) => e.toString()).toList());
  }

  Future<void> toggleSection(int index) async {
    setState(() {
      if (completedSections.contains(index)) {
        completedSections.remove(index);
      } else {
        completedSections.add(index);
      }
    });
    saveProgress();

    if (completedSections.length == sections.length && sections.isNotEmpty) {
      _confettiController.play();
      await Future.delayed(const Duration(seconds: 3));
      await ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("${AppLocalizations.of(context)!.greatJob} 🎉"),
        backgroundColor: Colors.deepOrange,
        duration: const Duration(seconds: 2),
      ));
      Navigator.of(context).pop();
    }
  }

  Future<void> speak(String text) async {
    await tts.setLanguage("ar-MA");
    await tts.setPitch(1);
    await tts.speak(text);
  }

  // Breathing scale animation for the cards
  Widget breathing(Widget child) {
    return AnimatedBuilder(
      animation: _breathController,
      builder: (context, childWidget) {
        final scale = 0.95 + 0.1 * _breathController.value; // 0.95 to 1.05 scale
        return Transform.scale(scale: scale, child: childWidget);
      },
      child: child,
    );
  }

  void showSubsectionModal(Map<String, dynamic> section, int index) {
    final subsections = section['subsections'] ?? [];
    showModalBottomSheet(
      enableDrag: true,
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.deepOrange.shade50,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                section['title'],
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepOrange),
              ),
              const SizedBox(height: 30),
              Center(
                child: Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: subsections.map<Widget>((sub) {
                    return breathing(BubbleButton(
                      label: sub['title'],
                      color: Colors.primaries[subsections.indexOf(sub) % Colors.primaries.length].shade700,
                      onTap: () {
                        Navigator.pop(context);
                        speak(sub['title']);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CourseNodePage(node: sub),
                          ),
                        );
                      },
                    ));
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final progressPercent = sections.isEmpty ? 0.0 : completedSections.length / sections.length;

    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: Text(
          courseTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
        ),
        backgroundColor: Colors.deepOrange,
        centerTitle: true,
        toolbarHeight: 70,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5, bottom: 24),
            child: Column(
              children: [
                Userstatutbar(),
                const SizedBox(height: 14),
                // Linear progress bar for clarity
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: LinearProgressIndicator(
                          minHeight: 20,
                          value: progressPercent,
                          backgroundColor: Colors.deepOrange.shade100,
                          color: Colors.deepOrange,
                        ),
                      ),
                      Text(
                        "${(progressPercent * 100).toInt()}% 🎉",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 26, color: Colors.deepOrange),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
                Text("Choose Course",  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 26, color: Colors.deepOrange),),
                Expanded(
                  child: PageView.builder(
                    controller: PageController(viewportFraction: 0.72),
                    itemCount: sections.length,
                    itemBuilder: (context, index) {
                      final section = sections[index];
                      return GestureDetector(
                        onTap: () => showSubsectionModal(section, index),
                        child: breathing(FunSectionCard(
                          title: section['title'],
                          emoji: '🎓',
                          color: Colors.primaries[index % Colors.primaries.length].shade400,
                          isCompleted: completedSections.contains(index),
                          onToggle: () => toggleSection(index),
                        )),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Confetti celebration on 100% progress
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.deepOrange,
                Colors.orange,
                Colors.amber,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FunSectionCard extends StatelessWidget {
  final String title;
  final Color color;
  final String emoji;
  final bool isCompleted;
  final VoidCallback onToggle;

  const FunSectionCard({
    super.key,
    required this.title,
    required this.color,
    required this.emoji,
    required this.isCompleted,
    required this.onToggle,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(24),
        color: color,
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              height: 270,
              width: double.infinity,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 56)),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 6,
                            color: Colors.black26,
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Checkbox(
                value: isCompleted,
                onChanged: (_) => onToggle(),
                checkColor: Colors.white,
                activeColor: Colors.green.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                side: BorderSide(color: Colors.white, width: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BubbleButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const BubbleButton({super.key, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.orange.shade200,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
      ),
    );
  }
}
