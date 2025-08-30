import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:provider/provider.dart';

enum BrushType { normal, dashed, rainbow }

class DrawPoint {
  final Offset point;
  final Paint paint;
  final BrushType brushType;

  DrawPoint({required this.point, required this.paint, this.brushType = BrushType.normal});
}

class DrawingWithBackgroundPainter extends CustomPainter {
  final List<DrawPoint?> points;
  final ui.Image backgroundImage;

  DrawingWithBackgroundPainter(this.points, this.backgroundImage);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final srcRect = Rect.fromLTWH(0, 0, backgroundImage.width.toDouble(), backgroundImage.height.toDouble());
    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(backgroundImage, srcRect, dstRect, paint);

    for (int i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      if (current != null && next != null) {
        switch (current.brushType) {
          case BrushType.dashed:
            _drawDashedLine(canvas, current.point, next.point, current.paint);
            break;
          case BrushType.rainbow:
            final rainbowPaint = Paint()
              ..shader = LinearGradient(
                  colors: [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.purple])
                  .createShader(Rect.fromPoints(current.point, next.point))
              ..strokeWidth = current.paint.strokeWidth
              ..strokeCap = StrokeCap.round;
            canvas.drawLine(current.point, next.point, rainbowPaint);
            break;
          default:
            canvas.drawLine(current.point, next.point, current.paint);
        }
      } else if (current != null && next == null) {
        canvas.drawPoints(ui.PointMode.points, [current.point], current.paint);
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const double dashWidth = 5, dashSpace = 5;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = sqrt(dx * dx + dy * dy);
    final dashCount = (distance / (dashWidth + dashSpace)).floor();
    final dashX = dx / distance * dashWidth;
    final dashY = dy / distance * dashWidth;
    final spaceX = dx / distance * dashSpace;
    final spaceY = dy / distance * dashSpace;

    double x = start.dx;
    double y = start.dy;
    for (int i = 0; i < dashCount; i++) {
      canvas.drawLine(Offset(x, y), Offset(x + dashX, y + dashY), paint);
      x += dashX + spaceX;
      y += dashY + spaceY;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DrawingOnBackgroundPage extends StatefulWidget {
  final String imageAssetPath;
  DrawingOnBackgroundPage({required this.imageAssetPath});

  @override
  _DrawingOnBackgroundPageState createState() => _DrawingOnBackgroundPageState();
}

class _DrawingOnBackgroundPageState extends State<DrawingOnBackgroundPage> {
  List<DrawPoint?> points = [];
  List<List<DrawPoint?>> history = [];
  ui.Image? backgroundImage;

  Color selectedColor = Colors.black;
  double strokeWidth = 6.0;
  bool isErasing = false;
  BrushType brushType = BrushType.normal;

  // Expanded kid-friendly color palette
  final List<Color> colorPalette = [
    Colors.red, Colors.redAccent, Colors.orange, Colors.deepOrange,
    Colors.yellow, Colors.yellowAccent, Colors.green, Colors.lightGreen,
    Colors.blue, Colors.blueAccent, Colors.indigo, Colors.purple,
    Colors.pink, Colors.brown, Colors.grey, Colors.black,
  ];

  Future<ui.Image> loadUiImage(String assetPath) async {
    final data = await DefaultAssetBundle.of(context).load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final img = await loadUiImage(widget.imageAssetPath);
      setState(() => backgroundImage = img);
    });
  }

  void addPoint(Offset point) {
    setState(() {
      final paint = Paint()
        ..color = (isErasing ? Colors.transparent : selectedColor).withOpacity(isErasing ? 1.0 : 0.8)
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..blendMode = isErasing ? BlendMode.clear : BlendMode.srcOver;
      points.add(DrawPoint(point: point, paint: paint, brushType: brushType));
    });
  }

  void endStroke() {
    setState(() {
      points.add(null);
      history.add(List.from(points));
    });
  }

  void undo() {
    if (history.isNotEmpty) {
      setState(() {
        history.removeLast();
        points = history.isNotEmpty ? List.from(history.last) : [];
      });
    }
  }

  void clearCanvas() {
    setState(() {
      points.clear();
      history.clear();
    });
  }

  void toggleEraser() => setState(() {
    isErasing = !isErasing;
    brushType = BrushType.normal;
  });

  Future<void> pickColor() async {
    Color tempColor = selectedColor;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pick a Color'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: selectedColor,
            availableColors: colorPalette,
            onColorChanged: (color) => tempColor = color,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                selectedColor = tempColor;
                isErasing = false;
              });
              Navigator.pop(context);
            },
            child: const Text('Select', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
          ),
        ],
      ),
    );
  }

  Future<void> pickStrokeWidth() async {
    double tempStroke = strokeWidth;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Select Brush Size'),
        content: StatefulBuilder(
          builder: (_, setStateDialog) => Slider(
            min: 1,
            max: 30,
            value: tempStroke,
            divisions: 29,
            onChanged: (val) => setStateDialog(() => tempStroke = val),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => strokeWidth = tempStroke);
              isErasing = false;
              Navigator.pop(context);
            },
            child: const Text('Select', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
          ),
        ],
      ),
    );
  }

  Future<void> pickBrushType() async {
    BrushType tempBrush = brushType;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Select Brush Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: BrushType.values
              .map((b) => RadioListTile<BrushType>(
            title: Text(b.toString().split('.').last),
            value: b,
            groupValue: tempBrush,
            onChanged: (val) {
              setState(() => tempBrush = val!);
            },
          ))
              .toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child:  Text(tr(context).cancel)),
          ElevatedButton(
            onPressed: () {
              final audioManager = Provider.of<AudioManager>(context, listen: false);
              audioManager.playEventSound("cancelButton");
              setState(() => brushType = tempBrush);
              isErasing = false;
              Navigator.pop(context);
            },
            child: const Text('Select', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (backgroundImage == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      body: Stack(
        children: [
          GestureDetector(
            onPanDown: (details) => addPoint(details.localPosition),
            onPanUpdate: (details) => addPoint(details.localPosition),
            onPanEnd: (_) => endStroke(),
            child: CustomPaint(
              painter: DrawingWithBackgroundPainter(points, backgroundImage!),
              size: Size.infinite,
            ),
          ),
          Positioned(
            top: 24,
            left: 16,
            child: FloatingActionButton(
              backgroundColor: Colors.pinkAccent,
              onPressed: () {
                final audioManager = Provider.of<AudioManager>(context, listen: false);
                audioManager.playEventSound("cancelButton");
                Navigator.pop(context);},
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Colors.pinkAccent, Colors.orangeAccent]),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FloatingActionButton(
                heroTag: 'color',
                onPressed: pickColor,
                backgroundColor: selectedColor,
                child: const Icon(Icons.color_lens, color: Colors.white),
              ),
              const SizedBox(width: 10),
              FloatingActionButton(
                heroTag: 'brush',
                onPressed: pickStrokeWidth,
                backgroundColor: Colors.pinkAccent,
                child: const Icon(Icons.brush, color: Colors.white),
              ),
              const SizedBox(width: 10),
              FloatingActionButton(
                heroTag: 'brushType',
                onPressed: pickBrushType,
                backgroundColor: Colors.pinkAccent,
                child: const Icon(Icons.auto_fix_high, color: Colors.white),
              ),
              const SizedBox(width: 10),
              FloatingActionButton(
                heroTag: 'undo',
                onPressed: undo,
                backgroundColor: Colors.pinkAccent,
                child: const Icon(Icons.undo, color: Colors.white),
              ),
              const SizedBox(width: 10),
              FloatingActionButton(
                heroTag: 'clear',
                onPressed: clearCanvas,
                backgroundColor: Colors.pinkAccent,
                child: const Icon(Icons.clear, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
