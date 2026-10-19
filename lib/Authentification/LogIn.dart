import 'dart:async';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mortaalim/IndexPage.dart';
import 'package:mortaalim/User_Input_Info_DataForm/User_Info_FirstCon/UserInfoForm_Introduction.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../XpSystem.dart';

/// First screen for signed-out users: "A world of discovery!".
///
/// Layout follows the 941 × 1672 design (see [KidSceneGeometry]); all
/// decorations are separate sprites so they can animate.
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  bool _isLoading = false;
  String? _errorMessage;
  bool _precached = false;

  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
  late final AnimationController _idle =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  late final AnimationController _jump =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 650));

  static const List<String> _assets = [
    KidAssets.loginBg,
    KidAssets.logo,
    KidAssets.mascot,
    KidAssets.rocket,
    KidAssets.pencil,
    KidAssets.globe,
    KidAssets.letterA,
    KidAssets.blocks,
    KidAssets.starBig,
    KidAssets.starSmall,
    KidAssets.icGlobe,
    KidAssets.icChevron,
    KidAssets.icLock,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<AudioManager>(context, listen: false)
          .playBackgroundMusic('assets/audios/BackGround_Audio/CuteBabySong_bg.mp3');
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      KidAssets.precache(context, _assets);
      // Small delay so the first frame (background) is on screen before
      // the sprites start popping in.
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _intro.forward();
      });
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _idle.dispose();
    _jump.dispose();
    super.dispose();
  }

  // ─── Auth logic ────────────────────────────────────────────────────────────
  Future<void> _signInAnonymously() async {
    if (_isLoading) return;
    if (!await _checkConnection()) return;
    if (!mounted) return;
    final confirmed = await _showConfirmationDialog(
      tr(context).loginWithoutGoogle,
      tr(context).loginWithoutGoogleDescription,
    );
    if (!confirmed || !mounted) return;
    _setLoading(true);
    if (mounted) setState(() => _errorMessage = null);
    try {
      // Reuse an existing anonymous session instead of creating a new one.
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        final cred = await FirebaseAuth.instance
            .signInAnonymously()
            .timeout(const Duration(seconds: 20));
        user = cred.user;
      }
      if (user == null) throw FirebaseAuthException(code: 'no-user');
      await _continueAfterSignIn(user);
    } catch (e) {
      _showFriendlyError(e);
      _setLoading(false);
    }
  }

  /// LoginPage is pushed directly by SplashPage (not under AuthGate), so
  /// nothing reacts to authStateChanges after sign-in. Navigate explicitly,
  /// using the same rules as SplashPage (onboarding → UserInfoForm, else Index).
  Future<void> _continueAfterSignIn(User user) async {
    if (!mounted) return;
    final xpManager = Provider.of<ExperienceManager>(context, listen: false);
    if (xpManager.lastLogin == null ||
        xpManager.lastLogin!
            .isBefore(DateTime.now().subtract(const Duration(seconds: 2)))) {
      xpManager.onAppStart(user.uid);
    }
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) =>
            onboardingCompleted ? const Index() : const UserInfoForm(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: CurvedAnimation(parent: a, curve: Curves.easeOut), child: child),
      ),
      (route) => false,
    );
  }

  Future<bool> _checkConnection() async {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      _showError(tr(context).noInternetConnection);
      audioManager.playEventSound("invalid");
      return false;
    }
    return true;
  }

  void _setLoading(bool value) {
    if (mounted) setState(() => _isLoading = value);
  }

  void _showError(String message) {
    if (mounted) setState(() => _errorMessage = message);
  }

  void _showFriendlyError(Object e) {
    debugPrint("LOGIN ERROR: $e");
    if (!mounted) return;
    String message = tr(context).noInternetConnection;
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'network-request-failed':
          message = tr(context).noInternetConnection;
          break;
        case 'operation-not-allowed':
        case 'admin-restricted-operation':
          // Anonymous sign-in is disabled in Firebase Console →
          // Authentication → Sign-in method → Anonymous.
          message = kDebugMode
              ? 'Anonymous sign-in is disabled in Firebase (${e.code}).'
              : tr(context).tryAgain;
          break;
        default:
          message = kDebugMode
              ? '${tr(context).tryAgain} (${e.code})'
              : tr(context).tryAgain;
      }
    } else if (e is TimeoutException) {
      message = tr(context).noInternetConnection;
    } else if (kDebugMode) {
      message = '${tr(context).tryAgain} ($e)';
    } else {
      message = tr(context).tryAgain;
    }
    setState(() => _errorMessage = message);
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    return await showGeneralDialog<bool>(
          context: context,
          barrierDismissible: true,
          barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
          barrierColor: KidColors.purpleDeep.withOpacity(0.35),
          transitionDuration: const Duration(milliseconds: 380),
          pageBuilder: (ctx, _, __) => KidDialog(
            headerAsset: KidAssets.logo,
            headerAspect: 0.9128,
            title: title,
            message: message,
            actions: [
              KidOutlineButton(
                label: tr(ctx).cancel,
                onTap: () {
                  Provider.of<AudioManager>(ctx, listen: false)
                      .playEventSound('cancelButton');
                  Navigator.of(ctx).pop(false);
                },
              ),
              KidButton(
                label: tr(ctx).confirm,
                width: double.infinity,
                height: 50,
                showArrow: false,
                onPressed: () {
                  final am = Provider.of<AudioManager>(ctx, listen: false);
                  am.playEventSound('clickButton');
                  am.stopMusic();
                  Navigator.of(ctx).pop(true);
                },
              ),
            ],
          ),
          transitionBuilder: (ctx, a, __, child) => ScaleTransition(
            scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
            child: FadeTransition(opacity: a, child: child),
          ),
        ) ??
        false;
  }

  // ─── Parents area (behind a simple parental gate) ─────────────────────────
  Future<void> _openParents() async {
    final am = Provider.of<AudioManager>(context, listen: false);
    am.playEventSound('clickButton');
    final ok = await _parentGate();
    if (!ok || !mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 22),
          decoration: BoxDecoration(
            color: KidColors.cream,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: KidColors.lavender, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                    color: KidColors.lavender, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(height: 18),
              Image.asset(KidAssets.icLock, height: 44),
              const SizedBox(height: 10),
              Text(tr(ctx).loginForParents,
                  style: kidBodyStyle(22, color: KidColors.ink, weight: FontWeight.w700)),
              const SizedBox(height: 14),
              _ParentInfoRow(icon: Icons.cloud_off_rounded, text: tr(ctx).manualBackupNotice),
              const SizedBox(height: 10),
              _ParentInfoRow(icon: Icons.link_rounded, text: tr(ctx).parentsInfoGoogle),
              const SizedBox(height: 20),
              KidButton(
                label: tr(ctx).ok,
                width: double.infinity,
                height: 54,
                showArrow: false,
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _parentGate() async {
    final rnd = Random();
    final a = 3 + rnd.nextInt(7), b = 3 + rnd.nextInt(7);
    final answer = a * b;
    final options = <int>{answer};
    while (options.length < 3) {
      final delta = (rnd.nextInt(3) + 1) * (rnd.nextBool() ? a : b);
      final v = rnd.nextBool() ? answer + delta : answer - delta;
      if (v > 0) options.add(v);
    }
    final shuffled = options.toList()..shuffle(rnd);

    return await showDialog<bool>(
          context: context,
          barrierColor: KidColors.purpleDeep.withOpacity(0.35),
          builder: (ctx) => KidDialog(
            title: tr(ctx).parentGateTitle,
            message: tr(ctx).parentGateQuestion(a, b),
            content: Row(
              children: [
                for (int i = 0; i < shuffled.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: KidOutlineButton(
                      label: '${shuffled[i]}',
                      height: 56,
                      onTap: () {
                        final am = Provider.of<AudioManager>(ctx, listen: false);
                        if (shuffled[i] == answer) {
                          am.playEventSound('clickButton');
                          Navigator.of(ctx).pop(true);
                        } else {
                          am.playEventSound('invalid');
                          Navigator.of(ctx).pop(false);
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ) ??
        false;
  }

  void _onMascotTap() {
    if (_jump.isAnimating) return;
    Provider.of<AudioManager>(context, listen: false).playEventSound('PopButton');
    _jump.forward(from: 0);
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final g = KidSceneGeometry(size);

    SceneSprite sprite(String asset, double l, double t, double w, double aspect,
            {double from = 0.2,
            double to = 0.7,
            double bob = 0,
            double sway = 0,
            double rot = 0,
            double phase = 0,
            int speed = 1,
            bool twinkle = false,
            bool pop = true,
            Animation<double>? jump,
            VoidCallback? onTap}) =>
        SceneSprite(
          g: g,
          asset: asset,
          left: l,
          top: t,
          width: w,
          aspect: aspect,
          idle: _idle,
          intro: _intro,
          introFrom: from,
          introTo: to,
          bob: bob,
          sway: sway,
          rot: rot,
          phase: phase,
          speed: speed,
          twinkle: twinkle,
          pop: pop,
          jump: jump,
          onTap: onTap,
        );

    final buttonH = g.lc(138, 52, 74);
    // Push the logo below the status bar / notch when needed (design px).
    final logoShift = max(0.0, pad.top + 2 - g.y(40)) / g.s;
    final rightInset = size.width - (g.visibleLeft + g.visibleWidth);

    return Scaffold(
      backgroundColor: KidColors.sky,
      body: Stack(
        children: [
          KidSceneBackground(asset: KidAssets.loginBg, g: g),

          // Sprites are laid out in LTR design coordinates in every locale.
          Directionality(
            textDirection: TextDirection.ltr,
            child: Stack(
              children: [
                sprite(KidAssets.rocket, 648, 268, 262, 0.9402,
                    from: 0.35, to: 0.8, bob: 14, sway: 10, rot: 0.05, phase: 0.1),
                sprite(KidAssets.pencil, 78, 448, 165, 1.1783,
                    from: 0.3, to: 0.75, bob: 9, rot: 0.08, phase: 0.35),
                sprite(KidAssets.globe, 698, 503, 180, 1.1525,
                    from: 0.38, to: 0.82, bob: 10, rot: 0.03, phase: 0.6),
                sprite(KidAssets.letterA, 604, 646, 122, 0.9673,
                    from: 0.42, to: 0.86, bob: 11, rot: 0.07, phase: 0.15, speed: 2),
                sprite(KidAssets.blocks, 16, 726, 280, 0.87,
                    from: 0.4, to: 0.85, bob: 5, rot: 0.015, phase: 0.45),
                sprite(KidAssets.mascot, 268, 420, 380, 1.5202,
                    from: 0.12, to: 0.62, bob: 9, rot: 0.02, phase: 0.8,
                    jump: _jump, onTap: _onMascotTap),
                sprite(KidAssets.logo, 262 + logoShift * 0.15, 40 + logoShift, 415 - logoShift * 0.3, 0.9128,
                    from: 0.0, to: 0.5, bob: 7, rot: 0.012, phase: 0.25),
                sprite(KidAssets.starBig, 214, 160, 52, 1.036,
                    from: 0.5, to: 0.9, twinkle: true, phase: 0.0, speed: 2),
                sprite(KidAssets.starBig, 668, 168, 44, 1.036,
                    from: 0.55, to: 0.95, twinkle: true, phase: 0.4, speed: 2),
                sprite(KidAssets.starSmall, 176, 312, 36, 1.0698,
                    from: 0.55, to: 0.95, twinkle: true, phase: 0.7, speed: 3),
                sprite(KidAssets.starSmall, 846, 452, 30, 1.0698,
                    from: 0.6, to: 1.0, twinkle: true, phase: 0.2, speed: 3),
                sprite(KidAssets.starSmall, 880, 505, 22, 1.0698,
                    from: 0.6, to: 1.0, twinkle: true, phase: 0.55, speed: 2),
              ],
            ),
          ),

          // ── Cream panel content ─────────────────────────────────────────
          Positioned(
            left: g.visibleLeft,
            width: g.visibleWidth,
            top: g.y(1192),
            bottom: 0,
            child: KidIntro(
              intro: _intro,
              from: 0.45,
              to: 1.0,
              child: Padding(
                padding: EdgeInsets.only(bottom: pad.bottom),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: g.visibleWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              tr(context).loginWorldOfDiscovery,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: kidTitleStyle(g.lc(66, 24, 40)),
                            ),
                          ),
                          SizedBox(height: g.l(12)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              tr(context).loginLearnPlayGrow,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: kidBodyStyle(g.lc(31, 14, 19)),
                            ),
                          ),
                          SizedBox(height: g.l(_errorMessage == null ? 34 : 14)),
                          if (_errorMessage != null)
                            _ErrorPill(message: _errorMessage!, maxWidth: g.visibleWidth - 48),
                          if (_errorMessage != null) SizedBox(height: g.l(14)),
                          KidButton(
                            label: tr(context).loginLetsExplore,
                            loading: _isLoading,
                            width: g.contentWidth(755, pad: 24),
                            height: buttonH,
                            onPressed: () {
                              audioManager.playEventSound("clickButton");
                              _signInAnonymously();
                            },
                          ),
                          SizedBox(height: g.l(26)),
                          KidPressable(
                            onTap: _openParents,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(KidAssets.icLock, height: g.lc(40, 16, 24)),
                                  const SizedBox(width: 8),
                                  Text(
                                    tr(context).loginForParents,
                                    style: kidBodyStyle(g.lc(28, 12, 16), color: KidColors.muted),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Language pill ───────────────────────────────────────────────
          Positioned(
            top: pad.top + 10,
            right: rightInset + 14,
            child: KidIntro(intro: _intro, from: 0.5, to: 1.0, rise: -12, child: const _LanguagePill()),
          ),
        ],
      ),
    );
  }
}

class _ErrorPill extends StatelessWidget {
  final String message;
  final double maxWidth;
  const _ErrorPill({required this.message, required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE7E3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFF8A7A), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Color(0xFFE5483B), size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(message,
                style: kidBodyStyle(13.5, color: const Color(0xFFB4302A), weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _ParentInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ParentInfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: KidColors.purpleLight, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: KidColors.purple, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: kidBodyStyle(14, color: KidColors.inkSoft))),
        ],
      ),
    );
  }
}

/// Top-right "🌐 EN ⌄" pill with a flag menu.
class _LanguagePill extends StatelessWidget {
  const _LanguagePill();

  static const _langs = <(String, String, String)>[
    ('ar', 'العربية', KidAssets.flagMa),
    ('fr', 'Français', KidAssets.flagFr),
    ('en', 'English', KidAssets.flagUk),
    ('de', 'Deutsch', KidAssets.flagDe),
    ('zgh', 'ⵜⴰⵎⴰⵣⵉⵖⵜ', KidAssets.flagZgh),
  ];

  @override
  Widget build(BuildContext context) {
    final current = Provider.of<ExperienceManager>(context).locale.languageCode;
    return PopupMenuButton<String>(
      tooltip: '',
      offset: const Offset(0, 48),
      color: KidColors.cream,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: KidColors.lavender, width: 1.5),
      ),
      onSelected: (code) {
        Provider.of<AudioManager>(context, listen: false).playEventSound('clickButton2');
        MyAppStateHelper.changeLanguage(context, Locale(code));
      },
      itemBuilder: (_) => [
        for (final l in _langs)
          PopupMenuItem<String>(
            value: l.$1,
            child: Row(
              children: [
                Image.asset(l.$3, width: 28, height: 28),
                const SizedBox(width: 12),
                Text(l.$2,
                    style: kidBodyStyle(16,
                        color: KidColors.ink,
                        weight: l.$1 == current ? FontWeight.w700 : FontWeight.w500)),
                if (l.$1 == current) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle_rounded, color: KidColors.purple, size: 18),
                ],
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 7, 12, 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.88),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
                color: KidColors.purpleDeep.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(KidAssets.icGlobe, width: 22, height: 22),
            const SizedBox(width: 7),
            Text(current.toUpperCase(),
                style: kidBodyStyle(15, color: KidColors.ink, weight: FontWeight.w700)),
            const SizedBox(width: 5),
            Image.asset(KidAssets.icChevron, width: 13, height: 9),
          ],
        ),
      ),
    );
  }
}
