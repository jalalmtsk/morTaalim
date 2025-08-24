import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class ColoringPage extends StatefulWidget {
  const ColoringPage({super.key});

  @override
  State<ColoringPage> createState() => _ColoringPageState();
}

class _ColoringPageState extends State<ColoringPage> {
  ui.Image? originalImage;
  ui.Image? coloredImage;
  Uint32List? pixels;
  int selectedColor = 0xFFFF0000; // Default red in RGBA format
  final TransformationController _transformationController = TransformationController();

  // Undo/Redo stack
  final List<Uint32List> _undoStack = [];
  final List<Uint32List> _redoStack = [];

  // Prevent overlapping taps
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadImage('assets/images/Sketches/Labubu.jpg');
  }

  Future<void> _loadImage(String path) async {
    ByteData data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    originalImage = frame.image;
    coloredImage = originalImage;

    final byteData =
    await originalImage!.toByteData(format: ui.ImageByteFormat.rawRgba);
    pixels = byteData!.buffer.asUint32List();

    setState(() {});
  }

  Future<ui.Image> _imageFromPixels(
      Uint32List pixels, int width, int height) async {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels.buffer.asUint8List(),
      width,
      height,
      ui.PixelFormat.rgba8888,
          (img) => completer.complete(img),
    );
    return completer.future;
  }

  void _floodFill(int x, int y, int targetColor, int replacementColor,
      int width, int height,
      {int tolerance = 32}) {
    if (targetColor == replacementColor) return;

    final stack = <Offset>[];
    stack.add(Offset(x.toDouble(), y.toDouble()));

    int getRed(int color) => color & 0xFF;
    int getGreen(int color) => (color >> 8) & 0xFF;
    int getBlue(int color) => (color >> 16) & 0xFF;

    bool similarColor(int c1, int c2) {
      return (getRed(c1) - getRed(c2)).abs() <= tolerance &&
          (getGreen(c1) - getGreen(c2)).abs() <= tolerance &&
          (getBlue(c1) - getBlue(c2)).abs() <= tolerance;
    }

    while (stack.isNotEmpty) {
      final point = stack.removeLast();
      int px = point.dx.toInt();
      int py = point.dy.toInt();

      if (px < 0 || px >= width || py < 0 || py >= height) continue;

      int index = py * width + px;
      if (!similarColor(pixels![index], targetColor)) continue;

      pixels![index] = replacementColor;

      stack.add(Offset(px + 1.0, py.toDouble()));
      stack.add(Offset(px - 1.0, py.toDouble()));
      stack.add(Offset(px.toDouble(), py + 1.0));
      stack.add(Offset(px.toDouble(), py - 1.0));
    }
  }

  void _onTapDown(BuildContext context, TapDownDetails details) async {
    if (coloredImage == null || _isProcessing) return; // Ignore if busy
    _isProcessing = true;

    // Save current state for undo
    _undoStack.add(Uint32List.fromList(pixels!));
    _redoStack.clear();

    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPos = box.globalToLocal(details.globalPosition);

    // Reverse transformation (zoom/pan)
    final Matrix4 matrix = _transformationController.value.clone();
    final Matrix4 inverseMatrix = Matrix4.inverted(matrix);
    final transformedPos = MatrixUtils.transformPoint(inverseMatrix, localPos);

    double scaleX = coloredImage!.width / box.size.width;
    double scaleY = coloredImage!.height / box.size.height;

    int x = (transformedPos.dx * scaleX).toInt();
    int y = (transformedPos.dy * scaleY).toInt();

    int pixelIndex = y * coloredImage!.width + x;
    int targetColor = pixels![pixelIndex];

    _floodFill(x, y, targetColor, selectedColor, coloredImage!.width,
        coloredImage!.height,
        tolerance: 32);

    final newImage =
    await _imageFromPixels(pixels!, coloredImage!.width, coloredImage!.height);

    setState(() {
      coloredImage = newImage;
      _isProcessing = false; // Done processing
    });
  }

  void _undo() async {
    if (_undoStack.isEmpty) return;
    _redoStack.add(Uint32List.fromList(pixels!));
    pixels = _undoStack.removeLast();
    coloredImage =
    await _imageFromPixels(pixels!, coloredImage!.width, coloredImage!.height);
    setState(() {});
  }

  void _redo() async {
    if (_redoStack.isEmpty) return;
    _undoStack.add(Uint32List.fromList(pixels!));
    pixels = _redoStack.removeLast();
    coloredImage =
    await _imageFromPixels(pixels!, coloredImage!.width, coloredImage!.height);
    setState(() {});
  }

  void _reset() async {
    pixels = (await originalImage!.toByteData(format: ui.ImageByteFormat.rawRgba))!
        .buffer
        .asUint32List();
    _undoStack.clear();
    _redoStack.clear();
    coloredImage =
    await _imageFromPixels(pixels!, originalImage!.width, originalImage!.height);
    setState(() {});
  }

  int colorToPixel(Color color) {
    int r = color.red;
    int g = color.green;
    int b = color.blue;
    int a = color.alpha;
    return (a << 24) | (b << 16) | (g << 8) | r;
  }

  @override
  Widget build(BuildContext context) {
    if (coloredImage == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Sketch Coloring')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onTapDown: (details) => _onTapDown(context, details),
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      panEnabled: true,
                      scaleEnabled: true,
                      minScale: 1.0,
                      maxScale: 5.0,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: CustomPaint(
                          size: Size(coloredImage!.width.toDouble(),
                              coloredImage!.height.toDouble()),
                          painter: ImagePainter(coloredImage!),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(
            height: 120,
            child: Column(
              children: [
                Expanded(child: _buildColorPalette()),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(onPressed: _undo, child: Text("Undo")),
                    ElevatedButton(onPressed: _redo, child: Text("Redo")),
                    ElevatedButton(onPressed: _reset, child: Text("Reset")),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPalette() {
    List<Color> colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.brown,
      Colors.pink,
      Colors.cyan,
      Colors.black,
      Colors.white, // Added white color for eraser
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: Colors.grey[200],
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: BouncingScrollPhysics(),
        itemCount: colors.length,
        itemBuilder: (context, index) {
          bool isSelected = selectedColor == colorToPixel(colors[index]);
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedColor = colorToPixel(colors[index]);
              });
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 12),
              width: isSelected ? 70 : 60,
              height: isSelected ? 70 : 60,
              decoration: BoxDecoration(
                color: colors[index],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  )
                ],
                border: isSelected
                    ? Border.all(color: Colors.white, width: 4)
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}

class ImagePainter extends CustomPainter {
  final ui.Image image;
  ImagePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final src =
    Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, src, dst, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
