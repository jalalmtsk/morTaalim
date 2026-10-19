import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/widgets/KidScene/kid_form.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:provider/provider.dart';

import '../../XpSystem.dart';
import '../../tools/audio_tool/Audio_Manager.dart';
import '../data/morocco_cities.dart';

/// Onboarding — "Where are you from?".
/// Morocco gets a searchable picker with every city, grouped by region.
class CityCountryPage extends StatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;

  const CityCountryPage({Key? key, this.onNext, this.onBack}) : super(key: key);

  @override
  State<CityCountryPage> createState() => _CityCountryPageState();
}

class _CityCountryPageState extends State<CityCountryPage> with TickerProviderStateMixin {
  KidCountry? _country = kidCountries.first; // Morocco by default
  String? _city; // stored value (Latin name for Moroccan cities)
  bool _precached = false;

  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1700));
  late final AnimationController _idle =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  late final AnimationController _jump =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  late final AnimationController _pinDrop =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

  static const List<String> _assets = [
    KidAssets.valleyBg,
    KidAssets.wordmark,
    KidAssets.backBtn,
    KidAssets.mascotGlobe,
    KidAssets.island,
    KidAssets.pinOrange,
    KidAssets.exclaim,
    KidAssets.icPinPurple,
    KidAssets.flagMa,
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
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
    final c = kidCountryFromStored(user.country);
    if (c != null) _country = c;
    if (user.city.trim().isNotEmpty) {
      final mc = _country?.code == 'MA' ? maCityFromStored(user.city) : null;
      _city = mc?.fr ?? user.city.trim();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _idle.dispose();
    _jump.dispose();
    _pinDrop.dispose();
    super.dispose();
  }

  String get _lang => Localizations.localeOf(context).languageCode;

  String? get _cityDisplay {
    if (_city == null) return null;
    if (_country?.code == 'MA') {
      final mc = maCityFromStored(_city!);
      if (mc != null) return mc.display(_lang);
    }
    return _city;
  }

  Future<void> _pickCountry() async {
    final am = Provider.of<AudioManager>(context, listen: false);
    am.playEventSound('PopButton');
    final picked = await showKidOptionSheet<KidCountry>(
      context: context,
      title: tr(context).chooseCountry,
      options: kidCountries,
      selected: _country,
      label: (c) => c.display(_lang),
      leading: (c) => c.code == 'MA'
          ? Image.asset(KidAssets.flagMa, width: 30, height: 30)
          : Text(c.flag, style: const TextStyle(fontSize: 26)),
    );
    if (picked == null || !mounted) return;
    am.playEventSound('clickButton2');
    setState(() {
      if (picked.code != _country?.code) _city = null;
      _country = picked;
    });
  }

  Future<void> _pickCity() async {
    final am = Provider.of<AudioManager>(context, listen: false);
    am.playEventSound('PopButton');
    final String? picked = _country?.code == 'MA'
        ? await showModalBottomSheet<String>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _MoroccoCitySheet(selected: _city, lang: _lang),
          )
        : await showModalBottomSheet<String>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _TypeCitySheet(initial: _city),
          );
    if (picked == null || picked.trim().isEmpty || !mounted) return;
    am.playEventSound('clickButton2');
    setState(() => _city = picked.trim());
    _pinDrop.forward(from: 0);
  }

  bool get _isValid => _country != null && (_city?.isNotEmpty ?? false);

  void _save() {
    final em = Provider.of<ExperienceManager>(context, listen: false);
    em.setCity(_city!.trim());
    em.setCountry(_country!.en);
  }

  void _continue() {
    if (!_isValid) return;
    Provider.of<AudioManager>(context, listen: false).playEventSound('clickButton');
    _save();
    widget.onNext?.call();
  }

  void _skip() {
    Provider.of<AudioManager>(context, listen: false).playEventSound('clickButton');
    widget.onNext?.call();
  }

  void _onMascotTap() {
    if (_jump.isAnimating) return;
    Provider.of<AudioManager>(context, listen: false).playEventSound('PopButton');
    _jump.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final g = KidSceneGeometry(size);
    final headerShift = max(0.0, pad.top + 6 - g.y(48));
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final fieldH = g.lc(125, 50, 66);
    final labelSize = g.lc(34, 14, 19);
    final buttonH = g.lc(136, 52, 72);
    final buttonTop = min(g.y(1408), size.height - pad.bottom - buttonH - 52);
    final formW = g.contentWidth(770, pad: 18);

    SceneSprite sprite(String asset, double l, double t, double w, double aspect,
            {double from = 0.2,
            double to = 0.7,
            double bob = 0,
            double rot = 0,
            double phase = 0,
            int speed = 1,
            bool twinkle = false,
            Animation<double>? jump,
            VoidCallback? onTap}) =>
        SceneSprite(
          g: g,
          asset: asset,
          left: l,
          top: t,
          width: w,
          aspect: aspect,
          idle: _idle,
          intro: _intro,
          introFrom: from,
          introTo: to,
          bob: bob,
          rot: rot,
          phase: phase,
          speed: speed,
          twinkle: twinkle,
          jump: jump,
          onTap: onTap,
        );

    return Scaffold(
      backgroundColor: KidColors.sky,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          KidSceneBackground(asset: KidAssets.valleyBg, g: g),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Stack(
              children: [
                sprite(KidAssets.island, 140, 760, 705, 0.382, from: 0.1, to: 0.55, bob: 6, phase: 0.5),
                sprite(KidAssets.mascotGlobe, 258, 362, 440, 1.2256,
                    from: 0.2, to: 0.65, bob: 6, rot: 0.015, phase: 0.5, jump: _jump, onTap: _onMascotTap),
                sprite(KidAssets.exclaim, 610, 505, 84, 1.0157,
                    from: 0.55, to: 0.95, bob: 5, rot: 0.08, phase: 0.2, speed: 2),
                // Map pin: bobs, and re-drops each time a city is picked.
                AnimatedBuilder(
                  animation: _pinDrop,
                  builder: (_, __) {
                    final p = _pinDrop.value;
                    final drop = p == 0 ? 0.0 : (1 - Curves.bounceOut.transform(p)) * 120;
                    return Positioned.fill(
                      child: Transform.translate(
                        offset: Offset(0, -g.l(drop)),
                        child: Stack(children: [
                          sprite(KidAssets.pinOrange, 668, 578, 100, 1.2866,
                              from: 0.5, to: 0.9, bob: 12, rot: 0.06, phase: 0.1, speed: 2),
                        ]),
                      ),
                    );
                  },
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: headerShift,
                  height: g.y(200),
                  child: Stack(children: [
                    sprite(KidAssets.wordmark, 272, 62, 398, 0.2289, from: 0, to: 0.45, bob: 4),
                  ]),
                ),
              ],
            ),
          ),

          // Title
          Positioned(
            left: g.visibleLeft + 16,
            width: g.visibleWidth - 32,
            top: g.y(168) + headerShift * 0.5,
            height: g.l(215),
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
                      child: Text(tr(context).whereFromTitle,
                          textAlign: TextAlign.center, style: kidTitleStyle(g.lc(84, 26, 46))),
                    ),
                  ),
                  SizedBox(height: g.l(6)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(tr(context).whereFromSubtitle,
                        style: kidBodyStyle(g.lc(34, 14, 19),
                            color: KidColors.ink, weight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),

          // Fields
          Positioned(
            left: (size.width - formW) / 2,
            width: formW,
            top: min(g.y(985), buttonTop - fieldH * 2 - labelSize * 2.6 - 56),
            child: KidIntro(
              intro: _intro,
              from: 0.4,
              to: 0.9,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  KidFieldLabel(tr(context).country, size: labelSize),
                  KidSelectField(
                    height: fieldH,
                    leading: _country?.code == 'MA'
                        ? Image.asset(KidAssets.flagMa)
                        : (_country == null
                            ? const Icon(Icons.public_rounded, color: KidColors.purple)
                            : FittedBox(child: Text(_country!.flag, style: const TextStyle(fontSize: 40)))),
                    value: _country?.display(_lang),
                    hint: tr(context).chooseCountry,
                    onTap: _pickCountry,
                  ),
                  SizedBox(height: g.l(16)),
                  KidFieldLabel(tr(context).city, size: labelSize),
                  KidSelectField(
                    height: fieldH,
                    leading: Image.asset(KidAssets.icPinPurple),
                    value: _cityDisplay,
                    hint: tr(context).chooseCity,
                    onTap: _country == null ? null : _pickCity,
                  ),
                ],
              ),
            ),
          ),

          // Skip + Continue
          Positioned(
            left: 0,
            right: 0,
            top: buttonTop - g.lc(52, 30, 40),
            child: KidIntro(
              intro: _intro,
              from: 0.6,
              to: 1.0,
              child: Column(
                children: [
                  KidLink(text: tr(context).skipForNow, onTap: _skip, size: g.lc(28, 12, 15)),
                  SizedBox(height: g.l(6)),
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
                    widget.onBack!.call();
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Searchable list of every Moroccan city, grouped by region.
class _MoroccoCitySheet extends StatefulWidget {
  final String? selected;
  final String lang;
  const _MoroccoCitySheet({required this.selected, required this.lang});

  @override
  State<_MoroccoCitySheet> createState() => _MoroccoCitySheetState();
}

class _MoroccoCitySheetState extends State<_MoroccoCitySheet> {
  final _search = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool get _ar => widget.lang == 'ar';

  @override
  Widget build(BuildContext context) {
    final key = maSearchKey(_q);
    final results = key.isEmpty
        ? const <MaCity>[]
        : (maCities
                .where((c) => maSearchKey(c.fr).contains(key) || maSearchKey(c.ar).contains(key))
                .toList()
              ..sort((a, b) {
                final aStarts = maSearchKey(a.fr).startsWith(key) || maSearchKey(a.ar).startsWith(key);
                final bStarts = maSearchKey(b.fr).startsWith(key) || maSearchKey(b.ar).startsWith(key);
                if (aStarts != bStarts) return aStarts ? -1 : 1;
                return a.fr.compareTo(b.fr);
              }));

    final children = <Widget>[];
    if (key.isEmpty) {
      // Popular chips
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        child: Text(tr(context).popularCities,
            style: kidBodyStyle(15, color: KidColors.muted, weight: FontWeight.w700)),
      ));
      children.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final name in maPopularCities)
              _CityChip(
                label: maCityFromStored(name)?.display(widget.lang) ?? name,
                selected: widget.selected == name,
                onTap: () => Navigator.of(context).pop(name),
              ),
          ],
        ),
      ));
      // Grouped by region
      for (int r = 0; r < maRegions.length; r++) {
        final cities = maCities.where((c) => c.region == r).toList()
          ..sort((a, b) => _ar ? a.ar.compareTo(b.ar) : a.fr.compareTo(b.fr));
        children.add(Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: KidColors.orange, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_ar ? maRegions[r].ar : maRegions[r].fr,
                    style: kidBodyStyle(15, color: KidColors.purpleDeep, weight: FontWeight.w700)),
              ),
            ],
          ),
        ));
        for (final c in cities) {
          children.add(KidOptionTile(
            label: c.display(widget.lang),
            subLabel: _ar ? c.fr : c.ar,
            selected: widget.selected == c.fr,
            onTap: () => Navigator.of(context).pop(c.fr),
          ));
        }
      }
    } else {
      for (final c in results) {
        children.add(KidOptionTile(
          label: c.display(widget.lang),
          subLabel: '${_ar ? c.fr : c.ar} · ${_ar ? maRegions[c.region].ar : maRegions[c.region].fr}',
          selected: widget.selected == c.fr,
          onTap: () => Navigator.of(context).pop(c.fr),
        ));
      }
      if (results.isEmpty) {
        children.add(KidOptionTile(
          label: _q.trim(),
          subLabel: tr(context).noCityFound,
          leading: const Icon(Icons.edit_location_alt_rounded, color: KidColors.purple),
          selected: false,
          onTap: () => Navigator.of(context).pop(_q.trim()),
        ));
      }
    }

    return KidSheetFrame(
      title: tr(context).chooseCity,
      maxHeightFactor: 0.88,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _SearchBox(
              controller: _search,
              hint: tr(context).searchCity,
              onChanged: (v) => setState(() => _q = v),
            ),
          ),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  const _SearchBox({required this.controller, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: KidColors.purple, width: 2.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: KidColors.purple, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              cursorColor: KidColors.purple,
              textInputAction: TextInputAction.search,
              style: kidBodyStyle(17, color: KidColors.ink, weight: FontWeight.w600),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: kidBodyStyle(17, color: const Color(0xFFA996D6), weight: FontWeight.w600),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                onChanged('');
              },
              child: const Icon(Icons.close_rounded, color: KidColors.muted),
            ),
        ],
      ),
    );
  }
}

