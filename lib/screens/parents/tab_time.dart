import 'package:flutter/material.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:mortaalim/widgets/KidScene/kid_toast.dart';

import 'parent_data.dart';
import 'parent_strings.dart';
import 'parent_ui.dart';
import 'parents_space.dart';

/// "Temps": daily limit, quiet hours, break reminder.
class TimeTab extends StatefulWidget {
  const TimeTab({super.key});

  @override
  State<TimeTab> createState() => _TimeTabState();
}

class _TimeTabState extends State<TimeTab> {
  final ParentSettings _s = ParentSettings.I;
  static const _steps = [15, 30, 45, 60, 90, 120];
  int _usedToday = 0;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    Usage.secondsOn(DateTime.now()).then((v) {
      if (mounted) setState(() => _usedToday = v);
    });
  }

  void _set(VoidCallback f) => setState(() {
        f();
        _dirty = true;
      });

  Future<void> _save() async {
    await _s.save();
    if (!mounted) return;
    setState(() => _dirty = false);
    KidToast.show(KidToastKind.saved, title: pT(context, 'savedTitle'), subtitle: pT(context, 'savedSub'));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          physics: const BouncingScrollPhysics(),
          children: [
            TabHeader(title: pT(context, 'timeTitle'), robot: 'robot_clock', robotW: 150),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(children: [
                _limitCard(),
                const SizedBox(height: 12),
                _quietCard(),
                const SizedBox(height: 12),
                _breakCard(),
              ]),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
        child: PButton(pT(context, 'save'), icon: Icons.save_rounded, onTap: _dirty ? _save : null),
      ),
    ]);
  }

  Widget _limitCard() {
    final idx = _steps.indexOf(_s.limitMin).clamp(0, _steps.length - 1);
    final used = _usedToday ~/ 60;
    return PCard(
      child: Column(children: [
        PTitle(Icons.schedule_rounded, pT(context, 'dailyLimit'), sub: pT(context, 'dailyLimitSub'),
            trailing: PSwitch(value: _s.limitOn, onChanged: (v) => _set(() => _s.limitOn = v))),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: _s.limitOn ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          secondChild: const SizedBox(width: double.infinity),
          firstChild: Column(children: [
            const SizedBox(height: 10),
            Text(fmtDuration(context, _s.limitMin * 60), style: ps(38, w: FontWeight.w700)),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: PC.teal,
                inactiveTrackColor: const Color(0xFFE3DFD6),
                thumbColor: PC.teal,
                trackHeight: 10,
                overlayColor: PC.teal.withOpacity(0.15),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
                activeTickMarkColor: Colors.white,
                inactiveTickMarkColor: const Color(0xFFBDB7AA),
              ),
              child: Slider(
                value: idx.toDouble(),
                min: 0,
                max: (_steps.length - 1).toDouble(),
                divisions: _steps.length - 1,
                onChanged: (v) => _set(() => _s.limitMin = _steps[v.round()]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                for (final m in _steps)
                  Text(fmtDuration(context, m * 60).replaceAll(' ', ''),
                      style: ps(12.5, color: m == _s.limitMin ? PC.teal : PC.sub, w: m == _s.limitMin ? FontWeight.w700 : FontWeight.w500)),
              ]),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFFE6EEF5), borderRadius: BorderRadius.circular(16)),
              child: Text(pT(context, 'todayUsed', {'used': used, 'max': _s.allowedToday}),
                  textAlign: TextAlign.center, style: ps(16, w: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            Text(pT(context, 'limitHow'), textAlign: TextAlign.center, style: ps(12.5, color: PC.sub, w: FontWeight.w500)),
          ]),
        ),
      ]),
    );
  }

  Widget _quietCard() {
    return PCard(
      child: Column(children: [
        PTitle(Icons.nightlight_round, pT(context, 'quietHours'), sub: pT(context, 'quietSub'),
            trailing: PSwitch(value: _s.quietOn, onChanged: (v) => _set(() => _s.quietOn = v))),
        if (_s.quietOn) ...[
          const SizedBox(height: 12),
          for (var i = 0; i < _s.quiet.length; i++) _rangeRow(i),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () async {
                final r = QuietRange('custom', 13 * 60, 14 * 60, {1, 2, 3, 4, 5, 6, 7});
                final res = await _editRange(r, isNew: true);
                if (res == 'ok') _set(() => _s.quiet.add(r));
              },
              icon: const CircleAvatar(radius: 14, backgroundColor: PC.teal, child: Icon(Icons.add_rounded, color: Colors.white, size: 20)),
              label: Text(pT(context, 'addRange'), style: ps(16, color: PC.tealDeep, w: FontWeight.w700)),
            ),
          ),
        ],
      ]),
    );
  }

  String _rangeName(QuietRange r) => r.name == 'night' || r.name == 'school' ? pT(context, 'range_${r.name}') : (r.name == 'custom' ? pT(context, 'range_custom') : r.name);

  Widget _rangeRow(int i) {
    final r = _s.quiet[i];
    final dayNames = pT(context, 'weekdays3').split(',');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(20), border: Border.all(color: PC.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Directionality(
              textDirection: Directionality.of(context),
              child: Text('${_rangeName(r)} :  ${QuietRange.hm(r.start)} → ${QuietRange.hm(r.end)}', style: ps(17, w: FontWeight.w700)),
            ),
          ),
          KidPressable(
            onTap: () async {
              final copy = QuietRange(r.name, r.start, r.end, {...r.days});
              final res = await _editRange(copy);
              if (res == 'ok') _set(() => _s.quiet[i] = copy);
              if (res == 'delete') _set(() => _s.quiet.removeAt(i));
            },
            child: Row(children: [
              Text(pT(context, 'edit'), style: ps(14, color: PC.sub)),
              const Icon(Icons.chevron_right_rounded, color: PC.ink),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (var d = 1; d <= 7; d++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: r.days.contains(d) ? PC.teal : const Color(0xFFEDE9E0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(dayNames[d - 1], style: ps(13, color: r.days.contains(d) ? Colors.white : PC.sub, w: FontWeight.w700)),
            ),
        ]),
      ]),
    );
  }

  Future<String?> _editRange(QuietRange r, {bool isNew = false}) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        final dayNames = pT(ctx, 'weekdays3').split(',');
        Future<void> pick(bool start) async {
          final cur = start ? r.start : r.end;
          final t = await showTimePicker(
            context: ctx,
            initialTime: TimeOfDay(hour: cur ~/ 60, minute: cur % 60),
            builder: (c, child) => MediaQuery(data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true), child: child!),
          );
          if (t != null) setS(() => start ? r.start = t.hour * 60 + t.minute : r.end = t.hour * 60 + t.minute);
        }

        Widget timeBox(bool start) => Expanded(
              child: KidPressable(
                onTap: () => pick(start),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: PC.line, width: 2)),
                  child: Column(children: [
                    Text(pT(ctx, start ? 'from' : 'to'), style: ps(13, color: PC.sub)),
                    Text(QuietRange.hm(start ? r.start : r.end), style: ps(28, w: FontWeight.w700)),
                  ]),
                ),
              ),
            );
        return Container(
          padding: EdgeInsets.fromLTRB(18, 14, 18, 18 + MediaQuery.paddingOf(ctx).bottom),
          decoration: const BoxDecoration(color: PC.cream, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: PC.line, borderRadius: BorderRadius.circular(5)))),
            const SizedBox(height: 12),
            Text(_rangeName(r), style: ps(24, w: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(children: [timeBox(true), const SizedBox(width: 10), const Icon(Icons.arrow_forward_rounded, color: PC.teal), const SizedBox(width: 10), timeBox(false)]),
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
              for (var d = 1; d <= 7; d++)
                KidPressable(
                  onTap: () => setS(() => r.days.contains(d) ? r.days.remove(d) : r.days.add(d)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: r.days.contains(d) ? PC.teal : const Color(0xFFEDE9E0), borderRadius: BorderRadius.circular(18)),
                    child: Text(dayNames[d - 1], style: ps(15, color: r.days.contains(d) ? Colors.white : PC.sub, w: FontWeight.w700)),
                  ),
                ),
            ]),
            const SizedBox(height: 18),
            PButton(pT(ctx, isNew ? 'add' : 'ok'), onTap: () => Navigator.pop(ctx, 'ok')),
            if (!isNew) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'delete'),
                child: Text(pT(ctx, 'delete'), style: ps(15, color: const Color(0xFFD9214E))),
              ),
            ],
          ]),
        );
      }),
    );
  }

  Widget _breakCard() {
    return PCard(
      child: Column(children: [
        PTitle(Icons.coffee_rounded, pT(context, 'breakTitle'), sub: pT(context, 'breakSub'),
            trailing: PSwitch(value: _s.breakOn, onChanged: (v) => _set(() => _s.breakOn = v))),
        if (_s.breakOn) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: const Color(0xFFEDE9E0), borderRadius: BorderRadius.circular(26)),
            child: Row(children: [
              for (final m in const [20, 25, 30])
                Expanded(
                  child: KidPressable(
                    onTap: () => _set(() => _s.breakMin = m),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: _s.breakMin == m ? PC.teal : Colors.transparent, borderRadius: BorderRadius.circular(22)),
                      child: Text('$m min', style: ps(17, color: _s.breakMin == m ? Colors.white : PC.ink, w: FontWeight.w700)),
                    ),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFFE3F1F8), borderRadius: BorderRadius.circular(16)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.hourglass_bottom_rounded, color: PC.tealDeep),
              const SizedBox(width: 6),
              Text(pT(context, 'breakAdvice'), style: ps(15, color: PC.tealDeep, w: FontWeight.w600)),
            ]),
          ),
        ],
      ]),
    );
  }
}
