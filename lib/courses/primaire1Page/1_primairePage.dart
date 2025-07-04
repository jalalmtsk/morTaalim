import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mortaalim/widgets/shimmerPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../Inside_Course_Logic/HomeCourse.dart';

class primaire1 extends StatefulWidget {
  const primaire1({Key? key}) : super(key: key);

  @override
  _Primaire1State createState() => _Primaire1State();
}

class _Primaire1State extends State<primaire1> {
  final List<Map<String, String>> courses = [
    {'title': 'math', 'file': 'assets/courses/primary/microeconomics.json'},
    {'title': 'french', 'file': 'assets/courses/primary/economics.json'},
    {'title': 'arabic', 'file': 'assets/courses/primary/economics.json'},
    {'title': 'islamicEducation', 'file': 'assets/courses/primary/primaire1/Education_Islamique/1primaire_education_islamique.json'},
    {'title': 'artEducation', 'file': 'assets/courses/primary/macroeconomics.json'},
  ];

  Map<String, double> courseProgress = {};

  @override
  void initState() {
    super.initState();
    loadProgressForCourses();
  }
  bool isLoading = true;

  Future<void> loadProgressForCourses() async {
    final prefs = await SharedPreferences.getInstance();
    for (var course in courses) {
      final courseId = course['title']!;
      final saved = prefs.getStringList('progress_$courseId') ?? [];
      final total = await getTotalSections(course['file']!);
      final progress = total > 0 ? saved.length / total : 0.0;

      courseProgress[courseId] = progress;
    }
    await Future.delayed(const Duration(seconds: 1)); // simulate loading
    setState(() {
      isLoading = false;
    });
  }

  Future<int> getTotalSections(String jsonFilePath) async {
    final data = await rootBundle.loadString(jsonFilePath);
    final jsonResult = jsonDecode(data);
    return (jsonResult['sections'] as List).length;
  }

  IconData getCourseIcon(String title) {
    switch (title) {
      case 'math':
        return Icons.calculate;
      case 'french':
        return Icons.language;
      case 'arabic':
        return Icons.translate;
      case 'islamicEducation':
        return Icons.mosque;
      case 'artEducation':
        return Icons.brush;
      default:
        return Icons.menu_book;
    }
  }

  String getCourseName(String key, AppLocalizations tr) {
    switch (key) {
      case 'math':
        return tr.math;
      case 'french':
        return tr.french;
      case 'arabic':
        return tr.arabic;
      case 'islamicEducation':
        return tr.islamicEducation;
      case 'artEducation':
        return tr.artEducation;
      default:
        return tr.class6;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            pinned: true,
            expandedHeight: 100,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xffff7043), Color(0xfff4511e)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: FlexibleSpaceBar(

                titlePadding: const EdgeInsets.only(left: 60, bottom: 20),
                title: Text(
                  "📘 ${tr.class1}",
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                background: Padding(
                  padding: const EdgeInsets.only(top: 30),
                 /* child: Image.asset(
                    'assets/images/Mathematics_toy.png',
                    fit: BoxFit.cover,
                  ),*/

                ),
              ),
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
          ),

          // Your course list section remains the same as SliverToBoxAdapter
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: isLoading
                  ? ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 5,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (_, __) => const ShimmerCard(),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: courses.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final course = courses[index];
                  final title = course['title']!;
                  final icon = getCourseIcon(title);
                  final percent = courseProgress[title] ?? 0.0;
                  final percentText = (percent * 100).toStringAsFixed(0);

                  return TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: percent),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, double value, child) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CoursePage(
                                jsonFilePath: course['file']!,
                                courseId: title,
                                progressPrefix: "progress", // standard
                              ),
                            ),
                          ).then((_) => loadProgressForCourses());
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22), // more rounded corners
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withValues(alpha:0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(icon, size: 30, color: Colors.deepOrange),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        getCourseName(title, tr),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      "$percentText%",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepOrange,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: LinearProgressIndicator(
                                    value: value,
                                    minHeight: 10,
                                    backgroundColor: Colors.grey[300],
                                    color: Colors.deepOrangeAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );


  }
}
