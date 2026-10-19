import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../tools/audio_tool/Audio_Manager.dart';
import '../../../widgets/KidScene/kid_page_parts.dart';
import '../../../widgets/KidScene/kid_scene.dart';
import '../ModeSelectorPage.dart';
import 'quiz_magic_data.dart';
import 'quiz_magic_duel.dart';
import 'quiz_magic_page.dart';
import 'quiz_magic_players.dart';
import 'quiz_magic_widgets.dart';

/// "Menu des quiz": Solo or Duel, opponent, robot level and theme.
class QuizMagicMenuPage extends StatefulWidget {
  const QuizMagicMenuPage({super.key});

  @override
  State<QuizMagicMenuPage> createState() => _QuizMagicMenuPageState();
}

class _QuizMagicMenuPageState extends State<QuizMagicMenuPage> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();

  bool _ready = false;
  bool _precached = false;
  QuizLanguage _lang = QuizLanguage.french;
  bool _duel = false;
  bool _vsRobot = true;
  int _robotLevel = 0;
  String _theme = 'animals';

  String get _ui => qmUiLang(_lang);
  AudioManager get _audio => Provider.of<AudioManager>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    KidAssets.precache(context, [
      ...qmAllImages,
      for (final t in qmThemes) t.image,
      for (final a in qmAvatars) qmAvatarAsset(a),
    ]);
  }

  Future<void> _load() async {
    await QmPrefs.init();
    await QmAssets.load();
    if (!mounted) return;
    final saved = QmPrefs.language;
    setState(() {
      _lang = saved != null ? qmLanguageFromCode(saved) : qmLanguageFromCode(Localizations.localeOf(context).languageCode);
      _duel = QmPrefs.duel;
      _vsRobot = QmPrefs.vsRobot;
      _robotLevel = QmPrefs.robotLevel.clamp(0, 2);
      _theme = QmPrefs.theme;
      _ready = true;
    });
    _intro.forward(from: 0);
  }

  @override
  void dispose() {
    _intro.dispose();
    _idle.dispose();
    super.dispose();
  }

  void _tap() => _audio.playEventSound('clickButton');

  void _start() {
    _audio.playEventSound('clickButton');
    Widget page;
    if (!_duel) {
      page = QuizMagicPage(language: _lang, theme: _theme);
    } else if (_vsRobot) {
      page = QuizMagicDuelPage(
        language: _lang,
        theme: _theme,
        players: [
          QmPlayer(QmPrefs.name(1).isEmpty ? qmText(_ui, 'you') : QmPrefs.name(1), QmPrefs.avatar(1)),
          QmPlayer(qmText(_ui, 'robotName'), 'robot', robot: true),
        ],
        robotLevel: _robotLevel,
        choices: 4,
      );
    } else {
      page = QuizMagicPlayersPage(language: _lang, theme: _theme);
    }
    Navigator.of(context).push(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _lang == QuizLanguage.arabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: KidColors.sky,
        body: Stack(children: [
          const Positioned.fill(child: KidPageBackground(asset: qmImgBg, wash: 0)),
          SafeArea(
            child: !_ready
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : LayoutBuilder(builder: (context, c) => _layout(c)),
          ),
        ]),
      ),
    );
  }

  Widget _layout(BoxConstraints c) {
    final w = min(c.maxWidth, 560.0);
    final s = min(w / 380, c.maxHeight / 760).clamp(0.7, 1.3).toDouble();
    Widget step(int i, Widget child) =>
        KidIntro(intro: _intro, from: 0.07 * i, to: min(1.0, 0.45 + 0.07 * i), rise: 18, child: child);
    final theme = qmTheme(_theme);

    return Stack(children: [
      PositionedDirectional(start: -12 * s, bottom: -8 * s, child: IgnorePointer(child: Image.asset(qmImgBush1, width: 110 * s))),
      PositionedDirectional(end: -10 * s, bottom: -8 * s, child: IgnorePointer(child: Image.asset(qmImgFlowers, width: 100 * s))),
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
                onGear: () => qmOpenSettings(context, language: _lang, onLanguage: (l) {
                  setState(() => _lang = l);
                  QmPrefs.language = qmLang(l);
                }),
              )),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(14 * s, 6 * s, 14 * s, 10 * s),
                child: Column(children: [
                  step(1, _modeRow(s)),
                  if (_duel) ...[
                    SizedBox(height: 6 * s),
                    step(2, _opponentSection(s)),
                  ],
                  SizedBox(height: 6 * s),
                  step(3, _themeSection(s)),
                  SizedBox(height: 10 * s),
                  step(4, _summary(s, theme)),
                ]),
              ),
            ),
            step(5, KidButton(
              label: qmText(_ui, _duel ? 'startDuel' : 'startQuiz'),
              onPressed: _start,
              width: 310 * s,
              height: 58 * s,
            )),
            SizedBox(height: 4 * s),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Image.asset(qmImgStar, width: 16 * s),
              SizedBox(width: 6 * s),
              Flexible(
                child: Text(qmText(_ui, _duel ? 'turnHint' : 'soloHint'),
                    textAlign: TextAlign.center, style: qmTitle(13.5 * s)),
              ),
              SizedBox(width: 6 * s),
              Image.asset(qmImgStar, width: 16 * s),
            ]),
            SizedBox(height: 8 * s),
          ]),
        ),
      ),
    ]);
  }

  // Solo | Duel à 2 toggle with the explorer robot peeking on the side
  Widget _modeRow(double s) {
    Widget seg(bool duel, IconData icon, String label) {
      final on = _duel == duel;
      return Expanded(
        child: KidPressable(
          onTap: () {
            _tap();
            setState(() => _duel = duel);
            QmPrefs.duel = duel;
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 50 * s,
            decoration: BoxDecoration(
              gradient: on ? const LinearGradient(colors: [Color(0xFF9C4DFF), Color(0xFF6A1FD6)]) : null,
              borderRadius: BorderRadius.circular(26 * s),
              border: on ? Border.all(color: qmGold, width: 2.5 * s) : null,
              boxShadow: on ? [BoxShadow(color: qmPurple.withOpacity(0.4), blurRadius: 10 * s, offset: Offset(0, 3 * s))] : null,
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 26 * s, color: on ? Colors.white : qmPurple),
              SizedBox(width: 6 * s),
              Flexible(
                child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: qmTitle(20 * s, color: on ? Colors.white : qmInk))),
              ),
            ]),
          ),
        ),
      );
    }

    return SizedBox(
      height: 92 * s,
      child: Stack(clipBehavior: Clip.none, children: [
        PositionedDirectional(
          start: 0,
          end: 92 * s,
          bottom: 4 * s,
          child: Container(
            padding: EdgeInsets.all(4 * s),
            decoration: BoxDecoration(
              color: qmCream,
              borderRadius: BorderRadius.circular(30 * s),
              border: Border.all(color: qmGold, width: 2.5 * s),
              boxShadow: [BoxShadow(color: qmPurple.withOpacity(0.18), blurRadius: 10 * s, offset: Offset(0, 4 * s))],
            ),
            child: Row(children: [
              seg(false, Icons.person_rounded, qmText(_ui, 'solo')),
              seg(true, Icons.people_alt_rounded, qmText(_ui, 'duel')),
            ]),
          ),
        ),
        PositionedDirectional(
          end: -6 * s,
          top: -6 * s,
          child: AnimatedBuilder(
            animation: _idle,
            builder: (_, ch) => Transform.translate(
              offset: Offset(0, sin(_idle.value * 2 * pi) * 3 * s),
              child: Transform.rotate(angle: sin(_idle.value * 4 * pi) * 0.04, child: ch),
            ),
            child: Image.asset(qmImgRobotLens, height: 100 * s),
          ),
        ),
      ]),
    );
  }

  Widget _opponentSection(double s) {
    Widget tile(bool robot) {
      final on = _vsRobot == robot;
      return Expanded(
        child: KidPressable(
          onTap: () {
            _tap();
            setState(() => _vsRobot = robot);
            QmPrefs.vsRobot = robot;
          },
          pressedScale: 0.95,
          child: Stack(clipBehavior: Clip.none, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: EdgeInsets.all(6 * s),
              decoration: qmCard(s, border: on ? qmGreen : const Color(0xFFB79BEA), radius: 20, glow: on ? qmGreen : null),
              child: Column(children: [
                Container(
                  height: 92 * s,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14 * s),
                    gradient: const LinearGradient(colors: [Color(0xFFD9F1FF), Color(0xFFF7E8FF)]),
                  ),
                  alignment: Alignment.center,
                  child: robot
                      ? Image.asset(qmImgAvRobot, height: 88 * s)
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          QmAvatar(avatar: 'boy', size: 62 * s),
                          Text('VS', style: qmTitle(18 * s, color: const Color(0xFFFF9A1F))),
                          QmAvatar(avatar: 'girl', size: 62 * s),
                        ]),
                ),
                SizedBox(height: 4 * s),
                FittedBox(fit: BoxFit.scaleDown, child: Text(qmText(_ui, robot ? 'robot' : 'friend'), style: qmTitle(19 * s))),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(qmText(_ui, robot ? 'robotSub' : 'friendSub'),
                      style: kidBodyStyle(12.5 * s, color: const Color(0xFF6B4FA8), weight: FontWeight.w600)),
                ),
              ]),
            ),
            if (on) PositionedDirectional(end: -6 * s, top: -8 * s, child: QmCheck(size: 34 * s)),
          ]),
        ),
      );
    }

    return QmSection(
      scale: s,
      title: qmText(_ui, 'chooseOpponent'),
      child: Column(children: [
        Row(children: [tile(false), SizedBox(width: 10 * s), tile(true)]),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          child: !_vsRobot
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: EdgeInsets.only(top: 10 * s),
                  child: Row(children: [
                    Flexible(
                      flex: 5,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(qmText(_ui, 'robotLevel'), style: qmTitle(14 * s)),
                      ),
                    ),
                    SizedBox(width: 6 * s),
                    for (var i = 0; i < 3; i++) ...[
                      Expanded(
                        flex: 5,
                        child: QmLevelChip(
                          scale: s,
                          level: i,
                          label: qmText(_ui, qmLevelKeys[i]),
                          selected: _robotLevel == i,
                          onTap: () {
                            _tap();
                            setState(() => _robotLevel = i);
                            QmPrefs.robotLevel = i;
                          },
                        ),
                      ),
                      if (i < 2) SizedBox(width: 5 * s),
                    ],
                  ]),
                ),
        ),
      ]),
    );
  }

  Widget _themeSection(double s) {
    return QmSection(
      scale: s,
      title: qmText(_ui, 'chooseTheme'),
      child: LayoutBuilder(builder: (context, c) {
        final gap = 8 * s;
        final tw = (c.maxWidth - gap) / 2;
        return Wrap(spacing: gap, runSpacing: gap, children: [
          for (final t in qmThemes)
            SizedBox(
              width: tw,
              child: QmThemeTile(
                scale: s,
                theme: t,
                lang: _ui,
                selected: _theme == t.id,
                onTap: () {
                  _tap();
                  setState(() => _theme = t.id);
                  QmPrefs.theme = t.id;
                },
              ),
            ),
        ]);
      }),
    );
  }

  Widget _summary(double s, QmTheme theme) {
    final me = QmPrefs.name(1).isEmpty ? qmText(_ui, 'you') : QmPrefs.name(1);
    Widget who(String avatar, String name) => Row(mainAxisSize: MainAxisSize.min, children: [
          QmAvatar(avatar: avatar, size: 46 * s),
          SizedBox(width: 6 * s),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 90 * s),
            child: FittedBox(fit: BoxFit.scaleDown, child: Text(name, style: qmTitle(18 * s))),
          ),
        ]);
    return Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
      Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 14 * s),
        padding: EdgeInsets.fromLTRB(12 * s, 8 * s, 12 * s, 18 * s),
        decoration: qmCard(s, radius: 26),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          who(QmPrefs.avatar(1), me),
          if (_duel) ...[
            SizedBox(width: 8 * s),
            QmOutlinedText('VS', size: 24 * s, stroke: const Color(0xFF6A1FB8), gradient: const [Color(0xFFFFF27A), Color(0xFFFFA51F)]),
            SizedBox(width: 8 * s),
            _vsRobot ? who('robot', qmText(_ui, 'robotName')) : who(QmPrefs.avatar(2), QmPrefs.name(2).isEmpty ? '?' : QmPrefs.name(2)),
          ],
        ]),
      ),
      Positioned(
        bottom: 0,
        child: Container(
          padding: EdgeInsetsDirectional.fromSTEB(4 * s, 3 * s, 12 * s, 3 * s),
          decoration: BoxDecoration(
            color: qmCream,
            borderRadius: BorderRadius.circular(18 * s),
            border: Border.all(color: const Color(0xFFF1D9A8), width: 2 * s),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            QmCategoryIcon(category: qmThemeCategory(theme), size: 24 * s),
            SizedBox(width: 6 * s),
            Text('${qmThemeName(theme, _ui)} · ${qmText(_ui, 'questionsN', a: '10')}', style: qmTitle(13.5 * s)),
          ]),
        ),
      ),
    ]);
  }
}
