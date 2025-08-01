import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';


import '../../XpSystem.dart';
import '../../main.dart';
import '../../tools/audio_tool/Audio_Manager.dart';
import 'Language_CardsUI.dart';

class LanguageSelectorPage extends StatelessWidget {
  final void Function(Locale) onChangeLocale;

  const LanguageSelectorPage({super.key, required this.onChangeLocale});

  @override
  Widget build(BuildContext context) {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    final xpManager = Provider.of<ExperienceManager>(context, listen: true);

    final languages = [
      LanguageOption(
        name: 'French Letters (A, B, C...)',
        languageCode: 'french',
        icon: "🇫🇷",
        imagePath: 'assets/images/FlagImagesForTracingLetters/FrenchLetters.png',
        locked: false,
      ),
      LanguageOption(
        name: 'حروف عربية',
        languageCode: 'arabic',
        icon: "🇸🇦",
        imagePath: 'assets/images/FlagImagesForTracingLetters/ArabicLetters.png',
        locked: false,
      ),
      
      LanguageOption(
        name: 'Русс Russian',
        languageCode: 'russian',
        icon: "🇷🇺",
        imagePath: 'assets/images/FlagImagesForTracingLetters/RussianLetters.png',
        locked: true,
        cost: 15,
      ),
      LanguageOption(
        name: 'ひら Japanese',
        languageCode: 'japanese',
        icon: "🇯🇵",
        imagePath: 'assets/images/FlagImagesForTracingLetters/JapaneseLetters.png',
        locked: true,
        cost: 50,
      ),

      LanguageOption(
        name: '한글 Korean',
        languageCode: 'korean',
        icon: "🇰🇷",
        imagePath: 'assets/images/FlagImagesForTracingLetters/KoreanLetters.png',
        locked: true,
        cost: 15,
      ),

      LanguageOption(
        name: '汉字 Chinese',
        languageCode: 'chinese',
        icon: "🇨🇳",
        imagePath: 'assets/images/FlagImagesForTracingLetters/ChineseLetters.png',
        locked: true,
        cost: 15,
      ),
    ];


    return Scaffold(

      body: SafeArea(
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                'assets/images/UI/BackGrounds/bg9.jpg', // <-- replace with your image path
                fit: BoxFit.cover,
              ),
            ),

            // Content with padding and scrollable GridView
            Container(
              height: double.infinity,
              padding: const EdgeInsets.all(10),
              color: Colors.black.withValues(alpha: 0.25), // optional: dark overlay for readability
              child: Column(
                children: [
                  Userstatutbar(),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_circle_left,
                          size: 50,
                        color: Colors.deepOrangeAccent,),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Back',
                      ),

                      ElevatedButton(
                        onPressed: () async {
                          // Add XP first
                          xpManager.addXP(500, context: context);

                          // Wait before showing the star banner
                          await Future.delayed(const Duration(milliseconds: 2000));
                          xpManager.addStarBanner(context, 1000);

                          // Wait before showing the token banner
                          await Future.delayed(const Duration(milliseconds: 2500));
                          xpManager.addTokenBanner(context, 1000);
                        }, child: Text("Add"),
                      ),
                    ],
                  ),
                   // Fun top header with icon and welcome text
                  Text(
                    tr(context).chooseYourLanguageToStartTracing,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepOrange.shade50, // adjusted for contrast on image
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: GridView.builder(
                      itemCount: languages.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // 2 per row
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 1.1,
                      ),
                      itemBuilder: (context, index) {
                        final lang = languages[index];
                        return LanguageCard(language: lang);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

    );
  }
}

