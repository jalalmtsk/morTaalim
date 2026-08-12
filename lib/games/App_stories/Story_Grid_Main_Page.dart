import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../tools/Ads_Manager.dart';
import 'Stories.dart';
import 'story_book_page.dart';

// ─── Card palette – each story gets its own vivid identity ────────────────────
class _CardPalette {
  final List<Color> gradient;
  final Color accent;
  final String emoji;
  const _CardPalette({required this.gradient, required this.accent, required this.emoji});
}

const List<_CardPalette> _palettes = [
  _CardPalette(gradient: [Color(0xFFFF6B6B), Color(0xFFFF8E53)], accent: Color(0xFFFF5722), emoji: '🦊'),
  _CardPalette(gradient: [Color(0xFF43E97B), Color(0xFF38F9D7)], accent: Color(0xFF00C853), emoji: '🐿️'),
  _CardPalette(gradient: [Color(0xFF4FACFE), Color(0xFF00F2FE)], accent: Color(0xFF0288D1), emoji: '🌊'),
  _CardPalette(gradient: [Color(0xFFA18CD1), Color(0xFFFBC2EB)], accent: Color(0xFF7B1FA2), emoji: '🦋'),
  _CardPalette(gradient: [Color(0xFFFDA085), Color(0xFFF6D365)], accent: Color(0xFFFF8F00), emoji: '🦁'),
  _CardPalette(gradient: [Color(0xFF30CFD0), Color(0xFF667EEA)], accent: Color(0xFF1565C0), emoji: '🐬'),
  _CardPalette(gradient: [Color(0xFFFF9A9E), Color(0xFFFFAFBD)], accent: Color(0xFFE91E63), emoji: '🌸'),
  _CardPalette(gradient: [Color(0xFF96FBC4), Color(0xFFF9F586)], accent: Color(0xFF558B2F), emoji: '🐸'),
];

_CardPalette _paletteFor(int i) => _palettes[i % _palettes.length];

// ═════════════════════════════════════════════════════════════════════════════
class StoriesGridPage extends StatefulWidget {
  final List<Story> stories;
  const StoriesGridPage({super.key, required this.stories});

  @override
  State<StoriesGridPage> createState() => _StoriesGridPageState();
}

class _StoriesGridPageState extends State<StoriesGridPage>
    with SingleTickerProviderStateMixin {

  late AnimationController _staggerCtrl;
  Set<int> _completedStories = {};
  InterstitialAd? _interstitialAd;
  bool _isAdReady = false;
  DateTime? _lastAdTime;

  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..forward();
    _loadCompleted();
    _loadAd();
  }

  Future<void> _loadCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final Set<int> done = {};
    for (int i = 0; i < widget.stories.length; i++) {
      final saved = prefs.getInt('progress_${widget.stories[i].title}') ?? 0;
      if (saved >= widget.stories[i].pages.length - 1) done.add(i);
    }
    if (mounted) setState(() => _completedStories = done);
  }

  void _loadAd() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(nonPersonalizedAds: true),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (mounted) setState(() { _interstitialAd = ad; _isAdReady = true; });
        },
        onAdFailedToLoad: (_) {
          if (mounted) setState(() => _isAdReady = false);
        },
      ),
    );
  }
  @override
  void dispose() {
    _staggerCtrl.dispose();
    _interstitialAd?.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_IndexedStory> get _filtered {
    final list = widget.stories
        .asMap()
        .entries
        .map((e) => _IndexedStory(e.key, e.value))
        .toList();
    if (_searchQuery.isEmpty) return list;
    return list
        .where((s) => s.story.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Future<void> _openStory(int originalIndex, Story story) async {
    final now = DateTime.now();
    final canAd = _isAdReady &&
        _interstitialAd != null &&
        (_lastAdTime == null ||
            now.difference(_lastAdTime!) > const Duration(seconds: 10));

    Future<void> push() async {
      await Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 450),
          pageBuilder: (_, anim, __) => FadeTransition(
            opacity: anim,
            child: StoryBookPage(story: story, storyIndex: originalIndex),
          ),
        ),
      );
      _loadCompleted();
    }

    if (canAd) {
      _lastAdTime = now;
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose(); _interstitialAd = null; _isAdReady = false;
          _loadAd(); push();
        },
        onAdFailedToShowFullScreenContent: (ad, _) {
          ad.dispose(); _interstitialAd = null; _isAdReady = false;
          _loadAd(); push();
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null; _isAdReady = false;
    } else {
      push();
    }
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F2),
      body: CustomScrollView(
        slivers: [

          // ── Gorgeous SliverAppBar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 210,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: _CircleAppBarBtn(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.pop(context),
            ),
            actions: [
              _CircleAppBarBtn(
                icon: Icons.bookmark_rounded,
                onTap: () => Navigator.pushNamed(context, 'FavoriteWords'),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: _LibraryHeader(),
            ),
          ),

          // ── Search bar ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: _SearchBar(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v),
                onClear: () {
                  _searchCtrl.clear();
                  setState(() => _searchQuery = '');
                },
                hasText: _searchQuery.isNotEmpty,
              ),
            ),
          ),

          // ── Stats row ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  _StatChip(
                    label: '${widget.stories.length} Stories',
                    icon: '📚',
                    color: const Color(0xFFFF7043),
                  ),
                  const SizedBox(width: 10),
                  _StatChip(
                    label: '${_completedStories.length} Completed',
                    icon: '⭐',
                    color: const Color(0xFF43A047),
                  ),
                  const Spacer(),
                  Text(
                    '${filtered.length} shown',
                    style: const TextStyle(fontSize: 12, color: Colors.black38,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),

          // ── Cards grid ─────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final item    = filtered[index];
                  final palette = _paletteFor(item.index);
                  final done    = _completedStories.contains(item.index);

                  // Stagger: each card fades + slides in with a small delay
                  final delay = (index / filtered.length).clamp(0.0, 0.8);
                  final anim  = CurvedAnimation(
                    parent: _staggerCtrl,
                    curve: Interval(delay, (delay + 0.5).clamp(0.0, 1.0),
                        curve: Curves.easeOutBack),
                  );

                  return AnimatedBuilder(
                    animation: anim,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(0, 40 * (1 - anim.value)),
                      child: Opacity(opacity: anim.value.clamp(0.0, 1.0), child: child),
                    ),
                    child: _StoryCard(
                      story: item.story,
                      palette: palette,
                      completed: done,
                      pageCount: item.story.pages.length,
                      onTap: () => _openStory(item.index, item.story),
                    ),
                  );
                },
                childCount: filtered.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.72,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Indexed story helper ──────────────────────────────────────────────────────
