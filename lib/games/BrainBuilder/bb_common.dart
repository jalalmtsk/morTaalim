import 'dart:math';

import 'package:mortaalim/Manager/rewards.dart';
import 'package:flutter/material.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bb_engine.dart';

/// Sprites sliced from the Brain Builder design sheet.
class BBAssets {
  BBAssets._();
  static const String dir = 'assets/images/Games/BrainBuilder/';
  static const String back = '${dir}bb_back.webp';
  static const String sound = '${dir}bb_sound.webp';
  static const String board = '${dir}bb_board.webp';
  static const String robot = '${dir}bb_robot.webp'; // 157 × 237
  static const String robotPoint = '${dir}bb_robot_point.webp'; // 278 × 289
  static const String glow = '${dir}bb_glow.webp';
  static const String goal = '${dir}bb_goal.webp';
  static const String star = '${dir}bb_star.webp';
  static const String reset = '${dir}bb_reset.webp';
  static const String bulb = '${dir}bb_bulb.webp'; // 93 × 115
  static const String plate = '${dir}bb_dpad_plate.webp'; // 352 × 336
  static const String cover = '${dir}bb_cover.webp'; // 3:2
  static const String tile = '${dir}bb_tile.webp'; // wide card art
  static const String bg = '${dir}bb_bg.webp';
  static const String coin = 'assets/images/UI/KidScene/home_coin.webp';
  static String btn(BBDir d) => '${dir}bb_btn_${d.name}.webp';

  // v2: map menu + world tiles
  static const String v2 = '${dir}v2/';
  static String a(String name) => '$v2$name.webp';
  static const String mapBg = '${v2}map_bg.webp'; // 941 × 1672
  static String worldThumb(int w) => '${v2}world_${const ['bridges', 'portal', 'ice', 'gear', 'moon', 'buddy'][w]}.webp';

  static List<String> get all => [
        back, sound, board, robot, robotPoint, glow, goal, star, reset, bulb, plate, cover, bg, coin,
        for (final d in BBDir.values) btn(d),
      ];
}

// ─── Translations (kept local so the game needs no ARB regeneration) ──────

