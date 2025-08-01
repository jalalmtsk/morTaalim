// Clean and Child-Friendly Flutter Drawing App
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class DrawPoint {
  final Offset point;
  final Paint paint;

  DrawPoint({required this.point, required this.paint});
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
        canvas.drawLine(current.point, next.point, current.paint);
      } else if (current != null && next == null) {
        canvas.drawPoints(ui.PointMode.points, [current.point], current.paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DrawingWithBackgroundPainter oldDelegate) => true;
}

class DrawingOnBackgroundPage extends StatefulWidget {
  final String imageAssetPath;

  DrawingOnBackgroundPage({required this.imageAssetPath});

  @override
  _DrawingOnBackgroundPageState createState() => _DrawingOnBackgroundPageState();
}

class _DrawingOnBackgroundPageState extends State<DrawingOnBackgroundPage> {
  List<DrawPoint?> points = [];
  ui.Image? backgroundImage;

  Color selectedColor = Colors.black;
  double strokeWidth = 6.0;
  bool isErasing = false;

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
      setState(() {
        backgroundImage = img;
      });
    });
  }

  void addPoint(Offset point) {
    setState(() {
      points.add(DrawPoint(
        point: point,
        paint: Paint()
          ..color = (isErasing ? Colors.white : selectedColor).withValues(alpha: 0.4)
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      ));
    });
  }

  void endStroke() => setState(() => points.add(null));

  void clearCanvas() => setState(() => points.clear());

  void toggleEraser() => setState(() => isErasing = !isErasing);

  Future<void> pickColor() async {
    Color pickedColor = selectedColor;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: selectedColor,
            availableColors: [
              Colors.redAccent,
              Colors.orange,
              Colors.yellow,
              Colors.green,
              Colors.blueAccent,
              Colors.purpleAccent,
              Colors.pink,
              Colors.brown,
              Colors.black,
              Colors.grey
            ],
            onColorChanged: (color) => pickedColor = color,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() {
                selectedColor = pickedColor;
                isErasing = false;
              });
              Navigator.pop(context);
            },
            child: const Text('Select'),
          )
        ],
      ),
    );
  }

  Future<void> pickStrokeWidth() async {
    double tempStroke = strokeWidth;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Brush Size'),
        content: StatefulBuilder(
          builder: (context, setStateDialog) => Slider(
            min: 1,
            max: 30,
            divisions: 29,
            label: tempStroke.toStringAsFixed(1),
            value: tempStroke,
            onChanged: (val) => setStateDialog(() => tempStroke = val),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() {
                strokeWidth = tempStroke;
                isErasing = false;
              });
              Navigator.pop(context);
            },
            child: const Text('Select'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (backgroundImage == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        title: const Text('Color the Sketch'),
        centerTitle: true,
        leading: const BackButton(),
      ),
      body: GestureDetector(
        onPanDown: (details) => addPoint(details.localPosition),
        onPanUpdate: (details) => addPoint(details.localPosition),
        onPanEnd: (_) => endStroke(),
        child: CustomPaint(
          painter: DrawingWithBackgroundPainter(points, backgroundImage!),
          size: Size.infinite,
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.pinkAccent,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.color_lens, color: Colors.white),
              onPressed: pickColor,
              tooltip: 'Pick Color',
            ),
            IconButton(
              icon: const Icon(Icons.brush, color: Colors.white),
              onPressed: pickStrokeWidth,
              tooltip: 'Brush Size',
            ),
            IconButton(
              icon: Icon(isErasing ? Icons.remove_circle : Icons.remove_circle_outline, color: Colors.white),
              onPressed: toggleEraser,
              tooltip: 'Eraser',
            ),
            IconButton(
              icon: const Icon(Icons.clear_all, color: Colors.white),
              onPressed: clearCanvas,
              tooltip: 'Clear',
            ),
          ],
        ),
      ),
    );
  }
}

class SketchSelectorPage extends StatelessWidget {
  final List<String> sketchPaths = [
    'assets/images/Sketches/doll.jpg',
    'assets/images/Sketches/Girl.jpg',
    'assets/images/Sketches/girl2.jpg',

  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        title: const Text('Choose a Sketch'),
        backgroundColor: Colors.pinkAccent,
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sketchPaths.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final path = sketchPaths[index];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DrawingOnBackgroundPage(imageAssetPath: path),
              ),
            ),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              clipBehavior: Clip.antiAlias,
              child: Image.asset(path, fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }
}