class _IndexedStory {
  final int index;
  final Story story;
  const _IndexedStory(this.index, this.story);
}

// ═════════════════════════════════════════════════════════════════════════════
// LIBRARY HEADER  – big warm illustration-style banner
// ═════════════════════════════════════════════════════════════════════════════
class _LibraryHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF6B6B),
            Color(0xFFFF8E53),
            Color(0xFFFFCA28),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative bubbles
          ..._bubbles(),

          // Content
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 36), // below status bar
                const Text('📚', style: TextStyle(fontSize: 52)),
                const SizedBox(height: 8),
                const Text(
                  'Story Library',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                    shadows: [Shadow(color: Colors.black26, blurRadius: 8)],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap a story and let the magic begin! ✨',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.88),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _bubbles() {
    final data = [
      // [left%, top%, size, opacity]
      [0.05, 0.1,  70.0, 0.15],
      [0.78, 0.05, 90.0, 0.12],
      [0.85, 0.55, 55.0, 0.10],
      [0.10, 0.65, 45.0, 0.13],
      [0.45, 0.02, 38.0, 0.09],
      [0.60, 0.70, 60.0, 0.10],
    ];
    return data.map((d) {
      return LayoutBuilder(builder: (ctx, con) {
        final w = MediaQuery.of(ctx).size.width;
        final h = 210.0;
        return Positioned(
          left: w * (d[0] as double),
          top:  h * (d[1] as double),
          child: Container(
            width: d[2] as double,
            height: d[2] as double,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(d[3] as double),
            ),
          ),
        );
      });
    }).toList();
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// STORY CARD  – tall book-cover feel, very colorful
// ═════════════════════════════════════════════════════════════════════════════
class _StoryCard extends StatefulWidget {
  final Story story;
  final _CardPalette palette;
  final bool completed;
  final int pageCount;
  final VoidCallback onTap;

  const _StoryCard({
    required this.story,
    required this.palette,
    required this.completed,
    required this.pageCount,
    required this.onTap,
  });

  @override
  State<_StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends State<_StoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _pressScale = Tween(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _pressCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;

    return ScaleTransition(
      scale: _pressScale,
      child: GestureDetector(
        onTapDown: (_) => _pressCtrl.forward(),
        onTapUp:   (_) async { await _pressCtrl.reverse(); widget.onTap(); },
        onTapCancel: () => _pressCtrl.reverse(),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: p.gradient.first.withOpacity(0.45),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: p.gradient.last.withOpacity(0.20),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [

                // ── Gradient background ──────────────────────────────────
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: p.gradient,
                      ),
                    ),
                  ),
                ),

                // ── Thumbnail image (top 58%) ────────────────────────────
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: SizedBox(
                    height: 150,
                    child: widget.story.thumbnail != null
                        ? Image.asset(
                      widget.story.thumbnail!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _emojiCover(p.emoji),
                    )
                        : _emojiCover(p.emoji),
                  ),
                ),

                // ── Gradient fade over thumbnail into card body ──────────
                Positioned(
                  top: 100, left: 0, right: 0, height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          p.gradient.last.withOpacity(0.95),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Book spine accent strip ──────────────────────────────
                Positioned(
                  left: 0, top: 0, bottom: 0, width: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.15),
                          Colors.black.withOpacity(0.30),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Completed gold badge (top-right) ─────────────────────
                if (widget.completed)
                  Positioned(
                    top: 10, right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.amber.withOpacity(0.5), blurRadius: 8),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 12, color: Colors.brown),
                          SizedBox(width: 3),
                          Text('Done', style: TextStyle(
                              color: Colors.brown, fontSize: 10,
                              fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),

                // ── Page count badge (top-left) ───────────────────────────
                Positioned(
                  top: 10, left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.pageCount}p',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                // ── Bottom text content ──────────────────────────────────
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          p.gradient.last.withOpacity(0.0),
                          p.gradient.last,
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          widget.story.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                            shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Read button
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.completed
                                    ? Icons.replay_rounded
                                    : Icons.auto_stories_rounded,
                                size: 14,
                                color: p.accent,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                widget.completed ? 'Read again' : 'Read now',
                                style: TextStyle(
                                  color: p.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Shimmer overlay on completed ──────────────────────────
                if (widget.completed)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFFFD700).withOpacity(0.6),
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emojiCover(String emoji) {
    return Container(
      color: Colors.transparent,
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 60)),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SMALL HELPERS
// ═════════════════════════════════════════════════════════════════════════════

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool hasText;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.hasText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7043).withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFFFDCC5), width: 1.5),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
        decoration: InputDecoration(
          hintText: '🔍  Search stories...',
          hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFFF7043), size: 22),
          suffixIcon: hasText
              ? IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: Colors.black38),
            onPressed: onClear,
          )
              : null,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, icon;
  final Color color;
  const _StatChip({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _CircleAppBarBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleAppBarBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.22),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}