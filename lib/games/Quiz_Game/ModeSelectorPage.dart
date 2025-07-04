import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mortaalim/IndexPage.dart';
import '../../main.dart';
import 'general_culture_game.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ModeSelectorPage extends StatelessWidget {
  const ModeSelectorPage({super.key});

  Future<Map<String, String>?> showAvatarPickerDialog(BuildContext context, int playerNumber) {
    final TextEditingController nameController = TextEditingController();
    String selectedEmoji = '😀';

    final emojis = [
      '😀', '😎', '🥳', '🤓', '👻', '🎃', '👽', '🧸', // faces & fun
      '🐱', '🐶', '🦊', '🐻', '🐼', '🐯', '🐰', '🐸', '🦁', '🐵', // animals
      '🚀', '🎈', '🎮', '🧁', '🍭', '🍕', // fun objects
    ];
    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => Container(
        child: Expanded(
          child: ListView(
            children: [
              AlertDialog(
                title: Text('${tr(context).player} $playerNumber: Choose your avatar and name'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 10, // optional: adds vertical space between rows
                        children: emojis.map((emoji) {
                          final isSelected = selectedEmoji == emoji;
                          return ChoiceChip(
                            label: Text(
                              emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                            selected: isSelected,
                            selectedColor: Colors.deepOrange.shade200,
                            backgroundColor: Colors.orange.shade50,
                            onSelected: (selected) {
                              if (selected) {
                                selectedEmoji = emoji;
                                (context as Element).markNeedsBuild(); // triggers rebuild for chips
                              }
                            },
                            elevation: isSelected ? 6 : 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        hintText: 'Enter Your name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final name = nameController.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a name')),
                        );
                        return;
                      }
                      Navigator.pop(context, {
                        'name': name,
                        'emoji': selectedEmoji,
                      });
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startGame(BuildContext context, GameMode mode) async {
    if (mode == GameMode.multiplayer) {
      final player1 = await showAvatarPickerDialog(context, 1);
      if (player1 == null) return;

      final player2 = await showAvatarPickerDialog(context, 2);
      if (player2 == null) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizPage(
            mode: mode,
            player1Name: player1['name']!,
            player1Emoji: player1['emoji']!,
            player2Name: player2['name']!,
            player2Emoji: player2['emoji']!,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const QuizPage(mode: GameMode.single),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        leading: IconButton(   onPressed: () => Navigator.of(context).pop(),icon: Icon(Icons.arrow_back),),
        title:  Text(tr(context).quizGame),
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildModeButton(
              context,
              title: "🎯 ${tr(context).singlePlayer}",
              icon: Icons.person,
              mode: GameMode.single,
            ),
            const SizedBox(height: 30),
            _buildModeButton(
              context,
              title: "👫 ${tr(context).multiplayer}",
              icon: Icons.people,
              mode: GameMode.multiplayer,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(BuildContext context,
      {required String title,
        required IconData icon,
        required GameMode mode}) {
    return ElevatedButton.icon(
      onPressed: () => _startGame(context, mode),
      icon: Icon(icon, size: 28),
      label: Text(title, style: const TextStyle(fontSize: 22)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepOrange,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}


