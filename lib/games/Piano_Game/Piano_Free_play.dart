import 'package:flutter/material.dart';
import 'package:mortaalim/games/Piano_Game/Black_Key_UI.dart';
import 'package:mortaalim/tools/audio_tool.dart';
import 'package:provider/provider.dart';

import '../../XpSystem.dart';

final MusicPlayer _musicPlayer = MusicPlayer();


class FullPianoPage extends StatefulWidget {
  const FullPianoPage({super.key});

  static const List<String> whiteKeys = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
  static const List<String> blackKeys = ['C#', 'D#', '', 'F#', 'G#', 'A#', ''];

  @override
  State<FullPianoPage> createState() => _FullPianoPageState();
}

class _FullPianoPageState extends State<FullPianoPage> {

  late ExperienceManager xpManager;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    xpManager = Provider.of<ExperienceManager>(context);
  }

  Future<void> playNoteWithXP(String note) async {
    await _musicPlayer.play('assets/audios/piano_notes/$note.mp3');
    // Reward a small XP for each note played
    xpManager.addXP(2);
  }


  int selectedGroup = 1;

  List<List<String>> generateWhiteNoteLines() {
    return [
      for (int i = 1; i <= 5; i++)
        [for (var note in FullPianoPage.whiteKeys) '$note$i']
    ];
  }

  List<List<String>> generateBlackNoteLines() {
    return [
      for (int i = 1; i <= 5; i++)
        [for (var note in FullPianoPage.blackKeys) note.isNotEmpty ? '$note$i' : '']
    ];
  }

  @override
  Widget build(BuildContext context) {
    final whiteNoteLines = generateWhiteNoteLines();
    final blackNoteLines = generateBlackNoteLines();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('🎹 Free Play'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text(
              'Select Octave:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple.shade700),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final group = index + 1;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedGroup == group ? Colors.deepPurple : Colors.grey.shade700,
                    ),
                    onPressed: () => setState(() => selectedGroup = group),
                    child: Text('Octave $group'),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Tap a key to play the sound.',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Stack(
                  children: [
                    Row(
                      children: whiteNoteLines[selectedGroup - 1]
                          .map((note) => _WhiteKey(note: note))
                          .toList(),
                    ),
                    Positioned.fill(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: blackNoteLines[selectedGroup - 1].map((note) {
                          return note.isEmpty
                              ?  SizedBox(width: 60)
                              : _BlackKey(note: note);
                        }).toList(),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}


class _WhiteKey extends StatelessWidget {
  final String note;

  const _WhiteKey({required this.note});

  Future<void> playNote() async {
    await _musicPlayer.play('assets/audios/piano_notes/$note.mp3');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: playNote,
      child: Container(
        width: 60,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              note,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}


class _BlackKey extends StatelessWidget {
  final String note;

  const _BlackKey({required this.note});

  Future<void> playNote() async {
    await _musicPlayer.play('assets/audios/piano_notes/$note.mp3');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      alignment: Alignment.topCenter,
      child: FractionallySizedBox(
        widthFactor: 0.6,
        heightFactor: 0.6,
        child: GestureDetector(
          onTap: playNote,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 5,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                note,
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


