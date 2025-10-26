import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  /// Initialize Ads
  static void initializeAds() {
    MobileAds.instance.initialize();
  }

  /// Get correct Ad Unit IDs based on Platform
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-9936922975297046/2736323402'; // Android Banner
    } else if (Platform.isIOS) {
      return 'ca-app-pub-9936922975297046/5532318884'; // iOS Banner
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-9936922975297046/8354774722'; // Android Interstitial
    } else if (Platform.isIOS) {
      return 'ca-app-pub-9936922975297046/5809033948'; // iOS Interstitial
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-9936922975297046/5494650006'; // Android Rewarded
    } else if (Platform.isIOS) {
      return 'ca-app-pub-9936922975297046/9162133201'; // iOS Rewarded
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  /// Banner Ad
  static BannerAd getBannerAd(Function onAdLoaded) {
    final BannerAd banner = BannerAd(
      adUnitId: bannerAdUnitId,
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

  /// Interstitial Ad with loading UI
  static Future<void> showInterstitialAd({
    required BuildContext context,
    Function? onDismissed,
  }) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
      const Center(child: CircularProgressIndicator(color: Colors.deepOrange)),
    );

    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          if (Navigator.canPop(context)) Navigator.of(context).pop();

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              onDismissed?.call();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              debugPrint('❌ InterstitialAd failed to show: ${error.message}');
              onDismissed?.call();
            },
          );

          ad.show();
        },
        onAdFailedToLoad: (error) {
          if (Navigator.canPop(context)) Navigator.of(context).pop();
          debugPrint('❌ InterstitialAd failed to load: ${error.message}');
          onDismissed?.call();
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
      builder: (_) =>
      const Center(child: CircularProgressIndicator(color: Colors.deepOrange)),
    );

    await RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          if (Navigator.canPop(context)) Navigator.of(context).pop();

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) => ad.dispose(),
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              debugPrint('❌ RewardedAd failed to show: ${error.message}');
            },
          );

          ad.show(onUserEarnedReward: (ad, reward) {
            onRewardEarned();
          });
        },
        onAdFailedToLoad: (LoadAdError error) {
          if (Navigator.canPop(context)) Navigator.of(context).pop();
          debugPrint('❌ RewardedAd failed to load: ${error.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ad failed to load. Try again later.')),
          );
        },
      ),
    );
  }

  /// Rewarded Ad returning Future<bool>
  static Future<bool> showRewardedAd(BuildContext context) {
    Completer<bool> completer = Completer<bool>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
      const Center(child: CircularProgressIndicator(color: Colors.deepOrange)),
    );

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          if (Navigator.canPop(context)) Navigator.of(context).pop();

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
          if (Navigator.canPop(context)) Navigator.of(context).pop();
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
