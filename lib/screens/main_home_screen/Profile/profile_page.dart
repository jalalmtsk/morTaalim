import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/Manager/lesson_progress.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/screens/main_home_screen/Quests/quests_page.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/Collection/Collection.dart';
import 'package:mortaalim/widgets/KidScene/kid_page_parts.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:mortaalim/widgets/ProfileSetup_Widget/BannerAndAvatarProfilePage/BannerAvatarProfile.dart';
import 'package:mortaalim/widgets/ProfileSetup_Widget/MainProfile_Page/Widgets/UserDataProfileEntering.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileAssets {
  ProfileAssets._();
  static const String dir = 'assets/images/UI/KidScene/';
  static const String banner = '${dir}prof_banner.webp';
  static const String pencil = '${dir}prof_pencil.webp';
  static const String star = '${dir}prof_star.webp';
  static const String palette = '${dir}prof_palette.webp';
  static const String book = '${dir}prof_book.webp';
  static const String padPurple = '${dir}prof_pad_purple.webp';
  static const String padPink = '${dir}prof_pad_pink.webp';
  static const String flame = '${dir}prof_flame.webp';
  static const String robot = '${dir}prof_robot.webp';
  static const String mosque = '${dir}prof_mosque.webp';
  static const String badgeSteps = '${dir}prof_badge_steps.webp';
  static const String badgeBook = '${dir}prof_badge_book.webp';
  static const String badgeCode = '${dir}prof_badge_code.webp';
  static const String collections = '${dir}prof_collections.webp';

  static const all = [banner, pencil, star, palette, book, padPurple, padPink, flame, robot, mosque, badgeSteps, badgeBook, badgeCode, collections];
}

/// Counts read from what the pages record.
class ProfileStats {
  final int courseLessons, itLessons, religionItems, gamePlays, distinctGames, streak;
  const ProfileStats(this.courseLessons, this.itLessons, this.religionItems, this.gamePlays, this.distinctGames, this.streak);
  static const empty = ProfileStats(0, 0, 0, 0, 0, 0);
  int get lessons => courseLessons + itLessons + religionItems;

  // Totals available in the app today (bars fill against these).
  static const int courseTotal = 18; // grade 1: math 8, french 3, science 4, islamic 3
  static const int itTotal = 5;
  static const int religionTotal = 12; // quran 6, duas 3, prayer 3
  static const int gamesTotal = 10;

  static Future<ProfileStats> load() async {
    final p = await SharedPreferences.getInstance();
    var courses = 0, it = 0, religion = 0, plays = 0, distinct = 0;
    for (final k in p.getKeys()) {
      if (k.startsWith('lessons_done_')) courses += (p.getStringList(k) ?? const []).length;
      if (k.startsWith('it_lessons_done_')) it += (p.getStringList(k) ?? const []).length;
      if (k.startsWith('religion_lessons_done_')) religion += (p.getStringList(k) ?? const []).length;
      if (k.startsWith('games_plays_')) {
        final n = p.getInt(k) ?? 0;
        plays += n;
        if (n > 0) distinct++;
      }
    }
    return ProfileStats(courses, it, religion, plays, distinct, await ActivityLog.streak());
  }
}

class _Badge {
  final String asset;
  final String Function(BuildContext) name, how;
  final bool Function(ProfileStats) earned;
  const _Badge(this.asset, this.name, this.how, this.earned);
}

final List<_Badge> _badges = [
  _Badge(ProfileAssets.badgeSteps, (c) => tr(c).badgeFirstSteps, (c) => tr(c).badgeFirstStepsHow, (s) => s.lessons + s.gamePlays >= 1),
  _Badge(ProfileAssets.badgeBook, (c) => tr(c).badgeBookLover, (c) => tr(c).badgeBookLoverHow, (s) => s.courseLessons >= 10),
  _Badge(ProfileAssets.badgeCode, (c) => tr(c).badgeCodeStarter, (c) => tr(c).badgeCodeStarterHow, (s) => s.itLessons >= 1),
];

/// A friendly title that grows with the level.
String profileTitle(BuildContext context, int level) {
  final t = tr(context);
  if (level <= 2) return t.titleLittleLearner;
  if (level <= 4) return t.titleCuriousExplorer;
  if (level <= 7) return t.titleBrightThinker;
  if (level <= 11) return t.titleStarScholar;
  return t.titleKnowledgeHero;
}

