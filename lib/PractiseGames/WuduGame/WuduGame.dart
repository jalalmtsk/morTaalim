import 'package:flutter/material.dart';
import 'package:mortaalim/tools/audio_tool.dart';

class WuduGameApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WuduGame();
  }
}

class WuduGame extends StatefulWidget {
  @override
  _WuduGameState createState() => _WuduGameState();
}

class _WuduGameState extends State<WuduGame> with TickerProviderStateMixin {
  final MusicPlayer player = MusicPlayer();

  final Map<String, String> stepImages = {
    'النية': 'assets/images/PractiseImage/WuduImages/intention.png',
    'غسل اليدين': 'assets/images/PractiseImage/WuduImages/hands_wudu.png',
    'المضمضة': 'assets/images/PractiseImage/WuduImages/mouth_wudu.png',
    'الاستنشاق': 'assets/images/PractiseImage/WuduImages/nose_wudu.png',
    'غسل الوجه': 'assets/images/PractiseImage/WuduImages/face_wudu.png',
    'غسل الذراعين': 'assets/images/PractiseImage/WuduImages/arm_wudu.png',
    'مسح الرأس': 'assets/images/PractiseImage/WuduImages/hear_wudu.png',
    'مسح الأذنين': 'assets/images/PractiseImage/WuduImages/ear_wudu.png',
    'غسل الرجلين': 'assets/images/PractiseImage/WuduImages/feet_wudu.png',
  };

  final Map<String, String> stepSounds = {
    'النية': 'assets/audios/tts_female/Wudu/intention_female.mp3',
    'غسل اليدين': 'assets/audios/tts_female/Wudu/hands_female.mp3',
    'المضمضة': 'assets/audios/tts_female/Wudu/mouth_female.mp3',
    'الاستنشاق': 'assets/audios/tts_female/Wudu/nose_female.mp3',
    'غسل الوجه': 'assets/audios/tts_female/Wudu/face_female.mp3',
    'غسل الذراعين': 'assets/audios/tts_female/Wudu/arms_female.mp3',
    'مسح الرأس': 'assets/audios/tts_female/Wudu/head_female.mp3',
    'مسح الأذنين': 'assets/audios/tts_female/Wudu/ears_female.mp3',
    'غسل الرجلين': 'assets/audios/tts_female/Wudu/feet_female.mp3',
  };

  final List<String> correctOrder = [
    'النية',
    'غسل اليدين',
    'المضمضة',
    'الاستنشاق',
    'غسل الوجه',
    'غسل الذراعين',
    'مسح الرأس',
    'مسح الأذنين',
    'غسل الرجلين'
  ];

  late List<String> userOrder;
  bool highlightCorrect = false;
  Map<String, AnimationController> _bounceControllers = {};
  String? draggingStep;

  @override
  void initState() {
    super.initState();
    userOrder = List.from(correctOrder)..shuffle();

    for (var step in correctOrder) {
      _bounceControllers[step] = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400),
        lowerBound: 0.0,
        upperBound: 0.1,
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _bounceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> playSound(String step) async {
    final path = stepSounds[step];
    if (path != null) {
      await player.stop();
      await player.play(path);
    }
  }

  Future<void> stopSound() async {
    await player.stop();
  }

  void checkOrder() {
    bool isCorrect = true;
    for (int i = 0; i < correctOrder.length; i++) {
      if (correctOrder[i] != userOrder[i]) {
        isCorrect = false;
        break;
      }
    }

    setState(() {
      highlightCorrect = isCorrect;
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isCorrect ? '🎉 أحسنت!' : '❌ حاول مرة أخرى',
          textDirection: TextDirection.rtl,
          style: TextStyle(fontSize: 24),
        ),
        content: Text(
          isCorrect
              ? 'لقد رتبت خطوات الوضوء بشكل صحيح. بارك الله فيك!'
              : 'ترتيب غير صحيح. حاول ترتيب الخطوات بشكل صحيح.',
          textDirection: TextDirection.rtl,
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('موافق', style: TextStyle(fontSize: 18)),
          )
        ],
      ),
    );
  }

  Widget buildStepCard(String step, {required Key key}) {
    final isCorrectStep =
        highlightCorrect && correctOrder[userOrder.indexOf(step)] == step;

    final controller = _bounceControllers[step]!;
    final scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );

    return Container(
      key: key,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: () async {
          await controller.forward();
          await controller.reverse();
          await playSound(step);
        },
        child: ScaleTransition(
          scale: scaleAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: isCorrectStep ? Colors.green[100] : Colors.lightBlue[50],
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.teal, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withValues(alpha: 0.2),
                  blurRadius: 5,
                  offset: Offset(2, 2),
                )
              ],
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(12),
              leading: Image.asset(
                stepImages[step] ?? '',
                width: 50,
                height: 50,
                fit: BoxFit.contain,
              ),
              title: Center(
                child: Text(
                  step,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[900],
                  ),
                ),
              ),
              trailing: IconButton(
                icon: Icon(Icons.volume_up, color: Colors.teal),
                onPressed: () => playSound(step),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.teal[50],
        appBar: AppBar(
          backgroundColor: Colors.teal,
          title: Text('لعبة ترتيب خطوات الوضوء', style: TextStyle(fontSize: 22)),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                '🎯 قم بسحب الخطوات بالترتيب الصحيح من الأعلى إلى الأسفل:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 20),
              Expanded(
                child: ReorderableListView(
                  onReorderStart: (index) => draggingStep = userOrder[index],
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final item = userOrder.removeAt(oldIndex);
                      userOrder.insert(newIndex, item);
                    });
                    stopSound();
                  },
                  children: userOrder
                      .map((step) => buildStepCard(step, key: ValueKey(step)))
                      .toList(),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: checkOrder,
                icon: Icon(Icons.check_circle_outline),
                label: Text('تحقق من الترتيب', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
