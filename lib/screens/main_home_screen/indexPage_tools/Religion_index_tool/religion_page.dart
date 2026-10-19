import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/Manager/lesson_progress.dart';
import 'package:mortaalim/PractiseGames/IslamExercice/WuduGame.dart';
import 'package:mortaalim/PractiseGames/MatchTheImage/MatchTheImage.dart';
import 'package:mortaalim/PractiseGames/PlayTheWord/PlayTheWord.dart';
import 'package:mortaalim/PractiseGames/practiseWords.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/GetReady__Widget.dart';
import 'package:mortaalim/widgets/KidScene/kid_page_parts.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:mortaalim/widgets/RandomAyat_Card/Ayat_List.dart';
import 'quran_page.dart';
import 'Stories/stories_data.dart';
import 'Stories/stories_pages.dart';
import 'Manners/manners_page.dart';
import 'package:provider/provider.dart';

class ReligionAssets {
  ReligionAssets._();
  static const String dir = 'assets/images/UI/KidScene/';
  static const String bg = '${dir}religion_bg.webp';
  static const String heroBg = '${dir}rel_hero_bg.webp';
  static const String quranStand = '${dir}rel_quran.webp';
  static const String lantern = '${dir}rel_lantern.webp';
  static const String moon = '${dir}rel_moon.webp';
  static const String play = '${dir}rel_play.webp';
  static const String heart = '${dir}rel_heart.webp';
  static const String leaves = '${dir}rel_leaves.webp';
  static const String ornamentBar = '${dir}rel_ornament_bar.webp';
  static const String goOrange = '${dir}courses_go_orange.webp';
  static String tile(String id) => '${dir}rel_tile_$id.webp';
  static const String fatihaAudio = 'assets/audios/quranSourate/fatiha.mp3';

  static List<String> get all => [
        bg, heroBg, quranStand, lantern, moon, play, heart, leaves, ornamentBar, goOrange, kidCoinAsset, kidGemAsset,
        for (final t in ['quran', 'prayer', 'duas', 'stories', 'manners', 'basics']) tile(t),
      ];
}

const LessonTracker _tracker = LessonTracker('religion');
const LessonTracker _kindness = LessonTracker('kindness');
const _ink = KidColors.ink;
const _emerald = Color(0xFF13915A);
const _emeraldDeep = Color(0xFF075238);
const _gold = Color(0xFFFFC94A);

// ─── Content ──────────────────────────────────────────────────────────────

const List<String> _fatiha = [
  'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
  'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
  'الرَّحْمَنِ الرَّحِيمِ',
  'مَالِكِ يَوْمِ الدِّينِ',
  'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ',
  'اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ',
  'صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ',
];

/// Quran items: Al-Fatiha first, then the verses already in the app.
int get _quranCount => quranItemCount;

class _Duaa {
  final String Function(BuildContext) label;
  final String text, emoji;
  final List<Color> colors;
  final bool Function(int hour) isNow;
  const _Duaa(this.label, this.text, this.emoji, this.colors, this.isNow);
}

final List<_Duaa> _duaas = [
  _Duaa((c) => tr(c).duaaMorning, 'الحمد لله الذي أحيانا بعدما أماتنا وإليه النشور', '🌅',
      const [Color(0xFFFFE3A3), Color(0xFFFFB45C)], (h) => h >= 5 && h < 12),
  _Duaa((c) => tr(c).duaaAfternoon, 'اللهم أعني على ذكرك وشكرك وحسن عبادتك', '☀️',
      const [Color(0xFFCDEBFF), Color(0xFF7CC2FF)], (h) => h >= 12 && h < 18),
  _Duaa((c) => tr(c).duaaNight, 'اللهم بك أمسينا وبك أصبحنا وبك نحيا وبك نموت وإليك المصير', '🌙',
      const [Color(0xFFC9C3FF), Color(0xFF7E73E8)], (h) => h >= 18 || h < 5),
];

