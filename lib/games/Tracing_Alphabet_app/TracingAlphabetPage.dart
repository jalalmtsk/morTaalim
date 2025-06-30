import 'package:flutter/material.dart';


class AlphabetTracingPage extends StatefulWidget {
  final String language; // 'french' or 'arabic'

  const AlphabetTracingPage({super.key, required this.language});

  @override
  State<AlphabetTracingPage> createState() => _AlphabetTracingPageState();
}

class _AlphabetTracingPageState extends State<AlphabetTracingPage> {

  late List<String> _letters;
  int _currentLetterIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.language == 'arabic') {
      _letters = ['ا', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ']; // full Arabic alphabet here
    } else {
      _letters = List.generate(26, (i) => String.fromCharCode(65 + i)); // A-Z
    }
  }

  final GlobalKey _paintKey = GlobalKey();
  List<Offset?> _points = [];


  void _clearCanvas() {
    setState(() {
      _points.clear();
    });
  }

  void _nextLetter() {
    setState(() {
      _currentLetterIndex = (_currentLetterIndex + 1) % _letters.length;
      _points.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentLetter = _letters[_currentLetterIndex];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alphabet Tracing'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 300,
              height: 300,
              child: Stack(
                children: [
                  // Big letter in background
                  Center(
                    child: Text(
                      currentLetter,
                      style: TextStyle(
                        fontSize: 200,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade200,
                      ),
                    ),
                  ),

                  // Drawing canvas on top
                  GestureDetector(
                    onPanUpdate: (details) {
                      final box = _paintKey.currentContext?.findRenderObject() as RenderBox?;
                      if (box != null) {
                        final localPosition = box.globalToLocal(details.globalPosition);
                        setState(() {
                          _points = List.from(_points)..add(localPosition);
                        });
                      }
                    },
                    onPanEnd: (details) {
                      setState(() {
                        _points = List.from(_points)..add(null); // Stroke separator
                      });
                    },
                    child: CustomPaint(
                      key: _paintKey,
                      painter: TracingPainter(points: _points),
                      size: const Size(300, 300),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _clearCanvas,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: _nextLetter,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next Letter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TracingPainter extends CustomPainter {
  final List<Offset?> points;

  TracingPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.deepOrange
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant TracingPainter oldDelegate) => oldDelegate.points != points;
}
