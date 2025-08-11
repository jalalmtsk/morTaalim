import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../ManagerTools/AppGlobal.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import '../../Authentification/LinkToGoogle.dart';
import '../../Authentification/LogOut.dart';
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

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // BACKGROUND with gradient overlay
            Positioned.fill(
              child: Image.asset(
                'assets/images/UI/BackGrounds/bg9.jpg',
                fit: BoxFit.cover,
              ),
            ),
            Container(
              color: Colors.black.withOpacity(0.4),
            ),

            // CONTENT
            Column(
              children: [
                const SizedBox(height: 10),
                Userstatutbar(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_circle_left,
                          size: 45,
                          color: Colors.deepOrangeAccent,
                        ),
                        onPressed: () {
                          audioManager.playEventSound('cancelButton'); // Play your sound
                          Navigator.pop(context); // Go back
                        },
                        tooltip: 'Back',
                      ),
                      const Spacer(),
                      // XP & ADD BUTTON (for testing)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange.withOpacity(0.9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          elevation: 6,
                        ),
                        onPressed: () async {
                          xpManager.addXP(200, context: context);
                          await Future.delayed(const Duration(milliseconds: 1000));
                          xpManager.addTokenBanner(context, 20);

                          await Future.delayed(const Duration(milliseconds: 500));
                          xpManager.addStarBanner(
                            context,
                            300,
                            starIconKey: AppGlobals.starIconKey,
                            animationFrom: const Offset(100, 600),
                            animationTo: const Offset(300, 100),
                          );
                        },
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text(
                          "Add",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),

                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // TITLE with glowing effect
                Text(
                  tr(context).chooseYourLanguageToStartTracing,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade50,
                    shadows: [
                      Shadow(
                        color: Colors.deepOrange.withValues(alpha: 0.9),
                        blurRadius: 12,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),

                // LANGUAGES GRID
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      itemCount: languages.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 18,
                        mainAxisSpacing: 18,
                        childAspectRatio: 0.95,
                      ),
                      itemBuilder: (context, index) {
                        final lang = languages[index];
                        return LanguageCard(language: lang);
                      },
                    ),
                  ),
                ),
                DisconnectButton(
                  onSignedOut: () {
                    print("User signed out!");
                    // Do any other cleanup if needed
                  },
                ),

                if (user != null && user.isAnonymous)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.login),
                      label: const Text(
                        "Lier compte Google",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LinkGoogleAccountPage()),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
