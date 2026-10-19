import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';

import 'piano_forte_data.dart';
import 'piano_forte_widgets.dart';

/// Shared shell: cream sheet with a golden rim, an icon sitting on its top
/// edge and the round orange ✕.
class _SheetShell extends StatelessWidget {
  final double s;
  final String topIcon;
  final double topIconAspect; // height / width
  final Widget child;
  final VoidCallback onClose;
  final Widget? cornerArt;
  const _SheetShell({
    required this.s,
    required this.topIcon,
    required this.topIconAspect,
    required this.child,
    required this.onClose,
    this.cornerArt,
  });

  @override
  Widget build(BuildContext context) {
    final iconW = 118 * s;
    final iconH = iconW * topIconAspect;
    return Stack(clipBehavior: Clip.none, children: [
      Container(
        margin: EdgeInsets.only(top: iconH * 0.55),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34 * s),
          gradient: const LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFFBF2), Color(0xFFFFF1D8)]),
          border: Border.all(color: pfGold, width: 3.5 * s),
          boxShadow: [BoxShadow(color: KidColors.purpleDeep.withOpacity(0.35), blurRadius: 30, offset: const Offset(0, 12))],
        ),
        padding: EdgeInsets.fromLTRB(14 * s, iconH * 0.5 + 4 * s, 14 * s, 14 * s),
        child: child,
      ),
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Center(child: Image.asset(topIcon, width: iconW, height: iconH, fit: BoxFit.contain)),
      ),
      PositionedDirectional(
        top: iconH * 0.55 - 14 * s,
        end: -10 * s,
        child: PfSpriteButton(asset: pfImgClose, size: 54 * s, onTap: onClose, label: MaterialLocalizations.of(context).closeButtonLabel),
      ),
      if (cornerArt != null) cornerArt!,
    ]);
  }
}

/// Segmented cream tabs with a purple pill on the selected one.
class _Tabs extends StatelessWidget {
  final double s;
  final List<Widget> items;
  final int index;
  final ValueChanged<int> onTap;
  const _Tabs({required this.s, required this.items, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
        height: 48 * s,
        padding: EdgeInsets.all(4 * s),
        decoration: pfPanel(28 * s, shadow: 0.1),
        child: Row(children: [
          for (int i = 0; i < items.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: EdgeInsets.symmetric(horizontal: 2 * s),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24 * s),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: i == index
                          ? const [Color(0xFF8B5CF6), Color(0xFF5B21D6)]
                          : const [Color(0x00FFFFFF), Color(0x00FFFFFF)],
                    ),
                  ),
                  child: DefaultTextStyle.merge(
                    style: pfBody(16 * s, color: i == index ? Colors.white : pfInk, weight: FontWeight.w700),
                    child: FittedBox(fit: BoxFit.scaleDown, child: items[i]),
                  ),
                ),
              ),
            ),
        ]),
      );
}

Widget _levelChip(BuildContext context, double s, PfLevel level) {
  final easy = level == PfLevel.easy;
  return Container(
    padding: EdgeInsetsDirectional.fromSTEB(6 * s, 3 * s, 10 * s, 3 * s),
    decoration: BoxDecoration(
      color: easy ? const Color(0xFFDFF5D3) : const Color(0xFFFFF0C8),
      borderRadius: BorderRadius.circular(14 * s),
      border: Border.all(color: easy ? const Color(0xFFB7E3A2) : const Color(0xFFF3D48A)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Image.asset(easy ? pfImgLeaf : pfImgStar, width: 18 * s, height: 18 * s),
      SizedBox(width: 4 * s),
      Text(pfText(context, easy ? 'easy' : 'medium'),
          style: pfBody(13 * s, color: easy ? const Color(0xFF2E8B2E) : const Color(0xFFB4690E), weight: FontWeight.w700)),
    ]),
  );
}

