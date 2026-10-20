import 'package:flutter/material.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';

import 'parent_data.dart';
import 'parent_strings.dart';
import 'parent_ui.dart' show pa;

/// The parent's real-life goals, shown to the child inside the Quests page.
class FamilyQuestsSection extends StatefulWidget {
  final double scale;
  const FamilyQuestsSection({super.key, this.scale = 1});

  @override
  State<FamilyQuestsSection> createState() => _FamilyQuestsSectionState();
}

class _FamilyQuestsSectionState extends State<FamilyQuestsSection> {
  List<FamilyGoal> _goals = [];
  List<FeedItem> _feed = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final g = (await FamilyGoals.load()).where((g) => g.visible && !g.rewarded).toList();
    final f = await ActivityFeed.all();
    if (mounted) {
      setState(() {
        _goals = g;
        _feed = f;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_goals.isEmpty) return const SizedBox.shrink();
    final s = widget.scale;
    return Padding(
      padding: EdgeInsets.fromLTRB(16 * s, 0, 16 * s, 12 * s),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Image.asset(pa('gift'), width: 34 * s),
          SizedBox(width: 8 * s),
          Expanded(
            child: Text(pT(context, 'kidFamilyQuests'),
                style: kidTitleStyle(20 * s).copyWith(shadows: [Shadow(color: Colors.white.withOpacity(0.9), blurRadius: 6)])),
          ),
        ]),
        SizedBox(height: 8 * s),
        for (final g in _goals) _card(g, s),
      ]),
    );
  }

  Widget _card(FamilyGoal g, double s) {
    final prog = g.progress(_feed);
    final ready = prog >= g.target;
    return Container(
      margin: EdgeInsets.only(bottom: 10 * s),
      padding: EdgeInsets.all(10 * s),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(22 * s),
        border: Border.all(color: ready ? const Color(0xFF2CCB86) : const Color(0xFFFFC85C), width: 3 * s),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Container(
          width: 70 * s,
          height: 70 * s,
          padding: EdgeInsets.all(4 * s),
          decoration: BoxDecoration(color: const Color(0xFFEDE9FB), borderRadius: BorderRadius.circular(18 * s)),
          child: Image.asset(pa(g.image), fit: BoxFit.contain),
        ),
        SizedBox(width: 10 * s),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(g.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: kidBodyStyle(16.5 * s, color: KidColors.ink, weight: FontWeight.w700)),
            SizedBox(height: 2 * s),
            Text(pT(context, 'goalDo_${g.kind}', {'n': g.target}), style: kidBodyStyle(12.5 * s, color: KidColors.muted, weight: FontWeight.w600)),
            SizedBox(height: 6 * s),
            Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: prog / g.target,
                    minHeight: 10 * s,
                    backgroundColor: const Color(0xFFEADFCB),
                    valueColor: AlwaysStoppedAnimation(ready ? const Color(0xFF2CCB86) : const Color(0xFFFF9A2E)),
                  ),
                ),
              ),
              SizedBox(width: 8 * s),
              Text('$prog/${g.target}', style: kidBodyStyle(13 * s, color: KidColors.ink, weight: FontWeight.w700)),
            ]),
            SizedBox(height: 4 * s),
            Text(
              ready ? pT(context, 'kidGoalReady') : '🎁 ${g.reward}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: kidBodyStyle(13 * s, color: ready ? const Color(0xFF16A06A) : KidColors.purpleDeep, weight: FontWeight.w700),
            ),
          ]),
        ),
      ]),
    );
  }
}
