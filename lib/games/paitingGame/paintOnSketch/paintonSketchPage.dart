import 'dart:ui' as ui;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:provider/provider.dart';

import '../model_logic_page.dart';

// ─────────────────────────────────────────────────────────
//  BRUSH META
// ─────────────────────────────────────────────────────────
class _BrushInfo {
  final BrushType type;
  final IconData icon;
  final String label;
  final Color color;
  const _BrushInfo(this.type, this.icon, this.label, this.color);
}

const _brushes = [
  _BrushInfo(BrushType.normal,  Icons.brush_rounded,      'Normal',  Color(0xFF6C63FF)),
  _BrushInfo(BrushType.dashed,  Icons.more_horiz_rounded, 'Dashes',  Color(0xFFFF6584)),
  _BrushInfo(BrushType.rainbow, Icons.gradient_rounded,   'Rainbow', Color(0xFFFFCC02)),
  _BrushInfo(BrushType.glitter, Icons.auto_awesome,       'Glitter', Color(0xFFFF85A1)),
  _BrushInfo(BrushType.glow,    Icons.flare_rounded,      'Glow',    Color(0xFF00C9FF)),
  _BrushInfo(BrushType.chalk,   Icons.texture_rounded,    'Chalk',   Color(0xFF43E97B)),
];

const _palette = [
  Color(0xFFFF3B3B), Color(0xFFFF7043), Color(0xFFFFD600), Color(0xFF69F0AE),
  Color(0xFF40C4FF), Color(0xFF651FFF), Color(0xFFFF4081), Color(0xFF795548),
  Color(0xFFFF6D00), Color(0xFF1DE9B6), Color(0xFF304FFE), Color(0xFFAA00FF),
  Color(0xFF00E5FF), Color(0xFF76FF03), Color(0xFFFF80AB), Color(0xFF000000),
  Color(0xFF616161), Color(0xFFFFFFFF),
];

// ─────────────────────────────────────────────────────────
//  PAGE
// ─────────────────────────────────────────────────────────
class DrawingOnBackgroundPage extends StatefulWidget {
  final String imageAssetPath;
  const DrawingOnBackgroundPage({required this.imageAssetPath, Key? key})
      : super(key: key);

  @override
  State<DrawingOnBackgroundPage> createState() => _DrawingOnBackgroundPageState();
}

class _DrawingOnBackgroundPageState extends State<DrawingOnBackgroundPage> {
  ui.Image? _bgImage;
  late CanvasController _canvas;

  Color _color = const Color(0xFFFF3B3B);
  double _stroke = 8.0;
  bool _isErasing = false;
  BrushType _brushType = BrushType.normal;

  bool _showBrushPanel = false;
  bool _showColorPanel = false;

