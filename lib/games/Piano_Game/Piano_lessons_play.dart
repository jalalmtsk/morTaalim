import 'package:flutter/material.dart';
import 'package:mortaalim/tools/audio_tool/audio_tool.dart';
import 'package:provider/provider.dart';

import '../../XpSystem.dart';

final MusicPlayer _lessonPlayer = MusicPlayer();

class PianoLessonsPage extends StatelessWidget {
  const PianoLessonsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lessons = [
      LessonData(title: '🎯 Lesson 1: First Touch', notes: ['C4', 'D4', 'E4']),
      LessonData(title: '🌈 Lesson 2: Rainbow Notes', notes: ['G4', 'A4', 'B4']),
      LessonData(title: '🔁 Lesson 3: Repeat Pattern', notes: ['C4', 'D4', 'E4', 'D4', 'C4']),
      LessonData(title: '🐦 Lesson 4: Bird Song', notes: ['C4', 'D4', 'E4', 'F4', 'G4']),
      LessonData(title: '🎵 Lesson 5: Rhythm Master', notes: ['C4', 'C4', 'G4', 'G4', 'A4', 'A4', 'G4']),

    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('📘 Piano Lessons'),
        backgroundColor: Colors.indigo,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: lessons.length,
        itemBuilder: (context, index) {
          final lesson = lessons[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Tap notes in order: ${lesson.notes.join(', ')}'),
              trailing: const Icon(Icons.keyboard),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InteractiveLessonPage(lesson: lesson),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}



class LessonData {
  final String title;
  final List<String> notes;
  LessonData({required this.title, required this.notes});
}

class InteractiveLessonPage extends StatefulWidget {
  final LessonData lesson;
  const InteractiveLessonPage({super.key, required this.lesson});

  @override
  State<InteractiveLessonPage> createState() => _InteractiveLessonPageState();
}

class _InteractiveLessonPageState extends State<InteractiveLessonPage> {


  int currentNoteIndex = 0;
  bool lessonCompleted = false;

  late ExperienceManager xpManager;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    xpManager = Provider.of<ExperienceManager>(context);
  }

  Future<void> playNote(String note) async {
    await _lessonPlayer.play('assets/audios/piano_notes/$note.mp3');

    if (!lessonCompleted && note == widget.lesson.notes[currentNoteIndex]) {
      // Add XP per correct note
      xpManager.addXP(10);

      setState(() {
        currentNoteIndex++;
        if (currentNoteIndex >= widget.lesson.notes.length) {
          lessonCompleted = true;
          // Bonus for completing lesson
          xpManager.addXP(50);
          xpManager.addStars(1);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🎉 Lesson Completed! You earned 50 XP & 1 star!')),
          );
        }
      });
    }
  }

  void restartLesson() {
    setState(() {
      currentNoteIndex = 0;
      lessonCompleted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final keys = <String>{...widget.lesson.notes}.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Play these notes in order:',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              widget.lesson.notes.join(' → '),
              style: const TextStyle(fontSize: 18, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            if (lessonCompleted)
              Column(
                children: [
                  const Text('🎉 Well done! Lesson completed!', style: TextStyle(fontSize: 20, color: Colors.green)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: restartLesson,
                    icon: const Icon(Icons.replay),
                    label: const Text('Restart Lesson'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                  ),
                ],
              )
            else
              Wrap(
                spacing: 12,
                children: keys.map((note) {
                  final isNext = widget.lesson.notes[currentNoteIndex] == note;
                  return GestureDetector(
                    onTap: () => playNote(note),
                    child: Container(
                      width: 60,
                      height: 180,
                      decoration: BoxDecoration(
                        color: isNext ? Colors.lightBlueAccent : Colors.white,
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      alignment: Alignment.center,
                      child: Text(note, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
