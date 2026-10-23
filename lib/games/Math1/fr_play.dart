import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'm1_kit.dart';
import 'm1_shell.dart';
import 'm1_text.dart';
import 'sc_play.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Français — 1re année primaire. Five games on the shared engine.
// ═══════════════════════════════════════════════════════════════════════════

// ── words with pictures ────────────────────────────────────────────────────

class FrWord {
  final String id, word, sprite, cat, sound, sentence;
  final List<String> syl;
  const FrWord(this.id, this.word, this.sprite, this.cat, this.syl, this.sound, this.sentence);
  String get first => word.substring(0, 1);
}

const List<String> frCats = ['animals', 'school', 'home'];

const List<FrWord> frWords = [
  FrWord('chat', 'chat', 'fr_cat2', 'animals', ['chat'], 'ch', 'Le chat dort.'),
  FrWord('chien', 'chien', 'fr_dog', 'animals', ['chien'], 'ch', 'Le chien joue.'),
  FrWord('lapin', 'lapin', 'fr_rabbit', 'animals', ['la', 'pin'], 'l', 'Le lapin saute.'),
  FrWord('souris', 'souris', 'fr_mouse', 'animals', ['sou', 'ris'], 's', 'La souris mange.'),
  FrWord('canard', 'canard', 'ar_w_duck', 'animals', ['ca', 'nard'], 'c', 'Le canard nage.'),
  FrWord('poisson', 'poisson', 'ar_w_fish', 'animals', ['pois', 'son'], 'p', 'Le poisson nage.'),
  FrWord('papillon', 'papillon', 'fr_bfly_blue', 'animals', ['pa', 'pi', 'llon'], 'p', 'Le papillon vole.'),
  FrWord('oiseau', 'oiseau', 'fr_bird', 'animals', ['oi', 'seau'], '', 'L\'oiseau chante.'),
  FrWord('ecureuil', 'écureuil', 'fr_squirrel', 'animals', ['é', 'cu', 'reuil'], 'é', 'L\'écureuil grimpe.'),
  FrWord('livre', 'livre', 'fr_book_purple', 'school', ['li', 'vre'], 'l', 'Je lis un livre.'),
  FrWord('sac', 'sac', 'fr_bag', 'school', ['sac'], 's', 'Mon sac est lourd.'),
  FrWord('crayon', 'crayon', 'ar_pencil', 'school', ['cra', 'yon'], 'c', 'Je dessine avec un crayon.'),
  FrWord('moto', 'moto', 'fr_moto2', 'school', ['mo', 'to'], 'm', 'La moto roule vite.'),
  FrWord('train', 'train', 'fr_engine', 'school', ['train'], 't', 'Le train arrive.'),
  FrWord('robot', 'robot', 'fr_robot_point', 'school', ['ro', 'bot'], 'r', 'Le robot m\'aide.'),
  FrWord('cartable', 'cartable', 'fr_bag_purple', 'school', ['car', 'ta', 'ble'], 'c', 'Mon cartable est violet.'),
  FrWord('maison', 'maison', 'ar_w_house', 'home', ['mai', 'son'], 'm', 'J\'aime ma maison.'),
  FrWord('arbre', 'arbre', 'ar_tree_green', 'home', ['ar', 'bre'], 'a', 'L\'arbre est grand.'),
  FrWord('fleur', 'fleur', 'fr_flowers2', 'home', ['fleur'], 'f', 'La fleur sent bon.'),
  FrWord('plante', 'plante', 'fr_plant', 'home', ['plan', 'te'], 'p', 'La plante pousse.'),
  FrWord('etoile', 'étoile', 'ar_star', 'home', ['é', 'toi', 'le'], 'é', 'L\'étoile brille.'),
  FrWord('champignon', 'champignon', 'fr_mushroom', 'home', ['cham', 'pi', 'gnon'], 'ch', 'Le champignon est rouge.'),
];

FrWord frWord(String id) => frWords.firstWhere((w) => w.id == id);

/// Article + word, read aloud ("le chat", "l'arbre").
String frSay(FrWord w) {
  final s = w.sentence.toLowerCase();
  final i = s.indexOf(w.word);
  if (i <= 0) return w.word;
  final before = s.substring(0, i).trim().split(' ');
  final art = before.isEmpty ? '' : before.last;
  return art.endsWith('\'') ? '$art${w.word}' : '$art ${w.word}';
}

/// Words the child already met (shown in the picture book "Mon imagier").
class FrStore {
  static const _k = 'fr_learned';
  static Future<Set<String>> learned() async => ((await SharedPreferences.getInstance()).getStringList(_k) ?? const []).toSet();
  static Future<void> learn(String id) async {
    final p = await SharedPreferences.getInstance();
    final l = (p.getStringList(_k) ?? <String>[]).toSet()..add(id);
    await p.setStringList(_k, l.toList());
  }
}

// ── letters, syllables, sentences ──────────────────────────────────────────

