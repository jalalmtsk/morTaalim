import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../tools/YoutubePlayerPage.dart';
import '../tools/audio_tool.dart';
import '../widgets/userStatutBar.dart';

class CourseNodePage extends StatefulWidget {
  final Map<String, dynamic> node;
  final String? parentTitle;

  const CourseNodePage({super.key, required this.node, this.parentTitle});

  @override
  State<CourseNodePage> createState() => _CourseNodePageState();
}

class _CourseNodePageState extends State<CourseNodePage> with TickerProviderStateMixin {
  late final MusicPlayer _musicPlayer;

  final List<String> emojiList = ['🦄', '🐸', '🐱', '🐵', '🐥', '🐳', '🎩', '🧸', '🍭', '🎈'];

  bool isPlaying = false;

  bool isArabic(String text) {
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    return arabicRegex.hasMatch(text);
  }

  @override
  void initState() {
    super.initState();
    _musicPlayer = MusicPlayer();
  }

  @override
  void dispose() {
    _musicPlayer.dispose();
    super.dispose();
  }

  Widget buildMediaWidget(String? type, String? videoController, String? audioController) {
    if ((videoController == null || videoController.isEmpty) && (audioController == null || audioController.isEmpty)) {
      return const SizedBox.shrink();
    }

    bool isYouTubeLink(String url) {
      return url.contains('youtube.com') || url.contains('youtu.be');
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 9,
      shadowColor: Colors.pink.shade200,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            if (type == 'video' && videoController != null && videoController.isNotEmpty)
                  YouTubeSectionPlayer(videoUrl: videoController)
          ],
        ),
      ),
    );
  }

  Route _createRoute(Map<String, dynamic> node, String? parentTitle) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => CourseNodePage(node: node, parentTitle: parentTitle),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fade = Tween(begin: 0.0, end: 1.0).animate(animation);
        final slide = Tween(begin: const Offset(0, 0.2), end: Offset.zero).animate(animation);
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }

  void showSubsectionsModal(List<dynamic> subsections) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.pink.shade50,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset('assets/animations/catPlaying.json', height: 110),
              const Text(
                "✨ محتوى إضافي!",
                style: TextStyle(
                  fontFamily: 'ComicNeue',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: subsections.map((sub) {
                  final emoji = emojiList[Random().nextInt(emojiList.length)];
                  return ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.primaries[Random().nextInt(Colors.primaries.length)].shade400,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                      elevation: 12,
                      shadowColor: Colors.pink.shade200,
                    ),
                    icon: Text(emoji, style: const TextStyle(fontSize: 26)),
                    label: Text(
                      sub['title'] ?? 'بدون عنوان',
                      style: const TextStyle(fontFamily: 'ComicNeue', fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () {
                      _musicPlayer.play('assets/audios/PopButton_SB.mp3');
                      Navigator.pop(context);
                      Navigator.push(context, _createRoute(sub, widget.node['title']));
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.node['title'] ?? 'بدون عنوان';
    final String content = widget.node['content'] ?? '';
    final List<dynamic> children = widget.node['subsections'] ?? [];
    final String? type = widget.node['type'];
    final String? videoController = widget.node['controller'];
    final String? audioController = widget.node['audio'];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F6),
      appBar: AppBar(
        backgroundColor: Colors.pink.shade400,
        title: Text(
          widget.parentTitle != null ? '${widget.parentTitle} > $title' : title,
          style: const TextStyle(fontFamily: 'ComicNeue', fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hero Progress Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 8,
            color: Colors.pink.shade100,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("🌟 Global Progress", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.pink.shade800)),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: 0.65, // example, replace with real progress
                    color: Colors.pink,
                    backgroundColor: Colors.pink.shade200,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Skill Points: 120", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      Chip(
                        label: Text("3 Courses Done"),
                        backgroundColor: Colors.pink.shade300,
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Media Card
          buildMediaWidget(type, videoController, audioController),

          if (content.isNotEmpty)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 6,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Directionality(
                  textDirection: isArabic(content) ? TextDirection.rtl : TextDirection.ltr,
                  child: Text(
                    content,
                    style: const TextStyle(fontSize: 18, height: 1.5),
                    textAlign: TextAlign.justify,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Subsections
          if (children.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📚 Additional Lessons', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.pink.shade700)),
                const SizedBox(height: 12),
                ...children.map((item) {
                  final emoji = emojiList[Random().nextInt(emojiList.length)];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 5,
                    color: Colors.primaries[Random().nextInt(Colors.primaries.length)].shade100,
                    child: ListTile(
                      leading: Text(emoji, style: const TextStyle(fontSize: 30)),
                      title: Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: item['content'] != null ? Text(item['content']) : null,
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        if (item['subsections'] != null && item['subsections'].isNotEmpty) {
                          showSubsectionsModal(item['subsections']);
                        } else {
                          Navigator.push(context, _createRoute(item, widget.node['title']));
                        }
                      },
                    ),
                  );
                }).toList(),
              ],
            ),
        ],
      ),
    );
  }
}
