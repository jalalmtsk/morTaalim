import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mortaalim/tools/audio_tool.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
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

class _ModeSelectorPageState extends State<ModeSelectorPage>
    with SingleTickerProviderStateMixin {
  QuizLanguage? _selectedLanguage;
  bool _languageWarning = false;
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;
  final MusicPlayer _transition = MusicPlayer();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _colorAnimation = ColorTween(
      begin: Colors.white,
      end: Colors.redAccent,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transition.dispose();
    super.dispose();
  }

  Future<Map<String, String>?> showAvatarPickerDialog(
      BuildContext context, int playerNumber) async {
    final TextEditingController nameController = TextEditingController();
    String selectedEmoji = '😀';
    final emojis = [
      '😀', '😎', '🥳', '🤓',
      '👻', '🐱', '🐶', '🦊', '🐻',
      '🐼', '🚀', '🎈', '🎮', '🍭', '🍕'
    ];

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('${tr(context).player} $playerNumber'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 10,
                    children: emojis.map((emoji) {
                      final isSelected = selectedEmoji == emoji;
                      return ChoiceChip(
                        label: Text(emoji, style: const TextStyle(fontSize: 24)),
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
                            borderRadius: BorderRadius.circular(16)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'Enter your name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    // If name is empty, assign default name based on playerNumber
                    final finalName = name.isEmpty ? 'Player$playerNumber' : name;
                    Navigator.pop(context, {
                      'name': finalName,
                      'emoji': selectedEmoji,
                    });
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _startGame(GameMode mode) async {
    if (_selectedLanguage == null) {
      setState(() {
        _languageWarning = true;
      });
      _animationController.forward(from: 0);
      return;
    } else {
      setState(() {
        _languageWarning = false;
      });
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

  void _showInstructionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.deepOrange.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.info_outline, color: Colors.deepOrange),
              SizedBox(width: 10),
              Text("How to Play", style: TextStyle(color: Colors.deepOrange)),
            ],
          ),
          content: const Text(
            "🎯 Ready to play?\n\n"
                "✅ Choose your language.\n"
                "✅ Pick single or multiplayer.\n\n"
                "🌟 Rules:\n"
                "- 3 correct answers = 1 star\n"
                "- Every correct answer = +2 XP\n"
                "- Compete or play solo\n\n"
                "🎉 Have fun and learn something new!",
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              child: const Text("Got it!", style: TextStyle(color: Colors.deepOrange)),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/UI/BackGrounds/bg_QuizzGame.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.3))),
          SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Userstatutbar(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(12),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(12),
                            ),
                            onPressed: () => _showInstructionsDialog(context),
                            child: const Icon(Icons.info_outline, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 50),
                      AnimatedBuilder(
                        animation: _colorAnimation,
                        builder: (context, child) => Text(
                          tr(context).chooseGame,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: _languageWarning ? _colorAnimation.value : Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 3,
                        children: QuizLanguage.values.map((lang) {
                          final isSelected = _selectedLanguage == lang;
                          final label = {
                            QuizLanguage.english: '🇬🇧 English',
                            QuizLanguage.french: '🇫🇷 Français',
                            QuizLanguage.arabic: '🇲🇦 العربية',
                          }[lang]!;

                          return ChoiceChip(
                            label: Text(
                              label,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: Colors.deepOrange,
                            backgroundColor: Colors.orange.withOpacity(0.6),
                            elevation: 3,
                            pressElevation: 6,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            onSelected: (_) {
                              _transition.play("assets/audios/sound_effects/buttonPressed.mp3");
                              setState(() => _selectedLanguage = lang);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 60),
                      _buildModeButton(context, mode: GameMode.single, assetPath: 'assets/images/UI/Buttons/1Player.png'),
                      const SizedBox(height: 20),
                      _buildModeButton(context, mode: GameMode.multiplayer, assetPath: 'assets/images/UI/Buttons/2Player.png'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(BuildContext context, {required GameMode mode, required String assetPath}) {
    return ElevatedButton(
      onPressed: () {
        _transition.play("assets/audios/sound_effects/buttonPressed.mp3");
        _startGame(mode);
      },
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Image.asset(
          assetPath,
          width: 290,
          height: 150,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