const List<List<String>> frLetterGroups = [
  ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'],
  ['I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q'],
  ['R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
];

/// Lowercase letters children mix up.
const List<List<String>> _twins = [
  ['b', 'd', 'p', 'q'], ['m', 'n', 'u'], ['a', 'o', 'e'], ['i', 'l', 'j'], ['f', 't', 'l'], ['c', 'e', 'o'], ['v', 'w', 'y'], ['h', 'n', 'k'], ['r', 'n', 'v'], ['s', 'z', 'x'], ['g', 'q', 'y'],
];

const List<String> frVowels = ['a', 'i', 'o', 'u', 'é'];
const List<List<String>> frConsonants = [
  ['m', 'l', 'r'],
  ['p', 't', 's', 'n'],
  ['b', 'd', 'f', 'v', 'ch'],
];

class FrSentence {
  final List<String> words;
  final String sprite;
  const FrSentence(this.words, this.sprite);
  String get text => words.join(' ');
}

const List<FrSentence> frSentences3 = [
  FrSentence(['Le', 'chat', 'dort.'], 'fr_cat_sleep'),
  FrSentence(['Le', 'chien', 'joue.'], 'fr_dog'),
  FrSentence(['Le', 'lapin', 'saute.'], 'fr_rabbit'),
  FrSentence(['La', 'souris', 'mange.'], 'fr_mouse'),
  FrSentence(['Le', 'papillon', 'vole.'], 'fr_bfly_orange'),
  FrSentence(['Le', 'robot', 'danse.'], 'fr_robot_cheer'),
];

const List<FrSentence> frSentences4 = [
  FrSentence(['La', 'moto', 'est', 'bleue.'], 'fr_moto2'),
  FrSentence(['Le', 'petit', 'chat', 'joue.'], 'fr_cat_small'),
  FrSentence(['Mon', 'sac', 'est', 'bleu.'], 'fr_bag'),
  FrSentence(['Le', 'garçon', 'lit', 'un', 'livre.'], 'fr_kid_read'),
  FrSentence(['Le', 'train', 'roule', 'très', 'vite.'], 'fr_engine'),
  FrSentence(['Le', 'garçon', 'saute', 'de', 'joie.'], 'fr_kid_jump'),
];

// ═══════════════════════════════════════════════════════════════════════════
// Shared base: a speaker the child taps first, French text faces.
// ═══════════════════════════════════════════════════════════════════════════

abstract class FrQuizState<W extends M1Play> extends ScQuizState<W> {
  bool heard = false;
  final GlobalKey speakerKey = GlobalKey();

  /// What the speaker says.
  String get voice;

  /// Modes where the child must listen before the answers appear.
  bool get needsListen => false;

  @override
  bool get optionsReady => !needsListen || heard;

  @override
  String get waitText => m1T(context, 'fr_wait_listen');

  void listen() {
    M1Voice.say(context, voice);
    if (!heard) setState(() => heard = true);
  }

  @override
  void idleHelp() {
    if (needsListen && !heard) {
      say(m1T(context, 'fr_tap_speaker'));
      showTap(speakerKey);
      return;
    }
    if (dragToScene) {
      say(missHelp == null ? instruction : m1T(context, missHelp!));
      demoDragAnswer();
      return;
    }
    super.idleHelp();
  }

  /// Big teal speaker with sound waves (pulses until it was tapped).
  Widget speaker({double? width}) => LayoutBuilder(builder: (_, c) {
        final h = min(c.maxHeight, (width ?? c.maxWidth) / 1.9);
        return M1Press(
          key: speakerKey,
          onTap: listen,
          sound: '',
          child: AnimatedBuilder(
            animation: pulse,
            builder: (_, ch) => Transform.scale(scale: heard ? 1 : 1 + 0.07 * sin(pulse.value * 2 * pi * 3), child: ch),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Image.asset(m1('fr_spk_teal'), height: h, fit: BoxFit.contain),
              SizedBox(width: h * 0.08),
              AnimatedBuilder(
                animation: pulse,
                builder: (_, ch) => Opacity(opacity: (0.55 + 0.45 * sin(pulse.value * 2 * pi * 4).abs()).clamp(0.0, 1.0), child: ch),
                child: Image.asset(m1('fr_waves'), height: h * 0.8, fit: BoxFit.contain),
              ),
            ]),
          ),
        );
      });

  /// A picture with a small speaker under it.
  Widget picWithSpeaker(String sprite) => Column(children: [
        Expanded(child: floatPic(sprite)),
        const SizedBox(height: 4),
        SizedBox(height: 50, child: Center(child: speaker())),
      ]);

  /// A big French text on a cream card.
  Widget bigText(String t, {Color color = m1Ink, double size = 90}) => M1Card(
        radius: 26,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        child: FittedBox(fit: BoxFit.scaleDown, child: Text(t, textDirection: TextDirection.ltr, style: m1Text(size, color: color, height: 1.2))),
      );

  @override
  Widget optFace(ScOpt o, double th) {
    if (!o.sprite.startsWith('T:')) return super.optFace(o, th);
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: th * 0.08),
          child: Text(o.sprite.substring(2), textDirection: TextDirection.ltr, style: m1Text(th * 0.4, color: textColor(o), height: 1.15)),
        ),
      ),
    );
  }

  @override
  void newRound() {
    heard = false;
  }
}

Color frLetterColor(String l) => m1DigitColor('abcdefghijklmnopqrstuvwxyz'.indexOf(l.toLowerCase()).clamp(0, 25));

// ═══════════════════════════════════════════════════════════════════════════
// 1 · La forêt des lettres — je reconnais · majuscule/minuscule · le début du mot
// ═══════════════════════════════════════════════════════════════════════════

class FrLettersPlay extends M1Play {
  const FrLettersPlay({super.key, required super.lv});
  @override
  State<FrLettersPlay> createState() => _LettersState();
}

class _LettersState extends FrQuizState<FrLettersPlay> {
  String _l = 'A';
  late FrWord _w;

  List<String> get _group => frLetterGroups[tier];

  @override
  String get voice => switch (mode) {
        'first' => frSay(_w),
        _ => m1T(context, 'fl_letter', {'l': _l}),
      };

  @override
  bool get needsListen => mode == 'recognize';

