import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/main.dart';
import 'package:provider/provider.dart';
import 'package:mortaalim/XpSystem.dart';

import '../../tools/audio_tool/Audio_Manager.dart'; // ExperienceManager

class LanguageTouch extends StatefulWidget {
  final VoidCallback? onLanguageSelected;

  const LanguageTouch({Key? key, this.onLanguageSelected}) : super(key: key);

  @override
  State<LanguageTouch> createState() => _LanguageTouchState();
}

class _LanguageTouchState extends State<LanguageTouch>
    with TickerProviderStateMixin {
  String? _selectedLanguage;
  late AnimationController _gradientController;

  // Gradient sets (softer than WelcomePage)
  final List<List<Color>> gradientSets = [
    [const Color(0xFF6DD5FA), const Color(0xFF2980B9)], // Soft blue
    [const Color(0xFFFFD194), const Color(0xFFD1913C)], // Warm gold
    [const Color(0xFFB2FEFA), const Color(0xFF0ED2F7)], // Light teal
  ];

  int currentGradientIndex = 0;

  @override
  void initState() {
    super.initState();

    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          currentGradientIndex = (currentGradientIndex + 1) % gradientSets.length;
        });
        _gradientController.forward(from: 0);
      }
    });

    _gradientController.forward();
  }

  @override
  void dispose() {
    _gradientController.dispose();
    super.dispose();
  }

  // ... Ton code actuel ...

  @override
  Widget build(BuildContext context) {
    final expManager = Provider.of<ExperienceManager>(context);

    final Map<String, Map<String, String>> languagesMap = {
      'en': {'flag': '🇺🇸', 'label': 'English'},
      'ar': {'flag': '🇸🇦', 'label': 'العربية'},
      'fr': {'flag': '🇫🇷', 'label': 'Français'},
      'de': {'flag': '🇩🇪', 'label': 'Deutsch'},
      'zgh': {'flag': '🇲🇦', 'label': 'Amazigh'},

    };

    List<String> unlockedLanguages = expManager.unlockedLanguages
        .where((lang) => languagesMap.containsKey(lang))
        .toList();

    if (unlockedLanguages.isEmpty) {
      unlockedLanguages = languagesMap.keys.toList();
    }

    final nextIndex = (currentGradientIndex + 1) % gradientSets.length;
    return Scaffold(
      body: AnimatedBuilder(
        animation: _gradientController,
        builder: (context, _) {
          final colors = List<Color>.generate(
            2,
                (i) => Color.lerp(
              gradientSets[currentGradientIndex][i],
              gradientSets[nextIndex][i],
              _gradientController.value,
            )!,
          );

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // Main content column
                  Column(
                    children: [
                      const SizedBox(height: 20),

                      // **Top Lottie animation**
                      Lottie.asset(
                        'assets/animations/languageSwitch_Animation.json',
                        width: 160,
                        height: 160,
                      ),

                      const SizedBox(height: 10),

                      // **Title**
                      Text(
                       tr(context).chooseALanguage,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            )
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // **Subtitle**
                      Text(
                       tr(context).selectALanguageToContinue,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // **Language grid**
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 20,
                            crossAxisSpacing: 20,
                            childAspectRatio: 1.1,
                          ),
                          itemCount: unlockedLanguages.length,
                          itemBuilder: (context, index) {
                            final langCode = unlockedLanguages[index];
                            final langInfo = languagesMap[langCode]!;
                            final isSelected = _selectedLanguage == langCode;
                            final audioManager = Provider.of<AudioManager>(context, listen: false);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedLanguage = langCode;
                                });

                                expManager.changeLanguage(Locale(langCode));

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                    Text('${tr(context).languageSetTo} ${langInfo['label']}'),
                                    backgroundColor: Colors.black87,
                                    duration: const Duration(milliseconds: 800),
                                  ),
                                );
                                audioManager.playEventSound('clickButton2');

                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                                transform: isSelected
                                    ? (Matrix4.identity()..scale(1.05))
                                    : Matrix4.identity(),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white.withOpacity(0.15)
                                      : Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.4),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    if (isSelected)
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      langInfo['flag']!,
                                      style: const TextStyle(fontSize: 42),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      langInfo['label']!,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    ],
                  ),

                  // Floating "Next" button bottom right

                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: FloatingActionButton(
                      backgroundColor: _selectedLanguage != null
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                      foregroundColor: _selectedLanguage != null
                          ? Colors.deepOrange
                          : Colors.deepOrange.withOpacity(0.5),
                      onPressed: _selectedLanguage != null
                          ? () {
                        final audioManager = Provider.of<AudioManager>(context, listen: false);
                        audioManager.playEventSound('clickButton');
                        widget.onLanguageSelected?.call();
                      }
                          : null,
                      child: const Icon(Icons.arrow_forward, size: 28),
                      elevation: 6,
                    ),
                  ),

                  Positioned(
                    bottom: -10,
                    right: -10,
                    child: _selectedLanguage != null
                        ? IgnorePointer(
                      ignoring: true, // <-- this makes it non-clickable
                      child: Lottie.asset(
                        'assets/animations/TutorielGesture/click_Tuto.json',
                        width: 100,
                        height: 100,
                      ),
                    )
                        : SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

  }
}
