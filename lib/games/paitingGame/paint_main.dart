import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:mortaalim/games/paitingGame/singleDrawing.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../XpSystem.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../tools/Ads_Manager.dart';
import 'model_logic_page.dart';

// ─────────────────────────────────────────────────────────
//  ROOT: DrawingApp (Draw ↔ Gallery)
// ─────────────────────────────────────────────────────────
class DrawingApp extends StatefulWidget {
  @override
  _DrawingAppState createState() => _DrawingAppState();
}

class _DrawingAppState extends State<DrawingApp> {
  List<SavedDrawing> savedDrawings = [];
  int _tab = 0;

  // Preserved drawing state
  List<DrawPoint?> _curPoints = [];
  Color _curColor = Colors.black;
  double _curStroke = 6.0;
  bool _curErasing = false;
  Duration _curElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadDrawings();
  }

  // ── Persistence ────────────────────────────────────────
  Future<Directory> get _dir async => getApplicationDocumentsDirectory();

  Future<void> _loadDrawings() async {
    final dir = await _dir;
    final meta = File('${dir.path}/drawings_metadata.json');
    if (!await meta.exists()) return;
    final list = jsonDecode(await meta.readAsString()) as List;
    final loaded = <SavedDrawing>[];
    for (final item in list) {
      final f = File('${dir.path}/${item['fileName']}');
      if (await f.exists()) {
        loaded.add(SavedDrawing(
          imageData: await f.readAsBytes(),
          drawDuration: Duration(milliseconds: item['drawDurationMs'] as int),
          savedAt: DateTime.parse(item['savedAt'] as String),
        ));
      }
    }
    setState(() => savedDrawings = loaded);
  }

  Future<void> _saveDrawingToDisk(SavedDrawing d) async {
    final dir = await _dir;
    final fname = 'drawing_${d.savedAt.millisecondsSinceEpoch}.png';
    await File('${dir.path}/$fname').writeAsBytes(d.imageData);

    final metaFile = File('${dir.path}/drawings_metadata.json');
    List<dynamic> list = [];
    if (await metaFile.exists()) {
      list = jsonDecode(await metaFile.readAsString());
    }
    list.add({
      'fileName': fname,
      'drawDurationMs': d.drawDuration.inMilliseconds,
      'savedAt': d.savedAt.toIso8601String(),
    });
    await metaFile.writeAsString(jsonEncode(list));
  }

  Future<void> _deleteDrawingFromDisk(int index) async {
    final dir = await _dir;
    final metaFile = File('${dir.path}/drawings_metadata.json');
    if (!await metaFile.exists()) return;
    final list = jsonDecode(await metaFile.readAsString()) as List;
    if (index < 0 || index >= list.length) return;
    final f = File('${dir.path}/${list[index]['fileName']}');
    if (await f.exists()) await f.delete();
    list.removeAt(index);
    await metaFile.writeAsString(jsonEncode(list));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tab == 0
          ? SingleDrawingPage(
        initialPoints: _curPoints,
        initialColor: _curColor,
        initialStrokeWidth: _curStroke,
        initialIsErasing: _curErasing,
        initialElapsed: _curElapsed,
        onSave: (d) async {
          await _saveDrawingToDisk(d);
          setState(() {
            savedDrawings.add(d);
            _curPoints = [];
            _curElapsed = Duration.zero;
            _curErasing = false;
            _curColor = Colors.black;
            _curStroke = 6.0;
            _tab = 1;
          });
        },
        onChanged: (pts, c, sw, e, el) {
          _curPoints = pts;
          _curColor = c;
          _curStroke = sw;
          _curErasing = e;
          _curElapsed = el;
        },
      )
          : GalleryPage(
        savedDrawings: savedDrawings,
        onDelete: (i) async {
          await _deleteDrawingFromDisk(i);
          setState(() => savedDrawings.removeAt(i));
        },
        onBack: () => setState(() => _tab = 0),
      ),

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF6584), Color(0xFF6C63FF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _tab,
          backgroundColor: Colors.transparent,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white54,
          elevation: 0,
          selectedLabelStyle:
          const TextStyle(fontFamily: 'ComicSansMS', fontWeight: FontWeight.bold),
          onTap: (i) => setState(() => _tab = i),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.brush_rounded), label: 'Draw'),
            BottomNavigationBarItem(
                icon: Icon(Icons.photo_library_rounded), label: 'Gallery'),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  GALLERY PAGE
// ─────────────────────────────────────────────────────────
class GalleryPage extends StatelessWidget {
  final List<SavedDrawing> savedDrawings;
  final void Function(int) onDelete;
  final VoidCallback onBack;

  const GalleryPage({
    required this.savedDrawings,
    required this.onDelete,
    required this.onBack,
    Key? key,
  }) : super(key: key);

