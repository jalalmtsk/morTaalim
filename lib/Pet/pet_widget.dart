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
    return ScaleTransition(
      scale: scaleAnim,
      child: Card(
        color: Colors.purple.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 200,
                width: 200,
                child: Lottie.asset('assets/lottie/evolving.json'),
              ),
              const SizedBox(height: 20),
              Text(
                'Evolving!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Time left: ${formatDuration(evolveSecondsLeft)}',
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.deepPurple,
                ),
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
    return Column(
      children: [
        // Pet image
        ScaleTransition(
          scale: scaleAnim,
          child: Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32)),
            elevation: 8,
            shadowColor: Colors.deepPurple.withOpacity(0.5),
            child: Container(
              height: 220,
              width: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                image: DecorationImage(
                  image: AssetImage(petImage),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Buttons as stats
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatButton(
              icon: Icons.restaurant,
              label: 'Feed',
              value: feed,
              maxValue: maxStat,
              color: Colors.orange,
              disabled: isEvolving || feed >= maxStat,
              onTap: onFeed,
            ),
            _StatButton(
              icon: Icons.local_drink,
              label: 'Water',
              value: water,
              maxValue: maxStat,
              color: Colors.blue,
              disabled: isEvolving || water >= maxStat,
              onTap: onWater,
            ),
            _StatButton(
              icon: Icons.sports_esports,
              label: 'Play',
              value: play,
              maxValue: maxStat,
              color: Colors.pink,
              disabled: isEvolving || play >= maxStat,
              onTap: onPlay,
            ),
          ],
        ),

        const SizedBox(height: 40),
      ],
    );
  }
}

class _StatButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final int maxValue;
  final Color color;
  final bool disabled;
  final VoidCallback onTap;

  const _StatButton({
    required this.icon,
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
    required this.disabled,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: value / maxValue,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Icon(icon, size: 36, color: disabled ? Colors.grey : color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$label',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: disabled ? Colors.grey : color),
          ),
          Text(
            '$value/$maxValue',
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}