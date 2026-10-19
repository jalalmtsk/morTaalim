import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../widgets/KidScene/kid_scene.dart';
import 'magic_paint_data.dart';
import 'magic_paint_widgets.dart';

// ── engine: region map + fills ─────────────────────────────────────────────

class MpColoringEngine {
  final MpPage page;
  final int w, h;
  final Int32List _order; // pixel indexes grouped by region
  final Int32List _start; // _start[r] .. _start[r+1]
  final Int32List _ids; // region per pixel
  final Uint8List _rgba;
  final ui.Image lines;
  final Map<int, int> fills = {};
  ui.Image? image;

  MpColoringEngine._(this.page, this.w, this.h, this._order, this._start, this._ids, this._rgba, this.lines);

  static Future<ui.Image> _decode(String asset) async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    return (await codec.getNextFrame()).image;
  }

  static Future<MpColoringEngine> load(MpPage page) async {
    final mapImg = await _decode(page.map);
    final lines = await _decode(page.lines);
    final w = mapImg.width, h = mapImg.height;
    final bd = (await mapImg.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final px = bd.buffer.asUint8List();
    final n = w * h;
    final regions = page.modelColors.length;
    final ids = Int32List(n);
    final counts = Int32List(regions + 2);
    for (var i = 0; i < n; i++) {
      var r = px[i * 4] * 256 + px[i * 4 + 1];
      if (r > regions) r = 0;
      ids[i] = r;
      counts[r]++;
    }
    final start = Int32List(regions + 2);
    for (var r = 1; r <= regions + 1; r++) {
      start[r] = start[r - 1] + counts[r - 1];
    }
    final fillPos = Int32List.fromList(start);
    final order = Int32List(n);
    for (var i = 0; i < n; i++) {
      order[fillPos[ids[i]]++] = i;
    }
    final rgba = Uint8List(n * 4)..fillRange(0, n * 4, 255);
    final e = MpColoringEngine._(page, w, h, order, start, ids, rgba, lines);
    await e.rebuild();
    return e;
  }

  int regionAt(Offset p) {
    final x = p.dx.floor(), y = p.dy.floor();
    if (x < 0 || y < 0 || x >= w || y >= h) return 0;
    return _ids[y * w + x];
  }

  int modelColor(int region) => region >= 1 && region <= page.modelColors.length ? page.modelColors[region - 1] : 0xFFFFFFFF;

  /// Sets (or clears with null) a region's colour. Call [rebuild] afterwards.
  void setFill(int region, int? color) {
    if (region <= 0 || region >= _start.length - 1) return;
    if (color == null) {
      fills.remove(region);
    } else {
      fills[region] = color;
    }
    final c = color ?? 0xFFFFFFFF;
    final r = (c >> 16) & 255, g = (c >> 8) & 255, b = c & 255;
    for (var k = _start[region]; k < _start[region + 1]; k++) {
      final o = _order[k] * 4;
      _rgba[o] = r;
      _rgba[o + 1] = g;
      _rgba[o + 2] = b;
      _rgba[o + 3] = 255;
    }
  }

  Future<void> rebuild() {
    final done = Completer<void>();
    ui.decodeImageFromPixels(_rgba, w, h, ui.PixelFormat.rgba8888, (img) {
      image = img;
      done.complete();
    });
    return done.future;
  }

  /// Final picture at full size.
  Future<ui.Image> render(List<MpStroke> strokes) async {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    paint(c, strokes, null);
    return rec.endRecording().toImage(w, h);
  }

  void paint(Canvas c, List<MpStroke> strokes, MpStroke? current) {
    final size = Size(w.toDouble(), h.toDouble());
    c.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    if (image != null) c.drawImage(image!, Offset.zero, Paint()..filterQuality = FilterQuality.medium);
    mpPaintStrokes(c, size, [...strokes, if (current != null) current]);
    c.drawImage(lines, Offset.zero, Paint()..filterQuality = FilterQuality.medium);
  }
}

// ── history ────────────────────────────────────────────────────────────────

abstract class _Op {}

class _FillOp extends _Op {
  final int region;
  final int? before, after;
  _FillOp(this.region, this.before, this.after);
}

class _StrokeOp extends _Op {
  final MpStroke stroke;
  _StrokeOp(this.stroke);
}

class _FillsOp extends _Op {
  final Map<int, int?> before, after;
  _FillsOp(this.before, this.after);
}