const Map<String, Map<String, String>> _bbStrings = {
  'en': {
    'w0': 'Rainbow Bridges',
    'w1': 'Portal Garden',
    'w2': 'Ice Slide',
    'w3': 'Gear Factory',
    'w4': 'Moonlight Memory',
    'w5': 'Buddy Rescue',
    'worldN': 'World {n}',
    'completedN': '{n} / {t} completed',
    'playNext': 'Play next',
    'worldLocked': 'Finish the world before to open this one!',
    'goal_bridge': 'Open the bridges!',
    'sub_bridge': 'Step on a button to open gates of its colour',
    'goal_portal': 'Use the magic portals!',
    'sub_portal': 'Step in a portal to jump to its twin',
    'goal_gear': 'Turn the gear!',
    'sub_gear': 'The gear swaps which doors are open',
    'goal_moon': 'Find the star in the dark!',
    'sub_moon': 'Your lantern lights the way. Remember the path!',
    'goal_buddy': 'Bring both robots home!',
    'sub_buddy': 'They move together, each to its own picture',
    'gateOpen': 'A bridge opened!',
    'whoosh': 'Whoosh!',
    'gearTurn': 'Click! The doors moved',
    'allDone': 'You finished every world!',
    'title': 'Brain Builder',
    'play': 'Play',
    'levelN': 'Level {n}',
    'movesN': 'Moves: {n}',
    'reset': 'Reset',
    'hint': 'Hint',
    'tip': 'Think, try, discover!',
    'goal_walk': 'Help Robo reach the star!',
    'sub_walk': 'Use the arrows to find the way',
    'goal_collect': 'Collect all the little stars!',
    'sub_collect': 'Then bring Robo to the big star',
    'goal_slide': 'Robo is on ice!',
    'sub_slide': 'He slides until he hits a wall',
    'world1': 'Maze Meadow',
    'world2': 'Star Garden',
    'world3': 'Ice Islands',
    'perfect': 'Perfect!',
    'greatJob': 'Great job!',
    'next': 'Next',
    'done': 'Done',
    'yourMoves': 'Your moves: {n}',
    'bestMoves': 'Fewest possible: {n}',
    'bump': 'Oops, a wall!',
    'gotStar': 'Yay, a star!',
    'allStars': 'All stars! Now go to the big star',
    'needStars': 'Collect all the little stars first!',
    'stuck': 'Robo is stuck! Tap Reset',
    'hintTip': 'Follow the glowing arrows!',
    'moreHints': 'More hints',
    'moreHintsMsg': 'Get 3 more hints for {n} gold?',
    'buy': 'Get',
    'cancel': 'Cancel',
    'notEnough': 'Not enough gold!',
    'lockedMsg': 'Finish the level before to unlock this one!',
  },
  'fr': {
    'w0': 'Ponts arc-en-ciel',
    'w1': 'Jardin des portails',
    'w2': 'Glissade glacée',
    'w3': 'Usine à engrenages',
    'w4': 'Mémoire au clair de lune',
    'w5': 'Sauvetage d\'ami',
    'worldN': 'Monde {n}',
    'completedN': '{n} / {t} terminés',
    'playNext': 'À jouer',
    'worldLocked': 'Termine le monde précédent pour ouvrir celui-ci !',
    'goal_bridge': 'Ouvre les ponts !',
    'sub_bridge': 'Marche sur un bouton pour ouvrir les portes de sa couleur',
    'goal_portal': 'Utilise les portails magiques !',
    'sub_portal': 'Entre dans un portail pour sauter vers son jumeau',
    'goal_gear': 'Tourne l\'engrenage !',
    'sub_gear': 'L\'engrenage change les portes ouvertes',
    'goal_moon': 'Trouve l\'étoile dans le noir !',
    'sub_moon': 'Ta lanterne éclaire le chemin. Retiens-le !',
    'goal_buddy': 'Ramène les deux robots !',
    'sub_buddy': 'Ils bougent ensemble, chacun vers son image',
    'gateOpen': 'Un pont s\'est ouvert !',
    'whoosh': 'Hop !',
    'gearTurn': 'Clic ! Les portes ont bougé',
    'allDone': 'Tu as fini tous les mondes !',
    'title': 'Brain Builder',
    'play': 'Jouer',
    'levelN': 'Niveau {n}',
    'movesN': 'Coups : {n}',
    'reset': 'Refaire',
    'hint': 'Indice',
    'tip': 'Réfléchis, essaie, découvre !',
    'goal_walk': 'Aide Robo à atteindre l\'étoile !',
    'sub_walk': 'Utilise les flèches pour trouver le chemin',
    'goal_collect': 'Ramasse toutes les petites étoiles !',
    'sub_collect': 'Puis emmène Robo à la grande étoile',
    'goal_slide': 'Robo est sur la glace !',
    'sub_slide': 'Il glisse jusqu\'à toucher un mur',
    'world1': 'Prairie des labyrinthes',
    'world2': 'Jardin des étoiles',
    'world3': 'Îles de glace',
    'perfect': 'Parfait !',
    'greatJob': 'Bravo !',
    'next': 'Suivant',
    'done': 'Terminé',
    'yourMoves': 'Tes coups : {n}',
    'bestMoves': 'Le moins possible : {n}',
    'bump': 'Oups, un mur !',
    'gotStar': 'Youpi, une étoile !',
    'allStars': 'Toutes les étoiles ! Va à la grande étoile',
    'needStars': 'Ramasse d\'abord toutes les petites étoiles !',
    'stuck': 'Robo est coincé ! Appuie sur Refaire',
    'hintTip': 'Suis les flèches lumineuses !',
    'moreHints': 'Plus d\'indices',
    'moreHintsMsg': '3 indices de plus pour {n} pièces ?',
    'buy': 'Oui',
    'cancel': 'Annuler',
    'notEnough': 'Pas assez de pièces !',
    'lockedMsg': 'Termine le niveau précédent pour débloquer celui-ci !',
  },
  'ar': {
    'w0': 'جسور قوس قزح',
    'w1': 'حديقة البوابات',
    'w2': 'انزلاق الجليد',
    'w3': 'مصنع التروس',
    'w4': 'ذاكرة ضوء القمر',
    'w5': 'إنقاذ الصديق',
    'worldN': 'العالم {n}',
    'completedN': '{n} / {t} مكتمل',
    'playNext': 'العب الآن',
    'worldLocked': 'أكمل العالم السابق لفتح هذا العالم!',
    'goal_bridge': 'افتح الجسور!',
    'sub_bridge': 'قف على زر لتفتح البوابات بنفس لونه',
    'goal_portal': 'استعمل البوابات السحرية!',
    'sub_portal': 'ادخل البوابة لتقفز إلى توأمها',
    'goal_gear': 'أدر الترس!',
    'sub_gear': 'الترس يبدّل الأبواب المفتوحة',
    'goal_moon': 'جد النجمة في الظلام!',
    'sub_moon': 'فانوسك يضيء الطريق. تذكّره!',
    'goal_buddy': 'أوصل الروبوتين!',
    'sub_buddy': 'يتحركان معاً، كل واحد إلى صورته',
    'gateOpen': 'انفتح جسر!',
    'whoosh': 'ووش!',
    'gearTurn': 'طق! تحركت الأبواب',
    'allDone': 'أنهيت كل العوالم!',
    'title': 'باني الذكاء',
    'play': 'العب',
    'levelN': 'المستوى {n}',
    'movesN': 'الحركات: {n}',
    'reset': 'إعادة',
    'hint': 'تلميح',
    'tip': 'فكّر، جرّب، اكتشف!',
    'goal_walk': 'ساعد روبو للوصول إلى النجمة!',
    'sub_walk': 'استخدم الأسهم لتجد الطريق',
    'goal_collect': 'اجمع كل النجوم الصغيرة!',
    'sub_collect': 'ثم أوصل روبو إلى النجمة الكبيرة',
    'goal_slide': 'روبو على الجليد!',
    'sub_slide': 'ينزلق حتى يصطدم بجدار',
    'world1': 'مرج المتاهات',
    'world2': 'حديقة النجوم',
    'world3': 'جزر الجليد',
    'perfect': 'ممتاز!',
    'greatJob': 'أحسنت!',
    'next': 'التالي',
    'done': 'انتهى',
    'yourMoves': 'حركاتك: {n}',
    'bestMoves': 'أقل عدد ممكن: {n}',
    'bump': 'أوه، جدار!',
    'gotStar': 'رائع، نجمة!',
    'allStars': 'جمعت كل النجوم! اذهب إلى النجمة الكبيرة',
    'needStars': 'اجمع كل النجوم الصغيرة أولاً!',
    'stuck': 'روبو عالق! اضغط إعادة',
    'hintTip': 'اتبع الأسهم المضيئة!',
    'moreHints': 'تلميحات إضافية',
    'moreHintsMsg': 'هل تريد 3 تلميحات مقابل {n} قطعة ذهبية؟',
    'buy': 'نعم',
    'cancel': 'إلغاء',
    'notEnough': 'لا يوجد ذهب كافٍ!',
    'lockedMsg': 'أكمل المستوى السابق لفتح هذا المستوى!',
  },
  'de': {
    'w0': 'Regenbogenbrücken',
    'w1': 'Portalgarten',
    'w2': 'Eisrutsche',
    'w3': 'Zahnradfabrik',
    'w4': 'Mondlicht-Gedächtnis',
    'w5': 'Freunde retten',
    'worldN': 'Welt {n}',
    'completedN': '{n} / {t} geschafft',
    'playNext': 'Als Nächstes',
    'worldLocked': 'Schaffe zuerst die Welt davor!',
    'goal_bridge': 'Öffne die Brücken!',
    'sub_bridge': 'Tritt auf einen Knopf, um Tore seiner Farbe zu öffnen',
    'goal_portal': 'Nutze die Zauberportale!',
    'sub_portal': 'Tritt in ein Portal, um zu seinem Zwilling zu springen',
    'goal_gear': 'Dreh das Zahnrad!',
    'sub_gear': 'Das Zahnrad tauscht die offenen Türen',
    'goal_moon': 'Finde den Stern im Dunkeln!',
    'sub_moon': 'Deine Laterne leuchtet. Merk dir den Weg!',
    'goal_buddy': 'Bring beide Roboter nach Hause!',
    'sub_buddy': 'Sie laufen zusammen, jeder zu seinem Bild',
    'gateOpen': 'Eine Brücke ist offen!',
    'whoosh': 'Wusch!',
    'gearTurn': 'Klick! Die Türen haben sich bewegt',
    'allDone': 'Du hast alle Welten geschafft!',
    'title': 'Brain Builder',
    'play': 'Spielen',
    'levelN': 'Level {n}',
    'movesN': 'Züge: {n}',
    'reset': 'Neustart',
    'hint': 'Tipp',
    'tip': 'Denken, probieren, entdecken!',
    'goal_walk': 'Hilf Robo zum Stern!',
    'sub_walk': 'Finde den Weg mit den Pfeilen',
    'goal_collect': 'Sammle alle kleinen Sterne!',
    'sub_collect': 'Dann bring Robo zum großen Stern',
    'goal_slide': 'Robo ist auf dem Eis!',
    'sub_slide': 'Er rutscht, bis er eine Wand trifft',
    'world1': 'Labyrinth-Wiese',
    'world2': 'Sternengarten',
    'world3': 'Eisinseln',
    'perfect': 'Perfekt!',
    'greatJob': 'Super gemacht!',
    'next': 'Weiter',
    'done': 'Fertig',
    'yourMoves': 'Deine Züge: {n}',
    'bestMoves': 'Am wenigsten: {n}',
    'bump': 'Hoppla, eine Wand!',
    'gotStar': 'Juhu, ein Stern!',
    'allStars': 'Alle Sterne! Jetzt zum großen Stern',
    'needStars': 'Sammle zuerst alle kleinen Sterne!',
    'stuck': 'Robo steckt fest! Tippe auf Neustart',
    'hintTip': 'Folge den leuchtenden Pfeilen!',
    'moreHints': 'Mehr Tipps',
    'moreHintsMsg': '3 weitere Tipps für {n} Gold?',
    'buy': 'Ja',
    'cancel': 'Abbrechen',
    'notEnough': 'Nicht genug Gold!',
    'lockedMsg': 'Schaffe zuerst das Level davor!',
  },
};

