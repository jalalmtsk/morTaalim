import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lottie/lottie.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';

import '../../../../XpSystem.dart';
import '../../../../Themes/ThemeManager.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../main.dart';
import '../../../../tools/Ads_Manager.dart';
import '../../../../tools/AnimatedGridItem.dart';
import '../../../../tools/audio_tool/Audio_Manager.dart';
import '../../../../tools/loading_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Tag colours (one accent per content category)
// ─────────────────────────────────────────────────────────────────────────────
const _tagColors = <String, Color>{
  'hardware': Color(0xFF5C6BC0),
  'internet': Color(0xFF0288D1),
  'safety':   Color(0xFF2E7D32),
  'files':    Color(0xFF6D4C41),
  'typing':   Color(0xFF00838F),
  'coding':   Color(0xFFE65100),
  'binary':   Color(0xFF6A1B9A),
  'data':     Color(0xFF00695C),
  'ai':       Color(0xFFC62828),
};

// Tier boundaries  (grade label → tier display name)
const _tierLabels = <String, String>{
  '1–2': '🌱 Tier 1 — Grade 1–2',
  '2–3': '🌿 Tier 2 — Grade 2–3',
  '3–4': '🌳 Tier 3 — Grade 3–4',
  '4–5': '🚀 Tier 4 — Grade 4–5',
  '5–6': '⭐ Tier 5 — Grade 5–6',
};

// ─────────────────────────────────────────────────────────────────────────────
//  Widget
// ─────────────────────────────────────────────────────────────────────────────
class ITGrid extends StatefulWidget {
  final List<Map<String, dynamic>> ITCourses;

  const ITGrid({super.key, required this.ITCourses});

  @override
  State<ITGrid> createState() => _ITGridState();
}

