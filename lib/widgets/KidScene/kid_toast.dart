import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/main.dart' show navigatorKey;

/// The 8 illustrated notification banners (level up, rewards, unlocks…).
enum KidToastKind { levelUp, rewards, avatar, banner, quest, badge, saved, lesson }

class _Spec {
  final String asset;
  final List<double> text; // text box L, T, R, B (fractions of the sprite)
  final double aspect; // height / width
  final Color title, sub;
  const _Spec(this.asset, this.text, this.aspect, this.title, this.sub);
}

const String _dir = 'assets/images/UI/Toasts/';
const Map<KidToastKind, _Spec> _specs = {
  KidToastKind.levelUp: _Spec('${_dir}toast_levelup.webp', [0.3768, 0.359, 0.8516, 0.8846], 312 / 775, Color(0xFFFFD43B), Color(0xFF4A1A9E)),
  KidToastKind.rewards: _Spec('${_dir}toast_rewards.webp', [0.3343, 0.2802, 0.8587, 0.7778], 207 / 715, Color(0xFF8A3B0E), Color(0xFFD9850A)),
  KidToastKind.avatar: _Spec('${_dir}toast_avatar.webp', [0.3855, 0.30, 0.8715, 0.80], 236 / 747, Color(0xFF5B1AAE), Color(0xFF5A2E0E)),
  KidToastKind.banner: _Spec('${_dir}toast_banner.webp', [0.3407, 0.25, 0.8654, 0.78], 180 / 728, Color(0xFF0B3F8A), Color(0xFF5A2E0E)),
  KidToastKind.quest: _Spec('${_dir}toast_quest.webp', [0.3622, 0.2727, 0.8486, 0.7525], 198 / 740, Color(0xFF1F7A1A), Color(0xFF5A2E0E)),
  KidToastKind.badge: _Spec('${_dir}toast_badge.webp', [0.4292, 0.3062, 0.8597, 0.8086], 209 / 727, Color(0xFF5B1AAE), Color(0xFF5A2E0E)),
  KidToastKind.saved: _Spec('${_dir}toast_saved.webp', [0.4126, 0.2304, 0.8465, 0.7277], 191 / 749, Color(0xFF1747A6), Color(0xFF5A2E0E)),
  KidToastKind.lesson: _Spec('${_dir}toast_lesson.webp', [0.4177, 0.2995, 0.8707, 0.7817], 197 / 735, Color(0xFF0E6B3C), Color(0xFF5A2E0E)),
};

class _Item {
  final KidToastKind kind;
  String? title, sub;
  int gold, gems, level;
  final VoidCallback? onTap;
  final Completer<void> done = Completer<void>();
  final DateTime at = DateTime.now();
  _Item(this.kind, this.title, this.sub, this.gold, this.gems, this.level, this.onTap);
}

/// Slide-down notification banners, shown one after another from anywhere.
class KidToast {
  KidToast._();
  static final List<_Item> _queue = [];
  static _Item? _current;
  static final ValueNotifier<int> _tick = ValueNotifier(0);

  /// Shows a banner. Rewards right after another banner are merged into it
  /// (e.g. "Quest completed! +20 gold"). Completes when the banner is gone.
  static Future<void> show(
    KidToastKind kind, {
    String? title,
    String? subtitle,
    int gold = 0,
    int gems = 0,
    int level = 0,
    VoidCallback? onTap,
  }) {
    if (kind == KidToastKind.rewards) {
      final target = _queue.isNotEmpty ? _queue.last : _current;
      if (target != null &&
          const {KidToastKind.rewards, KidToastKind.quest, KidToastKind.badge, KidToastKind.lesson}
              .contains(target.kind) &&
          DateTime.now().difference(target.at) < const Duration(milliseconds: 2500)) {
        target.gold += gold;
        target.gems += gems;
        _tick.value++;
        return target.done.future;
      }
    }
    final item = _Item(kind, title, subtitle, gold, gems, level, onTap);
    _queue.add(item);
    _next();
    return item.done.future;
  }

  static void reward({int gold = 0, int gems = 0}) {
    if (gold <= 0 && gems <= 0) return;
    show(KidToastKind.rewards, gold: gold, gems: gems);
  }

  static void _next() {
    if (_current != null || _queue.isEmpty) return;
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) {
      for (final i in _queue) {
        if (!i.done.isCompleted) i.done.complete();
      }
      _queue.clear();
      return;
    }
    final item = _current = _queue.removeAt(0);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastView(
        item: item,
        tick: _tick,
        onGone: () {
          entry.remove();
          if (!item.done.isCompleted) item.done.complete();
          _current = null;
          _next();
        },
      ),
    );
    overlay.insert(entry);
  }
}

