import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'word_link_levels.dart';

/// Word Link — swipe the letters on the wheel to fill a small crossword.

const String wlDir = 'assets/images/UI/KidScene/';

/// One word of a level, placed on the crossword grid.
class WlWord {
  final String text;
  final int row, col;
  final bool across;
  const WlWord(this.text, this.row, this.col, this.across);

  /// Grid cells (row, col) of each letter, as `row * 16 + col` keys.
  List<int> get cells => [
        for (int i = 0; i < text.length; i++) across ? row * 16 + col + i : (row + i) * 16 + col,
      ];
}

class WlLevel {
  final String letters; // the letters on the wheel
  final int rows, cols;
  final List<WlWord> words;
  const WlLevel(this.letters, this.rows, this.cols, this.words);

  /// key → letter for every filled cell.
  Map<int, String> get solution {
    final m = <int, String>{};
    for (final w in words) {
      final cs = w.cells;
      for (int i = 0; i < cs.length; i++) {
        m[cs[i]] = w.text[i];
      }
    }
    return m;
  }
}

/// Word languages the puzzles exist in.
const List<String> wlWordLangs = ['en', 'fr'];

List<WlLevel> wlLevels(String lang) => lang == 'fr' ? wlLevelsFr : wlLevelsEn;

/// UI language (texts around the puzzle); Amazigh falls back to French.
String wlUiLang(BuildContext c) {
  final l = Localizations.localeOf(c).languageCode;
  return const ['fr', 'en', 'ar', 'de'].contains(l) ? l : 'fr';
}

const Map<String, Map<String, String>> _ui = {
  'title': {'en': 'Word Link', 'fr': 'Mots liés', 'ar': 'ربط الكلمات', 'de': 'Wortverbinder'},
  'level': {'en': 'Level {N}', 'fr': 'Niveau {N}', 'ar': 'المستوى {N}', 'de': 'Level {N}'},
  'found': {'en': '{F} / {T} words found', 'fr': '{F} / {T} mots trouvés', 'ar': 'وجدت {F} / {T} كلمات', 'de': '{F} / {T} Wörter gefunden'},
  'start': {'en': 'Connect letters. Discover words!', 'fr': 'Relie les lettres. Trouve les mots !', 'ar': 'صل الحروف. اكتشف الكلمات!', 'de': 'Verbinde Buchstaben. Finde Wörter!'},
  'great': {'en': 'Great!', 'fr': 'Super !', 'ar': 'رائع!', 'de': 'Toll!'},
  'oneMore': {'en': 'One more word!', 'fr': 'Encore un mot !', 'ar': 'كلمة واحدة بعد!', 'de': 'Noch ein Wort!'},
  'tryAgain': {'en': 'Try again!', 'fr': 'Essaie encore !', 'ar': 'حاول مجددًا!', 'de': 'Versuch es nochmal!'},
  'already': {'en': 'Already found!', 'fr': 'Déjà trouvé !', 'ar': 'وجدتها من قبل!', 'de': 'Schon gefunden!'},
  'listen': {'en': 'Listen… can you spell it?', 'fr': 'Écoute… sais-tu l\'écrire ?', 'ar': 'استمع… هل تستطيع كتابتها؟', 'de': 'Hör zu… kannst du es schreiben?'},
  'needGold': {'en': 'You need {C} gold for a hint', 'fr': 'Il te faut {C} or pour un indice', 'ar': 'تحتاج {C} ذهب للتلميح', 'de': 'Du brauchst {C} Gold für einen Tipp'},
  'hintMsg': {'en': 'Here\'s a letter!', 'fr': 'Voici une lettre !', 'ar': 'إليك حرفًا!', 'de': 'Hier ist ein Buchstabe!'},
  'hint': {'en': 'Hint', 'fr': 'Indice', 'ar': 'تلميح', 'de': 'Tipp'},
  'hear': {'en': 'Hear', 'fr': 'Écouter', 'ar': 'استمع', 'de': 'Hören'},
  'footer': {'en': 'Take your time and have fun!', 'fr': 'Prends ton temps et amuse-toi !', 'ar': 'خذ وقتك واستمتع!', 'de': 'Lass dir Zeit und hab Spaß!'},
  'win': {'en': 'Level complete!', 'fr': 'Niveau terminé !', 'ar': 'أكملت المستوى!', 'de': 'Level geschafft!'},
  'next': {'en': 'Next level', 'fr': 'Niveau suivant', 'ar': 'المستوى التالي', 'de': 'Nächstes Level'},
  'settings': {'en': 'Settings', 'fr': 'Réglages', 'ar': 'الإعدادات', 'de': 'Einstellungen'},
  'wordsIn': {'en': 'Words in:', 'fr': 'Mots en :', 'ar': 'الكلمات بـ:', 'de': 'Wörter auf:'},
  'restart': {'en': 'Restart level', 'fr': 'Recommencer', 'ar': 'أعد المستوى', 'de': 'Neu starten'},
  'close': {'en': 'Close', 'fr': 'Fermer', 'ar': 'إغلاق', 'de': 'Schließen'},
};

String wlText(BuildContext c, String k) {
  final m = _ui[k];
  if (m == null) return k;
  return m[wlUiLang(c)] ?? m['en']!;
}

/// Saved word language and level per language.
class WlStore {
  static const _kLang = 'wl2_lang';
  static String _kLevel(String lang) => 'wl2_level_$lang';

  static Future<String?> lang() async => (await SharedPreferences.getInstance()).getString(_kLang);

  static Future<void> setLang(String lang) async =>
      (await SharedPreferences.getInstance()).setString(_kLang, lang);

  static Future<int> level(String lang) async =>
      (await SharedPreferences.getInstance()).getInt(_kLevel(lang)) ?? 0;

  static Future<void> setLevel(String lang, int i) async =>
      (await SharedPreferences.getInstance()).setInt(_kLevel(lang), i);
}