final List<PractiseWords> _wuduSteps = [
  PractiseWords(word: 'النية', emoji: '🧠', imagePath: 'assets/images/PractiseImage/WuduImages/intention_wudu.png', audioPath: 'assets/audios/tts_female/Wudu/intention_female.mp3'),
  PractiseWords(word: 'غسل اليدين', emoji: '👐', imagePath: 'assets/images/PractiseImage/WuduImages/hands_wudu.png', audioPath: 'assets/audios/tts_female/Wudu/hands_female.mp3'),
  PractiseWords(word: 'المضمضة', emoji: '👄', imagePath: 'assets/images/PractiseImage/WuduImages/mouth_wudu.png', audioPath: 'assets/audios/tts_female/Wudu/mouth_female.mp3'),
  PractiseWords(word: 'الاستنشاق', emoji: '👃', imagePath: 'assets/images/PractiseImage/WuduImages/nose_wudu.png', audioPath: 'assets/audios/tts_female/Wudu/nose_female.mp3'),
  PractiseWords(word: 'غسل الوجه', emoji: '🧼', imagePath: 'assets/images/PractiseImage/WuduImages/face_wudu.png', audioPath: 'assets/audios/tts_female/Wudu/face_female.mp3'),
  PractiseWords(word: 'غسل الذراعين', emoji: '💪', imagePath: 'assets/images/PractiseImage/WuduImages/arm_wudu.png', audioPath: 'assets/audios/tts_female/Wudu/arms_female.mp3'),
  PractiseWords(word: 'مسح الرأس', emoji: '🧴', imagePath: 'assets/images/PractiseImage/WuduImages/head_wudu.png', audioPath: 'assets/audios/tts_female/Wudu/head_female.mp3'),
  PractiseWords(word: 'مسح الأذنين', emoji: '👂', imagePath: 'assets/images/PractiseImage/WuduImages/ear_wudu.png', audioPath: 'assets/audios/tts_female/Wudu/ears_female.mp3'),
  PractiseWords(word: 'غسل الرجلين', emoji: '🦶', imagePath: 'assets/images/PractiseImage/WuduImages/feet_wudu.png', audioPath: 'assets/audios/tts_female/Wudu/feet_female.mp3'),
];

class _Activity {
  final String Function(BuildContext) title;
  final String image;
  final List<Color> colors;
  final Widget Function() game;
  const _Activity(this.title, this.image, this.colors, this.game);
}

final List<_Activity> _prayerActivities = [
  _Activity((c) => tr(c).wudu, 'assets/images/PractiseImage/WuduImages/hands_wudu.png',
      const [Color(0xFFD3F5E1), Color(0xFF6FD39A)], () => WuduGame()),
  _Activity((c) => tr(c).playTheWord, 'assets/images/PractiseImage/WuduImages/face_wudu.png',
      const [Color(0xFFD6ECFF), Color(0xFF7DB9FF)], () => PlayTheWord(words: _wuduSteps)),
  _Activity((c) => tr(c).chooseTheImage, 'assets/images/PractiseImage/WuduImages/feet_wudu.png',
      const [Color(0xFFFFE6C2), Color(0xFFFFB25C)], () => MatchWordToImage(words: _wuduSteps)),
];

enum RelCategory { all, listen, learn, practice }

class _Topic {
  final String id;
  final String Function(BuildContext) title, subtitle;
  final RelCategory category;
  final bool listenIcon; // green play vs orange chevron
  final int total; // 0 = coming soon
  const _Topic(this.id, this.title, this.subtitle, this.category, this.listenIcon, this.total);
  bool get available => total > 0;
}

List<_Topic> get _topics => [
      _Topic('quran', (c) => tr(c).relQuran, (c) => tr(c).relQuranSub, RelCategory.listen, true, _quranCount),
      _Topic('prayer', (c) => tr(c).relPrayer, (c) => tr(c).relPrayerSub, RelCategory.practice, false, _prayerActivities.length),
      _Topic('duas', (c) => tr(c).relDuas, (c) => tr(c).relDuasSub, RelCategory.listen, true, _duaas.length),
      _Topic('stories', (c) => tr(c).relStories, (c) => tr(c).relStoriesSub, RelCategory.learn, false,
          allStories.where((s) => s.available).length),
      _Topic('manners', (c) => tr(c).relManners, (c) => tr(c).relMannersSub, RelCategory.practice, false, manners.length),
      _Topic('basics', (c) => tr(c).relBasics, (c) => tr(c).relBasicsSub, RelCategory.learn, false, 0),
    ];

// ─── Shared audio helper ──────────────────────────────────────────────────