String _langOf(String code) {
  if (_bbStrings.containsKey(code)) return code;
  if (code == 'zgh') return 'fr';
  return 'en';
}

/// Brain Builder text in the app's current language.
String bbT(BuildContext context, String key, [Map<String, Object>? args]) {
  final lang = _langOf(Localizations.localeOf(context).languageCode);
  var s = _bbStrings[lang]?[key] ?? _bbStrings['en']![key] ?? key;
  args?.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
  return s;
}

/// Title for the games list (works from AppLocalizations.localeName).
String bbTitleFor(String localeName) {
  final lang = _langOf(localeName.split(RegExp('[_-]')).first);
  return _bbStrings[lang]!['title']!;
}

// ─── Progress ──────────────────────────────────────────────────────────────

class BBProgress {
  BBProgress._();
  static String _stars(int n) => 'bb2_stars_$n';
  static String _best(int n) => 'bb2_best_$n';

  static Future<List<int>> allStars() async {
    final p = await SharedPreferences.getInstance();
    return [for (var n = 1; n <= bbLevelCount; n++) p.getInt(_stars(n)) ?? 0];
  }

  static Future<int> starsOf(int n) async => (await SharedPreferences.getInstance()).getInt(_stars(n)) ?? 0;

  static Future<void> record(int n, int stars, int moves) async {
    final p = await SharedPreferences.getInstance();
    if (stars > (p.getInt(_stars(n)) ?? 0)) await p.setInt(_stars(n), stars);
    final best = p.getInt(_best(n));
    if (best == null || moves < best) await p.setInt(_best(n), moves);
  }
}