class _ToastView extends StatefulWidget {
  final _Item item;
  final ValueNotifier<int> tick;
  final VoidCallback onGone;
  const _ToastView({required this.item, required this.tick, required this.onGone});

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView> with TickerProviderStateMixin {
  late final AnimationController _in = AnimationController(vsync: this, duration: const Duration(milliseconds: 520))..forward();
  late final AnimationController _shine = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  Timer? _timer;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    widget.tick.addListener(_refresh);
    _timer = Timer(Duration(milliseconds: widget.item.kind == KidToastKind.levelUp ? 3600 : 2800), _leave);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    _timer?.cancel();
    await _in.reverse();
    widget.onGone();
  }

  @override
  void dispose() {
    widget.tick.removeListener(_refresh);
    _timer?.cancel();
    _in.dispose();
    _shine.dispose();
    super.dispose();
  }

  String _t(BuildContext context, String key, [Map<String, Object>? args]) {
    final code = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    final lang = _txt.containsKey(code) ? code : (code == 'zgh' ? 'fr' : 'en');
    var s = _txt[lang]![key] ?? _txt['en']![key] ?? key;
    args?.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final spec = _specs[item.kind]!;
    final size = MediaQuery.sizeOf(context);
    final w = min(size.width - 20, 470.0);
    final h = w * spec.aspect;
    final top = MediaQuery.paddingOf(context).top + 6;

    final title = item.title ?? _t(context, 'title_${item.kind.name}');
    String? sub = item.sub;
    if (sub == null && item.kind == KidToastKind.levelUp) {
      sub = _t(context, 'levelSub', {'n': item.level});
    } else if (sub == null && item.kind != KidToastKind.rewards) {
      sub = _defaultSub(context, item.kind);
    }
    final rewardParts = <InlineSpan>[];
    if (item.gold > 0) {
      rewardParts.add(TextSpan(text: '+${item.gold} ${_t(context, 'gold')}', style: const TextStyle(color: Color(0xFFD9850A))));
    }
    if (item.gems > 0) {
      if (rewardParts.isNotEmpty) rewardParts.add(const TextSpan(text: '  ·  ', style: TextStyle(color: Color(0xFF8A6A4A))));
      rewardParts.add(TextSpan(text: '+${item.gems} ${_t(context, 'gems')}', style: const TextStyle(color: Color(0xFF1E6FE0))));
    }

    final box = spec.text;
    final textW = w * (box[2] - box[0]);
    final textH = h * (box[3] - box[1]);
    final isLevel = item.kind == KidToastKind.levelUp;

    Widget text = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: isLevel
                ? _Outlined(title, size: textH * 0.42, fill: spec.title, stroke: const Color(0xFF3B0F86))
                : Text(title,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.w700,
                      fontSize: textH * (rewardParts.isEmpty && sub == null ? 0.42 : 0.36),
                      color: spec.title,
                      height: 1.1,
                    )),
          ),
        ),
        if (isLevel && sub != null)
          Container(
            margin: EdgeInsets.only(top: textH * 0.04),
            padding: EdgeInsets.symmetric(horizontal: textH * 0.14, vertical: textH * 0.03),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4DE),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(sub,
                  style: TextStyle(
                      fontFamily: 'Fredoka', fontWeight: FontWeight.w700, fontSize: textH * 0.19, color: spec.sub, height: 1.1)),
            ),
          )
        else if (sub != null || rewardParts.isNotEmpty)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(children: [
                if (sub != null) TextSpan(text: sub, style: TextStyle(color: spec.sub)),
                if (sub != null && rewardParts.isNotEmpty) const TextSpan(text: '   '),
                ...rewardParts,
              ]),
              maxLines: 1,
              style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600, fontSize: textH * 0.24, height: 1.15),
            ),
          ),
      ],
    );

    return Positioned(
      top: top,
      left: (size.width - w) / 2,
      width: w,
      height: h,
      child: AnimatedBuilder(
        animation: _in,
        builder: (_, child) {
          final v = Curves.easeOutBack.transform(_in.value.clamp(0.0, 1.0));
          return Opacity(
            opacity: _in.value.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, -(1 - v) * (h + top)),
              child: Transform.scale(scale: 0.9 + 0.1 * v, child: child),
            ),
          );
        },
        child: Material(
          type: MaterialType.transparency,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              item.onTap?.call();
              _leave();
            },
            onVerticalDragEnd: (d) {
              if ((d.primaryVelocity ?? 0) < -100) _leave();
            },
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned.fill(child: Image.asset(spec.asset, fit: BoxFit.fill, filterQuality: FilterQuality.medium)),
              // moving shine across the banner
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _shine,
                    builder: (_, __) => ShaderMask(
                      blendMode: BlendMode.srcATop,
                      shaderCallback: (r) => LinearGradient(
                        begin: Alignment(-1.6 + _shine.value * 3.2, -0.4),
                        end: Alignment(-1.1 + _shine.value * 3.2, 0.4),
                        colors: [Colors.white.withOpacity(0), Colors.white.withOpacity(0.28), Colors.white.withOpacity(0)],
                      ).createShader(r),
                      child: Image.asset(spec.asset, fit: BoxFit.fill),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: w * box[0],
                top: h * box[1],
                width: textW,
                height: textH,
                child: Directionality(textDirection: Directionality.of(context), child: text),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  String? _defaultSub(BuildContext context, KidToastKind k) => switch (k) {
        KidToastKind.quest => _t(context, 'sub_quest'),
        KidToastKind.saved => _t(context, 'sub_saved'),
        KidToastKind.lesson => _t(context, 'sub_lesson'),
        _ => null,
      };
}

