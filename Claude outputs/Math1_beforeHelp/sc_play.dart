import 'dart:math';

import 'package:flutter/material.dart';

import 'm1_kit.dart';
import 'm1_shell.dart';
import 'm1_text.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Sciences — 1re année primaire. The five games run on the shared engine
// (menu, play frame with 5 challenges, results, map) of m1_shell.dart.
// ═══════════════════════════════════════════════════════════════════════════

/// An answer card: key, picture, label (a text key, '' = no label).
class ScOpt {
  final String key, sprite, label;
  const ScOpt(this.key, this.sprite, this.label);
}

/// Picks [n] random items of [list] (shuffled).
List<T> _some<T>(List<T> list, int n, Random r) => (List<T>.of(list)..shuffle(r)).take(n).toList();

/// Common base: a question, a scene and answer cards.
abstract class ScQuizState<W extends M1Play> extends M1PlayState<W> {
  List<ScOpt> opts = [];
  Set<String> answers = {};
  final Map<String, M1TileState> st = {};
  final Map<String, int> shake = {};
  bool labels = true;
  bool multi = false; // several right answers to find (missions)
  String missTopic = ''; // text key
  String? missHelp; // text key

  String get mode => lv.modeId;
  int get tier => lv.range; // 0 découverte · 1 entraînement · 2 défi

  void clearQuiz() {
    st.clear();
    shake.clear();
    multi = false;
    labels = true;
    missHelp = null;
  }

  String? rightText(ScOpt o) => null;

  String _t(String k) => k.isEmpty ? '' : m1T(context, k);

  void pick(ScOpt o) {
    if (busy || st[o.key] == M1TileState.good) return;
    if (answers.contains(o.key)) {
      setState(() => st[o.key] = M1TileState.good);
      if (multi) {
        final found = st.values.where((s) => s == M1TileState.good).length;
        if (found < answers.length) {
          m1Sound(context, 'PopButton');
          M1Voice.say(context, '$found');
          return;
        }
      }
      good(text: rightText(o));
    } else {
      setState(() {
        st[o.key] = M1TileState.bad;
        shake[o.key] = (shake[o.key] ?? 0) + 1;
      });
      bad(_t(missTopic), help: missHelp == null ? null : _t(missHelp!));
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted && st[o.key] == M1TileState.bad) setState(() => st.remove(o.key));
      });
    }
  }

  @override
  void hint() {
    mistakes++;
    final a = opts.where((o) => answers.contains(o.key) && st[o.key] != M1TileState.good);
    if (a.isNotEmpty) setState(() => st[a.first.key] = M1TileState.selected);
    say(missHelp == null ? instruction : _t(missHelp!));
  }

  Widget pill(String t, double h, {Color fill = const Color(0xFFEDE4FF)}) => Container(
        height: h,
        padding: EdgeInsets.symmetric(horizontal: h * 0.4),
        decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(h / 2)),
        alignment: Alignment.center,
        child: FittedBox(fit: BoxFit.scaleDown, child: Text(t, maxLines: 1, style: m1Text(h * 0.62))),
      );

  Widget optionGrid(double w, double h) {
    final n = opts.length;
    if (n == 0) return const SizedBox();
    final cols = n <= 3 ? n : (n == 4 ? 2 : 3);
    final rows = (n / cols).ceil();
    const gap = 10.0;
    final tw = min((w - gap * (cols - 1)) / cols, 170.0);
    final th = min((h - gap * (rows - 1)) / rows, tw * 1.05);
    return Wrap(alignment: WrapAlignment.center, spacing: gap, runSpacing: gap, children: [
      for (var i = 0; i < n; i++) optCard(opts[i], tw, th, i),
    ]);
  }

  Widget optCard(ScOpt o, double tw, double th, int i) => M1PopIn(
        key: ValueKey('o$round-${o.key}'),
        delay: 70 * i,
        child: M1Shake(
          trigger: shake[o.key] ?? 0,
          child: M1Press(
            onTap: busy ? null : () => pick(o),
            sound: '',
            label: _t(o.label),
            child: AnimatedScale(
              scale: st[o.key] == M1TileState.good ? 1.06 : 1,
              duration: const Duration(milliseconds: 250),
              child: M1Tile(
                width: tw,
                height: th,
                state: st[o.key] ?? M1TileState.idle,
                child: Padding(
                  padding: EdgeInsets.all(th * 0.07),
                  child: Column(children: [
                    Expanded(child: Image.asset(m1(o.sprite), fit: BoxFit.contain)),
                    if (labels && o.label.isNotEmpty) ...[SizedBox(height: th * 0.04), pill(_t(o.label), th * 0.17)],
                  ]),
                ),
              ),
            ),
          ),
        ),
      );

  /// A picture floating on a cream card, sized to the space it gets.
  Widget floatPic(String sprite, {double pad = 12}) => LayoutBuilder(builder: (_, c) {
        final ih = max(20.0, c.maxHeight - pad * 2 - 8);
        final iw = max(20.0, min(c.maxWidth - pad * 2 - 8, ih / m1Ratio(sprite)));
        return M1Card(
          radius: 26,
          padding: EdgeInsets.all(pad),
          child: M1Float(amp: 4, tilt: 0.015, child: Image.asset(m1(sprite), width: iw, height: min(ih, iw * m1Ratio(sprite)), fit: BoxFit.contain)),
        );
      });

  /// Robot + bubble, scene, instruction, answer cards.
  Widget quizBoard(double w, double h, {Widget? scene, int sceneFlex = 42}) {
    final rh = min(h * 0.2, 104.0);
    return Column(children: [
      SizedBox(height: rh, child: robotLine(w, rh, robotH: rh)),
      if (scene != null)
        Expanded(
          flex: sceneFlex,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Stack(children: [
              Positioned.fill(child: Center(child: M1PopIn(key: ValueKey('scene$round'), child: scene))),
              Positioned.fill(child: burstLayer()),
            ]),
          ),
        ),
      const SizedBox(height: 6),
      M1SayPill(text: instruction, width: min(w - 24, 380.0), height: 48),
      const SizedBox(height: 8),
      Expanded(
        flex: scene == null ? 100 : 100 - sceneFlex,
        child: LayoutBuilder(
          builder: (_, c) => Stack(children: [
            Center(child: optionGrid(min(c.maxWidth - 20, 420.0), c.maxHeight - 6)),
            if (scene == null) Positioned.fill(child: burstLayer()),
          ]),
        ),
      ),
      const SizedBox(height: 4),
    ]);
  }

  /// Tap-or-drag sorting: [items] go into [targets]; [home] says where each belongs.
  /// Returns the board; state lives in [placed] / [selected].
  final Map<String, String> placed = {}; // item → target
  String? selected;
  final Map<String, int> targetShake = {};

  void drop(String item, String target, String Function(String item) home, {required String miss, String? help}) {
    if (busy || placed.containsKey(item)) return;
    if (home(item) == target) {
      setState(() {
        placed[item] = target;
        selected = null;
      });
      m1Sound(context, 'PopButton');
      burst.forward(from: 0);
      if (placed.length == sortItems.length) good();
    } else {
      setState(() {
        selected = null;
        targetShake[target] = (targetShake[target] ?? 0) + 1;
      });
      bad(miss, help: help);
    }
  }

  List<String> get sortItems => const [];

  Widget dragItem(String item, String sprite, double size) {
    final sel = selected == item;
    final tile = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.1),
      decoration: BoxDecoration(
        color: sel ? const Color(0xFFDDF2FF) : const Color(0xFFFFFAF0),
        borderRadius: BorderRadius.circular(size * 0.2),
        border: Border.all(color: sel ? const Color(0xFF39B8F2) : const Color(0xFFEFDDB8), width: sel ? 3.5 : 2),
        boxShadow: [
          BoxShadow(color: const Color(0xFFC49A52).withOpacity(0.4), offset: const Offset(0, 4)),
          if (sel) BoxShadow(color: const Color(0xFF39B8F2).withOpacity(0.5), blurRadius: 12),
        ],
      ),
      child: Image.asset(m1(sprite), fit: BoxFit.contain),
    );
    return Draggable<String>(
      data: item,
      feedback: Material(type: MaterialType.transparency, child: Image.asset(m1(sprite), width: size * 1.1, height: size * 1.1)),
      childWhenDragging: Opacity(opacity: 0.25, child: tile),
      child: GestureDetector(
        onTap: () {
          setState(() => selected = sel ? null : item);
          m1Sound(context, 'toggleButton');
        },
        child: AnimatedScale(scale: sel ? 1.08 : 1, duration: const Duration(milliseconds: 200), child: tile),
      ),
    );
  }
}

