import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../widgets/KidScene/kid_scene.dart';
import 'magic_paint_data.dart';
import 'magic_paint_widgets.dart';

/// Dessiner: free drawing on a white page.
class MpDrawTab extends StatefulWidget {
  final double scale;
  final Animation<double> idle;
  final void Function(String key) onSound;
  final Future<void> Function({required bool firstFinish}) onFinished;
  const MpDrawTab({super.key, required this.scale, required this.idle, required this.onSound, required this.onFinished});

  @override
  State<MpDrawTab> createState() => MpDrawTabState();
}

class MpDrawTabState extends State<MpDrawTab> {
  final List<MpStroke> _strokes = [];
  final List<MpStroke> _redo = [];
  MpStroke? _current;
  MpTool _tool = MpTool.pencil;
  int _size = 1;
  Color _color = mpColors[5];
  MpCreation? _creation;
  bool _dirty = false;
  int _tick = 0;
  String? _say;

  bool get hasWork => _strokes.isNotEmpty;

  Future<ui.Image> _render() {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    _paintPage(c, _strokes, null);
    return rec.endRecording().toImage(mpDrawSize.width.toInt(), mpDrawSize.height.toInt());
  }

  static void _paintPage(Canvas c, List<MpStroke> strokes, MpStroke? cur) {
    c.drawRect(Offset.zero & mpDrawSize, Paint()..color = Colors.white);
    mpPaintStrokes(c, mpDrawSize, [...strokes, if (cur != null) cur]);
  }

  Future<bool> _save({required bool done}) async {
    if (!hasWork) return false;
    final img = await _render();
    if (!mounted) return false;
    final all = await MpStore.list();
    final n = all.where((x) => x.kind == 'draw').length + 1;
    final c = _creation ?? MpCreation(id: MpStore.newId(), kind: 'draw', title: '${mpText(context, 'myDrawing')} $n', updated: 0);
    final first = done && !c.done;
    c
      ..done = done
      ..updated = DateTime.now().millisecondsSinceEpoch;
    await MpStore.save(c, MpWork(const {}, List.of(_strokes)), img);
    _creation = c;
    _dirty = false;
    return first;
  }

  Future<void> autosave() async {
    if (_dirty && hasWork) await _save(done: _creation?.done ?? false);
  }

  Future<void> saveDone() async {
    if (!hasWork) {
      setState(() => _say = mpText(context, 'yourTurn'));
      return;
    }
    final first = await _save(done: true);
    if (!mounted) return;
    setState(() => _say = mpText(context, 'saved'));
    await widget.onFinished(firstFinish: first);
  }

  Future<void> newPage() async {
    await autosave();
    if (!mounted) return;
    setState(() {
      _strokes.clear();
      _redo.clear();
      _creation = null;
      _dirty = false;
      _say = null;
      _tick++;
    });
  }

  Future<void> openCreation(MpCreation c) async {
    await autosave();
    final w = await MpStore.work(c.id);
    if (!mounted) return;
    setState(() {
      _strokes
        ..clear()
        ..addAll(w?.strokes ?? const []);
      _redo.clear();
      _creation = c;
      _dirty = false;
      _tick++;
    });
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    widget.onSound('clickButton');
    setState(() {
      _redo.add(_strokes.removeLast());
      _dirty = true;
      _tick++;
    });
  }

  void _redoOne() {
    if (_redo.isEmpty) return;
    widget.onSound('clickButton');
    setState(() {
      _strokes.add(_redo.removeLast());
      _dirty = true;
      _tick++;
    });
  }

