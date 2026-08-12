import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart' hide useWhiteForeground;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import 'package:provider/provider.dart';

import '../../XpSystem.dart';
import '../../main.dart';
import '../../tools/Ads_Manager.dart';
import 'model_logic_page.dart';

// ─────────────────────────────────────────────────────────
//  SAVED DRAWING
// ─────────────────────────────────────────────────────────
class SavedDrawing {
  final Uint8List imageData;
  final Duration drawDuration;
  final DateTime savedAt;
  SavedDrawing({required this.imageData, required this.drawDuration, required this.savedAt});
}

// ─────────────────────────────────────────────────────────
//  BRUSH META
// ─────────────────────────────────────────────────────────
class _BM {
  final BrushType type;
  final IconData icon;
  final String label;
  final Color color;
  const _BM(this.type, this.icon, this.label, this.color);
}

const _allBrushes = [
  _BM(BrushType.normal,  Icons.brush_rounded,      'Normal',  Color(0xFF6C63FF)),
  _BM(BrushType.dashed,  Icons.more_horiz_rounded, 'Dashes',  Color(0xFFFF6584)),
  _BM(BrushType.rainbow, Icons.gradient_rounded,   'Rainbow', Color(0xFFFFCC02)),
  _BM(BrushType.glitter, Icons.auto_awesome,       'Glitter', Color(0xFFFF85A1)),
  _BM(BrushType.glow,    Icons.flare_rounded,      'Glow',    Color(0xFF00C9FF)),
  _BM(BrushType.chalk,   Icons.texture_rounded,    'Chalk',   Color(0xFF43E97B)),
];

const _colorPalette = [
  Color(0xFFFF3B3B), Color(0xFFFF7043), Color(0xFFFFD600), Color(0xFF69F0AE),
  Color(0xFF40C4FF), Color(0xFF651FFF), Color(0xFFFF4081), Color(0xFF795548),
  Color(0xFFFF6D00), Color(0xFF1DE9B6), Color(0xFF304FFE), Color(0xFFAA00FF),
  Color(0xFF00E5FF), Color(0xFF76FF03), Color(0xFFFF80AB), Color(0xFF000000),
  Color(0xFF616161), Color(0xFFFFFFFF),
];

const _bgColors = [
  Colors.white,
  Color(0xFFFFF8EE), Color(0xFFE8F5E9),
  Color(0xFFE3F2FD), Color(0xFFF3E5F5), Colors.black,
];

// ─────────────────────────────────────────────────────────
//  SINGLE DRAWING PAGE
// ─────────────────────────────────────────────────────────
class SingleDrawingPage extends StatefulWidget {
  final List<DrawPoint?>? initialPoints; // kept for API compat, ignored
  final Color initialColor;
  final double initialStrokeWidth;
  final bool initialIsErasing;
  final Duration initialElapsed;
  final Function(SavedDrawing) onSave;
  final Function(List<DrawPoint?>, Color, double, bool, Duration) onChanged;

  const SingleDrawingPage({
    this.initialPoints,
    required this.initialColor,
    required this.initialStrokeWidth,
    required this.initialIsErasing,
    required this.initialElapsed,
    required this.onSave,
    required this.onChanged,
    Key? key,
  }) : super(key: key);

  @override
  _SingleDrawingPageState createState() => _SingleDrawingPageState();
}

class _SingleDrawingPageState extends State<SingleDrawingPage> {
  BannerAd? _bannerAd;
  bool _adLoaded = false;

  late CanvasController _canvas;
  late Color _color;
  late double _stroke;
  late bool _isErasing;
  Color _bg = Colors.white;
  BrushType _brushType = BrushType.normal;

  bool _showBrushPanel = false;

  final GlobalKey _repaintKey = GlobalKey();

