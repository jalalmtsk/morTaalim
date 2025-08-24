import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class ColorLinkScreen extends StatefulWidget {
  const ColorLinkScreen({super.key});

  @override
  State<ColorLinkScreen> createState() => _ColorLinkScreenState();
}

class _ColorLinkScreenState extends State<ColorLinkScreen>
    with SingleTickerProviderStateMixin {
  Map<Color, List<Offset>> paths = {};
  Map<Color, bool> completedPaths = {};
  Offset? startPoint;
  Color? currentColor;

  int score = 0;
  int level = 1;
  int timeLeft = 60;
  Timer? gameTimer;

  final Random random = Random();
  List<Map<String, dynamic>> circles = [];

  bool showCollisionFlash = false;
  Timer? flashTimer;

  final List<Color> availableColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.yellow,
  ];

  Size? screenSize;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    screenSize = MediaQuery.of(context).size;
    if (circles.isEmpty) {
      generateLevel();
      startTimer();
    }
  }

  void startTimer() {
    gameTimer?.cancel();
    timeLeft = 60;
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft <= 0) {
        timer.cancel();
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Time's Up!"),
            content: Text("Your score: $score"),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    resetGame();
                  },
                  child: const Text("Restart"))
            ],
          ),
        );
      } else {
        setState(() {
          timeLeft--;
        });
      }
    });
  }

  void resetGame() {
    setState(() {
      paths.clear();
      completedPaths.clear();
      startPoint = null;
      currentColor = null;
      score = 0;
      level = 1;
      generateLevel();
      startTimer();
    });
  }

  void generateLevel() {
    if (screenSize == null) return;

    circles.clear();
    paths.clear();
    completedPaths.clear();

    int numColors = min(availableColors.length, level + 2);
    List<Color> colors = availableColors.sublist(0, numColors);

    for (Color color in colors) {
      circles.add({'position': randomOffset(), 'color': color});
      circles.add({'position': randomOffset(), 'color': color});
      paths[color] = [];
      completedPaths[color] = false;
    }
  }

  Offset randomOffset() {
    Offset newOffset;
    bool isValid;
    int attempts = 0;
    do {
      double x = 50 + random.nextDouble() * (screenSize!.width - 100);
      double y = 150 + random.nextDouble() * (screenSize!.height - 250);
      newOffset = Offset(x, y);

      isValid = true;
      for (var circle in circles) {
        if ((circle['position'] - newOffset).distance < 80) {
          isValid = false;
          break;
        }
      }

      attempts++;
      if (attempts > 100) break;
    } while (!isValid);

    return newOffset;
  }

  bool isInsideCircle(Offset point, Map<String, dynamic> circle) {
    return (point - circle['position']).distance <= 30;
  }

  bool doesCrossOtherPathsSegment(Offset p1, Offset p2) {
    if (currentColor == null) return false;
    const double lineRadius = 16;

    for (var entry in paths.entries) {
      if (entry.key == currentColor) continue;

      List<Offset> otherPath = entry.value;
      for (int i = 0; i < otherPath.length - 1; i++) {
        Offset q1 = otherPath[i];
        Offset q2 = otherPath[i + 1];

        if ((q1 - q2).distance < 5) continue;

        if (segmentsIntersect(p1, p2, q1, q2)) return true;

        for (double t = 0; t <= 1; t += 0.25) {
          Offset sample = Offset(
            p1.dx + t * (p2.dx - p1.dx),
            p1.dy + t * (p2.dy - p1.dy),
          );
          if (lineDistance(q1, q2, sample) < lineRadius) return true;
        }
      }
    }
    return false;
  }

  double lineDistance(Offset a, Offset b, Offset p) {
    final double dx = b.dx - a.dx;
    final double dy = b.dy - a.dy;
    if (dx == 0 && dy == 0) return (p - a).distance;

    double t = ((p.dx - a.dx) * dx + (p.dy - a.dy) * dy) / (dx * dx + dy * dy);
    t = t.clamp(0.0, 1.0);
    Offset projection = Offset(a.dx + t * dx, a.dy + t * dy);
    return (p - projection).distance;
  }

  bool segmentsIntersect(Offset p1, Offset p2, Offset q1, Offset q2) {
    double det(Offset a, Offset b) => a.dx * b.dy - a.dy * b.dx;

    Offset r = p2 - p1;
    Offset s = q2 - q1;
    double denominator = det(r, s);

    if (denominator == 0) return false;

    double t = det(q1 - p1, s) / denominator;
    double u = det(q1 - p1, r) / denominator;

    return t >= 0 && t <= 1 && u >= 0 && u <= 1;
  }

  void completePath(Color color) {
    completedPaths[color] = true;
    score += 10;
    checkLevelCompletion();
  }

  void checkLevelCompletion() {
    bool allCompleted = completedPaths.values.every((completed) => completed);
    if (allCompleted) {
      level++;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Level $level!"),
          content: const Text("Great job! Next level!"),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    generateLevel();
                  });
                },
                child: const Text("Next"))
          ],
        ),
      );
    }
  }

  void showFlash() {
    setState(() => showCollisionFlash = true);
    flashTimer?.cancel();
    flashTimer = Timer(const Duration(milliseconds: 150), () {
      setState(() => showCollisionFlash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.blueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          GestureDetector(
            onPanStart: (details) {
              final localPos = details.localPosition;
              for (var circle in circles) {
                if (isInsideCircle(localPos, circle) &&
                    !completedPaths[circle['color']]!) {
                  startPoint = circle['position'];
                  currentColor = circle['color'];
                  paths[currentColor!] = [startPoint!];
                  break;
                }
              }
            },
            onPanUpdate: (details) {
              if (startPoint != null && currentColor != null) {
                final pos = details.localPosition;
                List<Offset> currentPath = paths[currentColor!]!;
                if (currentPath.isNotEmpty &&
                    (pos - currentPath.last).distance > 4) {
                  Offset lastPoint = currentPath.last;

                  // Collision with other paths
                  if (doesCrossOtherPathsSegment(lastPoint, pos)) {
                    showFlash();
                    setState(() {
                      paths[currentColor!] = [paths[currentColor!]!.first];
                      startPoint = null;
                      currentColor = null;
                    });
                    return;
                  }

                  // Collision with other circles (excluding start circle)
                  for (var circle in circles) {
                    if (circle['color'] != currentColor &&
                        isInsideCircle(pos, circle)) {
                      showFlash();
                      setState(() {
                        paths[currentColor!] = [paths[currentColor!]!.first];
                        startPoint = null;
                        currentColor = null;
                      });
                      return;
                    }
                  }

                  // Snap-to-dot if near the target circle
                  for (var circle in circles) {
                    if (circle['color'] == currentColor &&
                        circle['position'] != paths[currentColor!]!.first) {
                      if ((pos - circle['position']).distance < 20) {
                        setState(() {
                          currentPath.add(circle['position']);
                        });
                        return;
                      }
                    }
                  }

                  setState(() {
                    currentPath.add(pos);
                  });
                }
              }
            },
            onPanEnd: (details) {
              if (currentColor != null && paths[currentColor!]!.isNotEmpty) {
                bool connected = false;
                Offset endPoint = paths[currentColor!]!.last;

                for (var circle in circles) {
                  if (circle['color'] == currentColor &&
                      circle['position'] != paths[currentColor!]!.first &&
                      isInsideCircle(endPoint, circle)) {
                    connected = true;
                    completePath(currentColor!);
                    break;
                  }
                }

                if (!connected) {
                  setState(() {
                    paths[currentColor!] = [paths[currentColor!]!.first];
                  });
                }
              }

              startPoint = null;
              currentColor = null;
            },
            child: CustomPaint(
              painter: _LinePainter(circles, paths, completedPaths,
                  showCollisionFlash, startPoint),
              child: Container(),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            right: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Score: $score",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  "Time: $timeLeft s",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                IconButton(
                    onPressed: resetGame,
                    icon: const Icon(Icons.refresh, color: Colors.white))
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<Map<String, dynamic>> circles;
  final Map<Color, List<Offset>> paths;
  final Map<Color, bool> completedPaths;
  final bool showFlash;
  final Offset? flashPosition;

  _LinePainter(this.circles, this.paths, this.completedPaths, this.showFlash,
      this.flashPosition);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    // Draw paths
    paths.forEach((color, points) {
      if (points.length < 2) return;
      paint.color = color.withOpacity(0.8);
      for (int i = 0; i < points.length - 1; i++) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    });

    // Draw circles
    for (var circle in circles) {
      paint.color = circle['color'];
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(circle['position'], 30, paint);

      if (completedPaths[circle['color']] == true) {
        paint.color = Colors.white;
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 4;
        canvas.drawCircle(circle['position'], 35, paint);
      }
    }

    // Draw red flash on collision
    if (showFlash && flashPosition != null) {
      paint.color = Colors.red;
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 6;
      canvas.drawCircle(flashPosition!, 40, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
