import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'alpha_draw_data.dart';

const adInk = Color(0xFF2A1A78);
const adPurple = Color(0xFF7A3CF0);
const adPurpleDeep = Color(0xFF5420C8);
const adLavender = Color(0xFFC7B0F6);
const adCream = Color(0xFFFFFAF0);
const adCyan = Color(0xFF34C6F2);
const adGreen = Color(0xFF16A34A);

enum AdMode { trace, practice, free }

String adLang(BuildContext c) {
  final l = Localizations.localeOf(c).languageCode;
  return const ['fr', 'en', 'ar', 'de'].contains(l) ? l : 'fr';
}

const Map<String, Map<String, String>> _ui = {
  'heroTitle': {'fr': 'Chaque lettre est une aventure !', 'en': 'Every letter is an adventure!', 'ar': 'كل حرف مغامرة!', 'de': 'Jeder Buchstabe ist ein Abenteuer!'},
  'heroSub': {'fr': 'Choisis une langue pour commencer à écrire.', 'en': 'Choose a language to start writing.', 'ar': 'اختر لغة لتبدأ الكتابة.', 'de': 'Wähle eine Sprache und fang an zu schreiben.'},
  'trace': {'fr': 'Tracer', 'en': 'Trace', 'ar': 'تتبّع', 'de': 'Nachfahren'},
  'practice': {'fr': 'S’entraîner', 'en': 'Practice', 'ar': 'تمرّن', 'de': 'Üben'},
  'free': {'fr': 'Dessin libre', 'en': 'Free draw', 'ar': 'رسم حر', 'de': 'Frei malen'},
  'letsWrite': {'fr': 'C’est parti !', 'en': 'Let’s write!', 'ar': 'هيا نكتب!', 'de': 'Los geht’s!'},
  'traceLetter': {'fr': 'Trace la lettre {L}', 'en': 'Trace the letter {L}', 'ar': 'تتبّع الحرف {L}', 'de': 'Fahre {L} nach'},
  'writeLetter': {'fr': 'Écris la lettre {L}', 'en': 'Write the letter {L}', 'ar': 'اكتب الحرف {L}', 'de': 'Schreibe {L}'},
  'drawLetter': {'fr': 'Dessine la lettre {L}', 'en': 'Draw the letter {L}', 'ar': 'ارسم الحرف {L}', 'de': 'Male {L}'},
  'followDots': {'fr': 'Suis les points dans le bon sens', 'en': 'Follow the dots in the right order', 'ar': 'اتبع النقاط بالترتيب الصحيح', 'de': 'Folge den Punkten der Reihe nach'},
  'followShape': {'fr': 'Suis la forme de la lettre', 'en': 'Follow the shape of the letter', 'ar': 'اتبع شكل الحرف', 'de': 'Folge der Form des Buchstabens'},
  'practiceSub': {'fr': 'Sans les flèches cette fois !', 'en': 'No arrows this time!', 'ar': 'بدون أسهم هذه المرة!', 'de': 'Diesmal ohne Pfeile!'},
  'freeSub': {'fr': 'Amuse-toi avec les couleurs !', 'en': 'Have fun with the colours!', 'ar': 'استمتع بالألوان!', 'de': 'Viel Spaß mit den Farben!'},
  'upper': {'fr': 'Majuscule', 'en': 'Uppercase', 'ar': 'كبير', 'de': 'Groß'},
  'lower': {'fr': 'Minuscule', 'en': 'Lowercase', 'ar': 'صغير', 'de': 'Klein'},
  'undo': {'fr': 'Annuler', 'en': 'Undo', 'ar': 'تراجع', 'de': 'Zurück'},
  'clear': {'fr': 'Effacer', 'en': 'Clear', 'ar': 'مسح', 'de': 'Löschen'},
  'replay': {'fr': 'Revoir', 'en': 'Replay', 'ar': 'إعادة', 'de': 'Zeigen'},
  'check': {'fr': 'Vérifier', 'en': 'Check', 'ar': 'تحقّق', 'de': 'Prüfen'},
  'done': {'fr': 'Terminé !', 'en': 'Done!', 'ar': 'انتهيت!', 'de': 'Fertig!'},
  'yourTurn': {'fr': 'À toi de jouer !', 'en': 'Your turn!', 'ar': 'دورك!', 'de': 'Du bist dran!'},
  'startDot': {'fr': 'Commence au point vert !', 'en': 'Start at the green dot!', 'ar': 'ابدأ من النقطة الخضراء!', 'de': 'Start am grünen Punkt!'},
  'watch': {'fr': 'Regarde bien !', 'en': 'Watch carefully!', 'ar': 'انظر جيداً!', 'de': 'Schau genau hin!'},
  'bravo': {'fr': 'Bravo !', 'en': 'Well done!', 'ar': 'أحسنت!', 'de': 'Super!'},
  'almost': {'fr': 'Presque ! Essaie encore', 'en': 'Almost! Try again', 'ar': 'تقريباً! حاول مجدداً', 'de': 'Fast! Nochmal'},
  'drawMore': {'fr': 'Trace toute la lettre !', 'en': 'Trace the whole letter!', 'ar': 'اكتب الحرف كاملاً!', 'de': 'Den ganzen Buchstaben!'},
  'stayInside': {'fr': 'Reste sur la lettre !', 'en': 'Stay on the letter!', 'ar': 'ابقَ على الحرف!', 'de': 'Bleib auf dem Buchstaben!'},
  'nice': {'fr': 'Joli dessin !', 'en': 'Lovely drawing!', 'ar': 'رسم جميل!', 'de': 'Schön gemalt!'},
  'next': {'fr': 'Lettre suivante', 'en': 'Next letter', 'ar': 'الحرف التالي', 'de': 'Nächster Buchstabe'},
  'again': {'fr': 'Recommencer', 'en': 'Try again', 'ar': 'أعد المحاولة', 'de': 'Nochmal'},
  'newLetter': {'fr': 'Nouvelle lettre apprise !', 'en': 'New letter learned!', 'ar': 'تعلّمت حرفاً جديداً!', 'de': 'Neuer Buchstabe gelernt!'},
  'chooseLang': {'fr': 'Choisis une langue', 'en': 'Choose a language', 'ar': 'اختر لغة', 'de': 'Wähle eine Sprache'},
  'unlockTitle': {'fr': 'Débloquer {N} ?', 'en': 'Unlock {N}?', 'ar': 'فتح {N}؟', 'de': '{N} freischalten?'},
  'unlockMsg': {'fr': 'Utilise {C} pièces d\'or pour débloquer cette langue.', 'en': 'Use {C} gold to unlock this language.', 'ar': 'استخدم {C} ذهب لفتح هذه اللغة.', 'de': 'Nutze {C} Gold, um diese Sprache freizuschalten.'},
  'notEnough': {'fr': 'Il te faut {C} pièces d\'or. Joue encore pour en gagner !', 'en': 'You need {C} gold. Keep playing to earn more!', 'ar': 'تحتاج إلى {C} ذهب. واصل اللعب لتربح المزيد!', 'de': 'Du brauchst {C} Gold. Spiel weiter, um mehr zu sammeln!'},
  'unlock': {'fr': 'Débloquer', 'en': 'Unlock', 'ar': 'فتح', 'de': 'Freischalten'},
  'later': {'fr': 'Plus tard', 'en': 'Later', 'ar': 'لاحقاً', 'de': 'Später'},
  'ok': {'fr': 'D’accord', 'en': 'OK', 'ar': 'حسناً', 'de': 'OK'},
  'lettersDone': {'fr': '{D}/{T} lettres', 'en': '{D}/{T} letters', 'ar': '{D}/{T} حروف', 'de': '{D}/{T} Buchstaben'},
  'isFor': {'fr': 'comme', 'en': 'is for', 'ar': 'مثل', 'de': 'wie'},
};

