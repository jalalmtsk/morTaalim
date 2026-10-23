import 'dart:math';

import 'package:mortaalim/Manager/rewards.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../XpSystem.dart';
import '../../../tools/audio_tool/Audio_Manager.dart';
import '../../../widgets/KidScene/kid_page_parts.dart';
import '../../../widgets/KidScene/kid_scene.dart';
import '../ModeSelectorPage.dart';
import 'quiz_magic_data.dart';
import 'quiz_magic_page.dart';
import 'quiz_magic_widgets.dart';

/// End of a round: "Défi réussi !" (≥ 60 %) or "On réessaie ?".
class QuizMagicResultsPage extends StatefulWidget {
  final QuizLanguage language;
  final List<QmItem> items;
  final String theme;
  final int bestStreak;
  const QuizMagicResultsPage({super.key, required this.language, required this.items, this.theme = 'surprise', this.bestStreak = 0});

  @override
  State<QuizMagicResultsPage> createState() => _QuizMagicResultsPageState();
}

class _QuizMagicResultsPageState extends State<QuizMagicResultsPage> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  final ConfettiController _confetti = ConfettiController(duration: const Duration(seconds: 2));

  late final int _good = widget.items.where((i) => i.correct).length;
  late final int _total = widget.items.length;
  late final bool _won = qmPassed(_good, _total);
  late final Reward _prize = Rewards.session(correct: _good, total: _total, perfectGem: _won) + Reward(gold: _won ? 5 : 0);
  late final int _gold = _prize.gold;
  late final int _gems = _prize.gems;
  late final QmCategory _best = _bestCategory();

  String get _ui => qmUiLang(widget.language);

  QmCategory _bestCategory() {
    if (widget.theme != 'surprise') return qmThemeCategory(qmTheme(widget.theme));
    final count = <String, int>{};
    for (final i in widget.items) {
      count[i.category] = (count[i.category] ?? 0) + (i.correct ? 3 : 1);
    }
    if (count.isEmpty) return qmCategory('general');
    final id = count.entries.reduce((a, b) => b.value > a.value ? b : a).key;
    return qmCategory(id);
  }

  @override
  void initState() {
    super.initState();
    _intro.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reward());
  }

  void _reward() {
    if (!mounted) return;
    final xp = Provider.of<ExperienceManager>(context, listen: false);
    final audio = Provider.of<AudioManager>(context, listen: false);
    if (_won) {
      _confetti.play();
      audio.playSfx('assets/audios/UI_Audio/SFX_Audio/CorrectAnwser_SFX.mp3');
    }
    xp.grant(context, _prize);
  }

  @override
  void dispose() {
    _intro.dispose();
    _idle.dispose();
    _confetti.dispose();
    super.dispose();
  }

  void _playAgain() {
    Provider.of<AudioManager>(context, listen: false).playEventSound('clickButton');
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => QuizMagicPage(language: widget.language, theme: widget.theme),
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
    ));
  }

  void _menu() {
    Provider.of<AudioManager>(context, listen: false).playEventSound('cancelButton');
    Navigator.of(context).pop();
  }

  void _review() {
    Provider.of<AudioManager>(context, listen: false).playEventSound('clickButton');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Directionality(
        textDirection: widget.language == QuizLanguage.arabic ? TextDirection.rtl : TextDirection.ltr,
        child: QmReviewSheet(items: widget.items, lang: _ui),
      ),
    );
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
    final h = c.maxHeight;
    final s = min(w / 380, h / 800).clamp(0.62, 1.35).toDouble();
    Widget step(int i, Widget child) =>
        KidIntro(intro: _intro, from: 0.07 * i, to: min(1.0, 0.4 + 0.07 * i), rise: 22, child: child);

    return Stack(children: [
      PositionedDirectional(start: -12 * s, bottom: -8 * s, child: IgnorePointer(child: Image.asset(qmImgBush1, width: 120 * s))),
      PositionedDirectional(end: -10 * s, bottom: -8 * s, child: IgnorePointer(child: Image.asset(qmImgFlowers, width: 110 * s))),
      Center(
        child: SizedBox(
          width: w,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14 * s),
            child: Column(children: [
              step(0, QmTopBar(scale: s, title: qmText(_ui, 'title'), onBack: _menu)),
              SizedBox(height: 4 * s),
              step(1, _heading(s)),
              Expanded(child: step(2, _scene(s))),
              step(3, _scoreCard(s)),
              SizedBox(height: 10 * s),
              step(4, _won ? _rewardRow(s) : _tipCard(s)),
              SizedBox(height: 12 * s),
              step(5, KidButton(
                label: qmText(_ui, _won ? 'continue' : 'retry'),
                onPressed: _playAgain,
                width: 300 * s,
                height: 56 * s,
                showArrow: _won,
              )),
              SizedBox(height: 10 * s),
              step(6, _reviewButton(s)),
              SizedBox(height: 8 * s),
              step(7, _menuButton(s)),
              SizedBox(height: 8 * s),
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _heading(double s) {
    final title = qmText(_ui, _won ? 'winTitle' : 'retryTitle');
    final sub = qmText(_ui, _won ? 'winSub' : 'retrySub');
    return Column(children: [
      AnimatedBuilder(
        animation: _idle,
        builder: (_, c) => Transform.scale(scale: 1 + sin(_idle.value * 2 * pi * 2) * 0.02, child: c),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: _won
              ? QmOutlinedText(title, size: 46 * s, gradient: const [Color(0xFFFFE55C), Color(0xFFFF9A1F)])
              : QmOutlinedText(title, size: 42 * s, fill: qmPurple, stroke: Colors.white),
        ),
      ),
      SizedBox(height: 4 * s),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 18 * s, vertical: 5 * s),
        decoration: BoxDecoration(
          color: qmCream,
          borderRadius: BorderRadius.circular(20 * s),
          border: Border.all(color: qmGold, width: 2 * s),
          boxShadow: [BoxShadow(color: qmPurple.withOpacity(0.15), blurRadius: 8 * s, offset: Offset(0, 3 * s))],
        ),
        child: Text(sub, textAlign: TextAlign.center, style: qmTitle(16 * s)),
      ),
    ]);
  }

  Widget _scene(double s) {
    return AnimatedBuilder(
      animation: _idle,
      builder: (_, c) => Transform.translate(offset: Offset(0, sin(_idle.value * 2 * pi) * 4 * s), child: c),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4 * s),
        child: _won
            ? Image.asset(qmImgWinScene, fit: BoxFit.contain)
            : LayoutBuilder(builder: (_, c) {
                // the reading duo sits on the mossy rock
                final hh = c.maxHeight;
                return Stack(alignment: Alignment.bottomCenter, children: [
                  Positioned(bottom: 0, child: Image.asset(qmImgRetryGround, height: hh * 0.42, fit: BoxFit.contain)),
                  Positioned(bottom: hh * 0.16, child: Image.asset(qmImgRetryDuo, height: hh * 0.8, fit: BoxFit.contain)),
                ]);
              }),
      ),
    );
  }

  Widget _scoreCard(double s) {
    final stars = qmStars(_good, _total);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14 * s, 10 * s, 14 * s, 12 * s),
      decoration: qmCard(s, radius: 28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        QmCategoryPill(scale: s, category: _best, lang: _ui, height: 36),
        SizedBox(height: 4 * s),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (!_won) Image.asset(qmImgStar, width: 26 * s),
          SizedBox(width: 10 * s),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _good.toDouble()),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Text('${v.round()} / $_total', style: qmTitle(50 * s, color: qmPurple)),
          ),
          SizedBox(width: 10 * s),
          if (!_won) Image.asset(qmImgStar, width: 26 * s),
        ]),
        Text(qmText(_ui, 'goodAnswers'), style: qmTitle(16 * s)),
        if (widget.bestStreak >= 2)
          Padding(
            padding: EdgeInsets.only(top: 4 * s),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 3 * s),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16 * s),
                gradient: const LinearGradient(colors: [Color(0xFFFF8A3D), Color(0xFFFF3D6E)]),
              ),
              child: Text('🔥 ${qmText(_ui, 'bestStreak', a: '${widget.bestStreak}')}', style: qmTitle(14 * s, color: Colors.white)),
            ),
          ),
        SizedBox(height: 6 * s),
        if (_won)
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 6 * s),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 600 + i * 220),
                  curve: Curves.elasticOut,
                  builder: (_, v, c) => Transform.scale(scale: v, child: c),
                  child: Opacity(
                    opacity: i < stars ? 1 : 0.35,
                    child: Image.asset(i < stars ? qmImgBigStar : qmImgStarEmpty, width: 44 * s, height: 44 * s),
                  ),
                ),
              ),
          ])
        else
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 6 * s, horizontal: 10 * s),
            decoration: BoxDecoration(color: const Color(0xFFEDE1FF), borderRadius: BorderRadius.circular(18 * s)),
            child: Text(qmText(_ui, 'practice'), textAlign: TextAlign.center, style: qmTitle(16 * s)),
          ),
      ]),
    );
  }

  Widget _rewardRow(double s) {
    Widget box(String label, Widget child) => Expanded(
          child: Container(
            height: 82 * s,
            padding: EdgeInsets.fromLTRB(8 * s, 6 * s, 8 * s, 6 * s),
            decoration: qmCard(s, radius: 20),
            child: Column(children: [
              Text(label, style: qmTitle(13 * s)),
              Expanded(child: Center(child: child)),
            ]),
          ),
        );
    Widget amount(String icon, int v) => Row(mainAxisSize: MainAxisSize.min, children: [
          Image.asset(icon, width: 30 * s, height: 30 * s),
          SizedBox(width: 4 * s),
          Text('+$v', style: qmTitle(20 * s)),
        ]);
    return Row(children: [
      box(
        qmText(_ui, 'rewards'),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            amount(kidCoinAsset, _gold),
            if (_gems > 0) ...[SizedBox(width: 12 * s), amount(kidGemAsset, _gems)],
          ]),
        ),
      ),
      SizedBox(width: 10 * s),
      box(
        qmText(_ui, 'badge'),
        Row(children: [
          Image.asset(qmImgBadge, height: 46 * s),
          SizedBox(width: 6 * s),
          Expanded(
            child: Container(
              height: 36 * s,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: 6 * s),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFFE27A), Color(0xFFFFC93C)]),
                borderRadius: BorderRadius.circular(12 * s),
                border: Border.all(color: const Color(0xFFE6A92A), width: 1.5 * s),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(qmBadgeName(_best, _ui), textAlign: TextAlign.center, style: qmTitle(14 * s)),
              ),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _tipCard(double s) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 8 * s),
      decoration: qmCard(s, border: const Color(0xFF6FE0F0), fill: const Color(0xFFE6FBFF), radius: 20),
      child: Row(children: [
        Image.asset(qmImgBook, width: 54 * s),
        SizedBox(width: 10 * s),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(qmText(_ui, 'tipTitle'), style: qmTitle(17 * s)),
            SizedBox(height: 2 * s),
            Text(qmText(_ui, 'tipText'), style: kidBodyStyle(13.5 * s, color: qmInk, weight: FontWeight.w500)),
          ]),
        ),
      ]),
    );
  }

  Widget _reviewButton(double s) {
    return KidPressable(
      onTap: _review,
      child: Container(
        width: 300 * s,
        height: 48 * s,
        decoration: BoxDecoration(
          color: qmCream,
          borderRadius: BorderRadius.circular(26 * s),
          border: Border.all(color: qmGold, width: 2.5 * s),
          boxShadow: [BoxShadow(color: qmPurple.withOpacity(0.15), blurRadius: 8 * s, offset: Offset(0, 3 * s))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Image.asset(qmImgBook, height: 24 * s),
          SizedBox(width: 10 * s),
          Flexible(
            child: FittedBox(fit: BoxFit.scaleDown, child: Text(qmText(_ui, 'review'), style: qmTitle(17 * s, color: const Color(0xFF1E4FB8)))),
          ),
        ]),
      ),
    );
  }

  Widget _menuButton(double s) {
    return KidPressable(
      onTap: _menu,
      child: SizedBox(
        width: 190 * s,
        height: 44 * s,
        child: Stack(alignment: Alignment.center, children: [
          Positioned.fill(child: Image.asset(qmImgWoodSign, fit: BoxFit.fill)),
          Padding(
            padding: EdgeInsetsDirectional.only(start: 40 * s, end: 14 * s),
            child: FittedBox(fit: BoxFit.scaleDown, child: Text(qmText(_ui, 'menu'), style: qmTitle(15 * s))),
          ),
        ]),
      ),
    );
  }
}

