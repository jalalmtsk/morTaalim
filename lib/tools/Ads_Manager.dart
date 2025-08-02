import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  /// Initialize Ads
  static void initializeAds() {
    MobileAds.instance.initialize();
  }

  /// Banner Ad
  static BannerAd getBannerAd(Function onAdLoaded) {
    final BannerAd banner = BannerAd(
      adUnitId: 'ca-app-pub-9936922975297046/2736323402', // ✅ Replace with your real ID
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) => onAdLoaded(),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('❌ BannerAd failed: ${error.message}');
        },
      ),
    )..load();

    return banner;
  }

  /// Interstitial Ad
  static Future<void> showInterstitialAd({Function? onDismissed}) async {
    await InterstitialAd.load(
      adUnitId: 'ca-app-pub-9936922975297046/8354774722', // ✅ Replace with your real ID
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              onDismissed?.call();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              debugPrint('❌ InterstitialAd failed to show: ${error.message}');
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ InterstitialAd failed to load: ${error.message}');
        },
      ),
    );
  }

  /// Rewarded Ad with Loading UI
  static Future<void> showRewardedAdWithLoading(
      BuildContext context,
      VoidCallback onRewardEarned,
      ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.deepOrange),
      ),
    );

    await RewardedAd.load(
      adUnitId: 'ca-app-pub-9936922975297046/5494650006', // ✅  Real ID
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          Navigator.of(context).pop(); // close loading dialog

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              debugPrint('❌ RewardedAd failed to show: ${error.message}');
            },
          );

          ad.show(
            onUserEarnedReward: (ad, reward) {
              onRewardEarned();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          Navigator.of(context).pop(); // close loading dialog
          debugPrint('❌ RewardedAd failed to load: ${error.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ad failed to load. Try again later.')),
          );
        },
      ),
    );
  }




  static Future<bool> showRewardedAd(BuildContext context) {
    Completer<bool> completer = Completer<bool>();

    // Show loading spinner dialog while loading ad
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.deepOrange),
      ),
    );

    RewardedAd.load(
      adUnitId: 'ca-app-pub-9936922975297046/5494650006',
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          Navigator.of(context).pop(); // Close loading dialog

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              if (!completer.isCompleted) completer.complete(false);
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              if (!completer.isCompleted) completer.complete(false);
              ad.dispose();
              debugPrint('❌ RewardedAd failed to show: ${error.message}');
            },
          );

          ad.show(onUserEarnedReward: (ad, reward) {
            if (!completer.isCompleted) completer.complete(true);
          });
        },
        onAdFailedToLoad: (LoadAdError error) {
          Navigator.of(context).pop(); // Close loading dialog
          if (!completer.isCompleted) completer.complete(false);
          debugPrint('❌ RewardedAd failed to load: ${error.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ad failed to load. Try again later.')),
          );
        },
      ),
    );

    return completer.future;
  }



}
