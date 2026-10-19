import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/Manager/models/avatar_catalog.dart';
import 'package:mortaalim/Manager/models/banner_catalog.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/games/PuzzleLand/pz_common.dart';
import 'package:mortaalim/screens/main_home_screen/Profile/Badges/badge_catalog.dart';
import 'package:mortaalim/screens/main_home_screen/Profile/Badges/my_badges_page.dart';
import 'package:mortaalim/screens/main_home_screen/Profile/Customize/customize_page.dart';
import 'package:mortaalim/screens/main_home_screen/Profile/Customize/profile_look.dart';
import 'package:mortaalim/screens/main_shop_screen/MainShopPageIndex.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:provider/provider.dart';

const Color _ink = Color(0xFF2A1366);
const Color _cream = Color(0xFFFFFCF4);
const Color _lavender = Color(0xFFEDE6FF);

class _ColAssets {
  static const String dir = 'assets/images/UI/Collection/';
  static const String hero = '${dir}col_hero.webp';
  static const String icAvatar = '${dir}col_ic_avatar.webp';
  static const String icBanner = '${dir}col_ic_banner.webp';
  static const String icFrame = '${dir}col_ic_frame.webp';
  static const String icTreasure = '${dir}col_ic_treasure.webp';
  static const String icBadge = '${dir}col_ic_badge.webp';
  static const String crystal = '${dir}col_crystal.webp';
  static const String rocket = '${dir}col_rocket.webp';
  static const String key = '${dir}col_key.webp';
  static const String shop = '${dir}col_shop.webp';
}

/// "My Collection": everything the child owns, grouped, with a peek at each.
class MyCollectionPage extends StatefulWidget {
  final bool embedded; // shown as a bottom-bar tab: no back button
  const MyCollectionPage({super.key, this.embedded = false});

  @override
  State<MyCollectionPage> createState() => _MyCollectionPageState();
}

class _MyCollectionPageState extends State<MyCollectionPage> with TickerProviderStateMixin {
  BadgeStats _badges = BadgeStats.empty;
  Map<String, List<int>> _puzzles = {};
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();

  AudioManager get _audio => Provider.of<AudioManager>(context, listen: false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _idle.dispose();
    _intro.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final level = Provider.of<ExperienceManager>(context, listen: false).level;
    final b = await BadgeStats.load(level: level);
    final p = await PZProgress.load();
    if (mounted) {
      setState(() {
        _badges = b;
        _puzzles = p;
      });
    }
  }

  Future<void> _open(Widget page) async {
    _audio.playEventSound('clickButton');
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _load();
  }

  List<String> get _completedPuzzles =>
      [for (final p in pzPictures) if ((_puzzles[p] ?? const [0]).any((v) => v > 0)) p];

