import 'package:flutter/material.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:mortaalim/widgets/KidScene/kid_toast.dart';
import 'package:provider/provider.dart';

import 'parent_data.dart';
import 'parent_strings.dart';
import 'parent_ui.dart';
import 'parents_space.dart';

/// "Contenu": sections on/off, school level, focus subjects, languages.
class ContentTab extends StatefulWidget {
  const ContentTab({super.key});

  @override
  State<ContentTab> createState() => _ContentTabState();
}

class _ContentTabState extends State<ContentTab> {
  final ParentSettings _s = ParentSettings.I;
  late String _level, _grade, _appLang;
  bool _dirty = false;

  static const _levels = {
    'Primary': ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6'],
    'Middle School': ['Grade 7', 'Grade 8', 'Grade 9'],
    'High School': ['Common Track', '1st Year Bac', 'Baccalaureate'],
  };
  static const _langs = ['fr', 'ar', 'en', 'de', 'zgh'];
  static const _learnLangs = ['ar', 'fr', 'en'];

  @override
  void initState() {
    super.initState();
    final u = Provider.of<ExperienceManager>(context, listen: false).userProfile;
    _level = _levels.containsKey(u.schoolLevel) ? u.schoolLevel : 'Primary';
    _grade = _levels[_level]!.contains(u.schoolGrade) ? u.schoolGrade : _levels[_level]!.first;
    _appLang = _langs.contains(u.preferredLanguage) ? u.preferredLanguage : 'fr';
  }

  void _set(VoidCallback f) => setState(() {
        f();
        _dirty = true;
      });

