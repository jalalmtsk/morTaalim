import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mortaalim/tools/VideoPlayer.dart';
import 'package:mortaalim/tools/YoutubePlayerPage.dart';
import 'package:shared_preferences/shared_preferences.dart';


class CoursePage extends StatefulWidget {
  final String jsonFilePath;
  final String courseId;

  CoursePage({required this.jsonFilePath, required this.courseId});

  @override
  _CoursePageState createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  String courseTitle = '';
  List<dynamic> sections = [];
  Set<int> completedSections = {};

  bool isArabic(String text) {
    final arabicRegExp = RegExp(r'[\u0600-\u06FF]');
    return arabicRegExp.hasMatch(text);
  }

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
      if (completedSections.contains(index)) {
        completedSections.remove(index);
      } else {
        completedSections.add(index);
      }
    });
    saveProgress();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(title: const Text('Chargement...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    double progress = sections.isEmpty ? 0 : completedSections.length /
        sections.length;
    String progressPercent = (progress * 100).toStringAsFixed(0);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 3,
        backgroundColor: Colors.deepPurple,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        title: Text('$courseTitle ($progressPercent%)'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Progression: $progressPercent%',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[300],
                    color: Colors.deepPurpleAccent,
                    minHeight: 10,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: sections.length,
              itemBuilder: (context, index) {
                final section = sections[index];
                final isDone = completedSections.contains(index);

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 6.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                    child: ExpansionTile(
                      key: Key('$index'),
                      tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      title: Row(
                        children: [
                          Expanded(
                            child: Directionality(
                              textDirection: isArabic(section['title'])
                                  ? TextDirection.rtl
                                  : TextDirection.ltr,
                              child: Text(
                                section['title'],
                                textAlign: isArabic(section['title'])
                                    ? TextAlign.right
                                    : TextAlign.left,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.deepPurple,
                                  fontFamily: isArabic(section['title'])
                                      ? 'Amiri'
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          Checkbox(
                            value: isDone,
                            activeColor: Colors.deepPurple,
                            onChanged: (val) => toggleSection(index),
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Directionality(
                                textDirection: isArabic(section['content'])
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    section['content'],
                                    textAlign: isArabic(section['content'])
                                        ? TextAlign.right
                                        : TextAlign.left,
                                    style: TextStyle(
                                      fontSize: 16,
                                      height: 1.5,
                                      color: Colors.deepPurple.shade900,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: isArabic(section['content'])
                                          ? 'Amiri'
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (section['controller'] != null &&
                                  section['controller']
                                      .toString()
                                      .trim()
                                      .isNotEmpty)
                                section['type'] == 'youtube'
                                    ? YouTubeSectionPlayer(
                                    videoUrl: section['controller'])
                                    : SectionVlcPlayer(
                                    videoPath: section['controller']),
                            ],
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
      ),
    );
  }
}