  @override
  String get instruction => switch (mode) {
        'recognize' => m1T(context, 'fl_q_find'),
        'case' => m1T(context, 'fl_q_case', {'l': _l}),
        _ => m1T(context, 'fl_q_first'),
      };

  @override
  Color textColor(ScOpt o) => frLetterColor(o.key);

  @override
  void newRound() {
    super.newRound();
    clearQuiz();
    labels = false;
    switch (mode) {
      case 'recognize':
        _l = _group[rng.nextInt(_group.length)];
        final n = [3, 4, 4][lv.range];
        final others = (List.of(_group)..remove(_l)..shuffle(rng)).take(n - 1);
        opts = [for (final x in [_l, ...others]) ScOpt(x, 'T:$x', '')]..shuffle(rng);
        answers = {_l};
        missTopic = 'fl_rev_name';
        missHelp = 'fl_help_listen';
      case 'case':
        _l = _group[rng.nextInt(_group.length)];
        final low = _l.toLowerCase();
        final fam = _twins.where((f) => f.contains(low)).toList();
        final pool = <String>{
          if (lv.range > 0 && fam.isNotEmpty) ...fam[rng.nextInt(fam.length)],
          ...(_group.map((x) => x.toLowerCase()).toList()..shuffle(rng)),
        }..remove(low);
        final others = pool.take(lv.range == 0 ? 2 : 3);
        opts = [for (final x in [low, ...others]) ScOpt(x, 'T:$x', '')]..shuffle(rng);
        answers = {low};
        missTopic = 'fl_rev_case';
        missHelp = 'fl_help_case';
      default:
        final pool = frWords.where((w) => w.first != 'é').toList();
        _w = pool[rng.nextInt(pool.length)];
        _l = _w.first.toUpperCase();
        const abc = 'abcdefghijlmnoprstuv';
        final others = (abc.split('')..remove(_w.first)..shuffle(rng)).take(lv.range == 0 ? 2 : 3);
        opts = [for (final x in [_w.first, ...others]) ScOpt(x, 'T:${x.toUpperCase()} $x', '')]..shuffle(rng);
        answers = {_w.first};
        missTopic = 'fl_rev_first';
        missHelp = 'fl_help_first';
    }
  }

  @override
  String? rightText(ScOpt o) => switch (mode) {
        'first' => m1T(context, 'fl_yes_first', {'w': _w.word, 'l': _l}),
        'case' => m1T(context, 'fl_yes_case', {'l': _l}),
        _ => m1T(context, 'fl_yes', {'l': _l}),
      };

  @override
  Future<void> explain() async {
    setState(() => showWhy = true);
    if (mode == 'first') {
      FrStore.learn(_w.id);
      M1Voice.say(context, '${_w.word}. $_l');
    } else {
      M1Voice.say(context, m1T(context, 'fl_letter', {'l': _l}));
    }
    await Future.delayed(const Duration(milliseconds: 1600));
    if (mounted) setState(() => showWhy = false);
  }