// ── Colorier tab ───────────────────────────────────────────────────────────

class MpColorTab extends StatefulWidget {
  final double scale;
  final Animation<double> idle;
  final bool showModel;
  final VoidCallback onGallery;
  final void Function(String key) onSound;
  final Future<void> Function({required bool firstFinish}) onFinished;
  const MpColorTab({
    super.key,
    required this.scale,
    required this.idle,
    required this.showModel,
    required this.onGallery,
    required this.onSound,
    required this.onFinished,
  });

  @override
  State<MpColorTab> createState() => MpColorTabState();
}

class MpColorTabState extends State<MpColorTab> with TickerProviderStateMixin {
  MpPage _page = mpPages.first;
  MpColoringEngine? _engine;
  MpCreation? _creation;
  bool _dirty = false;
  bool _loading = true;

  MpColorTool _tool = MpColorTool.bucket;
  Color _color = mpColors[6];
  final List<MpStroke> _strokes = [];
  MpStroke? _current;
  final List<_Op> _undo = [], _redo = [];
  int _paintTick = 0;

  String? _robotText;
  Timer? _robotTimer;

  // sparkle burst for the wand / bucket
  late final AnimationController _burst = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  Offset? _burstAt; // in canvas widget coords
  Color _burstColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _open(mpPages.first);
  }

  @override
  void dispose() {
    _robotTimer?.cancel();
    _burst.dispose();
    super.dispose();
  }

  bool get hasWork => _engine != null && (_engine!.fills.isNotEmpty || _strokes.isNotEmpty);

  Future<void> _open(MpPage page, {MpCreation? creation, MpWork? work}) async {
    setState(() {
      _loading = true;
      _page = page;
    });
    final e = await MpColoringEngine.load(page);
    if (work != null) {
      for (final f in work.fills.entries) {
        e.setFill(f.key, f.value);
      }
      await e.rebuild();
    }
    if (!mounted) return;
    setState(() {
      _engine = e;
      _creation = creation;
      _strokes
        ..clear()
        ..addAll(work?.strokes ?? const []);
      _undo.clear();
      _redo.clear();
      _dirty = false;
      _loading = false;
      _paintTick++;
    });
  }

  /// Opens a page fresh (after saving the current work).
  Future<void> openPage(String pageId) async {
    await autosave();
    final p = mpPageById(pageId);
    if (p != null) await _open(p);
  }

  /// Continues a saved coloring.
  Future<void> openCreation(MpCreation c) async {
    await autosave();
    final p = mpPageById(c.page);
    if (p == null) return;
    final w = await MpStore.work(c.id);
    await _open(p, creation: c, work: w);
  }

  /// Saves unsaved changes as "En cours".
  Future<void> autosave() async {
    if (!_dirty || !hasWork) return;
    await _save(done: _creation?.done ?? false);
  }

  Future<bool> _save({required bool done}) async {
    final e = _engine;
    if (e == null) return false;
    final img = await e.render(_strokes);
    final c = _creation ??
        MpCreation(id: MpStore.newId(), kind: 'color', page: _page.id, title: _page.title(context), updated: 0);
    final first = done && !c.done;
    c
      ..done = done
      ..updated = DateTime.now().millisecondsSinceEpoch;
    await MpStore.save(c, MpWork(Map.of(e.fills), List.of(_strokes)), img);
    _creation = c;
    _dirty = false;
    return first;
  }

  Future<void> finish() async {
    if (!hasWork) {
      _say('🎨');
      return;
    }
    final first = await _save(done: true);
    _say(mpText(context, 'bravo'));
    await widget.onFinished(firstFinish: first);
  }

  void _say(String t) {
    _robotTimer?.cancel();
    setState(() => _robotText = t);
    _robotTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _robotText = null);
    });
  }

  // ── actions ─────────────────────────────────────────────────────────────

  Future<void> _fill(int region, int? color, Offset at, Color burst) async {
    final e = _engine;
    if (e == null || region <= 0) return;
    final before = e.fills[region];
    if (before == color) return;
    e.setFill(region, color);
    _undo.add(_FillOp(region, before, color));
    _redo.clear();
    _dirty = true;
    await e.rebuild();
    if (!mounted) return;
    setState(() {
      _paintTick++;
      _burstAt = at;
      _burstColor = burst;
    });
    _burst.forward(from: 0);
  }

  void _magicAll() async {
    // long-press with the wand: the whole picture like the model
    final e = _engine;
    if (e == null) return;
    final before = <int, int?>{};
    final after = <int, int?>{};
    for (var r = 1; r <= _page.modelColors.length; r++) {
      final m = e.modelColor(r);
      if (e.fills[r] != m) {
        before[r] = e.fills[r];
        after[r] = m;
        e.setFill(r, m);
      }
    }
    if (after.isEmpty) return;
    _undo.add(_FillsOp(before, after));
    _redo.clear();
    _dirty = true;
    await e.rebuild();
    if (!mounted) return;
    setState(() => _paintTick++);
    widget.onSound('starSound');
    _say(mpText(context, 'magic'));
  }

  Future<void> _applyOp(_Op op, {required bool undo}) async {
    final e = _engine;
    if (e == null) return;
    if (op is _FillOp) {
      e.setFill(op.region, undo ? op.before : op.after);
      await e.rebuild();
    } else if (op is _FillsOp) {
      final m = undo ? op.before : op.after;
      for (final x in m.entries) {
        e.setFill(x.key, x.value);
      }
      await e.rebuild();
    } else if (op is _StrokeOp) {
      if (undo) {
        _strokes.remove(op.stroke);
      } else {
        _strokes.add(op.stroke);
      }
    }
    _dirty = true;
    if (mounted) setState(() => _paintTick++);
  }

  void _doUndo() {
    if (_undo.isEmpty) return;
    widget.onSound('clickButton');
    final op = _undo.removeLast();
    _redo.add(op);
    _applyOp(op, undo: true);
  }

  void _doRedo() {
    if (_redo.isEmpty) return;
    widget.onSound('clickButton');
    final op = _redo.removeLast();
    _undo.add(op);
    _applyOp(op, undo: false);
  }

  Future<void> _pickPage() async {
    widget.onSound('clickButton');
    final id = await mpPickPage(context);
    if (id != null) await openPage(id);
  }

  void _zoomModel() {
    widget.onSound('clickButton');
    showDialog<void>(
      context: context,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.of(ctx).pop(),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(10),
            decoration: mpCard(1, radius: 26, border: const Color(0xFFFFE08A)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(mpText(context, 'model'), style: mpTitle(22, color: mpPurple)),
              const SizedBox(height: 8),
              ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset(_page.model, fit: BoxFit.contain)),
            ]),
          ),
        ),
      ),
    );
  }

  String _hint(BuildContext c) {
    switch (_tool) {
      case MpColorTool.wand:
        return mpText(c, 'tapMagic');
      case MpColorTool.brush:
        return mpText(c, 'tapBrush');
      case MpColorTool.eraser:
        return mpText(c, 'tapEraser');
      case MpColorTool.bucket:
        return mpText(c, 'tapZone');
    }
  }

  // ── build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    return Column(children: [
      MpHint(scale: s, icon: _tool == MpColorTool.wand ? Icons.auto_awesome_rounded : Icons.touch_app_rounded, text: _hint(context)),
      SizedBox(height: 4 * s),
      Expanded(child: _easel(s)),
      SizedBox(height: 4 * s),
      _tools(s),
      SizedBox(height: 6 * s),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 4 * s),
        decoration: mpCard(s, radius: 30),
        child: MpColorRow(scale: s, selected: _color, onPick: (c) {
          widget.onSound('clickButton');
          setState(() {
            _color = c;
            if (_tool == MpColorTool.eraser || _tool == MpColorTool.wand) _tool = MpColorTool.bucket;
          });
        }),
      ),
      SizedBox(height: 8 * s),
      Row(children: [
        Expanded(
          flex: 12,
          child: MpOrangeButton(
            scale: s,
            label: mpText(context, 'finish'),
            icon: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
            onTap: finish,
          ),
        ),
        SizedBox(width: 10 * s),
        Expanded(
          flex: 7,
          child: MpCreamButton(scale: s, label: mpText(context, 'gallery'), icon: Image.asset(mpImgFolder), onTap: widget.onGallery),
        ),
      ]),
    ]);
  }

  Widget _easel(double s) {
    return LayoutBuilder(builder: (context, c) {
      return Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(
          child: MpEasel(
            image: mpImgEaselTall,
            aspect: mpTallAspect,
            paper: mpTallPaper,
            child: _loading || _engine == null
                ? const Center(child: CircularProgressIndicator(color: mpPurple))
                : _canvas(s),
            overlays: const [],
          ),
        ),
        // robot peeking on the side of the easel
        PositionedDirectional(
          end: -14 * s,
          top: c.maxHeight * 0.38,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: widget.idle,
              builder: (_, ch) => Transform.translate(offset: Offset(sin(widget.idle.value * 2 * pi) * 4 * s, 0), child: ch),
              child: Stack(clipBehavior: Clip.none, children: [
                Image.asset(mpImgRobotSwirl, height: 150 * s),
                if (_robotText != null)
                  Positioned(
                    top: -34 * s,
                    left: -10 * s,
                    child: SizedBox(
                      width: 90 * s,
                      height: 56 * s,
                      child: Stack(alignment: Alignment.center, children: [
                        Positioned.fill(child: Image.asset(mpImgBubble, fit: BoxFit.fill)),
                        Padding(
                          padding: EdgeInsets.only(bottom: 12 * s),
                          child: FittedBox(fit: BoxFit.scaleDown, child: Text(_robotText!, style: mpTitle(16 * s))),
                        ),
                      ]),
                    ),
                  ),
              ]),
            ),
          ),
        ),
      ]);
    });
  }

  Widget _canvas(double s) {
    final e = _engine!;
    return LayoutBuilder(builder: (context, c) {
      // fit the page inside the paper
      final fit = min(c.maxWidth / e.w, c.maxHeight / e.h);
      final cw = e.w * fit, ch = e.h * fit;
      Offset toImg(Offset p) => Offset(p.dx / fit, p.dy / fit);
      final modelW = min(cw * 0.34, 120 * s);
      return Stack(clipBehavior: Clip.none, children: [
        Center(
          child: SizedBox(
            width: cw,
            height: ch,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) {
                final p = toImg(d.localPosition);
                final region = e.regionAt(p);
                switch (_tool) {
                  case MpColorTool.bucket:
                    widget.onSound('PopClick');
                    _fill(region, _color.value, d.localPosition, _color);
                    break;
                  case MpColorTool.wand:
                    widget.onSound('PopButton');
                    final m = e.modelColor(region);
                    _fill(region, m, d.localPosition, Color(m));
                    break;
                  case MpColorTool.eraser:
                    widget.onSound('PopClick');
                    _fill(region, null, d.localPosition, Colors.white);
                    break;
                  case MpColorTool.brush:
                    _addStroke(MpStroke(MpTool.brush, _color.value, 11, [p]));
                    break;
                }
              },
              onLongPress: _tool == MpColorTool.wand ? _magicAll : null,
              onPanStart: _tool == MpColorTool.brush || _tool == MpColorTool.eraser
                  ? (d) => setState(() => _current = MpStroke(
                      _tool == MpColorTool.brush ? MpTool.brush : MpTool.eraser, _color.value, _tool == MpColorTool.brush ? 11 : 14, [toImg(d.localPosition)]))
                  : null,
              onPanUpdate: _tool == MpColorTool.brush || _tool == MpColorTool.eraser
                  ? (d) {
                      final cur = _current;
                      if (cur == null) return;
                      final p = toImg(d.localPosition);
                      if ((p - cur.points.last).distance < 1.5) return;
                      setState(() => cur.points.add(p));
                    }
                  : null,
              onPanEnd: _tool == MpColorTool.brush || _tool == MpColorTool.eraser
                  ? (_) {
                      final cur = _current;
                      _current = null;
                      if (cur != null) _addStroke(cur);
                    }
                  : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6 * s),
                child: CustomPaint(
                  size: Size(cw, ch),
                  painter: _ColoringPainter(e, _strokes, _current, _paintTick, _current?.points.length ?? 0),
                ),
              ),
            ),
          ),
        ),
        // sparkle burst
        if (_burstAt != null)
          Positioned(
            left: (c.maxWidth - cw) / 2,
            top: (c.maxHeight - ch) / 2,
            width: cw,
            height: ch,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _burst,
                builder: (_, __) => CustomPaint(painter: _BurstPainter(_burstAt!, _burst.value, _burstColor, s)),
              ),
            ),
          ),
        // change picture
        PositionedDirectional(
          start: 4 * s,
          top: 4 * s,
          child: MpRoundButton(size: 40 * s, onTap: _pickPage, child: Icon(Icons.grid_view_rounded, color: mpPurple, size: 22 * s)),
        ),
        // model card
        if (widget.showModel)
          PositionedDirectional(
            end: -modelW * 0.12,
            top: -14 * s,
            child: KidPressable(
              onTap: _zoomModel,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(mpText(context, 'model'), style: mpTitle(13 * s, color: mpPurple)),
                SizedBox(height: 2 * s),
                Stack(clipBehavior: Clip.none, children: [
                  Container(
                    width: modelW,
                    padding: EdgeInsets.all(4 * s),
                    decoration: mpCard(s, radius: 14, border: const Color(0xFFFFE08A)),
                    child: ClipRRect(borderRadius: BorderRadius.circular(10 * s), child: Image.asset(_page.model, fit: BoxFit.contain)),
                  ),
                  Positioned(right: -10 * s, top: -10 * s, child: Image.asset(mpImgZoom, width: 32 * s)),
                ]),
              ]),
            ),
          ),
        // undo / redo
        PositionedDirectional(
          start: -10 * s,
          bottom: -8 * s,
          child: MpRoundButton(size: 50 * s, onTap: _undo.isEmpty ? null : _doUndo, child: Icon(Icons.undo_rounded, color: mpPurple, size: 30 * s)),
        ),
        PositionedDirectional(
          end: -10 * s,
          bottom: -8 * s,
          child: MpRoundButton(size: 50 * s, onTap: _redo.isEmpty ? null : _doRedo, child: Icon(Icons.redo_rounded, color: const Color(0xFF9E8F86), size: 30 * s)),
        ),
      ]);
    });
  }

  void _addStroke(MpStroke st) {
    setState(() {
      _strokes.add(st);
      _undo.add(_StrokeOp(st));
      _redo.clear();
      _dirty = true;
      _paintTick++;
    });
  }

  Widget _tools(double s) {
    final items = [
      (MpColorTool.bucket, mpImgBucket),
      (MpColorTool.brush, mpImgBrushIcon),
      (MpColorTool.wand, mpImgWand),
      (MpColorTool.eraser, mpImgEraserIcon),
    ];
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 8 * s),
      decoration: mpCard(s, radius: 26),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        for (final it in items)
          MpToolButton(
            size: 58 * s,
            image: it.$2,
            selected: _tool == it.$1,
            onTap: () {
              widget.onSound('clickButton');
              setState(() => _tool = it.$1);
            },
          ),
      ]),
    );
  }
}

