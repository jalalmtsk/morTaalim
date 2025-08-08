import 'dart:convert';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
import 'HomeCourse_Tools/Widgets/BadgeChip.dart';
import 'HomeCourse_Tools/Widgets/MascotBubble.dart';
import 'HomeCourse_Tools/Widgets/ProgressCard.dart';
import 'HomeCourse_Tools/Widgets/SectionCard.dart';
import 'nestedCourse.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import 'package:mortaalim/Inside_Course_Logic/HomeCourse_Tools/Widgets/SubsectionTile.dart';

/// ---------- CONFIG ----------
const String kProgressPrefix = 'gamified_progress';
const String kXpKey = 'gamified_xp';
const String kBadgeKey = 'gamified_badges';


/// ---------- Models ----------
class GamifiedSection {
  final String title;
  final List<dynamic> subsections;
  final String? image; // optional image asset
  GamifiedSection({required this.title, required this.subsections, this.image});
}

/// ---------- Main Widget ----------
class CoursePage extends StatefulWidget {
  final String jsonFilePath;
  final String courseId;

  const CoursePage({
    Key? key,
    required this.jsonFilePath,
    required this.courseId,
  }) : super(key: key);

  @override
  State<CoursePage> createState() => _CoursePageGamifiedState();
}

class _CoursePageGamifiedState extends State<CoursePage> with TickerProviderStateMixin {
  // Data
  String courseTitle = '';
  List<GamifiedSection> sections = [];
  Set<int> completed = {}; // section indices
  Map<int, int> sectionStars = {}; // section index -> stars earned (0..3)

  // Persistence
  SharedPreferences? _prefs;

  // Visuals & animations
  late ConfettiController _confetti;
  late AnimationController _bounceController;
  final FlutterTts _tts = FlutterTts();

  // Ads
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  // Gamification / XP
  int _xp = 0;
  Set<String> _badges = {};

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

