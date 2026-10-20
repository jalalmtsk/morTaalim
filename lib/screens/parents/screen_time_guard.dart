import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/main.dart' show navigatorKey;
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';

import 'parent_data.dart';
import 'parent_gate.dart';
import 'parent_strings.dart';
import 'parent_ui.dart';

/// Counts the time spent in the app and enforces the parent's rules:
/// daily limit and quiet hours (rest screen), break reminder (friendly dialog).
class ScreenTimeGuard with WidgetsBindingObserver {
  ScreenTimeGuard._();
  static final ScreenTimeGuard I = ScreenTimeGuard._();

  static const _tick = 20; // seconds
  Timer? _timer;
  bool _started = false, _resting = false, _breakOpen = false;
  int _sessionSecs = 0;

  /// Call once the child is in the app (Index). Safe to call again.
  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    ParentSettings.I.load().then((_) => _check());
    _timer = Timer.periodic(const Duration(seconds: _tick), (_) => _onTick());
    final ctx = navigatorKey.currentContext;
    if (ctx != null) WeekLevel.note(Provider.of<ExperienceManager>(ctx, listen: false).level);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) {
      _timer ??= Timer.periodic(const Duration(seconds: _tick), (_) => _onTick());
      _check();
    } else if (s == AppLifecycleState.paused || s == AppLifecycleState.detached) {
      _timer?.cancel();
      _timer = null;
      _sessionSecs = 0; // leaving the app counts as a break
    }
  }

  Future<void> _onTick() async {
    if (_resting) return;
    await Usage.add(_tick);
    _sessionSecs += _tick;
    await _check();
  }

  Future<void> _check() async {
    final s = ParentSettings.I;
    await s.load();
    final ctx = navigatorKey.currentContext;
    if (ctx == null || _resting) return;
    final now = DateTime.now();
    final quiet = s.activeQuiet(now);
    final used = await Usage.secondsOn(now);
    if (quiet != null) {
      _rest('quiet', until: quiet.end);
    } else if (s.limitOn && used >= s.allowedToday * 60) {
      _rest('limit');
    } else if (s.breakOn && _sessionSecs >= s.breakMin * 60 && !_breakOpen) {
      _sessionSecs = 0;
      _breakOpen = true;
      await showDialog(context: ctx, barrierDismissible: false, builder: (_) => const _BreakDialog());
      _breakOpen = false;
    }
  }

  Future<void> _rest(String reason, {int? until}) async {
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    _resting = true;
    await nav.push(PageRouteBuilder(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, __, ___) => RestScreen(reason: reason, until: until),
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
    ));
    _resting = false;
    _sessionSecs = 0;
  }
}

/// "Waki a besoin de repos !" — shown when the daily time is used up or
/// during quiet hours. Only an adult can let the child continue.
class RestScreen extends StatefulWidget {
  final String reason; // limit | quiet
  final int? until; // minutes after midnight (quiet hours end)
  const RestScreen({super.key, required this.reason, this.until});

  @override
  State<RestScreen> createState() => _RestScreenState();
}