class _Outlined extends StatelessWidget {
  final String text;
  final double size;
  final Color fill, stroke;
  const _Outlined(this.text, {required this.size, required this.fill, required this.stroke});

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w700, fontSize: size, height: 1.05);
    return Stack(children: [
      Text(text,
          maxLines: 1,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = size * 0.16
              ..strokeJoin = StrokeJoin.round
              ..color = stroke,
          )),
      Text(text,
          maxLines: 1,
          style: base.copyWith(color: fill, shadows: [Shadow(color: Colors.orange.shade800, offset: Offset(0, size * 0.05))])),
    ]);
  }
}

const Map<String, Map<String, String>> _txt = {
  'en': {
    'title_levelUp': 'LEVEL UP!',
    'levelSub': 'Level {n} · Keep exploring!',
    'title_rewards': 'Rewards collected!',
    'title_avatar': 'New avatar unlocked!',
    'title_banner': 'New banner unlocked!',
    'title_quest': 'Quest completed!',
    'sub_quest': 'Great work, explorer!',
    'title_badge': 'Badge earned!',
    'title_saved': 'Progress saved!',
    'sub_saved': 'Your adventure is safe',
    'title_lesson': 'Lesson completed!',
    'sub_lesson': 'You learned something new!',
    'gold': 'gold',
    'gems': 'gems',
  },
  'fr': {
    'title_levelUp': 'NIVEAU SUP !',
    'levelSub': 'Niveau {n} · Continue l\'aventure !',
    'title_rewards': 'Récompenses reçues !',
    'title_avatar': 'Nouvel avatar débloqué !',
    'title_banner': 'Nouvelle bannière débloquée !',
    'title_quest': 'Quête terminée !',
    'sub_quest': 'Bravo, explorateur !',
    'title_badge': 'Badge gagné !',
    'title_saved': 'Progression enregistrée !',
    'sub_saved': 'Ton aventure est en sécurité',
    'title_lesson': 'Leçon terminée !',
    'sub_lesson': 'Tu as appris quelque chose !',
    'gold': 'pièces',
    'gems': 'gemmes',
  },
  'ar': {
    'title_levelUp': 'مستوى جديد!',
    'levelSub': 'المستوى {n} · واصل الاستكشاف!',
    'title_rewards': 'حصلت على مكافآت!',
    'title_avatar': 'شخصية جديدة مفتوحة!',
    'title_banner': 'خلفية جديدة مفتوحة!',
    'title_quest': 'أكملت المهمة!',
    'sub_quest': 'عمل رائع أيها المستكشف!',
    'title_badge': 'ربحت وساماً!',
    'title_saved': 'تم حفظ تقدمك!',
    'sub_saved': 'مغامرتك في أمان',
    'title_lesson': 'أكملت الدرس!',
    'sub_lesson': 'تعلّمت شيئاً جديداً!',
    'gold': 'ذهب',
    'gems': 'جواهر',
  },
  'de': {
    'title_levelUp': 'LEVEL UP!',
    'levelSub': 'Level {n} · Entdecke weiter!',
    'title_rewards': 'Belohnung erhalten!',
    'title_avatar': 'Neuer Avatar freigeschaltet!',
    'title_banner': 'Neues Banner freigeschaltet!',
    'title_quest': 'Quest geschafft!',
    'sub_quest': 'Super gemacht, Entdecker!',
    'title_badge': 'Abzeichen verdient!',
    'title_saved': 'Fortschritt gespeichert!',
    'sub_saved': 'Dein Abenteuer ist sicher',
    'title_lesson': 'Lektion geschafft!',
    'sub_lesson': 'Du hast etwas Neues gelernt!',
    'gold': 'Gold',
    'gems': 'Edelsteine',
  },
};
