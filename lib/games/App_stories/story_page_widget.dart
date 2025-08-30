import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'definition_Dic/word_Pronouniciation.dart' as dict;
import 'definition_Dic/word_definition.dart' as dic;
import 'story_page_data.dart';
import 'favorite_Word/favorite_word_dictionnary.dart';
import 'LanguageManager.dart';

class StoryPageWidget extends StatefulWidget {
  final StoryPageData pageData;
  final int highlightedWordIndex;
  final bool isCurrentPage;
  final Animation<double> bounceAnimation;
  final VoidCallback onCharacterTap;
  final double textSize;
  final AppLanguage language;

  StoryPageWidget({
    super.key,
    required this.pageData,
    required this.highlightedWordIndex,
    required this.isCurrentPage,
    required this.bounceAnimation,
    required this.onCharacterTap,
    required this.textSize,
    required this.language,
  });

  @override
  State<StoryPageWidget> createState() => _StoryPageWidgetState();
}

class _StoryPageWidgetState extends State<StoryPageWidget> {
  final FlutterTts flutterTts = FlutterTts();

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }
  // --- Show Definition Dialog ---
  void _showDefinitionDialog(BuildContext context, String word) {
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
            child: SingleChildScrollView(
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
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      dic.getDefinitionFor(word, widget.language),
                      style: const TextStyle(fontSize: 16, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            await FavoriteWordsManager.addWord(word, dic.getDefinitionFor(word, widget.language));
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
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
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
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
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
      ),
    );
  }

  // --- Build tappable words ---
  List<InlineSpan> _buildTappableText(BuildContext context, bool isRtl) {
    final words = widget.pageData.getWords(widget.language);
    // Remove manual reversal
    final spans = <InlineSpan>[];

    for (int i = 0; i < words.length; i++) {
      final word = words[i].replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');
      final isHighlighted = widget.isCurrentPage && i <= widget.highlightedWordIndex;
      final definition = dic.getDefinitionFor(word, widget.language);
      final hasDefinition = definition != 'No definition found.';

      final wordKey = GlobalKey();

      spans.add(WidgetSpan(
        child: GestureDetector(
          key: wordKey,
          onTap: hasDefinition
              ? () async {
            final pronunciation = dict.getPronunciationFor(word, widget.language);
            _showPronunciationOverlay(context, wordKey, pronunciation);

            await flutterTts.setLanguage(_getTtsLanguage(widget.language));
            await flutterTts.speak(word);
          }
              : null,
          onLongPress: hasDefinition ? () => _showDefinitionDialog(context, word) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Text(
              words[i], // keep original order
              style: TextStyle(
                fontSize: widget.textSize,
                color: isHighlighted
                    ? Colors.deepOrange
                    : Colors.deepOrangeAccent.withOpacity(0.6),
                fontWeight: hasDefinition || isHighlighted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ));
    }

    return spans;
  }



  String _getTtsLanguage(AppLanguage language) {
    switch (language) {
      case AppLanguage.en:
        return "en-US";
      case AppLanguage.fr:
        return "fr-FR";
      case AppLanguage.ar:
        return "ar-SA";
      case AppLanguage.de:
        return "de-DE";
      case AppLanguage.es:
        return "es-ES";
      case AppLanguage.it:
        return "it-IT";
      case AppLanguage.zh:
        return "zh-CN";
      case AppLanguage.ko:
        return "ko-KR";
      default:
        return "en-US";
    }
  }

  // --- Show Pronunciation Dialog ---
  void _showPronunciationDialog(BuildContext context, String word) {
    final pronunciation = dict.getPronunciationFor(word, widget.language);
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
                children: [
                  Icon(Icons.volume_up_rounded, size: 50, color: Colors.orange.shade300),
                  const SizedBox(height: 10),
                  Text(
                    word,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    pronunciation,
                    style: const TextStyle(fontSize: 18, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPronunciationOverlay(BuildContext context, GlobalKey key, String pronunciation) {
    final overlay = Overlay.of(context);
    final renderBox = key.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    final entry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy - 40,
        width: size.width + 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              pronunciation,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), () => entry.remove());
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = widget.language == AppLanguage.ar || widget.language == AppLanguage.amazigh;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        children: [
          // --- Character Image with Bounce ---
          AnimatedBuilder(
            animation: widget.bounceAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, widget.bounceAnimation.value),
                child: GestureDetector(
                  onTap: widget.onCharacterTap,
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      widget.pageData.imageUrl,
                      fit: BoxFit.cover,
                      width: 200,
                      height: 150,
                      errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(
                        height: 130,
                        child: Center(
                          child: Icon(Icons.broken_image, size: 80, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // --- Text Content ---
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
                      text: TextSpan(children: _buildTappableText(context, isRtl)),
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