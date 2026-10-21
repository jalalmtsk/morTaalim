import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/screens/main_home_screen/Profile/Customize/profile_look.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/KidScene/kid_page_parts.dart';
import 'package:provider/provider.dart';

/// "Edit profile" — name, age group, country, city and (optional) school.
/// Class name kept so every place that opens it gets the new screen.
class UserAndSchoolInfoPage extends StatefulWidget {
  const UserAndSchoolInfoPage({Key? key}) : super(key: key);

  @override
  State<UserAndSchoolInfoPage> createState() => _UserAndSchoolInfoPageState();
}

const String _dir = 'assets/images/UI/EditProfile/';
const Color _ink = Color(0xFF2A1A78);
const Color _inkSoft = Color(0xFF7A68B8);
const Color _purple = Color(0xFF6D3BF5);
const Color _fieldFill = Color(0xFFF4F1FF);
const Color _fieldBorder = Color(0xFFCDBEFF);
const Color _cream = Color(0xFFFFFBF2);

TextStyle _f(double size, {Color color = _ink, FontWeight weight = FontWeight.w600}) =>
    TextStyle(fontFamily: 'Fredoka', fontSize: size, color: color, fontWeight: weight);

// ─── Age groups ──────────────────────────────────────────────────────────────

class _AgeGroup {
  final String label;
  final int min, max, saveAs; // saveAs = age stored when the group is picked
  const _AgeGroup(this.label, this.min, this.max, this.saveAs);
  bool has(int age) => age >= min && age <= max;
}

const List<_AgeGroup> _ageGroups = [
  _AgeGroup('3 – 6', 3, 6, 5),
  _AgeGroup('7 – 9', 7, 9, 8),
  _AgeGroup('10 – 12', 10, 12, 11),
  _AgeGroup('13+', 13, 120, 13),
];

// ─── Countries / cities ──────────────────────────────────────────────────────

class _Country {
  final String id; // stored value (English name)
  final String flag;
  final Map<String, String> names;
  const _Country(this.id, this.flag, this.names);
  String name(String lang) => names[lang] ?? id;
  bool matches(String v) {
    final x = v.trim().toLowerCase();
    return x == id.toLowerCase() || names.values.any((n) => n.toLowerCase() == x);
  }
}

const List<_Country> _countries = [
  _Country('Morocco', '🇲🇦', {'fr': 'Maroc', 'en': 'Morocco', 'ar': 'المغرب', 'de': 'Marokko'}),
  _Country('Algeria', '🇩🇿', {'fr': 'Algérie', 'en': 'Algeria', 'ar': 'الجزائر', 'de': 'Algerien'}),
  _Country('Tunisia', '🇹🇳', {'fr': 'Tunisie', 'en': 'Tunisia', 'ar': 'تونس', 'de': 'Tunesien'}),
  _Country('Mauritania', '🇲🇷', {'fr': 'Mauritanie', 'en': 'Mauritania', 'ar': 'موريتانيا', 'de': 'Mauretanien'}),
  _Country('Egypt', '🇪🇬', {'fr': 'Égypte', 'en': 'Egypt', 'ar': 'مصر', 'de': 'Ägypten'}),
  _Country('Saudi Arabia', '🇸🇦', {'fr': 'Arabie saoudite', 'en': 'Saudi Arabia', 'ar': 'السعودية', 'de': 'Saudi-Arabien'}),
  _Country('United Arab Emirates', '🇦🇪', {'fr': 'Émirats arabes unis', 'en': 'United Arab Emirates', 'ar': 'الإمارات', 'de': 'VAE'}),
  _Country('Qatar', '🇶🇦', {'fr': 'Qatar', 'en': 'Qatar', 'ar': 'قطر', 'de': 'Katar'}),
  _Country('Senegal', '🇸🇳', {'fr': 'Sénégal', 'en': 'Senegal', 'ar': 'السنغال', 'de': 'Senegal'}),
  _Country('France', '🇫🇷', {'fr': 'France', 'en': 'France', 'ar': 'فرنسا', 'de': 'Frankreich'}),
  _Country('Belgium', '🇧🇪', {'fr': 'Belgique', 'en': 'Belgium', 'ar': 'بلجيكا', 'de': 'Belgien'}),
  _Country('Spain', '🇪🇸', {'fr': 'Espagne', 'en': 'Spain', 'ar': 'إسبانيا', 'de': 'Spanien'}),
  _Country('Italy', '🇮🇹', {'fr': 'Italie', 'en': 'Italy', 'ar': 'إيطاليا', 'de': 'Italien'}),
  _Country('Germany', '🇩🇪', {'fr': 'Allemagne', 'en': 'Germany', 'ar': 'ألمانيا', 'de': 'Deutschland'}),
  _Country('Netherlands', '🇳🇱', {'fr': 'Pays-Bas', 'en': 'Netherlands', 'ar': 'هولندا', 'de': 'Niederlande'}),
  _Country('United Kingdom', '🇬🇧', {'fr': 'Royaume-Uni', 'en': 'United Kingdom', 'ar': 'المملكة المتحدة', 'de': 'Vereinigtes Königreich'}),
  _Country('Canada', '🇨🇦', {'fr': 'Canada', 'en': 'Canada', 'ar': 'كندا', 'de': 'Kanada'}),
  _Country('United States', '🇺🇸', {'fr': 'États-Unis', 'en': 'United States', 'ar': 'الولايات المتحدة', 'de': 'USA'}),
];

