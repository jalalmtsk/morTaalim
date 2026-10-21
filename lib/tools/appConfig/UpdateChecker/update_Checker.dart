// tools/appConfig/UpdateChecker/update_Checker.dart
//
// Firestore doc  app_settings/version  (all fields optional except latest_version):
//   latest_version : "1.1.0"   newest version on the store
//   min_version    : "1.0.5"   anything BELOW this is forced to update
//   force_update   : true      force everyone below latest_version (old behaviour)
//   android_url    : store link (falls back to the Play Store page of this app)
//   ios_url        : App Store link
//   update_message_en / _fr / _ar / _de / _zgh : optional custom line under the features
//
// Optional updates: "Later" hides the screen for that version for 2 days.

import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../audio_tool/Audio_Manager.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Logic
// ═══════════════════════════════════════════════════════════════════════════

class UpdateInfo {
  final String current, latest;
  final bool force;
  final String androidUrl, iosUrl;
  final Map<String, String> messages; // lang → custom line

  const UpdateInfo({
    required this.current,
    required this.latest,
    required this.force,
    this.androidUrl = '',
    this.iosUrl = '',
    this.messages = const {},
  });
}

class UpdateChecker {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String collectionName;
  final String documentName;

  UpdateChecker({this.collectionName = 'app_settings', this.documentName = 'version'});

  static const Duration snoozeFor = Duration(days: 2);
  static bool _showing = false;

  /// Call once at startup (after the first frame).
  Future<void> checkForUpdate(BuildContext context) async {
    if (_showing) return;
    try {
      final current = (await PackageInfo.fromPlatform()).version.trim();
      final doc = await firestore.collection(collectionName).doc(documentName).get();
      final data = doc.data();
      if (data == null) return;

      final latest = (data['latest_version'] ?? '').toString().trim();
      final minVersion = (data['min_version'] ?? '').toString().trim();
      if (latest.isEmpty || !isNewer(current, latest)) {
        debugPrint('✅ App is up to date: $current (latest $latest)');
        return;
      }

      final belowMin = minVersion.isNotEmpty && isNewer(current, minVersion);
      final force = belowMin || data['force_update'] == true;

      final info = UpdateInfo(
        current: current,
        latest: latest,
        force: force,
        androidUrl: (data['android_url'] ?? '').toString().trim(),
        iosUrl: (data['ios_url'] ?? '').toString().trim(),
        messages: {
          for (final l in const ['en', 'fr', 'ar', 'de', 'zgh'])
            if ((data['update_message_$l'] ?? '').toString().trim().isNotEmpty)
              l: data['update_message_$l'].toString().trim(),
        },
      );
      debugPrint('📦 Update: $current → $latest | force: $force');

      if (!force && await _isSnoozed(latest)) {
        debugPrint('😴 Optional update $latest snoozed');
        return;
      }
      if (!context.mounted) return;
      await show(context, info);
    } catch (e) {
      debugPrint('❌ Update check failed: $e');
    }
  }

