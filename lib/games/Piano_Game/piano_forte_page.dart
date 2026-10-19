import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../../XpSystem.dart';
import '../../tools/Ads_Manager.dart';
import '../../tools/audio_tool/Audio_Manager.dart';
import '../../widgets/KidScene/kid_page_parts.dart';
import '../../widgets/KidScene/kid_scene.dart';
import 'piano_forte_data.dart';
import 'piano_forte_sheets.dart';
import 'piano_forte_widgets.dart';

/// Piano Forte — learn songs by following the glowing keys, or play freely
/// with piano / xylophone / bells, record melodies and listen back.
class PianoFortePage extends StatefulWidget {
  const PianoFortePage({super.key});

  @override
  State<PianoFortePage> createState() => _PianoFortePageState();
}

class _PianoFortePageState extends State<PianoFortePage> with TickerProviderStateMixin {
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  late final AnimationController _beat = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  final ConfettiController _confetti = ConfettiController(duration: const Duration(seconds: 2));
  final PfSoundBank _bank = PfSoundBank();

  bool _ready = false;
  bool _precached = false;
  int _mode = 0; // 0 learn · 1 free
  double _volume = 0.8;
  PfInstrument _instrument = PfInstrument.piano;
  PfNaming _naming = PfNaming.solfege;
  bool _showNames = true;

  // learn
  PfSong _song = pfSongs.first;
  int _pos = 0;
  int _mistakes = 0;
  bool _hintSeen = false;
  bool _slow = false;
  Map<String, double> _bests = {};

  // playback of songs / previews / melodies
  final List<Timer> _seqTimers = [];
  Timer? _litTimer;
  String _seqKind = ''; // demo · preview · melody
  bool _seqPlaying = false, _seqPaused = false;
  List<int> _seqKeys = [], _seqTimes = [];
  int _seqIndex = 0;
  VoidCallback? _seqDone;
  Set<int> _lit = {};
  int _beats = 0; // counts notes, alternates the conductor's stroke

  // free play
  bool _recording = false;
  DateTime? _recStart;
  final List<int> _recKeys = [], _recTimes = [];
  PfMelody? _current;
  List<PfMelody> _melodies = [];

  // robot
  PfFace _face = PfFace.happy;
  Timer? _faceTimer;
  String _bubbleKey = 'yourTurn';
  int _bubbleTick = 0;

  BannerAd? _banner;
  bool _bannerLoaded = false;

  // the app's background music is paused while the piano is open
  AudioManager? _audioRef;
  String? _musicBefore;

