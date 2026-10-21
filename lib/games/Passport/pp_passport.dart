import 'dart:math';

import 'package:flutter/material.dart';

import 'pp_data.dart';
import 'pp_menu.dart';
import 'pp_strings.dart';

/// "Mon passeport magique" — every stamp the child collected.
class MyPassportPage extends StatefulWidget {
  final String? highlight;
  const MyPassportPage({super.key, this.highlight});
  @override
  State<MyPassportPage> createState() => _MyPassportPageState();
}

class _MyPassportPageState extends State<MyPassportPage> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  late final AnimationController _flip = AnimationController(vsync: this, duration: const Duration(milliseconds: 450))..value = 1;
  PpProgress _p = const PpProgress({}, null);
  int _page = 0;
  late String _sel = widget.highlight ?? ppStages.first.id;
  bool _loaded = false;

  static const int _perPage = 6;
  int get _pages => (ppStages.length / _perPage).ceil();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await PpStore.load();
    if (!mounted) return;
    setState(() {
      _p = p;
      if (!_loaded) {
        _loaded = true;
        final pick = widget.highlight ?? p.newest ?? ppStages.firstWhere((s) => p.done(s.id), orElse: () => ppStages.first).id;
        _sel = pick;
        _page = ppStages.indexWhere((s) => s.id == pick) ~/ _perPage;
      }
    });
  }

  @override
  void dispose() {
    PpVoice.stop();
    _idle.dispose();
    _flip.dispose();
    super.dispose();
  }

  void _turn(int d) {
    final n = (_page + d).clamp(0, _pages - 1);
    if (n == _page) return;
    ppSound(context, 'clickButton');
    setState(() => _page = n);
    _flip.forward(from: 0);
  }

  void _tap(PpStage st) {
    if (!_p.done(st.id)) {
      ppSound(context, 'clickButton2');
      PpVoice.say(context, ppT(context, 'emptyStamp'));
      setState(() => _sel = st.id);
      return;
    }
    ppSound(context, 'PopButton');
    setState(() => _sel = st.id);
    PpVoice.say(context, '${st.title(context)}. ${st.fact(context)}');
  }

  @override
  Widget build(BuildContext context) => PpFrame(child: Builder(builder: _page_));

  Widget _page_(BuildContext context) {
    final s = ppScale(context);
    final size = MediaQuery.sizeOf(context);
    final w = min(size.width, 520.0);
    final st = ppStage(_sel);
    return Scaffold(
      backgroundColor: const Color(0xFF8FD3F5),
      body: Stack(children: [
        const Positioned.fill(child: PpBg(asset: 'pp_bg_win')),
        SafeArea(
          child: Center(
            child: SizedBox(
              width: w,
              child: Column(children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 4 * s),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ppRound(context, 'pp_back', 44 * s, () {
                      ppSound(context, 'cancelButton');
                      Navigator.of(context).maybePop();
                    }, flipRtl: true),
                    Expanded(child: Center(child: PpHeader(a: ppT(context, 'ppA'), b: ppT(context, 'ppB'), width: min(w * 0.7, 280 * s)))),
                    ppMute(context, 44 * s),
                  ]),
                ),
                ppOnSprite(
                  'pp_pill_compass',
                  min(w * 0.78, 300 * s),
                  0.2,
                  Text(ppT(context, 'stampsOf', {'n': _p.stamps, 'm': ppStages.length}), style: ppText(14 * s)),
                  area: const EdgeInsets.fromLTRB(0.14, 0.12, 0.14, 0.16),
                ),
                SizedBox(height: 4 * s),
                Expanded(child: _book(s, w)),
                // pages
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Opacity(opacity: _page > 0 ? 1 : 0.4, child: ppRound(context, 'pp_prev', 40 * s, () => _turn(-1), flipRtl: true)),
                  SizedBox(width: 10 * s),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 4 * s),
                    decoration: BoxDecoration(color: ppCream, borderRadius: BorderRadius.circular(14 * s)),
                    child: Text('${_page + 1} / $_pages', style: ppText(15 * s)),
                  ),
                  SizedBox(width: 10 * s),
                  Opacity(opacity: _page < _pages - 1 ? 1 : 0.4, child: ppRound(context, 'pp_next', 40 * s, () => _turn(1), flipRtl: true)),
                ]),
                SizedBox(height: 6 * s),
                _detail(s, w, st),
                SizedBox(height: 6 * s),
                PpButton.main(ppT(context, 'continueTrip'), () async {
                  ppSound(context, 'PopButton');
                  await Navigator.of(context).pushReplacement(ppRoute(const DestinationsPage()));
                }, min(w * 0.76, 300 * s), pulse: _idle),
                SizedBox(height: 8 * s),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _book(double s, double w) => LayoutBuilder(builder: (_, c) {
        final bw = min(c.maxWidth - 10 * s, c.maxHeight / 0.7446);
        final bh = bw * 0.7446;
        final list = ppStages.skip(_page * _perPage).take(_perPage).toList();
        const xs = [0.31, 0.69];
        const ys = [0.255, 0.525, 0.79];
        final sw = bw * 0.25, sh = bh * 0.19;
        return Center(
          child: AnimatedBuilder(
            animation: _flip,
            builder: (_, ch) => Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015)
                ..rotateY((1 - Curves.easeOutBack.transform(_flip.value)) * 0.6),
              child: ch,
            ),
            child: SizedBox(
              width: bw,
              height: bh,
              child: Stack(clipBehavior: Clip.none, children: [
                Positioned.fill(child: Image.asset(pp('pp_book6'), fit: BoxFit.fill)),
                for (var i = 0; i < list.length; i++)
                  Positioned(
                    left: bw * xs[i ~/ 3] - sw / 2,
                    top: bh * ys[i % 3] - sh / 2,
                    width: sw,
                    height: sh,
                    child: _slot(list[i], sw, sh, s),
                  ),
              ]),
            ),
          ),
        );
      });

  Widget _slot(PpStage st, double sw, double sh, double s) {
    final done = _p.done(st.id);
    final sel = _sel == st.id;
    final isNew = done && _p.newest == st.id;
    return PpPress(
      onTap: () => _tap(st),
      label: done ? st.title(context) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10 * s),
          border: Border.all(color: sel ? const Color(0xFF39D2FF) : Colors.transparent, width: 3 * s),
          boxShadow: sel ? [BoxShadow(color: const Color(0xFF39D2FF).withOpacity(0.6), blurRadius: 10 * s)] : null,
        ),
        child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
          if (done)
            Row(children: [
              SizedBox(width: 3 * s),
              // small photo
              Expanded(
                flex: 5,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: sh * 0.12),
                  child: Container(
                    padding: EdgeInsets.all(2 * s),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5 * s), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)]),
                    child: ClipRRect(borderRadius: BorderRadius.circular(4 * s), child: Image.asset(st.scene, fit: BoxFit.cover, width: double.infinity, height: double.infinity)),
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  PpStamp(stage: st, size: sh * 0.62),
                  FittedBox(fit: BoxFit.scaleDown, child: Text(st.city(context), style: ppText(10 * s))),
                ]),
              ),
            ])
          else
            Opacity(
              opacity: 0.6,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Image.asset(pp('pp_lock'), height: sh * 0.42),
                FittedBox(fit: BoxFit.scaleDown, child: Text('?', style: ppText(12 * s, color: ppInkSoft))),
              ]),
            ),
          if (isNew)
            Positioned(
              left: -8 * s,
              top: -10 * s,
              child: AnimatedBuilder(
                animation: _idle,
                builder: (_, c) => Transform.rotate(angle: -0.2 + sin(_idle.value * 2 * pi * 3) * 0.05, child: c),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6 * s, vertical: 2 * s),
                  decoration: BoxDecoration(color: ppRed, borderRadius: BorderRadius.circular(8 * s), border: Border.all(color: Colors.white, width: 1.5 * s)),
                  child: Text(ppT(context, 'new'), style: ppText(10 * s, color: Colors.white)),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _detail(double s, double w, PpStage st) {
    final done = _p.done(st.id);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10 * s),
      padding: EdgeInsets.all(8 * s),
      decoration: BoxDecoration(
        color: ppCream,
        borderRadius: BorderRadius.circular(22 * s),
        border: Border.all(color: const Color(0xFFF1D7A6), width: 3 * s),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10 * s, offset: Offset(0, 4 * s))],
      ),
      child: Row(children: [
        Image.asset(pp('pp_robot_point'), height: 84 * s),
        SizedBox(width: 4 * s),
        Container(
          width: 84 * s,
          height: 84 * s,
          padding: EdgeInsets.all(3 * s),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12 * s), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)]),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9 * s),
            child: done
                ? Image.asset(st.scene, fit: BoxFit.cover)
                : ColorFiltered(colorFilter: const ColorFilter.mode(Color(0xFFBDB6A6), BlendMode.saturation), child: Image.asset(st.scene, fit: BoxFit.cover)),
          ),
        ),
        SizedBox(width: 8 * s),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Column(key: ValueKey(st.id), crossAxisAlignment: CrossAxisAlignment.start, children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text('${st.city(context)} · ${st.title(context)}', style: ppText(15 * s, weight: FontWeight.w800)),
              ),
              Text(done ? st.fact(context) : ppT(context, 'emptyStamp'),
                  maxLines: 2, style: ppText(11.5 * s, color: ppInkSoft, weight: FontWeight.w600, height: 1.15)),
              SizedBox(height: 4 * s),
              Row(children: [
                Flexible(
                  child: PpPill(
                    label: ppT(context, 'listenDisc'),
                    icon: Image.asset(pp('pp_sound'), height: 18 * s),
                    onTap: () => PpVoice.say(context, done ? '${st.title(context)}. ${st.fact(context)}' : ppT(context, 'emptyStamp')),
                    s: s * 0.8,
                    border: const Color(0xFF2B3FA8),
                    font: 14,
                  ),
                ),
                if (done) ...[
                  SizedBox(width: 4 * s),
                  PpPress(
                    onTap: () {
                      ppSound(context, 'clickButton');
                      ppDialog(context, _PostcardDialog(stage: st), dismissible: true);
                    },
                    label: ppT(context, 'seePostcard'),
                    child: Image.asset(pp('pp_btn_photo'), height: 32 * s),
                  ),
                ],
              ]),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _PostcardDialog extends StatelessWidget {
  final PpStage stage;
  const _PostcardDialog({required this.stage});
  @override
  Widget build(BuildContext context) => PpFrame(child: Builder(builder: _page));
  Widget _page(BuildContext context) {
    final s = ppScale(context);
    final w = min(MediaQuery.sizeOf(context).width - 40, 420.0);
    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Transform.rotate(
            angle: -0.03,
            child: Stack(clipBehavior: Clip.none, children: [
              PpPhoto(stage: stage, width: w, radius: 16 * s, border: 8 * s),
              Positioned(right: -10 * s, bottom: -16 * s, child: PpStamp(stage: stage, size: w * 0.3)),
            ]),
          ),
          SizedBox(height: 22 * s),
          Text(stage.title(context), style: ppText(22 * s, color: Colors.white, weight: FontWeight.w800)),
          SizedBox(height: 10 * s),
          ppRound(context, 'pp_ic_close', 54 * s, () => Navigator.pop(context)),
        ]),
      ),
    );
  }
}