class _Dash extends CustomPainter {
  final Color color;
  final double r;
  _Dash({this.color = const Color(0xFFB6A88E), this.r = 12});
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(3, 3, s.width - 6, s.height - 6), Radius.circular(r)));
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 9) {
        canvas.drawPath(m.extractPath(d, d + 5), p);
      }
    }
  }

  @override
  bool shouldRepaint(_Dash o) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
// 1 · LES CINQ SENS EN MISSION — je découvre · j'associe · petites missions
// ═══════════════════════════════════════════════════════════════════════════

const Map<String, String> _snSense = {
  'bird': 'ear', 'frog': 'ear', 'butterfly': 'eye', 'birdfly': 'eye', 'lavender': 'nose',
  'daisy': 'nose', 'scarf': 'hand', 'towel': 'hand', 'lemon': 'mouth',
};
const Map<String, String> _snSprite = {
  'bird': 'sc_bird_song', 'frog': 'sc_frog_pond', 'butterfly': 'sc_butterfly', 'birdfly': 'sc_bird_fly', 'lavender': 'sc_lavender',
  'daisy': 'sc_daisy', 'scarf': 'sc_m_scarf', 'towel': 'sc_m_towel', 'lemon': 'sc_lemon', 'key': 'sc_m_key', 'cube': 'sc_m_cube',
};
// things that clearly do NOT go with a sense (no tricky answers)
const Map<String, List<String>> _snNot = {
  'ear': ['lavender', 'lemon', 'key', 'scarf', 'butterfly', 'cube'],
  'nose': ['key', 'bird', 'cube', 'frog', 'butterfly', 'towel'],
  'hand': ['lemon', 'key', 'cube', 'lavender', 'frog', 'bird'],
  'mouth': ['key', 'scarf', 'butterfly', 'bird', 'cube', 'towel'],
};

class ScSensesPlay extends M1Play {
  const ScSensesPlay({super.key, required super.lv});
  @override
  State<ScSensesPlay> createState() => _SensesState();
}

