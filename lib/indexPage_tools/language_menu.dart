import 'package:flutter/material.dart';

class LanguageMenu extends StatelessWidget {
  final void Function(Locale) onChangeLocale;

  const LanguageMenu({super.key, required this.onChangeLocale});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Locale>(
      icon: const Icon(Icons.language_outlined, color: Colors.deepOrange, size: 28),
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
