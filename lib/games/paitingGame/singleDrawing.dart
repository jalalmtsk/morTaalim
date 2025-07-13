import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart' hide useWhiteForeground;
import 'package:confetti/confetti.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import 'package:provider/provider.dart';

import '../../XpSystem.dart';
import '../../main.dart';
import '../../tools/Ads_Manager.dart';
import 'model_logic_page.dart';

class SavedDrawing {
  final Uint8List imageData;
  final Duration drawDuration;
  final DateTime savedAt;

  SavedDrawing({
    required this.imageData,
    required this.drawDuration,
    required this.savedAt,
  });
}

class SingleDrawingPage extends StatefulWidget {
  final List<DrawPoint?>? initialPoints;
  final Color initialColor;
  final double initialStrokeWidth;
  final bool initialIsErasing;
  final Duration initialElapsed;

  final Function(SavedDrawing) onSave;
  final Function(List<DrawPoint?> points, Color color, double strokeWidth, bool isErasing, Duration elapsed) onChanged;

  SingleDrawingPage({
    this.initialPoints,
    required this.initialColor,
    required this.initialStrokeWidth,
    required this.initialIsErasing,
    required this.initialElapsed,
    required this.onSave,
    required this.onChanged,
  });

  @override
  _SingleDrawingPageState createState() => _SingleDrawingPageState();
}

class _SingleDrawingPageState extends State<SingleDrawingPage> {
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  late List<DrawPoint?> points;
  late Color selectedColor;
  late double strokeWidth;
  late bool isErasing;

  final GlobalKey canvasKey = GlobalKey();

  Timer? _timer;
  late Duration _elapsed;
  bool _timerRunning = false;

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    points = widget.initialPoints ?? [];
    selectedColor = widget.initialColor;
    strokeWidth = widget.initialStrokeWidth;
    isErasing = widget.initialIsErasing;
    _elapsed = widget.initialElapsed;

    _confettiController = ConfettiController(duration: const Duration(seconds: 1));

