import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:mortaalim/Manager/models/avatar_catalog.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';

import 'parent_data.dart';
import 'parent_strings.dart';
import 'parent_ui.dart';

/// A one-page summary of the week, shareable as an image.
class WeeklyReportPage extends StatefulWidget {
  const WeeklyReportPage({super.key});

  @override
  State<WeeklyReportPage> createState() => _WeeklyReportPageState();
}

class _WeeklyReportPageState extends State<WeeklyReportPage> {
  final _key = GlobalKey();
  bool _ready = false, _sharing = false;
  int _secs = 0, _lessons = 0, _games = 0, _drawings = 0, _badges = 0, _levels = 0, _days = 0;
  String? _best;
  List<int> _week = List.filled(7, 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final xp = Provider.of<ExperienceManager>(context, listen: false);
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final week = await Usage.week(now);
    final feed = (await ActivityFeed.all()).where((f) => !f.at.isBefore(monday)).toList();
    final startLevel = await WeekLevel.at(now);
    final bySubject = <String, int>{};
    for (final f in feed.where((f) => f.type == 'lesson')) {
      bySubject[f.ref] = (bySubject[f.ref] ?? 0) + 1;
    }
    String? best;
    bySubject.forEach((k, v) {
      if (best == null || v > bySubject[best]!) best = k;
    });
    if (!mounted) return;
    setState(() {
      _week = week;
      _secs = week.fold(0, (a, b) => a + b);
      _days = week.where((s) => s >= 60).length;
      _lessons = feed.where((f) => f.type == 'lesson').length;
      _games = feed.where((f) => f.type == 'game').length;
      _drawings = feed.where((f) => f.type == 'drawing').length;
      _badges = feed.where((f) => f.type == 'badge').length;
      _levels = startLevel == null ? 0 : (xp.level - startLevel).clamp(0, 99);
      _best = best;
      _ready = true;
    });
  }

  Future<void> _share({required bool whatsapp}) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundary = _key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return;
      final file = XFile.fromData(data.buffer.asUint8List(), mimeType: 'image/png', name: 'moortaalim_semaine.png');
      await SharePlus.instance.share(ShareParams(
        files: [file],
        text: whatsapp ? pT(context, 'shareText', {'name': childName(context)}) : null,
      ));
    } catch (_) {
      if (mounted) pSnack(context, pT(context, 'shareFail'), ok: false);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PC.cream,
      body: ParentBackground(
        dim: true,
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(children: [
                KidPressable(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: PC.cream, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8)]),
                    child: const Icon(Icons.arrow_back_rounded, color: PC.teal),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(pT(context, 'reportTitle'), style: ps(24, w: FontWeight.w700))),
              ]),
            ),
            Expanded(
              child: !_ready
                  ? const Center(child: CircularProgressIndicator(color: PC.teal))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: RepaintBoundary(key: _key, child: _card()),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(children: [
                Expanded(
                  child: PButton(pT(context, 'shareWhatsapp'),
                      icon: Icons.chat_rounded, colors: const [Color(0xFF3DDC84), Color(0xFF1FAF5E)], onTap: _ready ? () => _share(whatsapp: true) : null),
                ),
                const SizedBox(width: 10),
                Expanded(child: PButton(pT(context, 'saveImage'), icon: Icons.download_rounded, onTap: _ready ? () => _share(whatsapp: false) : null)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _card() {
    final xp = Provider.of<ExperienceManager>(context);
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final labels = pT(context, 'weekdaysShort').split(',');
    final maxS = _week.fold<int>(1, (a, b) => b > a ? b : a);
    String d(DateTime x) => '${x.day}/${x.month}';
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE6F7F6), Color(0xFFFFFBF3)]),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [BoxShadow(color: const Color(0xFF3B2A7A).withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          CircleAvatar(radius: 34, backgroundColor: PC.lav, backgroundImage: AssetImage(AvatarCatalog.resolve(xp.selectedAvatar))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(pT(context, 'reportOf', {'name': childName(context)}), style: ps(22, w: FontWeight.w700)),
              Text('${d(monday)} → ${d(sunday)} · ${pT(context, 'levelN', {'n': xp.level})}', style: ps(14, color: PC.sub)),
            ]),
          ),
          Image.asset(pa('robot_wave'), width: 64),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          _big(Icons.schedule_rounded, fmtDuration(context, _secs), pT(context, 'timeLearning'), PC.teal),
          const SizedBox(width: 10),
          _big(Icons.local_fire_department_rounded, '$_days / 7', pT(context, 'activeDays'), PC.orange),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          height: 90,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Container(
                    height: 4 + 62 * _week[i] / maxS,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF4FD1C5), PC.teal]),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(labels[i], style: ps(12.5, color: PC.sub, w: FontWeight.w700)),
                ]),
              ),
          ]),
        ),
        const SizedBox(height: 14),
        Wrap(spacing: 10, runSpacing: 10, children: [
          _small(Icons.menu_book_rounded, '$_lessons', pT(context, 'kind_lessons'), const Color(0xFF6D5BD0)),
          _small(Icons.sports_esports_rounded, '$_games', pT(context, 'kind_games'), PC.teal),
          _small(Icons.palette_rounded, '$_drawings', pT(context, 'drawings'), PC.orange),
          _small(Icons.emoji_events_rounded, '$_badges', pT(context, 'badges'), const Color(0xFFF5B400)),
          _small(Icons.trending_up_rounded, '+$_levels', pT(context, 'levels'), PC.green),
        ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Row(children: [
            Image.asset(pa('cloud_ok'), width: 54),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _best == null ? pT(context, 'reportEmpty') : pT(context, 'reportBest', {'subject': subjectName(context, _best!)}),
                style: ps(15, w: FontWeight.w600),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        Center(child: Text('MoorTaalim · Jalnix', style: ps(12, color: PC.sub))),
      ]),
    );
  }

  Widget _big(IconData i, String v, String l, Color c) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Row(children: [
            PIcon(i, color: c, bg: c.withOpacity(0.12), size: 42),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                FittedBox(fit: BoxFit.scaleDown, child: Text(v, style: ps(20, w: FontWeight.w700))),
                Text(l, maxLines: 1, overflow: TextOverflow.ellipsis, style: ps(12.5, color: PC.sub)),
              ]),
            ),
          ]),
        ),
      );

  Widget _small(IconData i, String v, String l, Color c) => Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
        decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(i, color: c, size: 20),
          const SizedBox(width: 6),
          Text(v, style: ps(16, w: FontWeight.w700)),
          const SizedBox(width: 4),
          Text(l, style: ps(13, color: PC.sub)),
        ]),
      );
}
