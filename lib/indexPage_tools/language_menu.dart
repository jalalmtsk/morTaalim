import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:provider/provider.dart';
import 'package:mortaalim/XpSystem.dart'; // for ExperienceManager

class LanguageMenu extends StatelessWidget {
  final Color colorButton;

  const LanguageMenu({
    super.key,
    required this.colorButton,
  });

  @override
  Widget build(BuildContext context) {
    final audioManager = Provider.of<AudioManager>(context,listen: false);
    return PopupMenuButton<Locale>(
      icon: Lottie.asset(
        'assets/animations/languageSwitch_Animation.json',
        width: 35,
        height: 30,
        fit: BoxFit.cover,
      ),
      onOpened: (){
        audioManager.playEventSound('toggleButton');
      },
      onCanceled: (){
        audioManager.playEventSound('cancelButton');
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      elevation: 8,
      tooltip: 'Change Language',
      onSelected: (locale) {
        // Update locale via ExperienceManager
        Provider.of<ExperienceManager>(context, listen: false)
            .changeLanguage(locale);
        audioManager.playEventSound('clickButton');

        // Show dialog if Tamazight is selected
        if (locale.languageCode == 'zgh') {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    "⚠️ Attention",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: const Text(
                "Amazigh is not fully supported yet.\n"
                    "ⵜⴰⵎⴰⵣⵉⵖⵜ ⴰⵎⴰⵣⵉⵖⵜ ⵢⵓⵙ ⵢⵓⴷⵓⴷ ⴷⵉⵏⵉⵎ.\n"
                    "الأمازيغية غير مدعومة بالكامل بعد.\n\n"
                    "Team Jalnix is working on it!",              ),
              actions: [
                TextButton(
                  onPressed: () {
          audioManager.playEventSound('cancelButton');
          Navigator.of(context).pop();
                  },
                  child: const Text(
                    "OK",
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            ),
          );
        }
      },
      itemBuilder: (BuildContext context) => const [
        PopupMenuItem(value: Locale("en"), child: _LangRow("🇺🇸", "English")),
        PopupMenuItem(value: Locale("ar"), child: _LangRow("🇸🇦", "العربية")),
        PopupMenuItem(value: Locale("zgh"), child: _LangRow("🇲🇦", "ⵜⴰⵎⴰⵣⵉⵖⵜ")),
        PopupMenuItem(value: Locale("fr"), child: _LangRow("🇫🇷", "Français")),
        PopupMenuItem(value: Locale("de"), child: _LangRow("🇩🇪", "Deutsch")),
      ],
    );
  }
}

class _LangRow extends StatelessWidget {
  final String flag;
  final String label;

  const _LangRow(this.flag, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(flag, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}
