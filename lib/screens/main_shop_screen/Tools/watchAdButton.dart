import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../../XpSystem.dart';
import '../../../main.dart';
import '../../../tools/Ads_Manager.dart';

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

    // Precharge une pub en arriere-plan, sans jamais l'afficher toute seule.
    _preloadAd();
  }

  void _preloadAd() {
    AdHelper.preloadRewardedAd(
      onLoaded: () {
        if (mounted) setState(() => adAvailable = true);
      },
      onFailed: () {
        if (mounted) setState(() => adAvailable = false);
      },
    );
  }

  void _onTap() async {
    if (!adAvailable || !AdHelper.isRewardedAdReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No ads available right now.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      adAvailable = false;
      showLottie = true;
    });

    bool earnedReward = await AdHelper.showPreloadedRewardedAd(context);

    if (earnedReward) {
      Provider.of<ExperienceManager>(context, listen: false)
          .addStarBanner(context, 1);
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => showLottie = false);
    });

    _preloadAd();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // FloatingActionButton.extended avec une etiquette texte explicite :
    // exige par la Families Ads Policy de Google Play, qui interdit les
    // declencheurs de pub non etiquetes ou qui se confondent avec le jeu.
    return FloatingActionButton.extended(
      onPressed: _onTap,
      backgroundColor: adAvailable ? Colors.greenAccent : Colors.grey,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: child,
        ),
        child: showLottie
            ? SizedBox(
          key: const ValueKey('lottie'),
          height: 32,
          width: 32,
          child: Lottie.asset(
            'assets/animations/UI_Animations/AdsGift.json',
            repeat: true,
            fit: BoxFit.contain,
          ),
        )
            : const Icon(
          Icons.ondemand_video,
          key: ValueKey('icon'),
          color: Colors.white,
          size: 22,
        ),
      ),
      label: Text(
        tr(context).watchAd,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
