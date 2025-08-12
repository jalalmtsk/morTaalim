import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class EvolvingView extends StatelessWidget {
  final Animation<double> scaleAnim;
  final int evolveSecondsLeft;
  final String Function(int) formatDuration;

  const EvolvingView({
    super.key,
    required this.scaleAnim,
    required this.evolveSecondsLeft,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: ScaleTransition(
          scale: scaleAnim,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 220,
                width: 220,
                child: Lottie.asset('assets/lottie/evolving.json'),
              ),
              const SizedBox(height: 24),
              Text(
                'Evolving...',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade700),
              ),
              const SizedBox(height: 12),
              Text(
                'Time left: ${formatDuration(evolveSecondsLeft)}',
                style:
                const TextStyle(fontSize: 20, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PetView extends StatelessWidget {
  final String petImage;
  final Animation<double> scaleAnim;
  final int feed;
  final int water;
  final int play;
  final VoidCallback onFeed;
  final VoidCallback onWater;
  final VoidCallback onPlay;
  final int maxStat;
  final bool isEvolving;

  const PetView({
    super.key,
    required this.petImage,
    required this.scaleAnim,
    required this.feed,
    required this.water,
    required this.play,
    required this.onFeed,
    required this.onWater,
    required this.onPlay,
    required this.maxStat,
    required this.isEvolving,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: [
            ScaleTransition(
              scale: scaleAnim,
              child: Container(
                height: 220,
                width: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 3),
                  ],
                  image: DecorationImage(
                    image: AssetImage(petImage),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            _buildStatRow('Feed', feed, Colors.orange, maxStat),
            _buildStatRow('Water', water, Colors.blue, maxStat),
            _buildStatRow('Play', play, Colors.pinkAccent, maxStat),
            const SizedBox(height: 24),
            const Text(
              'Interact with your pet:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ActionButton(
                    icon: Icons.restaurant,
                    label: 'Feed',
                    color: Colors.orange,
                    disabled: isEvolving || feed >= maxStat,
                    onTap: onFeed),
                _ActionButton(
                    icon: Icons.local_drink,
                    label: 'Water',
                    color: Colors.blue,
                    disabled: isEvolving || water >= maxStat,
                    onTap: onWater),
                _ActionButton(
                    icon: Icons.sports_esports,
                    label: 'Play',
                    color: Colors.pink,
                    disabled: isEvolving || play >= maxStat,
                    onTap: onPlay),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int value, Color color, int maxStat) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 75,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: value / maxStat,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 12,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$value / $maxStat',
            style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: 16, color: color),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool disabled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.disabled,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: disabled ? Colors.grey.shade300 : color.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding:
          const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  color: disabled ? Colors.grey : color, size: 32),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      color: disabled ? Colors.grey : color,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
