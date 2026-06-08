import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../XpSystem.dart';

class IT_InputOutput extends StatefulWidget {
  const IT_InputOutput({super.key});
  @override
  State<IT_InputOutput> createState() => _IT_InputOutputState();
}

class _IT_InputOutputState extends State<IT_InputOutput> {
  final List<Map<String, dynamic>> _devices = [
    {'name': 'Keyboard', 'icon': '⌨️', 'answer': 'input',  'placed': false},
    {'name': 'Mouse',    'icon': '🖱️', 'answer': 'input',  'placed': false},
    {'name': 'Microphone','icon':'🎙️', 'answer': 'input',  'placed': false},
    {'name': 'Scanner',  'icon': '🖨️', 'answer': 'input',  'placed': false},
    {'name': 'Monitor',  'icon': '🖥️', 'answer': 'output', 'placed': false},
    {'name': 'Printer',  'icon': '🖨️', 'answer': 'output', 'placed': false},
    {'name': 'Speaker',  'icon': '🔊', 'answer': 'output', 'placed': false},
    {'name': 'Projector','icon': '📽️', 'answer': 'output', 'placed': false},
  ];

  final List<String> _inputBucket  = [];
  final List<String> _outputBucket = [];
  int _score = 0;
  bool _done = false;

  void _onDrop(String bucketType, Map<String, dynamic> device) {
    if (device['placed']) return;
    setState(() {
      device['placed'] = true;
      final correct = device['answer'] == bucketType;
      if (bucketType == 'input')  _inputBucket.add(device['icon']);
      else                         _outputBucket.add(device['icon']);
      if (correct) _score++;
      _done = _devices.every((d) => d['placed']);
      if (_done && _score == _devices.length) {
        Provider.of<ExperienceManager>(context, listen: false).addXP(5);
      }
    });
  }

  Color _cardColor(Map<String, dynamic> d) {
    if (!d['placed']) return Colors.white;
    // find where it ended up
    final inInput  = _inputBucket.contains(d['icon']);
    final correct  = (inInput && d['answer'] == 'input') ||
        (!inInput && d['answer'] == 'output');
    return correct ? Colors.green.shade100 : Colors.red.shade100;
  }

  @override
  Widget build(BuildContext context) {
    final unplaced = _devices.where((d) => !d['placed']).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      appBar: AppBar(
        title: const Text('↔️ Input & Output'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('⭐ $_score / ${_devices.length}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── instruction ──────────────────────────────────
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Drag each device into the correct bucket!\n'
                  'INPUT = sends data TO the computer  |  OUTPUT = data COMES OUT',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF4F46E5), fontWeight: FontWeight.w500),
            ),
          ),

          // ── draggable device cards ────────────────────────
          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: unplaced.map((device) {
                return Draggable<Map<String, dynamic>>(
                  data: device,
                  feedback: Material(
                    color: Colors.transparent,
                    child: _DeviceCard(device: device, color: Colors.blue.shade100),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: _DeviceCard(device: device, color: Colors.white),
                  ),
                  child: _DeviceCard(device: device, color: Colors.white),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // ── two drop buckets ─────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(child: _Bucket(
                    label: 'INPUT',
                    emoji: '📥',
                    color: Colors.blue.shade50,
                    borderColor: Colors.blue.shade300,
                    items: _inputBucket,
                    onAccept: (d) => _onDrop('input', d),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _Bucket(
                    label: 'OUTPUT',
                    emoji: '📤',
                    color: Colors.purple.shade50,
                    borderColor: Colors.purple.shade300,
                    items: _outputBucket,
                    onAccept: (d) => _onDrop('output', d),
                  )),
                ],
              ),
            ),
          ),

          // ── done banner ──────────────────────────────────
          if (_done)
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: _score == _devices.length
                  ? Colors.green.shade600
                  : Colors.orange.shade600,
              child: Text(
                _score == _devices.length
                    ? '🎉 Perfect! +5 XP earned!'
                    : '🙂 $_score / ${_devices.length} correct! Try again!',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white,
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

          if (_done)
            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton.icon(
                onPressed: () => setState(() {
                  for (final d in _devices) d['placed'] = false;
                  _inputBucket.clear();
                  _outputBucket.clear();
                  _score = 0;
                  _done = false;
                }),
                icon: const Icon(Icons.refresh),
                label: const Text('Play Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final Map<String, dynamic> device;
  final Color color;
  const _DeviceCard({required this.device, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80, height: 80,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(device['icon'], style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 4),
          Text(device['name'],
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _Bucket extends StatelessWidget {
  final String label, emoji;
  final Color color, borderColor;
  final List<String> items;
  final void Function(Map<String, dynamic>) onAccept;
  const _Bucket({required this.label, required this.emoji, required this.color,
    required this.borderColor, required this.items, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return DragTarget<Map<String, dynamic>>(
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        final highlight = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: highlight ? borderColor.withOpacity(0.2) : color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: highlight ? 3 : 2),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Text(emoji, style: const TextStyle(fontSize: 30)),
              Text(label, style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: borderColor)),
              const Divider(),
              Expanded(
                child: Wrap(
                  spacing: 6, runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: items.map((e) =>
                      Text(e, style: const TextStyle(fontSize: 26))).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}