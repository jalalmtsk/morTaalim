import 'Stories.dart';
import 'story_page_data.dart';

final List<Story> stories = [
  Story(
    title: 'Flick the Dancing Fox',
    pages: [
      StoryPageData(
        words: [
          'Once', 'upon', 'a', 'time,', 'there', 'was', 'a', 'silly', 'fox',
          'named', 'Flick,', 'who', 'loved', 'to', 'dance', 'in', 'the', 'rain.'
        ],
        imageUrl: 'assets/images/et.png',
        characterName: 'Flick',
        funnyLine: 'Oops! He slipped and did a funny twirl!',
      ),
      StoryPageData(
        words: [
          'Flick', 'decided', 'to', 'invite', 'his', 'best', 'friend,', 'Benny', 'the', 'bunny,',
          'to', 'join', 'the', 'rain', 'dance', 'party.'
        ],
        imageUrl: 'https://i.imgur.com/MT2Hg6P.png',
        characterName: 'Benny',
        funnyLine: 'Benny tried to hop but ended up splashing mud everywhere!',
      ),
      StoryPageData(
        words: [
          'Together,', 'they', 'danced', 'and', 'laughed,', 'making', 'the', 'forest', 'a', 'happier', 'place.',
          'Suddenly,', 'a', 'rainbow', 'appeared,', 'and', 'Flick', 'wished', 'for', 'more', 'adventures.'
        ],
        imageUrl: 'https://i.imgur.com/PMjRJ9N.png',
        characterName: 'Flick & Benny',
        funnyLine: 'Rainbow magic made Benny\'s ears glow bright pink!',
      ),
    ],
  ),
  Story(
    title: 'Sunny the Squirrel',
    pages: [
      StoryPageData(
        words: [
          'Sunny', 'the', 'cheerful', 'squirrel', 'found', 'a', 'big', 'pile', 'of', 'acorns',
          'and', 'decided', 'to', 'share', 'them', 'with', 'his', 'friends', 'in', 'the', 'forest.'
        ],
        imageUrl: 'https://i.imgur.com/GQ6PxvQ.png',
        characterName: 'Sunny',
        funnyLine: 'Sunny accidentally buried one acorn in his own hat!',
      ),
      // Add 2 more pages here for Sunny story...
      StoryPageData(
        words: [
          'Sunny', 'and', 'his', 'friends', 'had', 'a', 'wonderful', 'feast', 'under', 'the', 'big', 'oak', 'tree.'
        ],
        imageUrl: 'https://i.imgur.com/YOUR_IMAGE2.png',
        characterName: 'Sunny & Friends',
        funnyLine: 'They laughed so much the acorns almost rolled away!',
      ),
      StoryPageData(
        words: [
          'At', 'the', 'end', 'of', 'the', 'day,', 'Sunny', 'felt', 'happy', 'and', 'thankful', 'for', 'his', 'friends.'
        ],
        imageUrl: 'https://i.imgur.com/YOUR_IMAGE3.png',
        characterName: 'Sunny',
        funnyLine: 'Sunny\'s tail was fluffier than ever!',
      ),
    ],
  ),
];