  late ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _canvas = CanvasController(backgroundColor: Colors.white);
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    _loadImage();
  }

  Future<void> _loadImage() async {
    final data = await DefaultAssetBundle.of(context).load(widget.imageAssetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    setState(() => _bgImage = frame.image);
  }

  @override
  void dispose() {
    _canvas.dispose();
    _confetti.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails d) {
    _canvas.beginStroke(
      color: _color,
      strokeWidth: _stroke,
      brushType: _brushType,
      isEraser: _isErasing,
      point: d.localPosition,
    );
  }

  void _onPanUpdate(DragUpdateDetails d) => _canvas.addPoint(d.localPosition);
  void _onPanEnd(DragEndDetails _) => _canvas.endStroke();

  void _clear() {
    _canvas.clear();
    _confetti.play();
    Provider.of<AudioManager>(context, listen: false).playEventSound('clickButton');
  }

  // ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_bgImage == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF8F0),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFF6584))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Canvas ──────────────────────────────────
          LayoutBuilder(builder: (ctx, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            _canvas.setSize(size);
            return GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: AnimatedBuilder(
                animation: _canvas,
                builder: (_, __) => CustomPaint(
                  painter: SketchPainter(
                    sketchImage: _bgImage!,
                    cachedPicture: _canvas.cachedPicture,
                    activeStroke: _canvas.activeStroke,
                  ),
                  size: size,
                ),
              ),
            );
          }),

          // ── Confetti ─────────────────────────────────
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 28,
              colors: [Colors.pinkAccent, Colors.orangeAccent, Colors.yellowAccent, Colors.cyanAccent],
            ),
          ),

          // ── Dismiss panels on canvas tap ──────────────
          if (_showBrushPanel || _showColorPanel)
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => setState(() {
                _showBrushPanel = false;
                _showColorPanel = false;
              }),
            ),

          // ── Top bar ──────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: _TopBar(
                  brushType: _brushType,
                  isErasing: _isErasing,
                  color: _color,
                  canUndo: _canvas.canUndo,
                  onBack: () {
                    Provider.of<AudioManager>(context, listen: false)
                        .playEventSound('cancelButton');
                    Navigator.pop(context);
                  },
                  onBrushTap: () => setState(() {
                    _showBrushPanel = !_showBrushPanel;
                    _showColorPanel = false;
                  }),
                  onColorTap: () => setState(() {
                    _showColorPanel = !_showColorPanel;
                    _showBrushPanel = false;
                  }),
                  onEraserTap: () => setState(() {
                    _isErasing = !_isErasing;
                    _showBrushPanel = false;
                    _showColorPanel = false;
                  }),
                  onUndo: () => setState(() => _canvas.undo()),
                  onClear: _clear,
                ),
              ),
            ),
          ),

          // ── Brush Panel ───────────────────────────────
          if (_showBrushPanel)
            Positioned(
              top: 100, left: 10, right: 10,
              child: _BrushPanel(
                selected: _brushType,
                onSelect: (b) => setState(() {
                  _brushType = b;
                  _isErasing = false;
                  _showBrushPanel = false;
                }),
              ),
            ),

          // ── Bottom bar: color + size ──────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _BottomBar(
              palette: _palette,
              selectedColor: _color,
              stroke: _stroke,
              isErasing: _isErasing,
              onColor: (c) => setState(() {
                _color = c;
                _isErasing = false;
                _showColorPanel = false;
              }),
              onStroke: (v) => setState(() => _stroke = v),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  TOP BAR
// ─────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final BrushType brushType;
  final bool isErasing;
  final bool canUndo;
  final Color color;
  final VoidCallback onBack, onBrushTap, onColorTap, onEraserTap, onUndo, onClear;

  const _TopBar({
    required this.brushType,
    required this.isErasing,
    required this.canUndo,
    required this.color,
    required this.onBack,
    required this.onBrushTap,
    required this.onColorTap,
    required this.onEraserTap,
    required this.onUndo,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final brush = _brushes.firstWhere((b) => b.type == brushType);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.93),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 14, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          _Btn(icon: Icons.arrow_back_ios_new_rounded, bg: const Color(0xFFFF6584), onTap: onBack),
          const SizedBox(width: 6),
          // Brush selector
          GestureDetector(
            onTap: onBrushTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: brush.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: brush.color, width: 1.5),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(brush.icon, size: 16, color: brush.color),
                const SizedBox(width: 4),
                Text(brush.label, style: TextStyle(
                  fontFamily: 'ComicSansMS', fontSize: 12,
                  fontWeight: FontWeight.bold, color: brush.color,
                )),
              ]),
            ),
          ),
          const SizedBox(width: 6),
          // Color dot
          GestureDetector(
            onTap: onColorTap,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: color, shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)],
              ),
            ),
          ),
          const SizedBox(width: 6),
          _Btn(
            icon: isErasing ? Icons.cleaning_services_rounded : Icons.auto_fix_off_rounded,
            bg: isErasing ? const Color(0xFFFF3B3B) : const Color(0xFF90A4AE),
            onTap: onEraserTap,
          ),
          const Spacer(),
          _Btn(
            icon: Icons.undo_rounded,
            bg: canUndo ? const Color(0xFF6C63FF) : Colors.grey.shade300,
            onTap: onUndo,
          ),
          const SizedBox(width: 6),
          _Btn(icon: Icons.delete_sweep_rounded, bg: const Color(0xFFFF6D00), onTap: onClear),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final VoidCallback onTap;
  const _Btn({required this.icon, required this.bg, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: bg, shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: bg.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    ),
  );
}

