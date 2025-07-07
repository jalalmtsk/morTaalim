// Full upgraded CourseNodePage with media playback and improved UI

import 'package:flutter/material.dart';

import '../tools/VideoPlayer.dart';
import '../tools/YoutubePlayerPage.dart';
import '../tools/audio_tool/audio_tool.dart';


class CourseNodePage extends StatefulWidget {
  final Map<String, dynamic> node;
  final String? parentTitle;

  const CourseNodePage({super.key, required this.node, this.parentTitle});

  @override
  State<CourseNodePage> createState() => _CourseNodePageState();
}

class _CourseNodePageState extends State<CourseNodePage> {
  late final MusicPlayer _musicPlayer;


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

  Widget buildMediaWidget(String? type, String? controller) {
    if (controller == null || controller.isEmpty) return const SizedBox.shrink();

    switch (type) {
      case 'video':
        return SectionVideoPlayer(
          videoPath: controller,
        );

      case 'youtube':
        return YouTubeSectionPlayer(videoUrl: controller);

      case 'audio':
        _musicPlayer.play('assets/audios/$controller');
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text('🔊 يتم تشغيل الصوت...', style: TextStyle(fontSize: 16, color: Colors.blue)),
        );

      default:
        return const SizedBox.shrink();
    }
  }



  @override
  Widget build(BuildContext context) {
    final String title = widget.node['title'] ?? 'Untitled';
    final String content = widget.node['content'] ?? '';
    final List<dynamic> children = widget.node['subsections'] ?? [];
    final String? type = widget.node['type'];
    final String? controller = widget.node['controller'];
    final _musicPlayer = SectionVideoPlayer(videoPath: controller.toString());

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.parentTitle != null ? '${widget.parentTitle} > $title' : title),
        backgroundColor: Colors.deepOrange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controller != null) buildMediaWidget(type, controller),
            if (content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  content,
                  style: const TextStyle(fontSize: 18, height: 1.5),
                  textAlign: TextAlign.justify,
                ),
              ),
            if (children.isNotEmpty)
              const Divider(thickness: 2),
            ...children.map((item) => Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text(item['title'] ?? 'بدون عنوان'),
                subtitle: item['content'] != null && item['subsections'] == null
                    ? Text(
                  item['content'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
                    : null,
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CourseNodePage(
                        node: item,
                        parentTitle: title,
                      ),
                    ),
                  );
                },
              ),
            )),
          ],
        ),
      ),
    );
  }
}
