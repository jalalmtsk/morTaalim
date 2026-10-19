import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mortaalim/Manager/lesson_progress.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/KidScene/kid_page_parts.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'stories_data.dart';

const String _d = 'assets/images/UI/KidScene/';
const _ink = Color(0xFF2D1A7A);
const _green = Color(0xFF13915A);
const _greenDeep = Color(0xFF0B6B40);
const LessonTracker _tracker = LessonTracker('religion');

class _StoryStore {
  static const _kFavs = 'story_favs';
  static const _kLast = 'story_last';
  static String _kPage(String id) => 'story_page_$id';
  static String _kDone(String id) => 'story_done_$id';

  static Future<Set<String>> favs() async =>
      ((await SharedPreferences.getInstance()).getStringList(_kFavs) ?? const []).toSet();
  static Future<void> setFavs(Set<String> f) async =>
      (await SharedPreferences.getInstance()).setStringList(_kFavs, f.toList());
  static Future<String?> last() async => (await SharedPreferences.getInstance()).getString(_kLast);
  static Future<int> page(String id) async => (await SharedPreferences.getInstance()).getInt(_kPage(id)) ?? 0;
  static Future<bool> done(String id) async => (await SharedPreferences.getInstance()).getBool(_kDone(id)) ?? false;
  static Future<void> savePage(String id, int p) async {
    final s = await SharedPreferences.getInstance();
    await s.setInt(_kPage(id), p);
    await s.setString(_kLast, id);
  }

  /// Returns true the first time a story is finished.
  static Future<bool> markDone(String id) async {
    final s = await SharedPreferences.getInstance();
    if (s.getBool(_kDone(id)) ?? false) return false;
    await s.setBool(_kDone(id), true);
    return true;
  }
}

Route _fade(Widget page) => PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      transitionDuration: const Duration(milliseconds: 350),
    );

TextStyle _title(double size, {Color color = Colors.white, Color outline = _greenDeep}) => TextStyle(
      fontFamily: 'Fredoka',
      fontWeight: FontWeight.w700,
      fontSize: size,
      height: 1.05,
      color: color,
      shadows: [
        Shadow(color: outline, offset: const Offset(0, -2)),
        Shadow(color: outline, offset: const Offset(2, 0)),
        Shadow(color: outline, offset: const Offset(-2, 0)),
        Shadow(color: outline, offset: const Offset(0, 2.5)),
        Shadow(color: outline, offset: const Offset(0, 4)),
        const Shadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 5)),
      ],
    );

/// Round purple button (back, sound, previous).
Widget _roundButton(double size, IconData icon, VoidCallback? onTap, {bool outlined = false, String? label}) => KidPressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: outlined
              ? null
              : const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF9B5CFF), Color(0xFF6A2BE0)]),
          color: outlined ? Colors.white : null,
          border: Border.all(color: outlined ? const Color(0xFF8B5CF6) : Colors.white, width: outlined ? 3 : 2.5),
          boxShadow: [BoxShadow(color: const Color(0xFF4A1BA8).withOpacity(0.35), blurRadius: 6, offset: const Offset(0, 3))],
        ),
        child: Icon(icon, color: outlined ? const Color(0xFF6A2BE0) : Colors.white, size: size * 0.52),
      ),
    );

Widget _pill(double h, Widget child, {List<Color>? colors, Color border = Colors.white, Color lip = const Color(0xFFD08A00), VoidCallback? onTap}) =>
    KidPressable(
      onTap: onTap,
      pressedScale: 0.95,
      child: Container(
        height: h,
        padding: EdgeInsets.symmetric(horizontal: h * 0.35),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(h),
          gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors ?? const [Color(0xFFFFE45C), Color(0xFFFFC21A)]),
          border: Border.all(color: border, width: 2.5),
          boxShadow: [BoxShadow(color: lip, offset: Offset(0, h * 0.07)), BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: Offset(0, h * 0.12))],
        ),
        child: Center(child: child),
      ),
    );

// ═══════════════════════════════════════════════════════════════════════════
// Menu
// ═══════════════════════════════════════════════════════════════════════════

enum _Filter { all, listen, favs }

class StoriesMenuPage extends StatefulWidget {
  const StoriesMenuPage({super.key});
  @override
  State<StoriesMenuPage> createState() => _StoriesMenuPageState();
}

