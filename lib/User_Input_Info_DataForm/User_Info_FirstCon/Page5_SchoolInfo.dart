import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/widgets/KidScene/kid_form.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:provider/provider.dart';

import '../../XpSystem.dart';
import '../../tools/audio_tool/Audio_Manager.dart';

/// Onboarding — "Tell us about your school" (shown when the child said they
/// go to school). Stored values are the same English keys as before
/// ('Public', 'Primary', 'Grade 1', 'Science', …).
class SchoolInfoPage extends StatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;

  const SchoolInfoPage({Key? key, this.onNext, this.onBack}) : super(key: key);

  @override
  State<SchoolInfoPage> createState() => _SchoolInfoPageState();
}

class _SchoolInfoPageState extends State<SchoolInfoPage> with TickerProviderStateMixin {
  final TextEditingController _schoolNameController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();

  String? _selectedSchoolType;
  String? _selectedSchoolLevel;
  String? _selectedGrade;
  String? _selectedLyceeTrack;
  bool _preferNotToSaySchool = false;
  bool _precached = false;

  static const List<String> schoolTypes = ['Public', 'Private', 'Other'];
  static const List<String> schoolLevels = ['Primary', 'Middle School', 'High School'];
  static const Map<String, List<String>> gradesByLevel = {
    'Primary': ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6'],
    'Middle School': ['Grade 7', 'Grade 8', 'Grade 9'],
    'High School': ['Common Track', '1st Year Bac', 'Baccalaureate'],
  };
  static const List<String> lyceeTracks = ['Science', 'Arts'];

  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  late final AnimationController _idle =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();

