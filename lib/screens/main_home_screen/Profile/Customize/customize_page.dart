import 'package:mortaalim/widgets/KidScene/kid_toast.dart';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/Manager/models/avatar_catalog.dart';
import 'package:mortaalim/Manager/models/banner_catalog.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:provider/provider.dart';

import 'profile_look.dart';

const Color _ink = Color(0xFF2A1366);
const Color _cream = Color(0xFFFFFCF4);
const Color _lavender = Color(0xFFEFEAFF);
const Color _cyan = Color(0xFF22C7DE);

class _CustAssets {
  static const String dir = 'assets/images/UI/KidScene/';
  static const String tabAvatar = '${dir}cust_tab_avatar.webp';
  static const String tabBanner = '${dir}cust_tab_banner.webp';
  static const String tabFrame = '${dir}cust_tab_frame.webp';
  static const String gem = '${dir}home_gem.webp';
}

const Set<String> _animals = {
  AvatarCatalog.fox,
  AvatarCatalog.foxCub,
  AvatarCatalog.panda,
  AvatarCatalog.kitty,
  AvatarCatalog.dragon,
};

/// "Personnaliser": avatar, banner, frame and profile title, with a live preview.
class CustomizePage extends StatefulWidget {
  final int initialTab; // 0 avatars, 1 banners, 2 frames
  const CustomizePage({super.key, this.initialTab = 0});

  @override
  State<CustomizePage> createState() => _CustomizePageState();
}

class _CustomizePageState extends State<CustomizePage> with SingleTickerProviderStateMixin {
  late String _avatar, _banner, _frame;
  int _title = -1;
  int _tab = 0;
  int _avatarFilter = 0; // 0 all, 1 characters, 2 animals
  int _frameFilter = 0; // 0 all, 1 owned, 2 locked
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();

  ExperienceManager get _xp => Provider.of<ExperienceManager>(context, listen: false);
  AudioManager get _audio => Provider.of<AudioManager>(context, listen: false);

  @override
  void initState() {
    super.initState();
    final xp = _xp;
    _tab = widget.initialTab < 0 ? 0 : (widget.initialTab > 2 ? 2 : widget.initialTab);
    _avatar = AvatarCatalog.resolve(xp.selectedAvatar);
    _banner = BannerCatalog.resolve(xp.selectedBannerImage);
    _frame = AvatarFrames.resolve(xp.selectedAvatarFrame);
    ProfileTitleStore.load().then((_) {
      if (mounted) setState(() => _title = ProfileTitleStore.choice);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final a in [...AvatarCatalog.all, ...BannerCatalog.all]) {
      precacheImage(AssetImage(a), context);
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    super.dispose();
  }

  String _t(String key, [Map<String, Object>? args]) => custT(context, key, args);

  void _pick(VoidCallback f) {
    _audio.playEventSound('clickButton2');
    setState(f);
  }

  Future<void> _save() async {
    final xp = _xp;
    _audio.playEventSound('clickButton');
    if (AvatarCatalog.starter.contains(_avatar)) xp.unlockAvatar(_avatar);
    xp.selectAvatar(_avatar);
    xp.selectBannerImage(_banner);
    xp.unlockAvatarFrame(_frame);
    xp.selectAvatarFrame(_frame);
    await ProfileTitleStore.save(_title);
    if (!mounted) return;
    _audio.playSfx('assets/audios/UI_Audio/SFX_Audio/MarimbaWin_SFX.mp3');
    KidToast.show(KidToastKind.saved);
    Navigator.pop(context);
  }

  void _snack(String msg) {
    _audio.playEventSound('invalid');
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: KidColors.purpleDeep,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(msg, style: kidBodyStyle(15, color: Colors.white, weight: FontWeight.w600)),
      ));
  }