  Future<void> _save() async {
    final xp = Provider.of<ExperienceManager>(context, listen: false);
    await _s.save();
    xp.setSchoolLevel(_level);
    xp.setSchoolGrade(_grade);
    if (xp.userProfile.preferredLanguage != _appLang) await xp.changeLanguage(Locale(_appLang));
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
            TabHeader(title: pT(context, 'contentTitle'), sub: pT(context, 'contentSub', {'name': childName(context)}), robot: 'robot_wave2', robotW: 130),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(children: [
                _sectionsCard(),
                const SizedBox(height: 12),
                _levelCard(),
                const SizedBox(height: 12),
                _langCard(),
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

  Widget _sectionsCard() {
    const rows = [
      ('games', Icons.sports_esports_rounded, Color(0xFF14A3A8)),
      ('stories', Icons.auto_stories_rounded, Color(0xFF7C4DDB)),
      ('religion', Icons.mosque_rounded, Color(0xFF14937A)),
      ('creativity', Icons.palette_rounded, Color(0xFFFF8A1E)),
      ('ai', Icons.smart_toy_rounded, Color(0xFF7A6BD0)),
    ];
    return PCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.extension_rounded, color: Color(0xFF7C4DDB), size: 30),
          const SizedBox(width: 8),
          Text(pT(context, 'allowedSections'), style: ps(20, w: FontWeight.w700)),
        ]),
        const SizedBox(height: 6),
        for (var i = 0; i < rows.length; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              Icon(rows[i].$2, color: rows[i].$3, size: 40),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(pT(context, 'sec_${rows[i].$1}'), style: ps(17, w: FontWeight.w700)),
                  Text(pT(context, rows[i].$1 == 'ai' && !_s.allows('ai') ? 'sec_ai_off' : 'sec_${rows[i].$1}_sub'),
                      style: ps(13.5, color: PC.sub, w: FontWeight.w500)),
                ]),
              ),
              PSwitch(value: _s.allows(rows[i].$1), onChanged: (v) => _set(() => _s.sections[rows[i].$1] = v)),
            ]),
          ),
          if (i < rows.length - 1) const Divider(height: 1, color: PC.line, indent: 54),
        ],
      ]),
    );
  }

  Widget _dropdown<T>(T value, List<T> items, String Function(T) label, ValueChanged<T> onChanged, {Widget? lead}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: PC.lav, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white, width: 2)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            borderRadius: BorderRadius.circular(16),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: PC.ink),
            items: [
              for (final it in items)
                DropdownMenuItem(
                  value: it,
                  child: Row(children: [
                    if (lead != null && it == value) ...[lead, const SizedBox(width: 8)],
                    Flexible(child: Text(label(it), overflow: TextOverflow.ellipsis, style: ps(16.5, w: FontWeight.w600))),
                  ]),
                ),
            ],
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      );

  Widget _levelCard() {
    const subjects = [
      ('math', Icons.functions_rounded),
      ('french', Icons.menu_book_rounded),
      ('arabic', Icons.translate_rounded),
      ('science', Icons.science_rounded),
      ('islamicEducation', Icons.mosque_rounded),
    ];
    final options = [for (final l in _levels.entries) for (final g in l.value) '${l.key}|$g'];
    return PCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.school_rounded, color: Color(0xFF7C4DDB), size: 30),
          const SizedBox(width: 8),
          Text(pT(context, 'schoolLevel'), style: ps(20, w: FontWeight.w700)),
        ]),
        const SizedBox(height: 10),
        _dropdown<String>('$_level|$_grade', options, (o) {
          final p = o.split('|');
          return '${pT(context, 'lvl_${p[0]}')} · ${pT(context, 'grd_${p[1]}')}';
        }, (o) {
          final p = o.split('|');
          _set(() {
            _level = p[0];
            _grade = p[1];
          });
        }),
        const SizedBox(height: 16),
        Row(children: [
          const Icon(Icons.layers_rounded, color: Color(0xFF7C4DDB), size: 28),
          const SizedBox(width: 8),
          Text(pT(context, 'focusSubjects'), style: ps(18, w: FontWeight.w700)),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final s in subjects)
            KidPressable(
              onTap: () => _set(() => _s.focus.contains(s.$1) ? _s.focus.remove(s.$1) : _s.focus.add(s.$1)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                decoration: BoxDecoration(
                  color: _s.focus.contains(s.$1) ? const Color(0xFFE5F8F7) : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: _s.focus.contains(s.$1) ? PC.teal : const Color(0xFFB9A8E8), width: 2),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(s.$2, color: const Color(0xFF3B2F7A), size: 22),
                  const SizedBox(width: 6),
                  Text(pT(context, 'subj_${s.$1}'), style: ps(15, w: FontWeight.w700)),
                  const SizedBox(width: 6),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _s.focus.contains(s.$1) ? 1 : 0,
                    child: const CircleAvatar(radius: 12, backgroundColor: PC.teal, child: Icon(Icons.check_rounded, color: Colors.white, size: 16)),
                  ),
                ]),
              ),
            ),
        ]),
      ]),
    );
  }

  Widget _flag(String code) => Text(const {'fr': '🇫🇷', 'ar': '🇲🇦', 'en': '🇬🇧', 'de': '🇩🇪', 'zgh': 'ⵣ'}[code] ?? '', style: const TextStyle(fontSize: 20));

  Widget _langCard() {
    return PCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.public_rounded, color: Color(0xFF7C4DDB), size: 30),
          const SizedBox(width: 8),
          Text(pT(context, 'languages'), style: ps(20, w: FontWeight.w700)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Text(pT(context, 'appLang'), style: ps(15.5, w: FontWeight.w500))),
          SizedBox(width: 190, child: _dropdown<String>(_appLang, _langs, (c) => langName(c), (c) => _set(() => _appLang = c), lead: _flag(_appLang))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: Text(pT(context, 'learnLang'), style: ps(15.5, w: FontWeight.w500))),
          SizedBox(
            width: 190,
            child: _dropdown<String>(_s.learnLang, _learnLangs, (c) => langName(c), (c) => _set(() => _s.learnLang = c), lead: _flag(_s.learnLang)),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.info_rounded, color: Color(0xFF8E86A8), size: 20),
          const SizedBox(width: 6),
          Expanded(child: Text(pT(context, 'langNote'), style: ps(13, color: PC.sub, w: FontWeight.w500))),
        ]),
      ]),
    );
  }
}

String langName(String c) =>
    const {'fr': 'Français', 'ar': 'العربية', 'en': 'English', 'de': 'Deutsch', 'zgh': 'ⵜⴰⵎⴰⵣⵉⵖⵜ'}[c] ?? c;