/// Plays one recitation at a time; tapping the same one again stops it.
mixin _Recitation<T extends StatefulWidget> on State<T> {
  late AudioManager audio;
  String? playingId;

  void bindAudio() => audio = Provider.of<AudioManager>(context, listen: false);

  Future<void> toggle(String id, String asset, Duration max, {VoidCallback? onStart}) async {
    if (playingId == id) {
      await audio.stopAlert();
      if (mounted) setState(() => playingId = null);
      return;
    }
    if (playingId != null) await audio.stopAlert();
    setState(() => playingId = id);
    onStart?.call();
    try {
      await audio.playAlert(asset).timeout(max, onTimeout: () {});
    } finally {
      if (mounted && playingId == id) setState(() => playingId = null);
    }
  }

  void stopRecitation() {
    if (playingId != null) audio.stopAlert();
  }
}

Widget _playIcon(bool playing, Animation<double> idle, double size) => AnimatedBuilder(
      animation: idle,
      builder: (_, c) => Transform.scale(scale: playing ? 1.0 + 0.06 * sin(idle.value * 24 * pi) : 1.0, child: c),
      child: Stack(alignment: Alignment.center, children: [
        Image.asset(ReligionAssets.play, width: size, height: size),
        if (playing)
          Container(
            width: size * 0.52,
            height: size * 0.52,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF14935C)),
            child: Icon(Icons.pause_rounded, color: Colors.white, size: size * 0.42),
          ),
      ]),
    );

void _soonSnack(BuildContext context, String what) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: _emeraldDeep,
    duration: const Duration(milliseconds: 1500),
    content: Text('$what · ${tr(context).comingSoon}', style: kidBodyStyle(15, color: Colors.white, weight: FontWeight.w600)),
  ));
}

Route _fade(Widget page) => PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      transitionDuration: const Duration(milliseconds: 320),
    );

// ═══════════════════════════════════════════════════════════════════════════
// Religion page
// ═══════════════════════════════════════════════════════════════════════════

class ReligionPage extends StatefulWidget {
  const ReligionPage({super.key});

  @override
  State<ReligionPage> createState() => _ReligionPageState();
}

class _ReligionPageState extends State<ReligionPage> with TickerProviderStateMixin, _Recitation<ReligionPage> {
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  late final AnimationController _idle =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();

