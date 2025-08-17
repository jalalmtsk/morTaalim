import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';


class ColoringPage extends StatefulWidget {
  const ColoringPage({super.key});

  @override
  State<ColoringPage> createState() => _ColoringPageState();
}

class _ColoringPageState extends State<ColoringPage> {
  ui.Image? originalImage;
  ui.Image? coloredImage;
  Uint32List? pixels;
  int selectedColor = 0xFFFF0000; // Default red ARGB

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

    final byteData = await originalImage!.toByteData(format: ui.ImageByteFormat.rawRgba);
    pixels = byteData!.buffer.asUint32List();

    setState(() {});
  }

  Future<ui.Image> _imageFromPixels(Uint32List pixels, int width, int height) async {
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

  // Flood-fill with tolerance
  void _floodFill(int x, int y, int targetColor, int replacementColor, int width, int height, {int tolerance = 32}) {
    if (targetColor == replacementColor) return;

    final stack = <Offset>[];
    stack.add(Offset(x.toDouble(), y.toDouble()));

    int getRed(int color) => (color >> 16) & 0xFF;
    int getGreen(int color) => (color >> 8) & 0xFF;
    int getBlue(int color) => color & 0xFF;

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
    if (coloredImage == null) return;

    RenderBox box = context.findRenderObject() as RenderBox;
    final localPos = box.globalToLocal(details.globalPosition);

    // Scale tap to image pixels
    double scaleX = coloredImage!.width / box.size.width;
    double scaleY = coloredImage!.height / box.size.height;

    int x = (localPos.dx * scaleX).toInt();
    int y = (localPos.dy * scaleY).toInt();

    int pixelIndex = y * coloredImage!.width + x;
    int targetColor = pixels![pixelIndex];

    _floodFill(x, y, targetColor, selectedColor, coloredImage!.width, coloredImage!.height, tolerance: 32);

    final newImage = await _imageFromPixels(pixels!, coloredImage!.width, coloredImage!.height);

    setState(() {
      coloredImage = newImage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (coloredImage == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sketch Coloring'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onTapDown: (details) => _onTapDown(context, details),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: CustomPaint(
                        size: Size(coloredImage!.width.toDouble(), coloredImage!.height.toDouble()),
                        painter: ImagePainter(coloredImage!),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(
            height: 80,
            child: _buildColorPalette(),
          )
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
    ];

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: colors.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedColor = 0xFF000000 | (colors[index].value & 0x00FFFFFF);
            });
          },
          child: Container(
            width: 60,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors[index],
              shape: BoxShape.circle,
              border: Border.all(
                width: selectedColor == (0xFF000000 | (colors[index].value & 0x00FFFFFF)) ? 3 : 0,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}

class ImagePainter extends CustomPainter {
  final ui.Image image;
  ImagePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, src, dst, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