    _configureTts();
    _loadData();
  }

  Future<void> _configureTts() async {
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.05);
    // Choose a default language - adapt to user locale
    await _tts.setLanguage('ar-MA'); // keep as original project's language setting
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    final raw = await rootBundle.loadString(widget.jsonFilePath);
    final json = jsonDecode(raw);
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;

    final saved = prefs.getStringList(_progressKey()) ?? [];
    final savedStars = prefs.getStringList(_starsKey()) ?? [];

    final xp = prefs.getInt(kXpKey) ?? 0;
    final badges = prefs.getStringList(kBadgeKey) ?? [];

    // parse sections
    List<GamifiedSection> parsed = [];
    final jsonSections = json['sections'] as List<dynamic>? ?? [];
    for (final s in jsonSections) {
      parsed.add(GamifiedSection(title: s['title'] ?? 'Untitled', subsections: s['subsections'] ?? [], image: s['image']));
    }

    // restore progress
    final completedIndices = saved.map((s) => int.tryParse(s) ?? -1).where((i) => i >= 0).toSet();
    final starsMap = <int, int>{};
    for (final s in savedStars) {
      final parts = s.split(':'); // "index:stars"
      if (parts.length == 2) {
        final idx = int.tryParse(parts[0]) ?? -1;
        final st = int.tryParse(parts[1]) ?? 0;
        if (idx >= 0) starsMap[idx] = st;
      }
    }

    setState(() {
      courseTitle = json['title'] ?? 'Course';
      sections = parsed;
      completed = completedIndices;
      sectionStars = starsMap;
      _xp = xp;
      _badges = badges.toSet();
      isLoading = false;
    });
  }

  String _progressKey() => '$kProgressPrefix\_${widget.courseId}';
  String _starsKey() => '${kProgressPrefix}_stars_${widget.courseId}';

  Future<void> _saveProgress() async {
    if (_prefs == null) return;
    await _prefs!.setStringList(_progressKey(), completed.map((i) => i.toString()).toList());
    await _prefs!.setStringList(_starsKey(), sectionStars.entries.map((e) => '${e.key}:${e.value}').toList());
    await _prefs!.setInt(kXpKey, _xp);
    await _prefs!.setStringList(kBadgeKey, _badges.toList());
  }

  @override
  void dispose() {
    _confetti.dispose();
    _bounceController.dispose();
    _bannerAd?.dispose();
    _tts.stop();
    super.dispose();
  }

  // ---------- GAMIFICATION UTILS ----------
  int _awardStarsForSection(int subsectionCount) {
    // Simple fun algorithm: 1..3 stars based on subsection count / randomization (you can adapt)
    if (subsectionCount <= 1) return 3;
    final rng = Random();
    final val = rng.nextInt(3) + 1; // 1..3
    return val;
  }

  void _grantXp(int amount) {
    setState(() => _xp += amount);
    _saveProgress();
    // Check for badges
    _maybeAwardBadge();
  }

  void _maybeAwardBadge() {
    // Examples: badges at xp thresholds 10, 30, 60
    if (_xp >= 60 && !_badges.contains('master')) {
      _badges.add('master');
      _showBadgeDialog('Master Learner', 'You earned the Master Learner badge!');
    } else if (_xp >= 30 && !_badges.contains('star_collector')) {
      _badges.add('star_collector');
      _showBadgeDialog('Star Collector', 'You earned the Star Collector badge!');
    } else if (_xp >= 10 && !_badges.contains('starter')) {
      _badges.add('starter');
      _showBadgeDialog('Starter', 'Good start! Badge unlocked.');
    }
    _saveProgress();
  }

  // ---------- INTERACTIONS ----------
  Future<void> _openSection(int index) async {
    // Open a fullscreen modal showing subsections in friendly big buttons
    final section = sections[index];
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.86,
          minChildSize: 0.5,
          maxChildSize: 0.98,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.white, Colors.orange.shade50]),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 6,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: Text(section.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                      IconButton(
                        icon: const Icon(Icons.volume_up_rounded),
                        onPressed: () => _speak(section.title),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      controller: controller,
                      itemCount: section.subsections.length,
                      itemBuilder: (ctx, i) {
                        final sub = section.subsections[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: SubsectionTile(
                            title: sub['title'] ?? 'Activity',
                            description: sub['description'] ?? '',
                            onTap: () async {
                              Navigator.of(ctx).pop();
                              // Play click sound if you have AudioManager
                              await _speak(sub['title'] ?? '');
                              // Navigate to node page (your nestedCourse)
                              if (sub is Map<String, dynamic>) {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => CourseNodePage(node: sub)));
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            backgroundColor: Colors.deepOrange,
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _completeSection(index);
                          },
                          icon: const Icon(Icons.celebration),
                          label: const Text('Mark Completed'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _speak(String text) async {
    if (_muted) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  void _completeSection(int index) {
    if (completed.contains(index)) {
      // already done -> show small reward
      _showSnack('Already completed! Great job! ⭐');
      return;
    }

    final stars = _awardStarsForSection(sections[index].subsections.length);
    setState(() {
      completed.add(index);
      sectionStars[index] = stars;
    });

    // grant XP based on stars
    final xpGain = 5 * stars; // 5,10,15 xp
    _grantXp(xpGain);

    _confetti.play();
    _showCompletionModal(index, stars, xpGain);
    _saveProgress();
  }

  // ---------- MODALS & TOASTS ----------
  void _showSnack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  void _showCompletionModal(int index, int stars, int xpGained) {
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
                  Text('Great job!', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('You completed: $title', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final lit = i < stars;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: Icon(
                          lit ? Icons.star : Icons.star_border,
                          color: lit ? Colors.amber : Colors.grey[400],
                          size: 36,
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

  void _showBadgeDialog(String badgeTitle, String message) {
    // small celebratory badge popup
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Colors.orange.shade50,
          title: Row(
            children: [
              const Icon(Icons.shield_rounded, color: Colors.amber),
              const SizedBox(width: 8),
              Text(badgeTitle),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Nice!')),
          ],
        );
      },
    );
  }

  // ---------- UI BUILD ----------
  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final progress = sections.isEmpty ? 0.0 : completed.length / sections.length;
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
            icon: Icon(_muted ? Icons.volume_off : Icons.volume_up, color: Colors.deepOrange),
            onPressed: () {
              setState(() => _muted = !_muted);
              if (_muted) _tts.stop();
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
              // user status bar (your widget)
              const Userstatutbar(),

              // Top card: progress + mascot
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: ProgressCard(progressPct: progressPct, progress: progress, xp: _xp, badges: _badges.length),
                    ),
                    const SizedBox(width: 12),
                    MascotBubble(
                      onTap: () {
                        // mascot speaks encouragement and shows small animation
                        _speak('Keep going! You are doing wonderful!');
                        _confetti.play();
                      },
                    ),
                  ],
                ),
              ),

              // Title inviting children to pick a section
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

              // PageView of section cards
              SizedBox(
                height: 280,
                child: PageView.builder(
                  controller: PageController(viewportFraction: 0.74, initialPage: _currentPage),
                  itemCount: sections.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (ctx, index) {
                    final s = sections[index];
                    final completedFlag = completed.contains(index);
                    final stars = sectionStars[index] ?? 0;
                    final scale = (_currentPage == index) ? 1.0 : 0.94;
                    return Transform.scale(
                      scale: scale,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                        child: SectionCard(
                          title: s.title,
                          subtitle: '${s.subsections.length} activities',
                          imageAsset: s.image,
                          completed: completedFlag,
                          stars: stars,
                          color: Colors.primaries[index % Colors.primaries.length].shade300,
                          onTap: () => _openSection(index),
                          onToggleComplete: () => _completeSection(index),
                          bounceController: _bounceController,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // Row of badges (scrollable)
              SizedBox(
                height: 86,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  children: [
                    const SizedBox(width: 6),
                    BadgeChip(title: 'Starter', unlocked: _badges.contains('starter')),
                    const SizedBox(width: 8),
                    BadgeChip(title: 'Star Collector', unlocked: _badges.contains('star_collector')),
                    const SizedBox(width: 8),
                    BadgeChip(title: 'Master', unlocked: _badges.contains('master')),
                    const SizedBox(width: 8),
                    // your additional badges...
                  ],
                ),
              ),

              const Spacer(),

              // Banner Ad slot
              if (_isBannerLoaded && _bannerAd != null)
                SizedBox(height: _bannerAd!.size.height.toDouble(), child: AdWidget(ad: _bannerAd!))
              else
                Container(
                  height: 64,
                  alignment: Alignment.center,
                  child: Text('Ad space', style: TextStyle(color: Colors.grey.shade400)),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}


