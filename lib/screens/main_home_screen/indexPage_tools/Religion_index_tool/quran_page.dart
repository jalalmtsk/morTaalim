import 'dart:async';
import 'dart:math';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:just_audio/just_audio.dart';
import 'package:mortaalim/Manager/lesson_progress.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/KidScene/kid_page_parts.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:mortaalim/widgets/RandomAyat_Card/Ayat_List.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuranAssets {
  QuranAssets._();
  static const String dir = 'assets/images/UI/KidScene/';
  static const String pageBg = '${dir}religion_bg.webp';
  static const String heroBg = '${dir}quran_hero_bg.webp';
  static const String stand = '${dir}quran_stand.webp';
  static const String book = '${dir}quran_book.webp';
  static const String playBig = '${dir}quran_play_big.webp';
  static const String play = '${dir}quran_play.webp';
  static const String repeat = '${dir}quran_repeat.webp';
  static const String heart = '${dir}quran_heart.webp';
  static const String heartFull = '${dir}quran_heart_full.webp';
  static const String search = '${dir}quran_search.webp';
  static const String sparkle = '${dir}quran_sparkle.webp';
  static const String icListen = '${dir}quran_ic_listen.webp';
  static const String icRepeat = '${dir}quran_ic_repeat.webp';
  static const String icMemorize = '${dir}quran_ic_memorize.webp';
  static const String icSound = '${dir}quran_ic_sound.webp';

  static const all = [
    pageBg, heroBg, stand, book, playBig, play, repeat, heart, heartFull, search, sparkle, icListen, icRepeat, icMemorize, icSound,
  ];
}

const String _bismillah = 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ';
const String _audioDir = 'assets/audios/quranSourate/';

/// One thing to listen to: a short surah or a single verse.
class QuranItem {
  final String id, name, arabic;
  final String audio; // asset path; the play button turns on as soon as the file exists
  final List<String> ayat;
  final bool bismillahHeader; // show the basmala above (not counted as a verse)
  final bool isVerse;
  const QuranItem(this.id, this.name, this.arabic, this.audio, this.ayat, {this.bismillahHeader = true, this.isVerse = false});
}

const List<QuranItem> _surahs = [
  QuranItem('fatiha', 'Al-Fatiha', 'الفاتحة', '${_audioDir}fatiha.mp3', [
    'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
    'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
    'الرَّحْمَنِ الرَّحِيمِ',
    'مَالِكِ يَوْمِ الدِّينِ',
    'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ',
    'اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ',
    'صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ',
  ], bismillahHeader: false),
  QuranItem('ikhlas', 'Al-Ikhlas', 'الإخلاص', '${_audioDir}ikhlas.mp3', [
    'قُلْ هُوَ اللَّهُ أَحَدٌ',
    'اللَّهُ الصَّمَدُ',
    'لَمْ يَلِدْ وَلَمْ يُولَدْ',
    'وَلَمْ يَكُنْ لَهُ كُفُوًا أَحَدٌ',
  ]),
  QuranItem('falaq', 'Al-Falaq', 'الفلق', '${_audioDir}falaq.mp3', [
    'قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ',
    'مِنْ شَرِّ مَا خَلَقَ',
    'وَمِنْ شَرِّ غَاسِقٍ إِذَا وَقَبَ',
    'وَمِنْ شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ',
    'وَمِنْ شَرِّ حَاسِدٍ إِذَا حَسَدَ',
  ]),
  QuranItem('nas', 'An-Nas', 'الناس', '${_audioDir}nas.mp3', [
    'قُلْ أَعُوذُ بِرَبِّ النَّاسِ',
    'مَلِكِ النَّاسِ',
    'إِلَهِ النَّاسِ',
    'مِنْ شَرِّ الْوَسْوَاسِ الْخَنَّاسِ',
    'الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ',
    'مِنَ الْجِنَّةِ وَالنَّاسِ',
  ]),
  QuranItem('kawthar', 'Al-Kawthar', 'الكوثر', '${_audioDir}kawthar.mp3', [
    'إِنَّا أَعْطَيْنَاكَ الْكَوْثَرَ',
    'فَصَلِّ لِرَبِّكَ وَانْحَرْ',
    'إِنَّ شَانِئَكَ هُوَ الْأَبْتَرُ',
  ]),
];

