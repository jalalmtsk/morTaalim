import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import 'VsScreen.dart';
import 'quiz_Page.dart';
import 'package:mortaalim/games/Quiz_Game/game_mode.dart' hide GameMode;

enum QuizLanguage { english, french, arabic, deutch, spanish, amazigh }

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
    super.dispose();
  }

  Future<Map<String, String>?> showAvatarPickerDialog(
      BuildContext context, int playerNumber) async {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
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
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 10,
                      children: emojis.map((emoji) {
                        final isSelected = selectedEmoji == emoji;
                        return ChoiceChip(
                          label: Text(emoji, style: const TextStyle(fontSize: 20)),
                          selected: isSelected,
                          selectedColor: Colors.deepOrange.shade400,
                          backgroundColor: Colors.orange.shade50,
                          onSelected: (selected) {
                            audioManager.playEventSound('PopButton');
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
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(8), // limit to 8 characters
                      ],
                      decoration: InputDecoration(
                        labelText: tr(context).name,
                        hintText: tr(context).enterName,
                        border: OutlineInputBorder(),
                      ),
                    ),

                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      audioManager.playEventSound('cancelButton');
                      Navigator.pop(context, null);
                    },
                    child:  Text(tr(context).cancel)),
                ElevatedButton(
                  onPressed: () {
                    audioManager.playEventSound('clickButton2');
                    final name = nameController.text.trim();
                    // If name is empty, assign default name based on playerNumber
                    final finalName = name.isEmpty ? 'Player$playerNumber' : name;
                    Navigator.pop(context, {
                      'name': finalName,
                      'emoji': selectedEmoji,
                    });
                  },
                  child:  Text(tr(context).ok),
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

      // 🎬 Show transition for Player 2
      await _showPlayerTransition(context, 2);

      final player2 = await showAvatarPickerDialog(context, 2);
      if (player2 == null) return;

      // 🎯 Show VS screen before starting the quiz
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VsScreen(
            player1Name: player1['name']!,
            player1Emoji: player1['emoji']!,
            player2Name: player2['name']!,
            player2Emoji: player2['emoji']!,
            mode: mode,
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

  Future<void> _showPlayerTransition(BuildContext context, int playerNumber) async {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (_) => Material(
        color: Colors.black.withOpacity(0.6),
        child: Center(
          child: AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 300),
            child: Text(
              '🎮 Player $playerNumber',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 10,
                    color: Colors.deepOrange,
                    offset: Offset(0, 2),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    await Future.delayed(const Duration(seconds: 1)); // show for 1 second
    entry.remove();
  }



  void _showInstructionsDialog(BuildContext context) {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    audioManager.playEventSound('clickButton2');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.deepOrange.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children:  [
              Icon(Icons.info_outline, color: Colors.deepOrange),
              SizedBox(width: 10),
              Text(tr(context).howToPlay, style: TextStyle(color: Colors.deepOrange)),
            ],
          ),
          content:  Text(
            "🎯 ${tr(context).readyToPlay}?\n\n"
                "✅ ${tr(context).chooseYourLanguage}.\n"
                "✅ ${tr(context).pickSingleOrMultiplayer}.\n\n"
                "🌟 ${tr(context).rules}:\n"
                "- ${tr(context).allCorrectAnwsersEqualOneTolim}\n"
                "- ${tr(context).everyCorrectAnswerEqualPlusTwoXP}\n"
                "- ${tr(context).competeOrPlaySolo}\n\n"
                "🎉 ${tr(context).haveFunAndLearnSomethingNew}!",
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              child:  Text(tr(context).awesome, style: TextStyle(color: Colors.deepOrange)),
              onPressed: () {
          audioManager.playEventSound('cancelButton');
          Navigator.of(ctx).pop();
        }
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
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
          Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.3))),
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
                            onPressed: () {
                              audioManager.playEventSound('cancelButton');
                              Navigator.of(context).pop();
                            },
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
                      const SizedBox(height: 20),
                      AnimatedBuilder(
                        animation: _colorAnimation,
                        builder: (context, child) => Text(
                          tr(context).chooseALanguage,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: _languageWarning ? _colorAnimation.value : Colors.white,
                          ),
                        ),
                      ),
                      Wrap(
                        spacing: 10,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: QuizLanguage.values.map((lang) {
                          final isSelected = _selectedLanguage == lang;
                          final label = {
                            QuizLanguage.english: '🇬🇧 English',
                            QuizLanguage.french: '🇫🇷 Français',
                            QuizLanguage.arabic: '🇸🇦العربية',
                            QuizLanguage.deutch: '🇩🇪 Deutch',
                            QuizLanguage.spanish: '🇪🇸 Spanish',
                            QuizLanguage.amazigh: '🇲🇦 Amazigh'
                          }[lang] ?? lang.name;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: isSelected
                                  ? [
                                BoxShadow(
                                  color: Colors.deepOrange.withOpacity(0.8),
                                  blurRadius: 30,
                                  spreadRadius: 2,
                                ),
                              ]
                                  : null,
                            ),
                            child: ChoiceChip(
                              label: Text(
                                label,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: Colors.deepOrange,
                              backgroundColor: Colors.orange.withOpacity(0.6),
                              elevation: 4,
                              pressElevation: 8,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              onSelected: (_) {
                                audioManager.playEventSound("toggleButton");
                                setState(() => _selectedLanguage = lang);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 40),
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
        audioManager.playEventSound("clickButton");
        _startGame(mode);
      },
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            colors: [Colors.deepOrange, Colors.orangeAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.deepOrange.withOpacity(0.8),
              blurRadius: 20,
              spreadRadius: 3,
            ),
            BoxShadow(
              color: Colors.deepOrange.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(4), // Border thickness
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Image.asset(
            assetPath,
            width: 260,
            height: 120,
            fit: BoxFit.cover,
          ),
        ),
      )
    );
  }
}
