import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mortaalim/widgets/course_progress.dart';
import 'package:mortaalim/widgets/section_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState() {
    super.initState();
    loadCourseAndProgress();
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
      completedSections.contains(index)
          ? completedSections.remove(index)
          : completedSections.add(index);
    });
    saveProgress();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    double progress = sections.isEmpty ? 0 : completedSections.length / sections.length;
    String progressPercent = (progress * 100).toStringAsFixed(0);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('$courseTitle ($progressPercent%)'),
        backgroundColor: Colors.deepPurple,
        elevation: 3,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Column(
        children: [

          //CourseProgress Page.......
          CourseProgress(progress: progress, progressPercent: progressPercent),
          Expanded(
            child: ListView.builder(
              itemCount: sections.length,
              itemBuilder: (context, index) {

                //SectionCard Page.......
                return SectionCard(
                  section: sections[index],
                  isDone: completedSections.contains(index),
                  index: index,
                  toggle: toggleSection,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
