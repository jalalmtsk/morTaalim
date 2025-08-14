import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';


class DragonBubblePopSpark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dragon Bubble Pop Sparkles',
      debugShowCheckedModeBanner: false,
      home: SparkGameScreen(),
    );
  }
}

class Bubble {
  double x;
  double y;
  Color color;
  double size;
  bool isGolden;

  Bubble({
    required this.x,
    required this.y,
    required this.color,
    this.size = 40,
    this.isGolden = false,
  });
}

class Spark {
  double x;
  double y;
  Color color;
  double size;
  int life;

  Spark({required this.x, required this.y, required this.color, this.size = 5, this.life = 15});
}

class SparkGameScreen extends StatefulWidget {
  @override
  State<SparkGameScreen> createState() => _SparkGameScreenState();
}

class _SparkGameScreenState extends State<SparkGameScreen>
    with SingleTickerProviderStateMixin {
  List<Bubble> bubbles = [];
  List<Spark> sparks = [];
  Random random = Random();
  int score = 0;
  bool isPlaying = false;
  Timer? gameTimer;
  Timer? bubbleTimer;
  double dragonMouthX = 0;
  double dragonMouthY = 0.85;

  late AnimationController dragonController;
  late Animation<double> dragonAnimation;

  @override
  void initState() {
    super.initState();
    dragonController =
    AnimationController(vsync: this, duration: Duration(seconds: 1))
      ..repeat(reverse: true);
    dragonAnimation =
        Tween<double>(begin: -0.1, end: 0.1).animate(dragonController);
  }

  @override
  void dispose() {
    dragonController.dispose();
    bubbleTimer?.cancel();
    gameTimer?.cancel();
    super.dispose();
  }

  void startGame() {
    setState(() {
      score = 0;
      isPlaying = true;
      bubbles.clear();
      sparks.clear();
    });

    bubbleTimer?.cancel();
    bubbleTimer = Timer.periodic(Duration(milliseconds: 800), (timer) {
      double x = dragonMouthX + random.nextDouble() * 0.1 - 0.05;
      bool golden = random.nextInt(10) == 0;
      bubbles.add(Bubble(
        x: x,
        y: dragonMouthY,
        color: golden ? Colors.amber : Colors.blue,
        size: golden ? 50 : 40,
        isGolden: golden,
      ));
    });

    gameTimer?.cancel();
    gameTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      // Move bubbles
      for (var bubble in bubbles) {
        bubble.y -= 0.02;
      }
      bubbles.removeWhere((b) => b.y < -1);

      // Update sparks
      List<Spark> aliveSparks = [];
      for (var spark in sparks) {
        spark.y -= 0.01;
        spark.life -= 1;
        if (spark.life > 0) aliveSparks.add(spark);
      }
      sparks = aliveSparks;

      setState(() {});
    });
  }

  void popBubble(Bubble bubble) {
    setState(() {
      score += bubble.isGolden ? 5 : 1;
      // Create sparks
      for (int i = 0; i < 10; i++) {
        sparks.add(Spark(
          x: bubble.x + random.nextDouble() * 0.05 - 0.025,
          y: bubble.y,
          color: bubble.color,
          size: random.nextDouble() * 8 + 3,
          life: 10 + random.nextInt(10),
        ));
      }
      bubbles.remove(bubble);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[200],
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 20),
            Text(
              "Score: $score",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated Dragon
                  AnimatedBuilder(
                    animation: dragonAnimation,
                    builder: (context, child) {
                      return Align(
                        alignment:
                        Alignment(dragonAnimation.value, dragonMouthY),
                        child: Icon(Icons.whatshot,
                            size: 80, color: Colors.green),
                      );
                    },
                  ),
                  // Bubbles
                  ...bubbles.map((bubble) {
                    return Align(
                      alignment: Alignment(bubble.x, bubble.y),
                      child: GestureDetector(
                        onTap: () => popBubble(bubble),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 100),
                          width: bubble.size,
                          height: bubble.size,
                          decoration: BoxDecoration(
                            color: bubble.color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: bubble.color.withOpacity(0.5),
                                blurRadius: 5,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  // Sparks
                  ...sparks.map((spark) {
                    return Align(
                      alignment: Alignment(spark.x, spark.y),
                      child: Container(
                        width: spark.size,
                        height: spark.size,
                        decoration: BoxDecoration(
                          color: spark.color.withOpacity((spark.life / 15).clamp(0.0, 1.0)),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }).toList(),
                  if (!isPlaying)
                    Center(
                      child: Text(
                        "Tap to Start 🐉",
                        style: TextStyle(
                            fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 20),
            if (!isPlaying)
              ElevatedButton(
                onPressed: startGame,
                child: Text("Start Game", style: TextStyle(fontSize: 20)),
              ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
