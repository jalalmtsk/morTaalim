import 'dart:convert';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/Manager/Services/YoutubeProgressManager.dart';
import 'package:mortaalim/Settings/SettingPanelInGame.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../XpSystem.dart';
import 'HomeCourse_Tools/CoursedetailPage.dart';
import 'HomeCourse_Tools/Widgets/BadgeChip.dart';
import 'HomeCourse_Tools/Widgets/MascotBubble.dart';
import 'HomeCourse_Tools/Widgets/ProgressCard.dart';
import 'HomeCourse_Tools/Widgets/SectionCard.dart';
import 'nestedCourse.dart';
import 'package:mortaalim/Inside_Course_Logic/HomeCourse_Tools/Widgets/SubsectionTile.dart';

/// ---------- CONFIG ----------
const String kProgressPrefix = 'gamified_progress';

/// ---------- Models ----------
class GamifiedSection {
  final String title;
  final List<dynamic> subsections;
  final String? image; // optional image asset
  GamifiedSection({required this.title, required this.subsections, this.image});
}

/// ---------- Main Widget ----------
///
///


YoutubeProgressManager youtubeProgressManager = YoutubeProgressManager(); // your instance
class CoursePage extends StatefulWidget {
  final String jsonFilePath;
  final String courseId;
  final ExperienceManager experienceManager; // <-- Inject ExperienceManager here

  const CoursePage({
    Key? key,
    required this.jsonFilePath,
    required this.courseId,
    required this.experienceManager,
  }) : super(key: key);

  @override
  State<CoursePage> createState() => _CoursePageGamifiedState();
}

class _CoursePageGamifiedState extends State<CoursePage> with TickerProviderStateMixin {
  // Data
  String courseTitle = '';
  List<GamifiedSection> sections = [];

  // Visuals & animations
  late ConfettiController _confetti;
  late AnimationController _bounceController;

  // UI
  bool isLoading = true;
  int _currentPage = 0;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _bounceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _bounceController.repeat(reverse: true);

