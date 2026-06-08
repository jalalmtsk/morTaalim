import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../XpSystem.dart';

class IT_BinaryNumbers extends StatefulWidget {
  const IT_BinaryNumbers({super.key});
  @override
  State<IT_BinaryNumbers> createState() => _IT_BinaryNumbersState();
}

class _IT_BinaryNumbersState extends State<IT_BinaryNumbers> {
  final Random _rng = Random();

  int _bits = 4;           // starts at 4-bit, advances to 8-bit
  int _target = 0;
  List<int> _switches = [];// 0 or 1 per bit
  int _score = 0;
  int _round = 0;
  bool _showResult = false;
  bool _correct = false;
  static const int _totalRounds = 8;

  @override
  void initState() {
    super.initState();
    _nextRound();
  }

  void _nextRound() {
    _round++;
    if (_round == 5) _bits = 8; // advance to 8-bit halfway
    final max = pow(2, _bits).toInt();
    _target = _rng.nextInt(max - 1) + 1;
    _switches = List.filled(_bits, 0);
    _showResult = false;
  }

  int get _currentValue => _switches.asMap().entries.fold(0, (sum, e) {
    return sum + e.value * pow(2, _bits - 1 - e.key).toInt();
  });

  void _toggle(int index) {
    if (_showResult) return;
    setState(() => _switches[index] = _switches[index] == 0 ? 1 : 0);
  }

  void _check() {
    setState(() {
      _correct = _currentValue == _target;
      if (_correct) {
        _score++;
        Provider.of<ExperienceManager>(context, listen: false).addXP(2);
      }
      _showResult = true;
    });

    if (_round < _totalRounds) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _nextRound());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = _showResult && _round >= _totalRounds;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('💡 Binary Numbers'),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('$_score / $_round',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: done ? _buildDoneScreen() : _buildGameScreen(),
    );
  }

  Widget _buildGameScreen() {
    return Column(
      children: [
        const SizedBox(height: 24),

        // ── round indicator ────────────────────────────
        Text('Round $_round / $_totalRounds',
            style: const TextStyle(color: Colors.white54, fontSize: 14)),
        const SizedBox(height: 8),

        // ── target number ──────────────────────────────
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF7C3AED), width: 2),
          ),
          child: Column(
            children: [
              const Text('Make this number in binary:',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              Text('$_target',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 64, fontWeight: FontWeight.bold)),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // ── bit position labels ────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_bits, (i) {
              final val = pow(2, _bits - 1 - i).toInt();
              return SizedBox(
                width: _bits == 8 ? 36 : 60,
                child: Text('$val',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white38, fontSize: 12)),
              );
            }),
          ),
        ),

        const SizedBox(height: 8),

        // ── bulb switches ─────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_bits, (i) => _BulbSwitch(
              on: _switches[i] == 1,
              size: _bits == 8 ? 36 : 60,
              onTap: () => _toggle(i),
            )),
          ),
        ),

        const SizedBox(height: 8),

        // ── bit value labels ──────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_bits, (i) {
              return SizedBox(
                width: _bits == 8 ? 36 : 60,
                child: Text('${_switches[i]}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: _switches[i] == 1 ? Colors.amberAccent : Colors.white38,
                        fontSize: 20, fontWeight: FontWeight.bold)),
              );
            }),
          ),
        ),

        const SizedBox(height: 24),

        // ── current value display ─────────────────────
        Text('Current value: $_currentValue',
            style: const TextStyle(color: Colors.white70, fontSize: 18)),

        const SizedBox(height: 24),

        // ── feedback / check button ───────────────────
        if (_showResult)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _correct ? Colors.green.shade700 : Colors.red.shade700,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _correct ? '✅ Correct! +2 XP' : '❌ That was $_target in binary: ${_target.toRadixString(2).padLeft(_bits, "0")}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          )
        else
          ElevatedButton(
            onPressed: _check,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            child: const Text('Check ✓'),
          ),
      ],
    );
  }

  Widget _buildDoneScreen() {
    final perfect = _score == _totalRounds;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(perfect ? '🏆' : '🎮', style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(perfect ? 'Binary Master!' : 'Good effort!',
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Score: $_score / $_totalRounds',
              style: const TextStyle(color: Colors.white70, fontSize: 20)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => setState(() { _bits = 4; _score = 0; _round = 0; _nextRound(); }),
            icon: const Icon(Icons.refresh),
            label: const Text('Play Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('← Back', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }
}

class _BulbSwitch extends StatelessWidget {
  final bool on;
  final double size;
  final VoidCallback onTap;
  const _BulbSwitch({required this.on, required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on ? Colors.amberAccent : const Color(0xFF2D2D4E),
          border: Border.all(
            color: on ? Colors.amber : Colors.white24,
            width: 2,
          ),
          boxShadow: on ? [
            BoxShadow(color: Colors.amberAccent.withOpacity(0.6),
                blurRadius: 12, spreadRadius: 2),
          ] : [],
        ),
        child: Icon(
          on ? Icons.lightbulb : Icons.lightbulb_outline,
          color: on ? Colors.white : Colors.white24,
          size: size * 0.5,
        ),
      ),
    );
  }
}