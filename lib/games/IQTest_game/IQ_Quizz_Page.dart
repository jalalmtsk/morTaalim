import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mortaalim/games/IQTest_game/result_page.dart';
import 'iqGame_data.dart';

class QuizPage extends StatefulWidget {
  final Section section;
  const QuizPage({super.key, required this.section});

  @override
  State<QuizPage> createState() => QuizPageState();
}

class QuizPageState extends State<QuizPage> {
  int questionIndex = 0;
  int score = 0;
  bool showHint = false;
  static const int maxTimePerQuestion = 15; // seconds
  late Timer _timer;
  int timeLeft = maxTimePerQuestion;
  bool isAnswered = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    timeLeft = maxTimePerQuestion;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft <= 0) {
        timer.cancel();
        onTimeOut();
      } else {
        setState(() {
          timeLeft--;
        });
      }
    });
  }

  void onTimeOut() {
    setState(() {
      isAnswered = true;
    });
    showSnackBar('Time\'s up! ❌');
    moveNextAfterDelay();
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void checkAnswer(String selected) {
    if (isAnswered) return; // Prevent double answers
    isAnswered = true;
    final correct = widget.section.questions[questionIndex].answer;
    if (selected == correct) {
      score += 10;
      showSnackBar('Correct! ✅');
    } else {
      showSnackBar('Wrong! ❌');
    }
    _timer.cancel();
    moveNextAfterDelay();
  }

  void moveNextAfterDelay() {
    Future.delayed(const Duration(seconds: 1), () {
      if (questionIndex < widget.section.questions.length - 1) {
        setState(() {
          questionIndex++;
          showHint = false;
          isAnswered = false;
          startTimer();
        });
      } else {
        _timer.cancel();
        saveScore();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultPage(score: score, section: widget.section),
          ),
        );
      }
    });
  }

  Future<void> saveScore() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'scores_${widget.section.title}';
    List<String> scores = prefs.getStringList(key) ?? [];
    scores.add(score.toString());
    await prefs.setStringList(key, scores);

    // Save for leaderboard (global)
    final globalScores = prefs.getStringList('global_scores') ?? [];
    globalScores.add(score.toString());
    await prefs.setStringList('global_scores', globalScores);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.section.questions[questionIndex];
    double timerPercent = timeLeft / maxTimePerQuestion;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.section.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: timerPercent,
            backgroundColor: Colors.grey.shade300,
            color: Colors.deepPurple,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Question ${questionIndex + 1} of ${widget.section.questions.length}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Row(
              children: [
                Text('Time Left: $timeLeft s',
                    style: const TextStyle(fontSize: 16, color: Colors.red)),
                const Spacer(),
                Text('Score: $score', style: const TextStyle(fontSize: 18)),
              ],
            ),
            const SizedBox(height: 20),
            Text(q.question, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 20),
            ...q.options.map((opt) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ElevatedButton(
                onPressed: () => checkAnswer(opt),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAnswered
                      ? (opt == q.answer
                      ? Colors.green
                      : Colors.grey.shade400)
                      : null,
                ),
                child: Text(opt, style: const TextStyle(fontSize: 18)),
              ),
            )),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => setState(() => showHint = !showHint),
              icon: const Icon(Icons.lightbulb),
              label: const Text('Hint'),
            ),
            if (showHint)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text('💡 ${q.hint}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey)),
              ),
          ],
        ),
      ),
    );
  }
}