import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../l10n/app_localizations.dart';
import 'package:mortaalim/userStatutBar.dart';


import '../../XpSystem.dart';
import '../../main.dart';
import 'Language_CardsUI.dart';

class LanguageSelectorPage extends StatelessWidget {
  final void Function(Locale) onChangeLocale;

  const LanguageSelectorPage({super.key, required this.onChangeLocale});

  @override
  Widget build(BuildContext context) {

    final languages = [
      LanguageOption(
        name: 'French Letters (A, B, C...)',
        languageCode: 'french',
        icon: "🇫🇷",
        color: Colors.deepOrange,
        locked: false,
      ),
      LanguageOption(
        name: 'حروف عربية',
        languageCode: 'arabic',
        icon: "🇸🇦",
        color: Colors.deepOrange.shade700,
        locked: false,
      ),
      
      LanguageOption(
        name: 'Русс Russian',
        languageCode: 'russian',
        icon: "🇷🇺",
        color: Colors.indigo.shade400,
        locked: true,
        cost: 15,
      ),
      LanguageOption(
        name: 'ひら Japanese',
        languageCode: 'japanese',
        icon: "🇯🇵",
        color: Colors.redAccent.shade200,
        locked: true,
        cost: 50,
      ),

      LanguageOption(
        name: '한글 Korean',
        languageCode: 'korean',
        icon: "🇰🇷",
        color: Colors.blueAccent.shade200,
        locked: true,
        cost: 15,
      ),

      LanguageOption(
        name: '汉字 Chinese',
        languageCode: 'chinese',
        icon: "🇨🇳",
        color: Colors.green.shade400,
        locked: true,
        cost: 15,
      ),
    ];


    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        actions: [
        ],
        title: Text(
          tr(context).alphabetTracing,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
        elevation: 6,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepOrange.shade200, Colors.deepOrange.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
Userstatutbar(),            // Fun top header with icon and welcome text
            Text(textAlign: TextAlign.center, tr(context).chooseYourLanguageToStartTracing, style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.deepOrange.shade800,
            )),
            Row(children: [
              Container(
                child: Lottie.asset(
                  'assets/animations/paiting_building.json',
                  width: 170,
                  height: 130,
                  fit: BoxFit.cover,
                ),
              ),

            ],
            ),

                SizedBox(height: 10),

            // Language options grid
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
    );
  }
}

