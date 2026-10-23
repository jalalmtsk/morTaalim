import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:mortaalim/XpSystem.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// AdPolicy — MoorTaalim (appli enfants)
/// Toutes les règles de fréquence au même endroit. Ajuster ici uniquement.
/// ════════════════════════════════════════════════════════════════════════════
class AdPolicy {
  AdPolicy._();

  /// Aucune interstitielle pendant les premières minutes d'une session.
  static const Duration sessionGrace = Duration(minutes: 2);

  /// Écart minimum entre deux pubs plein écran (interstitielle OU récompensée).
  static const Duration minFullScreenGap = Duration(minutes: 3);

  /// Une interstitielle au maximum toutes les N fins de niveau / de partie.
  static const int completionsPerInterstitial = 2;

  /// Nombre maximum de pubs récompensées par jour.
  static const int rewardedDailyCap = 6;

  /// Durée de l'écran « Petite pause publicité… » avant l'interstitielle.
  static const Duration adBreakNotice = Duration(milliseconds: 1300);
}

/// ════════════════════════════════════════════════════════════════════════════
/// AdHelper — MoorTaalim (appli enfants)
/// Conforme Google Play Families Policy :
///   • TagForChildDirectedTreatment.yes  (COPPA)
///   • TagForUnderAgeOfConsent.yes       (GDPR-K)
///   • MaxAdContentRating.g              (Tous publics)
///   • nonPersonalizedAds: true          (pas de ciblage comportemental)
///
/// Règles d'affichage :
///   • Interstitielle : UNIQUEMENT à une pause naturelle (fin de niveau /
///     de partie), préchargée (aucun faux écran « chargement »), précédée
///     d'un écran clairement étiqueté « Publicité », et plafonnée par AdPolicy.
///     Si les règles ne permettent pas d'en afficher une, le jeu continue
///     immédiatement.
///   • Récompensée : UNIQUEMENT après un tap sur un bouton étiqueté
///     « Regarder une pub », plafonnée par jour.
///   • Bannière : UNIQUEMENT sur menus / pages de résultats via FamilyAdBanner,
///     jamais pendant une partie.
/// ════════════════════════════════════════════════════════════════════════════
class AdHelper {
  AdHelper._(); // non instanciable

  // ── État de session ───────────────────────────────────────────────────────

  static DateTime _sessionStart = DateTime.now();
  static DateTime? _lastFullScreenAt;
  static int _completionsSinceAd = 0;
  static bool _fullScreenShowing = false;
  static bool _initialized = false;

  // ── Initialisation ────────────────────────────────────────────────────────