  double get _width => mpDrawSizes[_size] * (_tool == MpTool.star ? 1.6 : 1);

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    return Column(children: [
      Expanded(
        child: Column(children: [
          MpBanner(scale: s, title: mpText(context, 'imagine'), height: 48),
          Expanded(
            child: Transform.translate(
              offset: Offset(0, -10 * s),
              child: MpEasel(image: mpImgEaselWide, aspect: mpWideAspect, paper: mpWidePaper, child: _canvas(s)),
            ),
          ),
        ]),
      ),
      _panel(s),
      SizedBox(height: 8 * s),
      Row(children: [
        Expanded(
          flex: 12,
          child: MpOrangeButton(scale: s, label: mpText(context, 'save'), icon: Image.asset(mpImgSave), onTap: saveDone),
        ),
        SizedBox(width: 10 * s),
        Expanded(
          flex: 8,
          child: MpCreamButton(
            scale: s,
            label: mpText(context, 'new'),
            icon: Image.asset(mpImgNew),
            onTap: () {
              widget.onSound('clickButton');
              newPage();
            },
          ),
        ),
      ]),
    ]);
  }

  Widget _canvas(double s) {
    return LayoutBuilder(builder: (context, c) {
      final fit = min(c.maxWidth / mpDrawSize.width, c.maxHeight / mpDrawSize.height);
      final cw = mpDrawSize.width * fit, ch = mpDrawSize.height * fit;
      Offset toPage(Offset p) => Offset(p.dx / fit, p.dy / fit);
      return Stack(clipBehavior: Clip.none, children: [
        Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (d) => setState(() => _current = MpStroke(_tool, _color.value, _width, [toPage(d.localPosition)])),
            onPanUpdate: (d) {
              final cur = _current;
              if (cur == null) return;
              final p = toPage(d.localPosition);
              if ((p - cur.points.last).distance < 1.5) return;
              setState(() => cur.points.add(p));
            },
            onPanEnd: (_) {
              final cur = _current;
              if (cur == null) return;
              setState(() {
                _strokes.add(cur);
                _redo.clear();
                _current = null;
                _dirty = true;
                _tick++;
                _say = null;
              });
            },
            onTapUp: (d) {
              setState(() {
                _strokes.add(MpStroke(_tool, _color.value, _width, [toPage(d.localPosition)]));
                _redo.clear();
                _dirty = true;
                _tick++;
              });
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6 * s),
              child: CustomPaint(size: Size(cw, ch), painter: _DrawPainter(_strokes, _current, _tick, _current?.points.length ?? 0)),
            ),
          ),
        ),
        PositionedDirectional(
          start: -12 * s,
          bottom: -10 * s,
          child: MpRoundButton(size: 48 * s, onTap: _strokes.isEmpty ? null : _undo, child: Icon(Icons.undo_rounded, color: mpPurple, size: 28 * s)),
        ),
        PositionedDirectional(
          end: -12 * s,
          bottom: -10 * s,
          child: MpRoundButton(size: 48 * s, onTap: _redo.isEmpty ? null : _redoOne, child: Icon(Icons.redo_rounded, color: const Color(0xFF9E8F86), size: 28 * s)),
        ),
      ]);
    });
  }

  Widget _panel(double s) {
    final tools = [
      (MpTool.pencil, mpImgPencil),
      (MpTool.brush, mpImgBrush),
      (MpTool.crayon, mpImgCrayon),
      (MpTool.eraser, mpImgEraser),
      (MpTool.star, mpImgStarTool),
    ];
    return Stack(clipBehavior: Clip.none, children: [
      Container(
        padding: EdgeInsets.fromLTRB(8 * s, 8 * s, 8 * s, 6 * s),
        decoration: mpCard(s, radius: 26),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            for (final t in tools)
              MpToolButton(
                size: 54 * s,
                image: t.$2,
                round: true,
                selected: _tool == t.$1,
                onTap: () {
                  widget.onSound('clickButton');
                  setState(() => _tool = t.$1);
                },
              ),
          ]),
          Divider(height: 12 * s, color: mpCreamEdge),
          Row(children: [
            SizedBox(width: 10 * s),
            Text(mpText(context, 'size'), style: mpTitle(16 * s)),
            Container(width: 1.5 * s, height: 26 * s, margin: EdgeInsets.symmetric(horizontal: 12 * s), color: mpCreamEdge),
            for (var i = 0; i < 3; i++) ...[
              KidPressable(
                onTap: () {
                  widget.onSound('clickButton');
                  setState(() => _size = i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 40 * s,
                  height: 40 * s,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _size == i ? const Color(0xFFDDF9FF) : mpCream,
                    border: Border.all(color: _size == i ? mpCyan : Colors.white, width: 2.5 * s),
                    boxShadow: [if (_size == i) BoxShadow(color: mpCyan.withOpacity(0.55), blurRadius: 8 * s)],
                  ),
                  child: Container(
                    width: [7.0, 14.0, 22.0][i] * s,
                    height: [7.0, 14.0, 22.0][i] * s,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: _tool == MpTool.eraser ? const Color(0xFF9E9E9E) : (_color.value == 0xFFFFFFFF ? mpCreamEdge : _color)),
                  ),
                ),
              ),
              SizedBox(width: 10 * s),
            ],
          ]),
          SizedBox(height: 4 * s),
          Padding(
            padding: EdgeInsetsDirectional.only(end: 64 * s),
            child: MpColorRow(scale: s, selected: _color, onPick: (c) {
              widget.onSound('clickButton');
              setState(() {
                _color = c;
                if (_tool == MpTool.eraser) _tool = MpTool.pencil;
              });
            }),
          ),
        ]),
      ),
      PositionedDirectional(
        end: -10 * s,
        bottom: -18 * s,
        child: IgnorePointer(
          child: MpRobotTalk(scale: s, image: mpImgRobotSmall, text: _say ?? mpText(context, 'yourTurn'), idle: widget.idle, height: 112),
        ),
      ),
    ]);
  }
}

class _DrawPainter extends CustomPainter {
  final List<MpStroke> strokes;
  final MpStroke? current;
  final int tick, curLen;
  _DrawPainter(this.strokes, this.current, this.tick, this.curLen);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / mpDrawSize.width, size.height / mpDrawSize.height);
    MpDrawTabState._paintPage(canvas, strokes, current);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DrawPainter o) => o.tick != tick || o.curLen != curLen || o.current != current;
}
