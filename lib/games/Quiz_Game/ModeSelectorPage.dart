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
      '😀', '😎', '🥳', '🤓', '👻', '🐱', '🐶', '🦊', '🐻', '🐼', '🚀', '🎈', '🎮', '🍭', '🍕'
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
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a name')),
                      );
                      return;
                    }
                    Navigator.pop(context, {
                      'name': name,
                      'emoji': selectedEmoji
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: double.infinity,
            child: Positioned.fill(
              child: Image.asset(
                'assets/images/UI/BackGrounds/bg_QuizzGame.jpg',
                fit: BoxFit.cover,
              ),
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
                      const SizedBox(height: 60),
                      const Userstatutbar(),
                      const SizedBox(height: 20),
                      const Text(
                        "🎯 Ready to play?\nAnswer questions to win stars and XP!\n\n"
                            "🌟 3 right answers = 1 star\n"
                            "💡 Each correct answer = +2 XP\n\n"
                            "Play alone or with a friend!",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      AnimatedBuilder(
                        animation: _colorAnimation,
                        builder: (context, child) => Text(
                          "Choose your language:",
                          style: TextStyle(
                            fontSize:30,
                            fontWeight: FontWeight.bold,
                            color: _languageWarning ? _colorAnimation.value : Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
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
                              style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                            ),
                            selected: isSelected,
                            selectedColor: Colors.deepOrange,
                            backgroundColor: Colors.white70,
                            elevation: 3,
                            pressElevation: 6,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            onSelected: (_) {
                              _transition.play("assets/audios/sound_effects/buttonPressed.mp3");
                              setState(() => _selectedLanguage = lang);},
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 40),
                      _buildModeButton(context, mode: GameMode.single, assetPath: 'assets/images/UI/Buttons/1Player.png'),
                      const SizedBox(height: 30),
                      _buildModeButton(context, mode: GameMode.multiplayer, assetPath: 'assets/images/UI/Buttons/2Player.png'),
                    ],
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
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
        _startGame(mode);},
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          assetPath,
          width: 240,
          height: 120,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}