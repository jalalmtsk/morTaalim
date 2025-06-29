import 'package:flutter/material.dart';
import '../../tools/VideoPlayer.dart';
import '../../tools/YoutubePlayerPage.dart';
import 'subsection_tile.dart';

bool isArabic(String text) {
  final arabicRegExp = RegExp(r'[\u0600-\u06FF]');
  return arabicRegExp.hasMatch(text);
}

class SectionCard extends StatelessWidget {
  final Map<String, dynamic> section;
  final bool isDone;
  final int index;
  final void Function(int) toggle;

  const SectionCard({
    super.key,
    required this.section,
    required this.isDone,
    required this.index,
    required this.toggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: ExpansionTile(
          key: Key('$index'),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Row(
            children: [
              Expanded(
                child: Directionality(
                  textDirection: isArabic(section['title']) ? TextDirection.rtl : TextDirection.ltr,
                  child: Text(
                    section['title'],
                    textAlign: isArabic(section['title']) ? TextAlign.right : TextAlign.left,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.deepPurple,
                      fontFamily: isArabic(section['title']) ? 'Amiri' : null,
                    ),
                  ),
                ),
              ),
              Checkbox(
                value: isDone,
                activeColor: Colors.deepPurple,
                onChanged: (_) => toggle(index),
              ),
            ],
          ),
          children: [
            if (section['content'] != null && section['content'].toString().trim().isNotEmpty)
              Directionality(
                textDirection: isArabic(section['content']) ? TextDirection.rtl : TextDirection.ltr,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    section['content'],
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.deepPurple.shade900,
                      fontWeight: FontWeight.w600,
                      fontFamily: isArabic(section['content']) ? 'Amiri' : null,
                    ),
                  ),
                ),
              ),
            if (section['controller'] != null &&
                section['controller'].toString().trim().isNotEmpty)
              section['type'] == 'youtube'
                  ? YouTubeSectionPlayer(videoUrl: section['controller'])
                  : SectionVlcPlayer(videoPath: section['controller']),
            if (section['subsections'] != null)
              ...section['subsections']
                  .map<Widget>((sub) => SubsectionTile(subsection: sub))
                  .toList(),
          ],
        ),
      ),
    );
  }
}