  RelCategory _filter = RelCategory.all;
  LessonSnapshot _snap = LessonSnapshot.empty;
  bool _kindDone = false;
  bool _precached = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    bindAudio();
    if (!_precached) {
      _precached = true;
      KidAssets.precache(context, [...ReligionAssets.all, KidAssets.backBtn]);
      _intro.forward();
    }
  }

  @override
  void dispose() {
    stopRecitation();
    _intro.dispose();
    _idle.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final snap = await _tracker.load(_topics.map((t) => t.id));
    final kind = await _kindness.load(const []);
    if (mounted) {
      setState(() {
        _snap = snap;
        _kindDone = kind.claimedToday;
      });
    }
  }

  Future<void> _openTopic(_Topic t) async {
    if (!t.available) {
      audio.playEventSound('clickButton2');
      _soonSnack(context, t.title(context));
      return;
    }
    if (_busy) return;
    _busy = true;
    stopRecitation();
    setState(() => playingId = null);
    audio.playEventSound('clickButton');
    final page = switch (t.id) {
      'quran' => const QuranPage(),
      'stories' => const StoriesMenuPage(),
      'duas' => const DuasPage(),
      'manners' => const MannersPage(),
      _ => const PrayerPage(),
    };
    await Navigator.push(context, _fade(page));
    _busy = false;
    if (mounted) _refresh();
  }

  Future<void> _kindnessDone() async {
    if (_kindDone) return;
    await _kindness.record('kind', 0);
    if (!await _kindness.claimToday() || !mounted) return;
    Provider.of<ExperienceManager>(context, listen: false).addTokenBanner(context, LessonTracker.goalReward);
    audio.playSfx('assets/audios/UI_Audio/SFX_Audio/victory2_SFX.mp3');
    setState(() => _kindDone = true);
  }

  @override
  Widget build(BuildContext context) {
    final xp = Provider.of<ExperienceManager>(context);
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final w = min(size.width, 600.0) - 28;
    final s = (w / 380).clamp(0.8, 1.45);
    final cols = size.width >= 700 ? 3 : 2;
    final t = tr(context);
    final topics = _topics;
    final visible = _filter == RelCategory.all ? topics : topics.where((x) => x.category == _filter).toList();

    Widget step(int i, Widget child) =>
        KidIntro(intro: _intro, from: 0.06 * i, to: min(1.0, 0.42 + 0.06 * i), rise: 24, child: child);

    return Scaffold(
      backgroundColor: const Color(0xFF0E3B5C),
      body: Stack(children: [
        const Positioned.fill(child: KidPageBackground(asset: ReligionAssets.bg, wash: 0.05, alignment: Alignment.topCenter)),
        SafeArea(
          bottom: false,
          child: Center(
            child: SizedBox(
              width: w,
              child: Column(children: [
                const SizedBox(height: 6),
                step(0, KidPageHeader(scale: s, title: t.homeReligion, gold: xp.gold, gems: xp.gems)),
                SizedBox(height: 8 * s),
                Expanded(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: step(
                          1,
                          _Hero(
                            scale: s,
                            idle: _idle,
                            listened: min(_quranCount, _snap.done['quran'] ?? 0),
                            playing: playingId == 'fatiha',
                            onPlay: () => toggle('fatiha', ReligionAssets.fatihaAudio, const Duration(seconds: 70),
                                onStart: () async {
                              await _tracker.record('quran', 0);
                              _refresh();
                            }),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(child: SizedBox(height: 12 * s)),
                      SliverToBoxAdapter(
                        child: step(
                          2,
                          _Chips(
                            scale: s,
                            value: _filter,
                            onChanged: (v) {
                              if (v == _filter) return;
                              audio.playEventSound('clickButton2');
                              setState(() => _filter = v);
                            },
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(child: SizedBox(height: 12 * s)),
                      SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          mainAxisSpacing: 12 * s,
                          crossAxisSpacing: 12 * s,
                          childAspectRatio: 1.08,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final tp = visible[i];
                            return step(
                              3 + min(i, 6),
                              _TopicCard(
                                key: ValueKey('${_filter.name}-${tp.id}'),
                                scale: s,
                                topic: tp,
                                done: min(tp.total, _snap.done[tp.id] ?? 0),
                                idle: _idle,
                                phase: i * 0.13,
                                onTap: () => _openTopic(tp),
                              ),
                            );
                          },
                          childCount: visible.length,
                        ),
                      ),
                      SliverToBoxAdapter(child: SizedBox(height: 92 * s + pad.bottom)),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: pad.bottom + 10,
          child: Center(
            child: SizedBox(
              width: w,
              child: KidIntro(
                intro: _intro,
                from: 0.5,
                to: 1.0,
                rise: 40,
                child: _KindnessCard(scale: s, idle: _idle, done: _kindDone, onDone: _kindnessDone),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

TextStyle _heroWord(Color c, double size) => TextStyle(
      fontFamily: 'Fredoka',
      fontWeight: FontWeight.w700,
      fontSize: size,
      height: 1.0,
      color: c,
      shadows: const [
        Shadow(color: Color(0xFF0B3B2A), offset: Offset(0, 2.5)),
        Shadow(color: Color(0x88000000), blurRadius: 6, offset: Offset(0, 3)),
      ],
    );

class _Hero extends StatelessWidget {
  final double scale;
  final Animation<double> idle;
  final int listened;
  final bool playing;
  final VoidCallback onPlay;
  const _Hero({required this.scale, required this.idle, required this.listened, required this.playing, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final t = tr(context);
    final h = 176 * s;
    final r = 26 * s;
    return Container(
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: const Color(0xFFFFF3D0), width: 3),
        boxShadow: [BoxShadow(color: _emeraldDeep.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r - 3),
        child: Stack(children: [
          Positioned.fill(child: Image.asset(ReligionAssets.heroBg, fit: BoxFit.cover, alignment: Alignment.centerLeft)),
          // Quran on its stand
          PositionedDirectional(
            start: 2 * s,
            bottom: -2 * s,
            child: AnimatedBuilder(
              animation: idle,
              builder: (_, c) => Transform.translate(offset: Offset(0, sin(idle.value * 4 * pi) * 2.5 * s), child: c),
              child: Image.asset(ReligionAssets.quranStand, width: 118 * s, height: 118 * s * 0.8235),
            ),
          ),
          // Headline
          PositionedDirectional(
            end: 12 * s,
            top: 10 * s,
            width: 200 * s,
            height: 86 * s,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerEnd,
              child: Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                Text(t.relHeroTop, style: _heroWord(Colors.white, 26 * s)),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  ShaderMask(
                    shaderCallback: (b) =>
                        const LinearGradient(colors: [Color(0xFFFFF09A), Color(0xFFFFC21A)]).createShader(b),
                    child: Text(t.relHeroBottom, style: _heroWord(Colors.white, 36 * s)),
                  ),
                  SizedBox(width: 4 * s),
                  AnimatedBuilder(
                    animation: idle,
                    builder: (_, c) => Transform.scale(scale: 1 + 0.08 * sin(idle.value * 16 * pi).abs(), child: c),
                    child: Image.asset(ReligionAssets.heart, width: 26 * s, height: 26 * s * 0.9286),
                  ),
                ]),
                SizedBox(height: 4 * s),
                Text(t.relHeroSub,
                    style: kidBodyStyle(12 * s, color: Colors.white, weight: FontWeight.w600)
                        .copyWith(shadows: const [Shadow(color: Color(0xCC0B3B2A), blurRadius: 4)])),
              ]),
            ),
          ),
          // Continue listening strip
          PositionedDirectional(
            start: 120 * s,
            end: 10 * s,
            bottom: 10 * s,
            height: 60 * s,
            child: Container(
              padding: EdgeInsetsDirectional.only(start: 12 * s, end: 4 * s),
              decoration: BoxDecoration(color: kidCardCream.withOpacity(0.97), borderRadius: BorderRadius.circular(20 * s)),
              child: Row(children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(listened > 0 ? t.continueListening : t.startListening,
                            style: kidBodyStyle(14 * s, color: _ink, weight: FontWeight.w700)),
                      ),
                      Text(t.surahFatiha, style: kidBodyStyle(11.5 * s, color: KidColors.muted, weight: FontWeight.w600)),
                      SizedBox(height: 4 * s),
                      _GreenBar(value: listened / _quranCount, height: 7 * s),
                    ],
                  ),
                ),
                SizedBox(width: 8 * s),
                KidPressable(onTap: onPlay, semanticLabel: t.tapToListen, child: _playIcon(playing, idle, 50 * s)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
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
            const Positioned.fill(child: ColoredBox(color: Color(0xFFDAD7DE))),
            AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              widthFactor: value.clamp(0.0, 1.0),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Color(0xFF34C985), Color(0xFF13915A)])),
              ),
            ),
          ]),
        ),
      );
}

class _Chips extends StatelessWidget {
  final double scale;
  final RelCategory value;
  final ValueChanged<RelCategory> onChanged;
  const _Chips({required this.scale, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final t = tr(context);
    final labels = {
      RelCategory.all: t.filterAll,
      RelCategory.listen: t.relListen,
      RelCategory.learn: t.relLearn,
      RelCategory.practice: t.practiseTitle,
    };
    return Row(children: [
      for (final c in RelCategory.values) ...[
        if (c != RelCategory.all) SizedBox(width: 7 * s),
        Expanded(
          child: KidPressable(
            onTap: () => onChanged(c),
            pressedScale: 0.94,
            semanticLabel: labels[c],
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              height: 38 * s,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: 6 * s),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                gradient: c == value
                    ? const LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2CB574), _emerald])
                    : null,
                color: c == value ? null : KidColors.cream,
                border: Border.all(color: c == value ? const Color(0xFFBDEFD2) : Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                      color: _emeraldDeep.withOpacity(c == value ? 0.35 : 0.12),
                      blurRadius: c == value ? 10 : 6,
                      offset: const Offset(0, 3)),
                ],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(labels[c]!,
                    maxLines: 1,
                    style: kidBodyStyle(15 * s, color: c == value ? Colors.white : _ink, weight: FontWeight.w700)),
              ),
            ),
          ),
        ),
      ],
    ]);
  }
}