  Future<void> _buyBanner(String path, int cost) async {
    _audio.playEventSound('clickButton2');
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: KidColors.purpleDeep.withOpacity(0.35),
      builder: (ctx) => KidDialog(
        title: _t('unlockTitle'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset(path, height: 90, fit: BoxFit.cover)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Image.asset(_CustAssets.gem, width: 26, height: 26),
            const SizedBox(width: 6),
            Text('$cost', style: kidBodyStyle(22, color: _ink, weight: FontWeight.w700)),
          ]),
        ]),
        actions: [
          KidOutlineButton(label: tr(ctx).cancel, onTap: () => Navigator.pop(ctx, false)),
          const SizedBox(height: 10),
          KidButton(
            label: tr(ctx).unlock,
            width: double.infinity,
            height: 54,
            showArrow: false,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final xp = _xp;
    if (xp.gems < cost) return _snack(_t('notEnoughGems'));
    xp.spendGems(context, cost);
    xp.unlockBanner(path);
    KidToast.show(KidToastKind.banner);
    _audio.playSfx('assets/audios/UI_Audio/SFX_Audio/PurchaseSound.mp3');
    setState(() => _banner = path);
  }

  Future<void> _buyAvatar(String path, int cost) async {
    _audio.playEventSound('clickButton2');
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: KidColors.purpleDeep.withOpacity(0.35),
      builder: (ctx) => KidDialog(
        title: _t('unlockTitle'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          ClipOval(child: Image.asset(path, height: 96, width: 96, fit: BoxFit.cover)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Image.asset(_CustAssets.gem, width: 26, height: 26),
            const SizedBox(width: 6),
            Text('$cost', style: kidBodyStyle(22, color: _ink, weight: FontWeight.w700)),
          ]),
        ]),
        actions: [
          KidOutlineButton(label: tr(ctx).cancel, onTap: () => Navigator.pop(ctx, false)),
          const SizedBox(height: 10),
          KidButton(
            label: tr(ctx).unlock,
            width: double.infinity,
            height: 54,
            showArrow: false,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final xp = _xp;
    if (xp.gems < cost) return _snack(_t('notEnoughGems'));
    xp.spendGems(context, cost);
    xp.unlockAvatar(path);
    KidToast.show(KidToastKind.avatar);
    _audio.playSfx('assets/audios/UI_Audio/SFX_Audio/PurchaseSound.mp3');
    setState(() => _avatar = path);
  }

  Future<void> _buyFrame(AvatarFrame f) async {
    _audio.playEventSound('clickButton2');
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: KidColors.purpleDeep.withOpacity(0.35),
      builder: (ctx) => KidDialog(
        title: _t('unlockFrame'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          FramedAvatar(avatar: _avatar, frame: f.id, size: 120),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Image.asset(_CustAssets.gem, width: 26, height: 26),
            const SizedBox(width: 6),
            Text('${f.gems}', style: kidBodyStyle(22, color: _ink, weight: FontWeight.w700)),
          ]),
        ]),
        actions: [
          KidOutlineButton(label: tr(ctx).cancel, onTap: () => Navigator.pop(ctx, false)),
          const SizedBox(height: 10),
          KidButton(
            label: tr(ctx).unlock,
            width: double.infinity,
            height: 54,
            showArrow: false,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final xp = _xp;
    if (xp.gems < f.gems) return _snack(_t('notEnoughGems'));
    xp.spendGems(context, f.gems);
    xp.unlockAvatarFrame(f.id);
    KidToast.show(KidToastKind.avatar, title: _t('frameUnlocked'));
    _audio.playSfx('assets/audios/UI_Audio/SFX_Audio/PurchaseSound.mp3');
    setState(() => _frame = f.id);
  }

  Future<void> _pickTitle() async {
    _audio.playEventSound('clickButton2');
    final level = _xp.level;
    final max = ProfileTitleStore.tierFor(level);
    final r = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(16, 14, 16, 16 + MediaQuery.paddingOf(ctx).bottom),
        decoration: const BoxDecoration(color: _cream, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(width: 48, height: 5, decoration: BoxDecoration(color: _lavender, borderRadius: BorderRadius.circular(5))),
            ),
            const SizedBox(height: 12),
            Text(_t('profileTitle'), style: kidBodyStyle(22, color: _ink, weight: FontWeight.w700)),
            const SizedBox(height: 10),
            _titleOption(ctx, -1, _t('autoTitle'), true, null),
            for (var i = 0; i < ProfileTitleStore.minLevel.length; i++)
              _titleOption(ctx, i, titleName(ctx, i), i <= max, ProfileTitleStore.minLevel[i]),
          ],
        ),
      ),
    );
    if (r != null && mounted) _pick(() => _title = r);
  }

  Widget _titleOption(BuildContext ctx, int tier, String label, bool open, int? lvl) {
    final on = _title == tier;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: KidPressable(
        onTap: open ? () => Navigator.pop(ctx, tier) : () => _snack(_t('reachLevel', {'n': lvl!})),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: on ? const Color(0xFFE3F9FC) : (open ? Colors.white : _lavender),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: on ? _cyan : Colors.white, width: 2.5),
          ),
          child: Row(children: [
            Icon(open ? Icons.auto_awesome_rounded : Icons.lock_rounded,
                color: open ? const Color(0xFFFFC21A) : KidColors.purple, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: kidBodyStyle(17, color: open ? _ink : KidColors.muted, weight: FontWeight.w700)),
            ),
            if (!open && lvl != null)
              Text(_t('levelShort', {'n': lvl}), style: kidBodyStyle(14, color: KidColors.purple, weight: FontWeight.w700)),
            if (on) const Icon(Icons.check_circle_rounded, color: _cyan),
          ]),
        ),
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final xp = Provider.of<ExperienceManager>(context);
    final size = MediaQuery.sizeOf(context);
    final w = min(size.width, 600.0) - 28;
    final s = (w / 380).clamp(0.82, 1.4).toDouble();
    return Scaffold(
      backgroundColor: KidColors.sky,
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset(KidAssets.valleyBg, fit: BoxFit.cover)),
          SafeArea(
            child: Center(
              child: SizedBox(
                width: w + 28,
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(14, 6 * s, 14, 4 * s),
                      child: Row(children: [
                        KidBackButton(size: 52 * s, onTap: () {
                          _audio.playEventSound('cancelButton');
                          Navigator.maybePop(context);
                        }),
                        SizedBox(width: 12 * s),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(_t('title'), style: kidTitleStyle(36 * s, color: _ink)),
                          ),
                        ),
                      ]),
                    ),
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                        children: [
                          _preview(s, xp),
                          SizedBox(height: 12 * s),
                          _tabs(s),
                          SizedBox(height: 10 * s),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: KeyedSubtree(
                              key: ValueKey(_tab),
                              child: switch (_tab) {
                                0 => _avatarPanel(s, xp),
                                1 => _bannerPanel(s, xp),
                                _ => _framePanel(s, xp),
                              },
                            ),
                          ),
                          SizedBox(height: 10 * s),
                          _titleRow(s, xp),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                      child: Column(children: [
                        KidButton(label: _t('save'), width: double.infinity, height: 54 * s, showArrow: false, onPressed: _save),
                        SizedBox(height: 8 * s),
                        KidOutlineButton(
                          label: tr(context).cancel,
                          height: 48 * s,
                          onTap: () {
                            _audio.playEventSound('cancelButton');
                            Navigator.pop(context);
                          },
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _card({Color color = _cream, double r = 26}) => BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [BoxShadow(color: KidColors.purpleDeep.withOpacity(0.15), blurRadius: 14, offset: const Offset(0, 6))],
      );

  Widget _preview(double s, ExperienceManager xp) {
    final name = xp.userProfile.fullName.trim();
    final shown = (name.isEmpty || name == 'Player') ? tr(context).homeHiNoName : name.split(' ').first;
    final tier = _title >= 0 && _title <= ProfileTitleStore.tierFor(xp.level) ? _title : ProfileTitleStore.tierFor(xp.level);
    final bannerH = 150 * s, av = 122 * s;
    return SizedBox(
      height: bannerH + 96 * s,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            height: bannerH,
            decoration: _card(r: 28 * s),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25 * s),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: Image.asset(_banner, key: ValueKey(_banner), fit: BoxFit.cover, width: double.infinity, height: bannerH),
              ),
            ),
          ),
          Positioned(
            top: bannerH - 30 * s,
            child: Container(
              width: 230 * s,
              padding: EdgeInsets.fromLTRB(12 * s, 46 * s, 12 * s, 10 * s),
              decoration: _card(r: 26 * s),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(shown, maxLines: 1, style: kidBodyStyle(28 * s, color: _ink, weight: FontWeight.w700)),
                ),
                SizedBox(height: 4 * s),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 3 * s),
                  decoration: BoxDecoration(color: _lavender, borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.auto_awesome_rounded, color: const Color(0xFFFFC21A), size: 16 * s),
                    SizedBox(width: 4 * s),
                    Flexible(
                      child: Text(titleName(context, tier),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: kidBodyStyle(14 * s, color: KidColors.purpleDeep, weight: FontWeight.w700)),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
          Positioned(
            top: bannerH - av * 0.78,
            child: AnimatedBuilder(
              animation: _idle,
              builder: (_, c) => Transform.translate(offset: Offset(0, sin(_idle.value * 2 * pi) * 3 * s), child: c),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                child: FramedAvatar(key: ValueKey('$_avatar$_frame'), avatar: _avatar, frame: _frame, size: av),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabs(double s) {
    Widget tab(int i, String icon, String label) {
      final on = _tab == i;
      return Expanded(
        child: KidPressable(
          onTap: () {
            if (on) return;
            _audio.playEventSound('toggleButton');
            setState(() => _tab = i);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 54 * s,
            margin: EdgeInsets.symmetric(horizontal: 3 * s),
            padding: EdgeInsets.symmetric(horizontal: 6 * s),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: on ? null : _cream,
              gradient: on
                  ? const LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8B5BFF), Color(0xFF5B21C9)])
                  : null,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [BoxShadow(color: KidColors.purpleDeep.withOpacity(on ? 0.35 : 0.12), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 34 * s,
                height: 34 * s,
                padding: EdgeInsets.all(3 * s),
                decoration: on ? const BoxDecoration(shape: BoxShape.circle, color: Colors.white) : null,
                child: Image.asset(icon, fit: BoxFit.contain),
              ),
              SizedBox(width: 6 * s),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label, style: kidBodyStyle(17 * s, color: on ? Colors.white : _ink, weight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ),
      );
    }

    return Row(children: [
      tab(0, _CustAssets.tabAvatar, _t('avatars')),
      tab(1, _CustAssets.tabBanner, _t('banners')),
      tab(2, _CustAssets.tabFrame, _t('frames')),
    ]);
  }

  Widget _panel(double s, String title, String sub, List<Widget> children) {
    return Container(
      padding: EdgeInsets.fromLTRB(14 * s, 12 * s, 14 * s, 14 * s),
      decoration: _card(color: _cream.withOpacity(0.96), r: 28 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: kidBodyStyle(24 * s, color: _ink, weight: FontWeight.w700)),
          Text(sub, style: kidBodyStyle(15 * s, color: const Color(0xFF6D3FE0), weight: FontWeight.w600)),
          SizedBox(height: 10 * s),
          ...children,
        ],
      ),
    );
  }

  static const _pastels = [
    Color(0xFFDFF7FC), Color(0xFFFFF4D9), Color(0xFFE3ECFF), Color(0xFFE4F6E2), Color(0xFFFBE6F5), Color(0xFFEDE6FF),
  ];

  Widget _avatarPanel(double s, ExperienceManager xp) {
    bool owned(String a) => xp.unlockedAvatars.contains(a) || AvatarCatalog.isStarter(a);
    final list = AvatarCatalog.all.where((a) {
      if (_avatarFilter == 1) return !_animals.contains(a);
      if (_avatarFilter == 2) return _animals.contains(a);
      return true;
    }).toList()
      ..sort((a, b) => (owned(b) ? 1 : 0).compareTo(owned(a) ? 1 : 0));
    Widget chip(int i, String label) {
      final on = _avatarFilter == i;
      return Padding(
        padding: EdgeInsetsDirectional.only(end: 8 * s),
        child: KidPressable(
          onTap: () => _pick(() => _avatarFilter = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 7 * s),
            decoration: BoxDecoration(
              color: on ? KidColors.purple : _lavender,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(label, style: kidBodyStyle(15 * s, color: on ? Colors.white : const Color(0xFF4A2B91), weight: FontWeight.w700)),
          ),
        ),
      );
    }

    return _panel(s, _t('chooseAvatar'), _t('chooseAvatarSub'), [
      Row(children: [chip(0, _t('all')), chip(1, _t('characters')), chip(2, _t('animals'))]),
      SizedBox(height: 12 * s),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10 * s,
          crossAxisSpacing: 10 * s,
          childAspectRatio: 0.95,
        ),
        itemBuilder: (_, i) {
          final a = list[i];
          final on = a == _avatar;
          final open = owned(a);
          return KidPressable(
            onTap: () => open ? _pick(() => _avatar = a) : _buyAvatar(a, AvatarCatalog.costOf(a)),
            semanticLabel: _t('chooseAvatar'),
            child: _SelectableCard(
              color: _pastels[AvatarCatalog.all.indexOf(a) % _pastels.length],
              selected: on,
              equippedLabel: _t('equipped'),
              scale: s,
              child: Padding(
                padding: EdgeInsets.all(8 * s),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: on ? _cyan : Colors.white, width: on ? 4 : 3),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 3))],
                  ),
                  child: ClipOval(
                    child: Stack(fit: StackFit.expand, children: [
                      open
                          ? Image.asset(a, fit: BoxFit.cover)
                          : ColorFiltered(
                              colorFilter: const ColorFilter.matrix(<double>[
                                0.3, 0.5, 0.1, 0, 20, //
                                0.3, 0.5, 0.1, 0, 20,
                                0.3, 0.5, 0.1, 0, 20,
                                0, 0, 0, 1, 0,
                              ]),
                              child: Image.asset(a, fit: BoxFit.cover),
                            ),
                      if (!open)
                        Align(
                          alignment: const Alignment(0, 0.75),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 7 * s, vertical: 2 * s),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.lock_rounded, color: KidColors.purple, size: 14 * s),
                              SizedBox(width: 2 * s),
                              Image.asset(_CustAssets.gem, width: 14 * s, height: 14 * s),
                              Text('${AvatarCatalog.costOf(a)}', style: kidBodyStyle(12 * s, color: _ink, weight: FontWeight.w700)),
                            ]),
                          ),
                        ),
                    ]),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ]);
  }

  Widget _bannerPanel(double s, ExperienceManager xp) {
    final costs = {for (final b in BannerCatalog.shop) b['image'] as String: b['cost'] as int};
    final list = [...BannerCatalog.all]
      ..sort((a, b) => (xp.unlockedBanners.contains(b) ? 1 : 0).compareTo(xp.unlockedBanners.contains(a) ? 1 : 0));
    return _panel(s, _t('chooseBanner'), _t('chooseBannerSub'), [
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10 * s,
          crossAxisSpacing: 10 * s,
          childAspectRatio: 2.3,
        ),
        itemBuilder: (_, i) {
          final b = list[i];
          final open = xp.unlockedBanners.contains(b) || (costs[b] ?? 0) == 0;
          final on = b == _banner;
          return KidPressable(
            onTap: () {
              if (open) {
                if (!xp.unlockedBanners.contains(b)) xp.unlockBanner(b);
                _pick(() => _banner = b);
              } else {
                _buyBanner(b, costs[b] ?? 0);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18 * s),
                border: Border.all(color: on ? _cyan : Colors.white, width: on ? 4 : 2.5),
                boxShadow: [
                  BoxShadow(
                    color: on ? _cyan.withOpacity(0.55) : Colors.black.withOpacity(0.12),
                    blurRadius: on ? 12 : 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15 * s),
                child: Stack(fit: StackFit.expand, children: [
                  Image.asset(b, fit: BoxFit.cover),
                  if (!open) ...[
                    ColoredBox(color: const Color(0xFF2A1366).withOpacity(0.35)),
                    Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 4 * s),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.lock_rounded, color: KidColors.purple, size: 16 * s),
                          SizedBox(width: 4 * s),
                          Image.asset(_CustAssets.gem, width: 18 * s, height: 18 * s),
                          SizedBox(width: 2 * s),
                          Text('${costs[b]}', style: kidBodyStyle(14 * s, color: _ink, weight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                  ],
                  if (on)
                    PositionedDirectional(
                      start: 6 * s,
                      bottom: 6 * s,
                      child: _EquippedPill(label: _t('equipped'), scale: s),
                    ),
                ]),
              ),
            ),
          );
        },
      ),
    ]);
  }

  Widget _framePanel(double s, ExperienceManager xp) {
    final level = xp.level;
    final bought = xp.unlockedAvatarFrames;
    bool owned(AvatarFrame? f) => f == null || AvatarFrames.owned(f, level, bought);
    final entries = <AvatarFrame?>[null, ...AvatarFrames.all].where((f) {
      if (_frameFilter == 1) return owned(f);
      if (_frameFilter == 2) return !owned(f);
      return true;
    }).toList();
    Widget chip(int i, String label) {
      final on = _frameFilter == i;
      return Padding(
        padding: EdgeInsetsDirectional.only(end: 8 * s),
        child: KidPressable(
          onTap: () => _pick(() => _frameFilter = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 7 * s),
            decoration: BoxDecoration(color: on ? KidColors.purple : _lavender, borderRadius: BorderRadius.circular(30)),
            child: Text(label, style: kidBodyStyle(15 * s, color: on ? Colors.white : const Color(0xFF4A2B91), weight: FontWeight.w700)),
          ),
        ),
      );
    }

    return _panel(s, _t('chooseFrame'), _t('chooseFrameSub'), [
      Row(children: [chip(0, _t('all')), chip(1, _t('owned')), chip(2, _t('locked'))]),
      SizedBox(height: 12 * s),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: entries.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10 * s,
          crossAxisSpacing: 10 * s,
          childAspectRatio: 0.92,
        ),
        itemBuilder: (_, i) {
          final f = entries[i];
          final id = f?.id ?? AvatarFrames.none;
          final open = owned(f);
          final on = id == _frame;
          return KidPressable(
            onTap: () {
              if (open) {
                _pick(() => _frame = id);
              } else if (f!.gems > 0) {
                _buyFrame(f);
              } else {
                _snack(_t('reachLevel', {'n': f.level}));
              }
            },
            child: _SelectableCard(
              color: _pastels[i % _pastels.length],
              selected: on,
              equippedLabel: _t('equipped'),
              scale: s,
              child: Stack(alignment: Alignment.center, children: [
                Opacity(
                  opacity: open ? 1 : 0.6,
                  child: Center(child: FramedAvatar(avatar: _avatar, frame: id, size: 84 * s)),
                ),
                if (!open)
                  Positioned(
                    bottom: 6 * s,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 9 * s, vertical: 3 * s),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 4)],
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.lock_rounded, color: KidColors.purple, size: 15 * s),
                        SizedBox(width: 3 * s),
                        if (f!.gems > 0) ...[
                          Image.asset(_CustAssets.gem, width: 16 * s, height: 16 * s),
                          SizedBox(width: 2 * s),
                          Text('${f.gems}', style: kidBodyStyle(13 * s, color: _ink, weight: FontWeight.w700)),
                        ] else
                          Text(_t('levelShort', {'n': f.level}), style: kidBodyStyle(13 * s, color: _ink, weight: FontWeight.w700)),
                      ]),
                    ),
                  ),
              ]),
            ),
          );
        },
      ),
    ]);
  }

  Widget _titleRow(double s, ExperienceManager xp) {
    final tier = _title >= 0 && _title <= ProfileTitleStore.tierFor(xp.level) ? _title : ProfileTitleStore.tierFor(xp.level);
    return Container(
      padding: EdgeInsets.fromLTRB(16 * s, 8 * s, 8 * s, 8 * s),
      decoration: _card(r: 30),
      child: Row(children: [
        Expanded(child: Text(_t('profileTitle'), style: kidBodyStyle(18 * s, color: _ink, weight: FontWeight.w700))),
        KidPressable(
          onTap: _pickTitle,
          child: Container(
            constraints: BoxConstraints(maxWidth: 220 * s),
            padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 8 * s),
            decoration: BoxDecoration(color: _lavender, borderRadius: BorderRadius.circular(24)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.auto_awesome_rounded, color: const Color(0xFFFFC21A), size: 20 * s),
              SizedBox(width: 6 * s),
              Flexible(
                child: Text(titleName(context, tier),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: kidBodyStyle(15 * s, color: KidColors.purpleDeep, weight: FontWeight.w700)),
              ),
              Transform.flip(
                flipX: Directionality.of(context) == TextDirection.rtl,
                child: Icon(Icons.chevron_right_rounded, color: KidColors.purple, size: 24 * s),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _SelectableCard extends StatelessWidget {
  final Color color;
  final bool selected;
  final String equippedLabel;
  final double scale;
  final Widget child;
  const _SelectableCard({
    required this.color,
    required this.selected,
    required this.equippedLabel,
    required this.scale,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20 * s),
        border: Border.all(color: selected ? _cyan : Colors.white, width: selected ? 3 : 2),
        boxShadow: selected ? [BoxShadow(color: _cyan.withOpacity(0.45), blurRadius: 12)] : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: child),
          if (selected) ...[
            PositionedDirectional(
              top: 4 * s,
              end: 4 * s,
              child: Container(
                width: 28 * s,
                height: 28 * s,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _cyan,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: Icon(Icons.check_rounded, color: Colors.white, size: 18 * s),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 4 * s,
              child: Center(child: _EquippedPill(label: equippedLabel, scale: s)),
            ),
          ],
        ],
      ),
    );
  }
}

class _EquippedPill extends StatelessWidget {
  final String label;
  final double scale;
  const _EquippedPill({required this.label, required this.scale});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 3 * s),
      decoration: BoxDecoration(
        color: const Color(0xFF17AFC4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_rounded, color: Colors.white, size: 14 * s),
        SizedBox(width: 3 * s),
        Text(label, style: kidBodyStyle(12.5 * s, color: Colors.white, weight: FontWeight.w700)),
      ]),
    );
  }
}

