import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/Manager/models/banner_catalog.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/screens/main_shop_screen/MainShopPageIndex.dart';
import 'package:provider/provider.dart';

import 'cw_common.dart';

/// "Banner island": a painter robot shows each banner on a golden easel.
class CwBannersPage extends StatefulWidget {
  const CwBannersPage({super.key});
  @override
  State<CwBannersPage> createState() => _CwBannersPageState();
}

class _CwBannersPageState extends State<CwBannersPage> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  late final AnimationController _paint = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
  late final AnimationController _burst = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  String? _preview;

  @override
  void dispose() {
    _idle.dispose();
    _paint.dispose();
    _burst.dispose();
    super.dispose();
  }

  void _pick(String b) {
    if (b == _preview) return;
    cwSound(context, 'PopButton');
    setState(() => _preview = b);
    _paint.forward(from: 0);
  }

  Map<String, dynamic>? _shopEntry(String b) {
    for (final e in BannerCatalog.shop) {
      if (e['image'] == b) return e;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final xp = context.watch<ExperienceManager>();
    final s = cwScale(context);
    final h = MediaQuery.sizeOf(context).height;
    final owned = BannerCatalog.sanitizeUnlocked(xp.unlockedBanners);
    final equipped = BannerCatalog.resolve(xp.selectedBannerImage);
    final shown = _preview ?? equipped;
    final ownedShown = owned.contains(shown);
    final isEquipped = shown == equipped;
    // owned first, then the ones still to find
    final all = [...owned, ...BannerCatalog.all.where((b) => !owned.contains(b))];
    final heroH = (h * 0.34).clamp(240.0, 340.0);
    final btnW = min(MediaQuery.sizeOf(context).width * 0.78, 340 * s);

    return CwIslandLayout(
      s: s,
      header: Column(children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10 * s),
          child: Row(children: [
            CwBack(size: 48 * s),
            SizedBox(width: 6 * s),
            Expanded(child: CwTitlePill(title: cwT(context, 'bnTitle'), s: s)),
            SizedBox(width: 30 * s),
          ]),
        ),
        SizedBox(height: 4 * s),
        CwChip(s: s, icon: Icons.image_rounded, text: cwT(context, 'bnCount', {'n': owned.length})),
      ]),
      heroHeight: heroH,
      hero: _hero(s, heroH, shown, ownedShown, isEquipped),
      panel: Column(children: [
        CwPanelTitle(s: s, text: cwT(context, 'bnPick')),
        SizedBox(height: 10 * s),
        Expanded(
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(bottom: 8 * s),
            itemCount: all.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10 * s,
              crossAxisSpacing: 10 * s,
              childAspectRatio: 2.1,
            ),
            itemBuilder: (_, i) => _tile(s, all[i], owned.contains(all[i]), all[i] == shown, all[i] == equipped),
          ),
        ),
        SizedBox(height: 6 * s),
        if (ownedShown)
          CwButton(
            asset: cw('av_btn_orange'),
            label: cwT(context, 'bnChoose'),
            onTap: isEquipped
                ? null
                : () {
                    xp.selectBannerImage(shown);
                    cwCelebrate(context);
                    _burst.forward(from: 0);
                  },
            width: btnW,
            aspect: 0.2687,
            s: s,
            pulse: _idle,
          )
        else
          CwButton(
            asset: cw('av_btn_orange'),
            label: cwT(context, 'goShop'),
            onTap: () => cwOpen(context, const MainShopPageIndex()),
            width: btnW,
            aspect: 0.2687,
            s: s,
            leading: Icon(Icons.storefront_rounded, color: Colors.white, size: 22 * s),
          ),
        SizedBox(height: 4 * s),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.info_rounded, size: 16 * s, color: cwInkSoft),
          SizedBox(width: 5 * s),
          Flexible(
            child: Text(
              !ownedShown ? cwT(context, 'inShop') : (isEquipped ? cwT(context, 'bnAlready') : cwT(context, 'bnHint')),
              style: cwText(13.5 * s, color: cwInkSoft, weight: FontWeight.w500),
            ),
          ),
        ]),
        CwBackLink(s: s),
      ]),
    );
  }

  Widget _hero(double s, double heroH, String shown, bool owned, bool isEquipped) => LayoutBuilder(builder: (_, c) {
        final w = c.maxWidth;
        final easelW = min(w * 0.66, heroH * 0.95 / 0.8348);
        final easelH = easelW * 0.8348;
        final ex = w * 0.55 - easelW / 2;
        // hole of the easel frame (fractions)
        final hole = Rect.fromLTRB(ex + easelW * 0.048, easelH * 0.2552, ex + easelW * 0.954, easelH * 0.7396);
        return Stack(clipBehavior: Clip.none, children: [
          Positioned.fill(child: CwSparkles(idle: _idle, count: 12, seed: 41)),
          // the painting appears like it is being painted (left → right)
          Positioned.fromRect(
            rect: hole,
            child: AnimatedBuilder(
              animation: _paint,
              builder: (_, child) => ClipRect(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: Curves.easeOutCubic.transform(_paint.value).clamp(0.02, 1.0).toDouble(),
                  child: child,
                ),
              ),
              child: SizedBox(
                width: hole.width,
                height: hole.height,
                child: owned
                    ? Image.asset(shown, fit: BoxFit.cover)
                    : ColorFiltered(colorFilter: cwGrey, child: Image.asset(shown, fit: BoxFit.cover)),
              ),
            ),
          ),
          Positioned(left: ex, top: 0, width: easelW, height: easelH, child: IgnorePointer(child: Image.asset(cw('bn_easel')))),
          if (!owned)
            Positioned.fromRect(
              rect: hole,
              child: Center(child: Image.asset(cw('fr_lock'), width: 44 * s)),
            ),
          Positioned.fill(child: CwBurst(anim: _burst)),
          // painter robot
          PositionedDirectional(
            start: -4 * s,
            bottom: heroH * 0.06,
            child: AnimatedBuilder(
              animation: Listenable.merge([_idle, _paint]),
              builder: (_, c) {
                final brush = _paint.isAnimating ? sin(_paint.value * pi * 6) * 0.08 : sin(_idle.value * 2 * pi * 2) * 0.03;
                return Transform.rotate(angle: brush, alignment: Alignment.bottomCenter, child: c);
              },
              child: Transform.flip(flipX: cwRtl(context), child: Image.asset(cw('bn_robot'), height: heroH * 0.62)),
            ),
          ),
          // plaque under the easel
          Positioned(
            left: ex + easelW * 0.18,
            width: easelW * 0.64,
            top: easelH - 4 * s,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              CwPlaque(s: s, text: _bannerName(shown), width: easelW * 0.64, fontSize: 17),
              SizedBox(height: 3 * s),
              if (isEquipped) CwEquipped(s: s, text: cwT(context, 'equipped')),
            ]),
          ),
        ]);
      });

  String _bannerName(String path) {
    final key = path.split('/').last.replaceAll('.webp', '');
    final n = _names[key];
    return n == null ? key : cwPick(context, n);
  }

  Widget _tile(double s, String b, bool owned, bool sel, bool eq) {
    final e = _shopEntry(b);
    final cost = (e?['cost'] as int?) ?? 0;
    return CwPress(
      onTap: () => _pick(b),
      label: _bannerName(b),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16 * s),
          border: Border.all(color: sel ? const Color(0xFF34E0D6) : const Color(0xFFE8C77A), width: sel ? 3.5 * s : 2 * s),
          boxShadow: [
            if (sel) BoxShadow(color: const Color(0xFF34E0D6).withOpacity(0.6), blurRadius: 12 * s),
            BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6 * s, offset: Offset(0, 3 * s)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13 * s),
          child: Stack(fit: StackFit.expand, children: [
            owned ? Image.asset(b, fit: BoxFit.cover) : ColorFiltered(colorFilter: cwGrey, child: Image.asset(b, fit: BoxFit.cover)),
            if (!owned) ...[
              ColoredBox(color: Colors.white.withOpacity(0.15)),
              Center(child: Image.asset(cw('fr_lock'), width: 30 * s)),
              if (cost > 0)
                PositionedDirectional(
                  bottom: 4 * s,
                  end: 4 * s,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 7 * s, vertical: 2 * s),
                    decoration: BoxDecoration(color: cwInk.withOpacity(0.85), borderRadius: BorderRadius.circular(12 * s)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.monetization_on_rounded, color: cwGold, size: 13 * s),
                      SizedBox(width: 3 * s),
                      Text('$cost', style: cwText(11.5 * s, color: Colors.white)),
                    ]),
                  ),
                ),
            ],
            if (eq)
              PositionedDirectional(top: 4 * s, end: 4 * s, child: Image.asset(cw('av_check'), width: 24 * s)),
          ]),
        ),
      ),
    );
  }

  static const Map<String, Map<String, String>> _names = {
    'space': {'fr': 'Voyage spatial', 'en': 'Space trip', 'ar': 'رحلة فضائية', 'de': 'Weltraumreise'},
    'jungle': {'fr': 'Forêt enchantée', 'en': 'Enchanted forest', 'ar': 'الغابة المسحورة', 'de': 'Zauberwald'},
    'mountains': {'fr': 'Montagnes', 'en': 'Mountains', 'ar': 'الجبال', 'de': 'Berge'},
    'ocean': {'fr': 'Fond marin', 'en': 'Under the sea', 'ar': 'أعماق البحر', 'de': 'Unterwasserwelt'},
    'rainbow': {'fr': 'Arc-en-ciel', 'en': 'Rainbow', 'ar': 'قوس قزح', 'de': 'Regenbogen'},
    'library': {'fr': 'Bibliothèque', 'en': 'Library', 'ar': 'المكتبة', 'de': 'Bibliothek'},
    'candy': {'fr': 'Pays des bonbons', 'en': 'Candy land', 'ar': 'أرض الحلوى', 'de': 'Süßigkeitenland'},
    'dinos': {'fr': 'Vallée des dinos', 'en': 'Dino valley', 'ar': 'وادي الديناصورات', 'de': 'Dino-Tal'},
    'winter': {'fr': 'Château d’hiver', 'en': 'Winter castle', 'ar': 'قصر الشتاء', 'de': 'Winterschloss'},
    'train': {'fr': 'Petit train', 'en': 'Little train', 'ar': 'القطار الصغير', 'de': 'Kleiner Zug'},
    'sky_islands': {'fr': 'Îles du ciel', 'en': 'Sky islands', 'ar': 'جزر السماء', 'de': 'Himmelsinseln'},
    'robot_lab': {'fr': 'Labo des robots', 'en': 'Robot lab', 'ar': 'مختبر الروبوتات', 'de': 'Roboterlabor'},
    'savanna': {'fr': 'Savane', 'en': 'Savanna', 'ar': 'السافانا', 'de': 'Savanne'},
    'beach': {'fr': 'Plage', 'en': 'Beach', 'ar': 'الشاطئ', 'de': 'Strand'},
    'kites': {'fr': 'Cerfs-volants', 'en': 'Kites', 'ar': 'الطائرات الورقية', 'de': 'Drachen steigen'},
    'garden_bugs': {'fr': 'Jardin des insectes', 'en': 'Bug garden', 'ar': 'حديقة الحشرات', 'de': 'Käfergarten'},
    'mushroom_village': {'fr': 'Village champignon', 'en': 'Mushroom village', 'ar': 'قرية الفطر', 'de': 'Pilzdorf'},
    'crystal_cave': {'fr': 'Grotte de cristal', 'en': 'Crystal cave', 'ar': 'كهف الكريستال', 'de': 'Kristallhöhle'},
  };
}
