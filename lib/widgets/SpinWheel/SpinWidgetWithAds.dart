import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../XpSystem.dart';
import '../../tools/Ads_Manager.dart';

class SpinButtonWithAd extends StatefulWidget {
  const SpinButtonWithAd({Key? key}) : super(key: key);

  @override
  State<SpinButtonWithAd> createState() => _SpinButtonWithAdState();
}

class _SpinButtonWithAdState extends State<SpinButtonWithAd> {
  bool isSpinAvailable = true;
  int countdown = 0;
  Timer? _timer;

  void startCooldown({int seconds = 60}) {
    setState(() {
      isSpinAvailable = false;
      countdown = seconds;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown <= 1) {
        timer.cancel();
        setState(() {
          isSpinAvailable = true;
        });
      } else {
        setState(() {
          countdown--;
        });
      }
    });
  }

  void _onSpinPressed() {
    if (!isSpinAvailable) return;

    // Logic when spin is pressed
    Provider.of<ExperienceManager>(context, listen: false).addXP(5);

    // Start cooldown
    startCooldown(seconds: 60); // Set your cooldown duration
  }

  void _onWatchAdPressed() {
    AdHelper.showRewardedAdWithLoading(context, () {
      _timer?.cancel();
      setState(() {
        isSpinAvailable = true;
        countdown = 0;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Glowing Spin Button
        GestureDetector(
          onTap: isSpinAvailable ? _onSpinPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: isSpinAvailable
                  ? [
                BoxShadow(
                  color: Colors.orangeAccent.withOpacity(0.8),
                  blurRadius: 20,
                  spreadRadius: 3,
                )
              ]
                  : [],
              gradient: LinearGradient(
                colors: isSpinAvailable
                    ? [Colors.orange, Colors.deepOrange]
                    : [Colors.grey.shade400, Colors.grey.shade600],
              ),
            ),
            child: const Icon(
              Icons.casino,
              size: 40,
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Countdown or Ready Message
        Text(
          isSpinAvailable
              ? "🎉 It's your turn!"
              : "⏳ Wait $countdown seconds",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 20),

        // Watch Ad to Unlock Turn Early
        if (!isSpinAvailable)
          ElevatedButton.icon(
            onPressed: _onWatchAdPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.ondemand_video),
            label: const Text("Watch Ad to Unlock Turn"),
          ),
      ],
    );
  }
}
