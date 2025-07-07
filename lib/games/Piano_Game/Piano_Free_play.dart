import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../XpSystem.dart';
import '../../tools/audio_tool/audio_tool.dart';

class FullPianoPage extends StatefulWidget {
  const FullPianoPage({super.key});

  static const List<String> whiteKeys = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
  static const List<String> blackKeys = ['C#', 'D#', '', 'F#', 'G#', 'A#', ''];

  @override
  State<FullPianoPage> createState() => _FullPianoPageState();
}

class _FullPianoPageState extends State<FullPianoPage> {
  late ExperienceManager xpManager;
  final MusicPlayers _musicPlayers = MusicPlayers();

  int selectedGroup = 1;

  // Track pressed keys for animation
  final Set<String> _pressedNotes = {};

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    xpManager = Provider.of<ExperienceManager>(context);
  }

  @override
  void dispose() {
    _musicPlayers.dispose();
    super.dispose();
  }

  void playNoteWithXP(String note) {
    setState(() => _pressedNotes.add(note));
    _musicPlayers.play('assets/audios/piano_notes/$note.mp3');
    xpManager.addXP(2);

    // Remove pressed state after 150ms
    Future.delayed(const Duration(milliseconds: 150), () {
      setState(() => _pressedNotes.remove(note));
    });
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
            const SizedBox(height: 12),
            Text(
              'Select Octave:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.deepPurple.shade800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final group = index + 1;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        selectedGroup == group ? Colors.deepPurple : Colors.grey.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: selectedGroup == group ? 8 : 2,
                        shadowColor:
                        selectedGroup == group ? Colors.deepPurple.shade300 : Colors.black26,
                      ),
                      onPressed: () => setState(() => selectedGroup = group),
                      child: Text(
                        'Octave $group',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Tap a key to play the sound.',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Stack(
                  children: [
                    // White keys row
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: whiteNoteLines[selectedGroup - 1]
                          .map(
                            (note) => _WhiteKey(
                          note: note,
                          pressed: _pressedNotes.contains(note),
                          onPressed: () => playNoteWithXP(note),
                        ),
                      )
                          .toList(),
                    ),

                    // Black keys positioned over white keys
                    Positioned.fill(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: blackNoteLines[selectedGroup - 1].map((note) {
                          if (note.isEmpty) {
                            return const SizedBox(width: 52);
                          }
                          return _BlackKey(
                            note: note,
                            pressed: _pressedNotes.contains(note),
                            onPressed: () => playNoteWithXP(note),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _WhiteKey extends StatelessWidget {
  final String note;
  final VoidCallback onPressed;
  final bool pressed;

  const _WhiteKey({
    required this.note,
    required this.onPressed,
    this.pressed = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 62,
        height: 260,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: pressed ? Colors.deepPurple.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: pressed ? Colors.deepPurple : Colors.black54,
            width: pressed ? 3 : 1.2,
          ),
          boxShadow: pressed
              ? [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ]
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(3, 6),
            ),
          ],
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              note,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: pressed ? Colors.deepPurple.shade700 : Colors.black87,
                shadows: const [
                  Shadow(
                    blurRadius: 2,
                    color: Colors.black26,
                    offset: Offset(0, 1),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BlackKey extends StatelessWidget {
  final String note;
  final VoidCallback onPressed;
  final bool pressed;

  const _BlackKey({
    required this.note,
    required this.onPressed,
    this.pressed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 160,
          decoration: BoxDecoration(
            color: pressed ? Colors.deepPurple.shade800 : Colors.black,
            borderRadius: BorderRadius.circular(12),
            boxShadow: pressed
                ? [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.9),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ]
                : [
              BoxShadow(
                color: Colors.black87,
                blurRadius: 10,
                offset: const Offset(2, 5),
              )
            ],
          ),
          child: Center(
            child: Text(
              note,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    blurRadius: 2,
                    color: Colors.black45,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
