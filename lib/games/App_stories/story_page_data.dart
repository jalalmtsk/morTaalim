import 'LanguageManager.dart';

class StoryPageData {
  final Map<AppLanguage, List<String>> wordsByLang;
  final String imageUrl;
  final String characterName;
  final String funnyLine;

  StoryPageData({
    required this.wordsByLang,
    required this.imageUrl,
    required this.characterName,
    required this.funnyLine,
  });

  List<String> getWords(AppLanguage lang) => wordsByLang[lang] ?? wordsByLang[AppLanguage.en]!;
  String get fullText => getWords(AppLanguage.en).join(' '); // default English for TTS
}
