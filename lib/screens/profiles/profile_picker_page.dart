import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mortaalim/IndexPage.dart';
import 'package:mortaalim/Manager/models/avatar_catalog.dart';
import 'package:mortaalim/User_Input_Info_DataForm/User_Info_FirstCon/UserInfoForm_Introduction.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/screens/parents/parent_gate.dart';
import 'package:mortaalim/screens/parents/parents_space.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';

import 'profile_store.dart';

const String _dir = 'assets/images/UI/Profiles/';
String _a(String n) => '$_dir$n.webp';

const _ink = Color(0xFF3A1F8C);

const _texts = <String, Map<String, String>>{
  'fr': {
    'title': 'Qui part à l\'aventure ?',
    'sub': 'Choisis ton profil pour commencer',
    'add': 'Ajouter un joueur',
    'level': 'Niveau',
    'go': 'C\'est parti !',
    'parents': 'Espace parents',
    'parentsSub': 'Gérer les profils et les réglages',
    'hello': 'Heureux de te retrouver !',
    'first': 'Bienvenue, choisis ton profil !',
    'newKid': 'Nouveau joueur',
    'full': 'Maximum 4 joueurs',
  },
  'en': {
    'title': 'Who\'s off on an adventure?',
    'sub': 'Choose your profile to start',
    'add': 'Add a player',
    'level': 'Level',
    'go': 'Let\'s go!',
    'parents': 'Parents space',
    'parentsSub': 'Manage profiles and settings',
    'hello': 'Happy to see you again!',
    'first': 'Welcome, pick your profile!',
    'newKid': 'New player',
    'full': '4 players maximum',
  },
  'ar': {
    'title': 'من سينطلق في المغامرة؟',
    'sub': 'اختر ملفك الشخصي للبدء',
    'add': 'إضافة لاعب',
    'level': 'المستوى',
    'go': 'هيا بنا!',
    'parents': 'فضاء الآباء',
    'parentsSub': 'إدارة الملفات والإعدادات',
    'hello': 'سعيد برؤيتك من جديد!',
    'first': 'مرحبا، اختر ملفك!',
    'newKid': 'لاعب جديد',
    'full': '4 لاعبين كحد أقصى',
  },
  'de': {
    'title': 'Wer geht auf Abenteuer?',
    'sub': 'Wähle dein Profil, um zu starten',
    'add': 'Spieler hinzufügen',
    'level': 'Level',
    'go': 'Los geht\'s!',
    'parents': 'Elternbereich',
    'parentsSub': 'Profile und Einstellungen verwalten',
    'hello': 'Schön, dich wiederzusehen!',
    'first': 'Willkommen, wähle dein Profil!',
    'newKid': 'Neuer Spieler',
    'full': 'Maximal 4 Spieler',
  },
};

String profT(BuildContext context, String key) {
  final code = Localizations.localeOf(context).languageCode;
  return (_texts[code] ?? _texts['fr']!)[key] ?? _texts['fr']![key]!;
}

/// Colour per card slot (blue, purple, then orange and pink).
const _slotColors = [Color(0xFF1EC8F0), Color(0xFF9B6BF2), Color(0xFFFF9A2E), Color(0xFFF266A8)];

/// Push this to show the "Who's playing?" screen (it replaces the whole stack).
Future<void> openProfilePicker(BuildContext context) => Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const ProfilePickerPage(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      ),
      (_) => false,
    );

class ProfilePickerPage extends StatefulWidget {
  const ProfilePickerPage({super.key});

  @override
  State<ProfilePickerPage> createState() => _ProfilePickerPageState();
}

