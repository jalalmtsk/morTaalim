import 'dart:math' as math;
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
  final int highlightedWordIndex; // -1 = nothing highlighted
  final bool isCurrentPage;
  final Animation<double> bounceAnimation;
  final VoidCallback onCharacterTap;
  final double textSize;
  final AppLanguage language;
  final bool nightMode;
  final Color accentColor;

  const StoryPageWidget({
    super.key,
    required this.pageData,
    required this.highlightedWordIndex,
    required this.isCurrentPage,
    required this.bounceAnimation,
    required this.onCharacterTap,
    required this.textSize,
    required this.language,
    this.nightMode = false,
    this.accentColor = const Color(0xFFFF7043),
  });

  @override
  State<StoryPageWidget> createState() => _StoryPageWidgetState();
}

class _StoryPageWidgetState extends State<StoryPageWidget> with TickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  // Sparkle animations keyed by word index string
  final Map<String, AnimationController> _sparkles = {};
  String? _lastTappedKey;

  // BUG FIX 1: we store the overlay entry so we can remove it cleanly
  OverlayEntry? _pronEntry;

  @override
  void dispose() {
    _tts.stop();
    for (final c in _sparkles.values) c.dispose();
    _pronEntry?.remove();
    super.dispose();
  }

  AnimationController _getSparkle(String key) {
    return _sparkles.putIfAbsent(key, () {
      final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
      c.addStatusListener((s) { if (s == AnimationStatus.completed) c.reverse(); });
      return c;
    });
  }

  String _ttsLang(AppLanguage l) {
    switch (l) {
      case AppLanguage.fr:      return 'fr-FR';
      case AppLanguage.ar:      return 'ar-SA';
      case AppLanguage.de:      return 'de-DE';
      case AppLanguage.es:      return 'es-ES';
      case AppLanguage.amazigh: return 'fr-FR';
      case AppLanguage.ru:      return 'ru-RU';
      case AppLanguage.it:      return 'it-IT';
      case AppLanguage.zh:      return 'zh-CN';
      case AppLanguage.ko:      return 'ko-KR';
      default:                  return 'en-US';
    }
  }

  // ── BUG FIX 1: Pronunciation bubble ───────────────────────────────────────
  // Root cause of squares: GlobalKey lookup on a WidgetSpan inside a rebuilt
  // RichText returns stale or null RenderBox → zero-width container → font
  // can't lay out IPA glyphs → □□□.
  //
  // Fix: use the RAW TAP POSITION (TapUpDetails.globalPosition) from
  // GestureDetector instead of a GlobalKey lookup. This is always available
  // and never stale.
  void _showPronTooltip(BuildContext context, Offset tapPosition, String pronunciation) {
    if (pronunciation.isEmpty || pronunciation == 'Pronunciation not found') return;
    _pronEntry?.remove();
    _pronEntry = null;

    final screenW = MediaQuery.of(context).size.width;
    // Place bubble above the finger; clamp so it never goes off-screen
    final left = (tapPosition.dx - 60).clamp(8.0, screenW - 160.0);
    final top  = (tapPosition.dy - 62).clamp(8.0, double.infinity);

    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: left,
        top:  top,
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(maxWidth: screenW - 32, minWidth: 80),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: widget.accentColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: widget.accentColor.withOpacity(0.50),
                  blurRadius: 12, offset: const Offset(0, 3),
                ),
              ],
            ),
            // softWrap:false + intrinsic sizing so IPA text never wraps into squares
            child: IntrinsicWidth(
              child: Text(
                pronunciation,
                softWrap: false,
                overflow: TextOverflow.visible,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  // Fallback font chain covers IPA + Arabic + CJK + Korean
                  fontFamilyFallback: ['NotoSans', 'NotoSansArabic', 'NotoSerif', 'Roboto'],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(entry);
    _pronEntry = entry;
    Future.delayed(const Duration(seconds: 2), () {
      entry.remove();
      if (_pronEntry == entry) _pronEntry = null;
    });
  }

  // ── Definition dialog ──────────────────────────────────────────────────────
  void _showDefinitionDialog(BuildContext context, String word) {
    final definition = dic.getDefinitionFor(word, widget.language);
    final pron = dict.getPronunciationFor(word, widget.language);
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: widget.nightMode ? Colors.black.withOpacity(0.72) : Colors.white.withOpacity(0.88),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: widget.accentColor.withOpacity(0.4), width: 2),
              ),
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu_book_rounded, size: 48, color: widget.accentColor),
                  const SizedBox(height: 12),
                  Text(word,
                    style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w900,
                      color: widget.nightMode ? Colors.white : const Color(0xFF2D1200),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  if (pron != 'Pronunciation not found')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(pron,
                        style: TextStyle(
                          fontSize: 15, fontStyle: FontStyle.italic,
                          color: widget.accentColor, fontWeight: FontWeight.w600,
                          fontFamilyFallback: const ['NotoSans', 'NotoSansArabic', 'NotoSerif'],
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  Text(definition,
                    style: TextStyle(
                      fontSize: 16, height: 1.5,
                      color: widget.nightMode ? Colors.white70 : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.accentColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        icon: const Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
                        label: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          await FavoriteWordsManager.addWord(word, definition);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('⭐ "$word" saved!'),
                            backgroundColor: widget.accentColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ));
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: widget.nightMode ? Colors.white : const Color(0xFF2D1200),
                          side: BorderSide(color: widget.nightMode ? Colors.white30 : Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Sparkle widgets ────────────────────────────────────────────────────────
  List<Widget> _buildSparkles(Animation<double> anim) {
    const colors = [Colors.amber, Colors.pinkAccent, Colors.lightBlueAccent, Colors.greenAccent];
    return List.generate(4, (i) {
      final angle  = (i / 4) * 2 * math.pi;
      final radius = anim.value * 22.0;
      return Positioned(
        left: 6 + radius * math.cos(angle),
        top: -2 + radius * math.sin(angle),
        child: Opacity(
          opacity: (1 - anim.value).clamp(0.0, 1.0),
          child: Text('✦', style: TextStyle(fontSize: 10, color: colors[i % 4])),
        ),
      );
    });
  }

  // ── BUG FIX 2: Word color highlighting ────────────────────────────────────
  // Root cause: when parent passes a new highlightedWordIndex, Flutter may
  // reuse the widget and skip rebuild if no local state changed.
  // Fix: override didUpdateWidget to force setState whenever the highlight index
  // or language changes — this guarantees _buildTappableText re-runs with
  // fresh highlight values.
  @override
  void didUpdateWidget(StoryPageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.highlightedWordIndex != widget.highlightedWordIndex ||
        oldWidget.language != widget.language ||
        oldWidget.isCurrentPage != widget.isCurrentPage) {
      setState(() {}); // force rebuild so word colors update
    }
  }

  // ── Build tappable word spans ──────────────────────────────────────────────
  List<InlineSpan> _buildTappableText(BuildContext context, bool isRtl) {
    final words    = widget.pageData.getWords(widget.language);
    final spans    = <InlineSpan>[];

    // Color scheme for highlighted vs normal words
    final hiColor  = widget.accentColor;
    final hiShadow = [Shadow(color: hiColor.withOpacity(0.45), blurRadius: 8)];
    final baseColor = widget.nightMode
        ? Colors.white.withOpacity(0.82)
        : Colors.black87;

    for (int i = 0; i < words.length; i++) {
      final rawWord    = words[i];
      final cleanWord  = rawWord.replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');
      // BUG FIX 2: highlighted = true if this word has been spoken
      final isHi       = widget.isCurrentPage &&
          widget.highlightedWordIndex >= 0 &&
          i <= widget.highlightedWordIndex;
      final definition = dic.getDefinitionFor(cleanWord, widget.language);
      final hasDef     = definition != 'No definition found.';
      final pron       = dict.getPronunciationFor(cleanWord, widget.language);
      final sparkleKey = 'sp_${i}_${widget.language.name}';

      final wordStyle = TextStyle(
        fontSize: widget.textSize,
        // BUG FIX 2: explicit color per word — not inherited/cached
        color: isHi ? hiColor : baseColor,
        fontWeight: isHi || hasDef ? FontWeight.bold : FontWeight.w500,
        decoration: hasDef ? TextDecoration.underline : TextDecoration.none,
        decorationStyle: TextDecorationStyle.dotted,
        decorationColor: widget.accentColor.withOpacity(0.6),
        height: 1.7,
        shadows: isHi ? hiShadow : null,
        // Background highlight for the currently spoken word
        backgroundColor: isHi && i == widget.highlightedWordIndex
            ? widget.accentColor.withOpacity(0.12)
            : null,
      );

      if (isRtl) {
        // For RTL we must use TextSpan (WidgetSpan breaks RTL text flow)
        spans.add(TextSpan(
          text: '$rawWord ',
          style: wordStyle,
          recognizer: hasDef
              ? (TapGestureRecognizer()
            ..onTapUp = (d) async {
              _showPronTooltip(context, d.globalPosition, pron);
              await _tts.setLanguage(_ttsLang(widget.language));
              await _tts.speak(cleanWord);
            })
              : null,
        ));
      } else {
        final sparkle = _getSparkle(sparkleKey);
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: GestureDetector(
            // BUG FIX 1: use onTapUp to get the tap position
            onTapUp: hasDef
                ? (d) async {
              setState(() => _lastTappedKey = sparkleKey);
              sparkle.forward(from: 0);
              _showPronTooltip(context, d.globalPosition, pron);
              await _tts.setLanguage(_ttsLang(widget.language));
              await _tts.speak(cleanWord);
            }
                : null,
            onLongPress: hasDef ? () => _showDefinitionDialog(context, cleanWord) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 2),
              child: AnimatedBuilder(
                animation: sparkle,
                builder: (_, child) => Transform.scale(
                  scale: 1.0 + sparkle.value * 0.25,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      child!,
                      if (_lastTappedKey == sparkleKey && sparkle.value > 0)
                        ..._buildSparkles(sparkle),
                    ],
                  ),
                ),
                child: Text(rawWord, style: wordStyle),
              ),
            ),
          ),
        ));
      }
    }
    return spans;
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isRtl = widget.language == AppLanguage.ar || widget.language == AppLanguage.amazigh;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        children: [

          // Character image with bounce
          AnimatedBuilder(
            animation: widget.bounceAnimation,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, widget.bounceAnimation.value),
              child: child,
            ),
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                GestureDetector(
                  onTap: widget.onCharacterTap,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: widget.accentColor.withOpacity(0.30), blurRadius: 18, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        widget.pageData.imageUrl,
                        width: 210, height: 155, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(
                          width: 210, height: 155,
                          child: Center(child: Icon(Icons.broken_image, size: 60, color: Colors.grey)),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: widget.accentColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: widget.accentColor.withOpacity(0.4), blurRadius: 6)],
                    ),
                    child: const Text('💬 Tap me!',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Hint bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: widget.accentColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '👆 Tap word = hear it  •  Hold = definition',
              style: TextStyle(
                fontSize: 11,
                color: widget.nightMode ? Colors.white54 : widget.accentColor.withOpacity(0.70),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Story text
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.nightMode ? Colors.black.withOpacity(0.22) : Colors.white.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.nightMode ? Colors.white12 : widget.accentColor.withOpacity(0.15),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Directionality(
                      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                      child: RichText(
                        // BUG FIX 2: key = highlight index + language forces Flutter
                        // to rebuild the RichText widget (and its spans) whenever
                        // either value changes — no more stale cached colors.
                        key: ValueKey('rt_${widget.highlightedWordIndex}_${widget.language.name}_${widget.isCurrentPage}'),
                        textAlign: isRtl ? TextAlign.right : TextAlign.left,
                        text: TextSpan(children: _buildTappableText(context, isRtl)),
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