Widget _dots(double s, double value, PfLevel level) {
  final n = (value * 6).round().clamp(0, 6);
  final on = level == PfLevel.easy ? pfGreen : const Color(0xFFFFC21A);
  return Row(mainAxisSize: MainAxisSize.min, children: [
    for (int i = 0; i < 6; i++)
      Container(
        width: 15 * s,
        height: 15 * s,
        margin: EdgeInsetsDirectional.only(end: 4 * s),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: i < n ? on : const Color(0xFFDCDCDC),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 2, offset: Offset(0, 1))],
        ),
      ),
  ]);
}

/// "Choisis ta chanson" — returns the chosen song id (or null).
Future<String?> pfShowSongPicker(
  BuildContext context, {
  required String currentId,
  required Map<String, double> bests,
  required void Function(PfSong song) onPreview,
  required VoidCallback onStopPreview,
}) {
  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: KidColors.purpleDeep.withOpacity(0.35),
    transitionDuration: const Duration(milliseconds: 320),
    transitionBuilder: (_, a, __, child) => FadeTransition(
      opacity: a,
      child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOutBack)), child: child),
    ),
    pageBuilder: (ctx, _, __) => _SongPicker(currentId: currentId, bests: bests, onPreview: onPreview, onStopPreview: onStopPreview),
  ).whenComplete(onStopPreview);
}

class _SongPicker extends StatefulWidget {
  final String currentId;
  final Map<String, double> bests;
  final void Function(PfSong song) onPreview;
  final VoidCallback onStopPreview;
  const _SongPicker({required this.currentId, required this.bests, required this.onPreview, required this.onStopPreview});

  @override
  State<_SongPicker> createState() => _SongPickerState();
}

class _SongPickerState extends State<_SongPicker> {
  int _filter = 0; // 0 all · 1 easy · 2 medium
  late String _selected = widget.currentId;
  String? _previewing;

  List<PfSong> get _shown => switch (_filter) {
        1 => pfSongs.where((x) => x.level == PfLevel.easy).toList(),
        2 => pfSongs.where((x) => x.level == PfLevel.medium).toList(),
        _ => pfSongs,
      };