class ProfilePage extends StatefulWidget {
  final bool embedded; // shown as a bottom-bar tab: no back button
  const ProfilePage({super.key, this.embedded = false});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  late final AnimationController _idle =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  ProfileStats _stats = ProfileStats.empty;
  bool _precached = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      KidAssets.precache(context, [...ProfileAssets.all, KidAssets.valleyBg, KidAssets.backBtn]);
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _idle.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final s = await ProfileStats.load();
    if (mounted) setState(() => _stats = s);
  }

  Future<void> _open(Widget page) async {
    if (_busy) return;
    _busy = true;
    Provider.of<AudioManager>(context, listen: false).playEventSound('clickButton');
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    _busy = false;
    if (mounted) _refresh();
  }

  void _showBadge(_Badge b) {
    final earned = b.earned(_stats);
    Provider.of<AudioManager>(context, listen: false).playEventSound('clickButton2');
    showDialog(
      context: context,
      barrierColor: KidColors.purpleDeep.withOpacity(0.35),
      builder: (ctx) => KidDialog(
        headerAsset: b.asset,
        headerAspect: 0.77,
        title: b.name(ctx),
        message: earned ? '${tr(ctx).badgeEarned}\n${b.how(ctx)}' : b.how(ctx),
        actions: [KidOutlineButton(label: tr(ctx).awesome, onTap: () => Navigator.pop(ctx))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final xp = Provider.of<ExperienceManager>(context);
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final w = min(size.width, 600.0) - 28;
    final s = (w / 380).clamp(0.8, 1.45);
    final t = tr(context);
    final name = xp.userProfile.fullName.trim();
    final st = _stats;

    Widget step(int i, Widget child) =>
        KidIntro(intro: _intro, from: 0.06 * i, to: min(1.0, 0.42 + 0.06 * i), rise: 24, child: child);

    return Scaffold(
      backgroundColor: KidColors.sky,
      body: Stack(children: [
        const Positioned.fill(child: KidPageBackground()),
        SafeArea(
          bottom: false,
          child: Center(
            child: SizedBox(
              width: w,
              child: Column(children: [
                const SizedBox(height: 6),
                step(0, KidPageHeader(scale: s, title: t.myProfile, gold: xp.saveTokenCount, gems: xp.stars, showBack: !widget.embedded)),
                SizedBox(height: 8 * s),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(bottom: pad.bottom + 24),
                    children: [
                      step(
                        1,
                        _HeaderCard(
                          scale: s,
                          idle: _idle,
                          banner: xp.selectedBannerImage,
                          avatar: xp.selectedAvatar,
                          name: (name.isEmpty || name == 'Player') ? t.homeHiNoName : name,
                          title: profileTitle(context, xp.level),
                          onEdit: () => _open(const BannerAvatarProfile()),
                        ),
                      ),
                      SizedBox(height: 10 * s),
                      step(2, _LevelBar(scale: s, level: xp.level, now: xp.currentLevelXP, need: xp.requiredXPForNextLevel)),
                      SizedBox(height: 10 * s),
                      step(
                        3,
                        Row(children: [
                          Expanded(
                            child: _ActionPill(
                                scale: s,
                                icon: ProfileAssets.pencil,
                                label: t.editProfile,
                                onTap: () => _open(const UserAndSchoolInfoPage())),
                          ),
                          SizedBox(width: 10 * s),
                          Expanded(
                            child: _ActionPill(
                                scale: s,
                                icon: ProfileAssets.palette,
                                label: t.customizeLabel,
                                onTap: () => _open(const BannerAvatarProfile())),
                          ),
                        ]),
                      ),
                      SizedBox(height: 12 * s),
                      step(
                        4,
                        _Section(
                          scale: s,
                          title: t.myLearningJourney,
                          child: Row(children: [
                            Expanded(
                                child: _StatTile(scale: s, icon: ProfileAssets.book, value: '${st.lessons}', label: t.statLessons,
                                    color: const Color(0xFFDDF1FB))),
                            SizedBox(width: 8 * s),
                            Expanded(
                                child: _StatTile(scale: s, icon: ProfileAssets.padPurple, value: '${st.gamePlays}', label: t.statGames,
                                    color: const Color(0xFFF7E1F3))),
                            SizedBox(width: 8 * s),
                            Expanded(
                                child: _StatTile(scale: s, icon: ProfileAssets.flame, value: t.daysN(st.streak), label: t.statStreak,
                                    color: const Color(0xFFFCE7D9))),
                          ]),
                        ),
                      ),
                      SizedBox(height: 12 * s),
                      step(
                        5,
                        _Section(
                          scale: s,
                          title: t.myProgress,
                          child: Column(children: [
                            Row(children: [
                              Expanded(
                                child: _ProgressTile(scale: s, icon: ProfileAssets.book, title: t.courses,
                                    sub: t.lessonsN(st.courseLessons), value: st.courseLessons / ProfileStats.courseTotal,
                                    bg: const Color(0xFFEAE4FB), bar: const [Color(0xFF9B5CFF), Color(0xFF6A2BE0)]),
                              ),
                              SizedBox(width: 8 * s),
                              Expanded(
                                child: _ProgressTile(scale: s, icon: ProfileAssets.padPink, title: t.games,
                                    sub: t.playedN(st.gamePlays), value: st.distinctGames / ProfileStats.gamesTotal,
                                    bg: const Color(0xFFFBE3EF), bar: const [Color(0xFFFF7AB8), Color(0xFFEC3F8C)]),
                              ),
                            ]),
                            SizedBox(height: 8 * s),
                            Row(children: [
                              Expanded(
                                child: _ProgressTile(scale: s, icon: ProfileAssets.robot, title: t.homeIT,
                                    sub: t.lessonsN(st.itLessons), value: st.itLessons / ProfileStats.itTotal,
                                    bg: const Color(0xFFDCEFFB), bar: const [Color(0xFF5AA9FF), Color(0xFF2563EB)]),
                              ),
                              SizedBox(width: 8 * s),
                              Expanded(
                                child: _ProgressTile(scale: s, icon: ProfileAssets.mosque, title: t.homeReligion,
                                    sub: t.lessonsN(st.religionItems), value: st.religionItems / ProfileStats.religionTotal,
                                    bg: const Color(0xFFDDF6E7), bar: const [Color(0xFF34C985), Color(0xFF13915A)]),
                              ),
                            ]),
                          ]),
                        ),
                      ),
                      SizedBox(height: 12 * s),
                      step(
                        6,
                        _Section(
                          scale: s,
                          title: t.myBadges,
                          trailing: KidPressable(
                            onTap: () => _open(const QuestsPage(startOnMilestones: true)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Text(t.viewAll, style: kidBodyStyle(14 * s, color: KidColors.purpleDeep, weight: FontWeight.w700)),
                              Transform.flip(
                                flipX: Directionality.of(context) == TextDirection.rtl,
                                child: Icon(Icons.chevron_right_rounded, color: KidColors.purple, size: 24 * s),
                              ),
                            ]),
                          ),
                          child: Row(children: [
                            for (final b in _badges)
                              Expanded(
                                child: _BadgeView(
                                  scale: s,
                                  badge: b,
                                  earned: b.earned(st),
                                  idle: _idle,
                                  onTap: () => _showBadge(b),
                                ),
                              ),
                          ]),
                        ),
                      ),
                      SizedBox(height: 12 * s),
                      step(7, _CollectionsCard(scale: s, idle: _idle, onTap: () => _open(CollectionPagePremium()))),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Pieces
// ═══════════════════════════════════════════════════════════════════════════

const _ink = KidColors.ink;

Widget _avatarImage(String avatar, double size) {
  if (avatar.endsWith('.json')) return Lottie.asset(avatar, width: size, height: size, fit: BoxFit.cover);
  if (avatar.startsWith('assets/')) return Image.asset(avatar, width: size, height: size, fit: BoxFit.cover);
  return SizedBox(
      width: size, height: size, child: Center(child: Text(avatar.isEmpty ? '🙂' : avatar, style: TextStyle(fontSize: size * 0.5))));
}

class _HeaderCard extends StatelessWidget {
  final double scale;
  final Animation<double> idle;
  final String banner, avatar, name, title;
  final VoidCallback onEdit;
  const _HeaderCard({required this.scale, required this.idle, required this.banner, required this.avatar,
      required this.name, required this.title, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final bannerH = 140 * s;
    final av = 118 * s;
    final r = 26 * s;
    return SizedBox(
      height: bannerH + 92 * s,
      child: Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
        // The child's own banner (falls back to the space banner)
        Container(
          height: bannerH,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [BoxShadow(color: KidColors.purpleDeep.withOpacity(0.28), blurRadius: 18, offset: const Offset(0, 8))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(r - 3),
            child: Image.asset(
              banner.isEmpty ? ProfileAssets.banner : banner,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) => Image.asset(ProfileAssets.banner, fit: BoxFit.cover, width: double.infinity),
            ),
          ),
        ),
        PositionedDirectional(
          top: 10 * s,
          end: 10 * s,
          child: KidPressable(
            onTap: onEdit,
            semanticLabel: tr(context).customizeLabel,
            child: Image.asset(ProfileAssets.pencil, width: 42 * s, height: 42 * s),
          ),
        ),
        // Name plate
        Positioned(
          top: bannerH - 34 * s,
          child: Container(
            width: 220 * s,
            padding: EdgeInsets.fromLTRB(12 * s, 46 * s, 12 * s, 10 * s),
            decoration: kidCardDecoration(26 * s, shadow: 0.2),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(name, maxLines: 1, style: kidTitleStyle(30 * s, color: _ink).copyWith(shadows: const [])),
              ),
              SizedBox(height: 4 * s),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 3 * s),
                decoration: BoxDecoration(color: const Color(0xFFE6DCFF), borderRadius: BorderRadius.circular(30)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.auto_awesome_rounded, color: const Color(0xFFFFB627), size: 16 * s),
                  SizedBox(width: 4 * s),
                  Text(title, style: kidBodyStyle(13 * s, color: KidColors.purpleDeep, weight: FontWeight.w700)),
                ]),
              ),
            ]),
          ),
        ),
        // Avatar in a glowing ring
        Positioned(
          top: bannerH / 2 - av / 2 + 6 * s,
          child: AnimatedBuilder(
            animation: idle,
            builder: (_, c) => Transform.translate(offset: Offset(0, sin(idle.value * 4 * pi) * 2.5 * s), child: c),
            child: KidPressable(
              onTap: onEdit,
              child: Container(
                width: av,
                height: av,
                padding: EdgeInsets.all(5 * s),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFB794FF).withOpacity(0.7), blurRadius: 18),
                    BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: ClipOval(child: ColoredBox(color: const Color(0xFFDDEBFF), child: _avatarImage(avatar, av))),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _LevelBar extends StatelessWidget {
  final double scale;
  final int level, now, need;
  const _LevelBar({required this.scale, required this.level, required this.now, required this.need});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      height: 52 * s,
      padding: EdgeInsetsDirectional.only(start: 10 * s, end: 16 * s),
      decoration: kidCardDecoration(30 * s, shadow: 0.14),
      child: Row(children: [
        Image.asset(ProfileAssets.star, width: 34 * s, height: 34 * s),
        SizedBox(width: 6 * s),
        Text(tr(context).levelN(level), style: kidBodyStyle(17 * s, color: _ink, weight: FontWeight.w700)),
        SizedBox(width: 12 * s),
        Expanded(child: KidProgressBar(value: need <= 0 ? 0 : now / need, height: 14 * s)),
        SizedBox(width: 10 * s),
        Text('$now / $need XP', style: kidBodyStyle(12.5 * s, color: _ink, weight: FontWeight.w700)),
      ]),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final double scale;
  final String icon, label;
  final VoidCallback onTap;
  const _ActionPill({required this.scale, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return KidPressable(
      onTap: onTap,
      pressedScale: 0.95,
      semanticLabel: label,
      child: Container(
        height: 50 * s,
        padding: EdgeInsets.symmetric(horizontal: 12 * s),
        decoration: kidCardDecoration(30 * s, shadow: 0.14),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Image.asset(icon, width: 30 * s, height: 30 * s),
          SizedBox(width: 8 * s),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, style: kidBodyStyle(17 * s, color: _ink, weight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final double scale;
  final String title;
  final Widget? trailing;
  final Widget child;
  const _Section({required this.scale, required this.title, this.trailing, required this.child});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      padding: EdgeInsets.fromLTRB(12 * s, 12 * s, 12 * s, 12 * s),
      decoration: kidCardDecoration(26 * s, shadow: 0.16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: EdgeInsetsDirectional.only(start: 4 * s, bottom: 10 * s),
          child: Row(children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(title, style: kidTitleStyle(23 * s, color: _ink).copyWith(shadows: const [])),
              ),
            ),
            if (trailing != null) trailing!,
          ]),
        ),
        child,
      ]),
    );
  }
}

class _StatTile extends StatelessWidget {
  final double scale;
  final String icon, value, label;
  final Color color;
  const _StatTile({required this.scale, required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      height: 76 * s,
      padding: EdgeInsets.symmetric(horizontal: 6 * s),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18 * s)),
      child: Row(children: [
        Image.asset(icon, width: 36 * s, height: 36 * s, fit: BoxFit.contain),
        SizedBox(width: 4 * s),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 600),
                  builder: (_, v, c) => Opacity(opacity: v, child: c),
                  child: Text(value, maxLines: 1, style: kidTitleStyle(24 * s, color: _ink).copyWith(shadows: const [])),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(label, maxLines: 1, style: kidBodyStyle(12 * s, color: KidColors.purpleDeep, weight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _ProgressTile extends StatelessWidget {
  final double scale;
  final String icon, title, sub;
  final double value;
  final Color bg;
  final List<Color> bar;
  const _ProgressTile({required this.scale, required this.icon, required this.title, required this.sub,
      required this.value, required this.bg, required this.bar});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      height: 72 * s,
      padding: EdgeInsetsDirectional.only(start: 6 * s, end: 10 * s),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18 * s)),
      child: Row(children: [
        Container(
          width: 46 * s,
          height: 46 * s,
          padding: EdgeInsets.all(5 * s),
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.7)),
          child: Image.asset(icon, fit: BoxFit.contain),
        ),
        SizedBox(width: 8 * s),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(title, maxLines: 1, style: kidBodyStyle(15 * s, color: _ink, weight: FontWeight.w700)),
              ),
              SizedBox(height: 4 * s),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 8 * s,
                  child: Stack(children: [
                    const Positioned.fill(child: ColoredBox(color: Color(0xFFD9D6E0))),
                    AnimatedFractionallySizedBox(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      widthFactor: value.clamp(0.0, 1.0),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: bar)),
                      ),
                    ),
                  ]),
                ),
              ),
              SizedBox(height: 3 * s),
              Text(sub, style: kidBodyStyle(11.5 * s, color: KidColors.muted, weight: FontWeight.w600)),
            ],
          ),
        ),
      ]),
    );
  }
}