class _SensesState extends ScQuizState<ScSensesPlay> {
  String _item = 'bird', _sense = 'ear';

  List<String> get _senses => [
        ['eye', 'ear', 'hand'],
        ['eye', 'ear', 'hand', 'nose'],
        ['eye', 'ear', 'hand', 'nose', 'mouth'],
      ][tier];

  @override
  String get instruction => switch (mode) {
        'discover' => m1T(context, 'sn_q_$_sense', {'x': m1T(context, 'sn_x_$_item')}),
        'match' => m1T(context, 'sn_m_$_sense'),
        _ => m1T(context, 'sn_f_$_sense'),
      };

  @override
  void newRound() {
    clearQuiz();
    switch (mode) {
      case 'discover':
        final items = _snSense.keys.where((k) => _senses.contains(_snSense[k])).toList();
        _item = items[rng.nextInt(items.length)];
        _sense = _snSense[_item]!;
        opts = [for (final s in _senses) ScOpt(s, 'sc_s_$s', 'sn_o_$s')]..shuffle(rng);
        answers = {_sense};
        labels = tier < 2;
      case 'match':
        final pool = [
          ['ear', 'nose'],
          ['ear', 'nose', 'hand'],
          ['ear', 'nose', 'hand', 'mouth'],
        ][tier];
        _sense = pool[rng.nextInt(pool.length)];
        final mine = _snSense.keys.where((k) => _snSense[k] == _sense).toList();
        _item = mine[rng.nextInt(mine.length)];
        final others = _some(_snNot[_sense]!, tier == 2 ? 3 : 2, rng);
        opts = [for (final k in [_item, ...others]) ScOpt(k, _snSprite[k]!, '')]..shuffle(rng);
        answers = {_item};
        labels = false;
      default:
        final pool = tier == 0 ? ['ear', 'hand'] : ['ear', 'nose', 'hand'];
        _sense = pool[rng.nextInt(pool.length)];
        final mine = _snSense.keys.where((k) => _snSense[k] == _sense).toList();
        final others = _some(_snNot[_sense]!, [2, 3, 4][tier], rng);
        opts = [for (final k in [...mine, ...others]) ScOpt(k, _snSprite[k]!, '')]..shuffle(rng);
        answers = mine.toSet();
        labels = false;
        multi = true;
    }
    missTopic = 'sn_rev_$_sense';
    missHelp = 'sn_help_$_sense';
  }

  @override
  String? rightText(ScOpt o) => mode == 'discover' ? m1T(context, 'sn_yes_$_sense') : null;

