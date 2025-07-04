// 🟧 Refined CoursePage with Fun Bubble UI + JSON Integration + Progress Tracking

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mortaalim/tools/VideoPlayer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
  late AnimationController _wiggleController;
  final FlutterTts tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    loadData();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _wiggleController.dispose();
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

  void toggleSection(int index) {
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("${AppLocalizations.of(context)!.greatJob} 🎉"),
        backgroundColor: Colors.deepOrange,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> speak(String text) async {
    await tts.setLanguage("ar-MA");
    await tts.setPitch(1);
    await tts.speak(text);
  }

  Widget wiggle(Widget child) {
    return AnimatedBuilder(
      animation: _wiggleController,
      child: child,
      builder: (context, widget) {
        final double offset = 0.05 * sin(_wiggleController.value * 2 * pi);
        return Transform.rotate(angle: offset, child: widget);
      },
    );
  }

  void showSubsectionModal(Map<String, dynamic> section, int index) {
    final subsections = section['subsections'] ?? [];
    showModalBottomSheet(
      enableDrag: true,
      useSafeArea: true,

      context: context,
      backgroundColor: Colors.deepOrange.shade50,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Text(
              section['title'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            Expanded(
              child: ListView(children: [
                Center(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: subsections.map<Widget>((sub) {
                      return wiggle(BubbleButton(
                        label: sub['title'],
                        color: Colors.primaries[subsections.indexOf(sub) % Colors.primaries.length],
                        onTap: () {
                          Navigator.pop(context);
                          speak(sub['title']);
                          toggleSection(index);

                          // Here's where you push to the detailed page:
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CourseNodePage(node: sub),  // <== pass the subsection 'sub' here
                            ),
                          );
                        },
                      ));
                    }).toList(),
                  ),
                ),
              ],),
            ),
          ],
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

    return Scaffold(
      appBar: AppBar(
        title: Text(courseTitle),
        backgroundColor: Colors.deepOrange,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Text(
                  "${(completedSections.length / sections.length * 100).toStringAsFixed(0)}%",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: PageView.builder(
                    controller: PageController(viewportFraction: 0.7),
                    itemCount: sections.length,
                    itemBuilder: (context, index) {
                      final section = sections[index];
                      return GestureDetector(
                        onTap: () => showSubsectionModal(section, index),
                        child: FunSectionCard(
                          title: section['title'],
                          emoji: '🎓',
                          color: Colors.primaries[index % Colors.primaries.length],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
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
  const FunSectionCard({super.key, required this.title, required this.color, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        elevation: 5,
        borderRadius: BorderRadius.circular(20),
        color: color,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 10),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
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
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }
}