String adText(BuildContext c, String k) {
  final m = _ui[k];
  if (m == null) return k;
  return m[adLang(c)] ?? m['fr']!;
}

/// Saved progress for Alpha Draw.
class AdStore {
  static String _k(String code) => 'ad_done_$code';

  static Future<Set<String>> done(String code) async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_k(code)) ?? const []).toSet();
  }

  static Future<Map<String, int>> doneCounts() async {
    final p = await SharedPreferences.getInstance();
    return {for (final l in adLanguages) l.code: (p.getStringList(_k(l.code)) ?? const []).length};
  }

  /// Returns the new total when [char] was learned for the first time, otherwise null.
  static Future<int?> learn(String code, String char) async {
    final p = await SharedPreferences.getInstance();
    final s = (p.getStringList(_k(code)) ?? <String>[]);
    if (s.contains(char)) return null;
    s.add(char);
    await p.setStringList(_k(code), s);
    return s.length;
  }

  static Future<String?> lastLanguage() async => (await SharedPreferences.getInstance()).getString('ad_lang');
  static Future<void> setLastLanguage(String c) async => (await SharedPreferences.getInstance()).setString('ad_lang', c);
  static Future<int> lastIndex(String c) async => (await SharedPreferences.getInstance()).getInt('ad_idx_$c') ?? 0;
  static Future<void> setLastIndex(String c, int i) async => (await SharedPreferences.getInstance()).setInt('ad_idx_$c', i);
  static Future<AdMode> lastMode() async {
    final i = (await SharedPreferences.getInstance()).getInt('ad_mode') ?? 0;
    return AdMode.values[i.clamp(0, AdMode.values.length - 1)];
  }

  static Future<void> setLastMode(AdMode m) async => (await SharedPreferences.getInstance()).setInt('ad_mode', m.index);
}

