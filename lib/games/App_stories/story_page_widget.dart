import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'favorite_Word/favorite_word_dictionnary.dart';
import 'story_page_data.dart';
import 'package:mortaalim/games/App_stories/definition_Dic/word_define_story.dart' as dic;

class StoryPageWidget extends StatelessWidget {
  final StoryPageData pageData;
  final int highlightedWordIndex;
  final bool isCurrentPage;
  final Animation<double> bounceAnimation;
  final VoidCallback onCharacterTap;

  const StoryPageWidget({
    super.key,
    required this.pageData,
    required this.highlightedWordIndex,
    required this.isCurrentPage,
    required this.bounceAnimation,
    required this.onCharacterTap,
  });

  List<TextSpan> _buildTappableText(BuildContext context) {
    List<TextSpan> spans = [];
    final definitions = dic.getAllDefinitions();

    for (int i = 0; i < pageData.words.length; i++) {
      final word = pageData.words[i].replaceAll(RegExp(r'[^\w]'), '');
      final hasDefinition = definitions.containsKey(word);

      // Add your highlighting logic here
      final isHighlighted = isCurrentPage && i <= highlightedWordIndex;

      spans.add(
        TextSpan(
          text: pageData.words[i] + ' ',
          style: TextStyle(
            fontSize: 35, // keep text big and beautiful
            color: hasDefinition
                ? Colors.blue
                : (isHighlighted ? Colors.deepOrange : Colors.black54), // highlight orange if highlighted
            fontWeight: hasDefinition || isHighlighted ? FontWeight.bold : FontWeight.normal,
            decoration: hasDefinition ? TextDecoration.underline : TextDecoration.none,
          ),
          recognizer: hasDefinition
              ? (TapGestureRecognizer()
            ..onTap = () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(word),
                  content: Text(dic.getDefinitionFor(word)),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        await FavoriteWordsManager.addWord(word, dic.getDefinitionFor(word));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('"$word" added to favorites'),
                            backgroundColor: Colors.deepOrange,
                          ),
                        );
                      },
                      child: const Text('Add to Favorites'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            })
              : null,
        ),
      );
    }
    return spans;
  }



  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: bounceAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, bounceAnimation.value),
                child: GestureDetector(
                  onTap: onCharacterTap,
                  child: Image.asset(
                    pageData.imageUrl,
                    height: 310,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.broken_image, size: 200, color: Colors.grey);
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
          RichText(
            text: TextSpan(
              children: _buildTappableText(context),
            ),
          ),
        ],
      ),
    );
  }
}
