import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressManager {
  static late SharedPreferences prefs;
  static const _progressKey = 'child_progress';

  static Future init() async {
    prefs = await SharedPreferences.getInstance();
  }

  static Future<void> saveProgress(int lessonIndex) async {
    List<String> completed = prefs.getStringList(_progressKey) ?? [];
    if (!completed.contains(lessonIndex.toString())) {
      completed.add(lessonIndex.toString());
      await prefs.setStringList(_progressKey, completed);
    }
  }

  static List<int> getCompletedLessons() {
    List<String> completed = prefs.getStringList(_progressKey) ?? [];
    return completed.map(int.parse).toList();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parent Dashboard Demo',
      theme: ThemeData(primarySwatch: Colors.deepOrange),
      home: const ParentDashboardPage(),
    );
  }
}

class ParentDashboardPage extends StatefulWidget {
  const ParentDashboardPage({super.key});

  @override
  State<ParentDashboardPage> createState() => _ParentDashboardPageState();
}

class _ParentDashboardPageState extends State<ParentDashboardPage> {
  List<int> completedLessons = [];
  final int totalLessons = 20; // total number of lessons

  @override
  void initState() {
    super.initState();
    loadProgress();
  }

  Future<void> loadProgress() async {
    await ProgressManager.init();
    setState(() {
      completedLessons = ProgressManager.getCompletedLessons();
    });
  }

  Future<void> addCompletedLesson() async {
    if (completedLessons.length < totalLessons) {
      int nextLesson = completedLessons.isEmpty ? 1 : (completedLessons.reduce((a, b) => a > b ? a : b) + 1);
      await ProgressManager.saveProgress(nextLesson);
      setState(() {
        completedLessons.add(nextLesson);
      });
      await checkMilestones(context, completedLessons.length, totalLessons);
    }
  }

  Future<void> checkMilestones(BuildContext context, int completedCount, int total) async {
    final percent = completedCount / total;

    if (percent == 0.5) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Milestone Reached!"),
          content: const Text("Your child has completed 50% of the lessons! Keep it up! 🎉"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Great!")),
          ],
        ),
      );
    } else if (percent == 1.0) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Congratulations!"),
          content: const Text("Your child has completed all lessons! 🎉🏆"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Awesome!")),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = completedLessons.length / totalLessons;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Parent Dashboard"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Child's Learning Progress",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              minHeight: 20,
              backgroundColor: Colors.deepOrange.shade100,
              color: Colors.deepOrange,
            ),
            const SizedBox(height: 8),
            Text(
              "${(progress * 100).toStringAsFixed(1)}% Completed",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: completedLessons.isEmpty
                  ? const Center(child: Text("No lessons completed yet."))
                  : ListView.builder(
                itemCount: completedLessons.length,
                itemBuilder: (context, index) {
                  final lessonNumber = completedLessons[index];
                  return ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: Text("Lesson #$lessonNumber"),
                    subtitle: Text("Completed on: ${DateTime.now().toLocal().toString().split(' ')[0]}"),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              icon: const Icon(Icons.lightbulb),
              label: const Text("Show Parenting Tips"),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Parent Tip"),
                    content: const Text(
                      "Praise your child regularly to encourage consistent learning! 🎉",
                    ),
                    actions: [
                      TextButton(
                        child: const Text("Got it!"),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Simulate Lesson Completion"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrangeAccent),
              onPressed: addCompletedLesson,
            ),
          ],
        ),
      ),
    );
  }
}
