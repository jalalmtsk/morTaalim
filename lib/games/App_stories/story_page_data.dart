class StoryPageData {
  final List<String> words;
  final String imageUrl;
  final String characterName;
  final String funnyLine;

  StoryPageData({
    required this.words,
    required this.imageUrl,
    required this.characterName,
    required this.funnyLine,
  });

  String get fullText => words.join(' ');
}
