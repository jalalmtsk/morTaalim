import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Manager/models/LearningPrefrences.dart';
import '../../l10n/app_localizations.dart';
import '../../tools/audio_tool/Audio_Manager.dart';

class LearningPreferencesPages extends StatefulWidget {
  final LearningPreferences? initialPreferences;

  const LearningPreferencesPages({Key? key, this.initialPreferences})
      : super(key: key);

  @override
  _LearningPreferencesPagesState createState() =>
      _LearningPreferencesPagesState();
}

class _LearningPreferencesPagesState extends State<LearningPreferencesPages> {
  int _currentStep = 0;
  late LearningPreferences preferences;

  final TextEditingController weeklyGoalController = TextEditingController();
  final TextEditingController longTermGoalController = TextEditingController();

  final List<String> availableSubjects = [
    "Math",
    "Arabic",
    "English",
    "French",
    "Science",
    "Islamic Education",
    "Art",
  ];

  @override
  void initState() {
    super.initState();
    preferences = widget.initialPreferences ?? LearningPreferences();
    weeklyGoalController.text = preferences.weeklyGoal;
    longTermGoalController.text = preferences.longTermGoal;
  }

  @override
  void dispose() {
    weeklyGoalController.dispose();
    longTermGoalController.dispose();
    super.dispose();
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await preferences.saveToPrefs(prefs);
  }

  bool _isStepComplete(int step) {
    switch (step) {
      case 0:
        return preferences.betterSubjects.isNotEmpty;
      case 1:
        return preferences.preferredLearningStyle.isNotEmpty;
      case 2:
        return preferences.studyTimePreference.isNotEmpty;
      case 3:
        return preferences.difficultyPreference.isNotEmpty;
      case 4:
        return preferences.goalType.isNotEmpty &&
            weeklyGoalController.text.trim().isNotEmpty &&
            longTermGoalController.text.trim().isNotEmpty;
      default:
        return false;
    }
  }

