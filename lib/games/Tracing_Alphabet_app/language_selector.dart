import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


import '../../XpSystem.dart';
import 'Language_CardsUI.dart';

class LanguageSelectorPage extends StatelessWidget {
  final void Function(Locale) onChangeLocale;

  const LanguageSelectorPage({super.key, required this.onChangeLocale});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    final languages = [
      LanguageOption(
        name: 'French Letters (A, B, C...)',
        languageCode: 'french',
        icon: Icons.breakfast_dining_outlined,
        color: Colors.deepOrange,
        locked: false,
      ),
      LanguageOption(
        name: 'حروف عربية',
        languageCode: 'arabic',
        icon: Icons.brightness_high_outlined,
        color: Colors.deepOrange.shade700,
        locked: false,
      ),
      LanguageOption(
        name: '🇯🇵 ひらがな (Japanese)',
        languageCode: 'japanese',
        icon: Icons.draw,
        color: Colors.redAccent.shade200,
        locked: true,
        cost: 15,
      ),
      LanguageOption(
        name: '한글 (Korean Hangul)',
        languageCode: 'korean',
        icon: Icons.text_fields,
        color: Colors.blueAccent.shade200,
        locked: true,
        cost: 15,
      ),
      LanguageOption(
        name: '汉字 (Chinese Hanzi)',
        languageCode: 'chinese',
        icon: Icons.translate,
        color: Colors.green.shade400,
        locked: true,
        cost: 15,
      ),
      LanguageOption(
        name: 'Русский алфавит(Russian)',
        languageCode: 'russian',
        icon: Icons.airplanemode_active_sharp,
        color: Colors.indigo.shade400,
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
          tr.alphabetTracing,
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
            // Fun top header with icon and welcome text
            Text(textAlign: TextAlign.center,'Choose your language to start tracing!', style: TextStyle(
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

