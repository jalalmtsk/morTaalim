import 'package:flutter/material.dart';
import '../../tools/VideoPlayer.dart';
import '../../tools/YoutubePlayerPage.dart';

bool isArabic(String text) {
  final arabicRegExp = RegExp(r'[\u0600-\u06FF]');
  return arabicRegExp.hasMatch(text);
}

class SubsectionTile extends StatelessWidget {
  final Map<String, dynamic> subsection;
  final int depth;

  const SubsectionTile({super.key, required this.subsection, this.depth = 0});

  @override
  Widget build(BuildContext context) {
    final isRTL = isArabic(subsection['title']);
    final hasChildren = subsection['subsections'] != null;

    return ExpansionTile(
      tilePadding: EdgeInsets.only(left: 16.0 * depth, right: 16),
      title: Directionality(
        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
        child: Text(
          subsection['title'],
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple.shade700,
          ),
        ),
      ),
      children: [
        if (subsection['content'] != null && subsection['content'].toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Directionality(
              textDirection: isArabic(subsection['content']) ? TextDirection.rtl : TextDirection.ltr,
              child: Text(
                subsection['content'],
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
          ),
        if (subsection['controller'] != null &&
            subsection['controller'].toString().trim().isNotEmpty)
          subsection['type'] == 'youtube'
              ? YouTubeSectionPlayer(videoUrl: subsection['controller'])
              : SectionVlcPlayer(videoPath: subsection['controller']),
        if (hasChildren)
          ...subsection['subsections']
              .map<Widget>((child) => SubsectionTile(subsection: child, depth: depth + 1))
              .toList(),
      ],
    );
  }
}