  @override
  Widget board(BuildContext context, double w, double h) => switch (mode) {
        'discover' => quizBoard(w, h, scene: floatPic(_snSprite[_item]!)),
        'match' => quizBoard(w, h, scene: floatPic('sc_s_$_sense'), sceneFlex: 36),
        _ => quizBoard(w, h),
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// 2 · LA GRAINE QUI GRANDIT — j'observe · je mets en ordre · je prends soin
// ═══════════════════════════════════════════════════════════════════════════

const _stages = ['seed', 'root', 'sprout', 'leaves'];
const _slotColors = [Color(0xFFF7811E), Color(0xFF14A9B8), Color(0xFF8A45E0), Color(0xFFF7811E)];
const Map<String, String> _careAnswer = {'water': 'can', 'light': 'sun', 'dig': 'trowel', 'rain': 'drops'};
const Map<String, String> _careSprite = {
  'can': 'sc_can', 'sun': 'sc_sun', 'trowel': 'sc_trowel', 'drops': 'sc_drops',
  'scarf': 'sc_m_scarf', 'glasses': 'sc_glasses', 'key': 'sc_m_key', 'hat': 'sc_hat',
};
const Map<String, String> _careScene = {'water': 'sc_soil_sprout', 'light': 'sc_soil_leaves', 'dig': 'sc_bean', 'rain': 'sc_w_rain'};

class ScSeedPlay extends M1Play {
  const ScSeedPlay({super.key, required super.lv});
  @override
  State<ScSeedPlay> createState() => _SeedState();
}

class _SeedState extends ScQuizState<ScSeedPlay> {
  String _q = 'seed';
  List<String> _seq = [];
  List<String> _cards = [];
  final List<String> _done = [];
  final Map<String, int> _cardShake = {};

  @override
  String get instruction => switch (mode) {
        'observe' => m1T(context, 'sd_q_$_q'),
        'order' => m1T(context, 'sd_order'),
        _ => m1T(context, 'sd_c_$_q'),
      };

  @override
  void newRound() {
    clearQuiz();
    _done.clear();
    _cardShake.clear();
    switch (mode) {
      case 'observe':
        final qs = tier == 0 ? ['seed', 'sprout', 'leaves', 'root'] : ['seed', 'root', 'sprout', 'leaves', 'first'];
        _q = qs[rng.nextInt(qs.length)];
        final a = _q == 'first' ? 'root' : _q;
        final others = _some(_stages.where((s) => s != a).toList(), tier == 0 ? 2 : 3, rng);
        opts = [for (final s in [a, ...others]) ScOpt(s, 'sc_soil_$s', 'sd_s_$s')]..shuffle(rng);
        answers = {a};
        labels = tier < 2;
        missTopic = 'sd_rev_obs';
        missHelp = 'sd_help_$a';
      case 'order':
        _seq = tier == 0 ? ['seed', 'sprout', 'leaves'] : List.of(_stages);
        do {
          _cards = List.of(_seq)..shuffle(rng);
        } while (_cards.join() == _seq.join());
        missTopic = 'sd_rev_order';
        missHelp = 'sd_order_help';
      default:
        final qs = tier == 0 ? ['water', 'light'] : ['water', 'light', 'dig', 'rain'];
        _q = qs[rng.nextInt(qs.length)];
        final a = _careAnswer[_q]!;
        // never offer the other "water" answer as a wrong one
        final pool = ['scarf', 'glasses', 'key', 'hat', ..._careAnswer.values.where((v) => v != a && !(['can', 'drops'].contains(v) && ['can', 'drops'].contains(a)))];
        final others = _some(pool, tier == 0 ? 2 : 3, rng);
        opts = [for (final k in [a, ...others]) ScOpt(k, _careSprite[k]!, 'sd_o_$k')]..shuffle(rng);
        answers = {a};
        missTopic = 'sd_rev_care';
        missHelp = 'sd_ch_$_q';
    }
  }

  void _tapCard(String s) {
    if (busy || _done.contains(s)) return;
    if (s == _seq[_done.length]) {
      setState(() => _done.add(s));
      m1Sound(context, 'PopButton');
      M1Voice.say(context, m1T(context, 'sd_s_$s'));
      if (_done.length == _seq.length) {
        good(text: m1T(context, 'sd_order_ok'));
      }
    } else {
      setState(() => _cardShake[s] = (_cardShake[s] ?? 0) + 1);
      bad(_t(missTopic), help: m1T(context, 'sd_next_${_seq[_done.length]}'));
    }
  }

  @override
  void hint() {
    if (mode != 'order') return super.hint();
    mistakes++;
    say(m1T(context, 'sd_next_${_seq[_done.length]}'));
  }

  @override
  Widget board(BuildContext context, double w, double h) => switch (mode) {
        'observe' => quizBoard(w, h),
        'order' => _orderBoard(w, h),
        _ => quizBoard(w, h, scene: floatPic(_careScene[_q]!), sceneFlex: 36),
      };

  Widget _orderBoard(double w, double h) {
    final rh = min(h * 0.2, 104.0);
    final n = _seq.length;
    final cell = min((w - 44 - 8.0 * n) / n, 104.0);
    return Column(children: [
      SizedBox(height: rh, child: robotLine(w, rh, robotH: rh)),
      M1SayPill(text: instruction, width: min(w - 24, 380.0), height: 48),
      const SizedBox(height: 10),
      Stack(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8EA),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE09A4A), width: 4),
            boxShadow: [BoxShadow(color: const Color(0xFF8A5A1A).withOpacity(0.3), offset: const Offset(0, 5), blurRadius: 8)],
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              for (var i = 0; i < n; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _slotColors[i % 4],
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), offset: const Offset(0, 2))],
                      ),
                      child: Text('${i + 1}', style: m1Text(14, color: Colors.white)),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: cell,
                      height: cell * 1.1,
                      child: i < _done.length
                          ? M1PopIn(
                              from: 0.2,
                              child: Column(children: [
                                Expanded(child: Image.asset(m1('sc_soil_${_done[i]}'), fit: BoxFit.contain)),
                                FittedBox(child: Text(m1T(context, 'sd_s_${_done[i]}'), style: m1Text(13))),
                              ]),
                            )
                          : CustomPaint(painter: _Dash(color: i == _done.length ? const Color(0xFF39B8F2) : const Color(0xFFB6A88E))),
                    ),
                  ]),
                ),
            ]),
          ),
        ),
        Positioned.fill(child: burstLayer()),
      ]),
      const Spacer(),
      Directionality(
        textDirection: TextDirection.ltr,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < _cards.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: _done.contains(_cards[i])
                  ? SizedBox(width: cell * 1.08, height: cell * 1.3)
                  : M1PopIn(
                      key: ValueKey('c$round-$i'),
                      delay: 90 * i,
                      child: M1Shake(
                        trigger: _cardShake[_cards[i]] ?? 0,
                        child: M1Press(
                          onTap: busy ? null : () => _tapCard(_cards[i]),
                          sound: '',
                          child: M1Float(
                            amp: 2.5,
                            phase: i * 0.2,
                            child: M1Tile(
                              width: cell * 1.08,
                              height: cell * 1.3,
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Column(children: [
                                  Expanded(child: Image.asset(m1('sc_soil_${_cards[i]}'), fit: BoxFit.contain)),
                                  if (tier < 2) FittedBox(child: Text(m1T(context, 'sd_s_${_cards[i]}'), style: m1Text(13))),
                                ]),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
        ]),
      ),
      const Spacer(),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(m1T(context, 'sd_placed', {'n': _done.length, 't': n}), style: m1Text(15)),
        const SizedBox(width: 8),
        for (var i = 0; i < n; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 22,
            height: 10,
            decoration: BoxDecoration(color: i < _done.length ? m1Orange : const Color(0xFFE2DACB), borderRadius: BorderRadius.circular(5)),
          ),
      ]),
      const SizedBox(height: 6),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 3 · QUI VIT OÙ ? — je découvre · j'associe · petites missions
// ═══════════════════════════════════════════════════════════════════════════

const _habitats = ['pond', 'forest', 'savanna'];
const Map<String, String> _home = {'frog': 'pond', 'kingfisher': 'pond', 'deer': 'forest', 'squirrel': 'forest', 'giraffe': 'savanna'};
const Map<String, String> _animalSprite = {
  'frog': 'sc_a_frog', 'kingfisher': 'sc_kingfisher', 'deer': 'sc_a_deer', 'squirrel': 'sc_squirrel', 'giraffe': 'sc_a_giraffe',
};

class ScHabitatPlay extends M1Play {
  const ScHabitatPlay({super.key, required super.lv});
  @override
  State<ScHabitatPlay> createState() => _HabitatState();
}

class _HabitatState extends ScQuizState<ScHabitatPlay> {
  String _animal = 'frog', _hab = 'pond';
  List<String> _round = []; // match: one animal per habitat

  List<String> get _animals => tier == 0 ? ['frog', 'deer', 'giraffe'] : _home.keys.toList();

  @override
  List<String> get sortItems => _round;

  @override
  String get instruction => switch (mode) {
        'discover' => m1T(context, 'hb_q_where', {'a': m1T(context, 'hb_a_$_animal')}),
        'match' => m1T(context, 'hb_match'),
        _ => m1T(context, 'hb_who_$_hab'),
      };

  @override
  void newRound() {
    clearQuiz();
    placed.clear();
    selected = null;
    switch (mode) {
      case 'discover':
        _animal = _animals[rng.nextInt(_animals.length)];
        _hab = _home[_animal]!;
        opts = [for (final h in _habitats) ScOpt(h, 'sc_hab_$h', 'hb_h_$h')]..shuffle(rng);
        answers = {_hab};
        missHelp = 'hb_help_$_hab';
      case 'match':
        String one(String h) {
          final l = _animals.where((a) => _home[a] == h).toList();
          return l[rng.nextInt(l.length)];
        }
        _round = [for (final h in _habitats) one(h)]..shuffle(rng);
        missHelp = 'hb_match_help';
      default:
        _hab = _habitats[rng.nextInt(3)];
        final mine = _animals.where((a) => _home[a] == _hab).toList();
        _animal = mine[rng.nextInt(mine.length)];
        final others = <String>[];
        for (final h in _habitats.where((h) => h != _hab)) {
          final l = _animals.where((a) => _home[a] == h).toList();
          others.add(l[rng.nextInt(l.length)]);
        }
        if (tier == 2) {
          final extra = _animals.where((a) => _home[a] != _hab && !others.contains(a)).toList();
          if (extra.isNotEmpty) others.add(extra[rng.nextInt(extra.length)]);
        }
        opts = [for (final a in [_animal, ...others]) ScOpt(a, _animalSprite[a]!, 'hb_n_$a')]..shuffle(rng);
        answers = {_animal};
        labels = tier < 2;
        missHelp = 'hb_help_$_hab';
    }
    missTopic = 'hb_rev';
  }

  @override
  String? rightText(ScOpt o) => mode == 'discover' ? m1T(context, 'hb_yes', {'a': m1T(context, 'hb_n_$_animal'), 'h': m1T(context, 'hb_h_$_hab')}) : null;

  @override
  void hint() {
    if (mode != 'match') return super.hint();
    mistakes++;
    final left = _round.where((a) => !placed.containsKey(a)).toList();
    if (left.isNotEmpty) say(m1T(context, 'hb_help_${_home[left.first]}'));
  }

  @override
  Widget board(BuildContext context, double w, double h) => switch (mode) {
        'discover' => quizBoard(w, h, scene: floatPic(_animalSprite[_animal]!), sceneFlex: 38),
        'match' => _matchBoard(w, h),
        _ => quizBoard(w, h, scene: floatPic('sc_hab_$_hab', pad: 8), sceneFlex: 36),
      };

  Widget _matchBoard(double w, double h) {
    final rh = min(h * 0.2, 100.0);
    final colW = (w - 40) / 3;
    final cardS = min(colW * 0.9, 100.0);
    return Column(children: [
      SizedBox(height: rh, child: robotLine(w, rh, robotH: rh)),
      M1SayPill(text: instruction, width: min(w - 24, 380.0), height: 46),
      const SizedBox(height: 8),
      Expanded(
        child: Stack(children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [for (final hb in _habitats) _column(hb, colW)]),
          ),
          Positioned.fill(child: burstLayer()),
        ]),
      ),
      const SizedBox(height: 10),
      SizedBox(
        height: cardS + 8,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (final a in _round)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: placed.containsKey(a)
                  ? SizedBox(width: cardS, height: cardS)
                  : M1PopIn(key: ValueKey('a$round$a'), child: dragItem(a, _animalSprite[a]!, cardS)),
            ),
        ]),
      ),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(color: m1Cream, borderRadius: BorderRadius.circular(18), border: Border.all(color: m1Line, width: 2)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Image.asset(m1('sc_ic_paw'), width: 20),
          const SizedBox(width: 6),
          Text(m1T(context, 'hb_placed', {'n': placed.length, 't': _round.length}), style: m1Text(14)),
        ]),
      ),
      const SizedBox(height: 4),
    ]);
  }

  Widget _column(String hb, double colW) {
    final mine = _round.firstWhere((a) => _home[a] == hb, orElse: () => '');
    final done = placed.containsKey(mine);
    final sil = const {'frog': 'sc_sil_frog', 'deer': 'sc_sil_deer', 'giraffe': 'sc_sil_giraffe'}[mine];
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (d) => drop(d.data, hb, (a) => _home[a]!, miss: m1T(context, 'hb_rev'), help: m1T(context, 'hb_help_${_home[d.data]}')),
      builder: (_, cand, __) => GestureDetector(
        onTap: selected == null ? null : () => drop(selected!, hb, (a) => _home[a]!, miss: m1T(context, 'hb_rev'), help: m1T(context, 'hb_help_${_home[selected!]}')),
        child: M1Shake(
          trigger: targetShake[hb] ?? 0,
          child: AnimatedScale(
            scale: cand.isNotEmpty || selected != null ? 1.04 : 1,
            duration: const Duration(milliseconds: 180),
            child: SizedBox(
              width: colW,
              child: LayoutBuilder(builder: (_, c) {
                final fh = min(c.maxHeight, colW * m1Ratio('sc_hab_frame_$hb'));
                return Center(
                  child: SizedBox(
                    width: colW,
                    height: fh,
                    child: Stack(children: [
                      Positioned.fill(child: Image.asset(m1('sc_hab_frame_$hb'), fit: BoxFit.fill)),
                      Positioned(
                        left: colW * 0.12,
                        right: colW * 0.12,
                        top: fh * 0.025,
                        height: fh * 0.1,
                        child: Center(child: FittedBox(child: Text(m1T(context, 'hb_h_$hb'), style: m1Text(16)))),
                      ),
                      if (!done && sil != null)
                        Positioned(left: colW * 0.18, right: colW * 0.18, top: fh * 0.3, bottom: fh * 0.2, child: Opacity(opacity: 0.8, child: Image.asset(m1(sil), fit: BoxFit.contain))),
                      if (done)
                        Positioned(
                          left: colW * 0.08,
                          right: colW * 0.08,
                          top: fh * 0.28,
                          bottom: fh * 0.1,
                          child: M1PopIn(from: 0.2, child: M1Float(amp: 3, child: Image.asset(m1(_animalSprite[mine]!), fit: BoxFit.contain))),
                        ),
                    ]),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 4 · LA MÉTÉO DE WAKI — je reconnais · j'observe · je choisis ma tenue
// ═══════════════════════════════════════════════════════════════════════════

const _kinds = ['sun', 'rain', 'snow', 'wind'];
const Map<String, List<String>> _wear = {
  'rain': ['raincoat', 'umbrella', 'boots'],
  'sun': ['hat', 'glasses'],
  'snow': ['scarf'],
};
const Map<String, String> _wearSprite = {
  'raincoat': 'sc_raincoat', 'umbrella': 'sc_umbrella', 'boots': 'sc_boots', 'hat': 'sc_hat', 'glasses': 'sc_glasses', 'scarf': 'sc_m_scarf',
};

class ScWeatherPlay extends M1Play {
  const ScWeatherPlay({super.key, required super.lv});
  @override
  State<ScWeatherPlay> createState() => _WeatherState();
}

class _WeatherState extends ScQuizState<ScWeatherPlay> {
  String _kind = 'sun';

  @override
  String get instruction => switch (mode) {
        'recognize' => m1T(context, 'wt_show', {'k': m1T(context, 'wt_k_$_kind')}),
        'observe' => m1T(context, 'wt_obs'),
        _ => m1T(context, 'wt_dress_$_kind'),
      };

  @override
  void newRound() {
    clearQuiz();
    switch (mode) {
      case 'recognize':
        final ks = tier == 0 ? ['sun', 'rain', 'snow'] : _kinds;
        _kind = ks[rng.nextInt(ks.length)];
        opts = [for (final k in ks) ScOpt(k, 'sc_w_$k', 'wt_k_$k')]..shuffle(rng);
        labels = tier < 2;
      case 'observe':
        final ks = tier == 0 ? ['sun', 'rain', 'snow'] : _kinds;
        _kind = ks[rng.nextInt(ks.length)];
        opts = [for (final k in ks) ScOpt(k, 'sc_w_$k', 'wt_k_$k')]..shuffle(rng);
        labels = tier < 2;
      default:
        final ks = tier == 0 ? ['sun', 'rain'] : ['sun', 'rain', 'snow'];
        _kind = ks[rng.nextInt(ks.length)];
        final mine = _wear[_kind]!;
        final a = mine[rng.nextInt(mine.length)];
        final pool = [for (final e in _wear.entries) if (e.key != _kind) ...e.value];
        final others = _some(pool, tier == 0 ? 2 : 3, rng);
        opts = [for (final k in [a, ...others]) ScOpt(k, _wearSprite[k]!, 'wt_o_$k')]..shuffle(rng);
        answers = {a};
        missTopic = 'wt_rev_dress';
        missHelp = 'wt_dh_$_kind';
        return;
    }
    answers = {_kind};
    missTopic = 'wt_rev_$_kind';
    missHelp = 'wt_h_$_kind';
  }

  @override
  String? rightText(ScOpt o) => mode == 'dress' ? m1T(context, 'wt_dress_ok') : m1T(context, 'wt_yes', {'k': m1T(context, 'wt_k_$_kind')});

  @override
  Widget board(BuildContext context, double w, double h) => switch (mode) {
        'recognize' => quizBoard(w, h),
        'observe' => quizBoard(w, h, scene: _window(), sceneFlex: 44),
        _ => quizBoard(w, h, scene: floatPic('sc_w_$_kind'), sceneFlex: 34),
      };

  Widget _window() => LayoutBuilder(builder: (_, c) {
        final sprite = _kind == 'rain' ? 'sc_win_rain' : 'sc_win_sun';
        final r = m1Ratio(sprite);
        final ww = min(c.maxWidth, c.maxHeight / r);
        final wh = ww * r;
        return SizedBox(
          width: ww,
          height: wh,
          child: Stack(children: [
            Positioned.fill(child: Image.asset(m1(sprite), fit: BoxFit.fill)),
            Positioned(
              left: ww * 0.2,
              right: ww * 0.2,
              top: wh * 0.08,
              bottom: wh * 0.16,
              child: IgnorePointer(
                child: ClipRect(
                  child: AnimatedBuilder(animation: idle, builder: (_, __) => CustomPaint(painter: _WeatherFx(_kind, idle.value))),
                ),
              ),
            ),
          ]),
        );
      });
}

/// Moving weather drawn over the window: snowflakes, gusts of wind, rain, sun glow.
class _WeatherFx extends CustomPainter {
  final String kind;
  final double t;
  _WeatherFx(this.kind, this.t);
  @override
  void paint(Canvas canvas, Size s) {
    final r = Random(9);
    switch (kind) {
      case 'snow':
        canvas.drawRect(Offset.zero & s, Paint()..color = Colors.white.withOpacity(0.38));
        for (var i = 0; i < 40; i++) {
          final x0 = r.nextDouble() * s.width;
          final sp = 0.5 + r.nextDouble();
          final y = ((t * 6 * sp + r.nextDouble()) % 1.0) * s.height;
          final x = x0 + sin(t * 40 + i) * 6;
          canvas.drawCircle(Offset(x, y), 1.5 + r.nextDouble() * 2.5, Paint()..color = Colors.white.withOpacity(0.95));
        }
      case 'wind':
        final line = Paint()
          ..color = Colors.white.withOpacity(0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 5; i++) {
          final y = s.height * (0.15 + i * 0.17);
          final off = ((t * 8 + i * 0.23) % 1.0) * (s.width * 1.6) - s.width * 0.5;
          final p = Path()..moveTo(off, y);
          p.cubicTo(off + s.width * 0.15, y - 10, off + s.width * 0.3, y + 10, off + s.width * 0.45, y);
          canvas.drawPath(p, line);
        }
        for (var i = 0; i < 9; i++) {
          final sp = 0.6 + r.nextDouble();
          final x = ((t * 7 * sp + r.nextDouble()) % 1.0) * (s.width + 40) - 20;
          final y = s.height * r.nextDouble() + sin(t * 30 + i) * 12;
          canvas.save();
          canvas.translate(x, y);
          canvas.rotate(t * 60 + i);
          final leaf = Path()
            ..moveTo(0, -6)
            ..quadraticBezierTo(5, 0, 0, 6)
            ..quadraticBezierTo(-5, 0, 0, -6);
          canvas.drawPath(leaf, Paint()..color = (i.isEven ? const Color(0xFF6CC24A) : const Color(0xFFF2B33D)));
          canvas.restore();
        }
      case 'rain':
        final p = Paint()
          ..color = const Color(0xFFBFE3FF).withOpacity(0.8)
          ..strokeWidth = 1.6;
        for (var i = 0; i < 34; i++) {
          final x = r.nextDouble() * s.width;
          final y = ((t * 10 * (0.7 + r.nextDouble() * 0.6) + r.nextDouble()) % 1.0) * s.height;
          canvas.drawLine(Offset(x, y), Offset(x - 2, y + 10), p);
        }
      default:
        final c = Offset(s.width * 0.82, s.height * 0.12);
        final pulse = 0.5 + 0.5 * sin(t * 2 * pi * 4);
        canvas.drawCircle(
          c,
          s.width * (0.22 + 0.03 * pulse),
          Paint()..shader = RadialGradient(colors: [const Color(0xFFFFF3A0).withOpacity(0.85), const Color(0x00FFE066)]).createShader(Rect.fromCircle(center: c, radius: s.width * 0.25)),
        );
    }
  }

  @override
  bool shouldRepaint(_WeatherFx o) => o.t != t || o.kind != kind;
}

// ═══════════════════════════════════════════════════════════════════════════
// 5 · LE LABO DES MATIÈRES — je reconnais · je trie · j'observe
// ═══════════════════════════════════════════════════════════════════════════

const _mats = ['wood', 'metal', 'fabric'];
const Map<String, String> _matOf = {'cube': 'wood', 'wspoon': 'wood', 'spoon': 'metal', 'key': 'metal', 'scarf': 'fabric', 'towel': 'fabric'};

class ScMatterPlay extends M1Play {
  const ScMatterPlay({super.key, required super.lv});
  @override
  State<ScMatterPlay> createState() => _MatterState();
}

class _MatterState extends ScQuizState<ScMatterPlay> {
  String _obj = 'cube', _mat = 'wood';
  List<String> _items = [];

  @override
  List<String> get sortItems => _items;

  @override
  String get instruction => switch (mode) {
        'recognize' => m1T(context, 'mt_q_what'),
        'sort' => m1T(context, 'mt_sort'),
        _ => m1T(context, 'mt_q_which', {'m': m1T(context, 'mt_in_$_mat')}),
      };

  @override
  void newRound() {
    clearQuiz();
    placed.clear();
    selected = null;
    switch (mode) {
      case 'recognize':
        final objs = _matOf.keys.toList();
        _obj = objs[rng.nextInt(objs.length)];
        _mat = _matOf[_obj]!;
        opts = [for (final m in _mats) ScOpt(m, 'sc_lens_$m', 'mt_m_$m')]..shuffle(rng);
        answers = {_mat};
        labels = tier < 2;
        missHelp = 'mt_help_$_mat';
      case 'sort':
        final per = [1, 1, 2][tier];
        _items = [
          for (final m in _mats) ..._some(_matOf.keys.where((o) => _matOf[o] == m).toList(), per, rng),
        ];
        if (tier == 1) _items.add(_some(_matOf.keys.where((o) => !_items.contains(o)).toList(), 1, rng).first);
        _items.shuffle(rng);
        missHelp = 'mt_sort_help';
      default:
        _mat = _mats[rng.nextInt(3)];
        opts = [
          for (final m in _mats)
            () {
              final l = _matOf.keys.where((o) => _matOf[o] == m).toList();
              final o = l[rng.nextInt(l.length)];
              return ScOpt(o, 'sc_m_$o', '');
            }(),
        ]..shuffle(rng);
        answers = {opts.firstWhere((o) => _matOf[o.key] == _mat).key};
        labels = false;
        missHelp = 'mt_help_$_mat';
    }
    missTopic = 'mt_rev';
  }

  @override
  String? rightText(ScOpt o) => mode == 'recognize' ? m1T(context, 'mt_yes_$_mat') : null;

  @override
  void hint() {
    if (mode != 'sort') return super.hint();
    mistakes++;
    final left = _items.where((a) => !placed.containsKey(a)).toList();
    if (left.isNotEmpty) say(m1T(context, 'mt_help_${_matOf[left.first]}'));
  }

  @override
  Widget board(BuildContext context, double w, double h) => switch (mode) {
        'recognize' => quizBoard(w, h, scene: floatPic('sc_m_$_obj'), sceneFlex: 38),
        'sort' => _sortBoard(w, h),
        _ => quizBoard(w, h, scene: floatPic('sc_tex_$_mat'), sceneFlex: 34),
      };

  Widget _sortBoard(double w, double h) {
    final rh = min(h * 0.2, 100.0);
    final binW = (w - 36) / 3;
    final cols = _items.length <= 3 ? _items.length : 3;
    final cell = min((w - 40) / cols - 10, 92.0);
    return Column(children: [
      SizedBox(height: rh, child: robotLine(w, rh, robotH: rh)),
      M1SayPill(text: instruction, width: min(w - 24, 380.0), height: 46),
      const SizedBox(height: 8),
      Stack(children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [for (final m in _mats) _bin(m, binW)]),
        ),
        Positioned.fill(child: burstLayer()),
      ]),
      const Spacer(),
      Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10, children: [
        for (final o in _items)
          placed.containsKey(o) ? SizedBox(width: cell, height: cell) : M1PopIn(key: ValueKey('m$round$o'), child: dragItem(o, 'sc_m_$o', cell)),
      ]),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(color: m1Cream, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE09A4A), width: 2)),
        child: Text(m1T(context, 'mt_placed', {'n': placed.length, 't': _items.length}), style: m1Text(14)),
      ),
      const SizedBox(height: 4),
    ]);
  }

  Widget _bin(String m, double bw) {
    final bh = bw * m1Ratio('sc_bin_$m');
    final inside = [for (final e in placed.entries) if (e.value == m) e.key];
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (d) => drop(d.data, m, (o) => _matOf[o]!, miss: m1T(context, 'mt_rev'), help: m1T(context, 'mt_help_${_matOf[d.data]}')),
      builder: (_, cand, __) => GestureDetector(
        onTap: selected == null ? null : () => drop(selected!, m, (o) => _matOf[o]!, miss: m1T(context, 'mt_rev'), help: m1T(context, 'mt_help_${_matOf[selected!]}')),
        child: M1Shake(
          trigger: targetShake[m] ?? 0,
          child: AnimatedScale(
            scale: cand.isNotEmpty || selected != null ? 1.05 : 1,
            duration: const Duration(milliseconds: 180),
            child: SizedBox(
              width: bw,
              height: bh + 20,
              child: Stack(clipBehavior: Clip.none, children: [
                Positioned(left: 0, right: 0, bottom: 20, height: bh, child: Image.asset(m1('sc_bin_$m'), fit: BoxFit.fill)),
                // objects already in the bin peek out of it
                Positioned(
                  left: bw * 0.12,
                  right: bw * 0.12,
                  top: 0,
                  height: bh * 0.42,
                  child: Wrap(alignment: WrapAlignment.center, children: [
                    for (final o in inside) M1PopIn(from: 0.2, child: Image.asset(m1('sc_m_$o'), width: bw * 0.3, height: bw * 0.3)),
                  ]),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(color: m1Cream, borderRadius: BorderRadius.circular(10), border: Border.all(color: m1Line, width: 1.5)),
                      child: Text(m1T(context, 'mt_m_$m'), style: m1Text(14)),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
