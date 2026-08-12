import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../tools/audio_tool/Audio_Manager.dart';

/// The very first thing the user sees when the app opens — the MoorTaalim
/// mascot logo-intro animation, playing once, centered, on a black
/// backdrop.
///
/// Stretched to [_playDuration] (4.5s) rather than the composition's own
/// native length — a deliberate slow-down (not a hold-then-cut), so the
/// whole animation plays out unhurried instead of racing through it and
/// then just sitting on the last frame.
class CompanyLogoScreen extends StatefulWidget {
  final VoidCallback? onFinished;

  const CompanyLogoScreen({super.key, this.onFinished});

  @override
  State<CompanyLogoScreen> createState() => _CompanyLogoScreenState();
}

class _CompanyLogoScreenState extends State<CompanyLogoScreen>
    with TickerProviderStateMixin {
  static const _playDuration = Duration(milliseconds: 4500);

  late final AnimationController _controller;

  // A slow, breathing glow behind the mascot — echoes the mascot's own
  // warm orange palette (same accent already used by GlowingLogo /
  // ElegantProgressBar in this splash flow) so this screen feels like
  // part of the same app rather than a separate video clip dropped on a
  // plain black background.
  late final AnimationController _glowPulse;

  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _glowPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _controller.addStatusListener(_handleStatus);

    // Safety net: if the Lottie asset is ever missing/corrupt/slow to
    // decode, onLoaded may never fire — this guarantees the splash still
    // moves on to the actual app instead of hanging forever on a blank
    // screen. Given a couple of seconds' headroom over the intended
    // 4.5s play length.
    Future.delayed(const Duration(seconds: 7), _finish);
  }

  // Fire-and-forget — AudioManager.playSfx already swallows its own
  // errors, so a missing/broken audio asset never blocks or crashes the
  // splash, it just plays silently.
  void _playIntroAudio() {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    audioManager.playSfx('assets/audios/audioIntro.mp3');
  }

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _finish();
  }

  void _handleLoaded(LottieComposition composition) {
    if (_finished || !mounted) return;
    // Audio starts in the same frame the animation actually begins
    // playing — firing it in initState instead would lead the visual by
    // however long the (fairly large) Lottie file takes to decode.
    _playIntroAudio();
    _controller
      ..duration = _playDuration
      ..forward();
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    widget.onFinished?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    _glowPulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _glowPulse,
              builder: (context, _) {
                final t = _glowPulse.value;
                return Container(
                  width: 300 + t * 40,
                  height: 300 + t * 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.orange.withOpacity(0.22 + t * 0.10),
                        Colors.deepOrange.withOpacity(0.10),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                );
              },
            ),
            // A soft radial fade over the whole animation — without it,
            // the Lottie reads as a hard-edged rectangle sitting on the
            // glow (still a "video clip playing" read). Fading the
            // composition's own edges into the backdrop instead lets it
            // feel like it's actually part of the screen.
            ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (bounds) => const RadialGradient(
                center: Alignment.center,
                radius: 0.75,
                colors: [Colors.white, Colors.white, Colors.transparent],
                stops: [0.0, 0.6, 1.0],
              ).createShader(bounds),
              child: Lottie.asset(
                'assets/animations/logoIntro.json',
                controller: _controller,
                onLoaded: _handleLoaded,
                // No `repeat`/`animate` here on purpose — supplying an
                // explicit `controller` already puts playback fully in
                // our hands (forward() once, never looped), so those
                // params would just be redundant with what _handleLoaded
                // already does.
                fit: BoxFit.contain,
                width: 320,
                height: 320,
                // If the asset is ever missing/renamed, fall back to the
                // static mark instead of a blank frame, and still let the
                // splash move on (nothing here would ever call _finish()
                // otherwise).
                errorBuilder: (_, __, ___) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
                  return Image.asset(
                    'assets/icons/logo3.png',
                    width: 260,
                    height: 260,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox(width: 260, height: 260),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