class _RestScreenState extends State<RestScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _life = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    // Close by itself when quiet hours end / the parent changes the rules.
    _poll = Timer.periodic(const Duration(seconds: 30), (_) => _maybeClose());
  }

  Future<void> _maybeClose() async {
    final s = ParentSettings.I;
    final now = DateTime.now();
    final used = await Usage.secondsOn(now);
    final stillQuiet = s.activeQuiet(now) != null;
    final stillLimit = s.limitOn && used >= s.allowedToday * 60;
    if (!stillQuiet && !stillLimit && mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _life.dispose();
    super.dispose();
  }

  Future<void> _parent() async {
    if (!await ParentGate.check(context, force: true)) return;
    if (!mounted) return;
    final s = ParentSettings.I;
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(18, 16, 18, 18 + MediaQuery.paddingOf(ctx).bottom),
        decoration: const BoxDecoration(color: PC.cream, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(pT(ctx, 'restParentTitle'), style: ps(22, w: FontWeight.w700)),
          const SizedBox(height: 14),
          if (widget.reason == 'limit') ...[
            PButton(pT(ctx, 'plus15'), icon: Icons.more_time_rounded, onTap: () => Navigator.pop(ctx, '15')),
            const SizedBox(height: 10),
            PButton(pT(ctx, 'plus30'), icon: Icons.more_time_rounded, onTap: () => Navigator.pop(ctx, '30')),
            const SizedBox(height: 10),
          ],
          PGhostButton(pT(ctx, 'unlockToday'), icon: Icons.lock_open_rounded, onTap: () => Navigator.pop(ctx, 'off')),
        ]),
      ),
    );
    if (choice == null) return;
    final today = Usage.dayKey(DateTime.now());
    if (choice == '15' || choice == '30') {
      final add = int.parse(choice);
      s.bonusMin = (s.bonusDate == today ? s.bonusMin : 0) + add;
      s.bonusDate = today;
    } else {
      if (widget.reason == 'limit') {
        s.bonusMin = 24 * 60;
        s.bonusDate = today;
      } else {
        s.quietOn = false;
      }
    }
    await s.save();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final quiet = widget.reason == 'quiet';
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF1E2A5A),
        body: Stack(children: [
          // calm night sky
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1B2459), Color(0xFF3B3F8F), Color(0xFF7E73C9)],
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _life,
            builder: (_, __) => CustomPaint(size: size, painter: _StarsPainter(_life.value)),
          ),
          Positioned(
            right: w * 0.06,
            top: MediaQuery.paddingOf(context).top + 20,
            child: AnimatedBuilder(
              animation: _life,
              builder: (_, c) => Transform.translate(offset: Offset(0, 6 * sin(_life.value * 2 * pi)), child: c),
              child: Image.asset(pa('rest_moon'), width: w * 0.24),
            ),
          ),
          Positioned(left: -w * 0.08, bottom: size.height * 0.12, child: Image.asset(pa('rest_tree'), width: w * 0.62)),
          Positioned(
            right: w * 0.02,
            bottom: size.height * 0.12,
            child: AnimatedBuilder(
              animation: _life,
              builder: (_, c) => Transform.scale(scaleY: 1 + 0.03 * sin(_life.value * 2 * pi), alignment: Alignment.bottomCenter, child: c),
              child: Image.asset(pa('rest_fox'), width: w * 0.34),
            ),
          ),
          Positioned(
            left: w * 0.24,
            bottom: size.height * 0.11,
            child: AnimatedBuilder(
              animation: _life,
              builder: (_, c) => Transform.translate(offset: Offset(0, -5 * sin(_life.value * 2 * pi).abs()), child: c),
              child: Image.asset(pa('rest_robot'), width: w * 0.44),
            ),
          ),
          // floating "z"
          AnimatedBuilder(
            animation: _life,
            builder: (_, __) {
              final t = _life.value;
              return Stack(children: [
                for (var i = 0; i < 3; i++)
                  Positioned(
                    left: w * (0.5 + 0.05 * i) + 10 * sin((t + i / 3) * 2 * pi),
                    bottom: size.height * (0.4 + ((t + i / 3) % 1) * 0.12),
                    child: Opacity(
                      opacity: 1 - ((t + i / 3) % 1),
                      child: Text('z', style: ps(22.0 + i * 6, color: Colors.white, w: FontWeight.w700)),
                    ),
                  ),
              ]);
            },
          ),
          // message
          SafeArea(
            child: Column(children: [
              SizedBox(height: size.height * 0.12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  decoration: BoxDecoration(
                    color: PC.cream.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Column(children: [
                    Text(pT(context, 'restTitle'), textAlign: TextAlign.center, style: ps(28, w: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(
                      quiet && widget.until != null
                          ? pT(context, 'restQuiet', {'time': '${(widget.until! ~/ 60).toString().padLeft(2, '0')}:${(widget.until! % 60).toString().padLeft(2, '0')}'})
                          : pT(context, 'restLimit'),
                      textAlign: TextAlign.center,
                      style: ps(16.5, color: PC.sub, w: FontWeight.w500),
                    ),
                    const SizedBox(height: 10),
                    Image.asset(pa('rest_note'), width: 110),
                  ]),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
                child: PGhostButton(pT(context, 'imParent'), icon: Icons.lock_rounded, onTap: _parent),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _StarsPainter extends CustomPainter {
  final double t;
  _StarsPainter(this.t);
  static final _pts = List.generate(40, (i) {
    final r = Random(i * 7 + 3);
    return (r.nextDouble(), r.nextDouble() * 0.6, r.nextDouble());
  });

  @override
  void paint(Canvas c, Size s) {
    for (final p in _pts) {
      final a = 0.3 + 0.7 * (0.5 + 0.5 * sin((t + p.$3) * 2 * pi));
      c.drawCircle(Offset(p.$1 * s.width, p.$2 * s.height), 1.2 + p.$3 * 1.6, Paint()..color = Colors.white.withOpacity(a));
    }
  }

  @override
  bool shouldRepaint(_StarsPainter o) => o.t != t;
}

class _BreakDialog extends StatelessWidget {
  const _BreakDialog();

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(color: PC.cream, borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white, width: 3)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Image.asset(pa('rest_fox'), width: 130),
            const SizedBox(height: 8),
            Text(pT(context, 'breakTime'), textAlign: TextAlign.center, style: ps(24, w: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(pT(context, 'breakTimeSub'), textAlign: TextAlign.center, style: ps(15.5, color: PC.sub, w: FontWeight.w500)),
            const SizedBox(height: 16),
            KidPressable(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: PC.teal, borderRadius: BorderRadius.circular(28)),
                child: Text(pT(context, 'breakOk'), style: ps(19, color: Colors.white, w: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      );
}