/// Surahs first, then the single verses already in the app.
final List<QuranItem> quranItems = [
  ..._surahs,
  for (int i = 0; i < ayatList.length; i++)
    QuranItem('verse$i', ayatList[i]['surah']!, ayatList[i]['surah']!, ayatList[i]['audio']!, [ayatList[i]['text']!],
        bismillahHeader: false, isVerse: true),
];

int get quranItemCount => quranItems.length;

const LessonTracker _tracker = LessonTracker('religion');
const _ink = KidColors.ink;
const _emerald = Color(0xFF13915A);
const _emeraldDeep = Color(0xFF075238);

enum QuranMode { listen, repeat, memorize }

String _mmss(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

class QuranPage extends StatefulWidget {
  const QuranPage({super.key});

  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> with TickerProviderStateMixin {
  static const _kFavs = 'quran_favs';
  static const _kLast = 'quran_last';
  static const _kLastPos = 'quran_last_pos';

  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));
  late final AnimationController _idle =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  final AudioPlayer _player = AudioPlayer();
  late AudioManager _audio;
  StreamSubscription<PlayerState>? _stateSub;

  Set<String> _available = {}; // items whose audio file exists
  Set<String> _favs = {};
  Set<int> _done = {};
  int _current = 0;
  int? _loaded; // item loaded in the player
  bool _playing = false;
  bool _favTab = false;
  QuranMode _mode = QuranMode.listen;
  String _query = '';
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    _stateSub = _player.playerStateStream.listen((s) {
      final playing = s.playing && s.processingState != ProcessingState.completed;
      if (s.processingState == ProcessingState.completed && _mode != QuranMode.repeat) {
        _player.pause();
        _player.seek(Duration.zero);
      }
      if (mounted && playing != _playing) setState(() => _playing = playing);
    });
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audio = Provider.of<AudioManager>(context, listen: false);
    if (!_precached) {
      _precached = true;
      KidAssets.precache(context, [...QuranAssets.all, KidAssets.backBtn]);
      _intro.forward();
    }
  }

  Future<void> _load() async {
    final avail = <String>{};
    for (final it in quranItems) {
      try {
        await rootBundle.load(it.audio);
        avail.add(it.id);
      } catch (_) {}
    }
    final p = await SharedPreferences.getInstance();
    final done = await _tracker.doneIn('quran');
    final last = (p.getInt(_kLast) ?? 0).clamp(0, quranItems.length - 1);
    if (!mounted) return;
    setState(() {
      _available = avail;
      _favs = (p.getStringList(_kFavs) ?? const []).toSet();
      _done = done;
      _current = avail.contains(quranItems[last].id) ? last : 0;
    });
    // Prepare the last item so the progress bar shows where the child stopped.
    if (_available.contains(quranItems[_current].id)) {
      await _prepare(_current, Duration(milliseconds: p.getInt(_kLastPos) ?? 0));
    }
  }

  Future<void> _prepare(int i, [Duration at = Duration.zero]) async {
    try {
      await _player.setAudioSource(AudioSource.asset(quranItems[i].audio));
      await _player.setLoopMode(_mode == QuranMode.repeat ? LoopMode.one : LoopMode.off);
      final d = _player.duration;
      if (at > Duration.zero && d != null && at < d) await _player.seek(at);
      _loaded = i;
    } catch (_) {
      _loaded = null;
    }
  }

  Future<void> _savePosition() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kLast, _current);
    await p.setInt(_kLastPos, _player.position.inMilliseconds);
  }

  @override
  void dispose() {
    _savePosition();
    _stateSub?.cancel();
    _player.dispose();
    _intro.dispose();
    _idle.dispose();
    super.dispose();
  }

  Future<void> _togglePlay([int? index]) async {
    final i = index ?? _current;
    final item = quranItems[i];
    if (!_available.contains(item.id)) {
      _audio.playEventSound('clickButton2');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _emeraldDeep,
        duration: const Duration(milliseconds: 1600),
        content: Text('${item.name} · ${tr(context).audioSoon}',
            style: kidBodyStyle(15, color: Colors.white, weight: FontWeight.w600)),
      ));
      _openReader(i);
      return;
    }
    if (i == _current && _loaded == i && _playing) {
      await _player.pause();
      _savePosition();
      return;
    }
    await _audio.stopAlert();
    if (_loaded != i) {
      setState(() => _current = i);
      await _prepare(i);
    }
    _player.play();
    await _tracker.record('quran', i);
    final d = await _tracker.doneIn('quran');
    if (mounted) setState(() => _done = d);
    _savePosition();
  }

  Future<void> _setMode(QuranMode m) async {
    _audio.playEventSound('clickButton2');
    if (m == QuranMode.memorize) {
      _openReader(_current, memorize: true);
      return;
    }
    setState(() => _mode = m);
    await _player.setLoopMode(m == QuranMode.repeat ? LoopMode.one : LoopMode.off);
  }

  Future<void> _toggleFav(String id) async {
    _audio.playEventSound('clickButton2');
    setState(() => _favs.contains(id) ? _favs.remove(id) : _favs.add(id));
    (await SharedPreferences.getInstance()).setStringList(_kFavs, _favs.toList());
  }

  void _openReader(int i, {bool memorize = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReaderSheet(
        item: quranItems[i],
        memorize: memorize,
        player: _loaded == i ? _player : null,
        canPlay: _available.contains(quranItems[i].id),
        onPlay: () => _togglePlay(i),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audio = Provider.of<AudioManager>(context);
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final w = min(size.width, 600.0) - 28;
    final s = (w / 380).clamp(0.8, 1.45);
    final t = tr(context);
    final q = _query.trim().toLowerCase();
    bool match(QuranItem it) => q.isEmpty || it.name.toLowerCase().contains(q) || it.arabic.contains(q);
    final visible = <int>[
      for (int i = 0; i < quranItems.length; i++)
        if (match(quranItems[i]) && (!_favTab || _favs.contains(quranItems[i].id))) i,
    ];
    final surahRows = visible.where((i) => !quranItems[i].isVerse).toList();
    final verseRows = visible.where((i) => quranItems[i].isVerse).toList();

    Widget step(int i, Widget child) =>
        KidIntro(intro: _intro, from: 0.06 * i, to: min(1.0, 0.42 + 0.06 * i), rise: 22, child: child);

    Widget row(int i, int n) => _ItemRow(
          scale: s,
          number: n,
          item: quranItems[i],
          fav: _favs.contains(quranItems[i].id),
          done: _done.contains(i),
          hasAudio: _available.contains(quranItems[i].id),
          playing: _playing && _current == i,
          idle: _idle,
          onOpen: () => _openReader(i),
          onFav: () => _toggleFav(quranItems[i].id),
          onPlay: () => _togglePlay(i),
        );

    return Scaffold(
      backgroundColor: const Color(0xFF0E3B5C),
      body: Stack(children: [
        const Positioned.fill(child: KidPageBackground(asset: QuranAssets.pageBg, wash: 0.08, alignment: Alignment.topCenter)),
        SafeArea(
          bottom: false,
          child: Center(
            child: SizedBox(
              width: w,
              child: Column(children: [
                const SizedBox(height: 6),
                step(
                  0,
                  _TitleBar(
                    scale: s,
                    title: t.relQuran,
                    musicMuted: audio.isBgMuted,
                    onSound: () {
                      audio.playEventSound('toggleButton');
                      audio.toggleBgMute();
                    },
                  ),
                ),
                SizedBox(height: 10 * s),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(bottom: 96 * s + pad.bottom),
                    children: [
                      step(1, _Hero(scale: s, idle: _idle)),
                      SizedBox(height: 12 * s),
                      step(
                        2,
                        _NowPlaying(
                          scale: s,
                          item: quranItems[_current],
                          player: _player,
                          ready: _loaded == _current,
                          playing: _playing,
                          repeat: _mode == QuranMode.repeat,
                          started: _done.contains(_current),
                          idle: _idle,
                          onPlay: () => _togglePlay(),
                          onRepeat: () => _setMode(_mode == QuranMode.repeat ? QuranMode.listen : QuranMode.repeat),
                        ),
                      ),
                      SizedBox(height: 12 * s),
                      step(3, _Tabs(scale: s, favorites: _favTab, onChanged: (v) {
                        if (v == _favTab) return;
                        _audio.playEventSound('clickButton2');
                        setState(() => _favTab = v);
                      })),
                      SizedBox(height: 10 * s),
                      step(4, _SearchField(scale: s, onChanged: (v) => setState(() => _query = v))),
                      SizedBox(height: 10 * s),
                      if (visible.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 24 * s),
                          child: Center(
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 10 * s),
                              decoration: kidCardDecoration(20 * s),
                              child: Text(_favTab && q.isEmpty ? t.noFavorites : t.noResults,
                                  textAlign: TextAlign.center,
                                  style: kidBodyStyle(15 * s, color: KidColors.inkSoft, weight: FontWeight.w600)),
                            ),
                          ),
                        ),
                      for (int k = 0; k < surahRows.length; k++) ...[
                        step(5 + min(k, 5), row(surahRows[k], surahRows[k] + 1)),
                        SizedBox(height: 10 * s),
                      ],
                      if (verseRows.isNotEmpty) ...[
                        Padding(
                          padding: EdgeInsetsDirectional.only(start: 8 * s, top: 6 * s, bottom: 8 * s),
                          child: Text(t.versesTitle,
                              style: kidTitleStyle(22 * s, color: Colors.white).copyWith(shadows: const [
                                Shadow(color: Color(0xCC0B3B2A), blurRadius: 8, offset: Offset(0, 2)),
                              ])),
                        ),
                        for (final i in verseRows) ...[
                          row(i, i - _surahs.length + 1),
                          SizedBox(height: 10 * s),
                        ],
                      ],
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
                child: _ModeBar(scale: s, mode: _mode, onChanged: _setMode),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Pieces
// ═══════════════════════════════════════════════════════════════════════════

TextStyle _heroWord(Color c, double size) => TextStyle(
      fontFamily: 'Fredoka',
      fontWeight: FontWeight.w700,
      fontSize: size,
      height: 1.05,
      color: c,
      shadows: const [
        Shadow(color: Color(0xFF0B3B2A), offset: Offset(0, 2.5)),
        Shadow(color: Color(0x88000000), blurRadius: 6, offset: Offset(0, 3)),
      ],
    );

Widget _fit(String text, TextStyle style, {AlignmentGeometry align = AlignmentDirectional.centerStart}) => FittedBox(
      fit: BoxFit.scaleDown,
      alignment: align,
      child: Text(text, maxLines: 1, softWrap: false, style: style),
    );

class _TitleBar extends StatelessWidget {
  final double scale;
  final String title;
  final bool musicMuted;
  final VoidCallback onSound;
  const _TitleBar({required this.scale, required this.title, required this.musicMuted, required this.onSound});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      height: 70 * s,
      padding: EdgeInsets.symmetric(horizontal: 10 * s),
      decoration: BoxDecoration(
        color: KidColors.cream,
        borderRadius: BorderRadius.circular(40 * s),
        border: Border.all(color: const Color(0xFFFFD98A), width: 2.5),
        boxShadow: [BoxShadow(color: KidColors.purpleDeep.withOpacity(0.18), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        KidBackButton(
          size: 48 * s,
          onTap: () {
            Provider.of<AudioManager>(context, listen: false).playEventSound('cancelButton');
            Navigator.of(context).maybePop();
          },
        ),
        Expanded(child: _fit(title, kidTitleStyle(34 * s).copyWith(shadows: const []), align: Alignment.center)),
        KidPressable(
          onTap: onSound,
          semanticLabel: tr(context).backgroundMusic,
          child: Stack(alignment: Alignment.center, children: [
            Opacity(opacity: musicMuted ? 0.45 : 1, child: Image.asset(QuranAssets.icSound, width: 48 * s, height: 48 * s * 0.9677)),
            if (musicMuted)
              Transform.rotate(
                angle: -0.8,
                child: Container(width: 40 * s, height: 4 * s, decoration: BoxDecoration(color: const Color(0xFFE11D48), borderRadius: BorderRadius.circular(4))),
              ),
          ]),
        ),
      ]),
    );
  }
}

class _Hero extends StatelessWidget {
  final double scale;
  final Animation<double> idle;
  const _Hero({required this.scale, required this.idle});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final t = tr(context);
    final r = 26 * s;
    return AspectRatio(
      aspectRatio: 2.3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(r),
          border: Border.all(color: const Color(0xFFFFF3D0), width: 3),
          boxShadow: [BoxShadow(color: _emeraldDeep.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(r - 3),
          child: LayoutBuilder(builder: (context, c) {
            final w = c.maxWidth, h = c.maxHeight;
            final standW = w * 0.4;
            return Stack(children: [
              Positioned.fill(child: Image.asset(QuranAssets.heroBg, fit: BoxFit.cover, alignment: Alignment.centerRight)),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.centerStart,
                      end: AlignmentDirectional.centerEnd,
                      colors: [_emeraldDeep.withOpacity(0.55), Colors.transparent],
                      stops: const [0.25, 0.65],
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                end: w * 0.04,
                bottom: -h * 0.02,
                child: AnimatedBuilder(
                  animation: idle,
                  builder: (_, ch) => Transform.translate(offset: Offset(0, sin(idle.value * 4 * pi) * 2.5 * s), child: ch),
                  child: Image.asset(QuranAssets.stand, width: standW, height: standW * 0.9184),
                ),
              ),
              PositionedDirectional(
                end: w * 0.36,
                top: h * 0.16,
                child: AnimatedBuilder(
                  animation: idle,
                  builder: (_, ch) => Opacity(opacity: 0.4 + 0.6 * sin(idle.value * 6 * pi).abs(), child: ch),
                  child: Image.asset(QuranAssets.sparkle, width: 18 * s, height: 18 * s * 1.19),
                ),
              ),
              PositionedDirectional(
                start: w * 0.05,
                top: h * 0.1,
                bottom: h * 0.1,
                width: w * 0.55,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fit(t.quranHeroTop, _heroWord(const Color(0xFFFFF0B8), h * 0.19)),
                    _fit(t.quranHeroBottom, _heroWord(const Color(0xFFFFF0B8), h * 0.19)),
                    SizedBox(height: h * 0.06),
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 4 * s),
                        decoration: BoxDecoration(
                          color: _emeraldDeep.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFFFFE08A), width: 1.2),
                        ),
                        child: _fit(t.quranHeroSub, kidBodyStyle(11.5 * s, color: Colors.white, weight: FontWeight.w600),
                            align: Alignment.center),
                      ),
                    ),
                  ],
                ),
              ),
            ]);
          }),
        ),
      ),
    );
  }
}

