import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(const MaterialApp(home: DashboardPage()));
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  final FlutterTts _tts = FlutterTts();
  bool _muted = false;
  int _xp = 150;
  Set<String> badges = {'starter', 'point_collector'};

  // Simulated course sections for carousel
  final List<String> sections = ['Courses', 'Learning Preferences', 'Goals & Progress'];

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _configureTts();
  }

  Future<void> _configureTts() async {
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.setLanguage('en-US');
  }

  void _speak(String text) {
    if (_muted) return;
    _tts.stop();
    _tts.speak(text);
  }

  void _celebrate(String message) {
    _confettiController.play();
    _speak(message);
    setState(() => _xp += Random().nextInt(20) + 10);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pageController = PageController(viewportFraction: 0.8);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Dashboard'),
        backgroundColor: Colors.deepOrange,
        actions: [
          IconButton(
            icon: Icon(_muted ? Icons.volume_off : Icons.volume_up),
            onPressed: () => setState(() => _muted = !_muted),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            children: [
              SizedBox(
                height: 300,
                child: PageView.builder(
                  controller: pageController,
                  itemCount: sections.length,
                  onPageChanged: (index) => setState(() => _currentIndex = index),
                  itemBuilder: (context, index) {
                    return AnimatedScale(
                      scale: _currentIndex == index ? 1.0 : 0.9,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      child: DashboardCard(
                        title: sections[index],
                        color: Colors.primaries[index % Colors.primaries.length].shade300,
                        onPressed: () {
                          _celebrate('You opened ${sections[index]}!');
                          if (sections[index] == 'Learning Preferences') {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LearningPreferencesPage()));
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),

              // Badges row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 10,
                  children: [
                    BadgeChip(title: 'Starter', unlocked: badges.contains('starter')),
                    BadgeChip(title: 'Point Collector', unlocked: badges.contains('point_collector')),
                    BadgeChip(title: 'Master Learner', unlocked: badges.contains('master')),
                  ],
                ),
              ),

              const SizedBox(height: 80), // Extra bottom space for confetti overlay
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [Colors.amber, Colors.orange, Colors.deepOrange],
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final Color color;
  final VoidCallback onPressed;

  const DashboardCard({
    super.key,
    required this.title,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 8,
      shadowColor: color.withOpacity(0.5),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      color: color,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onPressed,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(36),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 26,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(blurRadius: 6, color: Colors.black26, offset: Offset(1, 2))
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class BadgeChip extends StatelessWidget {
  final String title;
  final bool unlocked;

  const BadgeChip({super.key, required this.title, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(title,
          style: TextStyle(
            color: unlocked ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.bold,
          )),
      backgroundColor: unlocked ? Colors.deepOrange : Colors.grey.shade300,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shadowColor: Colors.black12,
      elevation: unlocked ? 6 : 0,
    );
  }
}

class LearningPreferencesPage extends StatefulWidget {
  const LearningPreferencesPage({super.key});

  @override
  State<LearningPreferencesPage> createState() => _LearningPreferencesPageState();
}

class _LearningPreferencesPageState extends State<LearningPreferencesPage> {
  final List<String> subjects = ['Math', 'Science', 'History', 'Languages', 'Arts', 'Tech'];
  final Set<String> selectedSubjects = {};
  String difficulty = 'Standard';
  String studyTime = 'Morning';
  String goalType = 'Pass Exam';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Preferences'),
        backgroundColor: Colors.deepOrange,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Better Subjects', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: subjects.map((sub) {
              final selected = selectedSubjects.contains(sub);
              return FilterChip(
                label: Text(sub),
                selected: selected,
                onSelected: (v) => setState(() {
                  if (v) {
                    selectedSubjects.add(sub);
                  } else {
                    selectedSubjects.remove(sub);
                  }
                }),
                selectedColor: Colors.deepOrange.shade300,
                backgroundColor: Colors.orange.shade100,
                labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.deepOrange.shade700,
                    fontWeight: FontWeight.w600),
              );
            }).toList(),
          ),
          const SizedBox(height: 30),

          const Text('Difficulty Preference', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Standard', 'Advanced', 'Adaptive'].map((level) {
              final selected = difficulty == level;
              return ChoiceChip(
                label: Text(level),
                selected: selected,
                selectedColor: Colors.deepOrange.shade400,
                onSelected: (v) => setState(() => difficulty = level),
                labelStyle: TextStyle(color: selected ? Colors.white : Colors.deepOrange.shade700),
              );
            }).toList(),
          ),
          const SizedBox(height: 30),

          const Text('Study Time Preference', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Morning', 'Afternoon', 'Evening'].map((time) {
              final selected = studyTime == time;
              return ChoiceChip(
                label: Text(time),
                selected: selected,
                selectedColor: Colors.deepOrange.shade400,
                onSelected: (v) => setState(() => studyTime = time),
                labelStyle: TextStyle(color: selected ? Colors.white : Colors.deepOrange.shade700),
              );
            }).toList(),
          ),
          const SizedBox(height: 30),

          const Text('Goal Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: ['Pass Exam', 'Get Certified', 'Master Subject', 'Other'].map((goal) {
              final selected = goalType == goal;
              return ChoiceChip(
                label: Text(goal),
                selected: selected,
                selectedColor: Colors.deepOrange.shade400,
                onSelected: (v) => setState(() => goalType = goal),
                labelStyle: TextStyle(color: selected ? Colors.white : Colors.deepOrange.shade700),
              );
            }).toList(),
          ),

          const SizedBox(height: 40),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            icon: const Icon(Icons.save),
            label: const Text('Save Preferences'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Preferences saved! 🎉')),
              );
            },
          ),
        ],
      ),
    );
  }
}
