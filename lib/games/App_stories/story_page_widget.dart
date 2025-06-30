import 'package:flutter/material.dart';
import 'package:mortaalim/games/App_stories/story_page_data.dart';

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

  List<TextSpan> _buildHighlightedText() {
    List<TextSpan> spans = [];
    for (int i = 0; i < pageData.words.length; i++) {
      final isHighlighted = isCurrentPage && i <= highlightedWordIndex;
      spans.add(TextSpan(
        text: pageData.words[i] + ' ',
        style: TextStyle(
          color: isHighlighted ? Colors.deepOrange : Colors.black54,
          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
          fontSize: 22,
        ),
      ));
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
                  child: Image.network(
                    pageData.imageUrl,
                    height: 250,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
          RichText(
            text: TextSpan(
              children: _buildHighlightedText(),
            ),
          ),
        ],
      ),
    );
  }
}