class _TopicCard extends StatelessWidget {
  final double scale;
  final _Topic topic;
  final int done;
  final Animation<double> idle;
  final double phase;
  final VoidCallback onTap;
  const _TopicCard({super.key, required this.scale, required this.topic, required this.done, required this.idle,
      required this.phase, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final t = tr(context);
    final r = 22 * s;
    final ok = topic.available;
    final title = topic.title(context);
    return KidPressable(
      onTap: onTap,
      pressedScale: 0.95,
      semanticLabel: title,
      child: Container(
        decoration: kidCardDecoration(r),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(r - 3),
          child: Column(children: [
            Expanded(
              child: Stack(fit: StackFit.expand, children: [
                Image.asset(ReligionAssets.tile(topic.id), fit: BoxFit.cover, filterQuality: FilterQuality.medium),
                if (!ok) ...[
                  ColoredBox(color: Colors.white.withOpacity(0.3)),
                  PositionedDirectional(
                    top: 8 * s,
                    end: 8 * s,
                    child: AnimatedBuilder(
                      animation: idle,
                      builder: (_, c) => Transform.rotate(angle: sin((idle.value * 4 + phase) * 2 * pi) * 0.06, child: c),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 4 * s),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(colors: [Color(0xFF2CB574), _emeraldDeep]),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(t.soonBadge, style: kidBodyStyle(12 * s, color: Colors.white, weight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
                if (ok && done > 0)
                  PositionedDirectional(
                    top: 7 * s,
                    start: 7 * s,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 3 * s),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(20)),
                      child: Text('$done / ${topic.total}',
                          style: kidBodyStyle(11.5 * s, color: _emeraldDeep, weight: FontWeight.w700)),
                    ),
                  ),
              ]),
            ),
            Container(
              height: 58 * s,
              color: kidCardCream,
              padding: EdgeInsetsDirectional.only(start: 10 * s, end: 7 * s),
              child: Row(children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(title, maxLines: 1, style: kidTitleStyle(19 * s, color: _ink).copyWith(shadows: const [])),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(ok ? topic.subtitle(context) : t.comingSoon,
                            maxLines: 1, style: kidBodyStyle(11.5 * s, color: KidColors.muted, weight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 4 * s),
                Opacity(
                  opacity: ok ? 1 : 0.45,
                  child: Transform.flip(
                    flipX: Directionality.of(context) == TextDirection.rtl,
                    child: Image.asset(topic.listenIcon ? ReligionAssets.play : ReligionAssets.goOrange,
                        width: 42 * s, height: 42 * s),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _KindnessCard extends StatelessWidget {
  final double scale;
  final Animation<double> idle;
  final bool done;
  final VoidCallback onDone;
  const _KindnessCard({required this.scale, required this.idle, required this.done, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final t = tr(context);
    return KidPressable(
      onTap: done ? null : onDone,
      pressedScale: 0.97,
      semanticLabel: t.kindnessTitle,
      child: Container(
        height: 74 * s,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40 * s),
          boxShadow: [BoxShadow(color: _emeraldDeep.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Stack(children: [
          Positioned.fill(child: Image.asset(ReligionAssets.ornamentBar, fit: BoxFit.fill)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 34 * s),
            child: Row(children: [
              Image.asset(ReligionAssets.leaves, width: 26 * s, height: 28 * s),
              AnimatedBuilder(
                animation: idle,
                builder: (_, c) => Transform.scale(scale: 1 + 0.1 * sin(idle.value * 16 * pi).abs(), child: c),
                child: Image.asset(ReligionAssets.heart, width: 34 * s, height: 34 * s * 0.9286),
              ),
              SizedBox(width: 10 * s),
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(t.kindnessTitle, style: kidBodyStyle(17 * s, color: _ink, weight: FontWeight.w700)),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(done ? t.kindnessDone : t.kindnessMsg,
                        style: kidBodyStyle(12 * s, color: _emeraldDeep, weight: FontWeight.w600)),
                  ),
                ]),
              ),
              SizedBox(width: 8 * s),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                child: done
                    ? Icon(Icons.check_circle_rounded, key: const ValueKey('ok'), color: _emerald, size: 32 * s)
                    : Container(
                        key: const ValueKey('btn'),
                        padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 6 * s),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: const LinearGradient(colors: [Color(0xFF2CB574), _emerald]),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Image.asset(kidCoinAsset, width: 18 * s, height: 18 * s),
                          SizedBox(width: 3 * s),
                          Text('+${LessonTracker.goalReward}',
                              style: kidBodyStyle(13 * s, color: Colors.white, weight: FontWeight.w700)),
                        ]),
                      ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Topic pages
// ═══════════════════════════════════════════════════════════════════════════

/// Common frame: header, topic art banner with progress, then [children].
class _TopicScaffold extends StatelessWidget {
  final String title, art;
  final int done, total;
  final Animation<double> intro;
  final List<Widget> children;
  const _TopicScaffold(
      {required this.title, required this.art, required this.done, required this.total, required this.intro, required this.children});

  @override
  Widget build(BuildContext context) {
    final xp = Provider.of<ExperienceManager>(context);
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final w = min(size.width, 600.0) - 28;
    final s = (w / 380).clamp(0.8, 1.45);
    final t = tr(context);
    Widget step(int i, Widget child) =>
        KidIntro(intro: intro, from: 0.07 * i, to: min(1.0, 0.45 + 0.07 * i), rise: 22, child: child);
    return Scaffold(
      backgroundColor: const Color(0xFF0E3B5C),
      body: Stack(children: [
        const Positioned.fill(child: KidPageBackground(asset: ReligionAssets.bg, wash: 0.05, alignment: Alignment.topCenter)),
        SafeArea(
          bottom: false,
          child: Center(
            child: SizedBox(
              width: w,
              child: Column(children: [
                const SizedBox(height: 6),
                step(0, KidPageHeader(scale: s, title: title, gold: xp.gold, gems: xp.gems)),
                SizedBox(height: 10 * s),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(bottom: pad.bottom + 20),
                    children: [
                      step(
                        1,
                        Container(
                          decoration: kidCardDecoration(24 * s, shadow: 0.3),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24 * s - 3),
                            child: Column(children: [
                              AspectRatio(aspectRatio: 2.2, child: Image.asset(art, fit: BoxFit.cover)),
                              Padding(
                                padding: EdgeInsets.fromLTRB(14 * s, 10 * s, 14 * s, 12 * s),
                                child: Row(children: [
                                  Expanded(child: _GreenBar(value: total == 0 ? 0 : done / total, height: 10 * s)),
                                  SizedBox(width: 10 * s),
                                  Text('$done / $total', style: kidBodyStyle(13 * s, color: _ink, weight: FontWeight.w700)),
                                  SizedBox(width: 4 * s),
                                  Text(t.relDone, style: kidBodyStyle(12 * s, color: KidColors.muted, weight: FontWeight.w600)),
                                ]),
                              ),
                            ]),
                          ),
                        ),
                      ),
                      SizedBox(height: 14 * s),
                      for (int i = 0; i < children.length; i++) ...[
                        step(2 + min(i, 6), children[i]),
                        SizedBox(height: 10 * s),
                      ],
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

double _scaleOf(BuildContext context) => ((min(MediaQuery.sizeOf(context).width, 600.0) - 28) / 380).clamp(0.8, 1.45);

// ─── Daily duas ───────────────────────────────────────────────────────────

class DuasPage extends StatefulWidget {
  const DuasPage({super.key});
  @override
  State<DuasPage> createState() => _DuasPageState();
}

class _DuasPageState extends State<DuasPage> with TickerProviderStateMixin {
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();
  Set<int> _done = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final d = await _tracker.doneIn('duas');
    if (mounted) setState(() => _done = d);
  }

  Future<void> _ameen(int i) async {
    Provider.of<AudioManager>(context, listen: false).playEventSound('clickButton2');
    await _tracker.record('duas', i);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = _scaleOf(context);
    final t = tr(context);
    final hour = DateTime.now().hour;
    return _TopicScaffold(
      title: t.relDuas,
      art: ReligionAssets.tile('duas'),
      done: _done.where((i) => i < _duaas.length).length,
      total: _duaas.length,
      intro: _intro,
      children: [
        for (int i = 0; i < _duaas.length; i++)
          Container(
            padding: EdgeInsets.fromLTRB(12 * s, 12 * s, 12 * s, 12 * s),
            decoration: kidCardDecoration(22 * s, shadow: 0.25).copyWith(
              border: Border.all(color: _duaas[i].isNow(hour) ? _gold : Colors.white, width: 3),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 50 * s,
                  height: 50 * s,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: _duaas[i].colors),
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                  child: Text(_duaas[i].emoji, style: TextStyle(fontSize: 24 * s)),
                ),
                SizedBox(width: 10 * s),
                Expanded(
                  child: Text(_duaas[i].label(context),
                      style: kidBodyStyle(17 * s, color: _ink, weight: FontWeight.w700)),
                ),
                if (_duaas[i].isNow(hour))
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 3 * s),
                    decoration: BoxDecoration(color: const Color(0xFFFFF1C2), borderRadius: BorderRadius.circular(20)),
                    child: Text(t.nowLabel, style: kidBodyStyle(12 * s, color: const Color(0xFF9A5B00), weight: FontWeight.w700)),
                  ),
              ]),
              SizedBox(height: 10 * s),
              SizedBox(
                width: double.infinity,
                child: Text(_duaas[i].text,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20 * s, height: 1.7, color: _emeraldDeep, fontWeight: FontWeight.w600)),
              ),
              SizedBox(height: 10 * s),
              Center(
                child: KidPressable(
                  onTap: _done.contains(i) ? null : () => _ameen(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: EdgeInsets.symmetric(horizontal: 22 * s, vertical: 9 * s),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: _done.contains(i)
                          ? null
                          : const LinearGradient(
                              begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2CB574), _emerald]),
                      color: _done.contains(i) ? const Color(0xFFE0F5E8) : null,
                    ),
                    child: Text(_done.contains(i) ? '✓  ${t.ameen}' : '🤲  ${t.ameen}',
                        style: kidBodyStyle(16 * s,
                            color: _done.contains(i) ? _emerald : Colors.white, weight: FontWeight.w700)),
                  ),
                ),
              ),
            ]),
          ),
      ],
    );
  }
}

// ─── Prayer (wudu practice) ───────────────────────────────────────────────

class PrayerPage extends StatefulWidget {
  const PrayerPage({super.key});
  @override
  State<PrayerPage> createState() => _PrayerPageState();
}

class _PrayerPageState extends State<PrayerPage> with TickerProviderStateMixin {
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();
  late final AnimationController _idle =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  Set<int> _done = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _intro.dispose();
    _idle.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final d = await _tracker.doneIn('prayer');
    if (mounted) setState(() => _done = d);
  }

  Future<void> _open(int i) async {
    if (_busy) return;
    _busy = true;
    Provider.of<AudioManager>(context, listen: false).playEventSound('PopButton');
    await _tracker.record('prayer', i);
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (ctx) => GetReadyPage(
        onReadyComplete: () => Navigator.of(ctx).pushReplacement(
          MaterialPageRoute(builder: (_) => _prayerActivities[i].game()),
        ),
      ),
    ));
    _busy = false;
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = _scaleOf(context);
    final t = tr(context);
    return _TopicScaffold(
      title: t.relPrayer,
      art: ReligionAssets.tile('prayer'),
      done: _done.where((i) => i < _prayerActivities.length).length,
      total: _prayerActivities.length,
      intro: _intro,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(start: 6 * s),
          child: Text(t.wuduFirstStep,
              style: kidBodyStyle(15 * s, color: Colors.white, weight: FontWeight.w700)
                  .copyWith(shadows: const [Shadow(color: Color(0xCC0B3B2A), blurRadius: 6)])),
        ),
        for (int i = 0; i < _prayerActivities.length; i++)
          KidPressable(
            onTap: () => _open(i),
            pressedScale: 0.96,
            semanticLabel: _prayerActivities[i].title(context),
            child: Container(
              height: 84 * s,
              padding: EdgeInsetsDirectional.only(start: 8 * s, end: 10 * s),
              decoration: kidCardDecoration(22 * s, shadow: 0.25),
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16 * s),
                  child: SizedBox(
                    width: 68 * s,
                    height: 68 * s,
                    child: KidIconArt(
                        image: _prayerActivities[i].image,
                        colors: _prayerActivities[i].colors,
                        idle: _idle,
                        phase: i * 0.2,
                        scale: s * 0.6),
                  ),
                ),
                SizedBox(width: 12 * s),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.lessonN(i + 1), style: kidBodyStyle(12 * s, color: _emerald, weight: FontWeight.w700)),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(_prayerActivities[i].title(context),
                            maxLines: 1, style: kidBodyStyle(18 * s, color: _ink, weight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                if (_done.contains(i)) ...[
                  Icon(Icons.check_circle_rounded, color: _emerald, size: 26 * s),
                  SizedBox(width: 6 * s),
                ],
                Transform.flip(
                  flipX: Directionality.of(context) == TextDirection.rtl,
                  child: Image.asset(ReligionAssets.goOrange, width: 44 * s, height: 44 * s),
                ),
              ]),
            ),
          ),
      ],
    );
  }
}