const List<String> _moroccanCities = [
  'Casablanca', 'Rabat', 'Marrakech', 'Fès', 'Tanger', 'Agadir', 'Meknès', 'Oujda', 'Kénitra', 'Tétouan',
  'Salé', 'Témara', 'Mohammédia', 'El Jadida', 'Safi', 'Béni Mellal', 'Nador', 'Taza', 'Khouribga', 'Settat',
  'Berrechid', 'Larache', 'Ksar El Kébir', 'Khémisset', 'Guelmim', 'Errachidia', 'Ouarzazate', 'Essaouira',
  'Laâyoune', 'Dakhla', 'Al Hoceïma', 'Ifrane', 'Chefchaouen', 'Tiznit', 'Taroudant', 'Berkane', 'Sefrou',
];

// ─── School data (kept from the old screen, stored as before) ────────────────

const List<String> _schoolTypes = ['Privé', 'Publique', 'Autre'];
const List<String> _schoolLevels = ['Primaire', 'Collège', 'Lycée'];
const Map<String, List<String>> _gradesByLevel = {
  'Primaire': [
    '1ère année primaire (CP)',
    '2ème année primaire (CE1)',
    '3ème année primaire (CE2)',
    '4ème année primaire (CM1)',
    '5ème année primaire (CM2)',
    '6ème année primaire (CM3)',
  ],
  'Collège': [
    '7ème année (1ère année collège)',
    '8ème année (2ème année collège)',
    '9ème année (3ème année collège)',
  ],
  'Lycée': ['Tronc Commun (TC)', '1ère année bac', 'Baccalauréat', 'Baccalauréat (National)'],
};
const List<String> _lyceeTracks = ['Science', 'Lettre'];

// ═════════════════════════════════════════════════════════════════════════════

