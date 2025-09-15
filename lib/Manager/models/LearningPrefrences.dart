import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LearningPreferences extends ChangeNotifier {
  List<String> _betterSubjects;
  String _preferredLearningStyle;
  String _studyTimePreference;
  String _difficultyPreference;
  String _goalType;
  String _weeklyGoal;
  String _longTermGoal;

  LearningPreferences({
    List<String> betterSubjects = const [],
    String preferredLearningStyle = "Visual",
    String studyTimePreference = "Morning",
    String difficultyPreference = "Standard",
    String goalType = "Pass Exam",
    String weeklyGoal = "",
    String longTermGoal = "",
  })  : _betterSubjects = betterSubjects,
        _preferredLearningStyle = preferredLearningStyle,
        _studyTimePreference = studyTimePreference,
        _difficultyPreference = difficultyPreference,
        _goalType = goalType,
        _weeklyGoal = weeklyGoal,
        _longTermGoal = longTermGoal;

  // Getters
  List<String> get betterSubjects => _betterSubjects;
  String get preferredLearningStyle => _preferredLearningStyle;
  String get studyTimePreference => _studyTimePreference;
  String get difficultyPreference => _difficultyPreference;
  String get goalType => _goalType;
  String get weeklyGoal => _weeklyGoal;
  String get longTermGoal => _longTermGoal;

  // Setters with notifyListeners
  set betterSubjects(List<String> value) {
    _betterSubjects = value;
    notifyListeners();
  }

  set preferredLearningStyle(String value) {
    _preferredLearningStyle = value;
    notifyListeners();
  }

  set studyTimePreference(String value) {
    _studyTimePreference = value;
    notifyListeners();
  }

  set difficultyPreference(String value) {
    _difficultyPreference = value;
    notifyListeners();
  }

  set goalType(String value) {
    _goalType = value;
    notifyListeners();
  }

  set weeklyGoal(String value) {
    _weeklyGoal = value;
    notifyListeners();
  }

  set longTermGoal(String value) {
    _longTermGoal = value;
    notifyListeners();
  }

  // Convert to Map
  Map<String, dynamic> toMap() => {
    "betterSubjects": _betterSubjects,
    "preferredLearningStyle": _preferredLearningStyle,
    "studyTimePreference": _studyTimePreference,
    "difficultyPreference": _difficultyPreference,
    "goalType": _goalType,
    "weeklyGoal": _weeklyGoal,
    "longTermGoal": _longTermGoal,
  };

  factory LearningPreferences.fromMap(Map<String, dynamic> map) {
    return LearningPreferences(
      betterSubjects: map["betterSubjects"] != null
          ? List<String>.from(map["betterSubjects"])
          : [],
      preferredLearningStyle: map["preferredLearningStyle"] ?? "Visual",
      studyTimePreference: map["studyTimePreference"] ?? "Morning",
      difficultyPreference: map["difficultyPreference"] ?? "Standard",
      goalType: map["goalType"] ?? "Pass Exam",
      weeklyGoal: map["weeklyGoal"] ?? "",
      longTermGoal: map["longTermGoal"] ?? "",
    );
  }

  // SharedPreferences methods using JSON
  static Future<LearningPreferences> fromPrefs(SharedPreferences prefs) async {
    final betterSubjects = prefs.getString('betterSubjects') != null
        ? List<String>.from(jsonDecode(prefs.getString('betterSubjects')!))
        : <String>[];
    return LearningPreferences(
      betterSubjects: betterSubjects,
      preferredLearningStyle:
      prefs.getString('preferredLearningStyle') ?? "Visual",
      studyTimePreference: prefs.getString('studyTimePreference') ?? "Morning",
      difficultyPreference: prefs.getString('difficultyPreference') ?? "Standard",
      goalType: prefs.getString('goalType') ?? "Pass Exam",
      weeklyGoal: prefs.getString('weeklyGoal') ?? "",
      longTermGoal: prefs.getString('longTermGoal') ?? "",
    );
  }

  Future<void> saveToPrefs(SharedPreferences prefs) async {
    await prefs.setString('betterSubjects', jsonEncode(_betterSubjects));
    await prefs.setString('preferredLearningStyle', _preferredLearningStyle);
    await prefs.setString('studyTimePreference', _studyTimePreference);
    await prefs.setString('difficultyPreference', _difficultyPreference);
    await prefs.setString('goalType', _goalType);
    await prefs.setString('weeklyGoal', _weeklyGoal);
    await prefs.setString('longTermGoal', _longTermGoal);
  }

  Future<void> clearPrefs(SharedPreferences prefs) async {
    await prefs.remove('betterSubjects');
    await prefs.remove('preferredLearningStyle');
    await prefs.remove('studyTimePreference');
    await prefs.remove('difficultyPreference');
    await prefs.remove('goalType');
    await prefs.remove('weeklyGoal');
    await prefs.remove('longTermGoal');
  }
}
