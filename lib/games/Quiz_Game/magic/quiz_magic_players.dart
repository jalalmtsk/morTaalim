import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../tools/audio_tool/Audio_Manager.dart';
import '../../../widgets/KidScene/kid_page_parts.dart';
import '../../../widgets/KidScene/kid_scene.dart';
import '../ModeSelectorPage.dart';
import 'quiz_magic_data.dart';
import 'quiz_magic_duel.dart';
import 'quiz_magic_widgets.dart';

/// "Jouer avec un ami": names, avatars, theme and level for a duel on one screen.
class QuizMagicPlayersPage extends StatefulWidget {
  final QuizLanguage language;
  final String theme;
  const QuizMagicPlayersPage({super.key, required this.language, required this.theme});

  @override
  State<QuizMagicPlayersPage> createState() => _QuizMagicPlayersPageState();
}

class _QuizMagicPlayersPageState extends State<QuizMagicPlayersPage> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  late final TextEditingController _n1 = TextEditingController(text: QmPrefs.name(1));
  late final TextEditingController _n2 = TextEditingController(text: QmPrefs.name(2));
  late String _a1 = QmPrefs.avatar(1);
  late String _a2 = QmPrefs.avatar(2);
  late String _theme = widget.theme;
  int _level = QmPrefs.friendLevel.clamp(0, 2);

  String get _ui => qmUiLang(widget.language);
  AudioManager get _audio => Provider.of<AudioManager>(context, listen: false);

  @override
  void dispose() {
    _intro.dispose();
    _idle.dispose();
    _n1.dispose();
    _n2.dispose();
    super.dispose();
  }

  String _name(int p) {
    final t = (p == 1 ? _n1 : _n2).text.trim();
    return t.isEmpty ? qmText(_ui, 'player', a: '$p') : t;
  }

  void _start() {
    _audio.playEventSound('clickButton');
    QmPrefs.setName(1, _n1.text.trim());
    QmPrefs.setName(2, _n2.text.trim());
    QmPrefs.setAvatar(1, _a1);
    QmPrefs.setAvatar(2, _a2);
    QmPrefs.friendLevel = _level;
    QmPrefs.theme = _theme;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (_, __, ___) => QuizMagicDuelPage(
        language: widget.language,
        theme: _theme,
        players: [QmPlayer(_name(1), _a1), QmPlayer(_name(2), _a2)],
        robotLevel: 0,
        choices: 4,
      ),
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
    ));
  }

  Future<void> _pickTheme(double s) async {
    _audio.playEventSound('clickButton');
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Directionality(
        textDirection: widget.language == QuizLanguage.arabic ? TextDirection.rtl : TextDirection.ltr,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
          decoration: const BoxDecoration(
            color: qmCream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: qmGold, width: 3)),
          ),
          child: SafeArea(
            top: false,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(qmText(_ui, 'chooseTheme'), style: qmTitle(22, color: qmPurple)),
              const SizedBox(height: 10),
              LayoutBuilder(builder: (context, c) {
                final tw = (c.maxWidth - 8) / 2;
                return Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final t in qmThemes)
                    SizedBox(
                      width: tw,
                      child: QmThemeTile(
                        scale: 1,
                        theme: t,
                        lang: _ui,
                        selected: t.id == _theme,
                        onTap: () => Navigator.of(ctx).pop(t.id),
                      ),
                    ),
                ]);
              }),
            ]),
          ),
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _theme = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.language == QuizLanguage.arabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: KidColors.sky,
        resizeToAvoidBottomInset: true,
        body: Stack(children: [
          const Positioned.fill(child: KidPageBackground(asset: qmImgBg, wash: 0)),
          SafeArea(child: LayoutBuilder(builder: (context, c) => _layout(c))),
        ]),
      ),
    );
  }

  Widget _layout(BoxConstraints c) {
    final w = min(c.maxWidth, 560.0);
    final s = min(w / 380, c.maxHeight / 760).clamp(0.7, 1.3).toDouble();
    Widget step(int i, Widget child) =>
        KidIntro(intro: _intro, from: 0.07 * i, to: min(1.0, 0.45 + 0.07 * i), rise: 18, child: child);
    return Stack(children: [
      PositionedDirectional(start: -12 * s, bottom: -8 * s, child: IgnorePointer(child: Image.asset(qmImgBush1, width: 110 * s))),
      Center(
        child: SizedBox(
          width: w,
          child: Column(children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12 * s),
              child: step(0, QmTopBar(
                scale: s,
                title: qmText(_ui, 'title'),
                onBack: () {
                  _audio.playEventSound('cancelButton');
                  Navigator.of(context).pop();
                },
                onGear: () => qmOpenSettings(context, language: widget.language),
              )),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(12 * s, 6 * s, 12 * s, 10 * s),
                child: Column(children: [
                  step(1, _heading(s)),
                  SizedBox(height: 10 * s),
                  step(2, _playerCards(s)),
                  SizedBox(height: 6 * s),
                  step(3, _duelSection(s)),
                  SizedBox(height: 10 * s),
                  step(4, _tip(s)),
                ]),
              ),
            ),
            step(5, KidButton(label: qmText(_ui, 'startDuel'), onPressed: _start, width: 310 * s, height: 58 * s)),
            SizedBox(height: 4 * s),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Image.asset(qmImgStar, width: 16 * s),
              SizedBox(width: 6 * s),
              Text(qmText(_ui, 'onePoint'), style: qmTitle(13.5 * s)),
              SizedBox(width: 6 * s),
              Image.asset(qmImgStar, width: 16 * s),
            ]),
            SizedBox(height: 8 * s),
          ]),
        ),
      ),
    ]);
  }

  Widget _heading(double s) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 8 * s),
      decoration: qmCard(s, radius: 30),
      child: Row(children: [
        Image.asset(qmImgBigStar, width: 30 * s),
        Expanded(
          child: Column(children: [
            FittedBox(fit: BoxFit.scaleDown, child: Text(qmText(_ui, 'playWithFriend'), style: qmTitle(26 * s, color: qmPurple))),
            Text(qmText(_ui, 'sameScreen'), textAlign: TextAlign.center, style: qmTitle(14 * s)),
          ]),
        ),
        Image.asset(qmImgBigStar, width: 30 * s),
      ]),
    );
  }

  Widget _playerCards(double s) {
    return Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: _playerCard(s, 1)),
        SizedBox(width: 10 * s),
        Expanded(child: _playerCard(s, 2)),
      ]),
      Positioned(
        top: 96 * s,
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _idle,
            builder: (_, ch) => Transform.scale(scale: 1 + sin(_idle.value * 4 * pi) * 0.05, child: ch),
            child: QmOutlinedText('VS', size: 34 * s, stroke: const Color(0xFF6A1FB8), gradient: const [Color(0xFFFFF27A), Color(0xFFFFA51F)]),
          ),
        ),
      ),
    ]);
  }

  Widget _playerCard(double s, int p) {
    final blue = p == 1;
    final main = blue ? const Color(0xFF29B6F6) : const Color(0xFFF06BC6);
    final fill = blue ? const Color(0xFFE8F7FF) : const Color(0xFFFFEDF8);
    final ctrl = blue ? _n1 : _n2;
    final avatar = blue ? _a1 : _a2;
    return Container(
      padding: EdgeInsets.fromLTRB(8 * s, 8 * s, 8 * s, 10 * s),
      decoration: qmCard(s, border: main, fill: fill, radius: 22, glow: main),
      child: Column(children: [
        Container(
          height: 32 * s,
          decoration: BoxDecoration(
            color: qmCream,
            borderRadius: BorderRadius.circular(16 * s),
            border: Border.all(color: main.withOpacity(0.5), width: 1.5 * s),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Image.asset(blue ? qmImgPersonBlue : qmImgPersonPink, height: 20 * s),
            SizedBox(width: 6 * s),
            Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(qmText(_ui, 'player', a: '$p'), style: qmTitle(17 * s)))),
          ]),
        ),
        SizedBox(height: 8 * s),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: c),
          child: QmAvatar(key: ValueKey(avatar), avatar: avatar, size: 104 * s, ring: main),
        ),
        SizedBox(height: 6 * s),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(qmText(_ui, 'firstName'), style: kidBodyStyle(12.5 * s, color: qmPurple, weight: FontWeight.w700)),
        ),
        SizedBox(height: 2 * s),
        Container(
          height: 38 * s,
          padding: EdgeInsetsDirectional.only(start: 10 * s, end: 4 * s),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20 * s),
            border: Border.all(color: main, width: 1.8 * s),
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                maxLength: 12,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.words,
                style: qmTitle(18 * s),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  isCollapsed: true,
                  counterText: '',
                  border: InputBorder.none,
                  hintText: qmText(_ui, 'player', a: '$p'),
                  hintStyle: qmTitle(16 * s, color: qmInk.withOpacity(0.35)),
                ),
              ),
            ),
            Container(
              width: 28 * s,
              height: 28 * s,
              decoration: BoxDecoration(shape: BoxShape.circle, color: main),
              child: Icon(Icons.edit_rounded, color: Colors.white, size: 16 * s),
            ),
          ]),
        ),
        SizedBox(height: 8 * s),
        FittedBox(fit: BoxFit.scaleDown, child: Text(qmText(_ui, 'chooseAvatar'), style: qmTitle(13.5 * s))),
        SizedBox(height: 6 * s),
        LayoutBuilder(builder: (context, c) {
          final d = (c.maxWidth - 8 * s) / 3;
          return Wrap(spacing: 4 * s, runSpacing: 4 * s, children: [
            for (final a in qmAvatars)
              KidPressable(
                onTap: () {
                  _audio.playEventSound('clickButton');
                  setState(() {
                    if (blue) {
                      _a1 = a;
                    } else {
                      _a2 = a;
                    }
                  });
                },
                child: SizedBox(
                  width: d,
                  height: d,
                  child: Stack(clipBehavior: Clip.none, children: [
                    Positioned.fill(
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 200),
                        scale: a == avatar ? 1.0 : 0.88,
                        child: QmAvatar(avatar: a, size: d, ring: a == avatar ? qmGreen : null),
                      ),
                    ),
                    if (a == avatar) PositionedDirectional(end: -2 * s, top: -4 * s, child: QmCheck(size: 22 * s)),
                  ]),
                ),
              ),
          ]);
        }),
      ]),
    );
  }

  Widget _duelSection(double s) {
    final theme = qmTheme(_theme);
    return QmSection(
      scale: s,
      title: qmText(_ui, 'theDuel'),
      child: Column(children: [
        KidPressable(
          onTap: () => _pickTheme(s),
          child: Container(
            height: 46 * s,
            padding: EdgeInsetsDirectional.only(start: 6 * s, end: 12 * s),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(24 * s),
              border: Border.all(color: const Color(0xFFF1D9A8), width: 2 * s),
            ),
            child: Row(children: [
              QmCategoryIcon(category: qmThemeCategory(theme), size: 36 * s),
              SizedBox(width: 10 * s),
              Expanded(child: Text(qmThemeName(theme, _ui), style: qmTitle(18 * s))),
              Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                  color: qmPurple, size: 28 * s),
            ]),
          ),
        ),
        SizedBox(height: 8 * s),
        Row(children: [
          for (var i = 0; i < 3; i++) ...[
            Expanded(
              child: QmLevelChip(
                scale: s,
                level: i,
                label: qmText(_ui, qmLevelKeys[i]),
                selected: _level == i,
                onTap: () {
                  _audio.playEventSound('clickButton');
                  setState(() => _level = i);
                },
              ),
            ),
            if (i < 2) SizedBox(width: 6 * s),
          ],
        ]),
        SizedBox(height: 8 * s),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 5 * s),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(18 * s),
            border: Border.all(color: const Color(0xFFF1D9A8), width: 1.5 * s),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.shuffle_rounded, color: qmPurple, size: 18 * s),
            SizedBox(width: 6 * s),
            Text(qmText(_ui, 'roundsInfo', a: '10', b: '5'), style: qmTitle(14 * s)),
          ]),
        ),
      ]),
    );
  }

  Widget _tip(double s) {
    return SizedBox(
      height: 96 * s,
      child: Stack(clipBehavior: Clip.none, children: [
        PositionedDirectional(
          start: 0,
          end: 70 * s,
          top: 8 * s,
          bottom: 0,
          child: Container(
            padding: EdgeInsetsDirectional.fromSTEB(8 * s, 6 * s, 30 * s, 6 * s),
            decoration: qmCard(s, radius: 22),
            child: Row(children: [
              Image.asset(qmImgHandsTablet, width: 92 * s),
              SizedBox(width: 8 * s),
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  FittedBox(fit: BoxFit.scaleDown, child: Text(qmText(_ui, 'eachTurn'), style: qmTitle(17 * s, color: qmPurple))),
                  Text(qmText(_ui, 'passDevice'), style: kidBodyStyle(12 * s, color: qmInk, weight: FontWeight.w600)),
                ]),
              ),
            ]),
          ),
        ),
        PositionedDirectional(
          end: -4 * s,
          bottom: -6 * s,
          child: AnimatedBuilder(
            animation: _idle,
            builder: (_, ch) => Transform.translate(offset: Offset(0, sin(_idle.value * 2 * pi) * 3 * s), child: ch),
            child: Image.asset(qmImgRobotPoint, height: 110 * s),
          ),
        ),
      ]),
    );
  }
}