  void _preview(PfSong song) {
    if (_previewing == song.id) {
      widget.onStopPreview();
      setState(() => _previewing = null);
      return;
    }
    widget.onPreview(song);
    setState(() {
      _previewing = song.id;
      _selected = song.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = min(size.width - 28, 520.0);
    final s = min(w / 360, size.height / 760).clamp(0.72, 1.3).toDouble();
    final sel = pfSongById(_selected);
    return SafeArea(
      child: Center(
        child: SizedBox(
          width: w,
          height: min(size.height * 0.92, 760 * s),
          child: Material(
            type: MaterialType.transparency,
            child: _SheetShell(
              s: s,
              topIcon: pfImgBook,
              topIconAspect: 153 / 218,
              onClose: () => Navigator.pop(context),
              cornerArt: PositionedDirectional(
                start: -18 * s,
                bottom: -18 * s,
                width: 92 * s,
                height: 92 * s * 340 / 296,
                child: IgnorePointer(child: Image.asset(pfImgRobotPoint, fit: BoxFit.contain)),
              ),
              child: Column(children: [
                FittedBox(fit: BoxFit.scaleDown, child: Text(pfText(context, 'pickTitle'), style: pfTitle(30 * s, color: const Color(0xFF3A0E7A)))),
                SizedBox(height: 4 * s),
                Text(pfText(context, 'pickSub'), style: pfBody(16 * s, color: const Color(0xFF6E6787))),
                SizedBox(height: 12 * s),
                _Tabs(
                  s: s,
                  index: _filter,
                  onTap: (i) => setState(() => _filter = i),
                  items: [
                    Text(pfText(context, 'all')),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Image.asset(pfImgLeaf, width: 20 * s, height: 20 * s),
                      SizedBox(width: 5 * s),
                      Text(pfText(context, 'easy')),
                    ]),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Image.asset(pfImgStar, width: 20 * s, height: 20 * s),
                      SizedBox(width: 5 * s),
                      Text(pfText(context, 'medium')),
                    ]),
                  ],
                ),
                SizedBox(height: 10 * s),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(vertical: 4 * s),
                    children: [for (final song in _shown) _row(context, s, song)],
                  ),
                ),
                Container(height: 2, margin: EdgeInsets.symmetric(vertical: 8 * s), color: pfGold.withOpacity(0.6)),
                Padding(
                  padding: EdgeInsetsDirectional.only(start: 62 * s),
                  child: Row(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12 * s),
                      child: Image.asset(sel.art, width: 52 * s, height: 52 * s, fit: BoxFit.cover),
                    ),
                    SizedBox(width: 8 * s),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        FittedBox(fit: BoxFit.scaleDown, child: Text(sel.title(context), maxLines: 1, style: pfTitle(17 * s))),
                        FittedBox(fit: BoxFit.scaleDown, child: Text(pfText(context, 'oneAtATime'), maxLines: 1, style: pfBody(13 * s, color: const Color(0xFF6E6787)))),
                      ]),
                    ),
                    SizedBox(width: 8 * s),
                    KidButton(
                      label: pfText(context, 'go'),
                      onPressed: () => Navigator.pop(context, _selected),
                      width: 130 * s,
                      height: 54 * s,
                      showArrow: false,
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, double s, PfSong song) {
    final on = song.id == _selected;
    final current = song.id == widget.currentId;
    return KidPressable(
      onTap: () => setState(() => _selected = song.id),
      pressedScale: 0.97,
      semanticLabel: song.title(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: EdgeInsets.only(bottom: 10 * s),
        padding: EdgeInsets.all(10 * s),
        decoration: BoxDecoration(
          color: on ? const Color(0xFFE6FCFF) : const Color(0xFFFFF7E8),
          borderRadius: BorderRadius.circular(22 * s),
          border: Border.all(color: on ? pfCyan : const Color(0xFFF0DDBA), width: on ? 3 * s : 2 * s),
          boxShadow: [
            BoxShadow(color: (on ? pfCyan : Colors.black).withOpacity(on ? 0.5 : 0.06), blurRadius: on ? 16 : 6, offset: Offset(0, on ? 0 : 3)),
          ],
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16 * s),
            child: Image.asset(song.art, width: 78 * s, height: 78 * s, fit: BoxFit.cover),
          ),
          SizedBox(width: 12 * s),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FittedBox(fit: BoxFit.scaleDown, child: Text(song.title(context), maxLines: 1, style: pfTitle(19 * s))),
              SizedBox(height: 6 * s),
              Wrap(spacing: 6 * s, runSpacing: 4 * s, children: [
                _levelChip(context, s, song.level),
                if (current)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Image.asset(pfImgCheck, width: 20 * s, height: 20 * s),
                    SizedBox(width: 3 * s),
                    Text(pfText(context, 'current'), style: pfBody(13 * s, color: const Color(0xFF2E8B2E), weight: FontWeight.w700)),
                  ]),
              ]),
              SizedBox(height: 6 * s),
              _dots(s, widget.bests[song.id] ?? 0, song.level),
            ]),
          ),
          SizedBox(width: 6 * s),
          PfSpriteButton(
            asset: pfImgSpeaker,
            size: 54 * s,
            glow: _previewing == song.id,
            label: pfText(context, 'play'),
            onTap: () => _preview(song),
          ),
        ]),
      ),
    );
  }
}

/// "Mes mélodies" — list of saved recordings: play or delete.
Future<void> pfShowMelodies(
  BuildContext context, {
  required List<PfMelody> melodies,
  required void Function(PfMelody m) onPlay,
  required void Function(int index) onDelete,
  required VoidCallback onStop,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: KidColors.purpleDeep.withOpacity(0.35),
    transitionDuration: const Duration(milliseconds: 300),
    transitionBuilder: (_, a, __, child) => FadeTransition(
      opacity: a,
      child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOutBack)), child: child),
    ),
    pageBuilder: (ctx, _, __) => _Melodies(melodies: melodies, onPlay: onPlay, onDelete: onDelete, onStop: onStop),
  ).whenComplete(onStop);
}