    if (points.isNotEmpty) {
      _startTimer();
    }
  }


  void _loadBannerAd() {
    _bannerAd?.dispose();
    _isBannerAdLoaded = false;
    _bannerAd = AdHelper.getBannerAd(() {
      setState(() {
        _isBannerAdLoaded = true;
      });
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _timer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (!_timerRunning) {
      _timerRunning = true;
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          _elapsed += Duration(seconds: 1);
          widget.onChanged(points, selectedColor, strokeWidth, isErasing, _elapsed);
        });
      });
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    _timerRunning = false;
  }

  void addPoint(Offset localPosition) {
    if (!_timerRunning) _startTimer();

    setState(() {
      points.add(DrawPoint(
        points: localPosition,
        paint: Paint()
          ..color = isErasing ? Colors.white : selectedColor
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      ));
      widget.onChanged(points, selectedColor, strokeWidth, isErasing, _elapsed);
    });
  }

  void endStroke() {
    setState(() {
      points.add(null);
      widget.onChanged(points, selectedColor, strokeWidth, isErasing, _elapsed);
    });
  }

  void clearCanvas() {
    _confettiController.play();

    setState(() {
      points.clear();
      _elapsed = Duration.zero;
      _stopTimer();
      widget.onChanged(points, selectedColor, strokeWidth, isErasing, _elapsed);
    });
  }

  Future<void> saveDrawing() async {
    if (points.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Draw something before saving!")),
      );
      return;
    }


    final xpManager = Provider.of<ExperienceManager>(context, listen: false);

    // Check if user has at least 1 star
    if (xpManager.saveTokenCount < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Row(
          children: [
            Text("Not enough "),
            Icon(Icons.generating_tokens_rounded, color: Colors.green,),
            Text("to save the drawing!"),
          ],
        )),
      );
      return;
    }

    try {
      RenderRepaintBoundary boundary = canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
      var image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
      if (byteData != null) {
        _stopTimer();

        final savedDrawing = SavedDrawing(
          imageData: byteData.buffer.asUint8List(),
          drawDuration: _elapsed,
          savedAt: DateTime.now(),
        );

        widget.onSave(savedDrawing);

        // Deduct 1 star for saving
        xpManager.addTokens(-1);

        clearCanvas();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Row(
            children: [
              Text('Drawing saved!  '),
              Text('-1 ', style: TextStyle(fontWeight: FontWeight.bold, color: CupertinoColors.activeGreen),),
              Icon(Icons.generating_tokens_rounded, color: CupertinoColors.systemGreen,)
            ],
          )),
        );
      }
    } catch (e) {
      print("Error saving drawing: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save drawing.')),
      );
    }
  }


  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          // 🎉 Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.directional,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.yellow,
              ],
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              maxBlastForce: 20,
              minBlastForce: 10,
              gravity: 0.3,
              particleDrag: 0.05,
              blastDirection: -pi / 2,
            ),
          ),

          // 🎨 Drawing Canvas
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: RepaintBoundary(
              key: canvasKey,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanDown: (details) => addPoint(details.localPosition),
                onPanUpdate: (details) => addPoint(details.localPosition),
                onPanEnd: (details) => endStroke(),
                child: CustomPaint(
                  size: Size.infinite,
                  painter: DrawingPainter(points),
                ),
              ),
            ),
          ),

          // 👤 User Status Bar (TOP)
          Positioned(
            top: 5,
            left: 30,
            right: 30,
            child: Userstatutbar(), // Make sure this widget is implemented
          ),

          // 🕒 Timer Display (Top Left)
          Positioned(
            top: 100, // ⬅️ moved down below the status bar
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.85),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: Row(
                children: [
                  Icon(Icons.timer, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    _formatDuration(_elapsed),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Comic Sans MS',
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🧰 Tools Row (Top Right)
          Positioned(
            top: 93, // ⬅️ moved down below the status bar
            right: 12,
            child: Row(
              children: [
                FloatingActionButton(
                  heroTag: 'color',
                  mini: true,
                  backgroundColor: selectedColor,
                  child: Icon(Icons.color_lens, color: useWhiteForeground(selectedColor) ? Colors.white : Colors.black),
                  onPressed: () => pickColor(context),
                  tooltip: 'Choose Color',
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  heroTag: 'brush',
                  mini: true,
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.brush),
                  onPressed: () => pickStrokeWidth(context),
                  tooltip: 'Brush Size',
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  heroTag: 'eraser',
                  mini: true,
                  backgroundColor: isErasing ? Colors.redAccent : Colors.grey,
                  child: Icon(isErasing ? Icons.remove_circle_outline : Icons.remove_circle),
                  onPressed: () => setState(() {
                    isErasing = !isErasing;
                    widget.onChanged(points, selectedColor, strokeWidth, isErasing, _elapsed);
                  }),
                  tooltip: isErasing ? 'Eraser On' : 'Eraser Off',
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  heroTag: 'clear',
                  mini: true,
                  backgroundColor: Colors.orangeAccent,
                  child: Icon(Icons.delete_forever),
                  onPressed: clearCanvas,
                  tooltip: 'Clear Canvas',
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  heroTag: 'save',
                  mini: true,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.save),
                  onPressed: saveDrawing,
                  tooltip: 'Save Drawing',
                ),
              ],
            ),
          ),

          // 🔙 Back Button (Bottom Left)
          Positioned(
            bottom: 50,
            left: 16,
            child: FloatingActionButton(
              heroTag: 'back',
              mini: true,
              backgroundColor: Colors.black87,
              child: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Back',
            ),
          ),

          (context.watch<ExperienceManager>().adsEnabled && _bannerAd != null && _isBannerAdLoaded)
              ? SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
          )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }


  Future<void> pickColor(BuildContext context) async {
    Color picked = selectedColor;

    await showDialog<Color>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Pick a color 🎨', style: TextStyle(fontFamily: 'Comic Sans MS')),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: picked,
            onColorChanged: (color) {
              picked = color;
            },
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 8,
        contentPadding: EdgeInsets.all(20),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(tr(context).ok),
          ),
        ],
      ),
    );

    setState(() {
      isErasing = false;
      selectedColor = picked;
      widget.onChanged(points, selectedColor, strokeWidth, isErasing, _elapsed);
    });
  }

  Future<void> pickStrokeWidth(BuildContext context) async {
    double tempStroke = strokeWidth;

    double? selectedWidth = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Brush Size ✏️', style: TextStyle(fontFamily: 'Comic Sans MS')),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    min: 1,
                    max: 30,
                    divisions: 29,
                    value: tempStroke,
                    label: tempStroke.toStringAsFixed(1),
                    onChanged: (val) => setState(() => tempStroke = val),
                    activeColor: Colors.deepPurple,
                    inactiveColor: Colors.deepPurple.withAlpha(80),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('🖊', style: TextStyle(fontSize: 20)),
                      Text('✏️', style: TextStyle(fontSize: 26)),
                      Text('🖌', style: TextStyle(fontSize: 32)),
                    ],
                  ),
                ],
              );
            },
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 8,
          contentPadding: EdgeInsets.all(20),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(tempStroke),
              child: Text('OK', style: TextStyle(fontFamily: 'Comic Sans MS', fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (selectedWidth != null) {
      setState(() {
        strokeWidth = selectedWidth;
        isErasing = false;
        widget.onChanged(points, selectedColor, strokeWidth, isErasing, _elapsed);
      });
    }
  }
}
