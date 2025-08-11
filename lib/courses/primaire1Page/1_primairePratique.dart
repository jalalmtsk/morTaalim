import 'package:flutter/material.dart';
import 'package:mortaalim/courses/primaire1Page/PractiseCoursesSubjects/Arabic1/1_primaire_Arabic_Practise.dart';
import 'package:mortaalim/l10n/app_localizations.dart';

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
  final List<Map<String, dynamic>> courses = [
    {'title': 'arabic', 'route': 'IndexArabic1Practise', 'color': Colors.purpleAccent},
    {'title': 'math', 'route': 'IndexMath1Practise', 'color': Colors.orangeAccent},
    {'title': 'french', 'route': 'IndexFrench1Practise', 'color': Colors.lightBlueAccent},
    {'title': 'islamicEducation', 'route': 'IndexIslamicEducation1Practise', 'color': Colors.greenAccent},
    {'title': 'science', 'route': 'IndexScience1Practise', 'color': Colors.purpleAccent},
  ];

  IconData getIcon(String key) {
    switch (key) {
      case 'math':
        return Icons.calculate_rounded;
      case 'french':
        return Icons.language;
      case 'arabic':
        return Icons.offline_bolt_outlined;
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
        return const IndexMath1Practise();
      case 'IndexFrench1Practise':
        return IndexFrench1Practise();
      case 'IndexArabic1Practise':
        return IndexArabic1Practise();
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
      case 'arabic':
        return tr.arabic;
      case 'islamicEducation':
        return tr.islamicEducation;
      case 'science':
        return tr.artEducation;
      default:
        return tr.class1;
    }
  }

  // Example dynamic info cards data, easy to extend:
  final List<InfoCardData> infoCards = [];

  @override
  void initState() {
    super.initState();

    // Initialize your cards data (can come from API or user settings)
    infoCards.addAll([
      InfoCardData(
        title: 'Preferred Subject',
        content: 'Math',
        icon: Icons.calculate_rounded,
        color: Colors.orangeAccent,
        subtitle: 'Keep up the good work!',
      ),
      InfoCardData(
        title: 'Class Level',
        content: '1ère Primaire',
        icon: Icons.school_outlined,
        color: Colors.deepOrangeAccent,
      ),
      InfoCardData(
        title: 'Next Exam',
        content: '12 Sep 2025',
        icon: Icons.event_note_outlined,
        color: Colors.lightBlueAccent,
      ),
      InfoCardData(
        title: 'Progress',
        content: '67%',
        icon: Icons.show_chart_rounded,
        color: Colors.green,
        subtitle: 'Keep going!',
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xfffef9f4),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title for info cards section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'Your Dashboard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.deepOrange.shade700,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Horizontal scrollable info cards
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: infoCards.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final card = infoCards[index];
                    return SizedBox(
                      width: 200, // fixed width for uniformity
                      child: _InfoCard(
                        title: card.title,
                        content: card.content,
                        icon: card.icon,
                        color: card.color,
                        subtitle: card.subtitle,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // Title for practice courses
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'Practice Courses',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange.shade700,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: courses.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    final title = course['title'] as String;
                    final route = course['route'] as String;
                    final icon = getIcon(title);
                    final label = getLabel(title, tr);
                    final color = course['color'] as Color;

                    return _CourseCard(
                      color: color,
                      icon: icon,
                      label: label,
                      onTap: () {
                        final page = getPage(route);
                        if (page != null) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
                        }
                      },
                    );
                  },
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}

/// Data class for info card parameters
class InfoCardData {
  final String title;
  final String content;
  final IconData icon;
  final Color color;
  final String? subtitle;

  InfoCardData({
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
    this.subtitle,
  });
}

/// Reusable Info Card Widget with optional subtitle
class _InfoCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const _InfoCard({
    Key? key,
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
    this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      shadowColor: color.withOpacity(0.4),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.85), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              content,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

/// Horizontal course card for practice courses
class _CourseCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CourseCard({
    Key? key,
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      shadowColor: color.withOpacity(0.4),
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        splashColor: Colors.white30,
        onTap: onTap,
        child: Container(
          width: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.85), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
          ),
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 38,
                backgroundColor: Colors.white,
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(1, 1),
                      blurRadius: 4,
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
