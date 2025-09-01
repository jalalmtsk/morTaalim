import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../XpSystem.dart';
import '../../tools/Ads_Manager.dart';

class WatchAdButton extends StatefulWidget {
  const WatchAdButton({super.key});

  @override
  State<WatchAdButton> createState() => _WatchAdFABState();
}

class _WatchAdFABState extends State<WatchAdButton>
    with SingleTickerProviderStateMixin {
  bool adAvailable = false;
  bool showLottie = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController =
    AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _checkAdAvailability();
  }

  Future<void> _checkAdAvailability() async {
    bool available = await AdHelper.showRewardedAd(context).timeout(
      const Duration(seconds: 5),
      onTimeout: () => false,
    );

    setState(() => adAvailable = available);
  }

  void _onTap() async {
    if (!adAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No ads available right now.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => showLottie = true);

    bool earnedReward = await AdHelper.showRewardedAd(context);

    if (earnedReward) {
      Provider.of<ExperienceManager>(context, listen: false)
          .addStarBanner(context, 1);
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => showLottie = false);
    });

    _checkAdAvailability();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _onTap,
      backgroundColor: adAvailable ? Colors.greenAccent : Colors.grey,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: child,
        ),
        child: showLottie
            ? SizedBox(
          key: const ValueKey('lottie'),
          height: 80,
          width: 80,
          child: Lottie.asset(
            'assets/animations/UI_Animations/AdsGift.json',
            repeat: true,
            fit: BoxFit.contain,
          ),
        )
            : Icon(
          Icons.local_activity,
          key: const ValueKey('icon'),
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
