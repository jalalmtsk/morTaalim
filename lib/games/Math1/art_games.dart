import 'dart:math';

import 'package:flutter/material.dart';

import 'art_kit.dart';
import 'art_play.dart';
import 'm1_kit.dart';
import 'm1_shell.dart';
import 'm1_text.dart';

// Éducation artistique — 1re année primaire: the world, its five games and the gallery.

Widget artGalleryButton(BuildContext c) => M1OutlineButton(
      label: m1T(c, 'art_gallery'),
      icon: const Icon(Icons.photo_library_rounded, color: m1Purple),
      onTap: () => Navigator.of(c).push(m1Route(const ArtGalleryPage())),
      width: 230,
      height: 46,
    );

const artWorld = M1World(
  id: 'art',
  prefix: 'art',
  homeExtra: artGalleryButton,
  games: _artGames,
  subject: 'artEducation',
  homeBg: 'art_bg_home',
  homeSign: 'art_sign',
  homeBack: 'art_btn_back',
  homeSound: 'art_btn_sound',
  footerSprite: 'art_plank',
  mapBg: 'art_bg_map',
  mapMascot: 'art_robot',
  endBg: 'art_bg_end',
  endLeft: 'art_robot',
  endRight: 'ar_kid_jump',
  mapRatio: 890 / 941,
  mapPath: [
    Offset(0.308, 0.893), Offset(0.528, 0.787), Offset(0.81, 0.68), Offset(0.792, 0.466),
    Offset(0.542, 0.556), Offset(0.627, 0.258), Offset(0.494, 0.157), Offset(0.342, 0.073),
  ],
);
List<M1Game> _artGames() => artGames;

Widget _pic(String s, double size) => Image.asset(m1(s), height: size, fit: BoxFit.contain);

Widget _blobs(List<String> cs, double s) => FittedBox(
      child: Row(mainAxisSize: MainAxisSize.min, children: [for (var i = 0; i < cs.length; i++) ArtBlob(color: artColor(cs[i]), size: s * 0.42, seed: i + 3)]),
    );

Widget _lineIcon(String kind, double s) => SizedBox(width: s, height: s * 0.6, child: CustomPaint(painter: _LineIcon(kind)));

class _LineIcon extends CustomPainter {
  final String kind;
  _LineIcon(this.kind);
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..strokeWidth = s.height * 0.12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path();
    switch (kind) {
      case 'curves':
        p.color = m1Orange;
        path.moveTo(0, s.height * 0.6);
        for (var x = 0.0; x <= 1; x += 0.02) {
          path.lineTo(s.width * x, s.height * (0.5 - sin(x * 2 * pi) * 0.3));
        }
      case 'spirals':
        p.color = m1Purple;
        final c = s.center(Offset.zero);
        for (var t = 0.0; t <= 1; t += 0.01) {
          final q = c + Offset(cos(t * 5 * pi), sin(t * 5 * pi)) * (s.height * 0.45 * t);
          if (t == 0) {
            path.moveTo(q.dx, q.dy);
          } else {
            path.lineTo(q.dx, q.dy);
          }
        }
      default:
        p.color = m1Blue;
        path
          ..moveTo(s.width * 0.05, s.height * 0.5)
          ..lineTo(s.width * 0.95, s.height * 0.5);
    }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_LineIcon o) => false;
}

