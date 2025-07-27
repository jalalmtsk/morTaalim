import 'Stories.dart';
import 'story_page_data.dart';

final List<Story> stories = [
  Story(
    title: 'Flick the Dancing Fox',
    thumbnail: 'assets/images/StoriesImages/StoriesCovers/TheDancingFox_cover.png',
  pages: [

      // FIRST STORY /////
      StoryPageData(
        words: [
          'Once', 'upon', 'a', 'time,', 'there', 'was', 'a', 'silly', 'fox',
          'named', 'Flick,', 'who', 'loved', 'to', 'dance', 'in', 'the', 'rain.'
        ],
        imageUrl: 'assets/images/StoriesImages/InsideStoriesImages/FoxDancingOnRain_Story.png',
        characterName: 'Flick',
        funnyLine: 'Oops! He slipped and did a funny twirl!',
      ),
      StoryPageData(
        words: [
          'Flick', 'decided', 'to', 'invite', 'his', 'best', 'friend,', 'Benny', 'the', 'bunny,',
          'to', 'join', 'the', 'rain', 'dance', 'party.'
        ],
        imageUrl: 'assets/images/StoriesImages/InsideStoriesImages/FoxDancingWithFriends_Story.png',
        characterName: 'Benny',
        funnyLine: 'Benny tried to hop but ended up splashing mud everywhere!',
      ),
      StoryPageData(
        words: [
          'Together,', 'they', 'danced', 'and', 'laughed,', 'making', 'the', 'forest', 'a', 'happier', 'place.',
          'Suddenly,', 'a', 'rainbow', 'appeared,', 'and', 'Flick', 'wished', 'for', 'more', 'adventures.'
        ],
        imageUrl: 'assets/images/StoriesImages/InsideStoriesImages/FoxMud_Story.png',
        characterName: 'Flick & Benny',
        funnyLine: 'Rainbow magic made Benny\'s ears glow bright pink!',
      ),
    ],
  ),

  /// SECOND STORYY   EN
  Story(
    title: 'Sunny the Squirrel',
    thumbnail: 'assets/images/StoriesImages/StoriesCovers/SunnyTheSquirrel_cover.png',
    pages: [
      StoryPageData(
        words: [
          'Sunny', 'the', 'cheerful', 'squirrel', 'found', 'a', 'big', 'pile', 'of', 'acorns',
          'and', 'decided', 'to', 'share', 'them', 'with', 'his', 'friends', 'in', 'the', 'forest.'
        ],
        imageUrl: 'assets/images/StoriesImages/InsideStoriesImages/SquirrelEating_Story.png',
        characterName: 'Sunny',
        funnyLine: 'Sunny accidentally buried one acorn in his own hat!',
      ),
      // Add 2 more pages here for Sunny story...
      StoryPageData(
        words: [
          'Sunny', 'and', 'his', 'friends', 'had', 'a', 'wonderful', 'feast', 'under', 'the', 'big', 'oak', 'tree.'
        ],
        imageUrl: 'assets/images/StoriesImages/InsideStoriesImages/SquirrelHappyWithFriends_Story.png',
        characterName: 'Sunny & Friends',
        funnyLine: 'They laughed so much the acorns almost rolled away!',
      ),
      StoryPageData(
        words: [
          'At', 'the', 'end', 'of', 'the', 'day,', 'Sunny', 'felt', 'happy', 'and', 'thankful', 'for', 'his', 'friends.'
        ],
        imageUrl: 'assets/images/StoriesImages/InsideStoriesImages/SquirrelSharing_Story.png',
        characterName: 'Sunny',
        funnyLine: 'Sunny\'s tail was fluffier than ever!',
      ),
    ],
  ),

  /// THIRD STORY EN /////

  Story(
    title: 'Nina the Sleepy Narwhal',
    thumbnail: 'assets/images/StoriesImages/StoriesCovers/NinaTheNarwhale_cover.png',
    pages: [
      StoryPageData(
        words: [
          'In', 'the', 'deep', 'blue', 'sea,', 'lived', 'a', 'sleepy', 'narwhal', 'named', 'Nina.',
          'She', 'loved', 'to', 'nap', 'everywhere—even', 'on', 'top', 'of', 'a', 'jellyfish!'
        ],
        imageUrl: 'assets/images/StoriesImages/InsideStoriesImages/NinaAndJellyFish_Story.png',
        characterName: 'Nina',
        funnyLine: 'Zzz... *BOING!* The jellyfish bounced her like a trampoline!',
      ),
      StoryPageData(
        words: [
          'One', 'day,', 'Nina', 'tried', 'to', 'nap', 'on', 'a', 'sea', 'turtle,', 'but',
          'it', 'started', 'swimming', 'fast!', 'Wheee!'
        ],
        imageUrl: 'assets/images/StoriesImages/InsideStoriesImages/NinaScreaming_Story.png',
        characterName: 'Speedy Turtle',
        funnyLine: 'Nina yelled, "I’m not a surfboard!" as she zoomed across the waves!',
      ),
      StoryPageData(
        words: [
          'At', 'last,', 'Nina', 'found', 'a', 'quiet', 'spot', 'on', 'a', 'rock.',
          'But—SURPRISE!—it', 'was', 'a', 'sleeping', 'octopus!'
        ],
        imageUrl: 'assets/images/StoriesImages/InsideStoriesImages/NinaAndOctopus_Story.png',
        characterName: 'Ollie the Octopus',
        funnyLine: 'Ollie woke up, gave her a hug with all 8 arms, and said, "Best nap ever!"',
      ),
    ],
  ),

];