  Timer? _timer;
  late Duration _elapsed;
  bool _timerRunning = false;
  late ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _canvas = CanvasController(backgroundColor: Colors.white);
    _color = widget.initialColor;
    _stroke = widget.initialStrokeWidth;
    _isErasing = widget.initialIsErasing;
    _elapsed = widget.initialElapsed;
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd?.dispose();
    _adLoaded = false;
    _bannerAd = AdHelper.getBannerAd(() => setState(() => _adLoaded = true));
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _timer?.cancel();
    _confetti.dispose();
    _canvas.dispose();
    super.dispose();
  }

  // ── Timer ─────────────────────────────────────────────
  void _startTimer() {
    if (_timerRunning) return;
    Provider.of<AudioManager>(context, listen: false)
        .playSfx('assets/audios/UI_Audio/SFX_Audio/CinematicStart_SFX.mp3');
    _timerRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed += const Duration(seconds: 1);
        widget.onChanged([], _color, _stroke, _isErasing, _elapsed);
      });
    });
  }

  void _stopTimer() { _timer?.cancel(); _timerRunning = false; }

  // ── Drawing ───────────────────────────────────────────
  void _onPanStart(DragStartDetails d) {
    if (!_timerRunning) _startTimer();
    _canvas.beginStroke(
      color: _color, strokeWidth: _stroke,
      brushType: _brushType, isEraser: _isErasing,
      point: d.localPosition,
    );
  }
  void _onPanUpdate(DragUpdateDetails d) => _canvas.addPoint(d.localPosition);
  void _onPanEnd(DragEndDetails _) => _canvas.endStroke();

  void _undo() => setState(() => _canvas.undo());

  void _clear() {
    Provider.of<AudioManager>(context, listen: false)
        .playAlert('assets/audios/UI_Audio/SFX_Audio/TransisitonPages_SFX.mp3');
    _confetti.play();
    setState(() {
      _canvas.clear();
      _elapsed = Duration.zero;
      _stopTimer();
    });
  }

  // ── Save ──────────────────────────────────────────────
  Future<void> _save() async {
    if (!_canvas.canUndo) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Draw something first! ✏️'),
        backgroundColor: Colors.orangeAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ));
      return;
    }
    final xpManager = Provider.of<ExperienceManager>(context, listen: false);
    if (xpManager.saveTokenCount < 5) { await _doSave(); return; }
    final choice = await showDialog<String>(context: context, builder: (_) => _SaveDialog());
    if (choice == null) return;
    if (choice == 'ad') { await _doSave(); }
    else if (choice == 'spend') {
      final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Spend 1 Tolim?', style: TextStyle(fontFamily: 'ComicSansMS')),
        content: const Text('This will deduct 1 Tolim. Proceed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(_, true),
              child: const Text('Yes!', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF43E97B))),
        ],
      ));
      if (ok != true) return;
      xpManager..SpendTokenBanner(context, 1);
      await _doSave();
    }
  }

  Future<void> _doSave() async {
    final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final img = await boundary.toImage(pixelRatio: 2.0);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    _confetti.play();
    widget.onSave(SavedDrawing(
      imageData: bytes!.buffer.asUint8List(),
      drawDuration: _elapsed,
      savedAt: DateTime.now(),
    ));
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(fit: StackFit.expand, children: [
        // ── Canvas ──────────────────────────────────────
        RepaintBoundary(
          key: _repaintKey,
          child: LayoutBuilder(builder: (ctx, c) {
            final size = Size(c.maxWidth, c.maxHeight);
            _canvas
              ..setSize(size)
              ..backgroundColor = _bg;
            return GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: AnimatedBuilder(
                animation: _canvas,
                builder: (_, __) => CustomPaint(
                  painter: DrawingPainter(
                    cachedPicture: _canvas.cachedPicture,
                    activeStroke: _canvas.activeStroke,
                    backgroundColor: _bg,
                    canvasSize: size,
                  ),
                  size: size,
                ),
              ),
            );
          }),
        ),

        // ── Confetti ────────────────────────────────────
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 28,
            colors: const [Colors.pinkAccent, Colors.orangeAccent, Colors.yellowAccent, Colors.cyanAccent],
          ),
        ),

        // ── Status bar ──────────────────────────────────
        Positioned(top: 5, left: 30, right: 30, child: Userstatutbar()),

        // ── Top toolbar ─────────────────────────────────
        Positioned(
          top: 80, left: 12, right: 12,
          child: SafeArea(child: _buildTopBar()),
        ),

        // ── Brush panel ─────────────────────────────────
        if (_showBrushPanel)
          Positioned(
            top: 160, left: 12, right: 12,
            child: _BrushPanel(
              selected: _brushType,
              onSelect: (b) => setState(() { _brushType = b; _isErasing = false; _showBrushPanel = false; }),
            ),
          ),

        // ── Bottom bar ──────────────────────────────────
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: _buildBottomBar(),
        ),

        // ── Banner ad ───────────────────────────────────
        if (context.watch<ExperienceManager>().adsEnabled && _bannerAd != null && _adLoaded)
          SafeArea(child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: FamilyAdBanner(bannerAd: _bannerAd, isLoaded: _adLoaded),
            ),
          )),
      ]),
    );
  }

  Widget _buildTopBar() {
    final audio = Provider.of<AudioManager>(context, listen: false);
    final brush = _allBrushes.firstWhere((b) => b.type == _brushType);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.93),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 14, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        _Btn(
          icon: Icons.arrow_back_ios_new_rounded,
          bg: const Color(0xFFFF6584),
          onTap: () { audio.playEventSound('cancelButton'); Navigator.pop(context); },
        ),
        const SizedBox(width: 6),
        // Timer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.timer_rounded, size: 15, color: Color(0xFF6C63FF)),
            const SizedBox(width: 3),
            Text(_fmt(_elapsed), style: const TextStyle(
              fontFamily: 'ComicSansMS', fontWeight: FontWeight.bold,
              fontSize: 13, color: Color(0xFF6C63FF),
            )),
          ]),
        ),
        const SizedBox(width: 6),
        // Brush picker
        GestureDetector(
          onTap: () => setState(() { _showBrushPanel = !_showBrushPanel; if (_showBrushPanel) _isErasing = false; }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: brush.color.withOpacity(0.13),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: brush.color, width: 1.5),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(brush.icon, size: 15, color: brush.color),
              const SizedBox(width: 4),
              Text(brush.label, style: TextStyle(fontFamily: 'ComicSansMS', fontSize: 11, fontWeight: FontWeight.bold, color: brush.color)),
            ]),
          ),
        ),
        const SizedBox(width: 6),
        _Btn(
          icon: _isErasing ? Icons.cleaning_services_rounded : Icons.auto_fix_off_rounded,
          bg: _isErasing ? const Color(0xFFFF3B3B) : const Color(0xFF90A4AE),
          onTap: () => setState(() { _isErasing = !_isErasing; _showBrushPanel = false; }),
        ),
        const Spacer(),
        _Btn(
          icon: Icons.undo_rounded,
          bg: _canvas.canUndo ? const Color(0xFF6C63FF) : Colors.grey.shade300,
          onTap: _undo,
        ),
        const SizedBox(width: 4),
        _Btn(icon: Icons.delete_sweep_rounded, bg: const Color(0xFFFF6D00), onTap: _clear),
        const SizedBox(width: 4),
        _Btn(icon: Icons.save_rounded, bg: const Color(0xFF43E97B), onTap: _save),
      ]),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.only(
        top: 10, left: 12, right: 12,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 16)],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Colors
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _colorPalette.length,
            separatorBuilder: (_, __) => const SizedBox(width: 7),
            itemBuilder: (_, i) {
              final c = _colorPalette[i];
              final sel = c.value == _color.value && !_isErasing;
              return GestureDetector(
                onTap: () => setState(() { _color = c; _isErasing = false; }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: sel ? 40 : 33, height: sel ? 40 : 33,
                  decoration: BoxDecoration(
                    color: c, shape: BoxShape.circle,
                    border: Border.all(color: sel ? Colors.white : Colors.black12, width: sel ? 3 : 1),
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
        Row(children: [
          const Text('·', style: TextStyle(fontSize: 18, color: Color(0xFFAAAAAA))),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _isErasing ? Colors.grey : _color,
                inactiveTrackColor: (_isErasing ? Colors.grey : _color).withOpacity(0.2),
                thumbColor: _isErasing ? Colors.grey : _color,
                overlayColor: (_isErasing ? Colors.grey : _color).withOpacity(0.15),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                trackHeight: 4,
              ),
              child: Slider(min: 3, max: 36, value: _stroke,
                  onChanged: (v) => setState(() => _stroke = v)),
            ),
          ),
          Container(
            width: _stroke.clamp(8, 36), height: _stroke.clamp(8, 36),
            decoration: BoxDecoration(
              color: _isErasing ? Colors.grey : _color, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: (_isErasing ? Colors.grey : _color).withOpacity(0.4), blurRadius: 5)],
            ),
          ),
          const SizedBox(width: 8),
          // Canvas BG picker
          ...(_bgColors.map((c) => GestureDetector(
            onTap: () => setState(() { _bg = c; _canvas.backgroundColor = c; }),
            child: Container(
              width: 22, height: 22,
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(
                color: c, shape: BoxShape.circle,
                border: Border.all(
                  color: c == _bg ? _color : const Color(0xFFDDDDDD),
                  width: c == _bg ? 2.5 : 1,
                ),
              ),
            ),
          ))),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  SHARED BRUSH PANEL
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
    child: Wrap(spacing: 8, runSpacing: 8,
      children: _allBrushes.map((b) {
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
                fontFamily: 'ComicSansMS', fontSize: 13, fontWeight: FontWeight.bold,
                color: sel ? Colors.white : b.color,
              )),
            ]),
          ),
        );
      }).toList(),
    ),
  );
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

class _SaveDialog extends StatelessWidget {
  const _SaveDialog();
  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    title: const Text('Save Your Masterpiece! 🎨', style: TextStyle(fontFamily: 'ComicSansMS', fontSize: 18)),
    content: const Text('How would you like to save?', style: TextStyle(fontFamily: 'ComicSansMS')),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context, 'ad'), child: const Text('📺 Watch Ads')),
      ElevatedButton(
        onPressed: () => Navigator.pop(context, 'spend'),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF43E97B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: const Text('⭐ Spend 1 Tolim', style: TextStyle(color: Colors.white, fontFamily: 'ComicSansMS')),
      ),
      TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancel')),
    ],
  );
}