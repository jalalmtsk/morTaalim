import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CourseProgressionManager extends ChangeNotifier {
  int courseXp;
  Set<String> badges;

  Map<String, Set<int>> completedSectionsByCourse;
  Map<String, Map<int, int>> sectionCoursePointsByCourse;
  Map<String, int> courseTotalSections;

  static const _kCourseXpKey = 'courseXp';
  static const _kBadgeKey = 'gamified_badges';
  static const _kProgressPrefix = 'gamified_progress';
  static const _kPointsPrefix = 'gamified_points';
  static const _kTotalSectionsKey = 'gamified_total_sections';

  CourseProgressionManager({
    int? courseXp,
    Set<String>? badges,
    Map<String, Set<int>>? completedSectionsByCourse,
    Map<String, Map<int, int>>? sectionCoursePointsByCourse,
    Map<String, int>? courseTotalSections,
  })  : courseXp = courseXp ?? 0,
        badges = badges ?? <String>{},
        completedSectionsByCourse = completedSectionsByCourse ?? <String, Set<int>>{},
        sectionCoursePointsByCourse = sectionCoursePointsByCourse ?? <String, Map<int, int>>{},
        courseTotalSections = courseTotalSections ?? <String, int>{};

  // Factory to load from SharedPreferences
  static Future<CourseProgressionManager> fromPrefs(SharedPreferences prefs) async {
    int xp = prefs.getInt(_kCourseXpKey) ?? 0;
    Set<String> badges = (prefs.getStringList(_kBadgeKey) ?? []).toSet();

    Map<String, Set<int>> completedSectionsByCourse = {};
    Map<String, Map<int, int>> sectionCoursePointsByCourse = {};
    Map<String, int> courseTotalSections = {};



    final keys = prefs.getKeys();

    final courseIds = <String>{};
    for (final key in keys) {
      if (key.startsWith(_kProgressPrefix)) {
        final parts = key.split('_');
        if (parts.length >= 2) {
          courseIds.add(parts.sublist(2).join('_'));
        }
      }
    }

    for (final courseId in courseIds) {
      final completedList = prefs.getStringList('$_kProgressPrefix\_$courseId') ?? [];
      final completedSet = completedList.map((e) => int.tryParse(e) ?? -1).where((i) => i >= 0).toSet();
      completedSectionsByCourse[courseId] = completedSet;

      final pointsList = prefs.getStringList('$_kPointsPrefix\_$courseId') ?? [];
      final pointsMap = <int, int>{};
      for (final s in pointsList) {
        final parts = s.split(':');
        if (parts.length == 2) {
          final idx = int.tryParse(parts[0]) ?? -1;
          final pts = int.tryParse(parts[1]) ?? 0;
          if (idx >= 0) pointsMap[idx] = pts;
        }
      }
      sectionCoursePointsByCourse[courseId] = pointsMap;
    }

    return CourseProgressionManager(
      courseXp: xp,
      badges: badges,
      completedSectionsByCourse: completedSectionsByCourse,
      sectionCoursePointsByCourse: sectionCoursePointsByCourse,
      courseTotalSections: courseTotalSections,
    );
  }

  Future<void> saveToPrefs(SharedPreferences prefs) async {
    await prefs.setInt(_kCourseXpKey, courseXp);
    await prefs.setStringList(_kBadgeKey, badges.toList());

    for (final courseId in completedSectionsByCourse.keys) {
      final completedList = completedSectionsByCourse[courseId]?.map((i) => i.toString()).toList() ?? [];
      await prefs.setStringList('$_kProgressPrefix\_$courseId', completedList);
    }

    for (final courseId in sectionCoursePointsByCourse.keys) {
      final pointsMap = sectionCoursePointsByCourse[courseId] ?? {};
      final pointsList = pointsMap.entries.map((e) => '${e.key}:${e.value}').toList();
      await prefs.setStringList('$_kPointsPrefix\_$courseId', pointsList);
    }

    // TODO: Save courseTotalSections if desired (with JSON encode)
  }

  Map<String, dynamic> toMap() => {
    'courseXp': courseXp,
    'badges': badges.toList(),
    'completedSectionsByCourse': completedSectionsByCourse.map((k, v) => MapEntry(k, v.toList())),
    'sectionCoursePointsByCourse': sectionCoursePointsByCourse.map((k, v) =>
        MapEntry(k, v.map((key, val) => MapEntry(key.toString(), val)))),
    'courseTotalSections': courseTotalSections,
  };

  void loadFromMap(Map<String, dynamic> data) {
    courseXp = data['courseXp'] ?? courseXp;
    badges = Set<String>.from(data['badges'] ?? badges);

    completedSectionsByCourse = (data['completedSectionsByCourse'] as Map<String, dynamic>?)
        ?.map((k, v) => MapEntry(k, Set<int>.from(v))) ??
        completedSectionsByCourse;

    sectionCoursePointsByCourse =
        (data['sectionCoursePointsByCourse'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k,
            (v as Map<String, dynamic>).map((key, val) => MapEntry(int.parse(key), val)))) ??
            sectionCoursePointsByCourse;

    courseTotalSections = (data['courseTotalSections'] as Map<String, dynamic>?)
        ?.map((k, v) => MapEntry(k, v)) ??
        courseTotalSections;

    notifyListeners();
  }

  // Getters

  int getCourseXp() => courseXp;

  Set<String> getBadges() => badges;

  Set<int> getCompletedSections(String courseId) => completedSectionsByCourse[courseId] ?? {};

  Map<int, int> getSectionPoints(String courseId) => sectionCoursePointsByCourse[courseId] ?? {};

  int getTotalSections(String courseId) => courseTotalSections[courseId] ?? 0;

  double getProgress(String courseId) {
    final total = getTotalSections(courseId);
    if (total == 0) return 0.0;
    final completed = getCompletedSections(courseId).length;
    return (completed / total).clamp(0.0, 1.0);
  }

  // Set total sections for a course
  void setTotalSections(String courseId, int total) {
    courseTotalSections[courseId] = total;
    notifyListeners();
  }


  void setTotalSectionsBatch(Map<String, int> totals) {
    courseTotalSections.addAll(totals);
    notifyListeners();
  }


  // Mark section as completed for a course
  Future<void> completeSection(String courseId, int sectionIndex, int subsectionCount) async {
    final completed = completedSectionsByCourse.putIfAbsent(courseId, () => <int>{});
    final points = sectionCoursePointsByCourse.putIfAbsent(courseId, () => <int, int>{});

    if (completed.contains(sectionIndex)) return;

    int pts = 1;
    if (subsectionCount > 1) {
      pts = Random().nextInt(3) + 1;
    }

    completed.add(sectionIndex);
    points[sectionIndex] = pts;

    addCourseXp(pts * 5);

    final prefs = await SharedPreferences.getInstance();
    await saveToPrefs(prefs);

    notifyListeners();
  }

  // Add LP and award badges if thresholds met
  void addCourseXp(int amount) {
    courseXp += amount;

    // LP thresholds mapped to badge names
    final badgeLevels = {
      0: 'beginnerReader',
      30: 'curiousMind',
      60: 'bookLover',
      100: 'knowledgeSeeker',
      150: 'quizExpert',
      200: 'studyMaster',
      250: 'truthDiscoverer',
      300: 'intelligent',
      350: 'theorist',
      400: 'masterOfLogic',
      450: 'keeperOfWisdom',
      500: 'ideaArchitect',
      600: 'thoughtLeader',
      700: 'mindMentor',
      800: 'wizardOfWisdom',
      900: 'learningLegend',
      1200: 'sageOfTruth',
      1500: 'greatScholar',
      2000: 'pinnacleOfKnowledge',
    };


    // Award all eligible badges
    badgeLevels.forEach((xpRequired, badgeName) {
      if (courseXp >= xpRequired && !badges.contains(badgeName)) {
        badges.add(badgeName);
      }
    });

    // Save badges and XP
    SharedPreferences.getInstance().then((prefs) => saveToPrefs(prefs));
    notifyListeners();
  }

  // Reset all progress data
  Future<void> resetProgress() async {
    courseXp = 0;
    badges.clear();
    completedSectionsByCourse.clear();
    sectionCoursePointsByCourse.clear();
    courseTotalSections.clear();

    final prefs = await SharedPreferences.getInstance();

    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_kProgressPrefix) || key.startsWith(_kPointsPrefix)) {
        await prefs.remove(key);
      }
    }
    await prefs.remove(_kCourseXpKey);
    await prefs.remove(_kBadgeKey);
    // TODO: remove total sections key if saved

    notifyListeners();
  }


  Future<void> loadFromJsonString(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      loadFromMap(data);
    } catch (e) {
      print('Error parsing JSON: $e');
      // Handle error (e.g., fallback or reset)
    }
  }
}