class _ProfilePickerPageState extends State<ProfilePickerPage> with TickerProviderStateMixin {
  List<KidProfile> _list = [];
  String? _selected;
  bool _busy = false;
  bool _returning = true;

  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  late final AnimationController _life = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final xp = Provider.of<ExperienceManager>(context, listen: false);
    final list = await ProfileStore.load(xp);
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _list = list;
      _selected = ProfileStore.activeId;
      _returning = ProfileStore.isOnboarded(p) && list.first.name.isNotEmpty;
    });
    _intro.forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    _life.dispose();
    super.dispose();
  }

  void _click() {
    try {
      Provider.of<AudioManager>(context, listen: false).playEventSound('clickButton2');
    } catch (_) {}
  }

  void _pick(KidProfile k) {
    if (_busy) return;
    if (_selected == k.id) {
      _go();
      return;
    }
    _click();
    setState(() => _selected = k.id);
  }

  Future<void> _go() async {
    if (_busy || _selected == null) return;
    try {
      Provider.of<AudioManager>(context, listen: false).playEventSound('clickButton');
    } catch (_) {}
    setState(() => _busy = true);
    final xp = Provider.of<ExperienceManager>(context, listen: false);
    await ProfileStore.switchTo(_selected!, xp);
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    final onboarded = ProfileStore.isOnboarded(p);
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => onboarded ? const Index() : const UserInfoForm(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: CurvedAnimation(parent: a, curve: Curves.easeOut), child: child),
      ),
      (_) => false,
    );
  }

  Future<void> _add() async {
    if (_busy) return;
    _click();
    if (_list.length >= ProfileStore.maxProfiles) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(profT(context, 'full'))));
      return;
    }
    if (!await ParentGate.check(context)) return;
    final id = await ProfileStore.create();
    if (id == null || !mounted) return;
    setState(() => _selected = id);
    await _go();
  }

  Future<void> _parents() async {
    _click();
    await openParentsSpace(context, tab: 4);
    if (mounted) _load();
  }

  // ───────────────────────────────────────────── build

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final u = min(size.width / 390, size.height / 820);
    final w = size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF9ED8F5),
      body: Stack(children: [
        Positioned.fill(child: Image.asset('assets/images/UI/Loading/loading_bg_adventure.webp', fit: BoxFit.cover)),
        // soft light so the cards read well
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, 0.05),
                radius: 0.9,
                colors: [Colors.white.withOpacity(0.28), Colors.white.withOpacity(0)],
              ),
            ),
          ),
        ),
        // wooden signs on the left cliff
        AnimatedBuilder(
          animation: _life,
          builder: (_, __) {
            final t = _life.value * 2 * pi;
            return Positioned(
              left: -8 * u,
              top: pad.top + 205 * u,
              child: Column(children: [
                Transform.rotate(angle: 0.05 * sin(t), alignment: Alignment.topCenter, child: Image.asset(_a('pp_sign_moon'), width: 64 * u)),
                SizedBox(height: 2 * u),
                Transform.rotate(angle: -0.05 * sin(t + 1), alignment: Alignment.topCenter, child: Image.asset(_a('pp_sign_book'), width: 64 * u)),
              ]),
            );
          },
        ),
        SafeArea(
          child: Column(children: [
            SizedBox(height: 4 * u),
            _header(u, w),
            Expanded(child: Transform.translate(offset: Offset(0, -8 * u), child: _grid(u, w))),
            SizedBox(height: 4 * u),
            _bottom(u, w),
            SizedBox(height: 8 * u),
          ]),
        ),
        if (_busy)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.white.withOpacity(0.35),
              child: const Center(child: CircularProgressIndicator(color: Color(0xFF7C4DDB))),
            ),
          ),
      ]),
    );
  }

  Animation<double> _seg(double a, double b, [Curve c = Curves.easeOutBack]) =>
      CurvedAnimation(parent: _intro, curve: Interval(a, b, curve: c));

  Widget _pop(double a, double b, Widget child) {
    final an = _seg(a, b);
    final fade = _seg(a, min(1, b), Curves.easeOut);
    return AnimatedBuilder(
      animation: _intro,
      builder: (_, c) => Opacity(opacity: fade.value.clamp(0.0, 1.0), child: Transform.scale(scale: 0.6 + 0.4 * an.value, child: c)),
      child: child,
    );
  }

  TextStyle _title(double s, {Color color = _ink}) => TextStyle(
        fontFamily: 'Fredoka',
        fontWeight: FontWeight.w700,
        fontSize: s,
        color: color,
        height: 1.05,
      );

  Widget _stroked(String text, TextStyle st, {double stroke = 6, Color strokeColor = Colors.white}) => Stack(children: [
        Text(text,
            textAlign: TextAlign.center,
            style: st.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = stroke
                ..strokeJoin = StrokeJoin.round
                ..color = strokeColor,
            )),
        Text(text, textAlign: TextAlign.center, style: st),
      ]);

  Widget _header(double u, double w) {
    final logoW = min(w * 0.4, 170 * u);
    final logoH = logoW * 0.5238;
    final titleW = min(w * 0.72, 300 * u);
    final titleH = titleW * 0.3548;
    return Column(children: [
      _pop(
        0,
        0.35,
        AnimatedBuilder(
          animation: _life,
          builder: (_, c) => Transform.translate(offset: Offset(0, 3 * u * sin(_life.value * 2 * pi)), child: c),
          child: SizedBox(
            width: logoW,
            height: logoH,
            child: Stack(children: [
              Positioned.fill(child: Image.asset(_a('pp_logo'), fit: BoxFit.fill)),
              Positioned(
                left: logoW * 0.08,
                right: logoW * 0.08,
                top: logoH * 0.56,
                bottom: logoH * 0.08,
                child: FittedBox(
                  child: _stroked(
                    'MoorTaalim',
                    _title(40, color: const Color(0xFF4A22B0)).copyWith(
                      shadows: [const Shadow(color: Color(0x553A1F8C), blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    stroke: 7,
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
      Transform.translate(
        offset: Offset(0, -12 * u),
        child: _pop(
          0.12,
          0.45,
          SizedBox(
            width: titleW,
            height: titleH,
            child: Stack(children: [
              Positioned.fill(child: Image.asset(_a('pp_title'), fit: BoxFit.fill)),
              Positioned(
                left: titleW * 0.08,
                right: titleW * 0.08,
                top: titleH * 0.1,
                height: titleH * 0.44,
                child: FittedBox(child: Text(profT(context, 'title'), style: _title(34))),
              ),
              Positioned(
                left: titleW * 0.27,
                right: titleW * 0.27,
                top: titleH * 0.64,
                height: titleH * 0.22,
                child: FittedBox(
                  child: Text(profT(context, 'sub'),
                      style: _title(16).copyWith(fontWeight: FontWeight.w600, color: const Color(0xFF4B3A8A))),
                ),
              ),
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _grid(double u, double w) {
    final slots = <Widget>[];
    final count = _list.length < ProfileStore.maxProfiles ? max(4, _list.length + 1) : _list.length;
    return LayoutBuilder(builder: (context, c) {
      const ratio = 1.24;
      final gap = 14 * u;
      var cw = (min(c.maxWidth, 420 * u) - 3 * gap) / 2;
      final rows = (min(count, 4) / 2).ceil();
      final maxH = (c.maxHeight - (rows - 1) * gap - 6 * u) / rows;
      if (cw * ratio > maxH) cw = maxH / ratio;
      final ch = cw * ratio;
      slots.clear();
      for (var i = 0; i < min(count, 4); i++) {
        final Widget card;
        if (i < _list.length) {
          card = _ProfileCard(
            profile: _list[i],
            color: _slotColors[i % _slotColors.length],
            pillAsset: i == 0 ? 'pp_pill_blue' : (i == 1 ? 'pp_pill_purple' : null),
            selected: _selected == _list[i].id,
            width: cw,
            height: ch,
            life: _life,
            onTap: () => _pick(_list[i]),
          );
        } else {
          card = _AddCard(width: cw, height: ch, onTap: _add);
        }
        final start = 0.25 + i * 0.1;
        slots.add(_pop(start, min(1, start + 0.4), card));
      }
      return Center(
        child: Wrap(
          spacing: gap,
          runSpacing: gap,
          alignment: WrapAlignment.center,
          children: slots,
        ),
      );
    });
  }

  Widget _bottom(double u, double w) {
    final robotW = 96 * u;
    final side = robotW + 4 * u;
    final avail = w - side - 14 * u;
    final btnW = min(avail, 224 * u);
    final btnH = btnW * 0.3842;
    final parentH = 58 * u;
    final bubbleW = 106 * u, bubbleH = 106 * u * 0.6533;
    final rowH = parentH + 8 * u + btnH;
    final ready = _selected != null;
    return SizedBox(
      height: max(rowH, robotW * 1.3 + bubbleH),
      child: Stack(clipBehavior: Clip.none, children: [
        // robot
        Positioned(
          left: 2 * u,
          bottom: 0,
          child: AnimatedBuilder(
            animation: _life,
            builder: (_, c) {
              final t = _life.value * 2 * pi;
              return Transform.translate(
                offset: Offset(0, -4 * u * sin(t * 2).abs()),
                child: Transform.rotate(angle: 0.04 * sin(t), alignment: Alignment.bottomCenter, child: c),
              );
            },
            child: _pop(0.6, 1, Image.asset(_a('pp_robot'), width: robotW)),
          ),
        ),
        // speech bubble (tail points down-left to the robot)
        Positioned(
          left: robotW * 0.3,
          bottom: robotW * 1.3,
          child: _pop(
            0.75,
            1,
            SizedBox(
              width: bubbleW,
              height: bubbleH,
              child: Stack(children: [
                Positioned.fill(child: Image.asset(_a('pp_bubble'), fit: BoxFit.fill)),
                Positioned(
                  left: bubbleW * 0.1,
                  right: bubbleW * 0.08,
                  top: bubbleH * 0.1,
                  bottom: bubbleH * 0.3,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: bubbleW * 0.82,
                        child: Text(
                          profT(context, _returning ? 'hello' : 'first'),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          style: _title(13 * u).copyWith(fontWeight: FontWeight.w600, height: 1.15),
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
        // "C'est parti !"
        Positioned(
          left: side + (avail - btnW) / 2,
          bottom: parentH + 8 * u,
          child: _pop(
            0.55,
            0.95,
            AnimatedBuilder(
              animation: _life,
              builder: (_, c) => Transform.scale(scale: ready ? 1 + 0.025 * sin(_life.value * 4 * pi) : 1, child: c),
              child: KidPressable(
                onTap: _go,
                child: Opacity(
                  opacity: ready ? 1 : 0.6,
                  child: SizedBox(
                    width: btnW,
                    height: btnH,
                    child: Stack(children: [
                      Positioned.fill(child: Image.asset(_a('pp_btn_orange'), fit: BoxFit.fill)),
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(btnW * 0.11, btnH * 0.2, btnW * 0.1, btnH * 0.24),
                          child: Row(children: [
                            Image.asset(_a('pp_play'), height: btnH * 0.5),
                            SizedBox(width: btnW * 0.05),
                            Expanded(
                              child: FittedBox(
                                child: Text(
                                  profT(context, 'go'),
                                  style: _title(30, color: Colors.white).copyWith(
                                    shadows: const [Shadow(color: Color(0xAAB24A00), blurRadius: 3, offset: Offset(0, 2))],
                                  ),
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
        // parents space
        Positioned(
          left: side,
          right: 14 * u,
          bottom: 0,
          height: parentH,
          child: _pop(
            0.65,
            1,
            KidPressable(
              onTap: _parents,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16 * u),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E6),
                  borderRadius: BorderRadius.circular(parentH / 2),
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.16), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(children: [
                  Image.asset(_a('pp_lock'), height: parentH * 0.62),
                  SizedBox(width: 10 * u),
                  Expanded(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      FittedBox(child: Text(profT(context, 'parents'), style: _title(17 * u).copyWith(fontWeight: FontWeight.w600))),
                      FittedBox(
                        child: Text(profT(context, 'parentsSub'),
                            style: _title(11.5 * u).copyWith(fontWeight: FontWeight.w500, color: const Color(0xFF5B4C8F))),
                      ),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ───────────────────────────────────────────── cards

class _ProfileCard extends StatelessWidget {
  final KidProfile profile;
  final Color color;
  final String? pillAsset;
  final bool selected;
  final double width, height;
  final Animation<double> life;
  final VoidCallback onTap;
  const _ProfileCard({
    required this.profile,
    required this.color,
    required this.pillAsset,
    required this.selected,
    required this.width,
    required this.height,
    required this.life,
    required this.onTap,
  });

  String get _avatarAsset {
    if (AvatarCatalog.isValid(profile.avatar)) return profile.avatar;
    final g = profile.gender.toLowerCase();
    return _a(g.startsWith('f') || g.startsWith('g') ? 'pp_girl' : 'pp_boy');
  }

  @override
  Widget build(BuildContext context) {
    final w = width;
    final d = w * 0.7;
    final name = profile.name.isEmpty ? profT(context, 'newKid') : profile.name;
    return KidPressable(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: life,
        builder: (_, c) {
          final t = life.value * 2 * pi;
          return Transform.translate(offset: Offset(0, selected ? -3 * sin(t * 2) : 0), child: c);
        },
        child: AnimatedScale(
          scale: selected ? 1.04 : 0.97,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          child: SizedBox(
            width: w,
            height: height,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8EA),
                    borderRadius: BorderRadius.circular(w * 0.1),
                    border: Border.all(color: color, width: w * (selected ? 0.03 : 0.022)),
                    boxShadow: [
                      BoxShadow(color: color.withOpacity(selected ? 0.75 : 0.35), blurRadius: w * (selected ? 0.12 : 0.06), spreadRadius: selected ? w * 0.01 : 0),
                      BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                ),
              ),
              // sparkles
              for (final s in const [(0.09, 0.08, 0.075), (0.16, 0.17, 0.045), (0.85, 0.08, 0.07), (0.1, 0.62, 0.055), (0.87, 0.6, 0.06)])
                Positioned(
                  left: w * s.$1 - w * s.$3 / 2,
                  top: height * s.$2,
                  child: AnimatedBuilder(
                    animation: life,
                    builder: (_, c) => Opacity(opacity: 0.55 + 0.45 * sin(life.value * 2 * pi * 2 + s.$1 * 9).abs(), child: c),
                    child: Icon(Icons.auto_awesome, size: w * s.$3 * 1.6, color: const Color(0xFFFFC53D)),
                  ),
                ),
              // leaves
              Positioned(left: w * 0.06, top: height * 0.7, child: Transform.scale(scaleX: -1, child: Image.asset(_a('pp_leaf'), width: w * 0.15))),
              Positioned(right: w * 0.06, top: height * 0.7, child: Image.asset(_a('pp_leaf'), width: w * 0.15)),
              // avatar
              Positioned(
                left: (w - d) / 2,
                top: height * 0.07,
                child: Container(
                  width: d,
                  height: d,
                  padding: EdgeInsets.all(d * 0.035),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: d * 0.08)],
                  ),
                  child: ClipOval(
                    child: ColoredBox(
                      color: const Color(0xFFE6F4FF),
                      child: Image.asset(_avatarAsset, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
              // name
              Positioned(
                left: w * 0.2,
                right: w * 0.2,
                top: height * 0.665,
                height: height * 0.14,
                child: FittedBox(
                  child: Text(name,
                      style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w700, fontSize: 30, color: _ink)),
                ),
              ),
              // level pill
              Positioned(
                left: w * 0.18,
                right: w * 0.18,
                top: height * 0.815,
                height: height * 0.13,
                child: Stack(children: [
                  Positioned.fill(
                    child: pillAsset != null
                        ? Image.asset(_a(pillAsset!), fit: BoxFit.fill)
                        : Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(40),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color.lerp(color, Colors.white, 0.25)!, color],
                              ),
                              border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.5),
                            ),
                          ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: height * 0.018),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Image.asset(_a('pp_star'), height: height * 0.075),
                        SizedBox(width: w * 0.02),
                        Flexible(
                          child: FittedBox(
                            child: Text('${profT(context, 'level')} ${profile.level}',
                                style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600, fontSize: 20, color: Colors.white)),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ]),
              ),
              // selected tick
              Positioned(
                right: -w * 0.04,
                top: -w * 0.04,
                child: AnimatedScale(
                  scale: selected ? 1 : 0,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutBack,
                  child: Image.asset(_a('pp_check'), width: w * 0.22),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _AddCard extends StatelessWidget {
  final double width, height;
  final VoidCallback onTap;
  const _AddCard({required this.width, required this.height, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return KidPressable(
      onTap: onTap,
      child: Transform.scale(
        scale: 0.97,
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(children: [
            Positioned.fill(child: Image.asset(_a('pp_add_card'), fit: BoxFit.fill)),
            Positioned(
              left: width * 0.15,
              right: width * 0.15,
              bottom: height * 0.085,
              height: height * 0.11,
              child: FittedBox(
                child: Text(profT(context, 'add'),
                    style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600, fontSize: 22, color: _ink)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