  static const List<String> _assets = [
    KidAssets.valleyBg,
    KidAssets.wordmark,
    KidAssets.backBtn,
    KidAssets.mascotPeek,
    KidAssets.exclaim,
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _nameFocus.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      KidAssets.precache(context, _assets);
      _intro.forward();
    }
  }

  void _loadProfile() {
    final user = Provider.of<ExperienceManager>(context, listen: false).userProfile;
    final name = user.schoolName;
    if (name == 'Prefer not to say') {
      _preferNotToSaySchool = true;
    } else if (name != 'Not a student') {
      _schoolNameController.text = name;
    }
    _selectedSchoolType = schoolTypes.contains(user.schoolType) ? user.schoolType : null;
    _selectedSchoolLevel = schoolLevels.contains(user.schoolLevel) ? user.schoolLevel : null;
    final grades = gradesByLevel[_selectedSchoolLevel] ?? const [];
    _selectedGrade = grades.contains(user.schoolGrade) ? user.schoolGrade : null;
    _selectedLyceeTrack = lyceeTracks.contains(user.lyceeTrack) ? user.lyceeTrack : null;
  }

  @override
  void dispose() {
    _schoolNameController.dispose();
    _nameFocus.dispose();
    _intro.dispose();
    _idle.dispose();
    super.dispose();
  }

  // ── Localized labels ─────────────────────────────────────────────────────
  String _type(String t) {
    switch (t) {
      case 'Private':
        return tr(context).schoolTypePrivate;
      case 'Public':
        return tr(context).schoolTypePublic;
      default:
        return tr(context).schoolTypeOther;
    }
  }

  String _level(String l) {
    switch (l) {
      case 'Primary':
        return tr(context).schoolLevelPrimary;
      case 'Middle School':
        return tr(context).schoolLevelMiddle;
      default:
        return tr(context).schoolLevelHigh;
    }
  }

  String _grade(String g) {
    switch (g) {
      case 'Grade 1':
        return tr(context).gradesPrimary1;
      case 'Grade 2':
        return tr(context).gradesPrimary2;
      case 'Grade 3':
        return tr(context).gradesPrimary3;
      case 'Grade 4':
        return tr(context).gradesPrimary4;
      case 'Grade 5':
        return tr(context).gradesPrimary5;
      case 'Grade 6':
        return tr(context).gradesPrimary6;
      case 'Grade 7':
        return tr(context).gradesMiddle1;
      case 'Grade 8':
        return tr(context).gradesMiddle2;
      case 'Grade 9':
        return tr(context).gradesMiddle3;
      case 'Common Track':
        return tr(context).gradesHigh1;
      case '1st Year Bac':
        return tr(context).gradesHigh2;
      case 'Baccalaureate':
        return tr(context).gradesHigh3;
      default:
        return g;
    }
  }

  String _track(String t) =>
      t == 'Science' ? tr(context).lyceeTrackScience : tr(context).lyceeTrackLiterature;

  bool get _isHigh => _selectedSchoolLevel == 'High School';

  bool get _isValid =>
      _selectedSchoolType != null &&
      _selectedSchoolLevel != null &&
      _selectedGrade != null &&
      (!_isHigh || _selectedLyceeTrack != null);

  // ── Pickers ──────────────────────────────────────────────────────────────
  Future<void> _pickLevel() async {
    FocusScope.of(context).unfocus();
    final am = Provider.of<AudioManager>(context, listen: false)..playEventSound('PopButton');
    final v = await showKidOptionSheet<String>(
      context: context,
      title: tr(context).chooseSchoolLevel,
      options: schoolLevels,
      selected: _selectedSchoolLevel,
      label: _level,
      leading: (l) => Text(l == 'Primary' ? '🎒' : (l == 'Middle School' ? '📚' : '🎓'),
          style: const TextStyle(fontSize: 24)),
    );
    if (v == null || !mounted) return;
    am.playEventSound('clickButton2');
    setState(() {
      if (v != _selectedSchoolLevel) {
        _selectedGrade = null;
        _selectedLyceeTrack = null;
      }
      _selectedSchoolLevel = v;
    });
  }

  Future<void> _pickGrade() async {
    if (_selectedSchoolLevel == null) return;
    FocusScope.of(context).unfocus();
    final am = Provider.of<AudioManager>(context, listen: false)..playEventSound('PopButton');
    final v = await showKidOptionSheet<String>(
      context: context,
      title: tr(context).chooseGrade,
      options: gradesByLevel[_selectedSchoolLevel]!,
      selected: _selectedGrade,
      label: _grade,
    );
    if (v == null || !mounted) return;
    am.playEventSound('clickButton2');
    setState(() => _selectedGrade = v);
  }

  Future<void> _pickTrack() async {
    FocusScope.of(context).unfocus();
    final am = Provider.of<AudioManager>(context, listen: false)..playEventSound('PopButton');
    final v = await showKidOptionSheet<String>(
      context: context,
      title: tr(context).chooseTrack,
      options: lyceeTracks,
      selected: _selectedLyceeTrack,
      label: _track,
      leading: (t) => Text(t == 'Science' ? '🔬' : '📖', style: const TextStyle(fontSize: 24)),
    );
    if (v == null || !mounted) return;
    am.playEventSound('clickButton2');
    setState(() => _selectedLyceeTrack = v);
  }

  void _save() {
    final em = Provider.of<ExperienceManager>(context, listen: false);
    final name = _schoolNameController.text.trim();
    em.setSchoolName(_preferNotToSaySchool || name.isEmpty ? 'Prefer not to say' : name);
    em.setSchoolType(_selectedSchoolType!);
    em.setSchoolLevel(_selectedSchoolLevel!);
    em.setSchoolGrade(_selectedGrade!);
    em.setLyceeTrack(_isHigh ? _selectedLyceeTrack! : '');
  }

  void _continue() {
    if (!_isValid) return;
    Provider.of<AudioManager>(context, listen: false).playEventSound('clickButton');
    FocusScope.of(context).unfocus();
    _save();
    widget.onNext?.call();
  }

  void _skip() {
    Provider.of<AudioManager>(context, listen: false).playEventSound('clickButton');
    FocusScope.of(context).unfocus();
    widget.onNext?.call();
  }

  @override
  Widget build(BuildContext context) {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    final mq = MediaQuery.of(context);
    final size = mq.size;
    final pad = mq.padding;
    final g = KidSceneGeometry(size);
    final headerShift = max(0.0, pad.top + 6 - g.y(48));
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final buttonH = g.lc(130, 50, 70);
    final buttonTop = min(g.y(1458), size.height - pad.bottom - buttonH - 46);
    final linkH = g.lc(50, 30, 38);
    final panelTop = g.y(415) + headerShift * 0.5;
    final panelBottom = buttonTop - linkH - 4;
    final panelW = g.contentWidth(810, pad: 14);
    final fieldH = g.lc(88, 44, 54);
    final labelSize = g.lc(31, 14, 17);
    final keyboard = mq.viewInsets.bottom;

    Widget gap([double v = 18]) => SizedBox(height: g.l(v));

    final panel = Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF6),
        borderRadius: BorderRadius.circular(g.lc(44, 22, 30)),
        border: Border.all(color: const Color(0xFFD9CCF7), width: 3),
        boxShadow: [
          BoxShadow(color: KidColors.purpleDeep.withOpacity(0.16), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(g.lc(44, 22, 30)),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(g.l(40), g.l(34), g.l(40), g.l(30) + keyboard * 0.6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KidFieldLabel(tr(context).schoolName, tag: tr(context).optionalTag, size: labelSize),
              _NameField(
                controller: _schoolNameController,
                focusNode: _nameFocus,
                height: fieldH,
                hint: tr(context).enterSchoolName,
                enabled: !_preferNotToSaySchool,
                onTap: () => audioManager.playEventSound('PopButton'),
              ),
              gap(12),
              _CheckRow(
                label: tr(context).preferNotToSay,
                value: _preferNotToSaySchool,
                size: labelSize,
                onChanged: (v) {
                  audioManager.playEventSound('clickButton2');
                  FocusScope.of(context).unfocus();
                  setState(() => _preferNotToSaySchool = v);
                },
              ),
              gap(22),
              KidFieldLabel(tr(context).schoolType, size: labelSize),
              Row(
                children: [
                  for (int i = 0; i < schoolTypes.length; i++) ...[
                    if (i > 0) SizedBox(width: g.l(12)),
                    Expanded(
                      child: _Segment(
                        label: _type(schoolTypes[i]),
                        selected: _selectedSchoolType == schoolTypes[i],
                        height: fieldH,
                        onTap: () {
                          audioManager.playEventSound('clickButton2');
                          FocusScope.of(context).unfocus();
                          setState(() => _selectedSchoolType = schoolTypes[i]);
                        },
                      ),
                    ),
                  ],
                ],
              ),
              gap(22),
              KidFieldLabel(tr(context).schoolLevel, size: labelSize),
              KidSelectField(
                height: fieldH,
                value: _selectedSchoolLevel == null ? null : _level(_selectedSchoolLevel!),
                hint: tr(context).chooseSchoolLevel,
                onTap: _pickLevel,
              ),
              gap(22),
              KidFieldLabel(tr(context).grade, size: labelSize),
              KidSelectField(
                height: fieldH,
                value: _selectedGrade == null ? null : _grade(_selectedGrade!),
                hint: tr(context).chooseGrade,
                onTap: _selectedSchoolLevel == null ? null : _pickGrade,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _isHigh
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          gap(22),
                          KidFieldLabel(tr(context).highSchoolTrack, size: labelSize),
                          KidSelectField(
                            height: fieldH,
                            value: _selectedLyceeTrack == null ? null : _track(_selectedLyceeTrack!),
                            hint: tr(context).chooseTrack,
                            onTap: _pickTrack,
                          ),
                          Padding(
                            padding: const EdgeInsetsDirectional.only(start: 10, top: 6),
                            child: Text(tr(context).trackHighSchoolOnly,
                                style: kidBodyStyle(labelSize * 0.75, color: KidColors.muted)),
                          ),
                        ],
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: KidColors.sky,
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            KidSceneBackground(asset: KidAssets.valleyBg, g: g),

            Positioned(
              left: 0,
              right: 0,
              top: headerShift,
              height: g.y(200),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Stack(children: [
                  SceneSprite(
                    g: g, asset: KidAssets.wordmark, left: 272, top: 62, width: 398, aspect: 0.2289,
                    idle: _idle, intro: _intro, introFrom: 0, introTo: 0.45, bob: 4,
                  ),
                ]),
              ),
            ),

            // Title (left of the peeking mascot)
            Positioned(
              left: g.fitLeft(140, 600, bleed: 0, margin: 12),
              width: min(g.l(600), size.width * 0.72),
              top: g.y(170) + headerShift * 0.5,
              height: g.l(220),
              child: KidIntro(
                intro: _intro,
                from: 0.15,
                to: 0.6,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          tr(context).schoolTitle.replaceFirst(' ', '\n', _mid(tr(context).schoolTitle)),
                          textAlign: TextAlign.center,
                          style: kidTitleStyle(g.lc(82, 24, 44)),
                        ),
                      ),
                    ),
                    SizedBox(height: g.l(6)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(tr(context).schoolSubtitle,
                          style: kidBodyStyle(g.lc(32, 13, 18), color: KidColors.ink, weight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),

            // Form panel
            Positioned(
              left: (size.width - panelW) / 2,
              width: panelW,
              top: panelTop,
              height: max(160.0, panelBottom - panelTop),
              child: KidIntro(intro: _intro, from: 0.3, to: 0.8, rise: 40, child: panel),
            ),

            // Mascot peeking over the panel
            Positioned.fill(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: IgnorePointer(
                  child: Stack(children: [
                    SceneSprite(
                      g: g, asset: KidAssets.mascotPeek,
                      left: 688, top: (panelTop / g.s) - 245 * 1.0914 + 8, width: 245, aspect: 1.0914,
                      idle: _idle, intro: _intro, introFrom: 0.45, introTo: 0.9,
                      pop: false, bob: 3, rot: 0.02, phase: 0.3, speed: 2,
                    ),
                    SceneSprite(
                      g: g, asset: KidAssets.exclaim,
                      left: 866, top: (panelTop / g.s) - 262, width: 64, aspect: 1.0157,
                      idle: _idle, intro: _intro, introFrom: 0.6, introTo: 1.0,
                      bob: 4, rot: 0.1, phase: 0.6, speed: 2,
                    ),
                  ]),
                ),
              ),
            ),

            // Skip + Continue
            Positioned(
              left: 0,
              right: 0,
              top: buttonTop - linkH,
              child: KidIntro(
                intro: _intro,
                from: 0.6,
                to: 1.0,
                child: Column(
                  children: [
                    SizedBox(
                      height: linkH,
                      child: Center(
                        child: KidLink(text: tr(context).skipForNow, onTap: _skip, size: g.lc(28, 12, 15)),
                      ),
                    ),
                    KidButton(
                      label: tr(context).continueLabel,
                      width: g.contentWidth(722, pad: 24),
                      height: buttonH,
                      onPressed: _isValid ? _continue : null,
                    ),
                  ],
                ),
              ),
            ),

            if (widget.onBack != null)
              Positioned(
                top: g.y(46) + headerShift,
                left: isRtl ? null : g.fitLeft(42, 88, bleed: 0),
                right: isRtl ? g.fitLeft(42, 88, bleed: 0) : null,
                child: KidIntro(
                  intro: _intro,
                  from: 0.1,
                  to: 0.5,
                  rise: -10,
                  child: KidBackButton(
                    size: g.lc(88, 40, 52),
                    onTap: () {
                      audioManager.playEventSound('cancelButton');
                      FocusScope.of(context).unfocus();
                      widget.onBack!.call();
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static int _mid(String s) {
    final spaces = <int>[];
    for (int i = 0; i < s.length; i++) {
      if (s[i] == ' ') spaces.add(i);
    }
    if (spaces.isEmpty) return s.length;
    final mid = s.length / 2;
    spaces.sort((a, b) => (a - mid).abs().compareTo((b - mid).abs()));
    return spaces.first;
  }
}

class _NameField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final double height;
  final String hint;
  final bool enabled;
  final VoidCallback onTap;

  const _NameField({
    required this.controller,
    required this.focusNode,
    required this.height,
    required this.hint,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final h = height;
    final focused = focusNode.hasFocus;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.45,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: h,
        padding: EdgeInsets.symmetric(horizontal: h * 0.32),
        alignment: AlignmentDirectional.centerStart,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(h * 0.42),
          border: Border.all(
              color: focused ? KidColors.purple : const Color(0xFFC7B2F6), width: focused ? 3 : 2.5),
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          onTap: onTap,
          maxLength: 60,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          cursorColor: KidColors.purple,
          style: kidBodyStyle(h * 0.33, color: KidColors.ink, weight: FontWeight.w600),
          decoration: InputDecoration(
            counterText: '',
            isDense: true,
            border: InputBorder.none,
            hintText: hint,
            hintStyle: kidBodyStyle(h * 0.33, color: const Color(0xFFA996D6), weight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String label;
  final bool value;
  final double size;
  final ValueChanged<bool> onChanged;

  const _CheckRow({required this.label, required this.value, required this.size, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final box = size * 1.55;
    return KidPressable(
      onTap: () => onChanged(!value),
      pressedScale: 0.97,
      child: Row(
        children: [
          const SizedBox(width: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: box,
            height: box,
            decoration: BoxDecoration(
              color: value ? KidColors.purple : Colors.white,
              borderRadius: BorderRadius.circular(box * 0.28),
              border: Border.all(color: value ? KidColors.purple : const Color(0xFFC7B2F6), width: 2.5),
            ),
            child: AnimatedScale(
              scale: value ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: Icon(Icons.check_rounded, color: Colors.white, size: box * 0.75),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(child: Text(label, style: kidBodyStyle(size, color: KidColors.ink))),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final double height;
  final VoidCallback onTap;

  const _Segment({required this.label, required this.selected, required this.height, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final h = height;
    return KidPressable(
      onTap: onTap,
      pressedScale: 0.95,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: h,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFDCCBFF) : Colors.white,
          borderRadius: BorderRadius.circular(h * 0.32),
          border: Border.all(
            color: selected ? KidColors.purple : const Color(0xFFC7B2F6),
            width: selected ? 3.5 : 2.5,
          ),
          boxShadow: selected
              ? [BoxShadow(color: KidColors.purple.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
              : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label,
              style: kidBodyStyle(h * 0.33, color: KidColors.purpleDeep, weight: FontWeight.w700)),
        ),
      ),
    );
  }
}
