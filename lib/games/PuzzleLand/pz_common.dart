import 'dart:math';

import 'package:mortaalim/Manager/rewards.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Puzzle Land sprites + pictures.
class PZAssets {
  PZAssets._();
  static const String dir = 'assets/images/Games/PuzzleLand/';
  static const String bg = '${dir}pz_bg.webp';
  static const String board = '${dir}pz_board.webp'; // hole: see [boardHole]
  static const String winFrame = '${dir}pz_winframe.webp'; // hole: see [winHole]
  static const String tray = '${dir}pz_tray.webp';
  static const String back = '${dir}pz_back.webp';
  static const String sound = '${dir}pz_sound.webp';
  static const String hint = '${dir}pz_hint.webp'; // 389 × 185
  static const String eye = '${dir}pz_icon_eye.webp';
  static const String reset = '${dir}pz_icon_reset.webp';
  static const String coin = '${dir}pz_coin.webp';
  static const String star = '${dir}pz_star.webp';
  static const String starOff = '${dir}pz_star_off.webp';
  static const String hand = '${dir}pz_hand.webp'; // 139 × 199
  static String picture(String id) => '${dir}pic_$id.webp';

  /// Inner hole of the board / win frame sprites (fractions L, T, R, B).
  static const List<double> boardHole = [0.0665, 0.0719, 0.9335, 0.9232];
  static const List<double> winHole = [0.1494, 0.21, 0.8785, 0.8516];
}

/// The pictures, in map order.
const List<String> pzPictures = [
  'fox', 'bunny', 'turtle', 'lion', 'elephant', 'camel',
  'chefchaouen', 'mosque', 'dino', 'riad', 'rocket',
];

/// Difficulty → grid size.
const List<int> pzGrid = [3, 4, 5];

// ─── Progress ──────────────────────────────────────────────────────────────

class PZProgress {
  PZProgress._();
  static String _k(String pic, int d) => 'pz_stars_${pic}_$d';

  /// stars[pic][difficulty]
  static Future<Map<String, List<int>>> load() async {
    final p = await SharedPreferences.getInstance();
    return {
      for (final pic in pzPictures) pic: [for (var d = 0; d < pzGrid.length; d++) p.getInt(_k(pic, d)) ?? 0]
    };
  }

  static Future<int> starsOf(String pic, int d) async => (await SharedPreferences.getInstance()).getInt(_k(pic, d)) ?? 0;

  static Future<void> record(String pic, int d, int stars) async {
    final p = await SharedPreferences.getInstance();
    if (stars > (p.getInt(_k(pic, d)) ?? 0)) await p.setInt(_k(pic, d), stars);
  }

  /// Easy is always open; Medium/Hard need the level before on the same picture.
  static bool unlocked(Map<String, List<int>> s, String pic, int d) => d == 0 || (s[pic]?[d - 1] ?? 0) > 0;
}

int pzReward(int difficulty, int stars, int prev) => pzRewardFull(difficulty, stars, prev).gold;

/// Full reward of a puzzle (gold, XP, gems) — see Rewards.level.
Reward pzRewardFull(int difficulty, int stars, int prev) => Rewards.level(tier: difficulty + 1, stars: stars, prevStars: prev);

// ─── Jigsaw shapes ─────────────────────────────────────────────────────────

/// Tab layout for an n×n puzzle. +1 = knob points down/right from the edge.
class PZCut {
  final int n;
  final List<List<int>> h; // h[r][c]: edge under row r (r < n-1)
  final List<List<int>> v; // v[r][c]: edge right of col c (c < n-1)
  PZCut._(this.n, this.h, this.v);

  factory PZCut(int n, int seed) {
    final r = Random(seed);
    int s() => r.nextBool() ? 1 : -1;
    return PZCut._(
      n,
      [for (var i = 0; i < n - 1; i++) [for (var j = 0; j < n; j++) s()]],
      [for (var i = 0; i < n; i++) [for (var j = 0; j < n - 1; j++) s()]],
    );
  }

  /// Margin around each cell that tabs can reach (fraction of cell size).
  static const double margin = 0.24;

  /// Piece outline in a box of (cell × (1 + 2·margin))², cell origin at (m, m).
  Path path(int row, int col, double cell) {
    final m = cell * margin;
    final top = row == 0 ? 0 : -h[row - 1][col];
    final bottom = row == n - 1 ? 0 : h[row][col];
    final left = col == 0 ? 0 : -v[row][col - 1];
    final right = col == n - 1 ? 0 : v[row][col];
    final a = Offset(m, m), b = Offset(m + cell, m), c = Offset(m + cell, m + cell), d = Offset(m, m + cell);
    final p = Path()..moveTo(a.dx, a.dy);
    // All four values are already "outward" signs for this piece.
    _edge(p, a, b, top);
    _edge(p, b, c, right);
    _edge(p, c, d, bottom);
    _edge(p, d, a, left);
    p.close();
    return p;
  }

