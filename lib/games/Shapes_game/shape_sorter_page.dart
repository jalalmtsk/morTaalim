import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:mortaalim/games/Shapes_game/shape_data.dart';

class ShapeSorterPage extends StatefulWidget {
  final int shapeCount;
  const ShapeSorterPage({required this.shapeCount, super.key});

  @override
  State<ShapeSorterPage> createState() => _ShapeSorterPageState();
}

class _ShapeSorterPageState extends State<ShapeSorterPage> with SingleTickerProviderStateMixin {
  late List<ShapeData> shapes;
  final Set<String> matchedShapes = {};
  late ConfettiController _confettiController;

  int score = 0;
  int timeLeft = 20;
  Timer? countdownTimer;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    shapes = allShapes.take(widget.shapeCount).toList();
    if (widget.shapeCount >= 4) {
      _startTimer();
    }
  }

  void _startTimer() {
    countdownTimer?.cancel();
    timeLeft = widget.shapeCount == 2 ? 60 : (widget.shapeCount == 4 ? 30 : 20);
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft == 0) {
        timer.cancel();
        _showGameOverDialog();
      } else if (matchedShapes.length == shapes.length) {
        timer.cancel();
      } else {
        setState(() => timeLeft--);
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    countdownTimer?.cancel();
    super.dispose();
  }

  void _onShapeMatched(String name) {
    if (matchedShapes.contains(name)) return;
    setState(() {
      matchedShapes.add(name);
      score += 10;
      if (matchedShapes.length == shapes.length) {
        _confettiController.play();
        _showSuccessDialog();
      }
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Congratulations!'),
        content: Text('You matched all shapes!\nYour score: $score'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetGame();
            },
            child: const Text('Play Again'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Back to Menu'),
          ),
        ],
      ),
    );
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Time\'s up!'),
        content: Text('Your score: $score\nTry again?'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetGame();
            },
            child: const Text('Retry'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Back to Menu'),
          ),
        ],
      ),
    );
  }

  void _resetGame() {
    setState(() {
      matchedShapes.clear();
      score = 0;
      _startTimer();
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = matchedShapes.length / shapes.length;
    final isHard = widget.shapeCount == 6;

    return Scaffold(
      appBar: AppBar(
        title: Text('Shape Sorter - ${widget.shapeCount} Shapes'),
        backgroundColor: Colors.deepOrange,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              children: [
                if (widget.shapeCount >= 3) ...[
                  Text('Time Left: $timeLeft seconds', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 6),
                ],
                LinearProgressIndicator(
                  value: progress,
                  color: Colors.deepOrange,
                  backgroundColor: Colors.orange.shade100,
                  minHeight: 10,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: shapes.map((shape) {
                    final matched = matchedShapes.contains(shape.name);
                    return DragTarget<String>(
                      onWillAccept: (data) => data == shape.name,
                      onAccept: (data) => _onShapeMatched(data!),
                      builder: (context, candidateData, rejectedData) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          width: matched ? (isHard ? 70 : 90) : (isHard ? 60 : 80),
                          height: matched ? (isHard ? 70 : 90) : (isHard ? 60 : 80),
                          decoration: BoxDecoration(
                            color: matched ? shape.color.withOpacity(0.3) : Colors.transparent,
                            borderRadius: shape.name == 'Circle' ? BorderRadius.circular(45) : BorderRadius.circular(8),
                            border: Border.all(
                              color: candidateData.isNotEmpty ? Colors.deepOrange : Colors.grey,
                              width: candidateData.isNotEmpty ? 4 : 2,
                            ),
                            boxShadow: matched
                                ? [
                              BoxShadow(
                                color: shape.color.withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ]
                                : [],
                          ),
                          child: Center(
                            child: matched
                                ? Icon(shape.icon, color: shape.color, size: isHard ? 50 : 60)
                                : Text(
                              shape.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: shapes.map((shape) {
                      final isMatched = matchedShapes.contains(shape.name);
                      return Draggable<String>(
                        data: shape.name,
                        feedback: Material(
                          color: Colors.transparent,
                          child: Icon(shape.icon, color: shape.color, size: isHard ? 50 : 70),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.4,
                          child: Icon(shape.icon, color: shape.color, size: isHard ? 50 : 60),
                        ),
                        child: isMatched
                            ? Opacity(
                          opacity: 0.3,
                          child: Icon(shape.icon, color: shape.color, size: isHard ? 50 : 60),
                        )
                            : Icon(shape.icon, color: shape.color, size: isHard ? 50 : 60),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [Colors.deepOrange, Colors.orange, Colors.yellow],
              numberOfParticles: 30,
              maxBlastForce: 20,
              minBlastForce: 10,
              gravity: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