class _UserAndSchoolInfoPageState extends State<UserAndSchoolInfoPage> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  final TextEditingController _name = TextEditingController();

  // current values
  int _age = 0;
  int? _group;
  String _country = '';
  String _city = '';
  String _schoolName = '', _schoolType = '', _schoolLevel = '', _grade = '', _track = '';

  // values when the page opened (to know if something changed)
  late Map<String, Object?> _initial;
  bool _saving = false;

  ExperienceManager get _xp => Provider.of<ExperienceManager>(context, listen: false);

  @override
  void initState() {
    super.initState();
    final u = Provider.of<ExperienceManager>(context, listen: false).userProfile;
    _name.text = (u.fullName == 'Player') ? '' : u.fullName;
    _age = u.age;
    final gi = _ageGroups.indexWhere((g) => g.has(u.age));
    _group = gi < 0 ? null : gi;
    final known = _countries.where((c) => c.matches(u.country));
    _country = known.isEmpty ? u.country : known.first.id;
    _city = u.city;
    _schoolName = u.schoolName;
    _schoolType = u.schoolType;
    _schoolLevel = _schoolLevels.contains(u.schoolLevel) ? u.schoolLevel : '';
    _grade = (_gradesByLevel[_schoolLevel] ?? const []).contains(u.schoolGrade) ? u.schoolGrade : '';
    _track = _schoolLevel == 'Lycée' && _lyceeTracks.contains(u.lyceeTrack) ? u.lyceeTrack : '';
    _initial = _snapshot();
    _name.addListener(() => setState(() {}));
  }

  Map<String, Object?> _snapshot() => {
        'name': _name.text.trim(),
        'group': _group,
        'country': _country,
        'city': _city,
        'school': '$_schoolName|$_schoolType|$_schoolLevel|$_grade|$_track',
      };

  bool get _dirty {
    final now = _snapshot();
    return now.keys.any((k) => now[k] != _initial[k]);
  }

  bool get _canSave => _dirty && _name.text.trim().isNotEmpty && !_saving;

  @override
  void dispose() {
    _idle.dispose();
    _intro.dispose();
    _name.dispose();
    super.dispose();
  }

  // ── text ──────────────────────────────────────────────────────────────────
  String get _lang {
    final l = Localizations.localeOf(context).languageCode;
    return const ['fr', 'en', 'ar', 'de'].contains(l) ? l : 'fr';
  }

  String _t(String k) => _strings[k]?[_lang] ?? _strings[k]?['en'] ?? k;

  void _sound(String key) {
    try {
      Provider.of<AudioManager>(context, listen: false).playEventSound(key);
    } catch (_) {}
  }

  _Country? get _countryObj {
    for (final c in _countries) {
      if (c.id == _country) return c;
    }
    return null;
  }

  // ── actions ───────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_canSave) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    _sound('clickButton');
    HapticFeedback.mediumImpact();
    final xp = _xp;
    xp.setFullName(_name.text.trim());
    if (_group != null && !_ageGroups[_group!].has(_age)) xp.setAge(_ageGroups[_group!].saveAs);
    xp.setCountry(_country);
    xp.setCity(_city);
    xp.setSchoolName(_schoolName);
    xp.setSchoolType(_schoolType);
    xp.setSchoolLevel(_schoolLevel);
    xp.setSchoolGrade(_grade);
    xp.setLyceeTrack(_schoolLevel == 'Lycée' ? _track : '');
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF22A35A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white),
        const SizedBox(width: 8),
        Expanded(child: Text(_t('saved'), style: _f(15, color: Colors.white))),
      ]),
    ));
    Navigator.of(context).pop(true);
  }

  Future<bool> _confirmLeave() async {
    if (!_dirty) return true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(_t('discardTitle'), style: _f(20, weight: FontWeight.w700)),
        content: Text(_t('discardMsg'), style: _f(15, color: _inkSoft, weight: FontWeight.w500)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_t('keep'), style: _f(15, color: _purple))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(_t('discard'), style: _f(15, color: const Color(0xFFE5484D), weight: FontWeight.w700))),
        ],
      ),
    );
    return leave == true;
  }

  Future<void> _cancel() async {
    _sound('cancelButton');
    if (await _confirmLeave() && mounted) Navigator.of(context).pop(false);
  }

  Future<void> _pickCountry() async {
    _sound('clickButton');
    final r = await _pickFromList(
      title: _t('country'),
      hint: _t('searchCountry'),
      items: [for (final c in _countries) _PickItem(c.id, c.name(_lang), flag: c.id == 'Morocco' ? null : c.flag, ma: c.id == 'Morocco')],
      selected: _country,
      allowFree: true,
    );
    if (r == null || r == _country) return;
    setState(() {
      _country = r;
      // the city list depends on the country
      if (r != 'Morocco' || !_moroccanCities.contains(_city)) _city = '';
    });
  }

  Future<void> _pickCity() async {
    _sound('clickButton');
    final r = await _pickFromList(
      title: _t('city'),
      hint: _t('searchCity'),
      items: _country == 'Morocco' ? [for (final c in _moroccanCities) _PickItem(c, c)] : const [],
      selected: _city,
      allowFree: true,
    );
    if (r != null) setState(() => _city = r);
  }

  Future<String?> _pickFromList({
    required String title,
    required String hint,
    required List<_PickItem> items,
    required String selected,
    bool allowFree = false,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PickerSheet(
        title: title,
        hint: hint,
        items: items,
        selected: selected,
        allowFree: allowFree,
        useLabel: _t('use'),
      ),
    );
  }

  Future<void> _openSchool() async {
    _sound('clickButton');
    final r = await showModalBottomSheet<_School>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SchoolSheet(
        initial: _School(_schoolName, _schoolType, _schoolLevel, _grade, _track),
        t: _t,
      ),
    );
    if (r == null) return;
    setState(() {
      _schoolName = r.name;
      _schoolType = r.type;
      _schoolLevel = r.level;
      _grade = r.grade;
      _track = r.track;
    });
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Build
  // ═════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = min(size.width, 520.0);
    final s = ((w - 24) / 376).clamp(0.78, 1.3).toDouble();
    final xp = context.watch<ExperienceManager>();

    Widget step(int i, Widget c) {
      final a = CurvedAnimation(parent: _intro, curve: Interval(min(0.08 * i, 0.6), min(0.4 + 0.08 * i, 1), curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: a,
        child: SlideTransition(position: Tween(begin: const Offset(0, 0.12), end: Offset.zero).animate(a), child: c),
      );
    }

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && mounted) Navigator.of(context).pop(false);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFBFE6FF),
        body: Stack(children: [
          const Positioned.fill(child: KidPageBackground(wash: 0.05)),
          SafeArea(
            child: Center(
              child: SizedBox(
                width: w,
                child: Column(children: [
                  step(0, _header(s)),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(12 * s, 6 * s, 12 * s, 16 * s),
                      children: [
                        step(1, _bannerCard(s, xp)),
                        SizedBox(height: 10 * s),
                        step(2, _formCard(s)),
                      ],
                    ),
                  ),
                  step(4, _buttons(s)),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _header(double s) => Padding(
        padding: EdgeInsets.fromLTRB(10 * s, 6 * s, 10 * s, 2 * s),
        child: Row(children: [
          _Press(
            onTap: _cancel,
            child: Transform.flip(
              flipX: Directionality.of(context) == TextDirection.rtl,
              child: Image.asset('${_dir}ep_back.webp', width: 52 * s, height: 52 * s),
            ),
          ),
          Expanded(
            child: Center(
              child: Stack(children: [
                Text(_t('title'),
                    style: _f(30 * s, weight: FontWeight.w700).copyWith(
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 6 * s
                          ..color = Colors.white)),
                Text(_t('title'), style: _f(30 * s, weight: FontWeight.w700)),
              ]),
            ),
          ),
          SizedBox(width: 52 * s),
        ]),
      );

  // ── banner + avatar + name ────────────────────────────────────────────────

  Widget _bannerCard(double s, ExperienceManager xp) {
    final bannerH = 128 * s, av = 112 * s;
    final shownName = _name.text.trim().isEmpty ? _t('namePlaceholder') : _name.text.trim();
    return SizedBox(
      height: bannerH + 100 * s,
      child: Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
        // banner (the child's own, else the space one)
        Container(
          height: bannerH,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26 * s),
            border: Border.all(color: Colors.white, width: 3 * s),
            boxShadow: [BoxShadow(color: const Color(0xFF4B2A9A).withOpacity(0.25), blurRadius: 12 * s, offset: Offset(0, 5 * s))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(23 * s),
            child: Image.asset(
              xp.selectedBannerImage.isEmpty ? '${_dir}ep_banner.webp' : xp.selectedBannerImage,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) => Image.asset('${_dir}ep_banner.webp', fit: BoxFit.cover, width: double.infinity),
            ),
          ),
        ),
        // name plate
        Positioned(
          top: bannerH - 22 * s,
          child: Container(
            constraints: BoxConstraints(minWidth: 210 * s),
            padding: EdgeInsets.fromLTRB(16 * s, 46 * s, 16 * s, 10 * s),
            decoration: BoxDecoration(
              color: _cream,
              borderRadius: BorderRadius.circular(26 * s),
              boxShadow: [BoxShadow(color: const Color(0xFF4B2A9A).withOpacity(0.16), blurRadius: 10 * s, offset: Offset(0, 4 * s))],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 260 * s),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Text(shownName,
                        key: ValueKey(shownName),
                        maxLines: 1,
                        style: _f(28 * s, weight: FontWeight.w700, color: _name.text.trim().isEmpty ? _inkSoft : _ink)),
                  ),
                ),
              ),
              SizedBox(height: 4 * s),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 4 * s),
                decoration: BoxDecoration(color: const Color(0xFFEDE6FF), borderRadius: BorderRadius.circular(20 * s)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  AnimatedBuilder(
                    animation: _idle,
                    builder: (_, c) => Transform.rotate(angle: _idle.value * 2 * pi, child: c),
                    child: Icon(Icons.auto_awesome, size: 15 * s, color: const Color(0xFFFFC21A)),
                  ),
                  SizedBox(width: 5 * s),
                  Text(_t('welcome'), style: _f(13 * s, color: _purple)),
                ]),
              ),
            ]),
          ),
        ),
        // avatar (bobs gently)
        Positioned(
          top: bannerH / 2 - av / 2 + 12 * s,
          child: AnimatedBuilder(
            animation: _idle,
            builder: (_, c) => Transform.translate(offset: Offset(0, sin(_idle.value * 4 * pi) * 2.5 * s), child: c),
            child: FramedAvatar(avatar: xp.selectedAvatar, frame: xp.selectedAvatarFrame, size: av, fill: const Color(0xFFDDEBFF)),
          ),
        ),
      ]),
    );
  }

  // ── form ──────────────────────────────────────────────────────────────────

  Widget _formCard(double s) {
    final c = _countryObj;
    return Stack(clipBehavior: Clip.none, children: [
      Container(
        padding: EdgeInsets.fromLTRB(12 * s, 14 * s, 12 * s, 14 * s),
        decoration: BoxDecoration(
          color: _cream,
          borderRadius: BorderRadius.circular(28 * s),
          border: Border.all(color: Colors.white, width: 2 * s),
          boxShadow: [BoxShadow(color: const Color(0xFF4B2A9A).withOpacity(0.18), blurRadius: 14 * s, offset: Offset(0, 6 * s))],
        ),
        child: Column(children: [
          _row(s, 'ep_ic_name', _t('displayName'), _nameField(s)),
          SizedBox(height: 14 * s),
          _row(s, 'ep_ic_age', _t('ageGroup'), _ageSelector(s)),
          SizedBox(height: 14 * s),
          _row(
            s,
            'ep_ic_country',
            _t('country'),
            _selectField(
              s,
              leading: c == null
                  ? null
                  : (c.id == 'Morocco'
                      ? Image.asset('${_dir}ep_flag_ma.webp', height: 26 * s)
                      : Text(c.flag, style: TextStyle(fontSize: 24 * s))),
              text: c?.name(_lang) ?? _country,
              placeholder: _t('choose'),
              onTap: _pickCountry,
            ),
          ),
          SizedBox(height: 14 * s),
          _row(
            s,
            'ep_ic_city',
            _t('city'),
            _selectField(s, text: _city, placeholder: _t('choose'), onTap: _pickCity),
          ),
          SizedBox(height: 16 * s),
          _schoolRow(s),
        ]),
      ),
      // waving robot
      PositionedDirectional(
        end: -14 * s,
        bottom: -30 * s,
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _idle,
            builder: (_, c) => Transform.translate(
              offset: Offset(0, sin(_idle.value * 2 * pi * 2) * 4 * s),
              child: Transform.rotate(angle: sin(_idle.value * 2 * pi * 3) * 0.05, child: c),
            ),
            child: Image.asset('${_dir}ep_robot.webp', width: 84 * s),
          ),
        ),
      ),
    ]);
  }

  Widget _row(double s, String icon, String label, Widget field) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: EdgeInsets.only(top: 4 * s),
          child: Image.asset('$_dir$icon.webp', width: 46 * s, height: 46 * s),
        ),
        SizedBox(width: 10 * s),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: _f(16.5 * s, weight: FontWeight.w700)),
            SizedBox(height: 5 * s),
            field,
          ]),
        ),
      ]);

  BoxDecoration _fieldDeco(double s, {bool focus = false}) => BoxDecoration(
        color: _fieldFill,
        borderRadius: BorderRadius.circular(16 * s),
        border: Border.all(color: focus ? _purple : _fieldBorder, width: focus ? 2.4 * s : 2 * s),
      );

  Widget _nameField(double s) => Container(
        height: 48 * s,
        decoration: _fieldDeco(s),
        padding: EdgeInsets.symmetric(horizontal: 14 * s),
        alignment: AlignmentDirectional.centerStart,
        child: TextField(
          controller: _name,
          maxLength: 20,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          style: _f(18 * s, weight: FontWeight.w600),
          cursorColor: _purple,
          decoration: InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
            counterText: '',
            hintText: _t('namePlaceholder'),
            hintStyle: _f(17 * s, color: _inkSoft.withOpacity(0.6), weight: FontWeight.w500),
          ),
        ),
      );

  Widget _ageSelector(double s) => LayoutBuilder(builder: (_, c) {
        final n = _ageGroups.length;
        final cw = c.maxWidth / n;
        final h = 46 * s;
        return Container(
          height: h,
          decoration: _fieldDeco(s),
          child: Stack(children: [
            // sliding purple pill
            if (_group != null)
              AnimatedPositionedDirectional(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutBack,
                start: cw * _group! + 3 * s,
                top: 3 * s,
                width: cw - 6 * s - 2 * s,
                height: h - 10 * s,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13 * s),
                    gradient: const LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8B5CFF), Color(0xFF5B21E6)]),
                    boxShadow: [BoxShadow(color: _purple.withOpacity(0.45), blurRadius: 8 * s, offset: Offset(0, 3 * s))],
                  ),
                ),
              ),
            Row(children: [
              for (var i = 0; i < n; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      _sound('toggleButton');
                      HapticFeedback.selectionClick();
                      setState(() => _group = i);
                    },
                    child: Center(
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: _f(16.5 * s, color: _group == i ? Colors.white : _ink, weight: FontWeight.w700),
                          child: Text(_ageGroups[i].label),
                        ),
                      ),
                    ),
                  ),
                ),
            ]),
          ]),
        );
      });

  Widget _selectField(double s, {Widget? leading, required String text, required String placeholder, required VoidCallback onTap}) =>
      _Press(
        onTap: onTap,
        scale: 0.97,
        child: Container(
          height: 48 * s,
          decoration: _fieldDeco(s),
          padding: EdgeInsetsDirectional.fromSTEB(12 * s, 0, 8 * s, 0),
          child: Row(children: [
            if (leading != null) ...[leading, SizedBox(width: 10 * s)],
            Expanded(
              child: Text(text.isEmpty ? placeholder : text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.isEmpty
                      ? _f(17 * s, color: _inkSoft.withOpacity(0.6), weight: FontWeight.w500)
                      : _f(18 * s, weight: FontWeight.w600)),
            ),
            Image.asset('${_dir}ep_chev_down.webp', width: 30 * s, height: 30 * s),
          ]),
        ),
      );

  Widget _schoolRow(double s) {
    final summary = [
      if (_grade.isNotEmpty) _grade else if (_schoolLevel.isNotEmpty) _schoolLevel,
      if (_schoolName.isNotEmpty) _schoolName,
    ].join(' · ');
    return Padding(
      padding: EdgeInsetsDirectional.only(end: 52 * s), // room for the robot
      child: _Press(
        onTap: _openSchool,
        scale: 0.97,
        child: Container(
          padding: EdgeInsets.all(8 * s),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20 * s),
            boxShadow: [BoxShadow(color: const Color(0xFF4B2A9A).withOpacity(0.10), blurRadius: 8 * s, offset: Offset(0, 3 * s))],
          ),
          child: Row(children: [
            Image.asset('${_dir}ep_ic_school.webp', width: 46 * s, height: 46 * s),
            SizedBox(width: 10 * s),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_t('school'), style: _f(16 * s, weight: FontWeight.w700)),
                Text(summary.isEmpty ? _t('optional') : summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _f(13.5 * s, color: summary.isEmpty ? _inkSoft : const Color(0xFF22A35A), weight: FontWeight.w500)),
              ]),
            ),
            Transform.flip(
              flipX: Directionality.of(context) == TextDirection.rtl,
              child: Image.asset('${_dir}ep_chev_right.webp', width: 28 * s, height: 28 * s),
            ),
          ]),
        ),
      ),
    );
  }

  // ── buttons ───────────────────────────────────────────────────────────────

  Widget _buttons(double s) {
    final bw = min(MediaQuery.sizeOf(context).width, 520.0) - 28 * s;
    final can = _canSave;
    return Padding(
      padding: EdgeInsets.fromLTRB(14 * s, 4 * s, 14 * s, 10 * s),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: can ? 1 : 0.5,
          child: AnimatedBuilder(
            animation: _idle,
            builder: (_, c) => Transform.scale(scale: can ? 1 + 0.02 * sin(_idle.value * 2 * pi * 4) : 1, child: c),
            child: _Press(
              onTap: can ? _save : () {},
              child: SizedBox(
                width: bw,
                height: max(56 * s, bw * 0.1484),
                child: Stack(alignment: Alignment.center, children: [
                  Positioned.fill(child: Image.asset('${_dir}ep_btn_orange.webp', fit: BoxFit.fill)),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    if (_saving)
                      SizedBox(width: 24 * s, height: 24 * s, child: const CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                    else
                      Image.asset('${_dir}ep_check.webp', height: 26 * s),
                    SizedBox(width: 10 * s),
                    Text(_t('save'),
                        style: _f(22 * s, color: Colors.white, weight: FontWeight.w700)
                            .copyWith(shadows: const [Shadow(color: Color(0xFFB45309), offset: Offset(0, 2))])),
                  ]),
                ]),
              ),
            ),
          ),
        ),
        SizedBox(height: 8 * s),
        _Press(
          onTap: _cancel,
          child: SizedBox(
            width: bw,
            height: max(50 * s, bw * 0.1323),
            child: Stack(alignment: Alignment.center, children: [
              Positioned.fill(child: Image.asset('${_dir}ep_btn_cream.webp', fit: BoxFit.fill)),
              Text(_t('cancel'), style: _f(20 * s, weight: FontWeight.w700)),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Picker sheet (country / city) with search + free entry
// ═════════════════════════════════════════════════════════════════════════════

class _PickItem {
  final String value, label;
  final String? flag;
  final bool ma; // use the Morocco flag sprite
  const _PickItem(this.value, this.label, {this.flag, this.ma = false});
}

class _PickerSheet extends StatefulWidget {
  final String title, hint, selected, useLabel;
  final List<_PickItem> items;
  final bool allowFree;
  const _PickerSheet({
    required this.title,
    required this.hint,
    required this.items,
    required this.selected,
    required this.allowFree,
    required this.useLabel,
  });

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  final TextEditingController _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  String _norm(String v) => v
      .toLowerCase()
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[àâä]'), 'a')
      .replaceAll(RegExp('[ïî]'), 'i')
      .replaceAll(RegExp('[ôö]'), 'o')
      .trim();

  @override
  Widget build(BuildContext context) {
    final q = _norm(_q.text);
    final list = widget.items.where((i) => q.isEmpty || _norm(i.label).contains(q) || _norm(i.value).contains(q)).toList();
    final exact = widget.items.any((i) => _norm(i.label) == q || _norm(i.value) == q);
    final free = _q.text.trim();
    final h = MediaQuery.sizeOf(context).height;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: h * 0.75),
        decoration: const BoxDecoration(
          color: _cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 44, height: 5, decoration: BoxDecoration(color: _fieldBorder, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 10),
          Text(widget.title, style: _f(20, weight: FontWeight.w700)),
          const SizedBox(height: 10),
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: _fieldFill, borderRadius: BorderRadius.circular(16), border: Border.all(color: _fieldBorder, width: 2)),
            child: Row(children: [
              const Icon(Icons.search_rounded, color: _purple),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _q,
                  autofocus: widget.items.isEmpty,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (v) {
                    if (widget.allowFree && v.trim().isNotEmpty) Navigator.pop(context, v.trim());
                  },
                  style: _f(17),
                  cursorColor: _purple,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: widget.hint,
                    hintStyle: _f(16, color: _inkSoft.withOpacity(0.6), weight: FontWeight.w500),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                if (widget.allowFree && free.isNotEmpty && !exact)
                  _tile(
                    leading: const Icon(Icons.add_circle_rounded, color: _purple, size: 26),
                    label: '${widget.useLabel} “$free”',
                    selected: false,
                    onTap: () => Navigator.pop(context, free),
                  ),
                for (final i in list)
                  _tile(
                    leading: i.ma
                        ? Image.asset('${_dir}ep_flag_ma.webp', height: 22)
                        : (i.flag != null ? Text(i.flag!, style: const TextStyle(fontSize: 22)) : null),
                    label: i.label,
                    selected: i.value == widget.selected,
                    onTap: () => Navigator.pop(context, i.value),
                  ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _tile({Widget? leading, required String label, required bool selected, required VoidCallback onTap}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Material(
          color: selected ? const Color(0xFFEDE6FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                if (leading != null) ...[SizedBox(width: 32, child: Center(child: leading)), const SizedBox(width: 10)],
                Expanded(child: Text(label, style: _f(17, weight: selected ? FontWeight.w700 : FontWeight.w600))),
                if (selected) const Icon(Icons.check_circle_rounded, color: _purple),
              ]),
            ),
          ),
        ),
      );
}

// ═════════════════════════════════════════════════════════════════════════════
// School sheet (optional)
// ═════════════════════════════════════════════════════════════════════════════

class _School {
  final String name, type, level, grade, track;
  const _School(this.name, this.type, this.level, this.grade, this.track);
}

class _SchoolSheet extends StatefulWidget {
  final _School initial;
  final String Function(String) t;
  const _SchoolSheet({required this.initial, required this.t});

  @override
  State<_SchoolSheet> createState() => _SchoolSheetState();
}

class _SchoolSheetState extends State<_SchoolSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.initial.name);
  late String _type = widget.initial.type, _level = widget.initial.level, _grade = widget.initial.grade, _track = widget.initial.track;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Text(s, style: _f(16, weight: FontWeight.w700)),
      );

  Widget _chips(List<String> items, String value, ValueChanged<String> onPick) => Wrap(spacing: 8, runSpacing: 8, children: [
        for (final i in items)
          GestureDetector(
            onTap: () => onPick(value == i ? '' : i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: value == i ? _purple : _fieldFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: value == i ? _purple : _fieldBorder, width: 2),
              ),
              child: Text(i, style: _f(15, color: value == i ? Colors.white : _ink)),
            ),
          ),
      ]);

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final h = MediaQuery.sizeOf(context).height;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: h * 0.85),
        decoration: const BoxDecoration(color: _cream, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 44, height: 5, decoration: BoxDecoration(color: _fieldBorder, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 10),
          Row(children: [
            Image.asset('${_dir}ep_ic_school.webp', width: 40, height: 40),
            const SizedBox(width: 10),
            Expanded(child: Text(t('school'), style: _f(20, weight: FontWeight.w700))),
          ]),
          Flexible(
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label(t('schoolName')),
                Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: AlignmentDirectional.centerStart,
                  decoration: BoxDecoration(color: _fieldFill, borderRadius: BorderRadius.circular(16), border: Border.all(color: _fieldBorder, width: 2)),
                  child: TextField(
                    controller: _name,
                    style: _f(17),
                    cursorColor: _purple,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: t('schoolNameHint'),
                      hintStyle: _f(16, color: _inkSoft.withOpacity(0.6), weight: FontWeight.w500),
                    ),
                  ),
                ),
                _label(t('schoolType')),
                _chips(_schoolTypes, _type, (v) => setState(() => _type = v)),
                _label(t('level')),
                _chips(_schoolLevels, _level, (v) => setState(() {
                      _level = v;
                      _grade = '';
                      _track = '';
                    })),
                if (_level.isNotEmpty) ...[
                  _label(t('grade')),
                  _chips(_gradesByLevel[_level] ?? const [], _grade, (v) => setState(() => _grade = v)),
                ],
                if (_level == 'Lycée') ...[
                  _label(t('track')),
                  _chips(_lyceeTracks, _track, (v) => setState(() => _track = v)),
                ],
              ]),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              onPressed: () => Navigator.pop(context, _School(_name.text.trim(), _type, _level, _grade, _track)),
              child: Text(t('done'), style: _f(19, color: Colors.white, weight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════

class _Press extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scale;
  const _Press({required this.child, required this.onTap, this.scale = 0.94});
  @override
  State<_Press> createState() => _PressState();
}

class _PressState extends State<_Press> {
  bool _down = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) {
          setState(() => _down = false);
          widget.onTap();
        },
        child: AnimatedScale(scale: _down ? widget.scale : 1, duration: const Duration(milliseconds: 110), child: widget.child),
      );
}

