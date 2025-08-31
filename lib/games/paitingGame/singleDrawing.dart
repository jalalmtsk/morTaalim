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
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
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
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    audioManager.playSfx("assets/audios/UI_Audio/SFX_Audio/CinematicStart_SFX.mp3");
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
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    audioManager.playAlert("assets/audios/UI_Audio/SFX_Audio/TransisitonPages_SFX.mp3");
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
        SnackBar(content: Text(tr(context).drawSomethingBeforeSaving)),
      );
      return;
    }

    final xpManager = Provider.of<ExperienceManager>(context, listen: false);
    final audioManager = Provider.of<AudioManager>(context, listen: false);

    if (xpManager.saveTokenCount < 5) {
      // No tokens, force watching two ads
      await _watchTwoAdsAndSave(xpManager);
      return;
    }

    // User has tokens, offer choice
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context).save),
        content: Text(tr(context).youCanSpendONETolimToSaveOrWatchTwoAdsToSaveForFree),
        actions: [
          TextButton(
            onPressed: () {
              audioManager.playEventSound("clickButton2");
              Navigator.of(context).pop('ad');},
            child: Text(tr(context).watchAd),
          ),
          ElevatedButton(
            onPressed: () {
              audioManager.playEventSound("clickButton2");
              Navigator.of(context).pop('spend');},
            child: Text(tr(context).spendONETolim),
          ),
          TextButton(
            onPressed: () {
              audioManager.playEventSound("clickButton2");
              Navigator.of(context).pop(null);},
            child: Text(tr(context).cancel),
          ),
        ],
      ),
    );

    if (choice == null) {
      // Cancelled
      return;
    } else if (choice == 'ad') {
      await _watchTwoAdsAndSave(xpManager);
    } else if (choice == 'spend') {
      // Confirm spending token
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(tr(context).confirmSpending),
          content: Row(
            children: [
              Flexible(
                  child: Text(
                    overflow: TextOverflow.visible,
                      softWrap: true,
                      ' ${tr(context).thisWillDeductONEtolimProceed}?')),
              SizedBox(width: 8),
              Icon(Icons.generating_tokens_rounded, color: Colors.green),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                audioManager.playEventSound("cancelButton");
                Navigator.of(context).pop(false);},
              child: Text(tr(context).cancel),
            ),
            ElevatedButton(
              onPressed: () {
                audioManager.playEventSound("clickButton2");
                Navigator.of(context).pop(true);},
              child: Text(tr(context).confirm),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await _saveAndDeductToken(xpManager);
      }
    }
  }

  Future<void> _watchTwoAdsAndSave(ExperienceManager xpManager) async {
    await AdHelper.showRewardedAdWithLoading(context, () async {
      await AdHelper.showRewardedAdWithLoading(context, () async {
        if (!mounted) return;
        await _saveDrawing();
      });
    });
  }

  Future<void> _saveAndDeductToken(ExperienceManager xpManager) async {
    // Save the drawing first
    await _saveDrawing();

    // Check if widget is still active
    if (!mounted) return;

    // Deduct tokens
    xpManager.SpendTokenBanner(context, 5);

    // Clear the canvas
    clearCanvas();

    // Show snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Text(tr(context).drawingSaved),
              Text('-5 ', style: TextStyle(fontWeight: FontWeight.bold, color: CupertinoColors.activeGreen)),
              Icon(Icons.generating_tokens_rounded, color: CupertinoColors.systemGreen),
            ],
          ),
        ),
      );
    }
  }


  Future<void> _saveDrawing() async {
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
      }
    } catch (e) {
      print("Error saving drawing: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context).failedToSaveDrawing)),
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
    final xpManager = Provider.of<ExperienceManager>(context, listen: false);
    final audioManager = Provider.of<AudioManager>(context, listen: false);
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
                color: Colors.deepPurple.withValues(alpha: 0.85),
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
            top: 120, // ⬅️ moved down below the status bar
            right: 25,
            child: Row(
              children: [
                FloatingActionButton(
                  heroTag: 'color',
                  mini: true,
                  backgroundColor: selectedColor,
                  child: Icon(Icons.color_lens, color: useWhiteForeground(selectedColor) ? Colors.white : Colors.black),
                  onPressed: () {
                    audioManager.playEventSound("PopButton");
                    pickColor(context);},
                  tooltip: tr(context).chooseColor,
                ),
                SizedBox(width: 4),
                FloatingActionButton(
                  heroTag: "brush",
                  mini: true,
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.brush),
                  onPressed: () => pickStrokeWidth(context),
                  tooltip: tr(context).brushSize,
                ),
                SizedBox(width: 4),
                FloatingActionButton(
                  heroTag: "eraser",
                  mini: true,
                  backgroundColor: isErasing ? Colors.redAccent : Colors.grey,
                  child: Icon(isErasing ? Icons.remove_circle_outline : Icons.remove_circle),
                  onPressed: () => setState(() {
                    audioManager.playEventSound("PopButton");
                    isErasing = !isErasing;
                    widget.onChanged(points, selectedColor, strokeWidth, isErasing, _elapsed);
                  }),
                  tooltip: isErasing ? tr(context).eraserOn : tr(context).eraserOff,
                ),
                SizedBox(width: 4),
                FloatingActionButton(
                  heroTag: "clear",
                  mini: true,
                  backgroundColor: Colors.orangeAccent,
                  child: Icon(Icons.delete_forever),
                  onPressed: clearCanvas,
                  tooltip: tr(context).clearCanvas,
                ),
                SizedBox(width: 4),
                FloatingActionButton(
                  heroTag: tr(context).save,
                  mini: true,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.save),
                  onPressed: (){
                    audioManager.playEventSound("PopButton");
                    saveDrawing();
                  },
                  tooltip: tr(context).save,
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
              onPressed: () {
                audioManager.playEventSound("cancelButton");
                Navigator.of(context).pop();},
              tooltip: tr(context).back,
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
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    await showDialog<Color>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${tr(context).chooseColor} 🎨', style: TextStyle(fontFamily: 'Comic Sans MS')),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: picked,
            onColorChanged: (color) {
              audioManager.playEventSound("PopButton");
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
              audioManager.playEventSound("cancelButton");
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
                    activeColor: Colors.deepOrange,
                    inactiveColor: Colors.deepOrange.withAlpha(80),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('🖊', style: TextStyle(fontSize: 16)),
                      Text('✏️', style: TextStyle(fontSize: 26)),
                      Text('🖌', style: TextStyle(fontSize: 36)),
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
              onPressed: () {
                audioManager.playEventSound("cancelButton");
                Navigator.of(context).pop(tempStroke);},
              child: Text(tr(context).ok, style: TextStyle(fontFamily: 'Comic Sans MS', fontWeight: FontWeight.bold)),
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