class _BadgeView extends StatelessWidget {
  final double scale;
  final _Badge badge;
  final bool earned;
  final Animation<double> idle;
  final VoidCallback onTap;
  const _BadgeView({required this.scale, required this.badge, required this.earned, required this.idle, required this.onTap});

  static const _grey = ColorFilter.matrix([
    0.33, 0.45, 0.12, 0, 20, //
    0.33, 0.45, 0.12, 0, 20,
    0.33, 0.45, 0.12, 0, 30,
    0, 0, 0, 0.75, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final s = scale;
    Widget img = Image.asset(badge.asset, width: 96 * s, height: 96 * s * 0.77, fit: BoxFit.contain);
    if (!earned) img = ColorFiltered(colorFilter: _grey, child: img);
    return KidPressable(
      onTap: onTap,
      semanticLabel: badge.name(context),
      child: Column(children: [
        Stack(alignment: Alignment.center, children: [
          earned
              ? AnimatedBuilder(
                  animation: idle,
                  builder: (_, c) => Transform.scale(scale: 1 + 0.03 * sin(idle.value * 8 * pi), child: c),
                  child: img,
                )
              : img,
          if (!earned)
            Container(
              padding: EdgeInsets.all(5 * s),
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.9)),
              child: Icon(Icons.lock_rounded, color: KidColors.purple, size: 18 * s),
            ),
        ]),
        SizedBox(height: 4 * s),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 4 * s),
          decoration: BoxDecoration(
            color: kidCardCream,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEFE6D2), width: 1.5),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(badge.name(context),
                maxLines: 1,
                style: kidBodyStyle(12.5 * s, color: earned ? _ink : KidColors.muted, weight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}

class _CollectionsCard extends StatelessWidget {
  final double scale;
  final Animation<double> idle;
  final VoidCallback onTap;
  const _CollectionsCard({required this.scale, required this.idle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final t = tr(context);
    return KidPressable(
      onTap: onTap,
      pressedScale: 0.97,
      semanticLabel: t.myCollections,
      child: Container(
        height: 84 * s,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26 * s),
          gradient: const LinearGradient(colors: [Color(0xFFF3ECFF), Color(0xFFE0D3FF)]),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [BoxShadow(color: KidColors.purpleDeep.withOpacity(0.2), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Row(children: [
          AnimatedBuilder(
            animation: idle,
            builder: (_, c) => Transform.rotate(angle: sin(idle.value * 4 * pi) * 0.03, child: c),
            child: Image.asset(ProfileAssets.collections, width: 150 * s, height: 150 * s * 0.4339),
          ),
          SizedBox(width: 6 * s),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(t.myCollections, style: kidTitleStyle(20 * s, color: _ink).copyWith(shadows: const [])),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(t.myCollectionsSub,
                      style: kidBodyStyle(12 * s, color: KidColors.purpleDeep, weight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.only(end: 12 * s),
            child: Transform.flip(
              flipX: Directionality.of(context) == TextDirection.rtl,
              child: Image.asset('assets/images/UI/KidScene/courses_go_purple.webp', width: 42 * s, height: 42 * s),
            ),
          ),
        ]),
      ),
    );
  }
}