  AudioManager get _audio => Provider.of<AudioManager>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _banner = AdHelper.getBannerAd(() {
      if (mounted) setState(() => _bannerLoaded = true);
    });
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    _audioRef = Provider.of<AudioManager>(context, listen: false);
    _musicBefore = _audioRef!.currentBgMusic;
    WidgetsBinding.instance.addPostFrameCallback((_) => _audioRef?.stopMusic());
    KidAssets.precache(context, [
      pfImgBack, pfImgGear, pfImgSign, pfImgRobot, pfImgFaceHappy, pfImgFaceLaugh, pfImgFaceWow, pfImgStage, pfImgArc,
      pfImgRobotBody, pfImgArmBaton, pfImgArmFist, pfImgSparkleGold,
      pfImgBubble, pfImgSpeaker, pfImgPause, pfImgRestart, pfImgTurtle, pfImgHand, pfImgRipple, pfImgCheck, pfImgStar,
      pfImgRibbon, pfImgRec, pfImgPlay, pfImgRestartIcon, pfImgFolder, pfImgBg, ...pfImgNotes,
      for (final i in PfInstrument.values) pfInstrumentArt(i),
    ]);
  }

  @override
  void dispose() {
    _cancelSeqTimers();
    _litTimer?.cancel();
    _faceTimer?.cancel();
    _bank.dispose();
    final music = _musicBefore;
    if (music != null) _audioRef?.playBackgroundMusic(music);
    _intro.dispose();
    _idle.dispose();
    _beat.dispose();
    _confetti.dispose();
    _banner?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      PfStore.song(),
      PfStore.volume(),
      PfStore.instrument(),
      PfStore.naming(),
      PfStore.showNames(),
      PfStore.hintSeen(),
      PfStore.bests(),
      PfStore.melodies(),
    ]);
    _song = pfSongById(results[0] as String?);
    _volume = results[1] as double;
    _instrument = results[2] as PfInstrument;
    _naming = results[3] as PfNaming;
    _showNames = results[4] as bool;
    _hintSeen = results[5] as bool;
    _bests = results[6] as Map<String, double>;
    _melodies = results[7] as List<PfMelody>;
    await _bank.setVolume(_volume);
    // learning always uses the piano; free play remembers the instrument
    await _bank.load(PfInstrument.piano);
    if (!mounted) return;
    setState(() => _ready = true);
    _intro.forward(from: 0);
  }

  // ── robot ───────────────────────────────────────────────────────────────

  void _say(String key) => setState(() {
        _bubbleKey = key;
        _bubbleTick++;
      });

  void _flashFace(PfFace f, {int ms = 700}) {
    _faceTimer?.cancel();
    setState(() => _face = f);
    _faceTimer = Timer(Duration(milliseconds: ms), () {
      if (mounted) setState(() => _face = PfFace.happy);
    });
  }

  // ── sequences (song demo, preview, saved melody) ────────────────────────

  void _cancelSeqTimers() {
    for (final t in _seqTimers) {
      t.cancel();
    }
    _seqTimers.clear();
  }

  void _startSeq(String kind, List<int> keys, List<int> times, {VoidCallback? onDone}) {
    _stopSeq();
    if (keys.isEmpty) return;
    _seqKind = kind;
    _seqKeys = keys;
    _seqTimes = times;
    _seqIndex = 0;
    _seqPlaying = true;
    _seqPaused = false;
    _seqDone = onDone;
    _scheduleFrom(0);
    setState(() {});
  }

  void _scheduleFrom(int i) {
    _cancelSeqTimers();
    final base = _seqTimes[i];
    for (int j = i; j < _seqKeys.length; j++) {
      _seqTimers.add(Timer(Duration(milliseconds: _seqTimes[j] - base), () => _seqNote(j)));
    }
    _seqTimers.add(Timer(Duration(milliseconds: _seqTimes.last - base + 650), _seqFinish));
  }

  void _seqNote(int j) {
    if (!mounted) return;
    _seqIndex = j + 1;
    final k = _seqKeys[j];
    _bank.play(k);
    _beats++;
    _beat.forward(from: 0);
    if (_seqKind == 'preview') return;
    _litTimer?.cancel();
    setState(() => _lit = {k});
    _litTimer = Timer(const Duration(milliseconds: 280), () {
      if (mounted) setState(() => _lit = {});
    });
  }

  void _seqFinish() {
    if (!mounted) return;
    _cancelSeqTimers();
    final done = _seqDone;
    setState(() {
      _seqPlaying = false;
      _seqPaused = false;
      _lit = {};
      _seqDone = null;
    });
    done?.call();
  }

  void _pauseSeq() {
    if (!_seqPlaying || _seqPaused) return;
    _cancelSeqTimers();
    setState(() => _seqPaused = true);
  }

  void _resumeSeq() {
    if (!_seqPaused) return;
    if (_seqIndex >= _seqKeys.length) return _seqFinish();
    _seqPaused = false;
    _scheduleFrom(_seqIndex);
    setState(() {});
  }

  void _stopSeq() {
    _cancelSeqTimers();
    _litTimer?.cancel();
    _seqPlaying = false;
    _seqPaused = false;
    _seqDone = null;
    if (_lit.isNotEmpty) _lit = {};
  }

  // ── learn ───────────────────────────────────────────────────────────────

  Future<void> _demo() async {
    await _bank.load(PfInstrument.piano);
    if (!mounted) return;
    _say('listen');
    _startSeq('demo', _song.notes, pfSchedule(_song.beats, _song.bpm, slow: _slow ? 1.6 : 1),
        onDone: () => _say('yourTurn'));
  }

  void _playPause() {
    _audio.playEventSound('clickButton2');
    if (_seqPlaying && _seqKind == 'demo') {
      _seqPaused ? _resumeSeq() : _pauseSeq();
    } else {
      _demo();
    }
  }

  void _toggleSlow() {
    _audio.playEventSound('clickButton2');
    setState(() => _slow = !_slow);
    if (_slow) _say('slowOn');
  }

  void _restartSong() {
    _audio.playEventSound('clickButton2');
    setState(() {
      _stopSeq();
      _pos = 0;
      _mistakes = 0;
    });
    _say('yourTurn');
  }

  Future<void> _pickSong() async {
    _audio.playEventSound('clickButton2');
    setState(_stopSeq);
    final id = await pfShowSongPicker(
      context,
      currentId: _song.id,
      bests: _bests,
      onPreview: (song) async {
        await _bank.load(PfInstrument.piano);
        _startSeq('preview', song.notes, pfSchedule(song.beats, song.bpm));
      },
      onStopPreview: () {
        if (mounted) setState(_stopSeq);
      },
    );
    if (!mounted || id == null) return;
    PfStore.setSong(id);
    setState(() {
      _song = pfSongById(id);
      _pos = 0;
      _mistakes = 0;
      _mode = 0;
    });
    await _bank.load(PfInstrument.piano);
    _say('yourTurn');
  }

  void _learnKey(int k) {
    if (_seqPlaying) setState(_stopSeq); // the child takes over from the demo
    if (_pos >= _song.length) return;
    if (k == _song.notes[_pos]) {
      setState(() => _pos++);
      if (!_hintSeen) {
        _hintSeen = true;
        PfStore.setHintSeen();
      }
      _flashFace(PfFace.laugh, ms: 500);
      final v = _pos / _song.length;
      if (v > (_bests[_song.id] ?? 0)) _bests[_song.id] = v;
      PfStore.saveBest(_song.id, v);
      if (_pos == _song.length) {
        _songDone();
      } else if (_pos % 4 == 0) {
        _say('bravo');
      }
    } else {
      _mistakes++;
      HapticFeedback.lightImpact();
      _flashFace(PfFace.wow, ms: 800);
      _say('tryGlow');
    }
  }

  Future<void> _songDone() async {
    _say('wonderful');
    _flashFace(PfFace.laugh, ms: 2500);
    final stars = _mistakes <= 1 ? 3 : _mistakes <= 4 ? 2 : 1;
    final first = await PfStore.markDone(_song.id);
    if (!mounted) return;
    final gold = first ? 5 : 2;
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _confetti.play();
    _audio.playSfx('assets/audios/UI_Audio/SFX_Audio/victory2_SFX.mp3');
    final xp = Provider.of<ExperienceManager>(context, listen: false);
    xp.addGold(context, gold);
    xp.addXP(10, context: context);
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      barrierColor: KidColors.purpleDeep.withOpacity(0.35),
      builder: (ctx) => KidDialog(
        headerAsset: pfImgRobotPoint,
        headerAspect: 340 / 296,
        title: pfText(ctx, 'songDone'),
        message: _song.title(ctx),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (int i = 0; i < 3; i++)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 500 + 220 * i),
                curve: Curves.elasticOut,
                builder: (_, v, c) => Transform.scale(scale: v, child: c),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Opacity(
                    opacity: i < stars ? 1 : 0.25,
                    child: Image.asset(pfImgStar, width: i == 1 ? 58 : 46, height: i == 1 ? 58 : 46),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Image.asset(kidCoinAsset, width: 28, height: 28),
            const SizedBox(width: 6),
            Text('+$gold', style: kidBodyStyle(20, color: pfInk, weight: FontWeight.w700)),
          ]),
        ]),
        actions: [
          KidOutlineButton(label: pfText(ctx, 'changeSong'), onTap: () => Navigator.pop(ctx, 'change')),
          KidButton(
            label: pfText(ctx, 'again'),
            onPressed: () => Navigator.pop(ctx, 'again'),
            width: double.infinity,
            height: 54,
            showArrow: false,
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() {
      _pos = 0;
      _mistakes = 0;
    });
    if (choice == 'change') {
      _pickSong();
    } else {
      _say('yourTurn');
    }
  }

  // ── free play ───────────────────────────────────────────────────────────

  Future<void> _setMode(int m) async {
    if (m == _mode) return;
    _audio.playEventSound('clickButton2');
    if (_recording) _stopRecording();
    setState(() {
      _stopSeq();
      _mode = m;
    });
    await _bank.load(m == 0 ? PfInstrument.piano : _instrument);
    _say(m == 0 ? 'yourTurn' : 'firstNote');
  }

  Future<void> _setInstrument(PfInstrument i) async {
    _audio.playEventSound('clickButton2');
    setState(() {
      _stopSeq();
      _instrument = i;
    });
    PfStore.setInstrument(i);
    await _bank.load(i);
    _bank.play(7); // a little "Sol" to hear it
    _beat.forward(from: 0);
  }

  void _toggleRecord() {
    _audio.playEventSound('clickButton2');
    if (_recording) {
      _stopRecording();
      return;
    }
    setState(() {
      _stopSeq();
      _recording = true;
      _recStart = null;
      _recKeys.clear();
      _recTimes.clear();
    });
    _say('recording');
  }

  void _stopRecording() {
    if (_recKeys.isEmpty) {
      setState(() => _recording = false);
      _say('firstNote');
      return;
    }
    final m = PfMelody(
      pfText(context, 'melody').replaceAll('{N}', '${_melodies.length + 1}'),
      _instrument,
      List.of(_recKeys),
      List.of(_recTimes),
    );
    setState(() {
      _recording = false;
      _current = m;
      _melodies = [m, ..._melodies].take(12).toList();
    });
    PfStore.saveMelodies(_melodies);
    _flashFace(PfFace.laugh, ms: 1200);
    _say('saved');
  }

  Future<void> _playMelody(PfMelody m) async {
    if (_instrument != m.instrument) {
      setState(() => _instrument = m.instrument);
      PfStore.setInstrument(m.instrument);
    }
    await _bank.load(m.instrument);
    if (!mounted) return;
    _say('playingYours');
    _startSeq('melody', m.keys, m.times, onDone: () => _say('firstNote'));
  }

  void _listenToggle() {
    _audio.playEventSound('clickButton2');
    if (_seqPlaying && _seqKind == 'melody') {
      setState(_stopSeq);
      return;
    }
    final m = _current;
    if (m != null) _playMelody(m);
  }

  void _clear() {
    _audio.playEventSound('cancelButton');
    setState(() {
      _stopSeq();
      _current = null;
      _recording = false;
    });
    _say('firstNote');
  }

  Future<void> _openMelodies() async {
    _audio.playEventSound('clickButton2');
    if (_recording) _stopRecording();
    await pfShowMelodies(
      context,
      melodies: _melodies,
      onPlay: (m) {
        setState(() => _current = m);
        _playMelody(m);
      },
      onDelete: (i) {
        final removed = _melodies[i];
        setState(() {
          _melodies = List.of(_melodies)..removeAt(i);
          if (identical(_current, removed)) _current = null;
        });
        PfStore.saveMelodies(_melodies);
      },
      onStop: () {
        if (mounted) setState(_stopSeq);
      },
    );
  }

  // ── keys ────────────────────────────────────────────────────────────────

  void _onKey(int k) {
    _bank.play(k);
    _beats++;
    _beat.forward(from: 0);
    if (_mode == 0) return _learnKey(k);
    if (_seqPlaying) setState(_stopSeq);
    if (_recording) {
      final now = DateTime.now();
      _recStart ??= now;
      _recKeys.add(k);
      _recTimes.add(now.difference(_recStart!).inMilliseconds);
      if (_recKeys.length > 200) _stopRecording(); // keep melodies small
    }
  }

  Future<void> _openSettings() async {
    _audio.playEventSound('clickButton2');
    var naming = _naming;
    var show = _showNames;
    await showDialog<void>(
      context: context,
      barrierColor: KidColors.purpleDeep.withOpacity(0.35),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          Widget choice(String label, bool on, VoidCallback tap) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: KidPressable(
                    onTap: tap,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: on ? const Color(0xFFE6FCFF) : kidCardCream,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: on ? pfCyan : KidColors.lavender, width: 2.5),
                      ),
                      child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: pfBody(16, weight: FontWeight.w700))),
                    ),
                  ),
                ),
              );
          return KidDialog(
            title: pfText(ctx, 'settings'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(pfText(ctx, 'noteNames'), style: pfBody(15, weight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(children: [
                choice(pfLang(ctx) == 'ar' ? 'دو ري مي' : 'Do Ré Mi', naming == PfNaming.solfege, () => setD(() => naming = PfNaming.solfege)),
                choice('C D E', naming == PfNaming.letters, () => setD(() => naming = PfNaming.letters)),
              ]),
              const SizedBox(height: 14),
              Text(pfText(ctx, 'showNames'), style: pfBody(15, weight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(children: [
                choice(pfText(ctx, 'yes'), show, () => setD(() => show = true)),
                choice(pfText(ctx, 'no'), !show, () => setD(() => show = false)),
              ]),
            ]),
            actions: [
              KidButton(
                label: pfText(ctx, 'close'),
                onPressed: () => Navigator.pop(ctx),
                width: double.infinity,
                height: 52,
                showArrow: false,
              ),
            ],
          );
        },
      ),
    );
    if (!mounted) return;
    setState(() {
      _naming = naming;
      _showNames = show;
    });
    PfStore.setNaming(naming);
    PfStore.setShowNames(show);
  }

  // ── build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final xp = context.watch<ExperienceManager>();
    final showAd = xp.adsEnabled && _banner != null && _bannerLoaded;
    return Scaffold(
      backgroundColor: KidColors.sky,
      body: Stack(children: [
        const Positioned.fill(child: KidPageBackground(asset: pfImgBg, wash: 0)),
        SafeArea(
          bottom: !showAd,
          child: !_ready
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : LayoutBuilder(builder: (context, c) => _layout(c)),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 30,
            emissionFrequency: 0.06,
            gravity: 0.25,
            colors: const [Color(0xFF2FE3F0), Color(0xFF3CC85A), Color(0xFFFFC21A), Color(0xFFFF5FA8), Color(0xFF7B3FE4)],
          ),
        ),
      ]),
      bottomNavigationBar: showAd
          ? SafeArea(
              child: SizedBox(
                height: _banner!.size.height.toDouble(),
                width: _banner!.size.width.toDouble(),
                child: FamilyAdBanner(bannerAd: _banner, isLoaded: _bannerLoaded),
              ),
            )
          : null,
    );
  }

  /// Fixed blocks get sizes from the screen; the stage (robot) takes whatever
  /// height is left, so the keyboard and controls always fit.
  Widget _layout(BoxConstraints c) {
    final w = min(c.maxWidth, 620.0) - 24;
    final h = c.maxHeight;
    final s = min(w / 380, h / 820).clamp(0.68, 1.3).toDouble();
    final tall = h / s > 860;
    final names = pfNoteNames(context, _naming);
    final keysH = (w * 0.42).clamp(130 * s, 200 * s).toDouble();
    final topBarH = 60 * s;
    Widget step(int i, Widget child) =>
        KidIntro(intro: _intro, from: 0.06 * i, to: min(1.0, 0.5 + 0.06 * i), rise: 20, child: child);

    final learning = _mode == 0;
    final glowKey = learning && !_seqPlaying && _pos < _song.length ? _song.notes[_pos] : null;
    final showHand = learning && !_hintSeen && _pos == 0 && !_seqPlaying;

    return Center(
      child: SizedBox(
        width: w,
        child: Column(children: [
          SizedBox(height: 4 * s),
          step(0, _header(s, w)),
          SizedBox(height: 6 * s),
          step(1, Center(
            child: SizedBox(
              width: min(w * 0.86, 340 * s),
              child: PfModeToggle(
                s: s,
                index: _mode,
                labels: [pfText(context, 'learn'), pfText(context, 'free')],
                icons: const [Icons.school_rounded, Icons.sports_esports_rounded],
                onTap: _setMode,
              ),
            ),
          )),
          SizedBox(height: 8 * s),
          step(2, AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (ch, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(position: Tween(begin: const Offset(0, 0.05), end: Offset.zero).animate(a), child: ch),
            ),
            child: learning
                ? KeyedSubtree(key: const ValueKey('learn'), child: _learnCard(s, names))
                : KeyedSubtree(key: const ValueKey('free'), child: _freeCard(s)),
          )),
          Expanded(
            child: step(3, PfStageView(
              s: s,
              idle: _idle,
              beat: _beat,
              face: _face,
              bubble: pfText(context, _bubbleKey),
              bubbleTick: _bubbleTick,
              beatCount: _beats,
            )),
          ),
          step(4, SizedBox(
            height: keysH + topBarH + 24 * s,
            child: PfKeyboard(
              s: s,
              names: names,
              showNames: _showNames,
              glow: glowKey,
              lit: _lit,
              topBar: learning ? _learnControls(s) : _freeControls(s),
              topBarHeight: topBarH,
              onKeyDown: _onKey,
              hintKey: showHand ? glowKey : null,
              idle: _idle,
            ),
          )),
          SizedBox(height: 10 * s),
          step(5, SizedBox(
            height: 54 * s,
            child: Row(children: [
              Expanded(
                child: PfVolumePill(
                  s: s,
                  value: _volume,
                  onChanged: (v) {
                    setState(() => _volume = v);
                    _bank.setVolume(v);
                  },
                  onChangeEnd: PfStore.setVolume,
                ),
              ),
              SizedBox(width: 10 * s),
              Expanded(
                child: learning
                    ? PfPillButton(
                        s: s,
                        icon: Icon(Icons.menu_book_rounded, color: pfPurpleDeep, size: 30 * s),
                        label: pfText(context, 'changeSong'),
                        chevron: true,
                        onTap: _pickSong,
                      )
                    : PfPillButton(
                        s: s,
                        icon: Image.asset(pfImgFolder, width: 32 * s, height: 32 * s * 73 / 81),
                        label: pfText(context, 'myMelodies'),
                        onTap: _openMelodies,
                      ),
              ),
            ]),
          )),
          if (tall) ...[
            SizedBox(height: 8 * s),
            step(6, PfFooter(s: s, text: pfText(context, learning ? 'footerLearn' : 'footerFree'))),
          ],
          SizedBox(height: 8 * s),
        ]),
      ),
    );
  }

  Widget _header(double s, double w) => SizedBox(
        height: 84 * s,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: EdgeInsets.only(top: 14 * s),
            child: PfSpriteButton(
              asset: pfImgBack,
              size: 52 * s,
              flipForRtl: true,
              label: MaterialLocalizations.of(context).backButtonTooltip,
              onTap: () {
                _audio.playEventSound('cancelButton');
                Navigator.of(context).maybePop();
              },
            ),
          ),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: PfSign(width: min(w * 0.62, 250 * s), title: 'Piano Forte', subtitle: pfText(context, 'by')),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 14 * s),
            child: PfSpriteButton(asset: pfImgGear, size: 52 * s, label: pfText(context, 'settings'), onTap: _openSettings),
          ),
        ]),
      );

  Widget _learnCard(double s, List<String> names) {
    final len = _song.length;
    const window = 6;
    final start = max(0, min(_pos - 2, len - window));
    final end = min(len, start + window);
    return Container(
      height: 182 * s,
      padding: EdgeInsets.fromLTRB(14 * s, 10 * s, 10 * s, 10 * s),
      decoration: pfPanel(26 * s),
      child: Column(children: [
        Row(children: [
          SizedBox(width: 44 * s),
          Expanded(
            child: Column(children: [
              FittedBox(fit: BoxFit.scaleDown, child: Text(_song.title(context), maxLines: 1, style: pfTitle(25 * s, color: const Color(0xFF3A0E7A)))),
              SizedBox(height: 2 * s),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(pfText(context, 'followKeys'), maxLines: 1, style: pfBody(14 * s, color: const Color(0xFF6E6787))),
              ),
            ]),
          ),
          PfSpriteButton(
            asset: pfImgSpeaker,
            size: 44 * s,
            glow: _seqPlaying && _seqKind == 'demo' && !_seqPaused,
            label: pfText(context, 'play'),
            onTap: _playPause,
          ),
        ]),
        SizedBox(height: 8 * s),
        Expanded(
          child: LayoutBuilder(builder: (context, c) {
            final gap = 6 * s;
            final chip = min((c.maxWidth - gap * (window - 1)) / window, c.maxHeight / 1.12);
            return Directionality(
              textDirection: TextDirection.ltr, // the song reads left → right like the keyboard
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (int i = start; i < end; i++) ...[
                  if (i > start) SizedBox(width: gap),
                  PfNoteChip(
                    key: ValueKey('chip$i'),
                    size: chip,
                    keyIndex: _song.notes[i],
                    name: names[_song.notes[i]],
                    state: i < _pos ? PfChipState.done : i == _pos ? PfChipState.current : PfChipState.todo,
                  ),
                ],
              ]),
            );
          }),
        ),
        SizedBox(height: 8 * s),
        SizedBox(width: 220 * s, child: PfBar(value: _pos / len, height: 13 * s)),
        SizedBox(height: 3 * s),
        Text(pfText(context, 'notes').replaceAll('{A}', '$_pos').replaceAll('{B}', '$len'),
            style: pfBody(13 * s, weight: FontWeight.w700)),
      ]),
    );
  }

  Widget _freeCard(double s) => Container(
        height: 182 * s,
        padding: EdgeInsets.fromLTRB(12 * s, 10 * s, 12 * s, 8 * s),
        decoration: pfPanel(26 * s),
        child: Column(children: [
          FittedBox(fit: BoxFit.scaleDown, child: Text(pfText(context, 'create'), maxLines: 1, style: pfTitle(25 * s, color: const Color(0xFF3A0E7A)))),
          FittedBox(fit: BoxFit.scaleDown, child: Text(pfText(context, 'createSub'), maxLines: 1, style: pfBody(14 * s, color: const Color(0xFF6E6787)))),
          SizedBox(height: 6 * s),
          Expanded(
            child: Row(children: [
              for (final i in PfInstrument.values) ...[
                if (i != PfInstrument.piano) SizedBox(width: 8 * s),
                Expanded(child: _instrumentTile(s, i)),
              ],
            ]),
          ),
          SizedBox(height: 4 * s),
          SizedBox(height: 20 * s, child: Image.asset(pfImgRibbon, fit: BoxFit.contain)),
        ]),
      );

  Widget _instrumentTile(double s, PfInstrument i) {
    final on = _instrument == i;
    final label = pfText(context, i.name);
    return KidPressable(
      onTap: () => _setInstrument(i),
      pressedScale: 0.94,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: EdgeInsets.all(5 * s),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18 * s),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: on ? const [Color(0xFFC9FAFF), Color(0xFF7FE8F5)] : const [Color(0xFFFFF8EA), Color(0xFFFFF0D6)],
          ),
          border: Border.all(color: on ? Colors.white : const Color(0xFFF0DDBA), width: on ? 3 * s : 2 * s),
          boxShadow: [
            BoxShadow(color: (on ? pfCyan : Colors.black).withOpacity(on ? 0.65 : 0.06), blurRadius: on ? 14 : 5),
          ],
        ),
        child: Column(children: [
          Expanded(child: Image.asset(pfInstrumentArt(i), fit: BoxFit.contain)),
          FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1, style: pfBody(14 * s, weight: FontWeight.w700))),
        ]),
      ),
    );
  }

  Widget _learnControls(double s) {
    final playing = _seqPlaying && _seqKind == 'demo' && !_seqPaused;
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      PfSpriteButton(asset: pfImgTurtle, size: 44 * s, glow: _slow, label: pfText(context, 'slowOn'), onTap: _toggleSlow),
      SizedBox(width: 18 * s),
      playing
          ? PfSpriteButton(asset: pfImgPause, size: 54 * s, label: pfText(context, 'play'), onTap: _playPause)
          : PfOrangeIcon(icon: Icons.play_arrow_rounded, size: 54 * s, label: pfText(context, 'play'), onTap: _playPause),
      SizedBox(width: 18 * s),
      PfSpriteButton(asset: pfImgRestart, size: 44 * s, label: pfText(context, 'again'), onTap: _restartSong),
    ]);
  }

  Widget _freeControls(double s) {
    final listening = _seqPlaying && _seqKind == 'melody';
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2 * s, vertical: 6 * s),
      child: Row(children: [
        Expanded(
          child: PfPillButton(
            s: s,
            height: 44,
            active: _recording,
            icon: _recording
                ? AnimatedBuilder(
                    animation: _idle,
                    builder: (_, __) => Opacity(
                      opacity: 0.5 + 0.5 * sin(_idle.value * 2 * pi * 12).abs(),
                      child: Icon(Icons.stop_rounded, color: Colors.red, size: 26 * s),
                    ),
                  )
                : Image.asset(pfImgRec, width: 24 * s, height: 24 * s),
            label: pfText(context, _recording ? 'stop' : 'record'),
            onTap: _toggleRecord,
          ),
        ),
        SizedBox(width: 6 * s),
        Expanded(
          child: PfPillButton(
            s: s,
            height: 44,
            enabled: _current != null && !_recording,
            icon: listening
                ? Icon(Icons.stop_rounded, color: pfPurpleDeep, size: 24 * s)
                : Image.asset(pfImgPlay, width: 20 * s, height: 20 * s * 66 / 58),
            label: pfText(context, listening ? 'stop' : 'play'),
            onTap: _listenToggle,
          ),
        ),
        SizedBox(width: 6 * s),
        Expanded(
          child: PfPillButton(
            s: s,
            height: 44,
            icon: Image.asset(pfImgRestartIcon, width: 22 * s, height: 22 * s * 76 / 69),
            label: pfText(context, 'clear'),
            onTap: _clear,
          ),
        ),
      ]),
    );
  }
}