/// Gold paid for reaching [stars] on a level where [prev] stars were already earned.
int bbReward(int level, int stars, int prev) => bbRewardFull(level, stars, prev).gold;

/// Full reward of a Brain Builder level (gold, XP, gems) — see Rewards.level.
/// Finishing the last level of a world for the first time gives +3 gems.
Reward bbRewardFull(int level, int stars, int prev) => Rewards.level(
      tier: bbWorldOf(level) + 1,
      stars: stars,
      prevStars: prev,
      bonusGems: prev == 0 && bbIndexInWorld(level) == bbLevelsPerWorld - 1 ? 3 : 0,
    );

// ─── Shared look ───────────────────────────────────────────────────────────

const Color bbCream = Color(0xFFFFFCF4);
const Color bbInk = Color(0xFF2A1366);

/// Chunky title: deep purple fill with a thick white outline.
class BBTitle extends StatelessWidget {
  final String text;
  final double size;
  const BBTitle(this.text, {super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w700, fontSize: size, height: 1.1);
    return Stack(
      children: [
        Text(text,
            maxLines: 1,
            style: base.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = size * 0.2
                ..strokeJoin = StrokeJoin.round
                ..color = Colors.white,
              shadows: [Shadow(color: const Color(0xFF5B21C9).withOpacity(0.35), blurRadius: size * 0.3, offset: Offset(0, size * 0.08))],
            )),
        Text(text, maxLines: 1, style: base.copyWith(color: bbInk)),
      ],
    );
  }
}

