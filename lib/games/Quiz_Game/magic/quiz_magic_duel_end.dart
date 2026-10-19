import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../XpSystem.dart';
import '../../../tools/audio_tool/Audio_Manager.dart';
import '../../../widgets/KidScene/kid_page_parts.dart';
import '../../../widgets/KidScene/kid_scene.dart';
import '../ModeSelectorPage.dart';
import 'quiz_magic_data.dart';
import 'quiz_magic_duel.dart';
import 'quiz_magic_results.dart';
import 'quiz_magic_widgets.dart';

/// End of a duel: the winner on the podium, final score, rematch.
class QuizMagicDuelEndPage extends StatefulWidget {
  final QuizLanguage language;
  final String theme;
  final List<QmPlayer> players;
  final int robotLevel;
  final int choices;
  final List<QmItem> items;
  const QuizMagicDuelEndPage({
    super.key,
    required this.language,
    required this.theme,
    required this.players,
    required this.robotLevel,
    required this.choices,
    required this.items,
  });

  @override
  State<QuizMagicDuelEndPage> createState() => _QuizMagicDuelEndPageState();
}

class _QuizMagicDuelEndPageState extends State<QuizMagicDuelEndPage> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  final ConfettiController _confetti = ConfettiController(duration: const Duration(seconds: 2));

  late final List<int> _scores = [_score(0), _score(1)];
  late final int? _winner = _scores[0] == _scores[1] ? null : (_scores[0] > _scores[1] ? 0 : 1);
  late final bool _vsRobot = widget.players.any((p) => p.robot);

  String get _ui => qmUiLang(widget.language);
  AudioManager get _audio => Provider.of<AudioManager>(context, listen: false);

  int _score(int p) {
    var n = 0;
    for (var i = p; i < widget.items.length; i += 2) {
      if (widget.items[i].correct) n++;
    }
    return n;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reward());
  }

  void _reward() {
    if (!mounted) return;
    final xp = Provider.of<ExperienceManager>(context, listen: false);
    final humanWon = _winner != null && !widget.players[_winner!].robot;
    if (humanWon || _winner == null) {
      _confetti.play();
      _audio.playSfx('assets/audios/UI_Audio/SFX_Audio/CorrectAnwser_SFX.mp3');
    }
    // rewards go to the device owner: total right answers (+ bonus for beating the robot)
    final humanGood = [for (var p = 0; p < 2; p++) if (!widget.players[p].robot) _scores[p]].fold<int>(0, (a, b) => a + b);
    final gold = humanGood * 2 + (_vsRobot && humanWon ? 5 + widget.robotLevel * 5 : 0);
    if (gold > 0) xp.addGold(context, gold);
    xp.addXP(humanGood * 2 + 2, context: context);
  }

  @override
  void dispose() {
    _intro.dispose();
    _idle.dispose();
    _confetti.dispose();
    super.dispose();
  }

  void _rematch() {
    _audio.playEventSound('clickButton');
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => QuizMagicDuelPage(
        language: widget.language,
        theme: widget.theme,
        // the other player starts the rematch
        players: [widget.players[1], widget.players[0]].any((p) => p.robot) ? widget.players : [widget.players[1], widget.players[0]],
        robotLevel: widget.robotLevel,
        choices: widget.choices,
      ),
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
    ));
  }

  void _review() {
    _audio.playEventSound('clickButton');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Directionality(
        textDirection: widget.language == QuizLanguage.arabic ? TextDirection.rtl : TextDirection.ltr,
        child: QmReviewSheet(
          items: widget.items,
          lang: _ui,
          owners: [for (var i = 0; i < widget.items.length; i++) widget.players[i % 2].name],
        ),
      ),
    );
  }

  void _menu() {
    _audio.playEventSound('cancelButton');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.language == QuizLanguage.arabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: KidColors.sky,
        body: Stack(children: [
          const Positioned.fill(child: KidPageBackground(asset: qmImgBg, wash: 0)),
          SafeArea(child: LayoutBuilder(builder: (context, c) => _layout(c))),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 34,
              emissionFrequency: 0.05,
              gravity: 0.22,
              colors: const [Color(0xFF2FE3F0), Color(0xFF3CC85A), Color(0xFFFFC21A), Color(0xFFFF5FA8), Color(0xFF7B3FE4)],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _layout(BoxConstraints c) {
    final w = min(c.maxWidth, 560.0);
    final s = min(w / 380, c.maxHeight / 800).clamp(0.6, 1.3).toDouble();
    Widget step(int i, Widget child) =>
        KidIntro(intro: _intro, from: 0.07 * i, to: min(1.0, 0.4 + 0.07 * i), rise: 22, child: child);
    return Stack(children: [
      PositionedDirectional(start: -12 * s, bottom: -8 * s, child: IgnorePointer(child: Image.asset(qmImgBush1, width: 110 * s))),
      PositionedDirectional(end: -10 * s, bottom: -8 * s, child: IgnorePointer(child: Image.asset(qmImgFlowers, width: 100 * s))),
      Center(
        child: SizedBox(
          width: w,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14 * s),
            child: Column(children: [
              step(0, QmTopBar(scale: s, title: qmText(_ui, 'title'), subtitle: qmText(_ui, 'duel1v1'), onBack: _menu)),
              SizedBox(height: 14 * s),
              step(1, _heading(s)),
              Expanded(child: step(2, _podium(s))),
              step(3, _scoreCard(s)),
              SizedBox(height: 8 * s),
              step(4, _together(s)),
              SizedBox(height: 10 * s),
              step(5, KidButton(label: qmText(_ui, 'rematch'), onPressed: _rematch, width: 300 * s, height: 54 * s, showArrow: false)),
              SizedBox(height: 8 * s),
              step(6, _pillButton(s, qmImgBook, qmText(_ui, 'reviewAll'), _review, 290)),
              SizedBox(height: 6 * s),
              step(7, _pillButton(s, qmImgHome, qmText(_ui, 'menu'), _menu, 220)),
              SizedBox(height: 8 * s),
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _heading(double s) {
    String title, sub;
    if (_winner == null) {
      title = qmText(_ui, 'tie');
      sub = qmText(_ui, 'tieSub');
    } else if (widget.players[_winner!].robot) {
      title = qmText(_ui, 'robotWins');
      sub = qmText(_ui, 'robotWinsSub');
    } else {
      title = qmText(_ui, 'bravoName', a: widget.players[_winner!].name);
      sub = qmText(_ui, 'youWinDuel');
    }
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 8 * s),
      decoration: qmCard(s, radius: 34),
      child: Row(children: [
        Image.asset(qmImgBigStar, width: 30 * s),
        Expanded(
          child: Column(children: [
            FittedBox(fit: BoxFit.scaleDown, child: Text(title, style: qmTitle(36 * s, color: qmPurple))),
            FittedBox(fit: BoxFit.scaleDown, child: Text(sub, style: qmTitle(16 * s))),
          ]),
        ),
        Image.asset(qmImgBigStar, width: 30 * s),
      ]),
    );
  }

  Widget _podium(double s) {
    return LayoutBuilder(builder: (context, c) {
      // podium art is 569 × 484; its blue disc sits at (0.5, 0.42), Ø ≈ 0.44 w
      final h = c.maxHeight;
      final pw = min(c.maxWidth, h / 0.85);
      final ph = pw * 0.85;
      final disc = pw * 0.44;
      final hero = _winner == null ? null : widget.players[_winner!];
      return Center(
        child: SizedBox(
          width: pw,
          height: ph,
          child: AnimatedBuilder(
            animation: _idle,
            builder: (_, ch) => Transform.translate(offset: Offset(0, sin(_idle.value * 2 * pi) * 3 * s), child: ch),
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned.fill(child: Image.asset(qmImgWinnerPodium, fit: BoxFit.contain)),
              Positioned(
                left: pw * 0.5 - disc / 2,
                top: ph * 0.42 - disc / 2,
                width: disc,
                height: disc,
                child: hero != null
                    ? QmAvatar(avatar: hero.avatar, size: disc)
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        QmAvatar(avatar: widget.players[0].avatar, size: disc * 0.56),
                        QmAvatar(avatar: widget.players[1].avatar, size: disc * 0.56),
                      ]),
              ),
              Positioned(
                left: pw * 0.5 - pw * 0.13,
                top: ph * 0.6,
                width: pw * 0.26,
                child: Image.asset(qmImgTrophy, fit: BoxFit.contain),
              ),
            ]),
          ),
        ),
      );
    });
  }

  Widget _scoreCard(double s) {
    Widget side(int p) {
      final pl = widget.players[p];
      final won = _winner == p;
      final col = p == 0 ? const Color(0xFF1C7FD8) : const Color(0xFFE0329C);
      return Expanded(
        child: Column(children: [
          SizedBox(
            height: 94 * s,
            child: Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
              Positioned(top: 10 * s, child: QmAvatar(avatar: pl.avatar, size: 72 * s, ring: won ? qmGold : null)),
              if (won) Positioned(top: -6 * s, child: Image.asset(qmImgCrown, width: 40 * s)),
              if (won)
                Positioned(
                  bottom: 0,
                  child: SizedBox(
                    width: 130 * s,
                    height: 34 * s,
                    child: Stack(alignment: Alignment.center, children: [
                      Positioned.fill(child: Image.asset(qmImgRibbon, fit: BoxFit.fill)),
                      Padding(
                        padding: EdgeInsets.only(bottom: 6 * s),
                        child: Text(qmText(_ui, 'winner'), style: qmTitle(13 * s, color: const Color(0xFF7A4A00))),
                      ),
                    ]),
                  ),
                ),
            ]),
          ),
          SizedBox(height: 2 * s),
          FittedBox(fit: BoxFit.scaleDown, child: Text(pl.name, style: qmTitle(16 * s))),
          SizedBox(height: 2 * s),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 2 * s),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18 * s),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4 * s, offset: Offset(0, 2 * s))],
            ),
            child: Text.rich(TextSpan(children: [
              TextSpan(text: '${_scores[p]} ', style: qmTitle(24 * s, color: col)),
              TextSpan(text: qmText(_ui, _scores[p] == 1 ? 'pt' : 'pts'), style: qmTitle(15 * s, color: col)),
            ])),
          ),
        ]),
      );
    }

    final theme = qmTheme(widget.theme);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(10 * s, 8 * s, 10 * s, 10 * s),
      decoration: qmCard(s, radius: 26),
      child: Column(children: [
        Text(qmText(_ui, 'finalScore'), style: qmTitle(24 * s, color: qmPurple)),
        SizedBox(height: 4 * s),
        QmCategoryPill(scale: s, category: qmThemeCategory(theme), lang: _ui, height: 32),
        SizedBox(height: 4 * s),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          side(0),
          Padding(padding: EdgeInsets.only(top: 22 * s), child: QmVsBadge(width: 74 * s)),
          side(1),
        ]),
      ]),
    );
  }

  Widget _together(double s) {
    final total = _scores[0] + _scores[1];
    final humanGood = [for (var p = 0; p < 2; p++) if (!widget.players[p].robot) _scores[p]].fold<int>(0, (a, b) => a + b);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 6 * s),
      decoration: qmCard(s, radius: 22),
      child: Row(children: [
        Image.asset(qmImgStar, width: 22 * s),
        Expanded(
          child: Column(children: [
            Text(qmText(_ui, _vsRobot ? 'bravo' : 'bothBravo'), style: qmTitle(17 * s)),
            Text(
              _vsRobot ? qmText(_ui, 'youFound', a: '$humanGood') : qmText(_ui, 'together', a: '$total'),
              textAlign: TextAlign.center,
              style: kidBodyStyle(13 * s, color: qmInk, weight: FontWeight.w600),
            ),
          ]),
        ),
        Image.asset(qmImgStar, width: 22 * s),
      ]),
    );
  }

  Widget _pillButton(double s, String icon, String label, VoidCallback onTap, double width) {
    return KidPressable(
      onTap: onTap,
      child: Container(
        width: width * s,
        height: 44 * s,
        decoration: BoxDecoration(
          color: qmCream,
          borderRadius: BorderRadius.circular(24 * s),
          border: Border.all(color: qmGold, width: 2.5 * s),
          boxShadow: [BoxShadow(color: qmPurple.withOpacity(0.15), blurRadius: 8 * s, offset: Offset(0, 3 * s))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Image.asset(icon, height: 24 * s),
          SizedBox(width: 10 * s),
          Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: qmTitle(16 * s, color: const Color(0xFF1E4FB8))))),
        ]),
      ),
    );
  }
}
