import 'package:flutter/material.dart';

class DragAndDropSorter extends StatefulWidget {
  final List<String> items;
  final List<String> correctOrder;
  final Map<String, String> labels;
  final Map<String, String> imagePaths;

  const DragAndDropSorter({
    required this.items,
    required this.correctOrder,
    required this.labels,
    required this.imagePaths,
    super.key,
  });

  @override
  State<DragAndDropSorter> createState() => _DragAndDropSorterState();
}

class _DragAndDropSorterState extends State<DragAndDropSorter> {
  late List<String?> userOrder;
  bool submitted = false;
  bool isCorrect = false;

  @override
  void initState() {
    super.initState();
    userOrder = List<String?>.filled(widget.correctOrder.length, null);
  }

  void checkOrder() {
    isCorrect = true;
    for (int i = 0; i < widget.correctOrder.length; i++) {
      if (userOrder[i] != widget.correctOrder[i]) {
        isCorrect = false;
        break;
      }
    }
    setState(() {
      submitted = true;
    });
  }

  void resetExercise() {
    setState(() {
      userOrder = List<String?>.filled(widget.correctOrder.length, null);
      submitted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '🧩 اسحب الصور إلى الترتيب الصحيح:',
          style: const TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.correctOrder.length, (index) {
            return DragTarget<String>(
              onAccept: (data) {
                setState(() {
                  userOrder[index] = data;
                });
              },
              builder: (context, candidateData, rejectedData) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blueAccent),
                    color: Colors.grey.shade200,
                  ),
                  child: userOrder[index] != null
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        widget.imagePaths[userOrder[index]!]!,
                        width: 60,
                      ),
                      Text(
                        widget.labels[userOrder[index]!]!,
                        style: const TextStyle(fontSize: 16),
                      )
                    ],
                  )
                      : const Center(child: Text('فارغ')),
                );
              },
            );
          }),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 20,
          children: widget.items.map((item) {
            return Draggable<String>(
              data: item,
              feedback: Image.asset(widget.imagePaths[item]!, width: 60),
              childWhenDragging:
              Opacity(opacity: 0.3, child: Image.asset(widget.imagePaths[item]!, width: 60)),
              child: Column(
                children: [
                  Image.asset(widget.imagePaths[item]!, width: 60),
                  Text(widget.labels[item]!, style: const TextStyle(fontSize: 16)),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: checkOrder,
          child: const Text('تحقق'),
        ),
        const SizedBox(height: 10),
        if (submitted)
          Text(
            isCorrect ? '✅ أحسنت! الترتيب صحيح.' : '❌ حاول مرة أخرى!',
            style: TextStyle(
                fontSize: 20,
                color: isCorrect ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold),
          ),
        const SizedBox(height: 10),
        if (submitted)
          TextButton(
            onPressed: resetExercise,
            child: const Text('إعادة التمرين'),
          )
      ],
    );
  }
}