// ─────────────────────────────────────────────────────────
//  BRUSH PANEL
// ─────────────────────────────────────────────────────────
class _BrushPanel extends StatelessWidget {
  final BrushType selected;
  final ValueChanged<BrushType> onSelect;
  const _BrushPanel({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.97),
      borderRadius: BorderRadius.circular(22),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.14), blurRadius: 18)],
    ),
    child: Wrap(
      spacing: 8, runSpacing: 8,
      children: _brushes.map((b) {
        final sel = b.type == selected;
        return GestureDetector(
          onTap: () => onSelect(b.type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? b.color : b.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: b.color, width: sel ? 0 : 1.5),
              boxShadow: sel ? [BoxShadow(color: b.color.withOpacity(0.35), blurRadius: 8)] : [],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(b.icon, size: 17, color: sel ? Colors.white : b.color),
              const SizedBox(width: 5),
              Text(b.label, style: TextStyle(
                fontFamily: 'ComicSansMS', fontSize: 13,
                fontWeight: FontWeight.bold,
                color: sel ? Colors.white : b.color,
              )),
            ]),
          ),
        );
      }).toList(),
    ),
  );
}

// ─────────────────────────────────────────────────────────
//  BOTTOM BAR
// ─────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final List<Color> palette;
  final Color selectedColor;
  final double stroke;
  final bool isErasing;
  final ValueChanged<Color> onColor;
  final ValueChanged<double> onStroke;

  const _BottomBar({
    required this.palette,
    required this.selectedColor,
    required this.stroke,
    required this.isErasing,
    required this.onColor,
    required this.onStroke,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 10, left: 12, right: 12,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 16)],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Color row
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: palette.length,
            separatorBuilder: (_, __) => const SizedBox(width: 7),
            itemBuilder: (_, i) {
              final c = palette[i];
              final sel = c.value == selectedColor.value && !isErasing;
              return GestureDetector(
                onTap: () => onColor(c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: sel ? 40 : 33, height: sel ? 40 : 33,
                  decoration: BoxDecoration(
                    color: c, shape: BoxShape.circle,
                    border: Border.all(
                      color: sel ? Colors.white : Colors.black12, width: sel ? 3 : 1,
                    ),
                    boxShadow: sel
                        ? [BoxShadow(color: c.withOpacity(0.55), blurRadius: 9)]
                        : [const BoxShadow(color: Color(0x20000000), blurRadius: 3)],
                  ),
                  child: sel ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        // Stroke slider
        Row(children: [
          const Text('·', style: TextStyle(fontSize: 18, color: Color(0xFFAAAAAA))),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: isErasing ? Colors.grey : selectedColor,
                inactiveTrackColor: (isErasing ? Colors.grey : selectedColor).withOpacity(0.2),
                thumbColor: isErasing ? Colors.grey : selectedColor,
                overlayColor: (isErasing ? Colors.grey : selectedColor).withOpacity(0.15),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                trackHeight: 4,
              ),
              child: Slider(min: 3, max: 36, value: stroke, onChanged: onStroke),
            ),
          ),
          Container(
            width: stroke.clamp(8, 36), height: stroke.clamp(8, 36),
            decoration: BoxDecoration(
              color: isErasing ? Colors.grey : selectedColor,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: (isErasing ? Colors.grey : selectedColor).withOpacity(0.4), blurRadius: 5)],
            ),
          ),
          const SizedBox(width: 8),
        ]),
      ]),
    );
  }
}