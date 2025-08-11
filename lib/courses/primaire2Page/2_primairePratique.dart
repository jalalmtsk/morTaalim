import 'package:flutter/material.dart';
import 'package:mortaalim/courses/primaire1Page/PractiseCoursesSubjects/French1/1_primaire_French_Practise.dart';
import 'package:mortaalim/courses/primaire1Page/PractiseCoursesSubjects/IslamicEducation1/1_primaire_IslamicEducation_Practise.dart';
import 'package:mortaalim/courses/primaire1Page/PractiseCoursesSubjects/Math1/1_primaire_Math_Practise.dart';
import 'package:mortaalim/courses/primaire1Page/PractiseCoursesSubjects/Science1/1_primaire_Science_Practise.dart';
import 'package:mortaalim/l10n/app_localizations.dart';

// Make sure you have these 2nd grade practise pages ready and imported correctly

class Primaire2Pratique extends StatefulWidget {
  const Primaire2Pratique({super.key});

  @override
  State<Primaire2Pratique> createState() => _Primaire2PratiqueState();
}

class _Primaire2PratiqueState extends State<Primaire2Pratique> {
  final List<Map<String, dynamic>> courses = [
    {'title': 'math', 'route': 'IndexMath2Practise', 'color': Colors.orangeAccent},
    {'title': 'french', 'route': 'IndexFrench2Practise', 'color': Colors.lightBlueAccent},
    {'title': 'islamicEducation', 'route': 'IndexIslamicEducation2Practise', 'color': Colors.greenAccent},
    {'title': 'science', 'route': 'IndexScience2Practise', 'color': Colors.purpleAccent},
  ];

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
      case 'IndexMath2Practise':
        return const IndexMath1Practise();
      case 'IndexFrench2Practise':
        return IndexFrench1Practise();
      case 'IndexScience2Practise':
        return IndexScience1Practise();
      case 'IndexIslamicEducation2Practise':
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
        return tr.artEducation;  // You can adjust if you have a specific label for science
      default:
        return tr.class2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xfffef9f4),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xffffd54f), Color(0xffffb300)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.school, color: Colors.white, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '📚 ${tr.class2} - Practise',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(1, 1),
                          blurRadius: 2,
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Grid of courses
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: courses.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 18,
                crossAxisSpacing: 18,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final course = courses[index];
                final title = course['title'] as String;
                final route = course['route'] as String;
                final icon = getIcon(title);
                final label = getLabel(title, tr);
                final color = course['color'] as Color;

                return Material(
                  borderRadius: BorderRadius.circular(26),
                  elevation: 6,
                  shadowColor: color.withOpacity(0.4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(26),
                    splashColor: Colors.white30,
                    onTap: () {
                      final page = getPage(route);
                      if (page != null) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.withOpacity(0.85), color],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: Colors.white,
                            child: Icon(icon, size: 40, color: color),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            label,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(1, 1),
                                  blurRadius: 3,
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
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