  String _fmtDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _fmtDate(DateTime dt) =>
      DateFormat('MMM d, yyyy – HH:mm').format(dt);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
            pinned: true,
            expandedHeight: 120,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: onBack,
            ),
            flexibleSpace: const FlexibleSpaceBar(
              title: Text(
                '🖼️ My Gallery',
                style: TextStyle(
                  fontFamily: 'ComicSansMS',
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              background: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF3F8EFC)],
                  ),
                ),
              ),
            ),
          ),
          if (savedDrawings.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🎨', style: TextStyle(fontSize: 72)),
                    const SizedBox(height: 16),
                    const Text(
                      'No drawings yet!',
                      style: TextStyle(
                        fontFamily: 'ComicSansMS',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFAAAAAA),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: onBack,
                      icon: const Icon(Icons.brush_rounded),
                      label: const Text('Start Drawing!',
                          style: TextStyle(fontFamily: 'ComicSansMS')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6584),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _GalleryCard(
                    drawing: savedDrawings[i],
                    index: i,
                    fmtDuration: _fmtDuration,
                    fmtDate: _fmtDate,
                    onShare: () => _share(ctx, savedDrawings[i]),
                    onDelete: () => _confirmDelete(ctx, i),
                  ),
                  childCount: savedDrawings.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _share(BuildContext ctx, SavedDrawing d) async {
    final audio = Provider.of<AudioManager>(ctx, listen: false);
    audio.playEventSound('clickButton2');

    final image = await decodeImageFromList(d.imageData);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Paint()..color = Colors.white,
    );
    canvas.drawImage(image, Offset.zero, Paint());

    final stamp = TextPainter(
      text: const TextSpan(
        text: 'MoorTaalim',
        style: TextStyle(
          color: Color(0xFF6C63FF),
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    stamp.paint(canvas,
        Offset(image.width - stamp.width - 14, image.height - stamp.height - 14));

    final xpManager = Provider.of<ExperienceManager>(ctx, listen: false);
    final userStamp = TextPainter(
      text: TextSpan(
        text: 'By ${xpManager.userProfile.fullName}',
        style: const TextStyle(color: Color(0xFF333333), fontSize: 26, fontWeight: FontWeight.bold),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    userStamp.paint(canvas, Offset(14, image.height - userStamp.height - 14));

    final pic = recorder.endRecording();
    final finalImg = await pic.toImage(image.width, image.height);
    final bytes = await finalImg.toByteData(format: ui.ImageByteFormat.png);

    final tmp = await getTemporaryDirectory();
    final file = File('${tmp.path}/drawing_${d.savedAt.millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    await Share.shareXFiles([XFile(file.path)], text: '🎨 My Masterpiece!');
  }

  void _confirmDelete(BuildContext ctx, int index) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Drawing?',
            style: TextStyle(fontFamily: 'ComicSansMS')),
        content: const Text('This can\'t be undone!',
            style: TextStyle(fontFamily: 'ComicSansMS')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onDelete(index);
              Navigator.pop(_);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Delete 🗑️',
                style: TextStyle(color: Colors.white, fontFamily: 'ComicSansMS')),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  GALLERY CARD
// ─────────────────────────────────────────────────────────
class _GalleryCard extends StatefulWidget {
  final SavedDrawing drawing;
  final int index;
  final String Function(Duration) fmtDuration;
  final String Function(DateTime) fmtDate;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const _GalleryCard({
    required this.drawing,
    required this.index,
    required this.fmtDuration,
    required this.fmtDate,
    required this.onShare,
    required this.onDelete,
  });

  @override
  State<_GalleryCard> createState() => _GalleryCardState();
}

class _GalleryCardState extends State<_GalleryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scale = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutBack));
    Future.delayed(Duration(milliseconds: 80 * widget.index), () {
      if (mounted) _anim.forward();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              Image.memory(widget.drawing.imageData, fit: BoxFit.cover),
              // Gradient footer
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 22, 10, 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Color(0xCC000000)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.timer_rounded,
                              color: Colors.white70, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            widget.fmtDuration(widget.drawing.drawDuration),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'ComicSansMS',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        widget.fmtDate(widget.drawing.savedAt),
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 9,
                          fontFamily: 'ComicSansMS',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Action buttons
              Positioned(
                top: 8,
                right: 8,
                child: Column(
                  children: [
                    _ActionBtn(
                      icon: Icons.share_rounded,
                      onTap: widget.onShare,
                      bg: const Color(0xFF6C63FF),
                    ),
                    const SizedBox(height: 6),
                    _ActionBtn(
                      icon: Icons.delete_forever_rounded,
                      onTap: widget.onDelete,
                      bg: Colors.redAccent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color bg;
  const _ActionBtn({required this.icon, required this.onTap, required this.bg});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: bg.withOpacity(0.5), blurRadius: 8),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}