class _ColoringPainter extends CustomPainter {
  final MpColoringEngine e;
  final List<MpStroke> strokes;
  final MpStroke? current;
  final int tick, curLen;
  _ColoringPainter(this.e, this.strokes, this.current, this.tick, this.curLen);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / e.w, size.height / e.h);
    e.paint(canvas, strokes, current);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ColoringPainter o) => o.tick != tick || o.curLen != curLen || o.current != current || o.e != e;
}

class _BurstPainter extends CustomPainter {
  final Offset at;
  final double t;
  final Color color;
  final double s;
  _BurstPainter(this.at, this.t, this.color, this.s);

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final fade = 1 - t;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * s * fade
      ..color = Colors.white.withOpacity(0.9 * fade);
    canvas.drawCircle(at, 10 * s + 40 * s * t, ring);
    final dots = Paint()..color = (color.value == 0xFFFFFFFF ? const Color(0xFFFFD21A) : color).withOpacity(fade);
    final star = Paint()..color = const Color(0xFFFFE066).withOpacity(fade);
    for (var i = 0; i < 8; i++) {
      final a = i * pi / 4 + t * 0.6;
      final r = 14 * s + 46 * s * Curves.easeOut.transform(t);
      final p = at + Offset(cos(a) * r, sin(a) * r);
      if (i.isEven) {
        canvas.drawCircle(p, 4 * s * fade + 1, dots);
      } else {
        final path = Path();
        for (var k = 0; k < 8; k++) {
          final aa = k * pi / 4;
          final rr = k.isEven ? 6 * s * fade + 1 : 2 * s * fade;
          final q = p + Offset(cos(aa) * rr, sin(aa) * rr);
          if (k == 0) {
            path.moveTo(q.dx, q.dy);
          } else {
            path.lineTo(q.dx, q.dy);
          }
        }
        canvas.drawPath(path..close(), star);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter o) => o.t != t || o.at != at;
}