class _ITGridState extends State<ITGrid>
    with TickerProviderStateMixin, WidgetsBindingObserver {

  // ── Ads ──────────────────────────────────────────────────────────────────
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  // ── Confetti + unlock animation ───────────────────────────────────────────
  late ConfettiController _confettiController;
  bool _isUnlocking = false;

  // ── Tag filter ────────────────────────────────────────────────────────────
  String? _selectedTag;   // null = show all

  // ── All unique tags extracted from data ───────────────────────────────────
  List<String> get _allTags {
    final tags = widget.ITCourses
        .map((c) => c['tag'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
    tags.sort();
    return tags;
  }

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    WidgetsBinding.instance.addObserver(this);
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  void _loadBannerAd() {
    _bannerAd?.dispose();
    _isBannerAdLoaded = false;
    _bannerAd = AdHelper.getBannerAd(() {
      if (mounted) setState(() => _isBannerAdLoaded = true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadBannerAd();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _confettiController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _simulateLoading() async {
    await Future.delayed(Duration(seconds: 1 + Random().nextInt(2)));
  }

  void _triggerUnlockAnimation(AudioManager audio) {
    audio.playSfx('assets/audios/UI_Audio/SFX_Audio/victory2_SFX.mp3');
    audio.playSfx('assets/audios/QuizGame_Sounds/crowd-cheering-6229.mp3');
    _confettiController.play();
    setState(() => _isUnlocking = true);
  }

  /// Returns courses filtered by the active tag, preserving order.
  List<Map<String, dynamic>> get _filteredCourses {
    if (_selectedTag == null) return widget.ITCourses;
    return widget.ITCourses
        .where((c) => c['tag'] == _selectedTag)
        .toList();
  }

// ── Unlock dialog ─────────────────────────────────────────────────────────

  void _showUnlockDialog(
      BuildContext context,
      Map<String, dynamic> course,
      ExperienceManager xpManager,
      AudioManager audio,
      ) {
    final cost = course['cost'] as int? ?? 10;
    final hasEnough = xpManager.stars >= cost;
    final tag = course['tag'] as String? ?? '';
    final tagColor = _tagColors[tag] ?? Colors.blueGrey;

    audio.playEventSound('clickButton2');

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header image ─────────────────────────────────────────────
            Stack(
              children: [
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: Image.asset(
                    course['image'] ?? 'assets/images/AvatarImage/Avatar2.png',
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        tagColor.withOpacity(0.7),
                        Colors.black.withOpacity(0.3),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 14,
                  right: 14,
                  child: Text(
                    _getCourseTitle(course['title']),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                    ),
                  ),
                ),
              ],
            ),

            // ── Body ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                children: [
                  // Grade + tag chips
                  Row(
                    children: [
                      _chip(
                        '📚 Grade ${course['grade'] ?? '?'}',
                        Colors.indigo.shade400,
                      ),
                      const SizedBox(width: 8),
                      _chip(
                        '#${course['tag'] ?? ''}',
                        tagColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Stars needed
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 32),
                      const SizedBox(width: 6),
                      Text(
                        '$cost',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'stars to unlock',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Current balance
                  Text(
                    'Your balance: ${xpManager.stars} ⭐',
                    style: TextStyle(
                      color: hasEnough
                          ? Colors.green.shade700
                          : Colors.red.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!hasEnough) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border:
                        Border.all(color: Colors.red.shade200, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.red.shade400, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You need ${cost - xpManager.stars} more ⭐. '
                                  'Keep learning to earn more stars!',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // ── Actions ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        audio.playEventSound('cancelButton');
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(tr(context).cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.lock_open_rounded),
                      label: const Text('Unlock'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasEnough
                            ? tagColor
                            : Colors.grey.shade400,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: hasEnough
                          ? () {
                        xpManager.unlockCourse(course['title'], cost);
                        xpManager.SpendStarBanner(context, cost);
                        xpManager.addXP(10, context: context);
                        Navigator.pop(context);
                        _triggerUnlockAnimation(audio);
                      }
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
    padding:
    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.5), width: 1),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  // ── Filter chip ───────────────────────────────────────────────────────────

  Widget _filterChip(String label, String? tag, ThemeManager theme) {
    final isSelected = _selectedTag == tag;
    final color = tag != null
        ? (_tagColors[tag] ?? Colors.blueGrey)
        : theme.currentTheme.primaryColor;

    return GestureDetector(
      onTap: () => setState(() => _selectedTag = tag),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.85)
              : Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.white24,
            width: 1.2,
          ),
        ),
        child: Text(
          label[0].toUpperCase() + label.substring(1),
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 13,
            fontWeight:
            isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }



  // ── Tier section header ───────────────────────────────────────────────────

  Widget _buildTierHeader(String grade, ThemeManager theme) {
    final label = _tierLabels[grade] ?? '📌 Grade $grade';
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
              border:
              Border.all(color: Colors.white.withOpacity(0.15), width: 1),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Course card ───────────────────────────────────────────────────────────

  Widget _buildCourseCard(
      BuildContext context,
      Map<String, dynamic> course,
      ExperienceManager xpManager,
      AudioManager audio,
      ) {
    final isUnlocked =
        !course['locked'] || xpManager.isCourseUnlocked(course['title']);
    final cost = course['cost'] as int? ?? 10;
    final isLocked = course['locked'] == true && !isUnlocked;
    final tag = course['tag'] as String? ?? '';
    final tagColor = _tagColors[tag] ?? Colors.blueGrey;

    return GestureDetector(
      onTap: () {
        if (isUnlocked) {
          audio.playEventSound('PopButton');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LoadingPage(
                loadingFuture: _simulateLoading(),
                nextRouteName: course['routeName'],
              ),
            ),
          );
        } else {
          _showUnlockDialog(context, course, xpManager, audio);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // ── Background image ──────────────────────────────────────
            Positioned.fill(
              child: Image.asset(
                course['image'] ?? 'assets/images/AvatarImage/Avatar2.png',
                fit: BoxFit.cover,
                color: isLocked ? Colors.black.withOpacity(0.45) : null,
                colorBlendMode: isLocked ? BlendMode.darken : null,
              ),
            ),

            // ── Gradient overlay ──────────────────────────────────────
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.55),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ),

            // ── Tag accent bar (top-left) ──────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: tagColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
              ),
            ),

            // ── Grade badge ───────────────────────────────────────────
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${course['grade'] ?? '?'}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // ── Centre content ────────────────────────────────────────
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon + lock overlay
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isLocked
                              ? Colors.black.withOpacity(0.3)
                              : tagColor.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          course['icon'] as IconData? ?? Icons.school,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                      if (isLocked)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.lock,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      if (!isLocked && cost > 0)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check,
                                size: 14, color: Colors.white),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      _getCourseTitle(course['title']),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        shadows: [
                          Shadow(
                              color: Colors.black,
                              blurRadius: 4,
                              offset: Offset(1, 1))
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Cost / FREE badge
                  if (isLocked)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star,
                            size: 16, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          '$cost',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                  color: Colors.black,
                                  blurRadius: 4,
                                  offset: Offset(1, 1))
                            ],
                          ),
                        ),
                      ],
                    ),

                  if (!isLocked && cost == 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.shade700.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'FREE',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  if (!isLocked && cost > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.shade700.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'UNLOCKED ✓',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Override build to use a proper 2-column grouped layout
  //  We build one SliverGrid per tier section.
  // ─────────────────────────────────────────────────────────────────────────

  List<Widget> _buildSlivers(
      ExperienceManager xpManager,
      AudioManager audio,
      ThemeManager theme,
      ) {
    final courses = _filteredCourses;

    // Group by grade preserving insertion order
    final tiers = <String, List<Map<String, dynamic>>>{};
    for (final c in courses) {
      final grade = c['grade'] as String? ?? '?';
      tiers.putIfAbsent(grade, () => []).add(c);
    }

    final slivers = <Widget>[];
    for (final entry in tiers.entries) {
      // Tier header
      slivers.add(SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _buildTierHeader(entry.key, theme),
        ),
      ));

      // 2-column grid for this tier
      final tierCourses = entry.value;
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 4 / 3,
            ),
            delegate: SliverChildBuilderDelegate(
                  (ctx, i) => AnimatedGridItem(
                index: i,
                columnCount: 2,
                child: _buildCourseCard(ctx, tierCourses[i], xpManager, audio),
              ),
              childCount: tierCourses.length,
            ),
          ),
        ),
      );

      slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 8)));
    }

    if (slivers.isEmpty) {
      slivers.add(const SliverFillRemaining(
        child: Center(
          child: Text(
            'No exercises in this category yet.',
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ),
      ));
    }

    return slivers;
  }

  @override
  Widget build(BuildContext context) {
    final xpManager = Provider.of<ExperienceManager>(context);
    final audio = Provider.of<AudioManager>(context, listen: false);
    final theme = Provider.of<ThemeManager>(context);

    return Stack(
      children: [
        Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  Icon(Icons.computer,
                      color: theme.currentTheme.accentColor, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'IT Exercises',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 3,
                            color:
                            theme.currentTheme.primaryColor.withOpacity(0.4),
                            offset: const Offset(1, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Stars pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '${xpManager.stars}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // ── Tag filter ────────────────────────────────────────────────
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  _filterChip('All', null, theme),
                  ..._allTags.map((t) => _filterChip(t, t, theme)),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // ── Grouped grid ──────────────────────────────────────────────
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(const []),
                    ),
                  ),
                  ..._buildSlivers(xpManager, audio, theme),
                  const SliverPadding(
                    padding: EdgeInsets.only(bottom: 16),
                    sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
                  ),
                ],
              ),
            ),

            // ── Banner ad ─────────────────────────────────────────────────
            if (context.watch<ExperienceManager>().adsEnabled &&
                _bannerAd != null &&
                _isBannerAdLoaded)
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
                ),
              ),
          ],
        ),

        // ── Confetti ──────────────────────────────────────────────────────
        Positioned.fill(
          child: IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: 300,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  emissionFrequency: 0.05,
                  numberOfParticles: 60,
                  maxBlastForce: 22,
                  minBlastForce: 10,
                  gravity: 0.3,
                  shouldLoop: false,
                  colors: const [
                    Colors.cyan,
                    Colors.yellow,
                    Colors.green,
                    Colors.orange,
                    Colors.purple,
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Unlock Lottie overlay ─────────────────────────────────────────
        if (_isUnlocking)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.12),
              child: Center(
                child: Lottie.asset(
                  'assets/animations/unlock_key.json',
                  width: 220,
                  height: 220,
                  repeat: false,
                  onLoaded: (comp) {
                    Future.delayed(comp.duration, () {
                      if (mounted) setState(() => _isUnlocking = false);
                    });
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Title map ─────────────────────────────────────────────────────────────

  String _getCourseTitle(String key) {
    const map = <String, String>{
      'itWhatIsComputer':   '💻 What Is a Computer?',
      'itComputerParts':    '🖱️ Computer Parts',
      'itMousePractice':    '🎯 Mouse Practice',
      'itInputOutput':      '↔️ Input & Output',
      'itInternetBasics':   '🌐 Internet Basics',
      'itOnlineSafety':     '🛡️ Online Safety',
      'itFileFolders':      '📁 Files & Folders',
      'itTypingFingers':    '⌨️ Typing Practice',
      'itWhatIsAlgorithm':  '🔢 Algorithms',
      'itLoopsConditions':  '🔁 Loops & Conditions',
      'itPasswordSafety':   '🔐 Password Safety',
      'itFileTypes':        '📄 File Types',
      'itBinaryNumbers':    '💡 Binary Numbers',
      'itHowInternetWorks': '🌍 How Internet Works',
      'itScratchCoding':    '🐱 Scratch Coding',
      'itCyberThreats':     '🦠 Cyber Threats',
      'itIntroToPython':    '🐍 Intro to Python',
      'itDataAndDatabases': '🗄️ Databases',
      'itHtmlBasics':       '🌐 HTML Basics',
      'itAiAndRobots':      '🤖 AI & Robots',
    };
    return map[key] ?? key;
  }
}