import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/games/PuzzleLand/pz_common.dart';
import 'package:mortaalim/screens/main_home_screen/Profile/Badges/badge_catalog.dart';
import 'package:provider/provider.dart';

import 'cw_common.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Progress the collection world reads (badges stats, puzzles, level)
// ═══════════════════════════════════════════════════════════════════════════

class CwProgress {
  final BadgeStats stats;
  final int level, puzzlesDone;
  const CwProgress(this.stats, this.level, this.puzzlesDone);
  static const empty = CwProgress(BadgeStats.empty, 1, 0);

  int get badgesEarned => appBadges.where((b) => b.earned(stats)).length;
  int get treasuresFound => cwTreasures.where((t) => t.found(this)).length;

  static Future<CwProgress> load(BuildContext context) async {
    final level = Provider.of<ExperienceManager>(context, listen: false).level;
    final s = await BadgeStats.load(level: level);
    var puzzles = 0;
    try {
      final p = await PZProgress.load();
      puzzles = p.values.where((v) => v.any((x) => x > 0)).length;
    } catch (_) {}
    return CwProgress(s, level, puzzles);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// The nine treasures and how to find them
// ═══════════════════════════════════════════════════════════════════════════

class CwTreasure {
  final String id, asset;
  final int target;
  final int Function(CwProgress) value;
  final Map<String, String> name, how, story;
  const CwTreasure(this.id, this.asset, this.target, this.value, {required this.name, required this.how, required this.story});

  bool found(CwProgress p) => value(p) >= target;
  int progress(CwProgress p) => min(value(p), target);
}

final List<CwTreasure> cwTreasures = [
  CwTreasure('key', 'tr_key', 1, (p) => p.stats.courseLessons + p.stats.itLessons + p.stats.scope('religion') + p.stats.totalPlays,
      name: {'fr': 'La clé des découvertes', 'en': 'The key of discoveries', 'ar': 'مفتاح الاكتشافات', 'de': 'Der Schlüssel der Entdeckungen'},
      how: {'fr': 'fais ta toute première activité', 'en': 'do your very first activity', 'ar': 'أكمل أول نشاط لك', 'de': 'mach deine allererste Aufgabe'},
      story: {
        'fr': 'Un souvenir de tes premières aventures. Cette petite clé ouvre toutes les portes du savoir : il suffit d’être curieux !',
        'en': 'A souvenir of your first adventures. This little key opens every door of knowledge: all you need is curiosity!',
        'ar': 'ذكرى من مغامراتك الأولى. هذا المفتاح الصغير يفتح كل أبواب المعرفة، يكفي أن تكون فضولياً!',
        'de': 'Eine Erinnerung an deine ersten Abenteuer. Dieser kleine Schlüssel öffnet jede Tür des Wissens – du musst nur neugierig sein!',
      }),
  CwTreasure('crystal', 'tr_crystal', 3, (p) => p.level,
      name: {'fr': 'Le cristal des rêveries', 'en': 'The crystal of daydreams', 'ar': 'بلورة الأحلام', 'de': 'Der Kristall der Träume'},
      how: {'fr': 'atteins le niveau 3', 'en': 'reach level 3', 'ar': 'صل إلى المستوى 3', 'de': 'erreiche Level 3'},
      story: {
        'fr': 'Ce cristal brille plus fort chaque fois que tu apprends. Regarde dedans : tu y verras tous tes rêves !',
        'en': 'This crystal shines brighter every time you learn. Look inside: you will see all your dreams!',
        'ar': 'تلمع هذه البلورة أكثر كلما تعلمت. انظر بداخلها: سترى كل أحلامك!',
        'de': 'Dieser Kristall leuchtet heller, wann immer du lernst. Schau hinein: Du siehst all deine Träume!',
      }),
  CwTreasure('rocket', 'tr_rocket', 5, (p) => p.stats.distinctGames,
      name: {'fr': 'La fusée des possibles', 'en': 'The rocket of possibilities', 'ar': 'صاروخ الإمكانيات', 'de': 'Die Rakete der Möglichkeiten'},
      how: {'fr': 'essaie 5 jeux différents', 'en': 'try 5 different games', 'ar': 'جرّب 5 ألعاب مختلفة', 'de': 'probiere 5 verschiedene Spiele'},
      story: {
        'fr': 'Tu as exploré tant de jeux que cette fusée est prête à décoller vers de nouvelles planètes de découvertes !',
        'en': 'You explored so many games that this rocket is ready to blast off to new planets of discovery!',
        'ar': 'استكشفت ألعاباً كثيرة حتى أصبح هذا الصاروخ جاهزاً للانطلاق نحو كواكب جديدة!',
        'de': 'Du hast so viele Spiele erkundet, dass diese Rakete bereit ist, zu neuen Planeten zu starten!',
      }),
  CwTreasure('shell', 'tr_shell', 3, (p) => p.puzzlesDone,
      name: {'fr': 'Le coquillage des océans lointains', 'en': 'The shell of faraway oceans', 'ar': 'صدفة المحيطات البعيدة', 'de': 'Die Muschel der fernen Ozeane'},
      how: {'fr': 'termine 3 images de Puzzle Land', 'en': 'finish 3 Puzzle Land pictures', 'ar': 'أكمل 3 صور في أرض الألغاز', 'de': 'schaffe 3 Puzzle-Land-Bilder'},
      story: {
        'fr': 'Approche ton oreille : ce coquillage chante la mer. Il récompense les patients qui assemblent chaque pièce.',
        'en': 'Hold it to your ear: this shell sings the sea. It rewards patient minds who fit every piece together.',
        'ar': 'قرّبها من أذنك: هذه الصدفة تغني صوت البحر. إنها مكافأة لمن يصبر ويركّب كل قطعة.',
        'de': 'Halte sie ans Ohr: Diese Muschel singt vom Meer. Sie belohnt Geduldige, die jedes Teil zusammensetzen.',
      }),
  CwTreasure('compass', 'tr_compass', 3, (p) => p.stats.streak,
      name: {'fr': 'La boussole des horizons', 'en': 'The compass of horizons', 'ar': 'بوصلة الآفاق', 'de': 'Der Kompass der Horizonte'},
      how: {'fr': 'apprends 3 jours de suite', 'en': 'learn 3 days in a row', 'ar': 'تعلّم 3 أيام متتالية', 'de': 'lerne 3 Tage am Stück'},
      story: {
        'fr': 'Jour après jour, tu reviens apprendre. Cette boussole pointe toujours vers ta prochaine aventure.',
        'en': 'Day after day, you come back to learn. This compass always points to your next adventure.',
        'ar': 'يوماً بعد يوم تعود لتتعلم. هذه البوصلة تشير دائماً إلى مغامرتك التالية.',
        'de': 'Tag für Tag kommst du zum Lernen zurück. Dieser Kompass zeigt immer zu deinem nächsten Abenteuer.',
      }),
  CwTreasure('globe', 'tr_globe', 8, (p) => p.level,
      name: {'fr': 'Le globe des mondes', 'en': 'The globe of worlds', 'ar': 'كرة العوالم', 'de': 'Der Globus der Welten'},
      how: {'fr': 'atteins le niveau 8', 'en': 'reach level 8', 'ar': 'صل إلى المستوى 8', 'de': 'erreiche Level 8'},
      story: {
        'fr': 'Tu as tellement grandi ! Fais tourner ce globe : le monde entier attend tes découvertes.',
        'en': 'You have grown so much! Spin this globe: the whole world is waiting for your discoveries.',
        'ar': 'لقد كبرت كثيراً! أدر هذه الكرة: العالم كله ينتظر اكتشافاتك.',
        'de': 'Du bist so gewachsen! Dreh den Globus: Die ganze Welt wartet auf deine Entdeckungen.',
      }),
  CwTreasure('grimoire', 'tr_grimoire', 10, (p) => p.stats.courseLessons,
      name: {'fr': 'Le grimoire des histoires', 'en': 'The book of stories', 'ar': 'كتاب الحكايات', 'de': 'Das Buch der Geschichten'},
      how: {'fr': 'termine 10 leçons d’école', 'en': 'finish 10 school lessons', 'ar': 'أكمل 10 دروس مدرسية', 'de': 'schaffe 10 Schullektionen'},
      story: {
        'fr': 'Chaque leçon que tu termines ajoute une page magique à ce grimoire. Il est déjà bien rempli !',
        'en': 'Every lesson you finish adds a magic page to this book. It is already getting full!',
        'ar': 'كل درس تكمله يضيف صفحة سحرية إلى هذا الكتاب. لقد امتلأ كثيراً!',
        'de': 'Jede Lektion, die du schaffst, fügt diesem Buch eine Zauberseite hinzu. Es ist schon gut gefüllt!',
      }),
  CwTreasure('feather', 'tr_feather', 10, (p) => p.stats.artPlays,
      name: {'fr': 'La plume des grands rêves', 'en': 'The quill of big dreams', 'ar': 'ريشة الأحلام الكبيرة', 'de': 'Die Feder der großen Träume'},
      how: {'fr': 'dessine ou peins 10 fois', 'en': 'draw or paint 10 times', 'ar': 'ارسم أو لوّن 10 مرات', 'de': 'male 10 Mal'},
      story: {
        'fr': 'Cette plume dorée ne dessine que des choses merveilleuses… exactement comme toi !',
        'en': 'This golden quill only draws wonderful things… just like you!',
        'ar': 'هذه الريشة الذهبية لا ترسم إلا الأشياء الرائعة… تماماً مثلك!',
        'de': 'Diese goldene Feder malt nur wunderbare Dinge… genau wie du!',
      }),
  CwTreasure('lantern', 'tr_lantern', 8, (p) => p.badgesEarned,
      name: {'fr': 'La lanterne des amis', 'en': 'The lantern of friends', 'ar': 'فانوس الأصدقاء', 'de': 'Die Laterne der Freunde'},
      how: {'fr': 'gagne 8 badges', 'en': 'earn 8 badges', 'ar': 'اربح 8 أوسمة', 'de': 'verdiene 8 Abzeichen'},
      story: {
        'fr': 'Tous tes badges brillent dans cette lanterne. Elle éclaire le chemin pour toi et tes amis.',
        'en': 'All your badges glow inside this lantern. It lights the way for you and your friends.',
        'ar': 'كل أوسمتك تلمع داخل هذا الفانوس. إنه يضيء الطريق لك ولأصدقائك.',
        'de': 'All deine Abzeichen leuchten in dieser Laterne. Sie erhellt den Weg für dich und deine Freunde.',
      }),
];

// ═══════════════════════════════════════════════════════════════════════════
// The treasure cave
// ═══════════════════════════════════════════════════════════════════════════

class CwTreasuresPage extends StatefulWidget {
  const CwTreasuresPage({super.key});
  @override
  State<CwTreasuresPage> createState() => _CwTreasuresPageState();
}

class _CwTreasuresPageState extends State<CwTreasuresPage> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  late final AnimationController _pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
  CwProgress _p = CwProgress.empty;
  int _sel = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = await CwProgress.load(context);
      if (!mounted) return;
      setState(() {
        _p = p;
        _loaded = true;
        final first = cwTreasures.indexWhere((t) => t.found(p));
        _sel = first < 0 ? 0 : first;
      });
    });
  }

  @override
  void dispose() {
    _idle.dispose();
    _pop.dispose();
    super.dispose();
  }

  void _select(int i) {
    if (i == _sel) return;
    cwSound(context, cwTreasures[i].found(_p) ? 'PopButton' : 'clickButton2');
    setState(() => _sel = i);
    _pop.forward(from: 0);
  }

  void _story(CwTreasure t) {
    cwSound(context, 'clickButton');
    final s = cwScale(context);
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'story',
      barrierColor: const Color(0xCC120A35),
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (ctx, _, __) => Center(
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            width: min(MediaQuery.sizeOf(ctx).width - 40, 420),
            padding: EdgeInsets.fromLTRB(20 * s, 16 * s, 20 * s, 14 * s),
            decoration: BoxDecoration(
              color: cwCream,
              borderRadius: BorderRadius.circular(28 * s),
              border: Border.all(color: const Color(0xFFE8C77A), width: 3 * s),
              boxShadow: [BoxShadow(color: const Color(0xFFB794FF).withOpacity(0.6), blurRadius: 30 * s)],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(
                height: 170 * s,
                child: Stack(alignment: Alignment.center, children: [
                  Positioned.fill(child: _Rays(idle: _idle, color: const Color(0xFFFFE08A))),
                  CwFloat(idle: _idle, amp: 5 * s, speed: 2, child: Image.asset(cw(t.asset), height: 150 * s)),
                ]),
              ),
              Text(cwPick(ctx, t.name), textAlign: TextAlign.center, style: cwText(21 * s, color: cwPurpleDeep)),
              SizedBox(height: 8 * s),
              Text(cwPick(ctx, t.story),
                  textAlign: TextAlign.center, style: cwText(15.5 * s, color: cwInkSoft, weight: FontWeight.w500, height: 1.35)),
              SizedBox(height: 14 * s),
              CwButton(
                asset: cw('tr_btn_book'),
                label: cwT(ctx, 'close'),
                onTap: () => Navigator.pop(ctx),
                width: 180 * s,
                aspect: 0.3574,
                s: s,
              ),
            ]),
          ),
        ),
      ),
      transitionBuilder: (_, a, __, c) => ScaleTransition(
        scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: a, child: c),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = cwScale(context);
    final h = MediaQuery.sizeOf(context).height;
    final heroH = (h * 0.36).clamp(250.0, 360.0);
    final found = _p.treasuresFound;

    return CwIslandLayout(
      s: s,
      night: true,
      header: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10 * s),
        child: Row(children: [
          CwBack(size: 48 * s),
          SizedBox(width: 6 * s),
          Expanded(
            child: CwTitlePill(
              title: cwT(context, 'trTitle'),
              subtitle: cwT(context, 'trCount', {'n': found}),
              s: s,
              dark: true,
            ),
          ),
          SizedBox(width: 30 * s),
        ]),
      ),
      heroHeight: heroH,
      hero: _hero(s, heroH),
      panel: Column(children: [
        CwPanelTitle(s: s, text: cwT(context, 'trCabinet'), color: cwPurpleDeep),
        SizedBox(height: 10 * s),
        Expanded(
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(bottom: 8 * s, top: 4 * s),
            itemCount: cwTreasures.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10 * s,
              crossAxisSpacing: 10 * s,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (_, i) => _cell(s, i),
          ),
        ),
        CwBackLink(s: s, dark: true),
      ]),
    );
  }

  Widget _hero(double s, double heroH) {
    final t = cwTreasures[_sel];
    final got = t.found(_p);
    return LayoutBuilder(builder: (_, c) {
      final w = c.maxWidth;
      final itemH = heroH * 0.5;
      return Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(child: CwSparkles(idle: _idle, count: 18, seed: 5, color: const Color(0xFFB9E6FF))),
        // chest + explorer robot
        PositionedDirectional(
          start: -10 * s,
          top: heroH * 0.12,
          child: CwFloat(idle: _idle, amp: 2, speed: 1, child: Image.asset(cw('tr_chest'), width: w * 0.26)),
        ),
        PositionedDirectional(
          start: w * 0.08,
          top: heroH * 0.28,
          child: CwFloat(
            idle: _idle,
            amp: 4,
            speed: 1.5,
            phase: 0.3,
            tilt: 0.04,
            child: Transform.flip(flipX: cwRtl(context), child: Image.asset(cw('tr_robot'), width: w * 0.24)),
          ),
        ),
        // the treasure on its glowing stand
        Positioned(
          left: w * 0.28,
          right: w * 0.08,
          top: 0,
          height: itemH + 20 * s,
          child: Stack(alignment: Alignment.center, children: [
            if (got) Positioned.fill(child: _Rays(idle: _idle, color: const Color(0xFFFFE08A))),
            ScaleTransition(
              scale: CurvedAnimation(parent: _pop, curve: Curves.elasticOut),
              child: CwFloat(
                idle: _idle,
                amp: 6 * s,
                speed: 2,
                child: got
                    ? Image.asset(cw(t.asset), height: itemH)
                    : ColorFiltered(colorFilter: cwSilhouette, child: Image.asset(cw(t.asset), height: itemH)),
              ),
            ),
            if (!got)
              Icon(Icons.question_mark_rounded, size: itemH * 0.35, color: Colors.white.withOpacity(0.85)),
          ]),
        ),
        // plaque
        Positioned(
          left: 6 * s,
          right: 6 * s,
          bottom: 8 * s,
          child: _plaque(s, t, got),
        ),
      ]);
    });
  }

  Widget _plaque(double s, CwTreasure t, bool got) {
    final title = got ? cwPick(context, t.name) : cwT(context, 'hidden');
    final sub = got
        ? cwPick(context, t.story).split(RegExp(r'[.!?…]')).first.trim()
        : cwT(context, 'toFind', {'how': cwPick(context, t.how)});
    return Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
      Container(
        padding: EdgeInsets.fromLTRB(26 * s, 10 * s, 26 * s, got ? 24 * s : 12 * s),
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage('${cwDir}tr_plaque.webp'), fit: BoxFit.fill),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          FittedBox(fit: BoxFit.scaleDown, child: Text(title, maxLines: 1, style: cwText(20 * s, color: cwPurpleDeep))),
          SizedBox(height: 2 * s),
          Text(sub, maxLines: 2, textAlign: TextAlign.center, style: cwText(13.5 * s, color: cwInkSoft, weight: FontWeight.w500)),
          if (!got) ...[
            SizedBox(height: 6 * s),
            _progressBar(s, t.progress(_p) / t.target, '${t.progress(_p)} / ${t.target}'),
          ],
        ]),
      ),
      if (got)
        Positioned(
          bottom: -18 * s,
          child: CwPress(
            onTap: () => _story(t),
            label: cwT(context, 'story'),
            child: SizedBox(
              width: 170 * s,
              height: 170 * s * 0.3574,
              child: Stack(alignment: Alignment.center, children: [
                Positioned.fill(child: Image.asset(cw('tr_btn_book'), fit: BoxFit.fill)),
                Padding(
                  padding: EdgeInsetsDirectional.only(start: 34 * s, end: 10 * s),
                  child: FittedBox(fit: BoxFit.scaleDown, child: Text(cwT(context, 'story'), style: cwText(15 * s, color: Colors.white))),
                ),
              ]),
            ),
          ),
        ),
    ]);
  }

  Widget _progressBar(double s, double r, String label) => Row(children: [
        Expanded(
          child: Container(
            height: 12 * s,
            decoration: BoxDecoration(color: const Color(0xFFE5DCF5), borderRadius: BorderRadius.circular(10 * s)),
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              widthFactor: r.clamp(0.04, 1.0).toDouble(),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFA77BFF), cwPurple]),
                  borderRadius: BorderRadius.circular(10 * s),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 8 * s),
        Text(label, style: cwText(13 * s, color: cwPurpleDeep)),
      ]);

  Widget _cell(double s, int i) {
    final t = cwTreasures[i];
    final got = _loaded && t.found(_p);
    final sel = i == _sel;
    return CwPress(
      onTap: () => _select(i),
      label: got ? cwPick(context, t.name) : cwT(context, 'hidden'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.fromLTRB(4 * s, 6 * s, 4 * s, 4 * s),
        decoration: BoxDecoration(
          gradient: sel
              ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFEBDDFF), Color(0xFFFFF8EC)])
              : null,
          color: sel ? null : const Color(0xFFF7EFE0),
          borderRadius: BorderRadius.circular(20 * s),
          border: Border.all(color: sel ? const Color(0xFFB794FF) : Colors.transparent, width: 2.5 * s),
          boxShadow: sel ? [BoxShadow(color: const Color(0xFFB794FF).withOpacity(0.5), blurRadius: 12 * s)] : const [],
        ),
        child: Column(children: [
          Expanded(
            child: sel && got
                ? CwFloat(idle: _idle, amp: 3 * s, speed: 2, child: Image.asset(cw(t.asset), fit: BoxFit.contain))
                : got
                    ? Image.asset(cw(t.asset), fit: BoxFit.contain)
                    : Stack(alignment: Alignment.center, children: [
                        ColorFiltered(colorFilter: cwSilhouette, child: Image.asset(cw(t.asset), fit: BoxFit.contain)),
                        Icon(Icons.lock_rounded, color: Colors.white.withOpacity(0.9), size: 22 * s),
                      ]),
          ),
          SizedBox(height: 4 * s),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 6 * s, vertical: 3 * s),
            decoration: const BoxDecoration(
              image: DecorationImage(image: AssetImage('${cwDir}tr_plaque_small.webp'), fit: BoxFit.fill),
            ),
            child: Text(
              got ? cwPick(context, t.name) : '? ? ?',
              maxLines: 2,
              textAlign: TextAlign.center,
              style: cwText(10.5 * s, color: got ? cwInk : cwInkSoft, weight: FontWeight.w600, height: 1.1),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Slowly turning light rays behind a precious thing.
class _Rays extends StatelessWidget {
  final Animation<double> idle;
  final Color color;
  const _Rays({required this.idle, required this.color});
  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: idle,
          builder: (_, __) => CustomPaint(painter: _RaysPainter(idle.value, color)),
        ),
      );
}

class _RaysPainter extends CustomPainter {
  final double t;
  final Color color;
  _RaysPainter(this.t, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = min(size.width, size.height) * 0.62;
    canvas.drawCircle(
      c,
      r * 0.7,
      Paint()..shader = RadialGradient(colors: [color.withOpacity(0.55), color.withOpacity(0)]).createShader(Rect.fromCircle(center: c, radius: r * 0.7)),
    );
    final paint = Paint()
      ..shader = RadialGradient(colors: [color.withOpacity(0.45), color.withOpacity(0)]).createShader(Rect.fromCircle(center: c, radius: r));
    const n = 12;
    for (var i = 0; i < n; i++) {
      final a = t * 2 * pi * 0.5 + i * 2 * pi / n;
      final p = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + r * cos(a - 0.09), c.dy + r * sin(a - 0.09))
        ..lineTo(c.dx + r * cos(a + 0.09), c.dy + r * sin(a + 0.09))
        ..close();
      canvas.drawPath(p, paint);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter o) => o.t != t;
}