Widget _playButton(String asset, bool playing, Animation<double> idle, double size, double aspect) => AnimatedBuilder(
      animation: idle,
      builder: (_, c) => Transform.scale(scale: playing ? 1.0 + 0.05 * sin(idle.value * 24 * pi) : 1.0, child: c),
      child: SizedBox(
        width: size,
        height: size * aspect,
        child: Stack(alignment: Alignment.center, children: [
          Image.asset(asset, width: size, height: size * aspect, fit: BoxFit.contain),
          if (playing)
            Align(
              // the round button sits on the left part of the sprite (sparks on the right)
              alignment: aspect < 0.9 ? const Alignment(-0.22, 0) : Alignment.center,
              child: Container(
                width: size * (aspect < 0.9 ? 0.4 : 0.52),
                height: size * (aspect < 0.9 ? 0.4 : 0.52),
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF14935C)),
                child: Icon(Icons.pause_rounded, color: Colors.white, size: size * (aspect < 0.9 ? 0.32 : 0.42)),
              ),
            ),
        ]),
      ),
    );

class _NowPlaying extends StatelessWidget {
  final double scale;
  final QuranItem item;
  final AudioPlayer player;
  final bool ready, playing, repeat, started;
  final Animation<double> idle;
  final VoidCallback onPlay, onRepeat;
  const _NowPlaying({required this.scale, required this.item, required this.player, required this.ready, required this.playing,
      required this.repeat, required this.started, required this.idle, required this.onPlay, required this.onRepeat});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final t = tr(context);
    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(8 * s, 10 * s, 10 * s, 10 * s),
      decoration: kidCardDecoration(26 * s, shadow: 0.3),
      child: Row(children: [
        Image.asset(QuranAssets.stand, width: 70 * s, height: 70 * s * 0.9184),
        SizedBox(width: 8 * s),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fit(started ? t.resumeListening : t.startListening, kidBodyStyle(16 * s, color: _ink, weight: FontWeight.w700)),
              _fit(item.isVerse ? item.arabic : item.name, kidBodyStyle(13 * s, color: KidColors.purple, weight: FontWeight.w600)),
              SizedBox(height: 4 * s),
              StreamBuilder<Duration>(
                stream: player.positionStream,
                builder: (context, snap) {
                  final dur = ready ? (player.duration ?? Duration.zero) : Duration.zero;
                  final pos = ready ? (snap.data ?? Duration.zero) : Duration.zero;
                  final v = dur.inMilliseconds == 0 ? 0.0 : (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0);
                  return Column(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(
                      height: 22 * s,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 7 * s,
                          activeTrackColor: _emerald,
                          inactiveTrackColor: const Color(0xFFE9DFCF),
                          thumbColor: const Color(0xFFFFFAF0),
                          overlayColor: _emerald.withOpacity(0.12),
                          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 9 * s, elevation: 3),
                          overlayShape: RoundSliderOverlayShape(overlayRadius: 14 * s),
                          trackShape: const RoundedRectSliderTrackShape(),
                        ),
                        child: Slider(
                          value: v,
                          onChanged: ready && dur > Duration.zero
                              ? (x) => player.seek(Duration(milliseconds: (x * dur.inMilliseconds).round()))
                              : null,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6 * s),
                      child: Row(children: [
                        Text(_mmss(pos), style: kidBodyStyle(11 * s, color: KidColors.muted, weight: FontWeight.w600)),
                        const Spacer(),
                        Text(dur == Duration.zero ? '--:--' : _mmss(dur),
                            style: kidBodyStyle(11 * s, color: KidColors.muted, weight: FontWeight.w600)),
                      ]),
                    ),
                  ]);
                },
              ),
            ],
          ),
        ),
        SizedBox(width: 6 * s),
        KidPressable(onTap: onPlay, semanticLabel: t.tapToListen, child: _playButton(QuranAssets.playBig, playing, idle, 82 * s, 0.7817)),
        SizedBox(width: 2 * s),
        KidPressable(
          onTap: onRepeat,
          semanticLabel: t.modeRepeat,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: repeat ? 1 : 0.55,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: repeat ? 1.08 : 1,
              child: Image.asset(QuranAssets.repeat, width: 44 * s, height: 44 * s),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Tabs extends StatelessWidget {
  final double scale;
  final bool favorites;
  final ValueChanged<bool> onChanged;
  const _Tabs({required this.scale, required this.favorites, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final t = tr(context);
    Widget tab(bool fav, Widget icon, String label) {
      final active = favorites == fav;
      return Expanded(
        child: KidPressable(
          onTap: () => onChanged(fav),
          pressedScale: 0.95,
          semanticLabel: label,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            height: 50 * s,
            padding: EdgeInsets.symmetric(horizontal: 10 * s),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              gradient: active
                  ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2CB574), _emerald])
                  : null,
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  icon,
                  SizedBox(width: 8 * s),
                  Text(label, maxLines: 1, style: kidBodyStyle(18 * s, color: active ? Colors.white : KidColors.purpleDeep, weight: FontWeight.w700)),
                ]),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(4 * s),
      decoration: kidCardDecoration(40 * s, shadow: 0.18),
      child: Row(children: [
        tab(false, Icon(Icons.menu_book_rounded, color: favorites ? KidColors.purple : Colors.white, size: 24 * s), t.tabSurahs),
        tab(true, Image.asset(QuranAssets.heartFull, width: 26 * s, height: 26 * s * 0.8932), t.tabFavorites),
      ]),
    );
  }
}