class _Melodies extends StatefulWidget {
  final List<PfMelody> melodies;
  final void Function(PfMelody m) onPlay;
  final void Function(int index) onDelete;
  final VoidCallback onStop;
  const _Melodies({required this.melodies, required this.onPlay, required this.onDelete, required this.onStop});

  @override
  State<_Melodies> createState() => _MelodiesState();
}

class _MelodiesState extends State<_Melodies> {
  late final List<PfMelody> _list = List.of(widget.melodies);
  int? _playing;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = min(size.width - 28, 520.0);
    final s = min(w / 360, size.height / 760).clamp(0.72, 1.3).toDouble();
    return SafeArea(
      child: Center(
        child: SizedBox(
          width: w,
          height: min(size.height * 0.8, 620 * s),
          child: Material(
            type: MaterialType.transparency,
            child: _SheetShell(
              s: s,
              topIcon: pfImgFolder,
              topIconAspect: 73 / 81,
              onClose: () => Navigator.pop(context),
              child: Column(children: [
                FittedBox(fit: BoxFit.scaleDown, child: Text(pfText(context, 'myMelodies'), style: pfTitle(28 * s, color: const Color(0xFF3A0E7A)))),
                SizedBox(height: 12 * s),
                Expanded(
                  child: _list.isEmpty
                      ? Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Image.asset(pfImgRobotPoint, height: 130 * s),
                            SizedBox(height: 10 * s),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 18 * s),
                              child: Text(pfText(context, 'noMelodies'), textAlign: TextAlign.center, style: pfBody(16 * s)),
                            ),
                          ]),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: _list.length,
                          itemBuilder: (_, i) => _row(context, s, i),
                        ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, double s, int i) {
    final m = _list[i];
    final on = _playing == i;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: EdgeInsets.only(bottom: 10 * s),
      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 8 * s),
      decoration: BoxDecoration(
        color: on ? const Color(0xFFE6FCFF) : const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(20 * s),
        border: Border.all(color: on ? pfCyan : const Color(0xFFF0DDBA), width: on ? 3 * s : 2 * s),
      ),
      child: Row(children: [
        Image.asset(pfInstrumentArt(m.instrument), width: 56 * s, height: 46 * s, fit: BoxFit.contain),
        SizedBox(width: 10 * s),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FittedBox(fit: BoxFit.scaleDown, child: Text(m.name, maxLines: 1, style: pfTitle(18 * s))),
            SizedBox(height: 2 * s),
            Text('${pfText(context, 'noteCount').replaceAll('{N}', '${m.keys.length}')} · ${(m.durationMs / 1000).toStringAsFixed(1)} s',
                style: pfBody(13 * s, color: const Color(0xFF6E6787))),
          ]),
        ),
        PfSpriteButton(
          asset: pfImgSpeaker,
          size: 50 * s,
          glow: on,
          label: pfText(context, 'play'),
          onTap: () {
            if (on) {
              widget.onStop();
              setState(() => _playing = null);
            } else {
              widget.onPlay(m);
              setState(() => _playing = i);
              Future.delayed(Duration(milliseconds: m.durationMs), () {
                if (mounted && _playing == i) setState(() => _playing = null);
              });
            }
          },
        ),
        SizedBox(width: 6 * s),
        PfSpriteButton(
          asset: pfImgClose,
          size: 36 * s,
          label: pfText(context, 'clear'),
          onTap: () {
            widget.onStop();
            widget.onDelete(i);
            setState(() {
              _list.removeAt(i);
              _playing = null;
            });
          },
        ),
      ]),
    );
  }
}