// ─────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────

Widget adRoundBtn(double size, IconData icon, VoidCallback onTap, {bool flipRtl = false, BuildContext? context}) {
  final flip = flipRtl && context != null && Directionality.of(context) == TextDirection.rtl;
  return KidPressable(
    onTap: onTap,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFA06BFF), adPurpleDeep]),
        border: Border.all(color: Colors.white, width: max(2, size * 0.05)),
        boxShadow: [
          BoxShadow(color: adPurple.withOpacity(0.45), blurRadius: size * 0.22),
          BoxShadow(color: const Color(0xFF3A1490), offset: Offset(0, size * 0.06)),
        ],
      ),
      child: Transform.flip(flipX: flip, child: Icon(icon, color: Colors.white, size: size * 0.55)),
    ),
  );
}

BoxDecoration adPillDecoration(double r, {bool selected = false, Color? fill, Color? border}) => BoxDecoration(
      color: fill ?? adCream,
      borderRadius: BorderRadius.circular(r),
      border: Border.all(color: border ?? (selected ? adPurple : adLavender), width: selected ? 3.5 : 2.5),
      boxShadow: [
        if (selected) BoxShadow(color: adPurple.withOpacity(0.35), blurRadius: 14),
        BoxShadow(color: const Color(0xFF4B2A9A).withOpacity(0.18), blurRadius: 8, offset: const Offset(0, 4)),
      ],
    );

class AdHeader extends StatelessWidget {
  final double s;
  final String title;
  const AdHeader({super.key, required this.s, this.title = 'Alpha Draw'});

  @override
  Widget build(BuildContext context) {
    final audio = Provider.of<AudioManager>(context, listen: false);
    return Container(
      height: 64 * s,
      padding: EdgeInsets.symmetric(horizontal: 6 * s),
      decoration: adPillDecoration(40 * s),
      child: Row(children: [
        adRoundBtn(50 * s, Icons.arrow_back_rounded, () {
          audio.playEventSound('cancelButton');
          Navigator.of(context).maybePop();
        }, flipRtl: true, context: context),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(title, style: kidTitleStyle(32 * s, color: adInk).copyWith(shadows: const [])),
          ),
        ),
        Consumer<AudioManager>(
          builder: (_, a, __) => adRoundBtn(50 * s, a.isBgMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded, () {
            a.playEventSound('toggleButton');
            a.toggleBgMute();
          }),
        ),
      ]),
    );
  }
}

enum AdTail { none, left, bottomLeft, bottomRight }

