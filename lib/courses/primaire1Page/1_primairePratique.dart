import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mortaalim/l10n/app_localizations.dart';
import 'package:mortaalim/widgets/shimmerPage.dart';

import 'PractiseCoursesSubjects/French1/1_primaire_French_Practise.dart';
import 'PractiseCoursesSubjects/Math1/1_primaire_Math_Practise.dart';
import 'PractiseCoursesSubjects/Science1/1_primaire_Science_Practise.dart';
import 'PractiseCoursesSubjects/IslamicEducation1/1_primaire_IslamicEducation_Practise.dart';

class Primaire1Pratique extends StatefulWidget {
  const Primaire1Pratique({super.key});

  @override
  State<Primaire1Pratique> createState() => _Primaire1PratiqueState();
}

class _Primaire1PratiqueState extends State<Primaire1Pratique> {
  final List<Map<String, String>> courses = [
    {'title': 'math', 'route': 'IndexMath1Practise'},
    {'title': 'french', 'route': 'IndexFrench1Practise'},
    {'title': 'islamicEducation', 'route': 'IndexIslamicEducation1Practise'},
    {'title': 'science', 'route': 'IndexScience1Practise'},
  ];

  Map<String, double> courseProgress = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProgress();
  }

  Future<void> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    for (var course in courses) {
      final saved = prefs.getStringList('progress2_${course['title']}') ?? [];
      courseProgress[course['title']!] = saved.length / 10;
    }
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      isLoading = false;
    });
  }

  IconData getIcon(String key) {
    switch (key) {
      case 'math':
        return Icons.calculate_rounded;
      case 'french':
        return Icons.language;
      case 'islamicEducation':
        return Icons.mosque_outlined;
      case 'science':
        return Icons.science;
      default:
        return Icons.book;
    }
  }

  Widget? getPage(String route) {
    switch (route) {
      case 'IndexMath1Practise':
        return IndexMath1Practise();
      case 'IndexFrench1Practise':
        return IndexFrench1Practise();
      case 'IndexScience1Practise':
        return IndexScience1Practise();
      case 'IndexIslamicEducation1Practise':
        return IndexIslamicEducation1Practise();
      default:
        return null;
    }
  }

  String getLabel(String key, AppLocalizations tr) {
    switch (key) {
      case 'math':
        return tr.math;
      case 'french':
        return tr.french;
      case 'islamicEducation':
        return tr.islamicEducation;
      case 'science':
        return tr.artEducation;
      default:
        return tr.class1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xfff7f9fc),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff4db6ac), Color(0xff00796b)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.school, color: Colors.white, size: 30),
                const SizedBox(width: 12),
                Text(
                  '📘 ${tr.class1}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: isLoading
                ? ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 4,
              itemBuilder: (_, __) => const ShimmerCard(),
            )
                : GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: courses.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (context, index) {
                final course = courses[index];
                final title = course['title']!;
                final route = course['route']!;
                final icon = getIcon(title);
                final label = getLabel(title, tr);
                final progress = courseProgress[title] ?? 0.0;

                return GestureDetector(
                  onTap: () {
                    final page = getPage(route);
                    if (page != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => page))
                          .then((_) => loadProgress());
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.teal.shade100,
                          child: Icon(icon, size: 30, color: Colors.teal.shade900),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: Colors.grey[300],
                          color: Colors.teal,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${(progress * 100).toStringAsFixed(0)}%",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        )
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
