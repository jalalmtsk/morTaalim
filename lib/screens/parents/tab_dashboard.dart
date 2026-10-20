import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';

import 'parent_data.dart';
import 'parent_strings.dart';
import 'parent_ui.dart';
import 'parents_space.dart';
import 'weekly_report.dart';

/// "Suivi": time played, progress per subject, strengths, recent activity.
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  bool _week = true;
  int _today = 0;
  List<int> _days = List.filled(7, 0);
  Map<String, int> _lessons = {};
  List<FeedItem> _feed = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    final t = await Usage.secondsOn(now);
    final w = await Usage.week(now);
    final l = await lessonsPerSubject();
    final f = await ActivityFeed.all();
    if (!mounted) return;
    setState(() {
      _today = t;
      _days = w;
      _lessons = l;
      _feed = f.reversed.toList();
      _loaded = true;
    });
  }

  static const _subjects = [
    ('math', Icons.calculate_rounded, Color(0xFFFF7A1A)),
    ('french', Icons.menu_book_rounded, Color(0xFF2F7BEA)),
    ('arabic', Icons.translate_rounded, Color(0xFF13A38A)),
    ('islamicEducation', Icons.mosque_rounded, Color(0xFF8B5CF6)),
    ('science', Icons.eco_rounded, Color(0xFF34B254)),
  ];

  /// Lessons per subject this week (from the activity log).
  Map<String, int> get _weekLessons {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final out = <String, int>{};
    for (final f in _feed) {
      if (f.type != 'lesson' || f.at.isBefore(monday)) continue;
      final subj = f.ref.split('/').last;
      out[subj] = (out[subj] ?? 0) + 1;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final weekSecs = _days.fold<int>(0, (a, b) => a + b);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        children: [
          TabHeader(title: pT(context, 'dashTitle'), sub: pT(context, 'dashSub', {'name': childName(context)}), robot: 'robot_wave', robotW: 140),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(children: [
              _segmented(),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _stat(Icons.schedule_rounded, pT(context, 'today'), fmtDuration(context, _today), const Color(0xFF14A3A8))),
                const SizedBox(width: 10),
                Expanded(child: _stat(Icons.bar_chart_rounded, pT(context, 'thisWeek'), fmtDuration(context, weekSecs), const Color(0xFF6D5BD0))),
              ]),
              const SizedBox(height: 10),
              _chart(),
              const SizedBox(height: 12),
              _subjectsCard(),
              const SizedBox(height: 12),
              _recentCard(),
              const SizedBox(height: 12),
              PButton(pT(context, 'openReport'), icon: Icons.auto_awesome_rounded,
                  colors: const [Color(0xFF2EC4C9), Color(0xFF0E8F96)],
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeeklyReportPage()))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _segmented() => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: PC.cream, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white, width: 2)),
        child: Row(children: [
          for (final w in [false, true])
            Expanded(
              child: KidPressable(
                onTap: () => setState(() => _week = w),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: _week == w ? PC.teal : Colors.transparent, borderRadius: BorderRadius.circular(24)),
                  child: Text(pT(context, w ? 'thisWeek' : 'today'), style: ps(16, color: _week == w ? Colors.white : PC.ink, w: FontWeight.w700)),
                ),
              ),
            ),
        ]),
      );

  Widget _stat(IconData i, String label, String value, Color c) => PCard(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          PIcon(i, color: c, bg: c.withOpacity(0.14), size: 50),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: ps(14, color: PC.sub)),
              FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: ps(26, w: FontWeight.w700))),
            ]),
          ),
        ]),
      );

  Widget _chart() {
    final mx = max(1, _days.reduce(max));
    final todayIdx = DateTime.now().weekday - 1;
    final labels = pT(context, 'weekdaysShort').split(',');
    return PCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: SizedBox(
        height: 120,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                if (_days[i] > 0)
                  FittedBox(child: Text('${_days[i] ~/ 60}', style: ps(11, color: PC.sub))),
                const SizedBox(height: 2),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: _days[i] / mx),
                  duration: Duration(milliseconds: 500 + i * 60),
                  curve: Curves.easeOutBack,
                  builder: (_, v, __) => Container(
                    width: 18,
                    height: 8 + 70 * v.clamp(0.0, 1.2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: i == todayIdx ? PC.tealDeep : const Color(0xFF55D3D3),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(labels[i], style: ps(13, color: i == todayIdx ? PC.ink : PC.sub, w: FontWeight.w700)),
              ]),
            ),
        ]),
      ),
    );
  }

  Widget _subjectsCard() {
    final week = _weekLessons;
    // progress % per subject (lessons done / available)
    final pct = <String, double>{
      for (final s in _subjects)
        if ((subjectTotals[s.$1] ?? 0) > 0) s.$1: min(1.0, (_lessons[s.$1] ?? 0) / subjectTotals[s.$1]!),
    };
    String? best, weak;
    if (pct.isNotEmpty) {
      final sorted = pct.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      if (sorted.first.value > 0) best = sorted.first.key;
      weak = sorted.last.key == best ? null : sorted.last.key;
    }
    return PCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(pT(context, 'bySubject'), style: ps(22, w: FontWeight.w700)),
        const SizedBox(height: 10),
        for (final s in _subjects) _subjectRow(s.$1, s.$2, s.$3, _week ? (week[s.$1] ?? 0) : (_lessons[s.$1] ?? 0), pct[s.$1]),
        const SizedBox(height: 6),
        if (_loaded)
          Row(children: [
            Expanded(child: _insight(Icons.star_rounded, const Color(0xFF34B254), const Color(0xFFE2F6E6), pT(context, 'strength'),
                best == null ? pT(context, 'notYet') : pT(context, 'subj_$best'))),
            const SizedBox(width: 10),
            Expanded(child: _insight(Icons.track_changes_rounded, const Color(0xFFF0562E), const Color(0xFFFFEBDD), pT(context, 'toWork'),
                weak == null ? pT(context, 'notYet') : pT(context, 'subj_$weak'))),
          ]),
        const SizedBox(height: 6),
        Text(pT(context, 'fromRecent'), style: ps(12.5, color: PC.sub, w: FontWeight.w500)),
      ]),
    );
  }

  Widget _subjectRow(String key, IconData icon, Color c, int lessons, double? pct) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [c.withOpacity(0.8), c]),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FittedBox(fit: BoxFit.scaleDown, child: Text(pT(context, 'subj_$key'), style: ps(16.5, w: FontWeight.w700))),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pct ?? 0,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFEDE9F5),
                  valueColor: AlwaysStoppedAnimation(c),
                ),
              ),
            ]),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.menu_book_rounded, color: Color(0xFF3B3F78), size: 20),
          const SizedBox(width: 4),
          SizedBox(width: 58, child: Text(pT(context, 'lessonsN', {'n': lessons}), style: ps(13.5, color: PC.sub))),
          const Icon(Icons.emoji_events_rounded, color: Color(0xFFF5A623), size: 22),
          const SizedBox(width: 4),
          SizedBox(
            width: 44,
            child: Text(pct == null ? pT(context, 'soon') : '${(pct * 100).round()} %', style: ps(14, w: FontWeight.w700)),
          ),
        ]),
      );

  Widget _insight(IconData i, Color c, Color bg, String label, String value) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white, width: 2)),
        child: Row(children: [
          Icon(i, color: c, size: 34),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: ps(13.5, color: c)),
              FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: ps(17, w: FontWeight.w700))),
            ]),
          ),
        ]),
      );

  Widget _recentCard() {
    final items = _feed.take(4).toList();
    return PCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(pT(context, 'recent'), style: ps(22, w: FontWeight.w700))),
          if (_feed.length > 4)
            KidPressable(
              onTap: _showAll,
              child: Row(children: [
                Text(pT(context, 'seeAll'), style: ps(15, color: PC.teal, w: FontWeight.w700)),
                const Icon(Icons.chevron_right_rounded, color: PC.teal),
              ]),
            ),
        ]),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(pT(context, 'noActivity'), style: ps(15, color: PC.sub, w: FontWeight.w500)),
          )
        else
          for (final f in items) FeedRow(item: f),
      ]),
    );
  }

  void _showAll() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        builder: (_, sc) => Container(
          decoration: const BoxDecoration(color: PC.cream, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: ListView(controller: sc, padding: const EdgeInsets.all(16), children: [
            Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: PC.line, borderRadius: BorderRadius.circular(5)))),
            const SizedBox(height: 12),
            Text(pT(context, 'recent'), style: ps(22, w: FontWeight.w700)),
            const SizedBox(height: 10),
            for (final f in _feed.take(80)) FeedRow(item: f),
          ]),
        ),
      ),
    );
  }
}

class FeedRow extends StatelessWidget {
  final FeedItem item;
  const FeedRow({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (item.type) {
      'lesson' => (Icons.menu_book_rounded, const Color(0xFF2F7BEA)),
      'drawing' => (Icons.palette_rounded, const Color(0xFFFF7A1A)),
      'badge' => (Icons.military_tech_rounded, const Color(0xFFF5A623)),
      'listen' => (Icons.headphones_rounded, const Color(0xFF8B5CF6)),
      _ => (Icons.sports_esports_rounded, const Color(0xFF2F7BEA)),
    };
    final when = item.at;
    final now = DateTime.now();
    final sameDay = when.year == now.year && when.month == now.month && when.day == now.day;
    final time = '${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(feedTitle(context, item), maxLines: 1, overflow: TextOverflow.ellipsis, style: ps(16, w: FontWeight.w700)),
            Text(feedSub(context, item), style: ps(13, color: PC.sub, w: FontWeight.w500)),
          ]),
        ),
        Text(sameDay ? time : '${when.day}/${when.month}', style: ps(13, color: PC.sub)),
      ]),
    );
  }
}