  /// The letter as a big shiny 3D letter card.
  Widget _letterCard(String t) => M1Card(
        radius: 28,
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 4),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: m1Outlined(t, 110, color: frLetterColor(t), outline: Colors.white, stroke: 0.14, height: 1.1),
        ),
      );

  @override
  Widget board(BuildContext context, double w, double h) => switch (mode) {
        'recognize' => quizBoard(w, h, scene: Center(child: speaker(width: min(w * 0.55, 220.0))), sceneFlex: 22),
        'case' => quizBoard(w, h, scene: _letterCard(_l), sceneFlex: 30),
        _ => quizBoard(w, h, scene: picWithSpeaker(_w.sprite), sceneFlex: 42),
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// 2 · Le détective des sons — j'écoute · le premier son · même son
// ═══════════════════════════════════════════════════════════════════════════

class FrSoundsPlay extends M1Play {
  const FrSoundsPlay({super.key, required super.lv});
  @override
  State<FrSoundsPlay> createState() => _SoundsState();
}

class _SoundsState extends FrQuizState<FrSoundsPlay> {
  late FrWord _w;
  String _s = 'ch';

  static const _sounds = ['ch', 'm', 'l', 's', 'p', 'c', 'é'];

  List<FrWord> get _pool => switch (lv.range) {
        0 => frWords.where((w) => w.cat == 'animals').toList(),
        1 => frWords.where((w) => w.cat != 'animals').toList(),
        _ => frWords,
      };

  FrWord get _example => frWords.firstWhere((w) => w.sound == _s);

  @override
  String get voice => mode == 'same' ? m1T(context, 'fs_same_v', {'w': _example.word}) : frSay(_w);

  @override
  bool get needsListen => mode != 'same';

  @override
  String get instruction => switch (mode) {
        'listen' => m1T(context, 'fs_q_listen'),
        'first' => m1T(context, 'fs_q_first'),
        _ => m1T(context, 'fs_q_same', {'s': _s, 'w': _example.word}),
      };

  @override
  Color textColor(ScOpt o) => frLetterColor(o.key.substring(0, 1));

  @override
  void newRound() {
    super.newRound();
    clearQuiz();
    labels = false;
    switch (mode) {
      case 'listen':
        final pool = _pool;
        _w = pool[rng.nextInt(pool.length)];
        final others = (frWords.where((x) => x.id != _w.id).toList()..shuffle(rng)).take(lv.range == 0 ? 2 : 3);
        opts = [for (final x in [_w, ...others]) ScOpt(x.id, x.sprite, '')]..shuffle(rng);
        answers = {_w.id};
        missTopic = 'fs_rev_listen';
        missHelp = 'fs_help_listen';
      case 'first':
        final pool = _pool.where((w) => w.sound.isNotEmpty).toList();
        _w = pool[rng.nextInt(pool.length)];
        final others = (List.of(_sounds)..remove(_w.sound)..shuffle(rng)).take(lv.range == 0 ? 2 : 3);
        opts = [for (final x in [_w.sound, ...others]) ScOpt(x, 'T:$x', '')]..shuffle(rng);
        answers = {_w.sound};
        missTopic = 'fs_rev_first';
        missHelp = 'fs_help_first';
      default:
        _s = _sounds[rng.nextInt(_sounds.length)];
        final mine = (frWords.where((x) => x.sound == _s).toList()..shuffle(rng)).take(3).toList();
        final others = (frWords.where((x) => x.sound != _s && x.sound.isNotEmpty).toList()..shuffle(rng)).take([2, 3, 4][lv.range]);
        opts = [for (final x in [...mine, ...others]) ScOpt(x.id, x.sprite, '')]..shuffle(rng);
        answers = {for (final x in mine) x.id};
        multi = true;
        missTopic = 'fs_rev_same';
        missHelp = 'fs_help_same';
    }
  }

  @override
  String? rightText(ScOpt o) {
    if (mode != 'same') FrStore.learn(_w.id);
    return mode == 'first' ? m1T(context, 'fs_yes_first', {'w': _w.word, 's': _w.sound}) : null;
  }

  @override
  Future<void> explain() async {
    if (mode == 'same') {
      final ids = [for (final o in opts) if (answers.contains(o.key)) o.key];
      for (final i in ids) {
        FrStore.learn(i);
      }
      countKeys = ids;
      await countAlong(ids.length, word: (k) => frWord(ids[k]).word, ms: 1100);
      countKeys = [];
      return;
    }
    setState(() => showWhy = true);
    M1Voice.say(context, frSay(_w));
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => showWhy = false);
  }

  /// The detective with his magnifier, and the sound to look for.
  Widget _soundCard() => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Flexible(child: M1Float(child: Image.asset(m1('fr_detective'), fit: BoxFit.contain))),
        const SizedBox(width: 8),
        GestureDetector(onTap: listen, child: bigText(_s, color: frLetterColor(_s), size: 80)),
      ]);

  @override
  Widget board(BuildContext context, double w, double h) => switch (mode) {
        'listen' => quizBoard(w, h, scene: Center(child: speaker(width: min(w * 0.55, 220.0))), sceneFlex: 22),
        'first' => quizBoard(w, h, scene: Row(children: [
              Expanded(child: Image.asset(m1('fr_ear'), fit: BoxFit.contain)),
              Expanded(flex: 2, child: Center(child: speaker())),
            ]), sceneFlex: 24),
        _ => quizBoard(w, h, scene: _soundCard(), sceneFlex: 26),
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// 3 · Le train des syllabes — j'écoute · j'assemble · je lis
// ═══════════════════════════════════════════════════════════════════════════

class FrSyllablesPlay extends M1Play {
  const FrSyllablesPlay({super.key, required super.lv});
  @override
  State<FrSyllablesPlay> createState() => _SyllablesState();
}

class _SyllablesState extends FrQuizState<FrSyllablesPlay> {
  String _c = 'm', _v = 'a';
  late FrWord _w;
  String get _syl => '$_c$_v';

  @override
  String get voice => mode == 'read' ? frSay(_w) : _syl;

  @override
  bool get needsListen => mode == 'listen';

  @override
  bool get dragToScene => mode == 'build';

  @override
  String get instruction => switch (mode) {
        'listen' => m1T(context, 'fy_q_listen'),
        'build' => m1T(context, 'fy_q_build', {'s': _syl}),
        _ => m1T(context, 'fy_q_read'),
      };

  @override
  Color textColor(ScOpt o) => mode == 'build' ? frLetterColor(o.key) : m1Ink;

  @override
  void newRound() {
    super.newRound();
    clearQuiz();
    labels = false;
    final cs = frConsonants[lv.range];
    _c = cs[rng.nextInt(cs.length)];
    _v = frVowels[rng.nextInt(frVowels.length)];
    switch (mode) {
      case 'listen':
        final vs = (List.of(frVowels)..remove(_v)..shuffle(rng)).take(2);
        final alt = (List.of(cs)..remove(_c));
        opts = [
          ScOpt(_syl, 'T:$_syl', ''),
          for (final v in vs) ScOpt('$_c$v', 'T:$_c$v', ''),
          if (lv.range > 0 && alt.isNotEmpty) ScOpt('${alt.first}$_v', 'T:${alt.first}$_v', ''),
        ]..shuffle(rng);
        answers = {_syl};
        missTopic = 'fy_rev_listen';
        missHelp = 'fy_help_listen';
      case 'build':
        final vs = (List.of(frVowels)..remove(_v)..shuffle(rng)).take(lv.range == 0 ? 2 : 3);
        opts = [for (final v in [_v, ...vs]) ScOpt(v, 'T:$v', '')]..shuffle(rng);
        answers = {_v};
        missTopic = 'fy_rev_build';
        missHelp = 'fy_help_build';
      default:
        final n = [2, 2, 3][lv.range];
        final pool = frWords.where((w) => lv.range == 2 ? w.syl.length >= 3 : w.syl.length == n).toList();
        _w = pool[rng.nextInt(pool.length)];
        final others = (frWords.where((x) => x.id != _w.id).toList()..shuffle(rng)).take(2);
        opts = [for (final x in [_w, ...others]) ScOpt(x.id, x.sprite, '')]..shuffle(rng);
        answers = {_w.id};
        missTopic = 'fy_rev_read';
        missHelp = 'fy_help_read';
    }
  }

  @override
  String? rightText(ScOpt o) => switch (mode) {
        'read' => frSay(_w),
        'build' => m1T(context, 'fy_yes_build', {'c': _c, 'v': _v, 's': _syl}),
        _ => _syl,
      };

  @override
  Future<void> explain() async {
    if (mode == 'read') {
      FrStore.learn(_w.id);
      countKeys = [];
      await countAlong(_w.syl.length, word: (k) => _w.syl[k], ms: 750);
      if (!mounted) return;
      M1Voice.say(context, _w.word);
      await Future.delayed(const Duration(milliseconds: 1000));
      return;
    }
    setState(() => showWhy = true);
    M1Voice.say(context, '$_c... $_v... $_syl !');
    await Future.delayed(const Duration(milliseconds: 1700));
    if (mounted) setState(() => showWhy = false);
  }

  /// One wagon with a text on its label.
  Widget _wagon(String sprite, String text, double w, {bool lit = false, Color? color}) {
    final h = w * m1Ratio(sprite);
    return SizedBox(
      width: w,
      height: h,
      child: Stack(children: [
        Positioned.fill(child: Image.asset(m1(sprite), fit: BoxFit.contain)),
        Positioned(
          left: w * 0.12,
          width: w * 0.76,
          top: h * 0.17,
          height: h * 0.34,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              boxShadow: [if (lit) BoxShadow(color: const Color(0xFFFFD54A).withOpacity(0.9), blurRadius: 14, spreadRadius: 2)],
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (ch, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.elasticOut), child: ch),
                  child: Text(text.isEmpty ? '?' : text,
                      key: ValueKey(text),
                      style: m1Text(h * 0.3, color: text.isEmpty ? const Color(0xFFC4B8A6) : (color ?? m1Ink), weight: FontWeight.w800)),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  /// Engine + wagons, sized to the space.
  Widget _train(List<String> texts, {List<Color?>? colors}) => LayoutBuilder(builder: (_, c) {
        final n = texts.length;
        final eng = m1Ratio('fr_engine');
        // engine width e, wagon width ww ≈ 0.95 e; height of the whole train = e * eng
        var e = c.maxWidth / (1 + n * 0.95);
        e = min(e, c.maxHeight / eng);
        final ww = e * 0.95;
        return Center(
          child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (var i = 0; i < n; i++)
              M1Spot(
                on: countIdx == i,
                hand: countIdx == i,
                size: ww * 0.6,
                child: _wagon(i.isEven ? 'fr_wagon_teal' : 'fr_wagon_orange', texts[i], ww, lit: countIdx == i, color: colors?[i]),
              ),
            M1Float(amp: 2, child: Image.asset(m1('fr_engine'), width: e, fit: BoxFit.contain)),
          ]),
        );
      });

  @override
  Widget board(BuildContext context, double w, double h) => switch (mode) {
        'listen' => quizBoard(w, h,
            scene: Column(children: [
              Expanded(child: Center(child: speaker(width: min(w * 0.5, 200.0)))),
              Expanded(child: _train([heard && busy ? _syl : ''])),
            ]),
            sceneFlex: 36),
        'build' => quizBoard(w, h,
            scene: _train([_c, (busy ? _v : '')], colors: [frLetterColor(_c), frLetterColor(_v)]),
            sceneFlex: 34),
        _ => quizBoard(w, h, scene: GestureDetector(onTap: listen, child: _train(_w.syl)), sceneFlex: 30),
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// 4 · Les mots en images — je place · je lis · j'écoute
// ═══════════════════════════════════════════════════════════════════════════

class FrWordsPlay extends M1Play {
  const FrWordsPlay({super.key, required super.lv});
  @override
  State<FrWordsPlay> createState() => _WordsState();
}

class _WordsState extends FrQuizState<FrWordsPlay> {
  late FrWord _w;
  List<FrWord> _three = [];
  List<FrWord> _pills = [];
  final Map<String, String> _put = {}; // card id → word id placed under it
  final Map<String, int> _cardShake = {};
  final Map<String, GlobalKey> _cardKeys = {};
  final Map<String, GlobalKey> _pillKeys = {};
  String? _sel;

  @override
  int get rounds => mode == 'match' ? 3 : 5;

  @override
  String get voice => frSay(_w);

  @override
  bool get needsListen => mode == 'listen';

  @override
  String get instruction => switch (mode) {
        'match' => m1T(context, 'fw_q_match'),
        'read' => m1T(context, 'fw_q_read'),
        _ => m1T(context, 'fw_q_listen'),
      };

  @override
  int? get optCols => mode == 'read' ? null : 1;

  @override
  void newRound() {
    super.newRound();
    clearQuiz();
    labels = false;
    _put.clear();
    _cardShake.clear();
    _sel = null;
    final pool = frWords.where((x) => x.cat == frCats[lv.range]).toList()..shuffle(rng);
    _three = pool.take(3).toList();
    _w = _three[rng.nextInt(3)];
    _pills = List.of(_three)..shuffle(rng);
    if (mode != 'match') {
      opts = [for (final x in _three) mode == 'read' ? ScOpt(x.id, x.sprite, '') : ScOpt(x.id, 'T:${x.word}', '')];
      answers = {_w.id};
    }
    missTopic = 'fw_rev';
    missHelp = mode == 'match' ? 'fw_help_match' : 'fw_help';
  }

  @override
  String? rightText(ScOpt o) {
    FrStore.learn(_w.id);
    return frSay(_w);
  }

  @override
  Future<void> explain() async {
    if (mode == 'match') {
      final ids = [for (final x in _three) x.id];
      for (final i in ids) {
        FrStore.learn(i);
      }
      await countAlong(3, word: (k) => frSay(frWord(ids[k])), ms: 1000);
      return;
    }
    setState(() => showWhy = true);
    M1Voice.say(context, frWord(_w.id).sentence);
    await Future.delayed(const Duration(milliseconds: 1900));
    if (mounted) setState(() => showWhy = false);
  }

  // ── match mode: words go under their pictures ──
  void _place(String word, String card) {
    if (busy || _put.containsKey(card) || _put.containsValue(word)) return;
    if (word == card) {
      setState(() {
        _put[card] = word;
        _sel = null;
      });
      m1Sound(context, 'PopButton');
      M1Voice.say(context, frSay(frWord(word)));
      if (_put.length == 3) good(text: m1T(context, 'fw_all'));
    } else {
      setState(() {
        _sel = null;
        _cardShake[card] = (_cardShake[card] ?? 0) + 1;
      });
      bad(m1T(context, 'fw_rev'), help: m1T(context, 'fw_help_match'));
    }
  }

  @override
  void idleHelp() {
    if (mode != 'match') return super.idleHelp();
    final left = _pills.where((p) => !_put.containsValue(p.id)).toList();
    if (left.isEmpty) return;
    final p = left.first;
    say(m1T(context, 'fw_help_match'));
    final from = _pillKeys[p.id], to = _cardKeys[p.id];
    if (from != null && to != null) showDrag(from, to, '', ghost: _pill(p, 120, 46));
  }

  @override
  void hint() {
    if (mode != 'match') return super.hint();
    mistakes++;
    idleHelp();
  }

  Widget _pill(FrWord x, double w, double h, {bool selected = false}) => Container(
        width: w,
        height: h,
        padding: EdgeInsets.only(left: h * 0.3, right: h * 0.12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF0),
          borderRadius: BorderRadius.circular(h * 0.3),
          border: Border.all(color: selected ? const Color(0xFF39B8F2) : const Color(0xFFE8D7B5), width: selected ? 3 : 2),
          boxShadow: [BoxShadow(color: const Color(0xFFB98B4A).withOpacity(0.45), offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(x.word, style: m1Text(h * 0.5, color: const Color(0xFF1C2FB8), weight: FontWeight.w800)))),
          GestureDetector(
            onTap: () => M1Voice.say(context, frSay(x)),
            child: Image.asset(m1('fr_btn_sound_p'), height: h * 0.72),
          ),
        ]),
      );

  Widget _matchBoard(double w, double h) {
    final rh = min(h * 0.16, 90.0);
    final cw = (w - 40) / 3;
    final cardH = min(h * 0.44, cw * 1.5);
    final ph = min(52.0, h * 0.085);
    final pw = (w - 40) / 3;
    return Column(children: [
      SizedBox(height: rh, child: robotLine(w, rh, sprite: 'fr_robot_point', robotH: rh)),
      M1SayPill(text: instruction, width: min(w - 24, 380.0), height: 46),
      const SizedBox(height: 8),
      Stack(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (final x in _three)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: M1Shake(
                trigger: _cardShake[x.id] ?? 0,
                child: DragTarget<String>(
                  key: _cardKeys.putIfAbsent(x.id, () => GlobalKey()),
                  onWillAcceptWithDetails: (_) => !busy && !_put.containsKey(x.id),
                  onAcceptWithDetails: (d) => _place(d.data, x.id),
                  builder: (_, cand, __) => GestureDetector(
                    onTap: _sel == null ? () => M1Voice.say(context, m1T(context, 'fw_what')) : () => _place(_sel!, x.id),
                    child: M1Spot(
                      on: countIdx != null && _three.indexOf(x) == countIdx,
                      hand: countIdx != null && _three.indexOf(x) == countIdx,
                      size: cw * 0.7,
                      child: _picCard(x, cw, cardH, lit: cand.isNotEmpty),
                    ),
                  ),
                ),
              ),
            ),
        ]),
        Positioned.fill(child: burstLayer()),
      ]),
      const Spacer(),
      // wooden shelf with the words
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB9783F), Color(0xFF8A5229)]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF6E3E1C), width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          for (final x in _pills)
            _put.containsValue(x.id)
                ? SizedBox(width: pw - 8, height: ph)
                : M1PopIn(
                    key: ValueKey('p$round${x.id}'),
                    delay: 120 * _pills.indexOf(x),
                    child: Draggable<String>(
                      key: _pillKeys.putIfAbsent(x.id, () => GlobalKey()),
                      data: x.id,
                      maxSimultaneousDrags: busy ? 0 : 1,
                      feedback: Material(type: MaterialType.transparency, child: _pill(x, pw - 8, ph, selected: true)),
                      childWhenDragging: Opacity(opacity: 0.3, child: _pill(x, pw - 8, ph)),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _sel = _sel == x.id ? null : x.id);
                          M1Voice.say(context, frSay(x));
                        },
                        child: _pill(x, pw - 8, ph, selected: _sel == x.id),
                      ),
                    ),
                  ),
        ]),
      ),
      const SizedBox(height: 8),
      // progress pill "0 / 3 mots placés"
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(color: m1Cream, borderRadius: BorderRadius.circular(20), border: Border.all(color: m1Purple, width: 2)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(m1T(context, 'fw_placed', {'n': _put.length}), style: m1Text(15)),
          const SizedBox(width: 10),
          for (var i = 0; i < 3; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 16,
              height: 16,
              decoration: BoxDecoration(shape: BoxShape.circle, color: i < _put.length ? m1Green : const Color(0xFFD6D2DA)),
            ),
        ]),
      ),
      const SizedBox(height: 4),
    ]);
  }

  /// Picture card with a dashed slot under it (like on the mockup).
  Widget _picCard(FrWord x, double w, double h, {bool lit = false}) {
    final done = _put[x.id];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: w,
      height: h,
      padding: EdgeInsets.all(w * 0.06),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(w * 0.12),
        border: Border.all(color: lit ? const Color(0xFF39B8F2) : const Color(0xFFEBD9B4), width: lit ? 3 : 2),
        boxShadow: [BoxShadow(color: const Color(0xFFB98B4A).withOpacity(0.35), offset: const Offset(0, 4), blurRadius: 4)],
      ),
      child: Column(children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(w * 0.08),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFBFE6FF), Color(0xFFE9F7D9), Color(0xFF9ED36A)], stops: [0, 0.6, 1]),
              ),
              child: Padding(padding: EdgeInsets.all(w * 0.06), child: M1Float(amp: 2, child: Image.asset(m1(x.sprite), fit: BoxFit.contain))),
            ),
          ),
        ),
        SizedBox(height: w * 0.05),
        SizedBox(
          height: h * 0.2,
          child: done != null
              ? M1PopIn(from: 0.5, child: Center(child: FittedBox(child: Text(frWord(done).word, style: m1Text(30, color: const Color(0xFF1C2FB8), weight: FontWeight.w800)))))
              : CustomPaint(painter: _DashPainter(), child: const SizedBox.expand()),
        ),
      ]),
    );
  }

  @override
  Widget board(BuildContext context, double w, double h) => switch (mode) {
        'match' => _matchBoard(w, h),
        'read' => quizBoard(w, h, scene: GestureDetector(onTap: listen, child: bigText(_w.word, size: 64, color: const Color(0xFF1C2FB8))), sceneFlex: 24),
        _ => quizBoard(w, h, scene: Center(child: speaker(width: min(w * 0.55, 220.0))), sceneFlex: 22),
      };
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = const Color(0xFFE0A050)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(10)));
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 12) {
        canvas.drawPath(m.extractPath(d, d + 6), p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
// 5 · Ma première phrase — j'écoute · je mets en ordre · je comprends
// ═══════════════════════════════════════════════════════════════════════════

class FrSentencesPlay extends M1Play {
  const FrSentencesPlay({super.key, required super.lv});
  @override
  State<FrSentencesPlay> createState() => _SentencesState();
}

class _SentencesState extends FrQuizState<FrSentencesPlay> {
  late FrSentence _s;
  List<int> _cards = [];
  final List<int> _placed = [];
  final Map<int, int> _cardShake = {};
  final Map<int, GlobalKey> _cardKeys = {};
  final List<GlobalKey> _slotKeys = List.generate(6, (_) => GlobalKey());

  static const _tileColors = [Color(0xFFFFC2DA), Color(0xFFB8DEFF), Color(0xFFFFE680), Color(0xFFC9F2B9), Color(0xFFE2CCFF)];

  List<FrSentence> get _pool => switch (lv.range) {
        0 => frSentences3,
        1 => frSentences4,
        _ => [...frSentences3, ...frSentences4],
      };

  @override
  String get voice => _s.text;

  @override
  bool get needsListen => mode == 'listen';

  @override
  String get instruction => switch (mode) {
        'listen' => m1T(context, 'fp_q_listen'),
        'order' => m1T(context, 'fp_q_order'),
        _ => m1T(context, 'fp_q_understand'),
      };

  @override
  int? get optCols => 1;

  @override
  void newRound() {
    super.newRound();
    clearQuiz();
    _placed.clear();
    _cardShake.clear();
    final pool = _pool;
    _s = pool[rng.nextInt(pool.length)];
    final n = _s.words.length;
    do {
      _cards = List.generate(n, (i) => i)..shuffle(rng);
    } while (n > 1 && _cards.join() == List.generate(n, (i) => i).join());
    if (mode == 'understand') {
      final others = (pool.where((x) => x != _s).toList()..shuffle(rng)).take(2);
      opts = [for (final x in [_s, ...others]) ScOpt(x.text, 'T:${x.text}', '')]..shuffle(rng);
      answers = {_s.text};
      labels = false;
      missTopic = 'fp_rev_understand';
      missHelp = 'fp_help_understand';
    }
  }

  void _put(int i) {
    if (busy || _placed.contains(i)) return;
    if (needsListen && !heard) {
      say(m1T(context, 'fr_tap_speaker'));
      showTap(speakerKey);
      return;
    }
    if (i == _placed.length) {
      setState(() => _placed.add(i));
      m1Sound(context, 'PopButton');
      M1Voice.say(context, _s.words[i]);
      if (_placed.length == _s.words.length) good(text: _s.text);
    } else {
      setState(() => _cardShake[i] = (_cardShake[i] ?? 0) + 1);
      bad(m1T(context, 'fp_rev_order'), help: _placed.isEmpty ? m1T(context, 'fp_help_first') : m1T(context, 'fp_help_next'));
    }
  }

  Widget _wordCard(int i, {double h = 64}) => Container(
        height: h,
        padding: EdgeInsets.symmetric(horizontal: h * 0.2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _tileColors[i % _tileColors.length],
          borderRadius: BorderRadius.circular(h * 0.25),
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), offset: const Offset(0, 4), blurRadius: 3)],
        ),
        child: FittedBox(fit: BoxFit.scaleDown, child: Text(_s.words[i], style: m1Text(h * 0.46, color: const Color(0xFF231147), weight: FontWeight.w800))),
      );

  @override
  void idleHelp() {
    if (mode == 'understand') return super.idleHelp();
    if (needsListen && !heard) return super.idleHelp();
    final next = _placed.length;
    if (next >= _s.words.length) return;
    say(next == 0 ? m1T(context, 'fp_help_first') : m1T(context, 'fp_help_next'));
    final k = _cardKeys[next];
    if (k != null) showDrag(k, _slotKeys[next], '', ghost: _wordCard(next, h: 54));
  }

  @override
  void hint() {
    if (mode == 'understand') return super.hint();
    mistakes++;
    idleHelp();
  }

  @override
  Future<void> explain() async {
    if (mode == 'understand') return super.explain();
    await countAlong(_s.words.length, word: (k) => _s.words[k], ms: 650);
    if (!mounted) return;
    M1Voice.say(context, _s.text);
    await Future.delayed(const Duration(milliseconds: 1800));
  }

  @override
  Widget board(BuildContext context, double w, double h) {
    if (mode == 'understand') return quizBoard(w, h, scene: floatPic(_s.sprite), sceneFlex: 44);
    final rh = min(h * 0.16, 90.0);
    final n = _s.words.length;
    final slotW = (w - 40 - 6.0 * (n - 1)) / n;
    final cardH = min(58.0, h * 0.09);
    return Column(children: [
      SizedBox(height: rh, child: robotLine(w, rh, sprite: 'fr_robot_right', robotH: rh)),
      // the picture card, the slots under it (like the mockup)
      Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF2D49B), width: 2.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: FittedBox(fit: BoxFit.scaleDown, child: Text(instruction, style: m1Text(18))),
            ),
            Expanded(
              child: Stack(children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFE9C9), Color(0xFFF6D3A0)]),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: M1PopIn(key: ValueKey('pic$round'), child: M1Float(amp: 3, child: Image.asset(m1(_s.sprite), fit: BoxFit.contain))),
                      ),
                    ),
                  ),
                ),
                if (mode == 'listen')
                  Positioned(left: 4, top: 4, height: 54, child: speaker()),
              ]),
            ),
            const SizedBox(height: 8),
            Stack(children: [
              DragTarget<int>(
                onWillAcceptWithDetails: (_) => !busy,
                onAcceptWithDetails: (d) => _put(d.data),
                builder: (_, cand, __) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (var k = 0; k < n; k++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: k == _placed.length ? m1Orange : m1Purple),
                          child: Text('${k + 1}', style: m1Text(13, color: Colors.white)),
                        ),
                        const SizedBox(height: 3),
                        SizedBox(
                          key: _slotKeys[k],
                          width: slotW,
                          height: cardH,
                          child: k < _placed.length
                              ? M1PopIn(from: 0.3, child: M1Spot(on: countIdx == k, hand: countIdx == k, size: cardH, child: SizedBox(width: slotW, child: _wordCard(_placed[k], h: cardH))))
                              : CustomPaint(
                                  painter: _SlotPainter(on: k == _placed.length, hover: cand.isNotEmpty),
                                  child: const SizedBox.expand(),
                                ),
                        ),
                      ]),
                    ),
                ]),
              ),
              Positioned.fill(child: burstLayer()),
            ]),
          ]),
        ),
      ),
      const SizedBox(height: 10),
      (needsListen && !heard)
          ? M1WaitPill(text: m1T(context, 'fr_wait_listen'), width: min(w - 30, 360.0), height: cardH + 20)
          : Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
              for (final i in _cards)
                _placed.contains(i)
                    ? SizedBox(width: slotW, height: cardH)
                    : M1PopIn(
                        key: ValueKey('c$round-$i'),
                        delay: 80 * _cards.indexOf(i),
                        child: M1Shake(
                          key: _cardKeys.putIfAbsent(i, () => GlobalKey()),
                          trigger: _cardShake[i] ?? 0,
                          child: Draggable<int>(
                            data: i,
                            maxSimultaneousDrags: busy ? 0 : 1,
                            feedback: Material(type: MaterialType.transparency, child: SizedBox(width: slotW, child: _wordCard(i, h: cardH))),
                            childWhenDragging: Opacity(opacity: 0.3, child: SizedBox(width: slotW, child: _wordCard(i, h: cardH))),
                            child: M1Press(onTap: () => _put(i), sound: '', child: SizedBox(width: slotW, child: _wordCard(i, h: cardH))),
                          ),
                        ),
                      ),
            ]),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(color: m1Cream, borderRadius: BorderRadius.circular(18), border: Border.all(color: m1Line, width: 2)),
        child: Text(m1T(context, 'fp_placed', {'n': _placed.length, 't': n}), style: m1Text(15)),
      ),
      const SizedBox(height: 4),
    ]);
  }
}

class _SlotPainter extends CustomPainter {
  final bool on, hover;
  _SlotPainter({required this.on, required this.hover});
  @override
  void paint(Canvas canvas, Size s) {
    final r = RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(12));
    canvas.drawRRect(r, Paint()..color = hover ? const Color(0xFFE3F4FF) : const Color(0xFFF1E8FF));
    final p = Paint()
      ..color = on ? const Color(0xFF39B8F2) : const Color(0xFF7B3FE4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = on ? 2.5 : 2;
    final path = Path()..addRRect(r);
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 10) {
        canvas.drawPath(m.extractPath(d, d + 5), p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SlotPainter old) => old.on != on || old.hover != hover;
}