final List<M1Game> artGames = [
  M1Game(
    id: 'colors',
    world: artWorld,
    menuSign: 'art_sign',
    playSign: 'art_frame',
    back: 'art_btn_back',
    sound: 'art_btn_sound',
    playButton: 'btn_play',
    modes: const ['recognize', 'mix', 'color'],
    ranges: const [0, 1, 2],
    rangeStyle: M1RangeStyle.teal,
    tabIcon: 'art_palette',
    helpIcons: const ['art_palette', 'art_jar_blue', 'art_brush'],
    checkIcons: const ['art_brush', 'art_palette', 'art_easel'],
    robot: 'art_robot',
    modeIcon: (m, s) => switch (m) {
      0 => _blobs(['red', 'yellow', 'blue'], s),
      1 => FittedBox(child: Row(mainAxisSize: MainAxisSize.min, children: [ArtBlob(color: artColor('blue'), size: s * 0.45), Text('+', style: m1Text(s * 0.3)), ArtBlob(color: artColor('yellow'), size: s * 0.45, seed: 5)])),
      _ => _pic('art_easel', s * 0.8),
    },
    play: (lv) => ArtColorsPlay(lv: lv),
  ),
  M1Game(
    id: 'lines',
    world: artWorld,
    menuSign: 'art_sign',
    playSign: 'art_frame',
    back: 'art_btn_back',
    sound: 'art_btn_sound',
    playButton: 'btn_play',
    modes: const ['straight', 'curves', 'spirals'],
    ranges: const [0, 1, 2],
    rangeStyle: M1RangeStyle.stars,
    tabIcon: 'art_pencils',
    helpIcons: const ['art_pencils', 'ar_w_butterfly', 'art_butterfly_chalk'],
    checkIcons: const ['art_pencils', 'ar_w_butterfly', 'art_easel'],
    robot: 'art_robot',
    modeIcon: (m, s) => _lineIcon(const ['straight', 'curves', 'spirals'][m], s * 0.9),
    play: (lv) => ArtLinesPlay(lv: lv),
  ),
  M1Game(
    id: 'collage',
    world: artWorld,
    menuSign: 'art_sign',
    playSign: 'art_frame',
    back: 'art_btn_back',
    sound: 'art_btn_sound',
    playButton: 'btn_play',
    modes: const ['copy', 'complete', 'create'],
    ranges: const [0, 1, 2],
    rangeStyle: M1RangeStyle.blue,
    tabIcon: 'art_crane',
    helpIcons: const ['art_house', 'hand_tap', 'art_crane'],
    checkIcons: const ['art_house', 'art_crane', 'art_easel'],
    robot: 'art_robot',
    modeIcon: (m, s) => _pic(const ['art_house', 'art_crane', 'art_easel'][m], s * 0.75),
    play: (lv) => ArtCollagePlay(lv: lv),
  ),
  M1Game(
    id: 'motifs',
    world: artWorld,
    menuSign: 'art_sign',
    playSign: 'art_frame',
    back: 'art_btn_back',
    sound: 'art_btn_sound',
    playButton: 'btn_play',
    modes: const ['complete', 'copy', 'invent'],
    ranges: const [0, 1, 2],
    rangeStyle: M1RangeStyle.purple,
    tabIcon: 'art_palette',
    helpIcons: const ['art_palette', 'art_brush', 'art_easel'],
    checkIcons: const ['art_brush', 'art_palette', 'art_easel'],
    robot: 'art_robot',
    modeIcon: (m, s) => FittedBox(
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (final id in const [
          ['circle:orange', 'triangle:teal', 'circle:orange', 'triangle:teal'],
          ['flower:purple', 'flower:purple', 'flower:purple'],
          ['diamond:teal', 'flower:orange', 'diamond:teal'],
        ][m])
          ArtStamp(id: id, size: s * 0.32),
      ]),
    ),
    play: (lv) => ArtMotifsPlay(lv: lv),
  ),
  M1Game(
    id: 'rhythms',
    world: artWorld,
    menuSign: 'art_sign',
    playSign: 'art_frame',
    back: 'art_btn_back',
    sound: 'art_btn_sound',
    playButton: 'btn_play',
    modes: const ['listen', 'copy', 'compose'],
    ranges: const [0, 1, 2],
    rangeStyle: M1RangeStyle.purple,
    tabIcon: 'art_drum',
    helpIcons: const ['ar_ear', 'art_drum', 'art_note1'],
    checkIcons: const ['ar_ear', 'art_drum', 'art_maracas'],
    robot: 'art_robot',
    modeIcon: (m, s) => switch (m) {
      0 => _pic('ar_ear', s * 0.7),
      1 => _pic('art_drum', s * 0.7),
      _ => FittedBox(child: Row(mainAxisSize: MainAxisSize.min, children: [_pic('art_note1', s * 0.5), _pic('art_note2', s * 0.5), _pic('art_note3', s * 0.5)])),
    },
    play: (lv) => ArtRhythmsPlay(lv: lv),
  ),
];

