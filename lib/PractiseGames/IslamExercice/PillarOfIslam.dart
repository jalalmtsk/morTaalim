import 'package:flutter/material.dart';
import 'package:mortaalim/tools/audio_tool.dart';

class PillarsGame extends StatefulWidget {
  const PillarsGame({super.key});

  @override
  State<PillarsGame> createState() => _PillarsGameState();
}

class _PillarsGameState extends State<PillarsGame> {
  final MusicPlayer player = MusicPlayer();

  final List<String> pillars = [
    'الشهادتان',
    'إقام الصلاة',
    'إيتاء الزكاة',
    'صوم رمضان',
    'حج البيت'
  ];

  final Map<String, String> audios = {
    'الشهادتان': 'assets/audios/shahada.mp3',
    'إقام الصلاة': 'assets/audios/salat.mp3',
    'إيتاء الزكاة': 'assets/audios/zakat.mp3',
    'صوم رمضان': 'assets/audios/ramadan.mp3',
    'حج البيت': 'assets/audios/hajj.mp3',
  };

  List<String> selectedOrder = [];

  void playSound(String pillar) async {
    String? path = audios[pillar];
    if (path != null) {
      await player.stop();
      await player.play(path);
    }
  }

  void handleTap(String pillar) {
    if (selectedOrder.contains(pillar) || selectedOrder.length >= 5) return;

    setState(() {
      selectedOrder.add(pillar);
    });

    playSound(pillar);

    if (selectedOrder.length == 5) {
      Future.delayed(const Duration(milliseconds: 700), checkAnswer);
    }
  }

  void checkAnswer() {
    final correctOrder = [
      'الشهادتان',
      'إقام الصلاة',
      'إيتاء الزكاة',
      'صوم رمضان',
      'حج البيت',
    ];

    bool isCorrect = true;
    for (int i = 0; i < correctOrder.length; i++) {
      if (selectedOrder[i] != correctOrder[i]) {
        isCorrect = false;
        break;
      }
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          isCorrect ? '🎉 أحسنت!' : '❌ خطأ',
          textDirection: TextDirection.rtl,
        ),
        content: Text(
          isCorrect
              ? 'ترتيب أركان الإسلام صحيح. ممتاز!'
              : 'الترتيب غير صحيح. حاول مرة أخرى.',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                selectedOrder.clear();
              });
            },
            child: const Text("حاول مجددًا"),
          )
        ],
      ),
    );
  }

  Widget buildPillarTile(String pillar) {
    int index = selectedOrder.indexOf(pillar);
    return GestureDetector(
      onTap: () => handleTap(pillar),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.teal.shade100,
          border: Border.all(color: Colors.teal.shade700, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Image.asset(
              'assets/images/islamic_icon.png',
              width: 40,
              height: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                pillar,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade900,
                ),
              ),
            ),
            if (index >= 0)
              CircleAvatar(
                backgroundColor: Colors.teal.shade700,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
          ],
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
          title: const Text('ترتيب أركان الإسلام'),
          backgroundColor: Colors.teal,
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'اضغط على أركان الإسلام بالترتيب الصحيح:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: pillars.map(buildPillarTile).toList(),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => selectedOrder.clear());
                },
                icon: const Icon(Icons.refresh),
                label: const Text("إعادة"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
