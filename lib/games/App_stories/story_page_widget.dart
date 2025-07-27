import 'dart:ui';

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
  final double textSize;

  const StoryPageWidget({
    super.key,
    required this.pageData,
    required this.highlightedWordIndex,
    required this.isCurrentPage,
    required this.bounceAnimation,
    required this.onCharacterTap,
    required this.textSize,
  });

  List<TextSpan> _buildTappableText(BuildContext context) {
    List<TextSpan> spans = [];
    final definitions = dic.getAllDefinitions();

    for (int i = 0; i < pageData.words.length; i++) {
      final word = pageData.words[i].replaceAll(RegExp(r'[^\w]'), '');
      final hasDefinition = definitions.containsKey(word);

      final isHighlighted = isCurrentPage && i <= highlightedWordIndex;

      spans.add(
        TextSpan(
          text: pageData.words[i] + ' ',
          style: TextStyle(
            fontSize: textSize,
            color: (isHighlighted ? Colors.deepOrange : Colors.deepOrangeAccent.withOpacity(0.6)),
            fontWeight: hasDefinition || isHighlighted ? FontWeight.bold : FontWeight.normal,
          ),
          recognizer: hasDefinition
              ? (TapGestureRecognizer()
            ..onTap = () {
              showDialog(
                context: context,
                barrierDismissible: true,
                builder: (_) => Dialog(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.menu_book_rounded, size: 50, color: Colors.orange.shade300),
                            const SizedBox(height: 10),
                            Text(
                              word,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              dic.getDefinitionFor(word),
                              style: const TextStyle(fontSize: 16, color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
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
                                  icon: const Icon(Icons.favorite_border),
                                  label: const Text("Add to Favorites"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepOrangeAccent,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.close),
                                  label: const Text("Close"),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white54),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
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
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5,),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: bounceAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, bounceAnimation.value),
                child: GestureDetector(
                  onTap: onCharacterTap,
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      pageData.imageUrl,
                      fit: BoxFit.cover,
                      width: 200,
                      height: 150,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox(
                          height: 130,
                          child: Center(
                            child: Icon(Icons.broken_image, size: 80, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),


          // Scrollable text container with blur and rounded background
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: SingleChildScrollView(
                    child: RichText(
                      text: TextSpan(
                        children: _buildTappableText(context),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