// ═══════════════════════════════════════════════════════════════════════════
// MA GALERIE MAGIQUE
// ═══════════════════════════════════════════════════════════════════════════

class ArtGalleryPage extends StatefulWidget {
  const ArtGalleryPage({super.key});
  @override
  State<ArtGalleryPage> createState() => _ArtGalleryPageState();
}

class _ArtGalleryPageState extends State<ArtGalleryPage> {
  static const _tabs = [('drawings', Icons.edit_rounded), ('collages', Icons.content_cut_rounded), ('motifs', Icons.grid_view_rounded), ('rhythms', Icons.music_note_rounded)];
  static const Map<String, List<String>> _kinds = {
    'drawings': ['drawing', 'coloring'], 'collages': ['collage'], 'motifs': ['motif'], 'rhythms': ['rhythm'],
  };
  static const Map<String, int> _gameOf = {'drawings': 1, 'collages': 2, 'motifs': 3, 'rhythms': 4};
  int _tab = 0;
  List<ArtCreation> _all = [];
  String? _sel;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? M1Voice.say(context, m1T(context, 'art_gallery_say')) : null);
  }

  Future<void> _load() async {
    final l = await ArtGallery.all();
    if (!mounted) return;
    setState(() {
      _all = l;
      final mine = _list;
      _sel = mine.isEmpty ? null : mine.first.id;
    });
  }

  List<ArtCreation> get _list => _all.where((c) => _kinds[_tabs[_tab].$1]!.contains(c.kind)).toList();

  Future<void> _open(ArtCreation c) async {
    if (c.kind == 'rhythm') _playRhythm(List<String>.from(c.data['b'] as List));
    await m1Dialog(
      context,
      M1Frame(
        child: Center(
          child: Material(
            type: MaterialType.transparency,
            child: M1Card(
              width: 340,
              radius: 26,
              padding: const EdgeInsets.all(14),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(c.name, style: m1Text(22, color: m1Purple)),
                const SizedBox(height: 10),
                ArtThumb(creation: c, width: 300),
                const SizedBox(height: 12),
                M1OrangeButton(label: m1T(context, 'art_close'), onTap: () => Navigator.of(context).pop(), width: 220, height: 48),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _playRhythm(List<String> beats) async {
    for (final b in beats) {
      if (!mounted) return;
      artBeat(context, b);
      await Future.delayed(const Duration(milliseconds: 620));
    }
  }

  Future<void> _rename(ArtCreation c) async {
    final ctrl = TextEditingController(text: c.name);
    final ok = await m1Dialog<bool>(
      context,
      M1Frame(
        child: Center(
          child: Material(
            type: MaterialType.transparency,
            child: M1Card(
              width: 320,
              radius: 24,
              padding: const EdgeInsets.all(16),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(m1T(context, 'art_rename'), style: m1Text(20, color: m1Purple)),
                const SizedBox(height: 10),
                TextField(
                  controller: ctrl,
                  maxLength: 24,
                  autofocus: true,
                  style: m1Text(17),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 12),
                M1OrangeButton(label: m1T(context, 'art_save'), onTap: () => Navigator.of(context).pop(true), width: 220, height: 48),
              ]),
            ),
          ),
        ),
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      await ArtGallery.rename(c.id, ctrl.text.trim());
      _load();
    }
  }

  Future<void> _delete(ArtCreation c) async {
    await ArtGallery.remove(c.id);
    _load();
  }

  Future<void> _newOne() async {
    await Navigator.of(context).push(m1Route(M1GameMenu(game: artGames[_gameOf[_tabs[_tab].$1]!])));
    _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFFF6E9C8), body: M1Frame(child: Builder(builder: _page)));

  Widget _page(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final list = _list;
    ArtCreation? sel;
    for (final c in list) {
      if (c.id == _sel) sel = c;
    }
    return Stack(children: [
      const M1Bg(asset: 'art_bg_garden'),
      SafeArea(
        child: Column(children: [
          SizedBox(
            height: 92,
            child: Stack(children: [
              PositionedDirectional(start: 8, top: 8, child: m1Round(context, 'art_btn_back', 50, () => Navigator.of(context).maybePop(), flipRtl: true)),
              Align(alignment: Alignment.topCenter, child: M1Swing(child: M1Sign(sprite: 'art_sign', title: m1T(context, 'art_gallery'), width: min(w * 0.62, 250.0)))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(children: [
              for (var i = 0; i < _tabs.length; i++)
                Expanded(
                  child: M1Press(
                    onTap: () => setState(() {
                      _tab = i;
                      final l = _list;
                      _sel = l.isEmpty ? null : l.first.id;
                    }),
                    sound: 'toggleButton',
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: i == _tab ? m1Purple : m1Cream,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: i == _tab ? const Color(0xFFB98CFF) : m1Line, width: 2),
                      ),
                      child: Column(children: [
                        Icon(_tabs[i].$2, color: i == _tab ? Colors.white : m1Purple, size: 20),
                        FittedBox(child: Text(m1T(context, 'art_tab_${_tabs[i].$1}'), style: m1Text(12, color: i == _tab ? Colors.white : m1Ink))),
                      ]),
                    ),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.95),
              itemCount: list.length + 1,
              itemBuilder: (_, i) => i == list.length ? _newCard() : M1PopIn(delay: 40 * i, child: _card(list[i])),
            ),
          ),
          if (sel != null) _detail(sel),
          const SizedBox(height: 8),
        ]),
      ),
    ]);
  }

  Widget _card(ArtCreation c) {
    final on = c.id == _sel;
    return M1Press(
      onTap: () => setState(() => _sel = c.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: m1Cream,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: on ? m1Purple : m1Line, width: on ? 3.5 : 2),
          boxShadow: [if (on) BoxShadow(color: m1Purple.withOpacity(0.35), blurRadius: 12)],
        ),
        child: Column(children: [
          Expanded(child: Center(child: LayoutBuilder(builder: (_, k) => FittedBox(child: ArtThumb(creation: c, width: k.maxWidth))))),
          const SizedBox(height: 4),
          FittedBox(child: Text(c.name, style: m1Text(15))),
        ]),
      ),
    );
  }

  Widget _newCard() => M1Press(
        onTap: _newOne,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFB9A2E6), width: 2),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.add_circle_outline_rounded, color: m1Purple, size: 54),
            const SizedBox(height: 6),
            Text(m1T(context, 'art_new'), style: m1Text(15, color: m1Purple)),
          ]),
        ),
      );

  Widget _detail(ArtCreation c) {
    Widget btn(String label, Color col, IconData ic, VoidCallback tap) => Expanded(
          child: M1Press(
            onTap: tap,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(14)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(ic, color: Colors.white, size: 18),
                const SizedBox(width: 4),
                Flexible(child: FittedBox(child: Text(label, style: m1Text(13, color: Colors.white)))),
              ]),
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: M1Card(
        radius: 20,
        rim: const Color(0xFFB98CFF),
        padding: const EdgeInsets.all(8),
        child: Row(children: [
          SizedBox(width: 90, child: FittedBox(child: ArtThumb(creation: c, width: 160))),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: m1Text(17, color: m1Purple)),
              const SizedBox(height: 6),
              Row(children: [
                btn(m1T(context, 'art_open'), m1Purple, Icons.folder_open_rounded, () => _open(c)),
                btn(m1T(context, 'art_rename_s'), m1Orange, Icons.text_fields_rounded, () => _rename(c)),
                btn(m1T(context, 'art_delete'), m1Red, Icons.delete_rounded, () => _delete(c)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
