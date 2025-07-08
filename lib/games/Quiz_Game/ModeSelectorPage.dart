import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mortaalim/userStatutBar.dart';
import '../../main.dart';
import 'general_culture_game.dart';
import '../../l10n/app_localizations.dart';
import 'package:mortaalim/games/Quiz_Game/game_mode.dart' hide GameMode;

enum QuizLanguage { english, french, arabic }

class ModeSelectorPage extends StatefulWidget {
  const ModeSelectorPage({super.key});

  @override
  State<ModeSelectorPage> createState() => _ModeSelectorPageState();
}

class _ModeSelectorPageState extends State<ModeSelectorPage> {
  QuizLanguage? _selectedLanguage;

  Future<Map<String, String>?> showAvatarPickerDialog(BuildContext context, int playerNumber) {
    final TextEditingController nameController = TextEditingController();
    String selectedEmoji = '😀';

    final emojis = [
      '😀', '😎', '🥳', '🤓', '👻', '🎃', '👽', '🧸',
      '🐱', '🐶', '🦊', '🐻', '🐼', '🐯', '🐰', '🐸', '🦁', '🐵',
      '🚀', '🎈', '🎮', '🧁', '🍭', '🍕',
    ];

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('${tr(context).player} $playerNumber: Choose your avatar and name'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 10,
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
                                setState(() {
                                  selectedEmoji = emoji;
                                });
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
              );
            }
        );
      },
    );
  }


  void _startGame(GameMode mode) async {
    if (_selectedLanguage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 1),
            content: Text('Please select a language first!')),
      );
      return;
    }

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
            language: _selectedLanguage!,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizPage(
            mode: GameMode.single,
            language: _selectedLanguage!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(tr(context).quizGame),
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 20, right: 30, left: 30),
              child: Userstatutbar(),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 50),
              child: Text(
                "🧠 Answer questions correctly to earn rewards:\n"
                    "- ✅ +2 XP for each correct answer\n"
                    "- 🌟 Every 3 correct answers = +1 Token\n\n\n\n"
                    "You can play solo or challenge a friend in multiplayer mode.\n",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),


            const Text(
              "Select Language:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ToggleButtons(
              isSelected: [
                _selectedLanguage == QuizLanguage.english,
                _selectedLanguage == QuizLanguage.french,
                _selectedLanguage == QuizLanguage.arabic,
              ],
              onPressed: (index) {
                setState(() {
                  _selectedLanguage = QuizLanguage.values[index];
                });
              },
              borderRadius: BorderRadius.circular(8),
              selectedColor: Colors.white,
              fillColor: Colors.deepOrange,
              children: const [
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('English')),
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Français')),
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('العربية')),
              ],
            ),
            const SizedBox(height: 40),
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
      onPressed: () => _startGame(mode),
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
