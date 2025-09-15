import 'package:flutter/material.dart';
import 'package:mortaalim/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mortaalim/l10n/app_localizations.dart';

import '../../Manager/models/LearningPrefrences.dart';
import '../../User_Input_Info_DataForm/LearningPreferencesForm/LearningPreferencesEnteringForm.dart';
import 'PractiseCoursesSubjects/Arabic1/1_primaire_Arabic_Practise.dart';
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

  LearningPreferences? preferences;
  final List<InfoCardData> infoCards = [];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final loadedPrefs = await LearningPreferences.fromPrefs(prefs);

    setState(() {
      preferences = loadedPrefs;
      _updateInfoCards();
    });
  }

  void _updateInfoCards() {
    if (preferences == null) return;

    infoCards.clear();
    infoCards.addAll([
      InfoCardData(
        title: tr(context).preferredSubject,
        content: preferences!.betterSubjects.isNotEmpty
            ? preferences!.betterSubjects.first
            : "Not set",
        icon: Icons.book,
        color: Colors.orangeAccent,
        subtitle: tr(context).keepUpTheGoodWork,
      ),
      InfoCardData(
        title: tr(context).learningStyle,
        content: preferences!.preferredLearningStyle,
        icon: Icons.psychology_outlined,
        color: Colors.blueAccent,
      ),
      InfoCardData(
        title: tr(context).studyTime,
        content: preferences!.studyTimePreference,
        icon: Icons.access_time,
        color: Colors.green,
      ),
      InfoCardData(
        title: tr(context).difficulty,
        content: preferences!.difficultyPreference,
        icon: Icons.speed,
        color: Colors.redAccent,
      ),
      InfoCardData(
        title: tr(context).goals,
        content: preferences!.goalType,
        icon: Icons.flag_outlined,
        color: Colors.deepPurple,
      ),
    ]);
  }

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
        return tr.science;
      default:
        return tr.class1;
    }
  }

  Future<void> _editPreferences() async {
    if (preferences == null) return;

    final result = await Navigator.push<LearningPreferences>(
      context,
      MaterialPageRoute(
        builder: (_) => LearningPreferencesPages(
          initialPreferences: preferences,
        ),
      ),
    );

    if (result != null) {
      final prefs = await SharedPreferences.getInstance();
      await result.saveToPrefs(prefs);

      setState(() {
        preferences = result;
        _updateInfoCards();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final trLoc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 130,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: infoCards.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final card = infoCards[index];
                    return SizedBox(
                      width: 250,
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
              const SizedBox(height: 12),
              Row( mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    trLoc.practiseCourses,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange.shade700,
                    ),
                  ),

                  IconButton(onPressed: ()
                  {
                    audioManager.playEventSound("clickButton");
                    _editPreferences();
                  },
                      icon: Icon(Icons.edit, size: 30, color: Colors.white,))
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 220,
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
                    final label = getLabel(title, trLoc);
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
            Icon(icon, size: 22, color: Colors.white),
            Text(title,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            Text(content,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            if (subtitle != null) ...[
              Text(subtitle!,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
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
                radius: 42,
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
