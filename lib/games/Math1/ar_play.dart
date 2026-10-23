import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'm1_kit.dart';
import 'm1_shell.dart';
import 'm1_text.dart';
import 'sc_play.dart';

// ═══════════════════════════════════════════════════════════════════════════
// اللغة العربية — السنة الأولى ابتدائي. Five games on the shared engine.
// ═══════════════════════════════════════════════════════════════════════════

// ── letters ────────────────────────────────────────────────────────────────

const List<String> arLetters = ['ا', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ', 'د', 'ذ', 'ر', 'ز', 'س', 'ش', 'ص', 'ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ق', 'ك', 'ل', 'م', 'ن', 'ه', 'و', 'ي'];

const Map<String, String> arLetterName = {
  'ا': 'ألف', 'ب': 'باء', 'ت': 'تاء', 'ث': 'ثاء', 'ج': 'جيم', 'ح': 'حاء', 'خ': 'خاء', 'د': 'دال', 'ذ': 'ذال', 'ر': 'راء',
  'ز': 'زاي', 'س': 'سين', 'ش': 'شين', 'ص': 'صاد', 'ض': 'ضاد', 'ط': 'طاء', 'ظ': 'ظاء', 'ع': 'عين', 'غ': 'غين', 'ف': 'فاء',
  'ق': 'قاف', 'ك': 'كاف', 'ل': 'لام', 'م': 'ميم', 'ن': 'نون', 'ه': 'هاء', 'و': 'واو', 'ي': 'ياء',
};

/// Letters learned in each range of the letters game.
const List<List<String>> arLetterGroups = [
  ['ا', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ', 'د', 'ذ'],
  ['ر', 'ز', 'س', 'ش', 'ص', 'ض', 'ط', 'ظ', 'ع'],
  ['غ', 'ف', 'ق', 'ك', 'ل', 'م', 'ن', 'ه', 'و', 'ي'],
];

/// Letters that look alike (they differ by their dots).
const List<List<String>> _twins = [
  ['ب', 'ت', 'ث', 'ن', 'ي'], ['ج', 'ح', 'خ'], ['د', 'ذ', 'ر'], ['ر', 'ز', 'و'], ['س', 'ش', 'ص'], ['ص', 'ض', 'ط'],
  ['ط', 'ظ', 'ض'], ['ع', 'غ', 'ف'], ['ف', 'ق', 'غ'], ['ك', 'ل', 'ا'], ['م', 'ه', 'و'], ['ا', 'ل', 'ك'], ['ن', 'ب', 'ت'], ['ي', 'ب', 'ن'],
];

// ── words with pictures ────────────────────────────────────────────────────

class ArWord {
  final String id, word, sprite, cat, first;
  const ArWord(this.id, this.word, this.sprite, this.cat, this.first);
}

const List<String> arCats = ['animals', 'school', 'home'];

const List<ArWord> arWords = [
  ArWord('rabbit', 'أَرْنَب', 'ar_w_rabbit', 'animals', 'ا'),
  ArWord('duck', 'بَطَّة', 'ar_w_duck', 'animals', 'ب'),
  ArWord('fish', 'سَمَكَة', 'ar_w_fish', 'animals', 'س'),
  ArWord('camel', 'جَمَل', 'ar_w_camel', 'animals', 'ج'),
  ArWord('deer', 'غَزَال', 'ar_w_deer', 'animals', 'غ'),
  ArWord('squirrel', 'سِنْجَاب', 'ar_w_squirrel', 'animals', 'س'),
  ArWord('bird', 'عُصْفُور', 'ar_w_bird', 'animals', 'ع'),
  ArWord('butterfly', 'فَرَاشَة', 'ar_w_butterfly', 'animals', 'ف'),
  ArWord('book', 'كِتَاب', 'ar_w_book', 'school', 'ك'),
  ArWord('books', 'كُتُب', 'ar_books', 'school', 'ك'),
  ArWord('pencil', 'قَلَم', 'ar_pencil', 'school', 'ق'),
  ArWord('bag', 'حَقِيبَة', 'ar_w_bag', 'school', 'ح'),
  ArWord('notebook', 'دَفْتَر', 'ar_book_open', 'school', 'د'),
  ArWord('house', 'بَيْت', 'ar_w_house', 'home', 'ب'),
  ArWord('tree', 'شَجَرَة', 'ar_tree_green', 'home', 'ش'),
  ArWord('rose', 'وَرْدَة', 'ar_flowers', 'home', 'و'),
  ArWord('star', 'نَجْمَة', 'ar_star', 'home', 'ن'),
];

ArWord arWord(String id) => arWords.firstWhere((w) => w.id == id);

/// Words the child already learned (shown in the picture dictionary).
class ArStore {
  static const _k = 'ar_learned';
  static Future<Set<String>> learned() async => ((await SharedPreferences.getInstance()).getStringList(_k) ?? const []).toSet();
  static Future<void> learn(String id) async {
    final p = await SharedPreferences.getInstance();
    final l = (p.getStringList(_k) ?? <String>[]).toSet()..add(id);
    await p.setStringList(_k, l.toList());
  }
}

// ── harakat ────────────────────────────────────────────────────────────────

const List<String> arHarakat = ['fatha', 'damma', 'kasra'];
const Map<String, String> arMark = {'fatha': 'َ', 'damma': 'ُ', 'kasra': 'ِ'};
const Map<String, Color> arMarkColor = {'fatha': Color(0xFF14A9B8), 'damma': Color(0xFF7B3FE4), 'kasra': Color(0xFFF7811E)};
const List<List<String>> arHarakaLetters = [
  ['ب', 'ت', 'ن', 'م'],
  ['د', 'ر', 'س', 'ش', 'ف', 'ل'],
  ['ك', 'ق', 'ع', 'ج', 'ح', 'ه', 'و', 'ي'],
];

// ── sentences ──────────────────────────────────────────────────────────────

class ArSentence {
  final List<String> words;
  final String sprite;
  const ArSentence(this.words, this.sprite);
  String get text => words.join(' ');
}

const List<ArSentence> arSentences3 = [
  ArSentence(['أَنَا', 'أَقْرَأُ', 'كِتَابًا'], 'ar_kid_read'),
  ArSentence(['الْأَرْنَبُ', 'يَأْكُلُ', 'جَزَرًا'], 'ar_w_rabbit'),
  ArSentence(['السَّمَكَةُ', 'تَسْبَحُ', 'بِسُرْعَةٍ'], 'ar_w_fish'),
  ArSentence(['الْعُصْفُورُ', 'يَطِيرُ', 'عَالِيًا'], 'ar_w_bird'),
  ArSentence(['الْجَمَلُ', 'يَمْشِي', 'بِبُطْءٍ'], 'ar_w_camel'),
  ArSentence(['الْفَرَاشَةُ', 'جَمِيلَةٌ', 'جِدًّا'], 'ar_w_butterfly'),
];

const List<ArSentence> arSentences4 = [
  ArSentence(['الْبَطَّةُ', 'تَسْبَحُ', 'فِي', 'الْمَاءِ'], 'ar_p_duck'),
  ArSentence(['الطِّفْلُ', 'يَقْفِزُ', 'مِنَ', 'الْفَرَحِ'], 'ar_kid_jump'),
  ArSentence(['الْأَرْنَبُ', 'يَجْلِسُ', 'فِي', 'الْحَدِيقَةِ'], 'ar_p_rabbit'),
  ArSentence(['السِّنْجَابُ', 'يَحْمِلُ', 'حَبَّةَ', 'بَلُّوطٍ'], 'ar_w_squirrel'),
  ArSentence(['أَنَا', 'أَقْرَأُ', 'مَعَ', 'صَدِيقِي'], 'ar_kid_robot_book'),
  ArSentence(['الْغَزَالُ', 'يَرْكُضُ', 'فِي', 'الْغَابَةِ'], 'ar_w_deer'),
];

// ═══════════════════════════════════════════════════════════════════════════
// Shared base for the Arabic quizzes: a big speaker the child taps first.
// ═══════════════════════════════════════════════════════════════════════════

abstract class ArQuizState<W extends M1Play> extends ScQuizState<W> {
  bool heard = false;
  final GlobalKey speakerKey = GlobalKey();

  /// What the speaker says.
  String get voice;

  /// Modes where the child must listen before the answers appear.
  bool get needsListen => false;

  @override
  bool get optionsReady => !needsListen || heard;

  @override
  String get waitText => m1T(context, 'ar_wait_listen');

  void listen() {
    M1Voice.say(context, voice);
    if (!heard) {
      setState(() => heard = true);
    }
  }

  @override
  void idleHelp() {
    if (needsListen && !heard) {
      say(m1T(context, 'ar_tap_speaker'));
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

  /// The big speaker with sound waves.
  Widget speaker({double? width}) => LayoutBuilder(builder: (_, c) {
        final w = min(width ?? c.maxWidth, c.maxHeight / m1Ratio('ar_sound_wave'));
        return M1Press(
          key: speakerKey,
          onTap: listen,
          sound: '',
          child: AnimatedBuilder(
            animation: pulse,
            builder: (_, ch) => Transform.scale(scale: heard ? 1 : 1 + 0.06 * sin(pulse.value * 2 * pi * 3), child: ch),
            child: Image.asset(m1('ar_sound_wave'), width: w, fit: BoxFit.contain),
          ),
        );
      });

  /// A picture with a small speaker under it.
  Widget picWithSpeaker(String sprite) => Column(children: [
        Expanded(child: floatPic(sprite)),
        const SizedBox(height: 4),
        SizedBox(height: 46, child: speaker(width: 150)),
      ]);

  /// A big Arabic text on a cream card.
  Widget bigText(String t, {Color color = m1Ink, double size = 90}) => M1Card(
        radius: 26,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        child: FittedBox(fit: BoxFit.scaleDown, child: Text(t, textDirection: TextDirection.rtl, style: m1Text(size, color: color, height: 1.3))),
      );

  @override
  void newRound() {
    heard = false;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 1 · حديقة الحروف — أتعرف · أبحث · الحروف المتشابهة
// ═══════════════════════════════════════════════════════════════════════════

class ArLettersPlay extends M1Play {
  const ArLettersPlay({super.key, required super.lv});
  @override
  State<ArLettersPlay> createState() => _LettersState();
}

class _LettersState extends ArQuizState<ArLettersPlay> {
  String _l = 'ب';

  List<String> get _group => arLetterGroups[tier];

  @override
  String get voice => switch (mode) {
        'twins' => m1T(context, 'al_twins'),
        _ => '${m1T(context, 'al_letter')} ${arLetterName[_l]}',
      };

  @override
  bool get needsListen => mode == 'recognize';

  @override
  String get instruction => switch (mode) {
        'recognize' => m1T(context, 'al_q_find', {'n': arLetterName[_l]!}),
        'find' => m1T(context, 'al_q_all', {'n': arLetterName[_l]!}),
        _ => m1T(context, 'al_twins'),
      };

  @override
  Color textColor(ScOpt o) => m1DigitColor(arLetters.indexOf(o.key.split('#').first));

  @override
  void newRound() {
    super.newRound();
    clearQuiz();
    _l = _group[rng.nextInt(_group.length)];
    switch (mode) {
      case 'recognize':
        final n = [3, 4, 4][lv.range];
        final others = (List.of(_group)..remove(_l)..shuffle(rng)).take(n - 1);
        opts = [for (final x in [_l, ...others]) ScOpt(x, 'T:$x', '')]..shuffle(rng);
        answers = {_l};
      case 'find':
        final copies = 2 + rng.nextInt(2);
        final total = [6, 8, 9][lv.range];
        final others = (List.of(_group)..remove(_l)..shuffle(rng));
        opts = [
          for (var i = 0; i < copies; i++) ScOpt('$_l#$i', 'T:$_l', ''),
          for (var i = 0; i < total - copies; i++) ScOpt('${others[i % others.length]}#x$i', 'T:${others[i % others.length]}', ''),
        ]..shuffle(rng);
        answers = {for (var i = 0; i < copies; i++) '$_l#$i'};
        multi = true;
      default:
        final fam = _twins.where((f) => f.contains(_l)).toList();
        final f = fam.isEmpty ? (List.of(arLetters)..shuffle(rng)).take(3).toList() : fam[rng.nextInt(fam.length)];
        final others = (List.of(f)..remove(_l)..shuffle(rng)).take(lv.range == 0 ? 2 : 3);
        opts = [for (final x in [_l, ...others]) ScOpt(x, 'T:$x', '')]..shuffle(rng);
        answers = {_l};
    }
    labels = false;
    missTopic = 'al_rev_${mode == 'twins' ? 'twins' : 'shape'}';
    missHelp = mode == 'twins' ? 'al_help_dots' : 'al_help_shape';
  }

  @override
  String? rightText(ScOpt o) => '${m1T(context, 'al_yes')} ${arLetterName[_l]}';

  @override
  Future<void> explain() async {
    if (mode == 'find') return super.explain();
    setState(() => showWhy = true);
    M1Voice.say(context, '${arLetterName[_l]}. $_l');
    await Future.delayed(const Duration(milliseconds: 1600));
    if (mounted) setState(() => showWhy = false);
  }

  @override
  Widget board(BuildContext context, double w, double h) => switch (mode) {
        'recognize' => quizBoard(w, h, scene: speaker(), sceneFlex: 26),
        'find' => quizBoard(w, h, scene: bigText(_l, color: textColor(ScOpt(_l, '', '')), size: 70), sceneFlex: 24),
        _ => quizBoard(w, h, scene: bigText(_l, color: textColor(ScOpt(_l, '', ''))), sceneFlex: 34),
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// 2 · أسمع وأكتشف — أستمع · أول صوت · نفس الصوت
// ═══════════════════════════════════════════════════════════════════════════

class ArSoundsPlay extends M1Play {
  const ArSoundsPlay({super.key, required super.lv});
  @override
  State<ArSoundsPlay> createState() => _SoundsState();
}

class _SoundsState extends ArQuizState<ArSoundsPlay> {
  late ArWord _w;
  String _l = 'ب';

  List<ArWord> get _pool => switch (lv.range) {
        0 => arWords.where((w) => w.cat == 'animals').toList(),
        1 => arWords.where((w) => w.cat != 'animals').toList(),
        _ => arWords,
      };

  @override
  String get voice => mode == 'same' ? '${m1T(context, 'as_same_v')} ${arLetterName[_l]}' : _w.word;

  @override
  bool get needsListen => mode != 'same';

  @override
  String get instruction => switch (mode) {
        'listen' => m1T(context, 'as_q_listen'),
        'first' => m1T(context, 'as_q_first'),
        _ => m1T(context, 'as_q_same', {'n': arLetterName[_l]!}),
      };

  @override
  Color textColor(ScOpt o) => m1DigitColor(arLetters.indexOf(o.key));

  @override
  void newRound() {
    super.newRound();
    clearQuiz();
    final pool = _pool;
    _w = pool[rng.nextInt(pool.length)];
    switch (mode) {
      case 'listen':
        final others = (arWords.where((x) => x.id != _w.id).toList()..shuffle(rng)).take(lv.range == 0 ? 2 : 3);
        opts = [for (final x in [_w, ...others]) ScOpt(x.id, x.sprite, '')]..shuffle(rng);
        answers = {_w.id};
        labels = false;
        missTopic = 'as_rev_listen';
        missHelp = 'as_help_listen';
      case 'first':
        final others = (List.of(arLetters)..remove(_w.first)..shuffle(rng)).take(lv.range == 0 ? 2 : 3);
        opts = [for (final x in [_w.first, ...others]) ScOpt(x, 'T:$x', '')]..shuffle(rng);
        answers = {_w.first};
        labels = false;
        missTopic = 'as_rev_first';
        missHelp = 'as_help_first';
      default:
        const ls = ['ب', 'س', 'ك'];
        _l = ls[rng.nextInt(ls.length)];
        final mine = arWords.where((x) => x.first == _l).toList();
        final others = (arWords.where((x) => x.first != _l).toList()..shuffle(rng)).take([2, 3, 4][lv.range]);
        opts = [for (final x in [...mine, ...others]) ScOpt(x.id, x.sprite, '')]..shuffle(rng);
        answers = {for (final x in mine) x.id};
        multi = true;
        labels = false;
        missTopic = 'as_rev_same';
        missHelp = 'as_help_same';
    }
  }

  @override
  String? rightText(ScOpt o) {
    if (mode != 'same') ArStore.learn(_w.id);
    return mode == 'first' ? '${_w.word} ${m1T(context, 'as_starts')} ${arLetterName[_w.first]}' : null;
  }

  @override
  Future<void> explain() async {
    if (mode == 'same') {
      final ids = [for (final o in opts) if (answers.contains(o.key)) o.key];
      countKeys = ids;
      await countAlong(ids.length, word: (k) => arWord(ids[k]).word, ms: 1100);
      countKeys = [];
      return;
    }
    setState(() => showWhy = true);
    M1Voice.say(context, _w.word);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => showWhy = false);
  }

  @override
  Widget board(BuildContext context, double w, double h) => switch (mode) {
        'listen' => quizBoard(w, h, scene: speaker(), sceneFlex: 24),
        'first' => quizBoard(w, h, scene: picWithSpeaker(_w.sprite), sceneFlex: 40),
        _ => quizBoard(w, h, scene: GestureDetector(onTap: listen, child: bigText(_l, color: textColor(ScOpt(_l, '', '')), size: 70)), sceneFlex: 22),
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// 3 · قطار الحركات — أسمع · أركّب · أقرأ
// ═══════════════════════════════════════════════════════════════════════════

class ArHarakatPlay extends M1Play {
  const ArHarakatPlay({super.key, required super.lv});
  @override
  State<ArHarakatPlay> createState() => _HarakatState();
}

class _HarakatState extends ArQuizState<ArHarakatPlay> {
  String _l = 'ب', _h = 'fatha';
  String get _syl => '$_l${arMark[_h]}';

  @override
  String get bg => 'ar_bg_harakat';

  @override
  String get voice => _syl;

  @override
  bool get needsListen => mode == 'listen';

  @override
  bool get dragToScene => mode == 'build';

  @override
  String get instruction => switch (mode) {
        'listen' => m1T(context, 'ah_q_listen'),
        'build' => m1T(context, 'ah_q_build', {'s': _syl}),
        _ => m1T(context, 'ah_q_read'),
      };

  @override
  Color textColor(ScOpt o) => arMarkColor[o.key] ?? m1Ink;

  @override
  void newRound() {
    super.newRound();
    clearQuiz();
    final ls = arHarakaLetters[lv.range];
    _l = ls[rng.nextInt(ls.length)];
    _h = arHarakat[rng.nextInt(3)];
    switch (mode) {
      case 'listen':
        opts = [for (final h in arHarakat) ScOpt(h, 'T:$_l${arMark[h]}', '')]..shuffle(rng);
      case 'build':
        opts = [for (final h in arHarakat) ScOpt(h, 'T:ـ${arMark[h]}ـ', 'ah_n_$h')]..shuffle(rng);
      default:
        opts = [for (final h in arHarakat) ScOpt(h, 'T:${m1T(context, 'ah_n_$h')}', '')]..shuffle(rng);
    }
    answers = {_h};
    labels = mode == 'build' && lv.range < 2;
    missTopic = 'ah_rev_$_h';
    missHelp = 'ah_help_$_h';
  }

  @override
  String? rightText(ScOpt o) => '$_syl! ${m1T(context, 'ah_rev_$_h')}';

  @override
  Future<void> explain() async {
    setState(() => showWhy = true);
    for (final h in arHarakat) {
      if (!mounted) return;
      M1Voice.say(context, '$_l${arMark[h]}');
      await Future.delayed(const Duration(milliseconds: 750));
    }
    if (mounted) setState(() => showWhy = false);
  }

  /// The letter in a wagon (with its harakah once found).
  Widget _wagon() => LayoutBuilder(builder: (_, c) {
        final done = busy || mode == 'read';
        final r = m1Ratio('ar_train_big');
        final w = min(c.maxWidth, c.maxHeight / r);
        final h = w * r;
        return SizedBox(
          width: w,
          height: h,
          child: Stack(children: [
            Positioned.fill(child: Directionality(textDirection: TextDirection.ltr, child: Image.asset(m1('ar_train_big'), fit: BoxFit.contain))),
            Positioned(
              left: w * 0.08,
              width: w * 0.49,
              top: h * 0.14,
              height: h * 0.4,
              child: Center(
                child: FittedBox(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (ch, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.elasticOut), child: ch),
                    child: Text(done ? _syl : _l,
                        key: ValueKey(done),
                        textDirection: TextDirection.rtl,
                        style: m1Text(80, color: done ? (arMarkColor[_h] ?? m1Ink) : m1Ink, height: 1.4)),
                  ),
                ),
              ),
            ),
          ]),
        );
      });

  @override
  Widget board(BuildContext context, double w, double h) => switch (mode) {
        'listen' => quizBoard(w, h, scene: Column(children: [Expanded(child: speaker()), const SizedBox(height: 4), Text(_l, style: m1Text(34, height: 1.2))]), sceneFlex: 30),
        _ => quizBoard(w, h, scene: _wagon(), sceneFlex: 38),
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// 4 · كلمتي وصورتي — أصل · أقرأ · أستمع
// ═══════════════════════════════════════════════════════════════════════════

class ArWordsPlay extends M1Play {
  const ArWordsPlay({super.key, required super.lv});
  @override
  State<ArWordsPlay> createState() => _WordsState();
}

class _WordsState extends ArQuizState<ArWordsPlay> {
  late ArWord _w;

  @override
  String get voice => _w.word;

  @override
  bool get needsListen => mode == 'listen';

  @override
  bool get dragToScene => mode == 'match';

  @override
  String get instruction => switch (mode) {
        'match' => m1T(context, 'aw_q_match'),
        'read' => m1T(context, 'aw_q_read'),
        _ => m1T(context, 'aw_q_listen'),
      };

  @override
  int? get optCols => mode == 'read' ? null : (opts.length <= 3 ? 1 : 2);

  @override
  void newRound() {
    super.newRound();
    clearQuiz();
    final pool = arWords.where((x) => x.cat == arCats[lv.range]).toList();
    _w = pool[rng.nextInt(pool.length)];
    final others = (pool.where((x) => x.id != _w.id).toList()..shuffle(rng)).take(2);
    final list = [_w, ...others]..shuffle(rng);
    opts = [for (final x in list) mode == 'read' ? ScOpt(x.id, x.sprite, '') : ScOpt(x.id, 'T:${x.word}', '')];
    answers = {_w.id};
    labels = false;
    missTopic = 'aw_rev';
    missHelp = mode == 'match' ? 'aw_help_drag' : 'aw_help';
  }

  @override
  String? rightText(ScOpt o) {
    ArStore.learn(_w.id);
    return '${m1T(context, 'aw_this')} ${_w.word}';
  }

  @override
  Future<void> explain() async {
    setState(() => showWhy = true);
    M1Voice.say(context, '${m1T(context, 'aw_this')} ${_w.word}');
    await Future.delayed(const Duration(milliseconds: 1700));
    if (mounted) setState(() => showWhy = false);
  }

  @override
  Widget board(BuildContext context, double w, double h) => switch (mode) {
        'match' => quizBoard(w, h, scene: floatPic(_w.sprite), sceneFlex: 44),
        'read' => quizBoard(w, h, scene: GestureDetector(onTap: listen, child: bigText(_w.word, size: 64)), sceneFlex: 26),
        _ => quizBoard(w, h, scene: speaker(), sceneFlex: 24),
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// 5 · جملتي الأولى — أستمع · أرتّب · أفهم
// ═══════════════════════════════════════════════════════════════════════════

class ArSentencesPlay extends M1Play {
  const ArSentencesPlay({super.key, required super.lv});
  @override
  State<ArSentencesPlay> createState() => _SentencesState();
}

class _SentencesState extends ArQuizState<ArSentencesPlay> {
  late ArSentence _s;
  List<int> _cards = []; // word indexes in shuffled order
  final List<int> _placed = []; // word indexes placed in the slots
  final Map<int, int> _cardShake = {};
  final Map<int, GlobalKey> _cardKeys = {};
  final List<GlobalKey> _slotKeys = List.generate(5, (_) => GlobalKey());

  List<ArSentence> get _pool => switch (lv.range) {
        0 => arSentences3,
        1 => arSentences4,
        _ => [...arSentences3, ...arSentences4],
      };

  @override
  String get voice => _s.text;

  @override
  bool get needsListen => mode == 'listen';

  @override
  String get instruction => switch (mode) {
        'listen' => m1T(context, 'ase_q_listen'),
        'order' => m1T(context, 'ase_q_order'),
        _ => m1T(context, 'ase_q_understand'),
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
      missTopic = 'ase_rev_understand';
      missHelp = 'ase_help_understand';
    }
  }

  void _put(int i) {
    if (busy || _placed.contains(i)) return;
    if (needsListen && !heard) {
      say(m1T(context, 'ar_tap_speaker'));
      return;
    }
    if (i == _placed.length) {
      setState(() => _placed.add(i));
      m1Sound(context, 'PopButton');
      M1Voice.say(context, _s.words[i]);
      if (_placed.length == _s.words.length) good(text: _s.text);
    } else {
      setState(() => _cardShake[i] = (_cardShake[i] ?? 0) + 1);
      bad(m1T(context, 'ase_rev_order'), help: _placed.isEmpty ? m1T(context, 'ase_help_first') : m1T(context, 'ase_help_next'));
    }
  }

  Widget _wordCard(int i, {double h = 64}) => Container(
        height: h,
        padding: EdgeInsets.symmetric(horizontal: h * 0.25),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF0),
          borderRadius: BorderRadius.circular(h * 0.25),
          border: Border.all(color: const Color(0xFFF2B33D), width: 3),
          boxShadow: [BoxShadow(color: const Color(0xFFC49A52).withOpacity(0.45), offset: const Offset(0, 4))],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(_s.words[i], textDirection: TextDirection.rtl, style: m1Text(h * 0.48, color: m1DigitColor(i * 3 + 1), height: 1.3)),
        ),
      );

  @override
  void idleHelp() {
    if (mode == 'understand') return super.idleHelp();
    if (needsListen && !heard) return super.idleHelp();
    final next = _placed.length;
    if (next >= _s.words.length) return;
    say(next == 0 ? m1T(context, 'ase_help_first') : m1T(context, 'ase_help_next'));
    final k = _cardKeys[next];
    if (k != null) showDrag(k, _slotKeys[next], '', ghost: _wordCard(next, h: 54));
  }

  @override
  Future<void> explain() async {
    if (mode == 'understand') return super.explain();
    await countAlong(_s.words.length, word: (k) => _s.words[k], ms: 700);
    if (!mounted) return;
    M1Voice.say(context, _s.text);
    await Future.delayed(const Duration(milliseconds: 1800));
  }

  @override
  Widget board(BuildContext context, double w, double h) {
    if (mode == 'understand') return quizBoard(w, h, scene: floatPic(_s.sprite), sceneFlex: 46);
    final rh = min(h * 0.18, 96.0);
    final n = _s.words.length;
    final slotW = (w - 30 - 8.0 * (n - 1)) / n;
    final cardH = min(64.0, h * 0.1);
    return Column(children: [
      SizedBox(height: rh, child: robotLine(w, rh, robotH: rh)),
      Expanded(
        flex: 30,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Expanded(child: M1PopIn(key: ValueKey('pic$round'), child: floatPic(_s.sprite, pad: 8))),
            if (mode == 'listen') ...[const SizedBox(width: 8), SizedBox(width: w * 0.3, child: speaker())],
          ]),
        ),
      ),
      const SizedBox(height: 6),
      M1SayPill(text: instruction, width: min(w - 24, 380.0), height: 46),
      const SizedBox(height: 8),
      // numbered slots (the first one is on the right)
      Stack(children: [
        DragTarget<int>(
          onWillAcceptWithDetails: (_) => !busy,
          onAcceptWithDetails: (d) => _put(d.data),
          builder: (_, cand, __) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var k = 0; k < n; k++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: k == _placed.length ? m1Orange : m1Purple),
                    child: Text('${k + 1}', style: m1Text(14, color: Colors.white)),
                  ),
                  const SizedBox(height: 3),
                  SizedBox(
                    key: _slotKeys[k],
                    width: slotW,
                    height: cardH,
                    child: k < _placed.length
                        ? M1PopIn(from: 0.3, child: M1Spot(on: countIdx == k, hand: countIdx == k, size: cardH, child: SizedBox(width: slotW, child: _wordCard(_placed[k], h: cardH))))
                        : DecoratedBox(
                            decoration: BoxDecoration(
                              color: (cand.isNotEmpty ? const Color(0xFFE3F4FF) : const Color(0xFFFFF9EC)).withOpacity(0.9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: k == _placed.length ? const Color(0xFF39B8F2) : const Color(0xFFB9A2E6), width: 2),
                            ),
                          ),
                  ),
                ]),
              ),
          ]),
        ),
        Positioned.fill(child: burstLayer()),
      ]),
      const Spacer(),
      // the word cards
      (needsListen && !heard)
          ? M1WaitPill(text: m1T(context, 'ar_wait_listen'), width: min(w - 30, 360.0), height: cardH + 20)
          : Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10, children: [
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
      const Spacer(),
      Text(m1T(context, 'ase_placed', {'n': _placed.length, 't': n}), style: m1Text(15)),
      const SizedBox(height: 4),
    ]);
  }
}