  /// One side with an outward (s=1) / inward (s=-1) knob, or flat (s=0).
  static void _edge(Path p, Offset a, Offset b, int s) {
    if (s == 0) {
      p.lineTo(b.dx, b.dy);
      return;
    }
    final len = (b - a).distance;
    final dir = (b - a) / len;
    final nrm = Offset(dir.dy, -dir.dx) * s.toDouble(); // outward for clockwise path
    Offset q(double t, double k) => a + dir * (len * t) + nrm * (len * k);
    final p1 = q(0.36, 0), c1 = q(0.42, 0.0), c2 = q(0.28, 0.21), p2 = q(0.5, 0.22);
    final c3 = q(0.72, 0.21), c4 = q(0.58, 0.0), p3 = q(0.64, 0);
    p.lineTo(p1.dx, p1.dy);
    p.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    p.cubicTo(c3.dx, c3.dy, c4.dx, c4.dy, p3.dx, p3.dy);
    p.lineTo(b.dx, b.dy);
  }
}

/// One jigsaw piece of [image], sized for a board cell of [cell] px.
class PZPiece extends StatelessWidget {
  final PZCut cut;
  final String image;
  final int row, col;
  final double cell;
  final bool lifted; // stronger shadow while dragging
  const PZPiece({
    super.key,
    required this.cut,
    required this.image,
    required this.row,
    required this.col,
    required this.cell,
    this.lifted = false,
  });

  static double boxFor(double cell) => cell * (1 + 2 * PZCut.margin);

  @override
  Widget build(BuildContext context) {
    final box = boxFor(cell);
    final m = cell * PZCut.margin;
    final path = cut.path(row, col, cell);
    final n = cut.n;
    return SizedBox(
      width: box,
      height: box,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: CustomPaint(painter: _ShadowPainter(path, lifted))),
          Positioned.fill(
            child: ClipPath(
              clipper: _PathClip(path),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: m - col * cell,
                    top: m - row * cell,
                    width: n * cell,
                    height: n * cell,
                    child: Image.asset(image, fit: BoxFit.cover, filterQuality: FilterQuality.medium),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _OutlinePainter(path, cell))),
        ],
      ),
    );
  }
}

class _PathClip extends CustomClipper<Path> {
  final Path path;
  _PathClip(this.path);
  @override
  Path getClip(Size size) => path;
  @override
  bool shouldReclip(_PathClip o) => o.path != path;
}

class _ShadowPainter extends CustomPainter {
  final Path path;
  final bool lifted;
  _ShadowPainter(this.path, this.lifted);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawShadow(path, const Color(0xFF2A1366), lifted ? 10 : 3, false);
  }

  @override
  bool shouldRepaint(_ShadowPainter o) => o.path != path || o.lifted != lifted;
}

class _OutlinePainter extends CustomPainter {
  final Path path;
  final double cell;
  _OutlinePainter(this.path, this.cell);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.2, cell * 0.022)
        ..color = Colors.white.withOpacity(0.9),
    );
  }

  @override
  bool shouldRepaint(_OutlinePainter o) => o.path != path;
}

/// Faint outlines of every slot on the board (helps little ones).
class PZGridPainter extends CustomPainter {
  final PZCut cut;
  final double cell;
  PZGridPainter(this.cut, this.cell);