  /// À appeler dans main() AVANT runApp(), après WidgetsFlutterBinding.ensureInitialized()
  static Future<void> initializeAds() async {
    if (_initialized) return;
    _initialized = true;
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.yes,
        maxAdContentRating: MaxAdContentRating.g,
      ),
    );
    _sessionStart = DateTime.now();
    // La config enfants est appliquée (await ci-dessus) avant toute requête ;
    // l'initialisation du SDK se poursuit sans bloquer le démarrage.
    unawaited(MobileAds.instance.initialize().then((_) {
      debugPrint('✅ AdMob initialisé — mode Families (COPPA ON, G-rated)');
      // Préchargement en arrière-plan (n'affiche jamais rien tout seul).
      preloadInterstitial();
      preloadRewardedAd();
    }));
  }

  // ── AdRequest child-safe (réutilisé partout) ──────────────────────────────

  static const AdRequest _childRequest = AdRequest(
    nonPersonalizedAds: true,
    keywords: <String>[],
  );

  /// Requête child-safe à utiliser si un écran charge lui-même une pub.
  static AdRequest get childRequest => _childRequest;

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

  // ── Bannière ──────────────────────────────────────────────────────────────

  /// Retourne un BannerAd child-safe prêt à être injecté dans FamilyAdBanner.
  /// À utiliser uniquement sur des menus / pages de résultats.
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

  // ════════════════════════════════════════════════════════════════════════
  // INTERSTITIELLE — fin de niveau / fin de partie uniquement
  // ════════════════════════════════════════════════════════════════════════

  static InterstitialAd? _interstitial;
  static bool _interstitialLoading = false;
  static Timer? _interstitialRetry;

  /// Charge une interstitielle en arrière-plan SANS l'afficher.
  static void preloadInterstitial() {
    if (_interstitial != null || _interstitialLoading) return;
    _interstitialLoading = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: _childRequest,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialLoading = false;
          _interstitial = ad;
        },
        onAdFailedToLoad: (error) {
          _interstitialLoading = false;
          debugPrint('❌ Interstitial preload failed: ${error.message}');
          _interstitialRetry?.cancel();
          _interstitialRetry =
              Timer(const Duration(seconds: 60), preloadInterstitial);
        },
      ),
    );
  }

  static bool get _fullScreenGapOk =>
      _lastFullScreenAt == null ||
      DateTime.now().difference(_lastFullScreenAt!) >= AdPolicy.minFullScreenGap;

  static bool get _interstitialAllowed =>
      !_fullScreenShowing &&
      DateTime.now().difference(_sessionStart) >= AdPolicy.sessionGrace &&
      _completionsSinceAd >= AdPolicy.completionsPerInterstitial &&
      _fullScreenGapOk;

  /// À appeler à la FIN d'un niveau / d'une partie (bouton « Continuer »,
  /// « Rejouer », « Niveau suivant »…), jamais pendant le jeu.
  ///
  /// Si les règles AdPolicy le permettent et qu'une pub est prête :
  /// écran « Petite pause publicité… » → interstitielle → [onDismissed].
  /// Sinon : [onDismissed] est appelé immédiatement, sans attente.
  static Future<void> showInterstitialAd({
    required BuildContext context,
    VoidCallback? onDismissed,
  }) async {
    _completionsSinceAd++;

    final ad = _interstitial;
    if (ad == null ||
        !_interstitialAllowed ||
        !context.mounted ||
        !_adsEnabled(context)) {
      if (ad == null) preloadInterstitial();
      onDismissed?.call();
      return;
    }

    _interstitial = null; // consommée
    _fullScreenShowing = true;

    await _showAdBreakNotice(context);

    final completer = Completer<void>();
    void finish() {
      if (completer.isCompleted) return;
      _fullScreenShowing = false;
      preloadInterstitial();
      onDismissed?.call();
      completer.complete();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        _lastFullScreenAt = DateTime.now();
        _completionsSinceAd = 0;
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        finish();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        debugPrint('❌ Interstitial failed to show: ${error.message}');
        finish();
      },
    );
    ad.show();
    return completer.future;
  }

  /// Respecte le réglage admin / « sans pub » (ExperienceManager.adsEnabled).
  static bool _adsEnabled(BuildContext context) {
    try {
      return Provider.of<ExperienceManager>(context, listen: false).adsEnabled;
    } catch (_) {
      return true;
    }
  }

  /// Alias explicite : fin de niveau / de partie.
  static Future<void> onLevelCompleted({
    required BuildContext context,
    VoidCallback? onContinue,
  }) =>
      showInterstitialAd(context: context, onDismissed: onContinue);

  /// Écran court et clairement étiqueté avant l'interstitielle, pour que
  /// l'enfant comprenne que ce qui suit est une publicité (pas le jeu).
  static Future<void> _showAdBreakNotice(BuildContext context) async {
    BuildContext? dialogCtx;
    final text = adText(context, 'adBreak');
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (c) {
        dialogCtx = c;
        return PopScope(canPop: false, child: _AdBreakNotice(text: text));
      },
    );
    await Future.delayed(AdPolicy.adBreakNotice);
    final c = dialogCtx;
    if (c != null && c.mounted) Navigator.of(c).pop();
  }

  // ════════════════════════════════════════════════════════════════════════
  // RÉCOMPENSÉE — uniquement depuis un bouton étiqueté « Regarder une pub »
  // ════════════════════════════════════════════════════════════════════════
  //
  // IMPORTANT : ne jamais appeler showRewardedAd()/showRewardedAdWithLoading()
  // juste pour "tester" si une pub existe — ces méthodes affichent la pub
  // dès qu'elle est chargée. Utiliser preloadRewardedAd() + isRewardedAdReady.

  static RewardedAd? _preloadedRewardedAd;
  static bool _rewardedLoading = false;
  static final List<VoidCallback> _rwOnLoaded = [];
  static final List<VoidCallback> _rwOnFailed = [];

  /// true seulement si une pub récompensée est chargée et prête à être
  /// affichée suite à un tap explicite de l'utilisateur.
  static bool get isRewardedAdReady => _preloadedRewardedAd != null;

  /// Charge une pub récompensée en arrière-plan SANS l'afficher.
  static void preloadRewardedAd({VoidCallback? onLoaded, VoidCallback? onFailed}) {
    if (_preloadedRewardedAd != null) {
      onLoaded?.call();
      return;
    }
    // Plusieurs écrans peuvent attendre le même chargement.
    if (onLoaded != null) _rwOnLoaded.add(onLoaded);
    if (onFailed != null) _rwOnFailed.add(onFailed);
    if (_rewardedLoading) return;
    _rewardedLoading = true;

    void flush(bool ok) {
      final cbs = List<VoidCallback>.of(ok ? _rwOnLoaded : _rwOnFailed);
      _rwOnLoaded.clear();
      _rwOnFailed.clear();
      for (final cb in cbs) {
        cb();
      }
    }

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: _childRequest,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedLoading = false;
          _preloadedRewardedAd = ad;
          flush(true);
        },
        onAdFailedToLoad: (error) {
          _rewardedLoading = false;
          debugPrint('❌ Preload RewardedAd failed: ${error.message}');
          _preloadedRewardedAd = null;
          flush(false);
        },
      ),
    );
  }

  // ── Plafond quotidien ─────────────────────────────────────────────────────

  static const _kRwDay = 'ads_rewarded_day';
  static const _kRwCount = 'ads_rewarded_count';

  static String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  /// Nombre de pubs récompensées encore disponibles aujourd'hui.
  static Future<int> rewardedRemainingToday() async {
    final p = await SharedPreferences.getInstance();
    if (p.getString(_kRwDay) != _today()) return AdPolicy.rewardedDailyCap;
    return (AdPolicy.rewardedDailyCap - (p.getInt(_kRwCount) ?? 0))
        .clamp(0, AdPolicy.rewardedDailyCap);
  }

  static Future<void> _countRewardedView() async {
    final p = await SharedPreferences.getInstance();
    final today = _today();
    final count = p.getString(_kRwDay) == today ? (p.getInt(_kRwCount) ?? 0) : 0;
    await p.setString(_kRwDay, today);
    await p.setInt(_kRwCount, count + 1);
  }

  /// Vérifie le plafond et prévient l'enfant si atteint. true = on peut afficher.
  static Future<bool> _checkRewardedQuota(BuildContext context) async {
    if (_fullScreenShowing) return false;
    if (await rewardedRemainingToday() > 0) return true;
    if (context.mounted) _snack(context, adText(context, 'capReached'));
    return false;
  }

  /// Affiche une pub récompensée (préchargée si possible, sinon chargée avec
  /// un indicateur). Retourne true si la récompense a été gagnée.
  /// À appeler UNIQUEMENT depuis le onTap d'un bouton étiqueté « Regarder une pub ».
  static Future<bool> showRewardedAd(BuildContext context) async {
    if (!context.mounted) return false;
    if (!await _checkRewardedQuota(context)) return false;
    if (!context.mounted) return false;

    final preloaded = _preloadedRewardedAd;
    if (preloaded != null) {
      _preloadedRewardedAd = null;
      return _presentRewarded(preloaded);
    }

    // Pas de pub préchargée : chargement avec indicateur (l'enfant a tapé
    // sur un bouton « Regarder une pub », donc il sait ce qui arrive).
    final completer = Completer<RewardedAd?>();
    BuildContext? dialogCtx;
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (c) {
        dialogCtx = c;
        return const PopScope(
          canPop: false,
          child: Center(child: CircularProgressIndicator(color: Colors.deepOrange)),
        );
      },
    );
    var timedOut = false;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: _childRequest,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          // Chargée trop tard : on la garde pour le prochain tap.
          if (timedOut) {
            _preloadedRewardedAd ??= ad;
            return;
          }
          completer.complete(ad);
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ RewardedAd failed to load: ${error.message}');
          completer.complete(null);
        },
      ),
    );
    final ad = await completer.future.timeout(const Duration(seconds: 12),
        onTimeout: () {
      timedOut = true;
      return null;
    });
    final c = dialogCtx;
    if (c != null && c.mounted) Navigator.of(c).pop();

    if (ad == null) {
      if (context.mounted) _snack(context, adText(context, 'noAd'));
      return false;
    }
    return _presentRewarded(ad);
  }

  /// Variante callback (compatibilité avec l'ancien code).
  static Future<void> showRewardedAdWithLoading(
      BuildContext context,
      VoidCallback onRewardEarned,
      ) async {
    final earned = await showRewardedAd(context);
    if (earned) onRewardEarned();
  }

  /// Affiche la pub préchargée uniquement (aucun chargement).
  /// Retourne false si aucune n'est prête ou si le plafond est atteint.
  static Future<bool> showPreloadedRewardedAd(BuildContext context) async {
    final ad = _preloadedRewardedAd;
    if (ad == null) return false;
    if (!await _checkRewardedQuota(context)) return false;
    _preloadedRewardedAd = null; // consommée
    return _presentRewarded(ad);
  }

  static Future<bool> _presentRewarded(RewardedAd ad) {
    final completer = Completer<bool>();
    var earned = false;
    _fullScreenShowing = true;

    void finish() {
      _fullScreenShowing = false;
      preloadRewardedAd();
      if (!completer.isCompleted) completer.complete(earned);
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        _lastFullScreenAt = DateTime.now(); // pas d'interstitielle juste après
        _countRewardedView();
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        finish();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        debugPrint('❌ RewardedAd failed to show: ${error.message}');
        finish();
      },
    );
    ad.show(onUserEarnedReward: (_, __) => earned = true);
    return completer.future;
  }

  // ── Textes (localisés ici pour ne pas dépendre de gen-l10n) ───────────────

  static const Map<String, Map<String, String>> _texts = {
    'fr': {
      'adBreak': 'Petite pause publicité…',
      'adLabel': 'Publicité',
      'capReached': 'Plus de vidéos pour aujourd\'hui, reviens demain !',
      'noAd': 'Aucune vidéo disponible pour le moment.',
      'doubleGold': 'Regarder une pub : x2 pièces',
      'doubled': 'Pièces doublées !',
    },
    'en': {
      'adBreak': 'Short ad break…',
      'adLabel': 'Advertisement',
      'capReached': 'No more videos today, come back tomorrow!',
      'noAd': 'No video available right now.',
      'doubleGold': 'Watch an ad: x2 coins',
      'doubled': 'Coins doubled!',
    },
    'ar': {
      'adBreak': 'استراحة إعلانية قصيرة…',
      'adLabel': 'إعلان',
      'capReached': 'لا مزيد من الفيديوهات اليوم، عُد غدًا!',
      'noAd': 'لا يوجد فيديو متاح حاليًا.',
      'doubleGold': 'شاهد إعلانًا: ضاعف العملات',
      'doubled': 'تمت مضاعفة العملات!',
    },
    'de': {
      'adBreak': 'Kurze Werbepause…',
      'adLabel': 'Werbung',
      'capReached': 'Für heute keine Videos mehr – bis morgen!',
      'noAd': 'Gerade ist kein Video verfügbar.',
      'doubleGold': 'Werbung ansehen: x2 Münzen',
      'doubled': 'Münzen verdoppelt!',
    },
  };

  /// Texte publicitaire dans la langue de l'appli (français par défaut).
  static String adText(BuildContext context, String key) {
    final code = Localizations.maybeLocaleOf(context)?.languageCode ?? 'fr';
    return (_texts[code] ?? _texts['fr']!)[key] ?? _texts['fr']![key]!;
  }

  static void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }
}

/// Écran « Petite pause publicité… » — neutre, gris, clairement étiqueté.
class _AdBreakNotice extends StatelessWidget {
  final String text;
  const _AdBreakNotice({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  AdHelper.adText(context, 'adLabel'),
                  style: const TextStyle(
                      fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12),
              const Icon(Icons.ondemand_video_rounded, size: 36, color: Colors.black45),
              const SizedBox(height: 10),
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════════════════════
/// FamilyAdBanner
/// Widget bannière conforme Families Policy :
///   • Label "Annonce" toujours visible au-dessus de la pub
///   • Fond neutre (gris clair) — jamais le thème du jeu
///   • À placer UNIQUEMENT sur menus / pages de résultats, jamais en jeu
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
