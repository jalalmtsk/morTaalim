import 'package:flutter/material.dart';
import 'package:mortaalim/courses/primaire1Page/PractiseCoursesSubjects/IslamicEducation1/1_primaire_IslamicEducation_Practise.dart';
import 'package:mortaalim/widgets/shimmerPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import 'PractiseCoursesSubjects/French1/1_primaire_French_Practise.dart';
import 'PractiseCoursesSubjects/Math1/1_primaire_Math_Practise.dart';
import 'PractiseCoursesSubjects/Science1/1_primaire_Science_Practise.dart';

// 👇 Import your course pages


class primaire1Pratique extends StatefulWidget {
  const primaire1Pratique({Key? key}) : super(key: key);

  @override
  _Primaire1StatePratique createState() => _Primaire1StatePratique();
}

class _Primaire1StatePratique extends State<primaire1Pratique> {
  final List<Map<String, String>> courses = [
    {'title': 'math', 'route': 'IndexMath1Practise'},
    {'title': 'french', 'route': 'IndexFrench1Practise'},
    {'title': 'arabic', 'route': 'arabicCourse'},
    {'title': 'islamicEducation', 'route': 'IndexIslamicEducation1Practise'},
    {'title': 'science', 'route': 'IndexScience1Practise'},
  ];

  Map<String, double> courseProgress = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProgressForCourses();
  }

  Future<void> loadProgressForCourses() async {
    final prefs = await SharedPreferences.getInstance();
    for (var course in courses) {
      final courseId = course['title']!;
      final saved = prefs.getStringList('progress2_$courseId') ?? [];
      final total = 10;
      final progress = total > 0 ? saved.length / total : 0.0;
      courseProgress[courseId] = progress;
    }
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      isLoading = false;
    });
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
      case 'science':
        return Icons.science;
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
      case 'science':
        return tr.artEducation;
      default:
        return tr.class6;
    }
  }

  Widget? getCoursePage(String route) {
    switch (route) {
      case 'IndexMath1Practise':
        return  IndexMath1Practise();
        case 'IndexFrench1Practise':
          return  IndexFrench1Practise();
      case 'IndexScience1Practise':
        return  IndexScience1Practise();
      case 'IndexIslamicEducation1Practise':
        return  IndexIslamicEducation1Practise();

      default:
        return null;
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
          ),
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
                  final routeName = course['route']!;
                  final icon = getCourseIcon(title);
                  final percent = courseProgress[title] ?? 0.0;
                  final percentText = (percent * 100).toStringAsFixed(0);

                  return TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: percent),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, double value, child) {
                      return GestureDetector(
                        onTap: () {
                          final page = getCoursePage(routeName);
                          if (page != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => page),
                            ).then((_) => loadProgressForCourses());
                          }
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
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.4),
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
