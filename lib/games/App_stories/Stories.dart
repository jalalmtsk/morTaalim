import 'story_page_data.dart';

class Story {
  final String title;
  final List<StoryPageData> pages;
  final String? thumbnail;


  Story({
    required this.title,
    required this.pages,
    required this.thumbnail,
  });
}