class _CityChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CityChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return KidPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? KidColors.purple : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: selected ? KidColors.purple : KidColors.lavender, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on_rounded,
                size: 16, color: selected ? Colors.white : KidColors.orange),
            const SizedBox(width: 4),
            Text(label,
                style: kidBodyStyle(15,
                    color: selected ? Colors.white : KidColors.ink, weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// Free text city entry for countries other than Morocco.
class _TypeCitySheet extends StatefulWidget {
  final String? initial;
  const _TypeCitySheet({this.initial});

  @override
  State<_TypeCitySheet> createState() => _TypeCitySheetState();
}

class _TypeCitySheetState extends State<_TypeCitySheet> {
  late final TextEditingController _c = TextEditingController(text: widget.initial ?? '');

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KidSheetFrame(
      title: tr(context).typeYourCity,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: KidColors.purple, width: 2.5),
              ),
              child: Row(
                children: [
                  Image.asset(KidAssets.icPinPurple, width: 24, height: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _c,
                      autofocus: true,
                      maxLength: 40,
                      textCapitalization: TextCapitalization.words,
                      cursorColor: KidColors.purple,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (v) {
                        if (v.trim().isNotEmpty) Navigator.of(context).pop(v.trim());
                      },
                      style: kidBodyStyle(18, color: KidColors.ink, weight: FontWeight.w600),
                      decoration: InputDecoration(
                        counterText: '',
                        isDense: true,
                        border: InputBorder.none,
                        hintText: tr(context).typeYourCity,
                        hintStyle:
                            kidBodyStyle(18, color: const Color(0xFFA996D6), weight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            KidButton(
              label: tr(context).continueLabel,
              width: double.infinity,
              height: 56,
              showArrow: false,
              onPressed: _c.text.trim().isEmpty ? null : () => Navigator.of(context).pop(_c.text.trim()),
            ),
          ],
        ),
      ),
    );
  }
}