  @override
  Widget build(BuildContext context) {
    final xp = Provider.of<ExperienceManager>(context);
    final size = MediaQuery.sizeOf(context);
    final w = min(size.width, 600.0) - 28;
    final s = (w / 380).clamp(0.82, 1.4).toDouble();

    // Avatars (selected first)
    final avatars = AvatarCatalog.sanitizeUnlocked(xp.unlockedAvatars);
    final selAvatar = AvatarCatalog.resolve(xp.selectedAvatar);
    final avatarPeek = [selAvatar, ...avatars.where((a) => a != selAvatar)].take(3).toList();
    // Banners
    final banners = BannerCatalog.sanitizeUnlocked(xp.unlockedBanners);
    final selBanner = BannerCatalog.resolve(xp.selectedBannerImage);
    final bannerPeek = [selBanner, ...banners.where((b) => b != selBanner)].take(3).toList();
    // Frames
    final frames = AvatarFrames.all.where((f) => AvatarFrames.owned(f, xp.level, xp.unlockedAvatarFrames)).toList();
    final selFrame = AvatarFrames.of(xp.selectedAvatarFrame);
    final framePeek = [if (selFrame != null) selFrame, ...frames.where((f) => f != selFrame)].take(3).toList();
    // Badges
    final earned = appBadges.where((b) => b.earned(_badges)).toList();
    final badgePeek = (earned.isEmpty ? appBadges.take(3) : earned.reversed.take(3)).toList();
    // Treasures = finished Puzzle Land pictures
    final treasures = _completedPuzzles;

    Widget step(int i, Widget child) =>
        KidIntro(intro: _intro, from: 0.07 * i, to: min(1.0, 0.42 + 0.07 * i), rise: 22, child: child);

    return Scaffold(
      backgroundColor: KidColors.sky,
      body: Stack(children: [
        Positioned.fill(child: Image.asset(KidAssets.valleyBg, fit: BoxFit.cover)),
        SafeArea(
          bottom: false,
          child: Center(
            child: SizedBox(
              width: w + 28,
              child: Column(children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(14, 6 * s, 14, 4 * s),
                  child: Row(children: [
                    if (!widget.embedded) ...[
                      KidBackButton(size: 52 * s, onTap: () {
                        _audio.playEventSound('cancelButton');
                        Navigator.maybePop(context);
                      }),
                      SizedBox(width: 12 * s),
                    ],
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(colT(context, 'title'), style: kidTitleStyle(36 * s, color: _ink)),
                      ),
                    ),
                  ]),
                ),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(14, 4, 14, widget.embedded ? 110 : 24),
                    children: [
                      step(0, _hero(s)),
                      SizedBox(height: 12 * s),
                      step(
                        1,
                        _row(s,
                            icon: _ColAssets.icAvatar,
                            title: colT(context, 'avatars'),
                            count: colT(context, 'owned', {'n': avatars.length}),
                            onTap: () => _open(const CustomizePage(initialTab: 0)),
                            peek: [
                              for (final a in avatarPeek)
                                _check(
                                  a == selAvatar,
                                  s,
                                  FramedAvatar(
                                    avatar: a,
                                    frame: a == selAvatar ? xp.selectedAvatarFrame : '',
                                    size: 62 * s,
                                  ),
                                ),
                            ]),
                      ),
                      step(
                        2,
                        _row(s,
                            icon: _ColAssets.icBanner,
                            title: colT(context, 'banners'),
                            count: colT(context, 'owned', {'n': banners.length}),
                            onTap: () => _open(const CustomizePage(initialTab: 1)),
                            peek: [
                              for (final b in bannerPeek)
                                _check(
                                  b == selBanner,
                                  s,
                                  Container(
                                    width: 66 * s,
                                    height: 52 * s,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12 * s),
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 5, offset: const Offset(0, 2))],
                                      image: DecorationImage(image: AssetImage(b), fit: BoxFit.cover),
                                    ),
                                  ),
                                ),
                            ]),
                      ),
                      step(
                        3,
                        _row(s,
                            icon: _ColAssets.icFrame,
                            title: colT(context, 'frames'),
                            count: colT(context, 'owned', {'n': frames.length}),
                            onTap: () => _open(const CustomizePage(initialTab: 2)),
                            peek: [
                              for (final f in framePeek)
                                SizedBox(
                                  width: 66 * s,
                                  height: 62 * s,
                                  child: Image.asset(f.asset, fit: BoxFit.contain),
                                ),
                            ]),
                      ),
                      step(
                        4,
                        _row(s,
                            icon: _ColAssets.icTreasure,
                            title: colT(context, 'treasures'),
                            count: colT(context, 'collected', {'n': treasures.length}),
                            onTap: () => _open(_TreasuresPage(completed: treasures.toSet())),
                            peek: [
                              for (final (i, a) in [_ColAssets.crystal, _ColAssets.rocket, _ColAssets.key].indexed)
                                AnimatedBuilder(
                                  animation: _idle,
                                  builder: (_, c) =>
                                      Transform.translate(offset: Offset(0, sin(_idle.value * 2 * pi + i * 1.3) * 3 * s), child: c),
                                  child: SizedBox(width: 62 * s, height: 62 * s, child: Image.asset(a, fit: BoxFit.contain)),
                                ),
                            ]),
                      ),
                      step(
                        5,
                        _row(s,
                            icon: _ColAssets.icBadge,
                            title: colT(context, 'badges'),
                            count: colT(context, 'unlocked', {'n': earned.length}),
                            onTap: () => _open(const MyBadgesPage()),
                            peek: [
                              for (final b in badgePeek)
                                Opacity(
                                  opacity: b.earned(_badges) ? 1 : 0.55,
                                  child: SizedBox(width: 64 * s, height: 58 * s, child: Image.asset(b.asset, fit: BoxFit.contain)),
                                ),
                            ]),
                      ),
                      step(6, _shopRow(s)),
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

  BoxDecoration _card() => BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [BoxShadow(color: KidColors.purpleDeep.withOpacity(0.15), blurRadius: 14, offset: const Offset(0, 6))],
      );

  Widget _hero(double s) {
    return AspectRatio(
      aspectRatio: 851 / 278,
      child: Stack(children: [
        Positioned.fill(child: Image.asset(_ColAssets.hero, fit: BoxFit.fill)),
        PositionedDirectional(
          start: 0,
          top: 0,
          bottom: 0,
          width: (MediaQuery.sizeOf(context).width - 28) * 0.46,
          child: Padding(
            padding: EdgeInsetsDirectional.only(start: 18 * s),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _OutlinedText(colT(context, 'hero'), size: 26 * s),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _check(bool on, double s, Widget child) {
    if (!on) return child;
    return Stack(clipBehavior: Clip.none, children: [
      child,
      PositionedDirectional(
        end: -4 * s,
        bottom: -4 * s,
        child: Container(
          width: 22 * s,
          height: 22 * s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF22B573),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(Icons.check_rounded, color: Colors.white, size: 14 * s),
        ),
      ),
    ]);
  }

  Widget _row(double s,
      {required String icon, required String title, required String count, required VoidCallback onTap, required List<Widget> peek}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10 * s),
      child: KidPressable(
        onTap: onTap,
        pressedScale: 0.97,
        semanticLabel: title,
        child: Container(
          height: 96 * s,
          padding: EdgeInsetsDirectional.fromSTEB(10 * s, 8 * s, 8 * s, 8 * s),
          decoration: _card(),
          child: Row(children: [
            Image.asset(icon, width: 52 * s, height: 52 * s),
            SizedBox(width: 8 * s),
            SizedBox(
              width: 98 * s,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(title, maxLines: 1, style: kidBodyStyle(20 * s, color: _ink, weight: FontWeight.w700)),
                  ),
                  SizedBox(height: 4 * s),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 3 * s),
                    decoration: BoxDecoration(color: _lavender, borderRadius: BorderRadius.circular(20)),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(count, style: kidBodyStyle(13 * s, color: KidColors.purpleDeep, weight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [for (final p in peek) Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: p))],
              ),
            ),
            Container(
              width: 34 * s,
              height: 34 * s,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: _lavender),
              child: Transform.flip(
                flipX: Directionality.of(context) == TextDirection.rtl,
                child: Icon(Icons.chevron_right_rounded, color: KidColors.purple, size: 26 * s),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _shopRow(double s) {
    return KidPressable(
      onTap: () => _open(const MainShopPageIndex()),
      pressedScale: 0.97,
      child: Container(
        height: 84 * s,
        padding: EdgeInsetsDirectional.fromSTEB(6 * s, 4 * s, 12 * s, 4 * s),
        decoration: _card(),
        child: Row(children: [
          AnimatedBuilder(
            animation: _idle,
            builder: (_, c) => Transform.rotate(angle: sin(_idle.value * 2 * pi * 2) * 0.06, child: c),
            child: Image.asset(_ColAssets.shop, width: 72 * s, height: 72 * s),
          ),
          SizedBox(width: 12 * s),
          Expanded(
            child: Text(colT(context, 'shop'), style: kidBodyStyle(22 * s, color: _ink, weight: FontWeight.w700)),
          ),
          Transform.flip(
            flipX: Directionality.of(context) == TextDirection.rtl,
            child: Icon(Icons.chevron_right_rounded, color: KidColors.purple, size: 32 * s),
          ),
        ]),
      ),
    );
  }
}

class _OutlinedText extends StatelessWidget {
  final String text;
  final double size;
  const _OutlinedText(this.text, {required this.size});

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w700, fontSize: size, height: 1.05);
    return Stack(children: [
      Text(text,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = size * 0.22
              ..strokeJoin = StrokeJoin.round
              ..color = const Color(0xFF4A1FB8),
          )),
      Text(text, style: base.copyWith(color: Colors.white)),
    ]);
  }
}

/// Treasures: the Puzzle Land pictures the child has completed.
class _TreasuresPage extends StatelessWidget {
  final Set<String> completed;
  const _TreasuresPage({required this.completed});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = min(size.width, 600.0) - 28;
    final s = (w / 380).clamp(0.82, 1.4).toDouble();
    return Scaffold(
      backgroundColor: KidColors.sky,
      body: Stack(children: [
        Positioned.fill(child: Image.asset(KidAssets.valleyBg, fit: BoxFit.cover)),
        SafeArea(
          child: Center(
            child: SizedBox(
              width: w + 28,
              child: Column(children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(14, 6 * s, 14, 4 * s),
                  child: Row(children: [
                    KidBackButton(size: 52 * s, onTap: () => Navigator.maybePop(context)),
                    SizedBox(width: 12 * s),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(colT(context, 'treasures'), style: kidTitleStyle(34 * s, color: _ink)),
                      ),
                    ),
                  ]),
                ),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 14, vertical: 4 * s),
                  padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 6 * s),
                  decoration: BoxDecoration(color: _lavender.withOpacity(0.95), borderRadius: BorderRadius.circular(20)),
                  child: Text(colT(context, 'treasureHint'),
                      textAlign: TextAlign.center,
                      style: kidBodyStyle(14 * s, color: KidColors.purpleDeep, weight: FontWeight.w700)),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                    physics: const BouncingScrollPhysics(),
                    itemCount: pzPictures.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12 * s,
                      crossAxisSpacing: 12 * s,
                      childAspectRatio: 0.86,
                    ),
                    itemBuilder: (ctx, i) {
                      final p = pzPictures[i];
                      final got = completed.contains(p);
                      return KidPressable(
                        onTap: got
                            ? () => showDialog(
                                  context: ctx,
                                  barrierColor: Colors.black.withOpacity(0.6),
                                  builder: (d) => GestureDetector(
                                    onTap: () => Navigator.pop(d),
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(26),
                                          child: Image.asset(PZAssets.picture(p), fit: BoxFit.contain),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                            : null,
                        child: Container(
                          padding: EdgeInsets.all(7 * s),
                          decoration: BoxDecoration(
                            color: _cream,
                            borderRadius: BorderRadius.circular(22 * s),
                            border: Border.all(color: got ? const Color(0xFFFFC21A) : Colors.white, width: 3),
                            boxShadow: [BoxShadow(color: KidColors.purpleDeep.withOpacity(0.14), blurRadius: 10, offset: const Offset(0, 5))],
                          ),
                          child: Column(children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16 * s),
                                child: Stack(fit: StackFit.expand, children: [
                                  got
                                      ? Image.asset(PZAssets.picture(p), fit: BoxFit.cover)
                                      : ColorFiltered(
                                          colorFilter: const ColorFilter.matrix([
                                            0.2, 0.2, 0.2, 0, 150, 0.2, 0.2, 0.2, 0, 140, 0.2, 0.2, 0.2, 0, 190, 0, 0, 0, 1, 0, //
                                          ]),
                                          child: Image.asset(PZAssets.picture(p), fit: BoxFit.cover),
                                        ),
                                  if (!got)
                                    Center(
                                      child: Container(
                                        padding: EdgeInsets.all(8 * s),
                                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                                        child: Icon(Icons.extension_rounded, color: KidColors.purple, size: 24 * s),
                                      ),
                                    ),
                                ]),
                              ),
                            ),
                            SizedBox(height: 6 * s),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(pzT(ctx, 'pic_$p'),
                                  style: kidBodyStyle(14 * s, color: got ? _ink : KidColors.muted, weight: FontWeight.w700)),
                            ),
                          ]),
                        ),
                      );
                    },
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

String colT(BuildContext context, String key, [Map<String, Object>? args]) {
  final code = Localizations.localeOf(context).languageCode;
  final lang = _col.containsKey(code) ? code : (code == 'zgh' ? 'fr' : 'en');
  var s = _col[lang]![key] ?? _col['en']![key] ?? key;
  args?.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
  return s;
}

const Map<String, Map<String, String>> _col = {
  'en': {
    'title': 'My Collection',
    'hero': 'Your little\nworld of\nwonders',
    'avatars': 'Avatars',
    'banners': 'Banners',
    'frames': 'Frames',
    'treasures': 'Treasures',
    'badges': 'Badges',
    'owned': '{n} owned',
    'collected': '{n} collected',
    'unlocked': '{n} unlocked',
    'shop': 'Discover the shop',
    'treasureHint': 'Finish a Puzzle Land picture to add it to your treasures!',
  },
  'fr': {
    'title': 'Ma collection',
    'hero': 'Ton petit\nmonde de\nmerveilles',
    'avatars': 'Avatars',
    'banners': 'Bannières',
    'frames': 'Cadres',
    'treasures': 'Trésors',
    'badges': 'Badges',
    'owned': '{n} à moi',
    'collected': '{n} trouvés',
    'unlocked': '{n} gagnés',
    'shop': 'Découvre la boutique',
    'treasureHint': 'Termine une image de Puzzle Land pour l\'ajouter à tes trésors !',
  },
  'ar': {
    'title': 'مجموعتي',
    'hero': 'عالمك\nالصغير\nالمليء بالعجائب',
    'avatars': 'الشخصيات',
    'banners': 'الخلفيات',
    'frames': 'الإطارات',
    'treasures': 'الكنوز',
    'badges': 'الأوسمة',
    'owned': '{n} أملكها',
    'collected': '{n} مجموعة',
    'unlocked': '{n} مفتوحة',
    'shop': 'اكتشف المتجر',
    'treasureHint': 'أكمل صورة في أرض الألغاز لتضيفها إلى كنوزك!',
  },
  'de': {
    'title': 'Meine Sammlung',
    'hero': 'Deine kleine\nWunderwelt',
    'avatars': 'Avatare',
    'banners': 'Banner',
    'frames': 'Rahmen',
    'treasures': 'Schätze',
    'badges': 'Abzeichen',
    'owned': '{n} gehören dir',
    'collected': '{n} gesammelt',
    'unlocked': '{n} offen',
    'shop': 'Entdecke den Shop',
    'treasureHint': 'Schaffe ein Puzzle-Land-Bild, um es zu deinen Schätzen zu legen!',
  },
};