/// Cream rounded card used for every info pill.
class BBPill extends StatelessWidget {
  final Widget child;
  final double? height;
  final EdgeInsetsGeometry padding;
  final double radius;
  const BBPill({super.key, required this.child, this.height, this.padding = EdgeInsets.zero, this.radius = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bbCream,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: const Color(0xFF5B21C9).withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 5)),
        ],
      ),
      child: child,
    );
  }
}

/// A star sprite, or its pale lavender "empty" version.
class BBStar extends StatelessWidget {
  final bool on;
  final double size;
  const BBStar({super.key, required this.on, required this.size});

  @override
  Widget build(BuildContext context) {
    final img = Image.asset(BBAssets.star, width: size, height: size, fit: BoxFit.contain);
    if (on) return img;
    return ColorFiltered(colorFilter: const ColorFilter.mode(Color(0xFFDCD3FA), BlendMode.srcATop), child: img);
  }
}

/// Row of 3 stars; the change animates with a pop.
class BBStars extends StatelessWidget {
  final int count;
  final double size;
  const BBStars({super.key, required this.count, required this.size});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size * 0.06),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: BBStar(key: ValueKey(i < count), on: i < count, size: i == 1 ? size * 1.1 : size),
            ),
          ),
      ],
    );
  }
}

/// Round sprite button (back / sound), mirrored in RTL when asked.
class BBSpriteButton extends StatelessWidget {
  final String asset;
  final double size;
  final VoidCallback onTap;
  final bool flipRtl;
  final String? label;
  final Widget? overlay;
  const BBSpriteButton({
    super.key,
    required this.asset,
    required this.size,
    required this.onTap,
    this.flipRtl = false,
    this.label,
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return KidPressable(
      onTap: onTap,
      semanticLabel: label,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            Positioned.fill(
              child: Transform.flip(flipX: flipRtl && rtl, child: Image.asset(asset, fit: BoxFit.contain)),
            ),
            if (overlay != null) Positioned.fill(child: overlay!),
          ],
        ),
      ),
    );
  }
}
