import 'package:flutter/material.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';

import 'parent_data.dart';
import 'parent_gate.dart';
import 'parent_strings.dart';
import 'parent_ui.dart';
import 'tab_account.dart';
import 'tab_content.dart';
import 'tab_dashboard.dart';
import 'tab_family.dart';
import 'tab_time.dart';

/// Opens the Parents Space behind the adult gate.
Future<void> openParentsSpace(BuildContext context, {int tab = 0}) async {
  if (!await ParentGate.check(context)) return;
  await ParentSettings.I.load();
  if (!context.mounted) return;
  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ParentsSpace(initialTab: tab)));
}

class ParentsSpace extends StatefulWidget {
  final int initialTab;
  const ParentsSpace({super.key, this.initialTab = 0});

  @override
  State<ParentsSpace> createState() => _ParentsSpaceState();
}

class _ParentsSpaceState extends State<ParentsSpace> {
  late int _tab = widget.initialTab;

  static const _tabs = [
    (Icons.bar_chart_rounded, 'tabFollow'),
    (Icons.schedule_rounded, 'tabTime'),
    (Icons.shield_rounded, 'tabContent'),
    (Icons.groups_rounded, 'tabFamily'),
    (Icons.settings_rounded, 'tabAccount'),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      const DashboardTab(),
      const TimeTab(),
      const ContentTab(),
      const FamilyTab(),
      const AccountTab(),
    ];
    return Scaffold(
      backgroundColor: PC.cream,
      body: ParentBackground(
        child: Column(children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: KeyedSubtree(key: ValueKey(_tab), child: pages[_tab]),
            ),
          ),
          _nav(context),
        ]),
      ),
    );
  }

  Widget _nav(BuildContext context) {
    final pad = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + pad),
      decoration: BoxDecoration(
        color: PC.cream,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: const Color(0xFF3B2A7A).withOpacity(0.12), blurRadius: 18, offset: const Offset(0, -4))],
      ),
      child: Row(children: [
        for (var i = 0; i < _tabs.length; i++)
          Expanded(
            child: KidPressable(
              onTap: () => setState(() => _tab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 8),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i == _tab ? PC.teal : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_tabs[i].$1, color: i == _tab ? Colors.white : const Color(0xFF6E6690), size: 28),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(pT(context, _tabs[i].$2),
                        style: ps(13.5, color: i == _tab ? Colors.white : const Color(0xFF6E6690), w: FontWeight.w700)),
                  ),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

/// Common page header for the tabs: title + subtitle on the left, robot on the right.
class TabHeader extends StatelessWidget {
  final String title;
  final String? sub;
  final String robot;
  final double robotW;
  final bool showChild;
  const TabHeader({super.key, required this.title, this.sub, required this.robot, this.robotW = 150, this.showChild = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 8, 8, 0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              KidPressable(
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: PC.cream,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: PC.teal),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: PC.cream.withOpacity(0.9), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.lock_rounded, size: 16, color: PC.ink),
                  const SizedBox(width: 4),
                  Text(pT(context, 'parentsSpace'), style: ps(13, w: FontWeight.w700)),
                ]),
              ),
            ]),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(title, style: ps(32, w: FontWeight.w700, h: 1.05).copyWith(shadows: [Shadow(color: Colors.white, blurRadius: 10)])),
            ),
            if (sub != null)
              Text(sub!, style: ps(15, color: PC.ink.withOpacity(0.75), w: FontWeight.w500).copyWith(shadows: [Shadow(color: Colors.white, blurRadius: 8)])),
            if (showChild) ...[const SizedBox(height: 10), const ChildChip(showAge: true)],
            const SizedBox(height: 10),
          ]),
        ),
        Image.asset(pa(robot), width: robotW),
      ]),
    );
  }
}
