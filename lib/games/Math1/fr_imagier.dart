import 'dart:math';

import 'package:flutter/material.dart';

import 'fr_games.dart';
import 'fr_play.dart';
import 'm1_kit.dart';
import 'm1_shell.dart';
import 'm1_text.dart';

/// Mon imagier magique — the words the child already met, by theme.
class FrImagierPage extends StatefulWidget {
  const FrImagierPage({super.key});
  @override
  State<FrImagierPage> createState() => _FrImagierPageState();
}

class _FrImagierPageState extends State<FrImagierPage> {
  int _cat = 0;
  Set<String> _learned = {};
  String? _sel;

  static const _tabIcons = [Icons.pets_rounded, Icons.work_rounded, Icons.home_rounded];
  static const _tabColors = [Color(0xFF16C6DA), Color(0xFFB98CFF), Color(0xFFB98CFF)];

  @override
  void initState() {
    super.initState();
    m1LangOverride = 'fr';
    _load();
  }

  Future<void> _load() async {
    final l = await FrStore.learned();
    if (!mounted) return;
    setState(() {
      _learned = l;
      _pickFirst();
    });
    M1Voice.say(context, m1T(context, 'fi_say'));
  }

  void _pickFirst() {
    final w = frWords.where((x) => x.cat == frCats[_cat] && _learned.contains(x.id));
    _sel = w.isEmpty ? null : w.first.id;
  }

  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFFF6E9C8), body: M1Frame(child: Builder(builder: _page)));

  Widget _page(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final words = frWords.where((x) => x.cat == frCats[_cat]).toList();
    final done = words.where((x) => _learned.contains(x.id)).length;
    return Stack(children: [
      const M1Bg(asset: 'fr_bg_mots_menu'),
      SafeArea(
        child: Column(children: [
          SizedBox(
            height: 96,
            child: Stack(children: [
              PositionedDirectional(start: 8, top: 8, child: m1Round(context, 'fr_btn_back_p', 50, () => Navigator.of(context).maybePop())),
              PositionedDirectional(end: 8, top: 8, child: m1Round(context, 'fr_btn_sound_p', 50, () => M1Voice.say(context, m1T(context, 'fi_say')))),
              Align(
                alignment: Alignment.topCenter,
                child: M1Swing(child: M1Sign(sprite: 'fr_sign_wood', title: m1T(context, 'fi_title'), width: min(w * 0.58, 250.0))),
              ),
            ]),
          ),
          // theme tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              for (var i = 0; i < frCats.length; i++)
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
                        height: i == _cat ? 50 : 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: i == _cat ? _tabColors[0] : const Color(0xFFE2CCFF),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(18), bottom: Radius.circular(6)),
                          boxShadow: [if (i == _cat) BoxShadow(color: _tabColors[0].withOpacity(0.5), blurRadius: 10)],
                        ),
                        child: FittedBox(
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(_tabIcons[i], color: i == _cat ? const Color(0xFFFFC21A) : m1Purple, size: 22),
                            const SizedBox(width: 6),
                            Text(m1T(context, 'fi_cat_${frCats[i]}'), style: m1Text(16, color: i == _cat ? Colors.white : m1Ink)),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.75),
              itemCount: words.length,
              itemBuilder: (_, i) => M1PopIn(delay: 50 * i, child: _card(words[i])),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
            child: M1Card(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              radius: 18,
              child: Row(children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: words.isEmpty ? 0 : done / words.length,
                      minHeight: 12,
                      backgroundColor: const Color(0xFFE6DED0),
                      valueColor: const AlwaysStoppedAnimation(m1Green),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(m1T(context, 'fi_count', {'n': done, 't': words.length}), style: m1Text(14)),
              ]),
            ),
          ),
          if (_sel != null) _detail(frWord(_sel!), w),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
            child: M1OrangeButton(label: m1T(context, 'fi_continue'), icon: Icons.chevron_right_rounded, onTap: () => Navigator.of(context).maybePop(), width: min(w - 80, 300.0), height: 50),
          ),
        ]),
      ),
    ]);
  }

  Widget _card(FrWord x) {
    final ok = _learned.contains(x.id);
    final sel = x.id == _sel;
    return M1Press(
      onTap: () {
        if (ok) {
          setState(() => _sel = x.id);
          M1Voice.say(context, frSay(x));
        } else {
          M1Voice.say(context, m1T(context, 'fi_later'));
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: ok ? const Color(0xFFFFFBF0) : const Color(0xFFE4E2E6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? const Color(0xFF16C6DA) : (ok ? m1Line : const Color(0xFFCFCBD4)), width: sel ? 3.5 : 2),
          boxShadow: [if (sel) BoxShadow(color: const Color(0xFF16C6DA).withOpacity(0.6), blurRadius: 12)],
        ),
        child: Row(children: [
          Expanded(
            child: ok
                ? M1Float(amp: 2, child: Image.asset(m1(x.sprite), fit: BoxFit.contain))
                : ColorFiltered(colorFilter: const ColorFilter.mode(Color(0xFF4A3470), BlendMode.srcIn), child: Image.asset(m1(x.sprite), fit: BoxFit.contain)),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: ok
                ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    FittedBox(child: Text(x.word, style: m1Text(26))),
                    const SizedBox(height: 4),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Image.asset(m1('fr_btn_sound_p'), height: 28),
                      const SizedBox(width: 6),
                      const Icon(Icons.check_circle_rounded, color: m1Green, size: 28),
                    ]),
                  ])
                : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.lock_rounded, color: Color(0xFF4A3470), size: 26),
                    FittedBox(child: Text(m1T(context, 'fi_later'), style: m1Text(14, color: const Color(0xFF4A3470)))),
                  ]),
          ),
        ]),
      ),
    );
  }

  Widget _detail(FrWord x, double w) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: M1Card(
          radius: 22,
          padding: const EdgeInsets.all(8),
          child: SizedBox(
            height: 128,
            child: Row(children: [
              Expanded(flex: 4, child: M1PopIn(key: ValueKey(x.id), child: M1Float(child: Image.asset(m1(x.sprite), fit: BoxFit.contain)))),
              Expanded(
                flex: 6,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  FittedBox(child: Text(x.word, style: m1Text(34, height: 1.1))),
                  const SizedBox(height: 4),
                  M1Press(
                    onTap: () => M1Voice.say(context, frSay(x)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(color: m1Blue, borderRadius: BorderRadius.circular(16)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.volume_up_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 6),
                        Text(m1T(context, 'fi_listen'), style: m1Text(14, color: Colors.white)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 4),
                  M1Press(
                    onTap: () => M1Voice.say(context, x.sentence),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFF1ECE3), borderRadius: BorderRadius.circular(12)),
                      child: FittedBox(child: Text(x.sentence, style: m1Text(14))),
                    ),
                  ),
                  const SizedBox(height: 4),
                  M1Press(
                    onTap: () => Navigator.of(context).push(m1Route(M1GameMenu(game: frGames[3]))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.sync_rounded, color: m1Purple, size: 18),
                      const SizedBox(width: 4),
                      Text(m1T(context, 'fi_replay'), style: m1Text(13, color: m1Purple)),
                    ]),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      );
}
