import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../XpSystem.dart';

// ─── Palette ────────────────────────────────────────────────────────────────
const Color kSkyTop    = Color(0xFF1A237E); // deep indigo night sky
const Color kSkyBottom = Color(0xFF4FC3F7); // dawn horizon blue
const Color kStar      = Color(0xFFFFF9C4); // pale yellow stars
const Color kMoon      = Color(0xFFFFD54F); // golden moon
const Color kCoral     = Color(0xFFFF7043); // primary CTA
const Color kCoralDark = Color(0xFFE64A19);
const Color kCloud     = Color(0xFFFFFFFF);
const Color kTextDark  = Color(0xFF1A237E);

// ─── Star model ─────────────────────────────────────────────────────────────
class _Star {
  final double x, y, size;
  final double twinkleDuration; // seconds
  _Star({required this.x, required this.y, required this.size, required this.twinkleDuration});
}

// ─── Main page ───────────────────────────────────────────────────────────────
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  bool _isLoading = false;
  String? _errorMessage;

  // Typewriter
  final List<String> _welcomeTexts = [
    "MoorTaalim",
    "Welcome!",
    "Bienvenue!",
    "مرحبا!",
    "Benvenuto!",
    "Merhaba!",
    "Bienvenido!",
    "ようこそ!",
  ];
  int _currentTextIndex = 0;
  String _displayedText = "";
  Timer? _typingTimer;
  Timer? _changeTextTimer;

  // Animations
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late AnimationController _floatController;
  late Animation<double> _floatAnim;
  late AnimationController _glowController;
  late Animation<double> _glowAnim;
  late AnimationController _starController;
  late Animation<double> _starAnim;
  late AnimationController _cloudController;
  late Animation<double> _cloudAnim;
  late AnimationController _rocketController;
  late Animation<double> _rocketAnim;

  // Stars
  final List<_Star> _stars = [];
  final Random _rng = Random(42);

  @override
  void initState() {
    super.initState();

    // Generate random stars
    for (int i = 0; i < 60; i++) {
      _stars.add(_Star(
        x: _rng.nextDouble(),
        y: _rng.nextDouble() * 0.65, // top 65% of screen
        size: _rng.nextDouble() * 3 + 1,
        twinkleDuration: _rng.nextDouble() * 2 + 1,
      ));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audioManager = Provider.of<AudioManager>(context, listen: false);
      audioManager.playBackgroundMusic(
          'assets/audios/BackGround_Audio/CuteBabySong_bg.mp3');
    });

    // Logo pop-in
    _logoController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _logoScale =
        CurvedAnimation(parent: _logoController, curve: Curves.elasticOut);
    _logoController.forward();

    // Float up-down
    _floatController = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -10, end: 10).animate(
        CurvedAnimation(parent: _floatController, curve: Curves.easeInOut));

    // Glow pulse
    _glowController = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));

    // Star twinkle
    _starController = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _starAnim = Tween<double>(begin: 0.3, end: 1.0).animate(_starController);

    // Cloud drift
    _cloudController = AnimationController(
        vsync: this, duration: const Duration(seconds: 20))
      ..repeat();
    _cloudAnim = Tween<double>(begin: -0.4, end: 1.4).animate(
        CurvedAnimation(parent: _cloudController, curve: Curves.linear));

    // Rocket idle wiggle
    _rocketController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _rocketAnim = Tween<double>(begin: -6, end: 6).animate(
        CurvedAnimation(parent: _rocketController, curve: Curves.easeInOut));

    _startTypewriterEffect();
  }

  void _startTypewriterEffect() {
    _typeText(_welcomeTexts[_currentTextIndex]);
    _changeTextTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _currentTextIndex = (_currentTextIndex + 1) % _welcomeTexts.length;
      _typeText(_welcomeTexts[_currentTextIndex]);
    });
  }

  void _typeText(String text) {
    _typingTimer?.cancel();
    _displayedText = "";
    int index = 0;
    _typingTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
          if (index < text.length) {
            setState(() => _displayedText += text[index]);
            index++;
          } else {
            timer.cancel();
          }
        });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _changeTextTimer?.cancel();
    _logoController.dispose();
    _floatController.dispose();
    _glowController.dispose();
    _starController.dispose();
    _cloudController.dispose();
    _rocketController.dispose();
    super.dispose();
  }

  // ─── Auth logic (unchanged) ───────────────────────────────────────────────
  Future<void> _signInAnonymously() async {
    if (!await _checkConnection()) return;
    final confirmed = await _showConfirmationDialog(
      tr(context).loginWithoutGoogle,
      tr(context).loginWithoutGoogleDescription,
    );
    if (!confirmed) return;
    _setLoading(true);
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      _showFriendlyError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> _checkConnection() async {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
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
    setState(() => _errorMessage = tr(context).noInternetConnection);
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF8E1), Color(0xFFE3F2FD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎪', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: kTextDark)),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: kCoral, width: 2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        padding:
                        const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(tr(context).cancel,
                          style: const TextStyle(
                              color: kCoral, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final am = Provider.of<AudioManager>(ctx,
                            listen: false);
                        am.playEventSound('clickButton');
                        am.stopMusic();
                        Navigator.of(ctx).pop(true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kCoral,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        padding:
                        const EdgeInsets.symmetric(vertical: 12),
                        elevation: 4,
                      ),
                      child: Text(tr(context).confirm,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    ) ??
        false;
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Night-sky gradient background ──────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [kSkyTop, Color(0xFF283593), Color(0xFF1565C0), kSkyBottom],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.3, 0.65, 1.0],
              ),
            ),
          ),

          // ── Twinkling stars ────────────────────────────────────────────
          AnimatedBuilder(
            animation: _starAnim,
            builder: (_, __) => CustomPaint(
              size: size,
              painter: _StarPainter(stars: _stars, opacity: _starAnim.value),
            ),
          ),

          // ── Drifting cloud 1 ───────────────────────────────────────────
          AnimatedBuilder(
            animation: _cloudAnim,
            builder: (_, __) => Positioned(
              left: size.width * (_cloudAnim.value - 0.3),
              top: size.height * 0.15,
              child: _Cloud(width: 110, opacity: 0.18),
            ),
          ),

          // ── Drifting cloud 2 (offset phase) ───────────────────────────
          AnimatedBuilder(
            animation: _cloudAnim,
            builder: (_, __) {
              final phase = (_cloudAnim.value + 0.55) % 1.8 - 0.4;
              return Positioned(
                left: size.width * phase,
                top: size.height * 0.22,
                child: _Cloud(width: 80, opacity: 0.12),
              );
            },
          ),

          // ── Moon + glow ────────────────────────────────────────────────
          Positioned(
            right: 30,
            top: 50,
            child: AnimatedBuilder(
              animation: _glowAnim,
              builder: (_, __) => Stack(
                alignment: Alignment.center,
                children: [
                  // glow halo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: kMoon.withOpacity(_glowAnim.value * 0.5),
                          blurRadius: 30,
                          spreadRadius: 10,
                        )
                      ],
                    ),
                  ),
                  // moon
                  const Text('🌙', style: TextStyle(fontSize: 52)),
                ],
              ),
            ),
          ),

          // ── Ground wave (soft white arc at bottom) ────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(size.width, 200),
              painter: _WavePainter(),
            ),
          ),

          // ── Main content ───────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Language picker
                  Align(
                    alignment: Alignment.topRight,
                    child: _LanguagePicker(),
                  ),

                  const SizedBox(height: 16),

                  // Floating animated logo
                  AnimatedBuilder(
                    animation: _floatAnim,
                    builder: (_, __) => Transform.translate(
                      offset: Offset(0, _floatAnim.value),
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Glow ring behind logo
                            AnimatedBuilder(
                              animation: _glowAnim,
                              builder: (_, __) => Container(
                                width: 148,
                                height: 148,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white
                                          .withOpacity(_glowAnim.value * 0.4),
                                      blurRadius: 24,
                                      spreadRadius: 8,
                                    )
                                  ],
                                ),
                              ),
                            ),
                            // Logo
                            ClipOval(
                              child: Image.asset(
                                'assets/icons/logo3.png',
                                height: 130,
                                width: 130,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Typewriter text
                  Text(
                    _displayedText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(color: Colors.black38, blurRadius: 8, offset: Offset(2, 2)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Subtitle tagline
                  const Text(
                    '✨ Learn & Play Every Day ✨',
                    style: TextStyle(
                      fontSize: 14,
                      color: kStar,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Mascot illustration with wiggling rocket
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Image.asset(
                        'assets/icons/MoorTaalimLogoChildren_AuthScreen.png',
                        width: 220,
                        height: 220,
                      ),
                      // Animated rocket badge
                      AnimatedBuilder(
                        animation: _rocketAnim,
                        builder: (_, __) => Transform.rotate(
                          angle: _rocketAnim.value * 0.04,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: kMoon,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: kMoon.withOpacity(0.6),
                                    blurRadius: 12,
                                    spreadRadius: 2)
                              ],
                            ),
                            child: const Text('🎪',
                                style: TextStyle(fontSize: 24)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Error banner
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.redAccent, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Text('😢', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── BIG CTA button ─────────────────────────────────────
                  _BigPlayButton(
                    isLoading: _isLoading,
                    label: tr(context).enjoy,
                    onPressed: () {
                      audioManager.playEventSound("clickButton");
                      _signInAnonymously();
                    },
                  ),

                  const SizedBox(height: 20),

                  // Decorative divider with stars
                  Row(
                    children: const [
                      Expanded(child: Divider(color: Colors.white24, thickness: 1)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('⭐', style: TextStyle(fontSize: 14)),
                      ),
                      Expanded(child: Divider(color: Colors.white24, thickness: 1)),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Disclaimer note
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tr(context).manualBackupNotice,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Big CTA button ───────────────────────────────────────────────────────────
class _BigPlayButton extends StatefulWidget {
  final bool isLoading;
  final String label;
  final VoidCallback onPressed;

  const _BigPlayButton({
    required this.isLoading,
    required this.label,
    required this.onPressed,
  });

  @override
  State<_BigPlayButton> createState() => _BigPlayButtonState();
}

class _BigPlayButtonState extends State<_BigPlayButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _pressAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _pressAnim = Tween<double>(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        if (!widget.isLoading) widget.onPressed();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: ScaleTransition(
        scale: _pressAnim,
        child: Container(
          width: double.infinity,
          height: 68,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            gradient: const LinearGradient(
              colors: [Color(0xFFFF8A65), kCoral, kCoralDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: kCoral.withOpacity(0.55),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.15),
                blurRadius: 1,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: widget.isLoading
              ? const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                  strokeWidth: 3, color: Colors.white),
            ),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎪', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(1, 2))
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Text('✨', style: TextStyle(fontSize: 22)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Language picker ──────────────────────────────────────────────────────────
class _LanguagePicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white30, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Locale>(
          value: Provider.of<ExperienceManager>(context).locale,
          icon: const Icon(Icons.language_rounded, color: Colors.white70, size: 18),
          dropdownColor: const Color(0xFF1A237E),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          items: const [
            DropdownMenuItem(value: Locale('fr'), child: Text('🇫🇷 FR')),
            DropdownMenuItem(value: Locale('en'), child: Text('🇺🇸 EN')),
            DropdownMenuItem(value: Locale('ar'), child: Text('🇸🇦 AR')),
            DropdownMenuItem(value: Locale('de'), child: Text('🇩🇪 DE')),
            DropdownMenuItem(value: Locale('zgh'), child: Text('🇲🇦 ZGH')),
          ],
          onChanged: (Locale? newLocale) {
            if (newLocale != null) {
              MyAppStateHelper.changeLanguage(context, newLocale);
            }
          },
        ),
      ),
    );
  }
}

// ─── Cloud widget ─────────────────────────────────────────────────────────────
class _Cloud extends StatelessWidget {
  final double width;
  final double opacity;
  const _Cloud({required this.width, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: CustomPaint(
        size: Size(width, width * 0.5),
        painter: _CloudPainter(),
      ),
    );
  }
}

class _CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..addOval(Rect.fromCenter(center: Offset(w * 0.35, h * 0.65), width: w * 0.5, height: h * 0.7))
      ..addOval(Rect.fromCenter(center: Offset(w * 0.55, h * 0.55), width: w * 0.6, height: h * 0.8))
      ..addOval(Rect.fromCenter(center: Offset(w * 0.72, h * 0.65), width: w * 0.45, height: h * 0.65))
      ..addRect(Rect.fromLTRB(w * 0.1, h * 0.65, w * 0.9, h));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Star painter ─────────────────────────────────────────────────────────────
class _StarPainter extends CustomPainter {
  final List<_Star> stars;
  final double opacity;

  _StarPainter({required this.stars, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(0);
    for (int i = 0; i < stars.length; i++) {
      final s = stars[i];
      // Each star twinkles at slightly different phase
      final phase = (opacity + i * 0.07) % 1.0;
      final alpha = (0.4 + 0.6 * (sin(phase * pi))).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = kStar.withOpacity(alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}

// ─── Bottom wave painter ──────────────────────────────────────────────────────
class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFF8F0)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.4);
    path.cubicTo(
      size.width * 0.25, size.height * 0.1,
      size.width * 0.75, size.height * 0.55,
      size.width, size.height * 0.3,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}