import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LanguageMenu extends StatelessWidget {
  final void Function(Locale) onChangeLocale;
  final Color colorButton;

   LanguageMenu({super.key, required this.onChangeLocale, required this.colorButton});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Locale>(
      icon: Lottie.asset(
        'assets/animations/translation_anim.json',
        width: 40,
        height: 100,
        fit: BoxFit.cover,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      elevation: 8,
      tooltip: 'Change Language',
      onSelected: onChangeLocale,
      itemBuilder: (BuildContext context) => const [
        PopupMenuItem(value: Locale("en"), child: _LangRow("🇺🇸", "English")),
        PopupMenuItem(value: Locale("ar"), child: _LangRow("🇲🇦", "العربية")),
        PopupMenuItem(value: Locale("fr"), child: _LangRow("🇫🇷", "Français")),
        PopupMenuItem(value: Locale("it"), child: _LangRow("🇮🇹", "Italiano")),
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
