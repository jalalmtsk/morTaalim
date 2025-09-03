import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Manager/models/LearningPrefrences.dart';

class LearningPreferencesPage extends StatefulWidget {
  @override
  _LearningPreferencesPageState createState() => _LearningPreferencesPageState();
}

class _LearningPreferencesPageState extends State<LearningPreferencesPage>
    with SingleTickerProviderStateMixin {
  late LearningPreferences _preferences;
  bool _isLoading = true;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  // Controllers
  final TextEditingController weeklyGoalController = TextEditingController();
  final TextEditingController longTermGoalController = TextEditingController();
  final TextEditingController subjectsController = TextEditingController();

  final List<String> learningStyles = ["Visual", "Auditory", "Kinesthetic"];
  final List<String> studyTimes = ["Morning", "Afternoon", "Evening"];
  final List<String> difficultyLevels = ["Standard", "Advanced", "Adaptive"];
  final List<String> goalTypes = ["Pass Exam", "Improve Skills", "Get Certified"];

  String selectedLearningStyle = "Visual";
  String selectedStudyTime = "Morning";
  String selectedDifficulty = "Standard";
  String selectedGoalType = "Pass Exam";

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(seconds: 1));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final loadedPrefs = await LearningPreferences.fromPrefs(prefs);
    setState(() {
      _preferences = loadedPrefs;
      selectedLearningStyle = loadedPrefs.preferredLearningStyle;
      selectedStudyTime = loadedPrefs.studyTimePreference;
      selectedDifficulty = loadedPrefs.difficultyPreference;
      selectedGoalType = loadedPrefs.goalType;
      weeklyGoalController.text = loadedPrefs.weeklyGoal;
      longTermGoalController.text = loadedPrefs.longTermGoal;
      subjectsController.text = loadedPrefs.betterSubjects.join(", ");
      _isLoading = false;
      _controller.forward();
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _preferences
      ..betterSubjects = subjectsController.text.split(",").map((s) => s.trim()).toList()
      ..preferredLearningStyle = selectedLearningStyle
      ..studyTimePreference = selectedStudyTime
      ..difficultyPreference = selectedDifficulty
      ..goalType = selectedGoalType
      ..weeklyGoal = weeklyGoalController.text
      ..longTermGoal = longTermGoalController.text;

    await _preferences.saveToPrefs(prefs);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Preferences Saved! 🎉"),
        backgroundColor: Colors.greenAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _glassCard({required String title, required IconData icon, required Widget child}) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            margin: EdgeInsets.only(bottom: 20),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      title,
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: Colors.white),
    filled: true,
    fillColor: Colors.white.withOpacity(0.1),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
      borderRadius: BorderRadius.circular(12),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.blueAccent, Colors.teal],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(height: 20),
                Text(
                  "Your Learning Preferences",
                  style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 30),
                _glassCard(
                  title: "Subjects",
                  icon: Icons.book,
                  child: TextField(
                    controller: subjectsController,
                    style: TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Better Subjects (comma separated)"),
                  ),
                ),
                _glassCard(
                  title: "Learning Style",
                  icon: Icons.style,
                  child: DropdownButtonFormField<String>(
                    value: selectedLearningStyle,
                    dropdownColor: Colors.black54,
                    style: TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Select Style"),
                    items: learningStyles
                        .map((style) => DropdownMenuItem(
                        value: style, child: Text(style, style: TextStyle(color: Colors.white))))
                        .toList(),
                    onChanged: (val) => setState(() => selectedLearningStyle = val!),
                  ),
                ),
                _glassCard(
                  title: "Study Time",
                  icon: Icons.access_time,
                  child: DropdownButtonFormField<String>(
                    value: selectedStudyTime,
                    dropdownColor: Colors.black54,
                    style: TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Select Time"),
                    items: studyTimes
                        .map((time) => DropdownMenuItem(
                        value: time, child: Text(time, style: TextStyle(color: Colors.white))))
                        .toList(),
                    onChanged: (val) => setState(() => selectedStudyTime = val!),
                  ),
                ),
                _glassCard(
                  title: "Difficulty",
                  icon: Icons.bolt,
                  child: DropdownButtonFormField<String>(
                    value: selectedDifficulty,
                    dropdownColor: Colors.black54,
                    style: TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Select Difficulty"),
                    items: difficultyLevels
                        .map((level) => DropdownMenuItem(
                        value: level, child: Text(level, style: TextStyle(color: Colors.white))))
                        .toList(),
                    onChanged: (val) => setState(() => selectedDifficulty = val!),
                  ),
                ),
                _glassCard(
                  title: "Goals",
                  icon: Icons.flag,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedGoalType,
                        dropdownColor: Colors.black54,
                        style: TextStyle(color: Colors.white),
                        decoration: _inputDecoration("Goal Type"),
                        items: goalTypes
                            .map((goal) => DropdownMenuItem(
                            value: goal,
                            child: Text(goal, style: TextStyle(color: Colors.white))))
                            .toList(),
                        onChanged: (val) => setState(() => selectedGoalType = val!),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: weeklyGoalController,
                        style: TextStyle(color: Colors.white),
                        decoration: _inputDecoration("Weekly Goal"),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: longTermGoalController,
                        style: TextStyle(color: Colors.white),
                        decoration: _inputDecoration("Long Term Goal"),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                GestureDetector(
                  onTap: _savePreferences,
                  child: Container(
                    width: double.infinity,
                    height: 55,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.tealAccent, Colors.blueAccent]),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        "SAVE PREFERENCES",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
