import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mortaalim/widgets/course_progress.dart';
import 'package:mortaalim/widgets/section_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CoursePage extends StatefulWidget {
  final String jsonFilePath;
  final String courseId;

  const CoursePage({required this.jsonFilePath, required this.courseId, super.key});

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  String courseTitle = '';
  List<dynamic> sections = [];
  Set<int> completedSections = {};
  late SharedPreferences prefs;
  bool isLoading = true;

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    loadCourseAndProgress();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> loadCourseAndProgress() async {
    final String data = await rootBundle.loadString(widget.jsonFilePath);
    final jsonResult = jsonDecode(data);

    prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_progressKey()) ?? [];

    setState(() {
      courseTitle = jsonResult['title'];
      sections = jsonResult['sections'];
      completedSections =
          saved.map((e) => int.tryParse(e) ?? -1).where((i) => i >= 0).toSet();
      isLoading = false;
    });
  }

  String _progressKey() => 'progress_${widget.courseId}';

  Future<void> saveProgress() async {
    await prefs.setStringList(
      _progressKey(),
      completedSections.map((i) => i.toString()).toList(),
    );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${AppLocalizations.of(context)!.great_job} 🎉"),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.deepOrange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pop(); // Go back
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    double progress = sections.isEmpty ? 0 : completedSections.length / sections.length;
    String progressPercent = (progress * 100).toStringAsFixed(0);

    return Scaffold(
      backgroundColor: const Color(0xfffff8f1), // Soft warm pastel background
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 20),
        child: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xffff7043), Color(0xfff4511e)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepOrangeAccent,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            '$courseTitle ($progressPercent%)',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              shadows: [
                Shadow(
                  blurRadius: 8,
                  color: Colors.black26,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
        ),



      ),
      body: Stack(
        children: [
          Column(
            children: [
              CourseProgress(
                progress: progress,
                progressPercent: progressPercent,
                color: Colors.deepOrangeAccent, // vivid orange progress bar
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: sections.length,
                  itemBuilder: (context, index) {
                    return SectionCard(
                      section: sections[index],
                      isDone: completedSections.contains(index),
                      index: index,
                      toggle: toggleSection,
                      highlightColor: Colors.deepOrangeAccent, // vivid orange highlight
                    );
                  },
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.deepOrange,
                Colors.orangeAccent,
                Colors.amber,
                Colors.yellowAccent,
                Colors.orange,
              ],
              emissionFrequency: 0.05,
              numberOfParticles: 30,
            ),
          ),
        ],
      ),
    );
  }
}