  InputDecoration _lightGreenInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.green.shade700, fontSize: 14),
      filled: true,
      fillColor: Colors.green.shade50,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.green.shade400, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.green.shade200, width: 1.5),
      ),
    );
  }

  Widget _buildStepContent({
    required String lottieAsset,
    required Widget child,
  }) {
    return Column(
      children: [
        Lottie.asset(lottieAsset, height: 160, repeat: true),
        const SizedBox(height: 20),
        child,
      ],
    );
  }

  void _updateWeeklyGoal(String value) {
    setState(() {
      preferences.weeklyGoal = value;
      _savePrefs();
    });
  }

  void _updateLongTermGoal(String value) {
    setState(() {
      preferences.longTermGoal = value;
      _savePrefs();
    });
  }

  void _updatePreference(String key, String value) {
    setState(() {
      switch (key) {
        case "learningStyle":
          preferences.preferredLearningStyle = value;
          break;
        case "studyTime":
          preferences.studyTimePreference = value;
          break;
        case "difficulty":
          preferences.difficultyPreference = value;
          break;
        case "goalType":
          preferences.goalType = value;
          break;
      }
      _savePrefs();
    });
  }

  void _updateSubjects(String subject) {
    setState(() {
      preferences.betterSubjects = [subject];
      _savePrefs();
    });
  }

  void _saveAndClose() {
    preferences.weeklyGoal = weeklyGoalController.text;
    preferences.longTermGoal = longTermGoalController.text;
    _savePrefs();
    Navigator.pop(context, preferences);
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final audioManager = Provider.of<AudioManager>(context, listen: false);

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.green.shade50,
        appBar: AppBar(
          title: Text(tr.learningPreferences),
          backgroundColor: Colors.green.shade400,
          automaticallyImplyLeading: false,
          elevation: 0,
        ),
        body: SafeArea(
          child: Stepper(
            type: StepperType.vertical,
            currentStep: _currentStep,
            onStepContinue: () {
              if (_currentStep < 4) {
                if (_isStepComplete(_currentStep)) {
                  audioManager.playEventSound('clickButton');
                  setState(() => _currentStep += 1);
                }
              } else if (_isStepComplete(_currentStep)) {
                audioManager.playEventSound('clickButton');
                _saveAndClose();
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                audioManager.playEventSound('clickButton');
                setState(() => _currentStep -= 1);
              }
            },
            controlsBuilder: (context, details) {
              final isLastStep = _currentStep == 4;
              final canContinue = _isStepComplete(_currentStep);

              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: canContinue
                          ? () {
                        audioManager.playEventSound('clickButton');
                        details.onStepContinue!();
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canContinue
                            ? Colors.green.shade500
                            : Colors.green.shade200,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: canContinue ? 2 : 0,
                      ),
                      child: Text(isLastStep ? tr.save : tr.next),
                    ),
                    const SizedBox(width: 12),
                    if (_currentStep > 0)
                      OutlinedButton(
                        onPressed: () {
                          audioManager.playEventSound('clickButton');
                          details.onStepCancel!();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green.shade800,
                          side: BorderSide(color: Colors.green.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(tr.back),
                      ),
                  ],
                ),
              );
            },
            steps: [
              // Subjects
              Step(
                title: Text(tr.subjects),
                content: _buildStepContent(
                  lottieAsset:
                  "assets/animations/FirstTouchAnimations/BulbBook.json",
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: availableSubjects.map((subject) {
                      final isSelected = preferences.betterSubjects.contains(subject);
                      return GestureDetector(
                        onTap: () {
                          audioManager.playEventSound('clickButton');
                          _updateSubjects(subject);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 18),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.green.shade400
                                : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: Colors.green.shade300,
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                            ],
                          ),
                          child: Text(
                            subject,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.green.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                isActive: _currentStep == 0,
              ),
              // Learning Style
              Step(
                title: Text(tr.learningStyle),
                content: _buildStepContent(
                  lottieAsset:
                  "assets/animations/FirstTouchAnimations/Educatin.json",
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        value: tr.visual,
                        groupValue: preferences.preferredLearningStyle,
                        activeColor: Colors.green.shade400,
                        onChanged: (val) => _updatePreference("learningStyle", val!),
                        title: Text(tr.visual,
                            style: TextStyle(color: Colors.green.shade700)),
                      ),
                      RadioListTile<String>(
                        value: tr.auditory,
                        groupValue: preferences.preferredLearningStyle,
                        activeColor: Colors.green.shade400,
                        onChanged: (val) => _updatePreference("learningStyle", val!),
                        title: Text(tr.auditory,
                            style: TextStyle(color: Colors.green.shade700)),
                      ),
                      RadioListTile<String>(
                        value: tr.kinesthetic,
                        groupValue: preferences.preferredLearningStyle,
                        activeColor: Colors.green.shade400,
                        onChanged: (val) => _updatePreference("learningStyle", val!),
                        title: Text(tr.kinesthetic,
                            style: TextStyle(color: Colors.green.shade700)),
                      ),
                    ],
                  ),
                ),
                isActive: _currentStep == 1,
              ),
              // Study Time
              Step(
                title: Text(tr.studyTime),
                content: _buildStepContent(
                  lottieAsset: "assets/animations/girl_studying.json",
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        value: tr.morning,
                        groupValue: preferences.studyTimePreference,
                        activeColor: Colors.green.shade400,
                        onChanged: (val) => _updatePreference("studyTime", val!),
                        title: Text(tr.morning,
                            style: TextStyle(color: Colors.green.shade700)),
                      ),
                      RadioListTile<String>(
                        value: tr.afternoon,
                        groupValue: preferences.studyTimePreference,
                        activeColor: Colors.green.shade400,
                        onChanged: (val) => _updatePreference("studyTime", val!),
                        title: Text(tr.afternoon,
                            style: TextStyle(color: Colors.green.shade700)),
                      ),
                      RadioListTile<String>(
                        value: tr.evening,
                        groupValue: preferences.studyTimePreference,
                        activeColor: Colors.green.shade400,
                        onChanged: (val) => _updatePreference("studyTime", val!),
                        title: Text(tr.evening,
                            style: TextStyle(color: Colors.green.shade700)),
                      ),
                    ],
                  ),
                ),
                isActive: _currentStep == 2,
              ),
              // Difficulty
              Step(
                title: Text(tr.difficulty),
                content: _buildStepContent(
                  lottieAsset:
                  "assets/animations/FirstTouchAnimations/BulbBook.json",
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        value: tr.standard,
                        groupValue: preferences.difficultyPreference,
                        activeColor: Colors.green.shade400,
                        onChanged: (val) => _updatePreference("difficulty", val!),
                        title: Text(tr.standard,
                            style: TextStyle(color: Colors.green.shade700)),
                      ),
                      RadioListTile<String>(
                        value: tr.advanced,
                        groupValue: preferences.difficultyPreference,
                        activeColor: Colors.green.shade400,
                        onChanged: (val) => _updatePreference("difficulty", val!),
                        title: Text(tr.advanced,
                            style: TextStyle(color: Colors.green.shade700)),
                      ),
                      RadioListTile<String>(
                        value: tr.adaptive,
                        groupValue: preferences.difficultyPreference,
                        activeColor: Colors.green.shade400,
                        onChanged: (val) => _updatePreference("difficulty", val!),
                        title: Text(tr.adaptive,
                            style: TextStyle(color: Colors.green.shade700)),
                      ),
                    ],
                  ),
                ),
                isActive: _currentStep == 3,
              ),
              // Goals
              Step(
                title: Text(tr.goals),
                content: _buildStepContent(
                  lottieAsset: "assets/animations/superhero.json",
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        value: tr.passExam,
                        groupValue: preferences.goalType,
                        activeColor: Colors.green.shade400,
                        onChanged: (val) => _updatePreference("goalType", val!),
                        title: Text(tr.passExam,
                            style: TextStyle(color: Colors.green.shade700)),
                      ),
                      RadioListTile<String>(
                        value: tr.improveSkills,
                        groupValue: preferences.goalType,
                        activeColor: Colors.green.shade400,
                        onChanged: (val) => _updatePreference("goalType", val!),
                        title: Text(tr.improveSkills,
                            style: TextStyle(color: Colors.green.shade700)),
                      ),
                      RadioListTile<String>(
                        value: tr.getCertified,
                        groupValue: preferences.goalType,
                        activeColor: Colors.green.shade400,
                        onChanged: (val) => _updatePreference("goalType", val!),
                        title: Text(tr.getCertified,
                            style: TextStyle(color: Colors.green.shade700)),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: weeklyGoalController,
                        onChanged: _updateWeeklyGoal,
                        decoration: _lightGreenInputDecoration(tr.weeklyGoal),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: longTermGoalController,
                        onChanged: _updateLongTermGoal,
                        decoration: _lightGreenInputDecoration(tr.longTermGoal),
                      ),
                    ],
                  ),
                ),
                isActive: _currentStep == 4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
