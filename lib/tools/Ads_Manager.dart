import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../XpSystem.dart';

class AdHelper {
  /// ✅ Call this in your `main()` function to initialize ads
  static void initializeAds() {
    MobileAds.instance.initialize();
  }

  /// ✅ Get a BannerAd instance
  static BannerAd getBannerAd(Function onAdLoaded) {
    final BannerAd banner = BannerAd(
      adUnitId: 'ca-app-pub-9936922975297046/2736323402', // ✅ Replace with real banner ad unit
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

  /// ✅ Show an Interstitial Ad
  static Future<void> showInterstitialAd({Function? onDismissed}) async {
    await InterstitialAd.load(
      adUnitId: 'ca-app-pub-9936922975297046/8354774722', // ❗ Replace this with your interstitial ad unit
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (onDismissed != null) onDismissed();
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

  /// ✅ Show Rewarded Ad with loading spinner
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
      adUnitId: 'ca-app-pub-9936922975297046/5494650006', // ✅ Replace with your real unit ID
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          Navigator.of(context).pop(); // close loading dialog

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) => ad.dispose(),
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              debugPrint('❌ RewardedAd failed to show: ${error.message}');
            },
          );

          ad.show(
            onUserEarnedReward: (ad, reward) {
              onRewardEarned(); // ✅ Callback for reward earned
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          Navigator.of(context).pop(); // close loading
          debugPrint('❌ RewardedAd failed to load: ${error.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ad failed to load. Try again later.')),
          );
        },
      ),
    );
  }

}