class _StoriesMenuPageState extends State<StoriesMenuPage> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 7))..repeat();
  _Filter _filter = _Filter.all;
  Set<String> _favs = {};
  Story? _last;
  int _lastPage = 0;
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      KidAssets.precache(context, [
        '${_d}it_page_bg.webp', '${_d}stories_hero.webp', '${_d}stories_banner.webp', '${_d}stories_lantern.webp',
        for (final s in allStories) s.thumb,
      ]);
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _idle.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final favs = await _StoryStore.favs();
    final lastId = await _StoryStore.last();
    final last = allStories.firstWhere((s) => s.id == lastId && s.available, orElse: () => allStories.first);
    final page = await _StoryStore.page(last.id);
    if (mounted) setState(() {
      _favs = favs;
      _last = last;
      _lastPage = page;
    });
  }

  AudioManager get _audio => Provider.of<AudioManager>(context, listen: false);

  Future<void> _open(Story s, {bool listen = false, int? page}) async {
    if (!s.available) {
      _audio.playEventSound('clickButton2');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _greenDeep,
        content: Text(storyUi(context, 'soonMsg'), style: kidBodyStyle(15, color: Colors.white, weight: FontWeight.w600)),
      ));
      return;
    }
    _audio.playEventSound('PopButton');
    final start = page ?? await _StoryStore.page(s.id);
    if (!mounted) return;
    await Navigator.push(context, _fade(StoryReaderPage(story: s, startPage: start, autoListen: listen)));
    if (mounted) _refresh();
  }

  Future<void> _toggleFav(String id) async {
    _audio.playEventSound('clickButton2');
    setState(() => _favs.contains(id) ? _favs.remove(id) : _favs.add(id));
    await _StoryStore.setFavs(_favs);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final w = min(size.width, 600.0) - 28;
    final s = (w / 380).clamp(0.8, 1.4);
    final list = switch (_filter) {
      _Filter.all => allStories,
      _Filter.listen => allStories.where((x) => x.available).toList(),
      _Filter.favs => allStories.where((x) => _favs.contains(x.id)).toList(),
    };
    Widget step(int i, Widget c) => KidIntro(intro: _intro, from: 0.06 * i, to: min(1.0, 0.45 + 0.06 * i), rise: 22, child: c);

    return Scaffold(
      backgroundColor: KidColors.sky,
      body: Stack(children: [
        const Positioned.fill(child: KidPageBackground(asset: '${_d}it_page_bg.webp', wash: 0.04)),
        SafeArea(
          bottom: false,
          child: Center(
            child: SizedBox(
              width: w,
              child: Column(children: [
                const SizedBox(height: 6),
                step(0, _header(s)),
                SizedBox(height: 10 * s),
                Expanded(
                  child: CustomScrollView(physics: const BouncingScrollPhysics(), slivers: [
                    SliverToBoxAdapter(child: step(1, _hero(s))),
                    SliverToBoxAdapter(child: SizedBox(height: 12 * s)),
                    if (_last != null) SliverToBoxAdapter(child: step(2, _continueCard(s, _last!))),
                    SliverToBoxAdapter(child: SizedBox(height: 12 * s)),
                    SliverToBoxAdapter(child: step(3, _filters(s))),
                    SliverToBoxAdapter(child: SizedBox(height: 12 * s)),
                    if (list.isEmpty)
                      SliverToBoxAdapter(
                        child: Container(
                          padding: EdgeInsets.all(16 * s),
                          decoration: kidCardDecoration(22 * s),
                          child: Text(storyUi(context, 'noFavs'),
                              textAlign: TextAlign.center, style: kidBodyStyle(15 * s, color: _ink, weight: FontWeight.w600)),
                        ),
                      )
                    else
                      SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: size.width >= 700 ? 3 : 2,
                          mainAxisSpacing: 12 * s,
                          crossAxisSpacing: 12 * s,
                          childAspectRatio: 0.93,
                        ),
                        delegate: SliverChildBuilderDelegate((c, i) => step(4 + min(i, 4), _storyCard(s, list[i])), childCount: list.length),
                      ),
                    SliverToBoxAdapter(child: SizedBox(height: 12 * s)),
                    SliverToBoxAdapter(child: step(9, _banner(s))),
                    SliverToBoxAdapter(child: SizedBox(height: 20 * s + pad.bottom)),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _header(double s) => Container(
        height: 62 * s,
        padding: EdgeInsets.symmetric(horizontal: 6 * s),
        decoration: kidCardDecoration(40 * s, shadow: 0.18),
        child: Row(children: [
          _roundButton(48 * s, Icons.arrow_back_rounded, () {
            _audio.playEventSound('cancelButton');
            Navigator.of(context).maybePop();
          }),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(storyUi(context, 'title'), style: kidTitleStyle(32 * s, color: _ink).copyWith(shadows: const [])),
            ),
          ),
          Consumer<AudioManager>(
            builder: (_, a, __) => _roundButton(48 * s, a.isBgMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded, () {
              a.playEventSound('toggleButton');
              a.toggleBgMute();
            }),
          ),
        ]),
      );

  Widget _hero(double s) => AspectRatio(
        aspectRatio: 935 / 320,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26 * s),
          child: LayoutBuilder(builder: (c, b) {
            final h = b.maxHeight, w = b.maxWidth;
            return Stack(children: [
              Positioned.fill(child: Image.asset('${_d}stories_hero.webp', fit: BoxFit.cover)),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.centerStart,
                      end: AlignmentDirectional.centerEnd,
                      colors: [const Color(0xFF0B4F36).withOpacity(0.7), Colors.transparent],
                      stops: const [0.3, 0.62],
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                start: w * 0.05,
                top: h * 0.12,
                bottom: h * 0.12,
                width: w * 0.52,
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  FittedBox(fit: BoxFit.scaleDown, child: Text(storyUi(context, 'heroTop'), style: _title(h * 0.2, color: const Color(0xFFFFF4D6), outline: const Color(0xFF8A4B12)))),
                  FittedBox(fit: BoxFit.scaleDown, child: Text(storyUi(context, 'heroBottom'), style: _title(h * 0.2, color: const Color(0xFFFFF4D6), outline: const Color(0xFF8A4B12)))),
                  SizedBox(height: h * 0.05),
                  Flexible(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 3 * s),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B4F36).withOpacity(0.8),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0xFFFFD98A), width: 1.2),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(storyUi(context, 'heroSub'), style: kidBodyStyle(12 * s, color: Colors.white, weight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ]),
              ),
            ]);
          }),
        ),
      );

  Widget _continueCard(double s, Story st) {
    final total = st.pages.length;
    final started = _lastPage > 0;
    return KidPressable(
      onTap: () => _open(st),
      pressedScale: 0.97,
      child: Container(
        padding: EdgeInsets.all(8 * s),
        decoration: kidCardDecoration(24 * s, shadow: 0.2),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16 * s),
            child: Image.asset(st.thumb, width: 96 * s, height: 64 * s, fit: BoxFit.cover),
          ),
          SizedBox(width: 10 * s),
          Expanded(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(storyUi(context, started ? 'continue' : 'start'), style: kidBodyStyle(13 * s, color: _green, weight: FontWeight.w700)),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(pick(st.title, context), style: kidBodyStyle(18 * s, color: _ink, weight: FontWeight.w700)),
              ),
              SizedBox(height: 6 * s),
              Row(children: [
                Expanded(child: _GreenBar(value: total == 0 ? 0 : (_lastPage + (started ? 1 : 0)) / total, height: 8 * s)),
                SizedBox(width: 8 * s),
                Text('${started ? _lastPage + 1 : 0} / $total', style: kidBodyStyle(11.5 * s, color: KidColors.muted, weight: FontWeight.w700)),
              ]),
            ]),
          ),
          SizedBox(width: 8 * s),
          AnimatedBuilder(
            animation: _idle,
            builder: (_, c) => Transform.scale(scale: 1 + 0.05 * sin(_idle.value * 8 * pi), child: c),
            child: Container(
              width: 56 * s,
              height: 56 * s,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2CC07A), _greenDeep]),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [BoxShadow(color: _green.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36 * s),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _filters(double s) {
    Widget chip(_Filter f, IconData icon, String key) {
      final active = _filter == f;
      return Expanded(
        child: KidPressable(
          onTap: () {
            if (active) return;
            _audio.playEventSound('clickButton2');
            setState(() => _filter = f);
          },
          pressedScale: 0.94,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 46 * s,
            padding: EdgeInsets.symmetric(horizontal: 8 * s),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              gradient: active ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2CC07A), _green]) : null,
              color: active ? null : KidColors.cream,
              border: Border.all(color: active ? const Color(0xFFBDEFD2) : Colors.white, width: 2),
              boxShadow: [BoxShadow(color: _greenDeep.withOpacity(active ? 0.3 : 0.1), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(icon, color: active ? Colors.white : const Color(0xFF7C3AED), size: 22 * s),
                  SizedBox(width: 6 * s),
                  Text(storyUi(context, key), style: kidBodyStyle(15 * s, color: active ? Colors.white : _ink, weight: FontWeight.w700)),
                ]),
              ),
            ),
          ),
        ),
      );
    }

    return Row(children: [
      chip(_Filter.all, Icons.menu_book_rounded, 'all'),
      SizedBox(width: 7 * s),
      chip(_Filter.listen, Icons.headphones_rounded, 'listen'),
      SizedBox(width: 7 * s),
      chip(_Filter.favs, Icons.favorite_border_rounded, 'favs'),
    ]);
  }

  Widget _storyCard(double s, Story st) {
    final fav = _favs.contains(st.id);
    final ok = st.available;
    return Container(
      padding: EdgeInsets.all(6 * s),
      decoration: kidCardDecoration(22 * s, shadow: 0.18),
      child: Column(children: [
        Expanded(
          child: KidPressable(
            onTap: () => _open(st),
            pressedScale: 0.97,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16 * s),
              child: Stack(fit: StackFit.expand, children: [
                Image.asset(st.thumb, fit: BoxFit.cover),
                if (!ok) ...[
                  ColoredBox(color: Colors.white.withOpacity(0.3)),
                  PositionedDirectional(
                    top: 6 * s,
                    end: 6 * s,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 9 * s, vertical: 3 * s),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(colors: [Color(0xFF2CC07A), _greenDeep]),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(storyUi(context, 'soon'), style: kidBodyStyle(12 * s, color: Colors.white, weight: FontWeight.w700)),
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ),
        SizedBox(height: 6 * s),
        Row(children: [
          SizedBox(width: 4 * s),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(pick(st.title, context), maxLines: 1, style: kidBodyStyle(15.5 * s, color: _ink, weight: FontWeight.w700)),
            ),
          ),
          KidPressable(
            onTap: () => _toggleFav(st.id),
            child: Padding(
              padding: EdgeInsets.all(2 * s),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                child: Icon(fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    key: ValueKey(fav), color: fav ? const Color(0xFFEC4899) : const Color(0xFF7C3AED), size: 26 * s),
              ),
            ),
          ),
        ]),
        SizedBox(height: 4 * s),
        Opacity(
          opacity: ok ? 1 : 0.5,
          child: Row(children: [
            Expanded(
              child: KidPressable(
                onTap: () => _open(st),
                pressedScale: 0.93,
                child: Container(
                  height: 36 * s,
                  decoration: BoxDecoration(color: const Color(0xFFE9E1FF), borderRadius: BorderRadius.circular(30)),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.menu_book_rounded, color: const Color(0xFF6A2BE0), size: 18 * s),
                        SizedBox(width: 4 * s),
                        Text(storyUi(context, 'read'), style: kidBodyStyle(14 * s, color: _ink, weight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 6 * s),
            Expanded(
              child: KidPressable(
                onTap: () => _open(st, listen: true),
                pressedScale: 0.93,
                child: Container(
                  height: 36 * s,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2CC07A), _greenDeep]),
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20 * s),
                        SizedBox(width: 2 * s),
                        Text(storyUi(context, 'hear'), style: kidBodyStyle(14 * s, color: Colors.white, weight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _banner(double s) => AspectRatio(
        aspectRatio: 950 / 175,
        child: LayoutBuilder(builder: (c, b) {
          final w = b.maxWidth, h = b.maxHeight;
          return Stack(children: [
            Positioned.fill(child: Image.asset('${_d}stories_banner.webp', fit: BoxFit.fill)),
            Positioned(
              left: w * 0.33,
              right: w * 0.04,
              top: h * 0.1,
              height: h * 0.36,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(storyUi(context, 'calm'),
                    textAlign: TextAlign.center, style: kidBodyStyle(15 * s, color: _ink, weight: FontWeight.w700).copyWith(height: 1.1)),
              ),
            ),
            // the yellow button baked in the banner art
            Positioned(
              left: w * 0.525,
              width: w * 0.37,
              top: h * 0.4,
              height: h * 0.36,
              child: KidPressable(
                onTap: () => _open(allStories.firstWhere((x) => x.available)),
                child: Padding(
                  padding: EdgeInsets.only(right: w * 0.045),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(storyUi(context, 'discover'), style: kidBodyStyle(15 * s, color: const Color(0xFF6B3A00), weight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
            ),
          ]);
        }),
      );
}

class _GreenBar extends StatelessWidget {
  final double value, height;
  const _GreenBar({required this.value, required this.height});
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: SizedBox(
          height: height,
          child: Stack(children: [
            const Positioned.fill(child: ColoredBox(color: Color(0xFFE6DFCF))),
            AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 400),
              widthFactor: value.clamp(0.0, 1.0),
              child: const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF34C985), _green]))),
            ),
          ]),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// Reader
// ═══════════════════════════════════════════════════════════════════════════

class StoryReaderPage extends StatefulWidget {
  final Story story;
  final int startPage;
  final bool autoListen; // "Écouter": read aloud and turn pages by itself
  const StoryReaderPage({super.key, required this.story, this.startPage = 0, this.autoListen = false});
  @override
  State<StoryReaderPage> createState() => _StoryReaderPageState();
}

class _StoryReaderPageState extends State<StoryReaderPage> with TickerProviderStateMixin {
  static const _speeds = [0.75, 1.0, 1.25];
  static const _fontScales = [1.0, 1.15, 1.3, 0.9];

  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 7))..repeat();
  final FlutterTts _tts = FlutterTts();
  late int _page = widget.startPage.clamp(0, widget.story.pages.length - 1);
  bool _ended = false;
  bool _fav = false;
  bool _playing = false;
  late bool _auto = widget.autoListen;
  int _reading = -1; // paragraph being read
  int _charsDone = 0; // chars already spoken on this page
  int _speedIx = 1, _fontIx = 0;
  int _session = 0; // invalidates an old reading loop
  late AudioManager _audio;

  Story get _st => widget.story;
  List<String> _paras(BuildContext c) => pickList(_st.pages[_page].text, c);
  int _pageChars(BuildContext c) => _paras(c).fold(0, (a, p) => a + p.length);

  @override
  void initState() {
    super.initState();
    _StoryStore.favs().then((f) {
      if (mounted) setState(() => _fav = f.contains(_st.id));
    });
    _tts.awaitSpeakCompletion(true);
    _tts.setProgressHandler((text, start, end, word) {
      if (!mounted || _reading < 0) return;
      final before = _paras(context).take(_reading).fold(0, (a, p) => a + p.length);
      setState(() => _charsDone = before + end);
    });
    _StoryStore.savePage(_st.id, _page);
    if (_auto) WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audio = Provider.of<AudioManager>(context, listen: false);
    for (final p in _st.pages) {
      precacheImage(AssetImage(p.image), context);
    }
    precacheImage(const AssetImage('${_d}story_reader_bg.webp'), context);
  }

  @override
  void dispose() {
    _session++;
    _tts.stop();
    _idle.dispose();
    super.dispose();
  }

  Future<void> _stop() async {
    _session++;
    await _tts.stop();
    if (mounted) setState(() {
      _playing = false;
      _reading = -1;
    });
  }

  /// Reads the page paragraph by paragraph from [from].
  Future<void> _play({int from = 0}) async {
    final my = ++_session;
    await _tts.stop();
    final lang = storyLang(context);
    final code = switch (lang) { 'ar' => 'ar-SA', 'de' => 'de-DE', 'en' => 'en-US', _ => 'fr-FR' };
    try {
      await _tts.setLanguage(code);
      await _tts.setSpeechRate(0.45 * _speeds[_speedIx]);
      await _tts.setPitch(1.08);
    } catch (_) {}
    if (!mounted) return;
    final paras = _paras(context);
    setState(() {
      _playing = true;
      _charsDone = paras.take(from).fold(0, (a, p) => a + p.length);
    });
    for (int i = from; i < paras.length; i++) {
      if (my != _session || !mounted) return;
      setState(() => _reading = i);
      try {
        await _tts.speak(paras[i]);
      } catch (_) {}
      if (my != _session || !mounted) return;
      setState(() => _charsDone = paras.take(i + 1).fold(0, (a, p) => a + p.length));
    }
    if (my != _session || !mounted) return;
    setState(() {
      _playing = false;
      _reading = -1;
    });
    if (_auto) {
      await Future.delayed(const Duration(milliseconds: 900));
      if (my == _session && mounted) _next(keepReading: true);
    }
  }

  void _togglePlay() {
    _audio.playEventSound('clickButton2');
    if (_playing) {
      _auto = false;
      _stop();
    } else {
      final paras = _paras(context);
      var from = 0, acc = 0;
      for (int i = 0; i < paras.length; i++) {
        if (acc + paras[i].length > _charsDone) {
          from = i;
          break;
        }
        acc += paras[i].length;
        from = i + 1;
      }
      _play(from: from >= paras.length ? 0 : from);
    }
  }

  void _goTo(int p, {bool keepReading = false}) {
    _session++;
    _tts.stop();
    setState(() {
      _page = p;
      _ended = false;
      _playing = false;
      _reading = -1;
      _charsDone = 0;
    });
    _StoryStore.savePage(_st.id, p);
    if (keepReading) WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  Future<void> _next({bool keepReading = false}) async {
    if (_page < _st.pages.length - 1) {
      if (!keepReading) _audio.playEventSound('clickButton');
      _goTo(_page + 1, keepReading: keepReading || _auto);
      return;
    }
    await _stop();
    _auto = false;
    final first = await _StoryStore.markDone(_st.id);
    await _tracker.record('stories', allStories.indexOf(_st));
    await _StoryStore.savePage(_st.id, 0);
    if (!mounted) return;
    _audio.playSfx('assets/audios/UI_Audio/SFX_Audio/victory2_SFX.mp3');
    if (first) {
      final xp = Provider.of<ExperienceManager>(context, listen: false);
      xp.addTokenBanner(context, 20);
      xp.addXP(10, context: context);
    }
    setState(() => _ended = true);
  }

  void _prev() {
    if (_page == 0) return;
    _audio.playEventSound('clickButton');
    _goTo(_page - 1);
  }

  Future<void> _toggleFav() async {
    _audio.playEventSound('clickButton2');
    final f = await _StoryStore.favs();
    _fav ? f.remove(_st.id) : f.add(_st.id);
    await _StoryStore.setFavs(f);
    if (mounted) setState(() => _fav = !_fav);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = min(size.width, 560.0) - 24;
    final s = (w / 380).clamp(0.78, 1.35);
    return Scaffold(
      backgroundColor: const Color(0xFF9AD27A),
      body: Stack(children: [
        Positioned.fill(child: Image.asset('${_d}story_reader_bg.webp', fit: BoxFit.cover)),
        Positioned.fill(child: ColoredBox(color: Colors.white.withOpacity(0.12))),
        SafeArea(
          child: Center(
            child: SizedBox(
              width: w,
              child: Column(children: [
                const SizedBox(height: 4),
                _topBar(s),
                SizedBox(height: 6 * s),
                _titleBanner(s, _ended ? '${storyUi(context, 'bravo')}\n${storyUi(context, 'done')}' : pick(_st.title, context),
                    _ended ? pick(_st.title, context) : pick(_st.subtitle, context)),
                SizedBox(height: 8 * s),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 380),
                    transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
                    child: _ended ? KeyedSubtree(key: const ValueKey('end'), child: _endView(s)) : KeyedSubtree(key: ValueKey(_page), child: _pageView(s)),
                  ),
                ),
                SizedBox(height: 8 * s),
                if (!_ended) ...[
                  _player(s),
                  SizedBox(height: 8 * s),
                  _navBar(s),
                ] else
                  _endButtons(s),
                SizedBox(height: 8 * s),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _topBar(double s) => Container(
        height: 58 * s,
        padding: EdgeInsets.symmetric(horizontal: 6 * s),
        decoration: kidCardDecoration(40 * s, shadow: 0.18),
        child: Row(children: [
          _roundButton(46 * s, Icons.arrow_back_rounded, () {
            _audio.playEventSound('cancelButton');
            Navigator.of(context).maybePop();
          }),
          Expanded(child: Center(child: Text(storyUi(context, 'title'), style: kidBodyStyle(22 * s, color: _ink, weight: FontWeight.w700)))),
          _roundButton(46 * s, _fav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, _toggleFav, outlined: true),
        ]),
      );

  Widget _titleBanner(double s, String title, String sub) => Column(mainAxisSize: MainAxisSize.min, children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(title, maxLines: 2, textAlign: TextAlign.center, style: _title((title.contains('\n') ? 28 : 34) * s)),
        ),
        SizedBox(height: 4 * s),
        if (sub.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 3 * s),
            decoration: BoxDecoration(
              color: KidColors.cream,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFFFD98A), width: 1.5),
            ),
            child: Text(sub, style: kidBodyStyle(13 * s, color: _ink, weight: FontWeight.w700)),
          ),
      ]);

  Widget _pageView(double s) {
    final paras = _paras(context);
    final fontScale = _fontScales[_fontIx];
    final rtl = storyLang(context) == 'ar';
    return Column(children: [
      // illustration
      Flexible(
        flex: 5,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26 * s),
            border: Border.all(color: KidColors.cream, width: 4),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22 * s),
            child: AnimatedBuilder(
              animation: _idle,
              builder: (_, c) => Transform.scale(scale: 1.03 + 0.02 * sin(_idle.value * 2 * pi), child: c),
              child: SizedBox.expand(child: Image.asset(_st.pages[_page].image, fit: BoxFit.cover)),
            ),
          ),
        ),
      ),
      SizedBox(height: 8 * s),
      // text card
      Flexible(
        flex: 6,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(12 * s, 12 * s, 12 * s, 8 * s),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFCF3),
            borderRadius: BorderRadius.circular(26 * s),
            border: Border.all(color: const Color(0xFFFFE08A), width: 2.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 5))],
          ),
          child: Column(children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(children: [
                  for (int i = 0; i < paras.length; i++)
                    GestureDetector(
                      onTap: () => _play(from: i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: double.infinity,
                        margin: EdgeInsets.only(bottom: 6 * s),
                        padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 6 * s),
                        decoration: BoxDecoration(
                          color: _reading == i ? const Color(0xFFDFF5E6) : Colors.transparent,
                          borderRadius: BorderRadius.circular(16 * s),
                        ),
                        child: Text(paras[i],
                            textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
                            style: kidBodyStyle(19 * s * fontScale, color: _ink, weight: FontWeight.w600).copyWith(height: 1.35)),
                      ),
                    ),
                ]),
              ),
            ),
            SizedBox(height: 6 * s),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _smallPill(s, Text('Aa', style: kidBodyStyle(18 * s, color: _ink, weight: FontWeight.w700)), () {
                _audio.playEventSound('clickButton2');
                setState(() => _fontIx = (_fontIx + 1) % _fontScales.length);
              }),
              SizedBox(width: 8 * s),
              _smallPill(
                s,
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 28 * s,
                    height: 28 * s,
                    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF9B5CFF), Color(0xFF6A2BE0)])),
                    child: Icon(_playing ? Icons.graphic_eq_rounded : Icons.volume_up_rounded, color: Colors.white, size: 17 * s),
                  ),
                  SizedBox(width: 6 * s),
                  Text(storyUi(context, 'readWithMe'), style: kidBodyStyle(14 * s, color: _ink, weight: FontWeight.w700)),
                ]),
                () {
                  _audio.playEventSound('clickButton2');
                  _play();
                },
                flex: true,
              ),
              SizedBox(width: 8 * s),
              _smallPill(s, Text('${_speeds[_speedIx]}×'.replaceAll('.0', ''), style: kidBodyStyle(16 * s, color: _ink, weight: FontWeight.w700)), () {
                _audio.playEventSound('clickButton2');
                setState(() => _speedIx = (_speedIx + 1) % _speeds.length);
                if (_playing) _play(from: max(0, _reading));
              }),
            ]),
          ]),
        ),
      ),
    ]);
  }

  Widget _smallPill(double s, Widget child, VoidCallback onTap, {bool flex = false}) {
    final pill = KidPressable(
      onTap: onTap,
      pressedScale: 0.93,
      child: Container(
        height: 40 * s,
        padding: EdgeInsets.symmetric(horizontal: 12 * s),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFF1E4C8), width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: child)),
      ),
    );
    return flex ? Flexible(child: pill) : pill;
  }

  Widget _player(double s) {
    final total = max(1, _pageChars(context));
    final v = (_charsDone / total).clamp(0.0, 1.0);
    final secs = (total / (14 * _speeds[_speedIx])).round();
    String mmss(int x) => '${x ~/ 60}:${(x % 60).toString().padLeft(2, '0')}';
    return Container(
      height: 64 * s,
      padding: EdgeInsetsDirectional.only(start: 4 * s, end: 12 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40 * s),
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1FA35E), _greenDeep]),
        border: Border.all(color: const Color(0xFFFFE08A), width: 2.5),
        boxShadow: [BoxShadow(color: _greenDeep.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: Row(children: [
        KidPressable(
          onTap: _togglePlay,
          child: AnimatedBuilder(
            animation: _idle,
            builder: (_, c) => Transform.scale(scale: _playing ? 1 + 0.04 * sin(_idle.value * 30 * pi) : 1, child: c),
            child: Container(
              width: 54 * s,
              height: 54 * s,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: const Color(0xFFFFE08A), width: 3),
              ),
              child: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: _green, size: 36 * s),
            ),
          ),
        ),
        SizedBox(width: 8 * s),
        Text(mmss((v * secs).round()), style: kidBodyStyle(13 * s, color: Colors.white, weight: FontWeight.w700)),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 8 * s,
              activeTrackColor: const Color(0xFFFFD447),
              inactiveTrackColor: const Color(0xFF0A5434),
              thumbColor: const Color(0xFFFFD447),
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10 * s, elevation: 3),
              overlayColor: Colors.white24,
            ),
            child: Slider(
              value: v,
              onChanged: (x) {
                final paras = _paras(context);
                final target = (x * total).round();
                var acc = 0, from = 0;
                for (int i = 0; i < paras.length; i++) {
                  if (acc + paras[i].length > target) {
                    from = i;
                    break;
                  }
                  acc += paras[i].length;
                }
                setState(() => _charsDone = acc);
                if (_playing) _play(from: from);
              },
            ),
          ),
        ),
        Text(mmss(secs), style: kidBodyStyle(13 * s, color: Colors.white, weight: FontWeight.w700)),
        SizedBox(width: 6 * s),
        KidPressable(
          onTap: () {
            _audio.playEventSound('clickButton2');
            _play();
          },
          child: Icon(Icons.replay_rounded, color: Colors.white, size: 28 * s),
        ),
      ]),
    );
  }

  Widget _navBar(double s) {
    final n = _st.pages.length;
    final last = _page == n - 1;
    return Container(
      height: 66 * s,
      padding: EdgeInsets.symmetric(horizontal: 8 * s),
      decoration: kidCardDecoration(40 * s, shadow: 0.18),
      child: Row(children: [
        Opacity(opacity: _page == 0 ? 0.35 : 1, child: _roundButton(46 * s, Icons.chevron_left_rounded, _prev)),
        Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(storyUi(context, 'page', args: {'n': '${_page + 1}', 't': '$n'}), style: kidBodyStyle(14 * s, color: _ink, weight: FontWeight.w700)),
            SizedBox(height: 4 * s),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (int i = 0; i < n; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 11 * s,
                  height: 11 * s,
                  margin: EdgeInsets.symmetric(horizontal: 2.5 * s),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: i == _page ? _green : const Color(0xFFE2D8C4)),
                ),
            ]),
          ]),
        ),
        _pill(
          48 * s,
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text(storyUi(context, last ? 'finish' : 'next'), style: kidBodyStyle(19 * s, color: const Color(0xFF4A2A00), weight: FontWeight.w700)),
            SizedBox(width: 4 * s),
            Icon(Icons.chevron_right_rounded, color: const Color(0xFF4A2A00), size: 24 * s),
          ]),
          onTap: () => _next(),
        ),
      ]),
    );
  }

  // ── Ending ────────────────────────────────────────────────────────────────
  Widget _endView(double s) {
    Widget section(String title, Widget body) => Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(12 * s, 10 * s, 12 * s, 12 * s),
          decoration: kidCardDecoration(26 * s, shadow: 0.15).copyWith(border: Border.all(color: const Color(0xFFFFE08A), width: 2.5)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 18 * s, vertical: 4 * s),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF6DA),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFFFFD447), width: 2),
              ),
              child: Text(title, style: kidBodyStyle(19 * s, color: _ink, weight: FontWeight.w700)),
            ),
            SizedBox(height: 8 * s),
            body,
          ]),
        );
    Widget note(String t) => Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 10 * s),
          decoration: BoxDecoration(color: const Color(0xFFE6F6EB), borderRadius: BorderRadius.circular(16 * s)),
          child: Text(t, textAlign: TextAlign.center, style: kidBodyStyle(16.5 * s, color: _ink, weight: FontWeight.w700)),
        );
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(children: [
        AspectRatio(
          aspectRatio: 820 / 425,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24 * s),
            child: Image.asset(_st.endImage, fit: BoxFit.cover),
          ),
        ),
        SizedBox(height: 10 * s),
        section(
          storyUi(context, 'remember'),
          Column(children: [
            note(pick(_st.lesson, context)),
            SizedBox(height: 10 * s),
            Row(children: [
              for (int i = 0; i < _st.values.length; i++)
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 450 + i * 200),
                    curve: Curves.easeOutBack,
                    builder: (_, v, c) => Transform.scale(scale: v, child: c),
                    child: Column(children: [
                      Image.asset(_st.values[i].image, height: 72 * s, fit: BoxFit.contain),
                      SizedBox(height: 4 * s),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 3 * s),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF6DA),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFFD447), width: 1.5),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(pick(_st.values[i].label, context), style: kidBodyStyle(14 * s, color: _ink, weight: FontWeight.w700)),
                        ),
                      ),
                    ]),
                  ),
                ),
            ]),
          ]),
        ),
        SizedBox(height: 10 * s),
        section(storyUi(context, 'challenge'), note(pick(_st.challenge, context))),
      ]),
    );
  }

  Widget _endButtons(double s) => Row(children: [
        Expanded(
          child: KidPressable(
            onTap: () {
              _audio.playEventSound('clickButton');
              _goTo(0);
            },
            pressedScale: 0.95,
            child: Container(
              height: 60 * s,
              decoration: kidCardDecoration(34 * s, shadow: 0.18),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 40 * s,
                  height: 40 * s,
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF9B5CFF), Color(0xFF6A2BE0)])),
                  child: Icon(Icons.menu_book_rounded, color: Colors.white, size: 22 * s),
                ),
                SizedBox(width: 8 * s),
                Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(storyUi(context, 'reread'), style: kidBodyStyle(18 * s, color: _ink, weight: FontWeight.w700)))),
              ]),
            ),
          ),
        ),
        SizedBox(width: 10 * s),
        Expanded(
          child: _pill(
            60 * s,
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(storyUi(context, 'more'), style: kidBodyStyle(17 * s, color: const Color(0xFF4A2A00), weight: FontWeight.w700)),
                Icon(Icons.chevron_right_rounded, color: const Color(0xFF4A2A00), size: 24 * s),
              ]),
            ),
            onTap: () {
              _audio.playEventSound('clickButton');
              Navigator.of(context).maybePop();
            },
          ),
        ),
      ]);
}