const Map<String, Map<String, String>> _strings = {
  'title': {'en': 'Edit Profile', 'fr': 'Modifier le profil', 'ar': 'تعديل الملف', 'de': 'Profil bearbeiten'},
  'welcome': {'en': 'Make yourself at home!', 'fr': 'Fais comme chez toi !', 'ar': 'اعتبر المكان بيتك!', 'de': 'Fühl dich wie zu Hause!'},
  'namePlaceholder': {'en': 'Your name', 'fr': 'Ton prénom', 'ar': 'اسمك', 'de': 'Dein Name'},
  'displayName': {'en': 'Display name', 'fr': 'Prénom affiché', 'ar': 'الاسم الظاهر', 'de': 'Anzeigename'},
  'ageGroup': {'en': 'Age group', 'fr': 'Tranche d’âge', 'ar': 'الفئة العمرية', 'de': 'Altersgruppe'},
  'country': {'en': 'Country', 'fr': 'Pays', 'ar': 'البلد', 'de': 'Land'},
  'city': {'en': 'City', 'fr': 'Ville', 'ar': 'المدينة', 'de': 'Stadt'},
  'choose': {'en': 'Choose…', 'fr': 'Choisir…', 'ar': 'اختر…', 'de': 'Wählen…'},
  'searchCountry': {'en': 'Search a country', 'fr': 'Chercher un pays', 'ar': 'ابحث عن بلد', 'de': 'Land suchen'},
  'searchCity': {'en': 'Search or type your city', 'fr': 'Cherche ou écris ta ville', 'ar': 'ابحث أو اكتب مدينتك', 'de': 'Stadt suchen oder eingeben'},
  'use': {'en': 'Use', 'fr': 'Utiliser', 'ar': 'استخدم', 'de': 'Verwenden'},
  'school': {'en': 'School information', 'fr': 'Informations scolaires', 'ar': 'معلومات المدرسة', 'de': 'Schulinfos'},
  'optional': {'en': 'Optional', 'fr': 'Facultatif', 'ar': 'اختياري', 'de': 'Optional'},
  'schoolName': {'en': 'School name', 'fr': 'Nom de l’école', 'ar': 'اسم المدرسة', 'de': 'Name der Schule'},
  'schoolNameHint': {'en': 'e.g. Al Amal school', 'fr': 'ex. École Al Amal', 'ar': 'مثال: مدرسة الأمل', 'de': 'z. B. Al-Amal-Schule'},
  'schoolType': {'en': 'School type', 'fr': 'Type d’école', 'ar': 'نوع المدرسة', 'de': 'Schulart'},
  'level': {'en': 'Level', 'fr': 'Niveau', 'ar': 'المستوى', 'de': 'Stufe'},
  'grade': {'en': 'Class', 'fr': 'Classe', 'ar': 'القسم', 'de': 'Klasse'},
  'track': {'en': 'Track', 'fr': 'Filière', 'ar': 'الشعبة', 'de': 'Zweig'},
  'done': {'en': 'Done', 'fr': 'Terminé', 'ar': 'تم', 'de': 'Fertig'},
  'save': {'en': 'Save changes', 'fr': 'Enregistrer', 'ar': 'حفظ التغييرات', 'de': 'Speichern'},
  'cancel': {'en': 'Cancel', 'fr': 'Annuler', 'ar': 'إلغاء', 'de': 'Abbrechen'},
  'saved': {'en': 'Profile saved!', 'fr': 'Profil enregistré !', 'ar': 'تم حفظ الملف!', 'de': 'Profil gespeichert!'},
  'discardTitle': {'en': 'Leave without saving?', 'fr': 'Quitter sans enregistrer ?', 'ar': 'الخروج دون حفظ؟', 'de': 'Ohne Speichern verlassen?'},
  'discardMsg': {'en': 'Your changes will be lost.', 'fr': 'Tes modifications seront perdues.', 'ar': 'ستضيع تغييراتك.', 'de': 'Deine Änderungen gehen verloren.'},
  'keep': {'en': 'Keep editing', 'fr': 'Continuer', 'ar': 'متابعة التعديل', 'de': 'Weiter bearbeiten'},
  'discard': {'en': 'Leave', 'fr': 'Quitter', 'ar': 'خروج', 'de': 'Verlassen'},
};