class _SearchField extends StatelessWidget {
  final double scale;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.scale, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      height: 48 * s,
      padding: EdgeInsets.symmetric(horizontal: 14 * s),
      decoration: BoxDecoration(
        color: kidCardCream,
        borderRadius: BorderRadius.circular(30 * s),
        border: Border.all(color: const Color(0xFFEFE2C8), width: 2),
        boxShadow: [BoxShadow(color: KidColors.purpleDeep.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        Image.asset(QuranAssets.search, width: 24 * s, height: 24 * s),
        SizedBox(width: 10 * s),
        Expanded(
          child: TextField(
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            style: kidBodyStyle(16 * s, color: _ink, weight: FontWeight.w600),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: tr(context).searchSurah,
              hintStyle: kidBodyStyle(15 * s, color: KidColors.muted),
            ),
          ),
        ),
      ]),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final double scale;
  final int number;
  final QuranItem item;
  final bool fav, done, hasAudio, playing;
  final Animation<double> idle;
  final VoidCallback onOpen, onFav, onPlay;
  const _ItemRow({required this.scale, required this.number, required this.item, required this.fav, required this.done,
      required this.hasAudio, required this.playing, required this.idle, required this.onOpen, required this.onFav, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return KidPressable(
      onTap: onOpen,
      pressedScale: 0.97,
      semanticLabel: item.name,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsetsDirectional.fromSTEB(10 * s, 8 * s, 6 * s, 8 * s),
        decoration: kidCardDecoration(24 * s, shadow: 0.22).copyWith(
          border: Border.all(color: playing ? const Color(0xFF7DDBA8) : Colors.white, width: 3),
        ),
        child: Row(children: [
          Container(
            width: 36 * s,
            height: 36 * s,
            alignment: Alignment.center,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEDE6FF)),
            child: Text('$number', style: kidBodyStyle(17 * s, color: KidColors.purpleDeep, weight: FontWeight.w700)),
          ),
          SizedBox(width: 8 * s),
          Image.asset(QuranAssets.book, width: 44 * s, height: 44 * s * 1.1357),
          SizedBox(width: 10 * s),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.isVerse)
                  Text(item.ayat.first,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(fontSize: 15 * s, height: 1.5, color: _emeraldDeep, fontWeight: FontWeight.w600))
                else
                  _fit(item.name, kidTitleStyle(20 * s, color: _ink).copyWith(shadows: const [])),
                Row(children: [
                  Flexible(
                    child: _fit(item.isVerse ? item.arabic : item.arabic,
                        kidBodyStyle(12.5 * s, color: _emerald, weight: FontWeight.w700)),
                  ),
                  if (done) ...[
                    SizedBox(width: 6 * s),
                    Icon(Icons.check_circle_rounded, color: _emerald, size: 15 * s),
                  ],
                  if (!hasAudio) ...[
                    SizedBox(width: 6 * s),
                    Icon(Icons.headset_off_rounded, color: KidColors.lavender, size: 15 * s),
                  ],
                ]),
              ],
            ),
          ),
          SizedBox(width: 4 * s),
          KidPressable(
            onTap: onFav,
            child: Padding(
              padding: EdgeInsets.all(4 * s),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                child: Image.asset(fav ? QuranAssets.heartFull : QuranAssets.heart,
                    key: ValueKey(fav), width: 32 * s, height: 32 * s * 0.89),
              ),
            ),
          ),
          SizedBox(width: 2 * s),
          KidPressable(
            onTap: onPlay,
            child: Opacity(
              opacity: hasAudio ? 1 : 0.4,
              child: _playButton(QuranAssets.playBig, playing, idle, 70 * s, 0.7817),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ModeBar extends StatelessWidget {
  final double scale;
  final QuranMode mode;
  final ValueChanged<QuranMode> onChanged;
  const _ModeBar({required this.scale, required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final t = tr(context);
    Widget item(QuranMode m, String icon, double aspect, String label) {
      final active = mode == m;
      return Expanded(
        child: KidPressable(
          onTap: () => onChanged(m),
          semanticLabel: label,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: EdgeInsets.all(5 * s),
            decoration: BoxDecoration(
              color: active ? const Color(0xFFE6DCFF) : Colors.transparent,
              borderRadius: BorderRadius.circular(20 * s),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Image.asset(icon, height: 30 * s, width: 30 * s / aspect),
              SizedBox(height: 3 * s),
              _fit(label, kidBodyStyle(13.5 * s, color: KidColors.purpleDeep, weight: active ? FontWeight.w700 : FontWeight.w600),
                  align: Alignment.center),
            ]),
          ),
        ),
      );
    }

    Widget divider() => Container(width: 1.5, height: 40 * s, color: const Color(0xFFEADFC8));
    return Container(
      height: 76 * s,
      decoration: kidCardDecoration(30 * s, shadow: 0.3),
      child: Row(children: [
        item(QuranMode.listen, QuranAssets.icListen, 0.8938, t.modeListen),
        divider(),
        item(QuranMode.repeat, QuranAssets.icRepeat, 1.0, t.modeRepeat),
        divider(),
        item(QuranMode.memorize, QuranAssets.icMemorize, 0.8319, t.modeMemorize),
      ]),
    );
  }
}

/// Full text of a surah or verse. In memorize mode each verse is hidden
/// until the child taps it, to test themselves.
class _ReaderSheet extends StatefulWidget {
  final QuranItem item;
  final bool memorize, canPlay;
  final AudioPlayer? player;
  final VoidCallback onPlay;
  const _ReaderSheet({required this.item, required this.memorize, required this.player, required this.canPlay, required this.onPlay});

  @override
  State<_ReaderSheet> createState() => _ReaderSheetState();
}

class _ReaderSheetState extends State<_ReaderSheet> {
  late final Set<int> _revealed = widget.memorize ? <int>{} : {for (int i = 0; i < widget.item.ayat.length; i++) i};

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final h = MediaQuery.sizeOf(context).height;
    final it = widget.item;
    final all = _revealed.length == it.ayat.length;
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(maxHeight: h * 0.85),
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFFCF2), Color(0xFFFFF4D6)]),
          border: Border.all(color: const Color(0xFFFFC94A), width: 2.5),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          Container(width: 46, height: 5, decoration: BoxDecoration(color: const Color(0xFFFFC94A), borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Image.asset(QuranAssets.book, width: 40, height: 45),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  _fit(it.isVerse ? t.versesTitle : it.name, kidTitleStyle(22, color: _ink).copyWith(shadows: const [])),
                  Text(it.arabic, textDirection: TextDirection.rtl, style: kidBodyStyle(14, color: _emerald, weight: FontWeight.w700)),
                ]),
              ),
              if (widget.memorize)
                KidPressable(
                  onTap: () => setState(() {
                    if (all) {
                      _revealed.clear();
                    } else {
                      _revealed.addAll(List.generate(it.ayat.length, (i) => i));
                    }
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(color: const Color(0xFFEDE6FF), borderRadius: BorderRadius.circular(20)),
                    child: Text(all ? t.hideAll : t.showAll, style: kidBodyStyle(13, color: KidColors.purpleDeep, weight: FontWeight.w700)),
                  ),
                ),
              if (widget.canPlay) ...[
                const SizedBox(width: 8),
                KidPressable(
                  onTap: () {
                    widget.onPlay();
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted) setState(() {});
                    });
                  },
                  child: Image.asset(QuranAssets.play, width: 46, height: 46),
                ),
              ],
            ]),
          ),
          if (!widget.canPlay)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('🎧 ${t.audioSoon}', style: kidBodyStyle(12.5, color: KidColors.muted, weight: FontWeight.w600)),
            ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              children: [
                if (it.bismillahHeader)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(_bismillah,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(fontSize: 20, height: 1.7, color: Color(0xFFB7791F), fontWeight: FontWeight.w700)),
                  ),
                for (int i = 0; i < it.ayat.length; i++)
                  GestureDetector(
                    onTap: widget.memorize ? () => setState(() => _revealed.contains(i) ? _revealed.remove(i) : _revealed.add(i)) : null,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE8DDB8), width: 1.5),
                      ),
                      child: Row(textDirection: TextDirection.rtl, children: [
                        if (!it.isVerse) ...[
                          Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE0F5E8)),
                            child: Text('${i + 1}', style: kidBodyStyle(14, color: _emerald, weight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Stack(alignment: Alignment.center, children: [
                            ImageFiltered(
                              enabled: !_revealed.contains(i),
                              imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                              child: Text(it.ayat[i],
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 21, height: 1.7, color: _emeraldDeep, fontWeight: FontWeight.w600)),
                            ),
                            if (!_revealed.contains(i))
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFFEDE6FF), borderRadius: BorderRadius.circular(20)),
                                child: Text('👆 ${t.tapToReveal}', style: kidBodyStyle(12.5, color: KidColors.purpleDeep, weight: FontWeight.w700)),
                              ),
                          ]),
                        ),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
