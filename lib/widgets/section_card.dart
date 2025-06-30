import 'package:flutter/material.dart';
import '../../tools/VideoPlayer.dart';
import '../../tools/YoutubePlayerPage.dart';
import 'subsection_tile.dart';

bool isArabic(String text) {
  final arabicRegExp = RegExp(r'[\u0600-\u06FF]');
  return arabicRegExp.hasMatch(text);
}

class SectionCard extends StatefulWidget {
  final Map<String, dynamic> section;
  final bool isDone;
  final int index;
  final void Function(int) toggle;

  const SectionCard({
    super.key,
    required this.section,
    required this.isDone,
    required this.index,
    required this.toggle, required MaterialAccentColor highlightColor,
  });

  @override
  _SectionCardState createState() => _SectionCardState();
}

class _SectionCardState extends State<SectionCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      lowerBound: 0.8,
      upperBound: 1.0,
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);

    if (widget.isDone) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant SectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDone && !oldWidget.isDone) {
      _controller.forward();
    } else if (!widget.isDone && oldWidget.isDone) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
          child: ExpansionTile(
            key: Key('${widget.index}'),
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Row(
              children: [
                Expanded(
                  child: Directionality(
                    textDirection: isArabic(widget.section['title']) ? TextDirection.rtl : TextDirection.ltr,
                    child: Text(
                      widget.section['title'],
                      textAlign: isArabic(widget.section['title']) ? TextAlign.right : TextAlign.left,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.deepOrange,
                        fontFamily: isArabic(widget.section['title']) ? 'Amiri' : null,
                      ),
                    ),
                  ),
                ),
                Checkbox(
                  value: widget.isDone,
                  activeColor: Colors.deepOrange,
                  onChanged: (_) => widget.toggle(widget.index),
                ),
              ],
            ),
            children: [
              if (widget.section['content'] != null && widget.section['content'].toString().trim().isNotEmpty)
                Directionality(
                  textDirection: isArabic(widget.section['content']) ? TextDirection.rtl : TextDirection.ltr,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.section['content'],
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.deepOrange.shade900,
                        fontWeight: FontWeight.w600,
                        fontFamily: isArabic(widget.section['content']) ? 'Amiri' : null,
                      ),
                    ),
                  ),
                ),
              if (widget.section['controller'] != null && widget.section['controller'].toString().trim().isNotEmpty)
                widget.section['type'] == 'youtube'
                    ? YouTubeSectionPlayer(videoUrl: widget.section['controller'])
                    : SectionVlcPlayer(videoPath: widget.section['controller']),
              if (widget.section['subsections'] != null)
                ...widget.section['subsections']
                    .map<Widget>((sub) => SubsectionTile(subsection: sub))
                    .toList(),
            ],
          ),
        ),
      ),
    );
  }
}
