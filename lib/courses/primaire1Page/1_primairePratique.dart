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
    {
      'title': 'arabic',
      'route': 'IndexArabic1Practise',
      'image': 'assets/images/UI/BackGrounds/Course_BG/arabicCourse_bg.png',
      'color': Colors.purpleAccent
    },
    {
      'title': 'math',
      'route': 'IndexMath1Practise',
      'image': 'assets/images/UI/BackGrounds/Course_BG/mathCourse_bg.png',
      'color': Colors.orangeAccent
    },
    {
      'title': 'french',
      'route': 'IndexFrench1Practise',
      'image': 'assets/images/UI/BackGrounds/Course_BG/frenchCourse_bg.png',
      'color': Colors.lightBlueAccent
    },
    {
      'title': 'islamicEducation',
      'route': 'IndexIslamicEducation1Practise',
      'image': 'assets/images/UI/BackGrounds/Course_BG/islamCourse_bg.png',
      'color': Colors.greenAccent
    },
    {
      'title': 'science',
      'route': 'IndexScience1Practise',
      'image': 'assets/images/UI/BackGrounds/Course_BG/scienceCourse_bg.png',
      'color': Colors.purpleAccent
    },
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

  final List<InfoCardData> infoCards = [];

  @override
  void initState() {
    super.initState();
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
                      width: 200,
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
                    final image = course['image'] as String;
                    final color = course['color'] as Color;

                    return _CourseCard(
                      imagePath: image,
                      overlayColor: color,
                      icon: icon,
                      label: label,
                      onTap: () {
                        final page = getPage(route);
                        if (page != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => page),
                          );
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

class _InfoCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const _InfoCard({
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
    this.subtitle,
  });

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
            Text(title,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(content,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ]
          ],
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final String imagePath;
  final Color overlayColor;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CourseCard({
    required this.imagePath,
    required this.overlayColor,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      shadowColor: overlayColor.withOpacity(0.4),
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        splashColor: Colors.white30,
        onTap: onTap,
        child: Container(
          width: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                overlayColor.withOpacity(0.3),
                BlendMode.darken,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 38,
                backgroundColor: Colors.white,
                child: Icon(icon, size: 40, color: overlayColor),
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
