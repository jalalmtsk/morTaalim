import 'story_page_data.dart';
import 'LanguageManager.dart';

class Story {
  final String title;
  final String? thumbnail;
  final List<StoryPageData> pages;

  Story({required this.title, this.thumbnail, required this.pages});
}