  @override
  void paint(Canvas canvas, Size size) {
    final m = cell * PZCut.margin;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.0, cell * 0.016)
      ..color = Colors.white.withOpacity(0.7);
    for (var r = 0; r < cut.n; r++) {
      for (var c = 0; c < cut.n; c++) {
        canvas.drawPath(cut.path(r, c, cell).shift(Offset(c * cell - m, r * cell - m)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(PZGridPainter o) => o.cut != cut || o.cell != cell;
}

// ─── Text ──────────────────────────────────────────────────────────────────

String pzT(BuildContext context, String key, [Map<String, Object>? args]) {
  final code = Localizations.localeOf(context).languageCode;
  final lang = _pz.containsKey(code) ? code : (code == 'zgh' ? 'fr' : 'en');
  var s = _pz[lang]![key] ?? _pz['en']![key] ?? key;
  args?.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
  return s;
}

String pzTitleFor(String localeName) {
  final code = localeName.split(RegExp('[_-]')).first;
  final lang = _pz.containsKey(code) ? code : (code == 'zgh' ? 'fr' : 'en');
  return _pz[lang]!['title']!;
}

const Map<String, Map<String, String>> _pz = {
  'en': {
    'title': 'Puzzle Land',
    'goal': 'Complete the picture!',
    'sub': 'Drag each piece into its place',
    'piecesN': '{n} / {t} pieces',
    'preview': 'Preview',
    'hint': 'Hint',
    'reset': 'Reset',
    'easy': 'Easy',
    'medium': 'Medium',
    'hard': 'Hard',
    'great': "You're doing great!",
    'almost': 'Almost! Try another spot',
    'nice': 'Perfect fit!',
    'hintTip': 'Look, it goes here!',
    'done': 'You did it!',
    'perfect': 'Perfect!',
    'next': 'Next',
    'replay': 'Again',
    'choose': 'Pick a picture',
    'lockedMsg': 'Finish the easier level first!',
    'moreHints': 'More hints',
    'moreHintsMsg': 'Get 3 more hints for {n} gold?',
    'buy': 'Get',
    'notEnough': 'Not enough gold!',
    'pic_fox': 'Happy Fox',
    'pic_bunny': 'Garden Bunny',
    'pic_turtle': 'Sea Turtle',
    'pic_lion': 'Little Lion',
    'pic_elephant': 'Splashy Elephant',
    'pic_camel': 'Desert Camel',
    'pic_chefchaouen': 'Blue Chefchaouen',
    'pic_mosque': 'Hassan II Mosque',
    'pic_dino': 'Baby Dino',
    'pic_riad': 'Marrakech Riad',
    'pic_rocket': 'Space Rocket',
  },
  'fr': {
    'title': 'Puzzle Land',
    'goal': 'Complète l\'image !',
    'sub': 'Glisse chaque pièce à sa place',
    'piecesN': '{n} / {t} pièces',
    'preview': 'Aperçu',
    'hint': 'Indice',
    'reset': 'Refaire',
    'easy': 'Facile',
    'medium': 'Moyen',
    'hard': 'Difficile',
    'great': 'Tu te débrouilles très bien !',
    'almost': 'Presque ! Essaie un autre endroit',
    'nice': 'Parfait !',
    'hintTip': 'Regarde, elle va ici !',
    'done': 'Tu as réussi !',
    'perfect': 'Parfait !',
    'next': 'Suivant',
    'replay': 'Rejouer',
    'choose': 'Choisis une image',
    'lockedMsg': 'Termine d\'abord le niveau plus facile !',
    'moreHints': 'Plus d\'indices',
    'moreHintsMsg': '3 indices de plus pour {n} pièces ?',
    'buy': 'Oui',
    'notEnough': 'Pas assez de pièces !',
    'pic_fox': 'Renard joyeux',
    'pic_bunny': 'Lapin du jardin',
    'pic_turtle': 'Tortue de mer',
    'pic_lion': 'Petit lion',
    'pic_elephant': 'Éléphant rigolo',
    'pic_camel': 'Chameau du désert',
    'pic_chefchaouen': 'Chefchaouen la bleue',
    'pic_mosque': 'Mosquée Hassan II',
    'pic_dino': 'Bébé dino',
    'pic_riad': 'Riad de Marrakech',
    'pic_rocket': 'Fusée de l\'espace',
  },
  'ar': {
    'title': 'أرض الألغاز',
    'goal': 'أكمل الصورة!',
    'sub': 'اسحب كل قطعة إلى مكانها',
    'piecesN': '{n} / {t} قطع',
    'preview': 'معاينة',
    'hint': 'تلميح',
    'reset': 'إعادة',
    'easy': 'سهل',
    'medium': 'متوسط',
    'hard': 'صعب',
    'great': 'أنت رائع!',
    'almost': 'تقريباً! جرّب مكاناً آخر',
    'nice': 'في مكانها تماماً!',
    'hintTip': 'انظر، مكانها هنا!',
    'done': 'لقد نجحت!',
    'perfect': 'ممتاز!',
    'next': 'التالي',
    'replay': 'مرة أخرى',
    'choose': 'اختر صورة',
    'lockedMsg': 'أكمل المستوى الأسهل أولاً!',
    'moreHints': 'تلميحات إضافية',
    'moreHintsMsg': 'هل تريد 3 تلميحات مقابل {n} قطعة ذهبية؟',
    'buy': 'نعم',
    'notEnough': 'لا يوجد ذهب كافٍ!',
    'pic_fox': 'الثعلب السعيد',
    'pic_bunny': 'أرنب الحديقة',
    'pic_turtle': 'السلحفاة البحرية',
    'pic_lion': 'الأسد الصغير',
    'pic_elephant': 'الفيل المرح',
    'pic_camel': 'جمل الصحراء',
    'pic_chefchaouen': 'شفشاون الزرقاء',
    'pic_mosque': 'مسجد الحسن الثاني',
    'pic_dino': 'الديناصور الصغير',
    'pic_riad': 'رياض مراكش',
    'pic_rocket': 'صاروخ الفضاء',
  },
  'de': {
    'title': 'Puzzle Land',
    'goal': 'Vervollständige das Bild!',
    'sub': 'Zieh jedes Teil an seinen Platz',
    'piecesN': '{n} / {t} Teile',
    'preview': 'Vorschau',
    'hint': 'Tipp',
    'reset': 'Neu',
    'easy': 'Leicht',
    'medium': 'Mittel',
    'hard': 'Schwer',
    'great': 'Das machst du super!',
    'almost': 'Fast! Probier eine andere Stelle',
    'nice': 'Passt genau!',
    'hintTip': 'Schau, es gehört hierhin!',
    'done': 'Geschafft!',
    'perfect': 'Perfekt!',
    'next': 'Weiter',
    'replay': 'Nochmal',
    'choose': 'Wähle ein Bild',
    'lockedMsg': 'Schaffe zuerst das leichtere Level!',
    'moreHints': 'Mehr Tipps',
    'moreHintsMsg': '3 weitere Tipps für {n} Gold?',
    'buy': 'Ja',
    'notEnough': 'Nicht genug Gold!',
  },
};