  /// Opens the update screen. [preview] = debug mode (a forced screen can still be closed).
  static Future<void> show(BuildContext context, UpdateInfo info, {bool preview = false}) async {
    _showing = true;
    final route = PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 500),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => UpdateScreen(info: info, preview: preview),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    );
    try {
      final nav = Navigator.of(context);
      if (info.force && !preview) {
        await nav.pushAndRemoveUntil(route, (_) => false);
      } else {
        await nav.push(route);
      }
    } finally {
      _showing = false;
    }
  }

  /// Debug helper: shows the screen with fake versions.
  static Future<void> preview(BuildContext context, {required bool force}) async {
    var current = '1.0.0';
    try {
      current = (await PackageInfo.fromPlatform()).version;
    } catch (_) {}
    final parts = current.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    while (parts.length < 3) parts.add(0);
    parts[force ? 0 : 1] += 1;
    if (!context.mounted) return;
    await show(
      context,
      UpdateInfo(current: current, latest: parts.join('.'), force: force),
      preview: true,
    );
  }

  /// true when [latest] > [current]  (1.10.0 > 1.9.3, "1.2.0+5" handled).
  static bool isNewer(String current, String latest) {
    List<int> parse(String v) =>
        v.split('+').first.split('.').map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0).toList();
    final c = parse(current), l = parse(latest);
    for (var i = 0; i < max(c.length, l.length); i++) {
      final a = i < c.length ? c[i] : 0, b = i < l.length ? l[i] : 0;
      if (b != a) return b > a;
    }
    return false;
  }

  static String _snoozeKey(String v) => 'update_snooze_until_$v';

  static Future<bool> _isSnoozed(String latest) async {
    final p = await SharedPreferences.getInstance();
    final until = p.getInt(_snoozeKey(latest)) ?? 0;
    return DateTime.now().millisecondsSinceEpoch < until;
  }

  static Future<void> snooze(String latest) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_snoozeKey(latest), DateTime.now().add(snoozeFor).millisecondsSinceEpoch);
  }

  /// Tries the configured link, then the Play Store app, then the Play Store website.
  static Future<bool> openStore(UpdateInfo info) async {
    final ios = defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;
    var pkg = '';
    try {
      pkg = (await PackageInfo.fromPlatform()).packageName;
    } catch (_) {}
    final links = <String>[
      ios ? info.iosUrl : info.androidUrl,
      if (!ios && pkg.isNotEmpty) 'market://details?id=$pkg',
      if (!ios && pkg.isNotEmpty) 'https://play.google.com/store/apps/details?id=$pkg',
    ].where((l) => l.isNotEmpty);
    for (final l in links) {
      try {
        if (await launchUrl(Uri.parse(l), mode: LaunchMode.externalApplication)) return true;
      } catch (_) {}
    }
    return false;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Screen
// ═══════════════════════════════════════════════════════════════════════════

const String _dir = 'assets/images/UI/Update/';
const Color _ink = Color(0xFF3B1A8C);
const Color _inkSoft = Color(0xFF5B3FA8);

class UpdateScreen extends StatefulWidget {
  final UpdateInfo info;
  final bool preview;
  const UpdateScreen({super.key, required this.info, this.preview = false});

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> with TickerProviderStateMixin {
  late final AnimationController _in =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..forward();
  late final AnimationController _idle =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  bool _opening = false;

  UpdateInfo get _info => widget.info;
  bool get _force => _info.force;

  @override
  void dispose() {
    _in.dispose();
    _idle.dispose();
    super.dispose();
  }

  String _t(String key) {
    var code = 'en';
    try {
      code = Localizations.localeOf(context).languageCode;
    } catch (_) {}
    final m = _strings[code] ?? (code == 'zgh' ? _strings['fr']! : _strings['en']!);
    return m[key] ?? _strings['en']![key] ?? key;
  }

  String get _lang {
    try {
      return Localizations.localeOf(context).languageCode;
    } catch (_) {
      return 'en';
    }
  }

  void _sound(String key) {
    try {
      Provider.of<AudioManager>(context, listen: false).playEventSound(key);
    } catch (_) {}
  }

  Animation<double> _seg(double a, double b, [Curve c = Curves.easeOutBack]) =>
      CurvedAnimation(parent: _in, curve: Interval(a, b, curve: c));

  Future<void> _update() async {
    if (_opening) return;
    _sound('clickButton');
    HapticFeedback.lightImpact();
    setState(() => _opening = true);
    final ok = await UpdateChecker.openStore(_info);
    if (!mounted) return;
    setState(() => _opening = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_t('error'), style: const TextStyle(fontFamily: 'Fredoka')),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _later() async {
    _sound('cancelButton');
    if (!widget.preview) await UpdateChecker.snooze(_info.latest);
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = mq.size;
    final s = min(size.width / 400, (size.height - mq.padding.vertical) / 820).clamp(0.62, 1.25).toDouble();

    return PopScope(
      canPop: !_force || widget.preview,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFBF0),
        body: Stack(fit: StackFit.expand, children: [
          // sky
          Image.asset('assets/images/UI/BackGrounds/onboarding_sky_bg.jpg', fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 0.45, 0.75],
                colors: [Color(0xFF8FD3FF), Color(0xFFCDEBFF), Color(0x00FFFFFF)],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _idle,
            builder: (_, __) => CustomPaint(painter: _CloudsPainter(_idle.value)),
          ),
          SafeArea(
            child: Column(children: [
              SizedBox(height: 6 * s),
              _header(s),
              Expanded(child: _scene(s)),
              _card(s),
              SizedBox(height: 10 * s),
            ]),
          ),
          if (widget.preview)
            PositionedDirectional(
              top: mq.padding.top + 8,
              end: 10,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(20)),
                  child: Text('DEBUG · ${_force ? 'forced' : 'optional'}  ✕',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  // ── header: logo + headline ──────────────────────────────────────────────
  Widget _header(double s) {
    return Column(children: [
      ScaleTransition(
        scale: _seg(0.0, 0.35),
        child: AnimatedBuilder(
          animation: _idle,
          builder: (_, c) => Transform.translate(offset: Offset(0, sin(_idle.value * 2 * pi * 2) * 3 * s), child: c),
          child: Column(children: [
            Image.asset('${_dir}up_logo.webp', width: 96 * s),
            _OutlinedText('MoorTaalim', size: 22 * s, color: _ink, stroke: 5 * s),
          ]),
        ),
      ),
      SizedBox(height: 4 * s),
      FadeTransition(
        opacity: _seg(0.15, 0.45, Curves.easeOut),
        child: SlideTransition(
          position: Tween(begin: const Offset(0, -0.3), end: Offset.zero).animate(_seg(0.15, 0.5)),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20 * s),
            child: _OutlinedText(_t('headline'), size: 30 * s, color: _ink, stroke: 7 * s, maxLines: 2),
          ),
        ),
      ),
    ]);
  }

  // ── scene: magic book + characters ──────────────────────────────────────
  Widget _scene(double s) {
    return LayoutBuilder(builder: (_, c) {
      final w = c.maxWidth, h = c.maxHeight;
      if (h < 90) return const SizedBox.shrink();
      final k = min(w / 400, h / 330); // scene scale
      double bob(double speed, double phase, double amp) => sin((_idle.value * speed + phase) * 2 * pi) * amp * k;

      Widget pop(double a, double b, Widget child) => ScaleTransition(scale: _seg(a, b), child: child);

      return AnimatedBuilder(
        animation: _idle,
        builder: (_, __) {
          final glow = 0.55 + 0.25 * sin(_idle.value * 2 * pi * 3);
          final bookW = 250 * k;
          final bookL = w * 0.5 - bookW * 0.32;
          final bookT = h * 0.04;
          return Stack(clipBehavior: Clip.none, children: [
            // glow behind the book
            Positioned(
              left: bookL - 40 * k,
              top: bookT - 30 * k,
              width: bookW + 80 * k,
              height: bookW * 0.61 + 60 * k,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(colors: [
                    const Color(0xFFFFF2B0).withOpacity(glow),
                    const Color(0xFFFFF2B0).withOpacity(0),
                  ]),
                ),
              ),
            ),
            // the book
            Positioned(
              left: bookL,
              top: bookT + bob(2, 0, 4),
              child: pop(0.2, 0.55, Image.asset('${_dir}up_book.webp', width: bookW)),
            ),
            // little icons flying out of the book
            ..._flyers(k, bookL, bookT, bookW, bob),
            // sparkles
            for (var i = 0; i < 6; i++) _twinkle(k, w, h, i),
            // robot
            Positioned(
              left: w * 0.5 - 190 * k,
              bottom: 0 + bob(2, 0.2, 2).abs(),
              child: pop(
                0.35,
                0.7,
                Transform.rotate(
                  angle: sin(_idle.value * 2 * pi * 2) * 0.03,
                  alignment: Alignment.bottomCenter,
                  child: Image.asset('${_dir}up_robot.webp', width: 135 * k),
                ),
              ),
            ),
            // kid
            Positioned(
              left: w * 0.5 - 62 * k,
              bottom: 0,
              child: pop(
                0.42,
                0.78,
                Transform.translate(
                  offset: Offset(0, -bob(3, 0.5, 2.5).abs()),
                  child: Image.asset('${_dir}up_kid.webp', width: 92 * k),
                ),
              ),
            ),
            // fox (little hop every cycle)
            Positioned(
              left: w * 0.5 + 40 * k,
              bottom: 0,
              child: pop(
                0.5,
                0.85,
                Transform.translate(
                  offset: Offset(0, -_hop(_idle.value) * 14 * k),
                  child: Image.asset('${_dir}up_fox.webp', width: 104 * k),
                ),
              ),
            ),
          ]);
        },
      );
    });
  }

  /// A short hop twice per cycle.
  double _hop(double t) {
    final x = (t * 2) % 1.0;
    return x < 0.12 ? sin(x / 0.12 * pi) : 0;
  }

  List<Widget> _flyers(double k, double bookL, double bookT, double bookW, double Function(double, double, double) bob) {
    const items = [
      ['up_puzzle', -0.18, 0.15, 46.0, 0.0],
      ['up_blocks', -0.12, 0.62, 44.0, 0.3],
      ['up_rocket', 0.92, -0.05, 40.0, 0.6],
      ['up_palette', 0.98, 0.58, 42.0, 0.15],
      ['up_minibook', 0.42, -0.14, 38.0, 0.8],
    ];
    return [
      for (var i = 0; i < items.length; i++)
        Positioned(
          left: bookL + bookW * (items[i][1] as double) + bob(1.5, items[i][4] as double, 5),
          top: bookT + bookW * 0.61 * (items[i][2] as double) + bob(2, (items[i][4] as double) + 0.25, 6),
          child: ScaleTransition(
            scale: _seg(0.45 + i * 0.06, 0.8 + i * 0.03),
            child: Transform.rotate(
              angle: sin((_idle.value * 2 + i * 0.2) * 2 * pi) * 0.12,
              child: Image.asset('${_dir}${items[i][0]}.webp', width: (items[i][3] as double) * k),
            ),
          ),
        ),
    ];
  }

  Widget _twinkle(double k, double w, double h, int i) {
    final r = Random(i * 31 + 7);
    final x = w * (0.1 + r.nextDouble() * 0.8), y = h * (0.05 + r.nextDouble() * 0.5);
    final t = (_idle.value * 3 + i / 6) % 1.0;
    final o = sin(t * pi);
    return Positioned(
      left: x,
      top: y,
      child: Opacity(
        opacity: o.clamp(0, 1).toDouble(),
        child: Transform.scale(
          scale: 0.5 + o * 0.6,
          child: Icon(Icons.auto_awesome, size: 16 * k, color: const Color(0xFFFFD54A)),
        ),
      ),
    );
  }

  // ── bottom card ──────────────────────────────────────────────────────────
  Widget _card(double s) {
    final custom = _info.messages[_lang];
    final line = custom ?? (_force ? _t('needed') : _t('install'));
    return SlideTransition(
      position: Tween(begin: const Offset(0, 0.6), end: Offset.zero).animate(_seg(0.25, 0.6, Curves.easeOutCubic)),
      child: FadeTransition(
        opacity: _seg(0.25, 0.5, Curves.easeOut),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 16 * s),
          padding: EdgeInsets.fromLTRB(16 * s, 14 * s, 16 * s, 14 * s),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFFDF7), Color(0xFFFFF5E2)],
            ),
            borderRadius: BorderRadius.circular(30 * s),
            border: Border.all(color: const Color(0xFFF3DFB5), width: 2.5 * s),
            boxShadow: [
              BoxShadow(color: const Color(0xFF6B4BB8).withOpacity(0.22), blurRadius: 24 * s, offset: Offset(0, 8 * s)),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // title with bursts
            Row(children: [
              Transform.flip(flipX: true, child: Image.asset('${_dir}up_burst.webp', width: 26 * s)),
              SizedBox(width: 4 * s),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(_t('title'),
                      style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w700, fontSize: 23 * s, color: _ink)),
                ),
              ),
              SizedBox(width: 4 * s),
              Image.asset('${_dir}up_burst.webp', width: 26 * s),
            ]),
            SizedBox(height: 6 * s),
            _versionChip(s),
            SizedBox(height: 10 * s),
            _feature(s, 0, 'up_ic_gift', _t('f1')),
            _feature(s, 1, 'up_ic_sparkle', _t('f2')),
            _feature(s, 2, 'up_ic_shield', _t('f3')),
            SizedBox(height: 6 * s),
            Text(line,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w600,
                    fontSize: 14 * s,
                    height: 1.3,
                    color: _force && custom == null ? const Color(0xFFC2410C) : _inkSoft)),
            SizedBox(height: 12 * s),
            _updateButton(s),
            SizedBox(height: 8 * s),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Image.asset('${_dir}up_ic_cloud.webp', width: 30 * s),
              SizedBox(width: 6 * s),
              Flexible(
                child: Text(_t('kept'),
                    style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600, fontSize: 13.5 * s, color: _inkSoft)),
              ),
            ]),
            if (!_force || widget.preview) ...[
              SizedBox(height: 8 * s),
              _Press(
                onTap: _later,
                child: SizedBox(
                  width: 270 * s,
                  height: 270 * s * 103 / 508,
                  child: Stack(alignment: Alignment.center, children: [
                    Positioned.fill(child: Image.asset('${_dir}up_btn_light.webp', fit: BoxFit.fill)),
                    Text(_force ? _t('close') : _t('later'),
                        style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w700, fontSize: 18 * s, color: _ink)),
                  ]),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _versionChip(double s) => Directionality(
        textDirection: TextDirection.ltr,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 4 * s),
          decoration: BoxDecoration(color: const Color(0xFFEDE6FF), borderRadius: BorderRadius.circular(20 * s)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('v${_info.current}',
                style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 12.5 * s,
                    color: _inkSoft.withOpacity(0.7),
                    decoration: TextDecoration.lineThrough)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6 * s),
              child: Icon(Icons.arrow_forward_rounded, size: 14 * s, color: _inkSoft),
            ),
            Text('v${_info.latest}',
                style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w700, fontSize: 13.5 * s, color: _ink)),
          ]),
        ),
      );

  Widget _feature(double s, int i, String icon, String label) {
    final a = _seg(0.5 + i * 0.08, 0.8 + i * 0.07, Curves.easeOutCubic);
    return FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween(begin: const Offset(0.25, 0), end: Offset.zero).animate(a),
        child: Container(
          margin: EdgeInsets.only(bottom: 7 * s),
          padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 6 * s),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(22 * s),
            boxShadow: [BoxShadow(color: const Color(0xFFE9D9B8).withOpacity(0.7), blurRadius: 6 * s, offset: Offset(0, 2 * s))],
          ),
          child: Row(children: [
            AnimatedBuilder(
              animation: _idle,
              builder: (_, c) => Transform.rotate(angle: sin((_idle.value * 3 + i * 0.33) * 2 * pi) * 0.08, child: c),
              child: Image.asset('${_dir}$icon.webp', width: 34 * s, height: 34 * s),
            ),
            SizedBox(width: 12 * s),
            Expanded(
              child: Text(label,
                  style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600, fontSize: 16 * s, color: _ink)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _updateButton(double s) {
    final w = 320 * s, h = w * 112 / 511;
    return ScaleTransition(
      scale: _seg(0.65, 1.0),
      child: AnimatedBuilder(
        animation: _idle,
        builder: (_, c) => Transform.scale(scale: 1 + 0.03 * sin(_idle.value * 2 * pi * 4), child: c),
        child: _Press(
          onTap: _update,
          child: SizedBox(
            width: w,
            height: h,
            child: Stack(alignment: Alignment.center, children: [
              Positioned.fill(child: Image.asset('${_dir}up_btn_orange.webp', fit: BoxFit.fill)),
              // shine sweeping across
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(h / 2),
                  child: AnimatedBuilder(
                    animation: _idle,
                    builder: (_, __) {
                      final t = (_idle.value * 2) % 1.0;
                      return FractionallySizedBox(
                        widthFactor: 1,
                        child: Transform.translate(
                          offset: Offset((t * 2.2 - 0.6) * w, 0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Transform.rotate(
                              angle: 0.35,
                              child: Container(
                                width: 28 * s,
                                height: h * 2,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    Colors.white.withOpacity(0),
                                    Colors.white.withOpacity(0.45),
                                    Colors.white.withOpacity(0),
                                  ]),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 4 * s),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (_opening)
                    SizedBox(
                      width: 26 * s,
                      height: 26 * s,
                      child: const CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                    )
                  else
                    AnimatedBuilder(
                      animation: _idle,
                      builder: (_, c) =>
                          Transform.translate(offset: Offset(0, sin(_idle.value * 2 * pi * 6) * 2.5 * s), child: c),
                      child: Image.asset('${_dir}up_ic_download.webp', width: 32 * s),
                    ),
                  SizedBox(width: 12 * s),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(_t('update'),
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontWeight: FontWeight.w700,
                            fontSize: 25 * s,
                            color: Colors.white,
                            shadows: const [Shadow(color: Color(0xFFB45309), blurRadius: 0, offset: Offset(0, 2))],
                          )),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Pieces
// ═══════════════════════════════════════════════════════════════════════════

/// Big title text with a white outline (like the mock-up).
class _OutlinedText extends StatelessWidget {
  final String text;
  final double size, stroke;
  final Color color;
  final int maxLines;
  const _OutlinedText(this.text, {required this.size, required this.color, required this.stroke, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    TextStyle base() => TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w700, fontSize: size, height: 1.1);
    return Stack(children: [
      Text(text,
          textAlign: TextAlign.center,
          maxLines: maxLines,
          style: base().copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = stroke
              ..strokeJoin = StrokeJoin.round
              ..color = Colors.white,
            shadows: [Shadow(color: const Color(0xFF6B4BB8).withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))],
          )),
      Text(text, textAlign: TextAlign.center, maxLines: maxLines, style: base().copyWith(color: color)),
    ]);
  }
}

class _Press extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _Press({required this.child, required this.onTap});
  @override
  State<_Press> createState() => _PressState();
}

class _PressState extends State<_Press> {
  bool _down = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) {
          setState(() => _down = false);
          widget.onTap();
        },
        child: AnimatedScale(scale: _down ? 0.93 : 1, duration: const Duration(milliseconds: 110), child: widget.child),
      );
}

/// Soft clouds drifting across the sky.
class _CloudsPainter extends CustomPainter {
  final double t;
  _CloudsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    const clouds = [
      [0.10, 0.10, 1.0, 1.0],
      [0.70, 0.06, 0.8, 1.6],
      [0.40, 0.22, 0.6, 0.7],
      [0.90, 0.30, 0.9, 1.2],
    ];
    for (final c in clouds) {
      final scale = size.width / 400 * c[2];
      final x = ((c[0] + t * 0.08 * c[3]) % 1.25 - 0.12) * size.width;
      final y = c[1] * size.height;
      for (final b in const [
        [0.0, 0.0, 22.0],
        [24.0, -10.0, 28.0],
        [52.0, 0.0, 22.0],
        [26.0, 8.0, 24.0],
      ]) {
        canvas.drawCircle(Offset(x + b[0] * scale, y + b[1] * scale), b[2] * scale, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_CloudsPainter o) => o.t != t;
}

// ═══════════════════════════════════════════════════════════════════════════
// Texts (zgh falls back to French)
// ═══════════════════════════════════════════════════════════════════════════

const Map<String, Map<String, String>> _strings = {
  'en': {
    'headline': 'A new adventure awaits you!',
    'title': 'MoorTaalim got even better!',
    'f1': 'New things to discover',
    'f2': 'A smoother experience',
    'f3': 'Bugs fixed',
    'install': 'Install the latest version to continue your adventure.',
    'needed': 'This update is needed to keep playing.',
    'update': 'Update',
    'kept': 'Your progress will be kept.',
    'later': 'Later',
    'close': 'Close',
    'error': "Couldn't open the store. Please try again.",
  },
  'fr': {
    'headline': 'Une nouvelle aventure t’attend !',
    'title': 'MoorTaalim s’améliore !',
    'f1': 'Des nouveautés à découvrir',
    'f2': 'Une expérience plus fluide',
    'f3': 'Des bugs corrigés',
    'install': 'Installe la dernière version pour continuer ton aventure.',
    'needed': 'Cette mise à jour est nécessaire pour continuer à jouer.',
    'update': 'Mettre à jour',
    'kept': 'Tes progrès seront conservés.',
    'later': 'Plus tard',
    'close': 'Fermer',
    'error': 'Impossible d’ouvrir le store. Réessaie.',
  },
  'ar': {
    'headline': 'مغامرة جديدة في انتظارك!',
    'title': 'MoorTaalim أصبح أفضل!',
    'f1': 'أشياء جديدة لتكتشفها',
    'f2': 'تجربة أكثر سلاسة',
    'f3': 'إصلاح الأخطاء',
    'install': 'ثبّت آخر إصدار لتكمل مغامرتك.',
    'needed': 'هذا التحديث ضروري لمواصلة اللعب.',
    'update': 'تحديث',
    'kept': 'سيتم الاحتفاظ بتقدّمك.',
    'later': 'لاحقاً',
    'close': 'إغلاق',
    'error': 'تعذّر فتح المتجر. حاول مرة أخرى.',
  },
  'de': {
    'headline': 'Ein neues Abenteuer wartet!',
    'title': 'MoorTaalim wird noch besser!',
    'f1': 'Neues zum Entdecken',
    'f2': 'Ein flüssigeres Erlebnis',
    'f3': 'Fehler behoben',
    'install': 'Installiere die neueste Version, um dein Abenteuer fortzusetzen.',
    'needed': 'Dieses Update wird zum Weiterspielen benötigt.',
    'update': 'Aktualisieren',
    'kept': 'Dein Fortschritt bleibt erhalten.',
    'later': 'Später',
    'close': 'Schließen',
    'error': 'Store konnte nicht geöffnet werden. Versuch es nochmal.',
  },
};
