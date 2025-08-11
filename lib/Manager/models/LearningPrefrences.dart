import 'package:shared_preferences/shared_preferences.dart';

class LearningPreferences {
  List<String> _betterSubjects;
  String _preferredLearningStyle; // e.g. "Visual", "Auditory"
  String _studyTimePreference;    // e.g. "Morning", "Afternoon"
  String _difficultyPreference;   // e.g. "Standard", "Advanced", "Adaptive"
  String _goalType;               // e.g. "Pass Exam"
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

  // Setters
  set betterSubjects(List<String> value) => _betterSubjects = value;
  set preferredLearningStyle(String value) => _preferredLearningStyle = value;
  set studyTimePreference(String value) => _studyTimePreference = value;
  set difficultyPreference(String value) => _difficultyPreference = value;
  set goalType(String value) => _goalType = value;
  set weeklyGoal(String value) => _weeklyGoal = value;
  set longTermGoal(String value) => _longTermGoal = value;

  // Convert to Map for storage/serialization
  Map<String, dynamic> toMap() {
    return {
      "betterSubjects": _betterSubjects,
      "preferredLearningStyle": _preferredLearningStyle,
      "studyTimePreference": _studyTimePreference,
      "difficultyPreference": _difficultyPreference,
      "goalType": _goalType,
      "weeklyGoal": _weeklyGoal,
      "longTermGoal": _longTermGoal,
    };
  }

  // Create from Map
  factory LearningPreferences.fromMap(Map<String, dynamic> map) {
    return LearningPreferences(
      betterSubjects: map["betterSubjects"] != null ? List<String>.from(map["betterSubjects"]) : [],
      preferredLearningStyle: map["preferredLearningStyle"] ?? "Visual",
      studyTimePreference: map["studyTimePreference"] ?? "Morning",
      difficultyPreference: map["difficultyPreference"] ?? "Standard",
      goalType: map["goalType"] ?? "Pass Exam",
      weeklyGoal: map["weeklyGoal"] ?? "",
      longTermGoal: map["longTermGoal"] ?? "",
    );
  }

  // Load from SharedPreferences
  static Future<LearningPreferences> fromPrefs(SharedPreferences prefs) async {
    final betterSubjectsStr = prefs.getString('betterSubjects') ?? "";
    final betterSubjects = betterSubjectsStr.isNotEmpty ? betterSubjectsStr.split(',') : <String>[];
    final preferredLearningStyle = prefs.getString('preferredLearningStyle') ?? "Visual";
    final studyTimePreference = prefs.getString('studyTimePreference') ?? "Morning";
    final difficultyPreference = prefs.getString('difficultyPreference') ?? "Standard";
    final goalType = prefs.getString('goalType') ?? "Pass Exam";
    final weeklyGoal = prefs.getString('weeklyGoal') ?? "";
    final longTermGoal = prefs.getString('longTermGoal') ?? "";

    return LearningPreferences(
      betterSubjects: betterSubjects,
      preferredLearningStyle: preferredLearningStyle,
      studyTimePreference: studyTimePreference,
      difficultyPreference: difficultyPreference,
      goalType: goalType,
      weeklyGoal: weeklyGoal,
      longTermGoal: longTermGoal,
    );
  }

  // Save to SharedPreferences
  Future<void> saveToPrefs(SharedPreferences prefs) async {
    await prefs.setString('betterSubjects', _betterSubjects.join(','));
    await prefs.setString('preferredLearningStyle', _preferredLearningStyle);
    await prefs.setString('studyTimePreference', _studyTimePreference);
    await prefs.setString('difficultyPreference', _difficultyPreference);
    await prefs.setString('goalType', _goalType);
    await prefs.setString('weeklyGoal', _weeklyGoal);
    await prefs.setString('longTermGoal', _longTermGoal);
  }

  // Clear all preferences
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
