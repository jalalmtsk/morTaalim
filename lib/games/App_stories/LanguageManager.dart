import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  en,  // English
  fr,  // French
  ar,  // Arabic
  de,  // German
  es,  // Spanish
  amazigh,  // Amazigh
  ru,  // Russian
  it,  // Italian
  zh,  // Chinese (Mandarin)
  ko,  // Korean
}


class LanguageManager {
  static const _key = 'selected_language';

  static Future<void> setLanguage(AppLanguage lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, lang.name);
  }

  static Future<AppLanguage> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final langStr = prefs.getString(_key) ?? 'en';
    return AppLanguage.values.firstWhere((e) => e.name == langStr);
  }
}
