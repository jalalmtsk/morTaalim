import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// AdHelper — MoorTaalim (appli enfants)
/// Conforme Google Play Families Policy :
///   • TagForChildDirectedTreatment.yes  (COPPA)
///   • TagForUnderAgeOfConsent.yes       (GDPR-K)
///   • MaxAdContentRating.g              (Tous publics)
///   • nonPersonalizedAds: true          (pas de ciblage comportemental)
/// ════════════════════════════════════════════════════════════════════════════
class AdHelper {
  AdHelper._(); // non instanciable

  // ── Initialisation ────────────────────────────────────────────────────────

  /// À appeler dans main() AVANT runApp(), après WidgetsFlutterBinding.ensureInitialized()
  static Future<void> initializeAds() async {
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.yes,
        maxAdContentRating: MaxAdContentRating.g,
      ),
    );
    await MobileAds.instance.initialize();
    debugPrint('✅ AdMob initialisé — mode Families (COPPA ON, G-rated)');
  }

  // ── AdRequest child-safe (réutilisé partout) ──────────────────────────────

  static const AdRequest _childRequest = AdRequest(
    nonPersonalizedAds: true,
    keywords: <String>[],
  );

  // ── IDs de production ────────────────────────────────────────────────────

  static String get bannerAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-9936922975297046/2736323402';
    if (Platform.isIOS)     return 'ca-app-pub-9936922975297046/5532318884';
    throw UnsupportedError('Plateforme non supportée');
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-9936922975297046/8354774722';
    if (Platform.isIOS)     return 'ca-app-pub-9936922975297046/5809033948';
    throw UnsupportedError('Plateforme non supportée');
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-9936922975297046/5494650006';
    if (Platform.isIOS)     return 'ca-app-pub-9936922975297046/9162133201';
    throw UnsupportedError('Plateforme non supportée');
  }

  // ── Banner ────────────────────────────────────────────────────────────────

  /// Retourne un BannerAd child-safe prêt à être injecté dans FamilyAdBanner.
  static BannerAd getBannerAd(VoidCallback onAdLoaded) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      request: _childRequest,
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) => onAdLoaded(),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('❌ BannerAd failed: ${error.message}');
        },
      ),
    )..load();
  }

  // ── Interstitiel ──────────────────────────────────────────────────────────

  static Future<void> showInterstitialAd({
    required BuildContext context,
    VoidCallback? onDismissed,
  }) async {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.deepOrange),
      ),
    );

    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: _childRequest,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          if (context.mounted && Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              onDismissed?.call();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              debugPrint('❌ Interstitial failed to show: ${error.message}');
              onDismissed?.call();
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (error) {
          if (context.mounted && Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
          debugPrint('❌ Interstitial failed to load: ${error.message}');
          onDismissed?.call();
        },
      ),
    );
  }

  // ── Rewarded (avec loading dialog) ───────────────────────────────────────

  static Future<void> showRewardedAdWithLoading(
      BuildContext context,
      VoidCallback onRewardEarned,
      ) async {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.deepOrange),
      ),
    );

    await RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: _childRequest,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          if (context.mounted && Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) => ad.dispose(),
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              debugPrint('❌ RewardedAd failed to show: ${error.message}');
            },
          );
          ad.show(onUserEarnedReward: (_, __) => onRewardEarned());
        },
        onAdFailedToLoad: (error) {
          if (context.mounted && Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
          debugPrint('❌ RewardedAd failed to load: ${error.message}');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ad failed to load. Try again later.')),
            );
          }
        },
      ),
    );
  }

  // ── Rewarded → Future<bool> ───────────────────────────────────────────────

  static Future<bool> showRewardedAd(BuildContext context) {
    final completer = Completer<bool>();

    if (!context.mounted) return Future.value(false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.deepOrange),
      ),
    );

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: _childRequest,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          if (context.mounted && Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              if (!completer.isCompleted) completer.complete(false);
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              if (!completer.isCompleted) completer.complete(false);
              ad.dispose();
            },
          );
          ad.show(onUserEarnedReward: (_, __) {
            if (!completer.isCompleted) completer.complete(true);
          });
        },
        onAdFailedToLoad: (error) {
          if (context.mounted && Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
          if (!completer.isCompleted) completer.complete(false);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ad failed to load. Try again later.')),
            );
          }
        },
      ),
    );

    return completer.future;
  }
}

/// ════════════════════════════════════════════════════════════════════════════
/// FamilyAdBanner
/// Widget bannière conforme Families Policy :
///   • Label "Annonce" toujours visible au-dessus de la pub
///   • Fond neutre (gris clair) — jamais le thème du jeu
///   • Remplace tous les anciens _XxxBannerBar thématisés
///
/// Usage :
///   FamilyAdBanner(bannerAd: _bannerAd, isLoaded: _isBannerAdLoaded)
/// ════════════════════════════════════════════════════════════════════════════
class FamilyAdBanner extends StatelessWidget {
  final BannerAd? bannerAd;
  final bool isLoaded;

  const FamilyAdBanner({
    required this.bannerAd,
    required this.isLoaded,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoaded || bannerAd == null) return const SizedBox.shrink();

    return Container(
      // Fond neutre obligatoire — distingue visuellement la pub du contenu
      color: const Color(0xFFF5F5F5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Label "Annonce" ── obligatoire Families Policy ────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
            color: const Color(0xFFE0E0E0),
            child: const Text(
              'Annonce',
              style: TextStyle(
                fontSize: 10,
                color: Colors.black45,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          // ── Unité publicitaire ────────────────────────────────────────
          SizedBox(
            width: bannerAd!.size.width.toDouble(),
            height: bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: bannerAd!),
          ),
        ],
      ),
    );
  }
}