/// "Revoir mes réponses": every question with the child's pick and the answer.
class QmReviewSheet extends StatelessWidget {
  final List<QmItem> items;
  final String lang;
  final List<String>? owners; // who answered each question (duel)
  const QmReviewSheet({super.key, required this.items, required this.lang, this.owners});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, ctrl) => Container(
        decoration: const BoxDecoration(
          color: qmCream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: qmGold, width: 3)),
        ),
        child: Column(children: [
          const SizedBox(height: 10),
          Container(width: 48, height: 5, decoration: BoxDecoration(color: const Color(0xFFE2CFA6), borderRadius: BorderRadius.circular(3))),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Image.asset(qmImgBook, height: 26),
            const SizedBox(width: 8),
            Text(qmText(lang, 'review'), style: qmTitle(22, color: qmPurple)),
          ]),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _row(i, items[i]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _row(int i, QmItem it) {
    final ok = it.correct;
    Widget answer(String label, int? idx, Color c) {
      final text = idx == null ? '—' : it.question.options[idx];
      final key = idx == null ? null : it.keys[idx];
      return Expanded(
        child: Column(children: [
          Text(label, style: kidBodyStyle(12, color: c, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Container(
            height: 74,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c, width: 2.5),
            ),
            child: QmAnswerArt(artKey: key, text: text, radius: 12),
          ),
          if (QmAnswerArt.hasPicture(key))
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: qmTitle(14)),
            ),
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ok ? const Color(0xFFF1FFF1) : const Color(0xFFFFF3F4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ok ? const Color(0xFFA6E3A1) : const Color(0xFFFFC2CA), width: 2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Image.asset(ok ? qmImgBadgeOk : qmImgBadgeX, width: 30, height: 30),
          const SizedBox(width: 8),
          Expanded(child: Text('${i + 1}. ${it.question.questionText}', style: qmTitle(16))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          answer(owners != null && i < owners!.length ? owners![i] : qmText(lang, 'yourAnswer'), it.picked, ok ? qmGreen : qmRed),
          if (!ok) ...[
            const SizedBox(width: 10),
            answer(qmText(lang, 'rightAnswer'), it.question.correctIndex, qmGreen),
          ],
        ]),
      ]),
    );
  }
}