/// Profile title name for a tier (0..4).
String titleName(BuildContext context, int tier) {
  final t = tr(context);
  return switch (tier) {
    0 => t.titleLittleLearner,
    1 => t.titleCuriousExplorer,
    2 => t.titleBrightThinker,
    3 => t.titleStarScholar,
    _ => t.titleKnowledgeHero,
  };
}

String custT(BuildContext context, String key, [Map<String, Object>? args]) {
  final code = Localizations.localeOf(context).languageCode;
  final lang = _cust.containsKey(code) ? code : (code == 'zgh' ? 'fr' : 'en');
  var s = _cust[lang]![key] ?? _cust['en']![key] ?? key;
  args?.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
  return s;
}

const Map<String, Map<String, String>> _cust = {
  'en': {
    'frameUnlocked': 'New frame unlocked!',
    'owned': 'Owned',
    'locked': 'Locked',
    'unlockFrame': 'Unlock this frame?',
    'title': 'Customize',
    'avatars': 'Avatars',
    'banners': 'Banners',
    'frames': 'Frames',
    'chooseAvatar': 'Choose your avatar',
    'chooseAvatarSub': 'Who will join your adventure?',
    'chooseBanner': 'Choose your banner',
    'chooseBannerSub': 'Pick a world that feels like you',
    'chooseFrame': 'Choose your frame',
    'chooseFrameSub': 'Make your picture shine',
    'all': 'All',
    'characters': 'Characters',
    'animals': 'Animals',
    'equipped': 'Equipped',
    'profileTitle': 'Profile title',
    'autoTitle': 'Follow my level',
    'save': 'Save look',
    'saved': 'Your new look is saved!',
    'reachLevel': 'Reach level {n} to unlock this!',
    'levelShort': 'Lv {n}',
    'unlockTitle': 'Unlock this banner?',
    'notEnoughGems': 'Not enough gems yet!',
  },
  'fr': {
    'frameUnlocked': 'Nouveau cadre débloqué !',
    'owned': 'À moi',
    'locked': 'Verrouillés',
    'unlockFrame': 'Débloquer ce cadre ?',
    'title': 'Personnaliser',
    'avatars': 'Avatars',
    'banners': 'Bannières',
    'frames': 'Cadres',
    'chooseAvatar': 'Choisis ton avatar',
    'chooseAvatarSub': 'Qui va t\'accompagner dans l\'aventure ?',
    'chooseBanner': 'Choisis ta bannière',
    'chooseBannerSub': 'Choisis un monde qui te ressemble',
    'chooseFrame': 'Choisis ton cadre',
    'chooseFrameSub': 'Fais briller ta photo',
    'all': 'Tous',
    'characters': 'Personnages',
    'animals': 'Animaux',
    'equipped': 'Équipé',
    'profileTitle': 'Titre du profil',
    'autoTitle': 'Suivre mon niveau',
    'save': 'Enregistrer',
    'saved': 'Ton nouveau look est enregistré !',
    'reachLevel': 'Atteins le niveau {n} pour le débloquer !',
    'levelShort': 'Niv {n}',
    'unlockTitle': 'Débloquer cette bannière ?',
    'notEnoughGems': 'Pas encore assez de gemmes !',
  },
  'ar': {
    'frameUnlocked': 'إطار جديد مفتوح!',
    'owned': 'أملكها',
    'locked': 'مقفلة',
    'unlockFrame': 'فتح هذا الإطار؟',
    'title': 'تخصيص',
    'avatars': 'الشخصيات',
    'banners': 'الخلفيات',
    'frames': 'الإطارات',
    'chooseAvatar': 'اختر شخصيتك',
    'chooseAvatarSub': 'من سيرافقك في المغامرة؟',
    'chooseBanner': 'اختر خلفيتك',
    'chooseBannerSub': 'اختر عالماً يشبهك',
    'chooseFrame': 'اختر إطارك',
    'chooseFrameSub': 'اجعل صورتك تلمع',
    'all': 'الكل',
    'characters': 'شخصيات',
    'animals': 'حيوانات',
    'equipped': 'مُفعّل',
    'profileTitle': 'لقب الملف',
    'autoTitle': 'حسب مستواي',
    'save': 'حفظ المظهر',
    'saved': 'تم حفظ مظهرك الجديد!',
    'reachLevel': 'صل إلى المستوى {n} لفتحه!',
    'levelShort': 'مستوى {n}',
    'unlockTitle': 'فتح هذه الخلفية؟',
    'notEnoughGems': 'لا توجد جواهر كافية بعد!',
  },
  'de': {
    'frameUnlocked': 'Neuer Rahmen freigeschaltet!',
    'owned': 'Meine',
    'locked': 'Gesperrt',
    'unlockFrame': 'Diesen Rahmen freischalten?',
    'title': 'Anpassen',
    'avatars': 'Avatare',
    'banners': 'Banner',
    'frames': 'Rahmen',
    'chooseAvatar': 'Wähle deinen Avatar',
    'chooseAvatarSub': 'Wer begleitet dich auf dem Abenteuer?',
    'chooseBanner': 'Wähle dein Banner',
    'chooseBannerSub': 'Such dir eine Welt aus, die zu dir passt',
    'chooseFrame': 'Wähle deinen Rahmen',
    'chooseFrameSub': 'Lass dein Bild strahlen',
    'all': 'Alle',
    'characters': 'Figuren',
    'animals': 'Tiere',
    'equipped': 'Aktiv',
    'profileTitle': 'Profiltitel',
    'autoTitle': 'Nach meinem Level',
    'save': 'Look speichern',
    'saved': 'Dein neuer Look ist gespeichert!',
    'reachLevel': 'Erreiche Level {n}, um das freizuschalten!',
    'levelShort': 'Lv {n}',
    'unlockTitle': 'Dieses Banner freischalten?',
    'notEnoughGems': 'Noch nicht genug Edelsteine!',
  },
};
