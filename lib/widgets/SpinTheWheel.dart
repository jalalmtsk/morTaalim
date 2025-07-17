import 'dart:math';
import 'package:flutter/material.dart';

class SpinTheWheel extends StatefulWidget {
  const SpinTheWheel({Key? key}) : super(key: key);

  @override
  State<SpinTheWheel> createState() => _SpinTheWheelState();
}

class _SpinTheWheelState extends State<SpinTheWheel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _angle = 0;
  bool _spinning = false;
  String? _reward;
  final List<String> rewards = [
    '+50 XP',
    '+100 XP',
    'x2 Booster',
    '+1 Avatar',
    '+20 Tokens'
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  Future<void> _spinWheel() async {
    if (_spinning) return;

    setState(() => _spinning = true);

    final random = Random();
    final spins = 5 + random.nextInt(5); // total spins
    final segment = 360 / rewards.length;
    final resultIndex = random.nextInt(rewards.length);

    final double endAngle = 360.0 * spins + (segment * resultIndex);
    final double radians = endAngle * (pi / 180);

    final animation = Tween<double>(begin: _angle, end: _angle + radians).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    animation.addListener(() {
      setState(() {
        _angle = animation.value;
      });
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _reward = rewards[resultIndex];
          _spinning = false;
        });
        _showRewardDialog();
      }
    });

    await _controller.forward(from: 0);
  }

  void _showRewardDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🎉 You won!'),
        content: Text(
          _reward!,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Nice!"),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildWheel() {
    final List<Color> colors = [
      Colors.red,
      Colors.orange,
      Colors.green,
      Colors.blue,
      Colors.purple
    ];
    final double segment = 2 * pi / rewards.length;

    return Container(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: _angle,
            child: Stack(
              children: List.generate(rewards.length, (index) {
                final startAngle = index * segment;
                return CustomPaint(
                  painter: SegmentPainter(
                    startAngle: startAngle,
                    sweepAngle: segment,
                    color: colors[index % colors.length],
                    label: rewards[index],
                  ),
                  child: Container(),
                );
              }),
            ),
          ),
          const Icon(Icons.arrow_drop_down, size: 50, color: Colors.black),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        _buildWheel(),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: _spinning ? null : _spinWheel,
          child: const Text("🎯 Spin the Wheel"),
        )
      ],
    );
  }
}

class SegmentPainter extends CustomPainter {
  final double startAngle;
  final double sweepAngle;
  final Color color;
  final String label;

  SegmentPainter({
    required this.startAngle,
    required this.sweepAngle,
    required this.color,
    required this.label,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final Rect rect =
    Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: 150);
    canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

    // Label
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
            fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final double angle = startAngle + sweepAngle / 2;
    final Offset labelOffset = Offset(
      size.width / 2 + cos(angle) * 100 - textPainter.width / 2,
      size.height / 2 + sin(angle) * 100 - textPainter.height / 2,
    );
    textPainter.paint(canvas, labelOffset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
