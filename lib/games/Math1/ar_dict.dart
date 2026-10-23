import 'dart:math';

import 'package:flutter/material.dart';

import 'ar_games.dart';
import 'ar_play.dart';
import 'm1_kit.dart';
import 'm1_shell.dart';
import 'm1_text.dart';

/// معجمي المصور — the words the child already learned, by theme.
class ArDictPage extends StatefulWidget {
  const ArDictPage({super.key});
  @override
  State<ArDictPage> createState() => _ArDictPageState();
}

class _ArDictPageState extends State<ArDictPage> {
  int _cat = 0;
  Set<String> _learned = {};
  String? _sel;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final l = await ArStore.learned();
    if (!mounted) return;
    setState(() {
      _learned = l;
      _pickFirst();
    });
  }

  void _pickFirst() {
    final w = arWords.where((x) => x.cat == arCats[_cat] && _learned.contains(x.id));
    _sel = w.isEmpty ? null : w.first.id;
  }

  void _say(ArWord w) => M1Voice.say(context, w.word);

  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFFF6E9C8), body: M1Frame(child: Builder(builder: _page)));

  Widget _page(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final words = arWords.where((x) => x.cat == arCats[_cat]).toList();
    final done = words.where((x) => _learned.contains(x.id)).length;
    return Stack(children: [
      const M1Bg(asset: 'ar_bg_words_menu'),
      SafeArea(
        child: Column(children: [
          SizedBox(
            height: 82,
            child: Stack(children: [
              PositionedDirectional(start: 8, top: 8, child: m1Round(context, 'ar_btn_back', 50, () => Navigator.of(context).maybePop(), flipRtl: true)),
              Align(alignment: Alignment.topCenter, child: M1Swing(child: M1Sign(sprite: 'ar_sign_wood', title: m1T(context, 'ar_dict'), width: min(w * 0.6, 240.0)))),
            ]),
          ),
          // theme tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              for (var i = 0; i < arCats.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: M1Press(
                      onTap: () => setState(() {
                        _cat = i;
                        _pickFirst();
                      }),
                      sound: 'toggleButton',
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: i == _cat ? m1Purple : m1Cream,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16), bottom: Radius.circular(8)),
                          border: Border.all(color: i == _cat ? const Color(0xFFFFC21A) : m1Line, width: 2),
                        ),
                        child: FittedBox(child: Text(m1T(context, 'ar_cat_${arCats[i]}'), style: m1Text(16, color: i == _cat ? Colors.white : m1Ink))),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.45),
              itemCount: words.length,
              itemBuilder: (_, i) => M1PopIn(delay: 50 * i, child: _card(words[i])),
            ),
          ),
          // progress
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
            child: M1Card(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              radius: 18,
              child: Row(children: [
                Text(m1T(context, 'ar_dict_count', {'n': done, 't': words.length}), style: m1Text(14)),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: words.isEmpty ? 0 : done / words.length,
                      minHeight: 10,
                      backgroundColor: const Color(0xFFE6DED0),
                      valueColor: const AlwaysStoppedAnimation(m1Green),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Image.asset(m1('ar_w_dict'), width: 30),
              ]),
            ),
          ),
          if (_sel != null) _detail(arWord(_sel!), w),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
            child: M1OrangeButton(label: m1T(context, 'ar_dict_more'), icon: Icons.chevron_left_rounded, onTap: () => Navigator.of(context).maybePop(), width: min(w - 80, 280.0), height: 50),
          ),
        ]),
      ),
    ]);
  }

  Widget _card(ArWord x) {
    final ok = _learned.contains(x.id);
    final sel = x.id == _sel;
    return M1Press(
      onTap: () {
        if (ok) {
          setState(() => _sel = x.id);
          _say(x);
        } else {
          M1Voice.say(context, m1T(context, 'ar_dict_later'));
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ok ? const Color(0xFFFFFBF0) : const Color(0xFFE4E2E6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? const Color(0xFF22C8F0) : (ok ? m1Line : const Color(0xFFCFCBD4)), width: sel ? 3.5 : 2),
          boxShadow: [if (sel) BoxShadow(color: const Color(0xFF22C8F0).withOpacity(0.6), blurRadius: 12)],
        ),
        child: Stack(children: [
          Row(children: [
            Expanded(
              child: ok
                  ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      FittedBox(child: Text(x.word, textDirection: TextDirection.rtl, style: m1Text(28, height: 1.3))),
                      const SizedBox(height: 4),
                      const Icon(Icons.volume_up_rounded, color: m1Blue, size: 26),
                    ])
                  : Center(child: FittedBox(child: Text(m1T(context, 'ar_dict_later'), style: m1Text(13, color: const Color(0xFF8C8696))))),
            ),
            Expanded(
              child: ok
                  ? M1Float(amp: 2, child: Image.asset(m1(x.sprite), fit: BoxFit.contain))
                  : ColorFiltered(colorFilter: const ColorFilter.mode(Color(0xFF8C8696), BlendMode.srcIn), child: Opacity(opacity: 0.55, child: Image.asset(m1(x.sprite), fit: BoxFit.contain))),
            ),
          ]),
          PositionedDirectional(
            end: 0,
            top: 0,
            child: ok ? const Icon(Icons.check_circle_rounded, color: m1Green, size: 24) : const Icon(Icons.lock_rounded, color: Color(0xFF8C8696), size: 22),
          ),
        ]),
      ),
    );
  }

  Widget _detail(ArWord x, double w) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: M1Card(
          radius: 22,
          rim: const Color(0xFF9B62F2),
          padding: const EdgeInsets.all(8),
          child: SizedBox(
            height: 112,
            child: Row(children: [
              Expanded(
                flex: 5,
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  FittedBox(child: Text(x.word, textDirection: TextDirection.rtl, style: m1Text(32, height: 1.3))),
                  const SizedBox(height: 4),
                  M1Press(
                    onTap: () => M1Voice.say(context, '${m1T(context, 'aw_this')} ${x.word}'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFFDDF0FF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF59AEF5), width: 2)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.volume_up_rounded, color: m1Blue, size: 20),
                        const SizedBox(width: 6),
                        Text('${m1T(context, 'aw_this')} ${x.word}', textDirection: TextDirection.rtl, style: m1Text(15)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 4),
                  M1Press(
                    onTap: () => Navigator.of(context).push(m1Route(M1GameMenu(game: arGames[3]))),
                    child: Text('🎮 ${m1T(context, 'ar_dict_play')}', style: m1Text(13, color: m1Purple)),
                  ),
                ]),
              ),
              Expanded(flex: 4, child: M1PopIn(key: ValueKey(x.id), child: M1Float(child: Image.asset(m1(x.sprite), fit: BoxFit.contain)))),
            ]),
          ),
        ),
      );
}
