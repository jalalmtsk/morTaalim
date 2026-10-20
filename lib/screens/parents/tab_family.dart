import 'package:flutter/material.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:mortaalim/widgets/KidScene/kid_toast.dart';

import 'parent_data.dart';
import 'parent_strings.dart';
import 'parent_ui.dart';
import 'parents_space.dart';

const goalImages = ['goal_park2', 'goal_books', 'goal_game', 'goal_pond', 'goal_park', 'goal_bed'];

/// "Famille": real-life rewards the parent sets, shown to the child as quests.
class FamilyTab extends StatefulWidget {
  const FamilyTab({super.key});

  @override
  State<FamilyTab> createState() => _FamilyTabState();
}

class _FamilyTabState extends State<FamilyTab> {
  List<FamilyGoal> _goals = [];
  List<FeedItem> _feed = [];
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final g = await FamilyGoals.load();
    final f = await ActivityFeed.all();
    if (mounted) {
      setState(() {
        _goals = g;
        _feed = f;
      });
    }
  }

  Future<void> _save() async {
    await FamilyGoals.save(_goals);
    if (mounted) setState(() {});
  }

  bool _isDone(FamilyGoal g) => g.rewarded;

  @override
  Widget build(BuildContext context) {
    final shown = _goals.where((g) => _isDone(g) == _done).toList()..sort((a, b) => b.created.compareTo(a.created));
    return Column(children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          physics: const BouncingScrollPhysics(),
          children: [
            TabHeader(title: pT(context, 'familyTitle'), sub: pT(context, 'familySub', {'name': childName(context)}), robot: 'robot_point', robotW: 120),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(children: [
                _hero(),
                const SizedBox(height: 12),
                _segment(),
                const SizedBox(height: 12),
                if (shown.isEmpty)
                  PCard(
                    child: Column(children: [
                      Image.asset(pa('gift'), width: 70),
                      const SizedBox(height: 8),
                      Text(pT(context, _done ? 'noDoneGoals' : 'noGoals'), textAlign: TextAlign.center, style: ps(15.5, color: PC.sub, w: FontWeight.w500)),
                    ]),
                  )
                else
                  for (final g in shown) ...[_goalCard(g), const SizedBox(height: 12)],
              ]),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
        child: PButton(pT(context, 'newGoal'), icon: Icons.add_rounded, onTap: () => _edit(null)),
      ),
    ]);
  }

  Widget _hero() => PCard(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(pT(context, 'familyHero'), style: ps(19, w: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(pT(context, 'familyHeroSub'), style: ps(13.5, color: PC.sub, w: FontWeight.w500)),
            ]),
          ),
          Image.asset(pa('family_hero'), width: 130),
        ]),
      );

  Widget _segment() => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: PC.cream, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white, width: 2)),
        child: Row(children: [
          for (final d in [false, true])
            Expanded(
              child: KidPressable(
                onTap: () => setState(() => _done = d),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: _done == d ? PC.teal : Colors.transparent, borderRadius: BorderRadius.circular(26)),
                  child: Text(pT(context, d ? 'goalsDone' : 'goalsActive'), style: ps(16, color: _done == d ? Colors.white : PC.ink, w: FontWeight.w700)),
                ),
              ),
            ),
        ]),
      );

  Widget _goalCard(FamilyGoal g) {
    final prog = g.progress(_feed);
    final ready = prog >= g.target;
    final late = g.deadline != null && DateTime.now().isAfter(g.deadline!) && !ready;
    return PCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 74,
            height: 74,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: PC.lav, borderRadius: BorderRadius.circular(20)),
            child: Image.asset(pa(g.image), fit: BoxFit.contain),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(g.title, style: ps(18, w: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(pT(context, 'goalDo_${g.kind}', {'n': g.target}), style: ps(13.5, color: PC.sub, w: FontWeight.w500)),
              const SizedBox(height: 4),
              Row(children: [
                Image.asset(pa('gift'), width: 20),
                const SizedBox(width: 6),
                Expanded(child: Text(g.reward, maxLines: 2, overflow: TextOverflow.ellipsis, style: ps(14.5, color: PC.tealDeep, w: FontWeight.w700))),
              ]),
            ]),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: PC.sub),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (v) async {
              if (v == 'edit') _edit(g);
              if (v == 'vis') {
                g.visible = !g.visible;
                _save();
              }
              if (v == 'del') {
                _goals.remove(g);
                _save();
              }
            },
            itemBuilder: (_) => [
              if (!g.rewarded) PopupMenuItem(value: 'edit', child: Text(pT(context, 'edit'), style: ps(15))),
              PopupMenuItem(value: 'vis', child: Text(pT(context, g.visible ? 'hideFromChild' : 'showToChild'), style: ps(15))),
              PopupMenuItem(value: 'del', child: Text(pT(context, 'delete'), style: ps(15, color: const Color(0xFFD9214E)))),
            ],
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: g.target == 0 ? 0 : prog / g.target,
                minHeight: 12,
                backgroundColor: const Color(0xFFEDE9E0),
                valueColor: AlwaysStoppedAnimation(ready ? PC.green : PC.teal),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('$prog / ${g.target}', style: ps(15, w: FontWeight.w700)),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
          if (g.deadline != null)
            _chip(Icons.event_rounded, pT(context, 'until', {'d': '${g.deadline!.day}/${g.deadline!.month}'}), late ? const Color(0xFFD9214E) : PC.sub),
          _chip(g.visible ? Icons.visibility_rounded : Icons.visibility_off_rounded, pT(context, g.visible ? 'visibleChild' : 'hiddenChild'), PC.sub),
          if (g.rewarded) _chip(Icons.verified_rounded, pT(context, 'rewardGiven'), PC.green),
        ]),
        if (ready && !g.rewarded) ...[
          const SizedBox(height: 12),
          PButton(pT(context, 'confirmReward'), icon: Icons.card_giftcard_rounded, colors: const [Color(0xFF2CCB86), Color(0xFF16A06A)], onTap: () async {
            g.rewarded = true;
            await _save();
            KidToast.show(KidToastKind.quest, title: pT(context, 'rewardGivenTitle'), subtitle: g.reward);
          }),
        ],
      ]),
    );
  }

  Widget _chip(IconData i, String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(i, size: 16, color: c),
          const SizedBox(width: 4),
          Text(t, style: ps(13, color: c, w: FontWeight.w700)),
        ]),
      );

  Future<void> _edit(FamilyGoal? old) async {
    final title = TextEditingController(text: old?.title ?? '');
    final reward = TextEditingController(text: old?.reward ?? '');
    var kind = old?.kind ?? 'lessons';
    var target = old?.target ?? 5;
    var image = old?.image ?? goalImages.first;
    var visible = old?.visible ?? true;
    int? days = old?.deadline == null ? null : old!.deadline!.difference(DateTime.now()).inDays.clamp(1, 60);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        InputDecoration deco(String hint) => InputDecoration(
              hintText: hint,
              hintStyle: ps(15, color: PC.sub, w: FontWeight.w500),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: PC.line, width: 2)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: PC.line, width: 2)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: PC.teal, width: 2)),
            );
        Widget label(String k) => Padding(padding: const EdgeInsets.only(top: 14, bottom: 6), child: Text(pT(ctx, k), style: ps(15.5, w: FontWeight.w700)));
        Widget choice(String text, bool on, VoidCallback tap) => KidPressable(
              onTap: tap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: on ? PC.teal : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: on ? PC.teal : PC.line, width: 2),
                ),
                child: Text(text, style: ps(14.5, color: on ? Colors.white : PC.ink, w: FontWeight.w700)),
              ),
            );
        final ok = title.text.trim().isNotEmpty && reward.text.trim().isNotEmpty;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.9),
            decoration: const BoxDecoration(color: PC.cream, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(18, 14, 18, 18 + MediaQuery.paddingOf(ctx).bottom),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: PC.line, borderRadius: BorderRadius.circular(5)))),
                const SizedBox(height: 12),
                Text(pT(ctx, old == null ? 'newGoal' : 'editGoal'), style: ps(24, w: FontWeight.w700)),
                label('goalName'),
                TextField(controller: title, style: ps(16), decoration: deco(pT(ctx, 'goalNameHint')), onChanged: (_) => setS(() {})),
                label('goalKind'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final k in ['lessons', 'activities', 'games']) choice(pT(ctx, 'kind_$k'), kind == k, () => setS(() => kind = k)),
                ]),
                label('goalTarget'),
                Row(children: [
                  _stepBtn(Icons.remove_rounded, () => setS(() => target = (target - 1).clamp(1, 50))),
                  Expanded(child: Center(child: Text(pT(ctx, 'goalDo_$kind', {'n': target}), style: ps(18, w: FontWeight.w700)))),
                  _stepBtn(Icons.add_rounded, () => setS(() => target = (target + 1).clamp(1, 50))),
                ]),
                label('goalReward'),
                TextField(controller: reward, style: ps(16), decoration: deco(pT(ctx, 'goalRewardHint')), onChanged: (_) => setS(() {})),
                label('goalDeadline'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final d in <int?>[null, 7, 14, 30])
                    choice(d == null ? pT(ctx, 'noDeadline') : pT(ctx, 'inDays', {'n': d}), days == d, () => setS(() => days = d)),
                ]),
                label('goalImage'),
                SizedBox(
                  height: 76,
                  child: ListView(scrollDirection: Axis.horizontal, children: [
                    for (final im in goalImages)
                      KidPressable(
                        onTap: () => setS(() => image = im),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 76,
                          margin: const EdgeInsetsDirectional.only(end: 8),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: image == im ? PC.teal : PC.line, width: image == im ? 3 : 2),
                          ),
                          child: Image.asset(pa(im), fit: BoxFit.contain),
                        ),
                      ),
                  ]),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: Text(pT(ctx, 'showToChildLong'), style: ps(15.5, w: FontWeight.w600))),
                  PSwitch(value: visible, onChanged: (v) => setS(() => visible = v)),
                ]),
                const SizedBox(height: 18),
                PButton(pT(ctx, 'save'), icon: Icons.check_rounded, onTap: ok ? () => Navigator.pop(ctx, true) : null),
              ]),
            ),
          ),
        );
      }),
    );
    if (saved != true) return;
    final deadline = days == null ? null : DateTime.now().add(Duration(days: days!));
    if (old == null) {
      _goals.add(FamilyGoal(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title.text.trim(),
        kind: kind,
        target: target,
        reward: reward.text.trim(),
        image: image,
        visible: visible,
        created: DateTime.now(),
        deadline: deadline,
      ));
    } else {
      old
        ..title = title.text.trim()
        ..kind = kind
        ..target = target
        ..reward = reward.text.trim()
        ..image = image
        ..visible = visible
        ..deadline = deadline;
    }
    setState(() => _done = false);
    await _save();
    if (mounted) KidToast.show(KidToastKind.saved, title: pT(context, 'savedTitle'), subtitle: pT(context, 'goalSavedSub'));
  }

  Widget _stepBtn(IconData i, VoidCallback onTap) => KidPressable(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: PC.tealSoft, borderRadius: BorderRadius.circular(16)),
          child: Icon(i, color: PC.tealDeep, size: 28),
        ),
      );
}
