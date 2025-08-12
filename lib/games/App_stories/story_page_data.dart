class StoryPageData {
  final List<String> words;
  final String imageUrl;
  final String characterName;
  final String funnyLine;

  // New optional field for Arabic audio asset path
  final String? arabicAudioPath;

  StoryPageData({
    required this.words,
    required this.imageUrl,
    required this.characterName,
    required this.funnyLine,
    this.arabicAudioPath,
  });

  String get fullText => words.join(' ');
}