    _loadData();
  }

  Future<void> _resetProgression() async {
    await widget.experienceManager.courseProgressionManager.resetProgress();
    setState(() {}); // refresh UI
    _showSnack('Progress reset successfully.');
  }



  Future<void> _loadData() async {
    setState(() => isLoading = true);
    final raw = await rootBundle.loadString(widget.jsonFilePath);
    final json = jsonDecode(raw);

    List<GamifiedSection> parsed = [];
    final jsonSections = json['sections'] as List<dynamic>? ?? [];
    for (final s in jsonSections) {
      parsed.add(GamifiedSection(title: s['title'] ?? 'Untitled', subsections: s['subsections'] ?? [], image: s['image']));
    }

    // Register total sections count for progress calculation
    widget.experienceManager.courseProgressionManager.setTotalSections(widget.courseId, parsed.length);

    setState(() {
      courseTitle = json['title'] ?? 'Course';
      sections = parsed;
      isLoading = false;
    });
  }

  // Use course-specific completed sections and points
  Set<int> get completed => widget.experienceManager.courseProgressionManager.getCompletedSections(widget.courseId);
  Map<int, int> get sectionCoursePoints => widget.experienceManager.courseProgressionManager.getSectionPoints(widget.courseId);
  Set<String> get badges => widget.experienceManager.courseProgressionManager.badges;
  int get courseXp => widget.experienceManager.courseProgressionManager.courseXp;

  int _awardCoursePointsForSection(int subsectionCount) {
    if (subsectionCount <= 1) return 1;
    final rng = Random();
    return rng.nextInt(3) + 1; // 1..3
  }

  Future<void> _completeSection(int index) async {
    if (completed.contains(index)) {
      _showSnack('Already completed! Great job! 🏆');
      return;
    }

    final subsectionCount = sections[index].subsections.length;
    await widget.experienceManager.courseProgressionManager.completeSection(
      widget.courseId,
      index,
      subsectionCount,
    );

    setState(() {}); // Refresh UI after updating experienceManager

    _confetti.play();
    final points = _awardCoursePointsForSection(subsectionCount);
    _showCompletionModal(index, points, points * 5);
  }

  Future<void> _openSection(int index) async {
    final section = sections[index];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourseDetailPage(
          section: section,
          index: index,
          onComplete: () => _completeSection(index),
        ),
      ),
    );
  }


  void _showSnack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  void _showCompletionModal(int index, int points, int xpGained) {
    final title = sections[index].title;
    showDialog(
      context: context,
      builder: (_) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.orange.shade100, Colors.white]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black26.withOpacity(0.08), blurRadius: 12)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset('assets/animations/girl_jumping.json', width: 160, repeat: false),
                  const SizedBox(height: 8),
                  const Text('Great job!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('You completed: $title', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(2, (i) {
                      final lit = i < points;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: Icon(
                          lit ? Icons.emoji_events : Icons.emoji_events_outlined,
                          color: lit ? Colors.amber : Colors.grey[400],
                          size: 40,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text('+$xpGained XP', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Padding(padding: EdgeInsets.symmetric(horizontal: 18.0, vertical: 12), child: Text('Continue')),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _confetti.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    final locale = AppLocalizations.of(context);
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final progress = widget.experienceManager.courseProgressionManager.getProgress(widget.courseId);
    final progressPct = (progress * 100).toInt();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(courseTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black87)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {
              audioManager.playEventSound('clickButton');
              showDialog(
                barrierDismissible: false,
                context: context,
                barrierColor: Colors.black.withValues(alpha: 0.3),
                builder: (BuildContext context) {
                  return const SettingsDialog();
                },
              );
            },
          ),
          const SizedBox(width: 8)
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [const Color(0xFFFFF5F0), Colors.orange.shade50], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: SafeArea(
          child: ListView(
            children: [
              const Userstatutbar(),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: ProgressCard(progressPct: progressPct, progress: progress, xp: courseXp, badges: badges.length),
                    ),
                    const SizedBox(width: 12),
                    MascotBubble(

                      emoji: "🐱",
                      onTap: () {
                        _confetti.play();
                      },
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(children: [
                  Text("Choose" ?? 'Choose a section', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _showSnack('Tip: Tap a card to open activities.'),
                    icon: const Icon(Icons.info_outline),
                  )
                ]),
              ),

              const SizedBox(height: 8),

              SizedBox(
                height: 280,
                child: PageView.builder(
                  controller: PageController(viewportFraction: 0.74, initialPage: _currentPage),
                  itemCount: sections.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (ctx, index) {
                    final s = sections[index];
                    final completedFlag = completed.contains(index);
                    final points = sectionCoursePoints[index] ?? 0;
                    final scale = (_currentPage == index) ? 1.0 : 0.94;
                    return Transform.scale(
                      scale: scale,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                        child: SectionCard(
                          title: s.title,
                          subtitle: '${s.subsections.length} activities',
                          imageAsset: "assets/images/UI/BackGrounds/bg10.jpg",
                          completed: completedFlag,
                          points: points,
                          color: Colors.primaries[index % Colors.primaries.length].shade300,
                          onTap: () => _openSection(index),
                          onToggleComplete: completedFlag ? null : () => _completeSection(index),
                          bounceController: _bounceController,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: 86,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  children: [
                    const SizedBox(width: 6),
                    BadgeChip(title: 'Starter', unlocked: badges.contains('starter')),
                    const SizedBox(width: 8),
                    BadgeChip(title: 'Point Collector', unlocked: badges.contains('point_collector')),
                    const SizedBox(width: 8),
                    BadgeChip(title: 'Master Learner', unlocked: badges.contains('master')),
                    const SizedBox(width: 6),
                  ],
                ),
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
      floatingActionButton: ConfettiWidget(
        confettiController: _confetti,
        blastDirectionality: BlastDirectionality.explosive,
        shouldLoop: false,
        colors: const [Colors.amber, Colors.orange, Colors.deepOrange],
        emissionFrequency: 0.04,
        numberOfParticles: 20,
        gravity: 0.1,
      ),
    );
  }
}