/// Speech bubble with a purple outline and optional yellow sparkle marks.
class AdBubble extends StatelessWidget {
  final Widget child;
  final AdTail tail;
  final bool sparks;
  final EdgeInsets padding;
  const AdBubble({super.key, required this.child, this.tail = AdTail.none, this.sparks = false, this.padding = const EdgeInsets.all(12)});

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    var t = tail;
    if (rtl) {
      t = switch (tail) { AdTail.bottomLeft => AdTail.bottomRight, AdTail.bottomRight => AdTail.bottomLeft, _ => tail };
    }
    return CustomPaint(
      painter: _BubblePainter(t, sparks, rtl),
      child: Padding(
        padding: padding.add(EdgeInsets.only(
          left: t == AdTail.left && !rtl ? 12 : 0,
          right: t == AdTail.left && rtl ? 12 : 0,
          bottom: t == AdTail.bottomLeft || t == AdTail.bottomRight ? 12 : 0,
        )),
        child: child,
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  final AdTail tail;
  final bool sparks, rtl;
  _BubblePainter(this.tail, this.sparks, this.rtl);

  @override
  void paint(Canvas canvas, Size size) {
    final leftTail = tail == AdTail.left;
    final bottom = tail == AdTail.bottomLeft || tail == AdTail.bottomRight;
    final body = Rect.fromLTRB(
      leftTail && !rtl ? 12 : 0,
      0,
      size.width - (leftTail && rtl ? 12 : 0),
      size.height - (bottom ? 12 : 0),
    );
    final r = min(body.height * 0.45, 30.0);
    final path = Path()..addRRect(RRect.fromRectAndRadius(body, Radius.circular(r)));
    final tp = Path();
    switch (tail) {
      case AdTail.left:
        final y = body.top + body.height * 0.55;
        final x = rtl ? body.right : body.left;
        final d = rtl ? 1.0 : -1.0;
        tp
          ..moveTo(x - d * 2, y - 10)
          ..lineTo(x + d * 13, y + 6)
          ..lineTo(x - d * 2, y + 6)
          ..close();
      case AdTail.bottomLeft:
        final x = body.left + body.width * 0.16;
        tp
          ..moveTo(x, body.bottom - 2)
          ..lineTo(x - 8, body.bottom + 13)
          ..lineTo(x + 16, body.bottom - 2)
          ..close();
      case AdTail.bottomRight:
        final x = body.right - body.width * 0.16;
        tp
          ..moveTo(x, body.bottom - 2)
          ..lineTo(x + 8, body.bottom + 13)
          ..lineTo(x - 16, body.bottom - 2)
          ..close();
      case AdTail.none:
        break;
    }
    final full = Path.combine(PathOperation.union, path, tp);
    canvas.drawShadow(full, const Color(0xFF4B2A9A), 5, false);
    canvas.drawPath(full, Paint()..color = adCream);
    canvas.drawPath(
        full,
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB58BFF), adPurple])
              .createShader(Offset.zero & size)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2);
    if (sparks) {
      final p = Paint()
        ..color = const Color(0xFFFFC21A)
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round;
      final cy = body.center.dy - 2;
      for (final side in [-1.0, 1.0]) {
        // short dashes pointing outwards, like the mockup
        final x = side < 0 ? body.left + 12 : body.right - 12;
        canvas.drawLine(Offset(x, cy - 5), Offset(x + side * 7, cy - 11), p);
        canvas.drawLine(Offset(x, cy + 4), Offset(x + side * 8, cy + 8), p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter o) => o.tail != tail || o.sparks != sparks || o.rtl != rtl;
}

/// Big glossy yellow call-to-action button.
class AdYellowButton extends StatelessWidget {
  final double s;
  final String label;
  final Widget? leading;
  final VoidCallback? onTap;
  final double height;
  const AdYellowButton({super.key, required this.s, required this.label, this.leading, this.onTap, this.height = 70});

  @override
  Widget build(BuildContext context) {
    final h = height * s;
    return Opacity(
      opacity: onTap == null ? 0.55 : 1,
      child: KidPressable(
        onTap: onTap,
        pressedScale: 0.95,
        child: Container(
          height: h,
          padding: EdgeInsets.symmetric(horizontal: 12 * s),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(h / 2),
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFF07A), Color(0xFFFFD21F), Color(0xFFFFB800)]),
            border: Border.all(color: const Color(0xFFFFF6D8), width: 3.5),
            boxShadow: [
              const BoxShadow(color: Color(0xFFD98C00), offset: Offset(0, 5)),
              BoxShadow(color: const Color(0xFFFFB800).withOpacity(0.45), blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          child: Stack(alignment: Alignment.center, children: [
            Positioned(
              top: h * 0.08,
              left: h * 0.35,
              right: h * 0.35,
              height: h * 0.28,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.35), borderRadius: BorderRadius.circular(h)),
              ),
            ),
            Row(mainAxisSize: MainAxisSize.min, children: [
              if (leading != null) ...[leading!, SizedBox(width: 12 * s)],
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label, style: kidTitleStyle(30 * s, color: adInk).copyWith(shadows: const [])),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

/// Purple circle with a white check, used inside the yellow button.
Widget adCheckBadge(double size) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFA06BFF), adPurpleDeep]),
        border: Border.all(color: Colors.white, width: 2.5),
      ),
      child: Icon(Icons.check_rounded, color: Colors.white, size: size * 0.66),
    );

/// The emoji, or the plane sprite for ✈️.
Widget adWordPicture(String emoji, double size) {
  if (emoji == '✈️') return Image.asset('${adDir}ad_plane.webp', width: size * 1.5, height: size * 0.9, fit: BoxFit.contain);
  return Text(emoji, style: TextStyle(fontSize: size * 0.8, height: 1.1));
}
