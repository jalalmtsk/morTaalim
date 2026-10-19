import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../XpSystem.dart';
import '../../../tools/audio_tool/Audio_Manager.dart';
import '../../../widgets/KidScene/kid_page_parts.dart';
import '../../../widgets/KidScene/kid_scene.dart';
import 'magic_paint_color.dart';
import 'magic_paint_data.dart';
import 'magic_paint_draw.dart';
import 'magic_paint_gallery.dart';
import 'magic_paint_widgets.dart';

/// Peinture magique: Colorier · Dessiner · Mes créations.
class MagicPaintPage extends StatefulWidget {
  const MagicPaintPage({super.key});

  @override
  State<MagicPaintPage> createState() => _MagicPaintPageState();
}

class _MagicPaintPageState extends State<MagicPaintPage> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  final ConfettiController _confetti = ConfettiController(duration: const Duration(milliseconds: 1600));
  final GlobalKey<MpColorTabState> _colorKey = GlobalKey();
  final GlobalKey<MpDrawTabState> _drawKey = GlobalKey();
  final GlobalKey<MpGalleryTabState> _galleryKey = GlobalKey();

  int _tab = 0;
  bool _showModel = true;
  bool _sounds = true;
  bool _precached = false;
  bool _leaving = false;

  AudioManager get _audio => Provider.of<AudioManager>(context, listen: false);

  @override
  void initState() {
    super.initState();
    MpStore.showModel.then((v) {
      if (mounted) setState(() => _showModel = v);
    });
    MpStore.sounds.then((v) {
      if (mounted) setState(() => _sounds = v);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    KidAssets.precache(context, [...mpAllImages, for (final p in mpPages) p.model]);
  }

  @override
  void dispose() {
    _intro.dispose();
    _idle.dispose();
    _confetti.dispose();
    super.dispose();
  }

  void _sound(String key) {
    if (!_sounds) return;
    _audio.playEventSound(key);
  }

  Future<void> _saveAll() async {
    await _colorKey.currentState?.autosave();
    await _drawKey.currentState?.autosave();
  }

  Future<void> _switch(int i) async {
    if (i == _tab) return;
    _sound('clickButton');
    await _saveAll();
    if (!mounted) return;
    setState(() => _tab = i);
    if (i == 2) _galleryKey.currentState?.reload();
  }

  Future<void> _exit() async {
    if (_leaving) return;
    _leaving = true;
    _sound('cancelButton');
    await _saveAll();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _finished({required bool firstFinish}) async {
    _confetti.play();
    if (_sounds) _audio.playSfx('assets/audios/UI_Audio/SFX_Audio/MarimbaWin_SFX.mp3');
    if (firstFinish && mounted) {
      final xp = Provider.of<ExperienceManager>(context, listen: false);
      xp.addGold(context, 3);
      xp.addXP(5, context: context);
    }
    _galleryKey.currentState?.reload();
  }

  Future<void> _openCreation(MpCreation c) async {
    _sound('clickButton');
    if (c.kind == 'color') {
      await _drawKey.currentState?.autosave();
      setState(() => _tab = 0);
      await _colorKey.currentState?.openCreation(c);
    } else {
      await _colorKey.currentState?.autosave();
      setState(() => _tab = 1);
      await _drawKey.currentState?.openCreation(c);
    }
  }

  Future<void> _newCreation() async {
    final id = await mpPickPage(context, withBlank: true);
    if (id == null || !mounted) return;
    if (id == '__blank__') {
      setState(() => _tab = 1);
      await _drawKey.currentState?.newPage();
    } else {
      setState(() => _tab = 0);
      await _colorKey.currentState?.openPage(id);
    }
  }

  Future<void> _createDrawing() async {
    setState(() => _tab = 1);
    await _drawKey.currentState?.newPage();
  }

  void _settings() {
    _sound('clickButton');
    mpOpenSettings(
      context,
      showModel: _showModel,
      onShowModel: (v) {
        setState(() => _showModel = v);
        MpStore.setShowModel(v);
      },
      sounds: _sounds,
      onSounds: (v) {
        setState(() => _sounds = v);
        MpStore.setSounds(v);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exit();
      },
      child: Scaffold(
        backgroundColor: KidColors.sky,
        resizeToAvoidBottomInset: false,
        body: Stack(children: [
          const Positioned.fill(child: KidPageBackground(asset: mpImgBg, wash: 0)),
          SafeArea(child: LayoutBuilder(builder: (context, c) => _layout(c))),
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
      ),
    );
  }

  Widget _layout(BoxConstraints c) {
    final w = min(c.maxWidth, 560.0);
    final s = min(w / 390, c.maxHeight / 840).clamp(0.62, 1.3).toDouble();
    Widget step(int i, Widget child) =>
        KidIntro(intro: _intro, from: 0.08 * i, to: min(1.0, 0.5 + 0.08 * i), rise: 16, child: child);
    return Center(
      child: SizedBox(
        width: w,
        child: Padding(
          padding: EdgeInsets.fromLTRB(12 * s, 4 * s, 12 * s, 8 * s),
          child: Column(children: [
            step(0, MpTopBar(scale: s, title: mpText(context, 'title'), onBack: _exit, onGear: _settings)),
            SizedBox(height: 6 * s),
            step(1, Padding(
              padding: EdgeInsets.symmetric(horizontal: 12 * s),
              child: MpTabs(scale: s, index: _tab, onTap: _switch),
            )),
            SizedBox(height: 8 * s),
            Expanded(
              child: step(2, IndexedStack(
                index: _tab,
                sizing: StackFit.expand,
                children: [
                  MpColorTab(
                    key: _colorKey,
                    scale: s,
                    idle: _idle,
                    showModel: _showModel,
                    onSound: _sound,
                    onFinished: _finished,
                    onGallery: () => _switch(2),
                  ),
                  MpDrawTab(key: _drawKey, scale: s, idle: _idle, onSound: _sound, onFinished: _finished),
                  MpGalleryTab(
                    key: _galleryKey,
                    scale: s,
                    idle: _idle,
                    onSound: _sound,
                    onOpen: _openCreation,
                    onNew: _newCreation,
                    onCreateDrawing: _createDrawing,
                  ),
                ],
              )),
            ),
          ]),
        ),
      ),
    );
  }
}
