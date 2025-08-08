class LearningPreferences {
  String classLevel;
  List<String> betterSubjects;
  String preferredLearningStyle; // "Visual", "Auditory", etc.
  String studyTimePreference;    // "Morning", "Afternoon", etc.
  String difficultyPreference;   // "Standard", "Advanced", "Adaptive"
  String goalType;               // "Pass Exam", etc.
  String weeklyGoal;
  String longTermGoal;

  LearningPreferences({
    this.classLevel = "",
    this.betterSubjects = const [],
    this.preferredLearningStyle = "Visual",
    this.studyTimePreference = "Morning",
    this.difficultyPreference = "Standard",
    this.goalType = "Pass Exam",
    this.weeklyGoal = "",
    this.longTermGoal = "",
  });

  Map<String, dynamic> toMap() {
    return {
      "classLevel": classLevel,
      "betterSubjects": betterSubjects,
      "preferredLearningStyle": preferredLearningStyle,
      "studyTimePreference": studyTimePreference,
      "difficultyPreference": difficultyPreference,
      "goalType": goalType,
      "weeklyGoal": weeklyGoal,
      "longTermGoal": longTermGoal,
    };
  }

  factory LearningPreferences.fromMap(Map<String, dynamic> map) {
    return LearningPreferences(
      classLevel: map["classLevel"] ?? "",
      betterSubjects: List<String>.from(map["betterSubjects"] ?? []),
      preferredLearningStyle: map["preferredLearningStyle"] ?? "Visual",
      studyTimePreference: map["studyTimePreference"] ?? "Morning",
      difficultyPreference: map["difficultyPreference"] ?? "Standard",
      goalType: map["goalType"] ?? "Pass Exam",
      weeklyGoal: map["weeklyGoal"] ?? "",
      longTermGoal: map["longTermGoal"] ?? "",
    );
  }
}
