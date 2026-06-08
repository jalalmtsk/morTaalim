import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../main.dart';

class GlobalStatsCard extends StatelessWidget {
  final double progress;
  final int badges;
  final int courseXp;
  final int completedCourses;
  final int totalCourses;

  const GlobalStatsCard({
    Key? key,
    required this.progress,
    required this.badges,
    required this.courseXp,
    required this.completedCourses,
    required this.totalCourses,
  }) : super(key: key);

  // ── palette ──────────────────────────────────────────────────
  static const _orange  = Color(0xFFFF9F43);
  static const _teal    = Color(0xFF4ECDC4);
  static const _pink    = Color(0xFFFF6B9D);
  static const _violet  = Color(0xFFA78BFA);
  static const _yellow  = Color(0xFFFFE66D);
  static const _white   = Colors.white;

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8F0), Color(0xFFF3EEFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _violet.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: _violet.withOpacity(0.15), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── circular progress ──────────────────────────────
          _ProgressRing(progress: progress, pct: pct),
          const SizedBox(width: 16),

          // ── stats ─────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(context).global,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF3D2C8D),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Chip(
                      icon: Icons.emoji_events_rounded,
                      label: '$badges ${tr(context).badges}',
                      bg: _yellow,
                      fg: const Color(0xFF7C4700),
                    ),
                    _Chip(
                      icon: Icons.bolt_rounded,
                      label: '$courseXp XP',
                      bg: _teal,
                      fg: const Color(0xFF044E47),
                    ),
                    _Chip(
                      icon: Icons.check_circle_rounded,
                      label: '$completedCourses/$totalCourses',
                      bg: _pink,
                      fg: _white,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated ring ──────────────────────────────────────────────
class _ProgressRing extends StatelessWidget {
  final double progress;
  final String pct;

  const _ProgressRing({required this.progress, required this.pct});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // outer glow ring
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: const [
                Color(0xFFFF9F43),
                Color(0xFFA78BFA),
                Color(0xFF4ECDC4),
                Color(0xFFFF9F43),
              ],
              stops: const [0.0, 0.33, 0.66, 1.0],
            ),
          ),
        ),
        // white inner mask
        Container(
          width: 74,
          height: 74,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFFFF8F0),
          ),
        ),
        // percent text
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$pct%',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF3D2C8D),
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'TOP',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Color(0xFFFF9F43),
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        // animated arc overlay — draws the actual progress
        SizedBox(
          width: 88,
          height: 88,
          child: CircularProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            strokeWidth: 6,
            backgroundColor: Colors.transparent,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFF8F0)),
          ),
        ),
      ],
    );
  }
}

// ── Stat chip ─────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;

  const _Chip({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: bg.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}