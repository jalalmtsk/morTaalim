import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../tools/VideoPlayer.dart';
import '../tools/audio_tool/audio_tool.dart';

// Simple trophy tracking for demo
class CompletionTracker {
  static final Set<String> completedNodes = {};
  static void markCompleted(String title) => completedNodes.add(title);
  static void unmarkCompleted(String title) => completedNodes.remove(title);
  static bool isCompleted(String title) => completedNodes.contains(title);
}

class CourseNodePage extends StatefulWidget {
  final Map<String, dynamic> node;
  final String? parentTitle;

  const CourseNodePage({super.key, required this.node, this.parentTitle});

  @override
  State<CourseNodePage> createState() => _CourseNodePageState();
}

class _CourseNodePageState extends State<CourseNodePage> with TickerProviderStateMixin {
  late final MusicPlayer _musicPlayer;
  late final AnimationController _bounceController;

  // For breathing animation per card - we’ll create a map of controllers by index
  final Map<int, AnimationController> _breathControllers = {};
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

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      lowerBound: 0.9,
      upperBound: 1.0,
    )..forward();
  }

  @override
  void dispose() {
    _musicPlayer.dispose();
    _bounceController.dispose();
    _breathControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  // Init breath controller for each card index if not exists
  Animation<double> _getBreathAnimation(int index) {
    if (!_breathControllers.containsKey(index)) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(seconds: 2 + (index % 3)), // Stagger durations a bit
        lowerBound: 0.95,
        upperBound: 1.05,
      )..repeat(reverse: true);
      _breathControllers[index] = controller;
    }
    return Tween(begin: 0.95, end: 1.05).animate(_breathControllers[index]!);
  }

  Widget buildAudioWidget(String controller) {
    return StatefulBuilder(
      builder: (context, setState) {
        return ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pinkAccent.shade400,
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 10,
            shadowColor: Colors.pink.shade300,
          ),
          icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, size: 40, color: Colors.white),
          label: Text(
            isPlaying ? 'إيقاف الصوت 🔊' : 'تشغيل الصوت 🔊',
            style: const TextStyle(fontSize: 24, fontFamily: 'ComicNeue', color: Colors.white),
          ),
          onPressed: () async {
            if (isPlaying) {
              await _musicPlayer.pause();
              setState(() => isPlaying = false);
            } else {
              await _musicPlayer.play('assets/audios/$controller');
              setState(() => isPlaying = true);
            }
          },
        );
      },
    );
  }

  Widget buildMediaWidget(String? type, String? videoController, String? audioController) {
    if ((videoController == null || videoController.isEmpty) && (audioController == null || audioController.isEmpty)) {
      return const SizedBox.shrink();
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
              SectionVideoPlayer(videoPath: videoController),
            if (audioController != null && audioController.isNotEmpty) ...[
              const SizedBox(height: 14),
              buildAudioWidget(audioController),
            ],
          ],
        ),
      ),
    );
  }

  void sparkleEffect() {
    _musicPlayer.play('assets/audios/sparkle_pop.mp3');
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Center(
          child: Lottie.asset('assets/animations/girl_jumping.json', width: 320, height: 320),
        );
      },
    );
    Future.delayed(const Duration(seconds: 1), () => Navigator.of(context).pop());
  }

  Future<void> markCompleted(String title) async {
    CompletionTracker.markCompleted(title);

    sparkleEffect();
  }

  void unmarkCompleted(String title) {
    CompletionTracker.unmarkCompleted(title);
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
                      _musicPlayer.play('assets/audios/pop.mp3');
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

  // Calculate progress percentage of completed children
  double _calculateProgress(List<dynamic> children) {
    if (children.isEmpty) return 0;
    final completedCount = children.where((c) => CompletionTracker.isCompleted(c['title'] ?? '')).length;
    return completedCount / children.length;
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.node['title'] ?? 'بدون عنوان';
    final String content = widget.node['content'] ?? '';
    final List<dynamic> children = widget.node['subsections'] ?? [];
    final String? type = widget.node['type'];
    final String? videoController = widget.node['controller'];
    final String? audioController = widget.node['audio'];

    final progress = _calculateProgress(children);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F6),
      appBar: AppBar(
        backgroundColor: Colors.pink.shade400,
        title: Text(
          widget.parentTitle != null ? '🎉 ${widget.parentTitle} > $title' : '🎉 $title',
          style: const TextStyle(fontFamily: 'ComicNeue', fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: CompletionTracker.isCompleted(title) ? '🎉 مكتمل' : '✅ أكمل الدرس',
            icon: Icon(
              CompletionTracker.isCompleted(title) ? Icons.emoji_events : Icons.check_circle_outline,
              color: CompletionTracker.isCompleted(title) ? Colors.amber : Colors.white,
              size: 36,
            ),
            onPressed: CompletionTracker.isCompleted(title)
                ? null
                : () {
              markCompleted(title);
              setState(() {});
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: Column(
          children: [
            Lottie.asset('assets/animations/rabbit_boat.json', height: 160),

            buildMediaWidget(type, videoController, audioController),

            const SizedBox(height: 22),

            if (content.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.shade100.withOpacity(0.75),
                      offset: const Offset(0, 6),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Directionality(
                  textDirection: isArabic(content) ? TextDirection.rtl : TextDirection.ltr,
                  child: Text(
                    content,
                    style: const TextStyle(
                      fontFamily: 'ComicNeue',
                      fontSize: 22,
                      height: 1.6,
                      color: Colors.deepPurple,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ),
              ),

            const SizedBox(height: 32),

            if (children.isNotEmpty) ...[
              // Progress bar & percentage
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Column(
                  children: [
                    Text(
                      '🌟 التقدم: ${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontFamily: 'ComicNeue',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.pinkAccent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 18,
                        backgroundColor: Colors.pink.shade100,
                        color: Colors.pinkAccent.shade400,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Text(
                '🎨 دروس إضافية:',
                style: TextStyle(
                  fontFamily: 'ComicNeue',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink.shade700,
                ),
              ),

              const SizedBox(height: 14),

              ...children.asMap().entries.map((entry) {
                final item = entry.value;
                final emoji = emojiList[entry.key % emojiList.length];
                final hasSub = item['subsections'] != null && item['subsections'].isNotEmpty;
                final titleChild = item['title'] ?? '';

                final breathAnimation = _getBreathAnimation(entry.key);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ScaleTransition(
                    scale: breathAnimation,
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 11,
                      shadowColor: Colors.pink.shade300,
                      color: Colors.primaries[entry.key % Colors.primaries.length].shade200,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                        leading: Text(emoji, style: const TextStyle(fontSize: 40)),
                        title: Directionality(
                          textDirection: isArabic(titleChild) ? TextDirection.rtl : TextDirection.ltr,
                          child: Text(
                            titleChild,
                            style: const TextStyle(
                              fontFamily: 'ComicNeue',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        subtitle: item['content'] != null && !hasSub
                            ? Directionality(
                          textDirection: isArabic(item['content']) ? TextDirection.rtl : TextDirection.ltr,
                          child: Text(
                            item['content'],
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 18, color: Colors.deepPurple),
                          ),
                        )
                            : null,
                        trailing: Checkbox(
                          value: CompletionTracker.isCompleted(titleChild),
                          activeColor: Colors.pinkAccent.shade400,
                          checkColor: Colors.white,
                          onChanged: (val) {
                            if (val == true) {
                              markCompleted(titleChild);
                            } else {
                              unmarkCompleted(titleChild);
                            }
                            setState(() {});
                          },
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          side: BorderSide(color: Colors.pinkAccent.shade400, width: 2),
                        ),
                        onTap: () {
                          _musicPlayer.play('assets/audios/pop.mp3');
                          if (hasSub) {
                            showSubsectionsModal(item['subsections']);
                          } else {
                            Navigator.push(context, _createRoute(item, title));
                          }
                        },
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],

            const SizedBox(height: 40),

            Lottie.asset('assets/animations/girl_studying.json', ),
          ],
        ),
      ),
    );
  }
}
