import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../XpSystem.dart';
import '../../tools/audio_tool/Audio_Manager.dart';

/// Onboarding — "What's your name?".
/// The mascot holds a sign that shows the name live while the child types.
class NameAgePage extends StatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;

  const NameAgePage({Key? key, this.onNext, this.onBack}) : super(key: key);

  @override
  State<NameAgePage> createState() => _NameAgePageState();
}

class _NameAgePageState extends State<NameAgePage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _lastNameFocus = FocusNode();

  bool _isFormValid = false;
  bool isMinor = true;
  bool _precached = false;

  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1700));
  late final AnimationController _idle =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  late final AnimationController _jump =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

  static const List<String> _assets = [
    KidAssets.valleyBg,
    KidAssets.wordmark,
    KidAssets.backBtn,
    KidAssets.mascotSign,
    KidAssets.island,
    KidAssets.star5Big,
    KidAssets.star5Small,
    KidAssets.exclaim,
    KidAssets.pencilYellow,
    KidAssets.icPencilPurple,
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _nameController.addListener(_validateForm);
    _lastNameController.addListener(_validateForm);
    _ageController.addListener(_validateForm);
    _nameFocus.addListener(() => setState(() {}));
    _lastNameFocus.addListener(() => setState(() {}));
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

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final experienceManager = Provider.of<ExperienceManager>(context, listen: false);

    final int savedAge = prefs.getInt('age') ?? experienceManager.userProfile.age;
    isMinor = savedAge < 18;
    _ageController.text = savedAge > 0 ? savedAge.toString() : "";
    _nameController.text = prefs.getString('name') ?? experienceManager.userProfile.fullName;
    if (!isMinor) {
      _lastNameController.text =
          prefs.getString('lastName') ?? experienceManager.userProfile.lastName;
    }
    _validateForm();
  }

  void _validateForm() {
    final nameValid = _nameController.text.trim().isNotEmpty;
    final ageValid = _ageController.text.trim().isNotEmpty;
    final lastNameValid = isMinor || _lastNameController.text.trim().isNotEmpty;
    final valid = nameValid && ageValid && lastNameValid;
    if (mounted) setState(() => _isFormValid = valid);
  }

  Future<bool> saveData() async {
    if (!(_formKey.currentState?.validate() ?? false)) return false;
    final age = int.tryParse(_ageController.text.trim());
    if (age == null) return false;

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return false;
    final experienceManager = Provider.of<ExperienceManager>(context, listen: false);

    final name = _nameController.text.trim();
    final lastName = isMinor ? "" : _lastNameController.text.trim();

    await prefs.setString('name', name);
    await prefs.setInt('age', age);
    await prefs.setString('lastName', lastName);

    experienceManager.setFullName(name);
    experienceManager.setAge(age);
    experienceManager.setLastName(lastName);
    return true;
  }

  Future<void> _continue() async {
    if (!_isFormValid) return;
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    audioManager.playEventSound('clickButton');
    FocusScope.of(context).unfocus();
    if (await saveData()) {
      widget.onNext?.call();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _nameFocus.dispose();
    _lastNameFocus.dispose();
    _intro.dispose();
    _idle.dispose();
    _jump.dispose();
    super.dispose();
  }

  void _onMascotTap() {
    if (_jump.isAnimating) return;
    Provider.of<AudioManager>(context, listen: false).playEventSound('PopButton');
    _jump.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    final mq = MediaQuery.of(context);
    final size = mq.size;
    final pad = mq.padding;
    final keyboard = mq.viewInsets.bottom;
    final g = KidSceneGeometry(size);
    final headerShift = max(0.0, pad.top + 6 - g.y(48));
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    // Field layout (design px): one field for kids, two for adults.
    final fieldH = isMinor ? g.lc(150, 54, 78) : g.lc(120, 48, 64);
    final labelTop = isMinor ? g.y(1046) : g.y(1000);
    final field1Top = labelTop + g.lc(52, 24, 32);
    final field2Top = field1Top + fieldH + g.l(22);
    final fieldsBottom = isMinor ? field1Top + fieldH : field2Top + fieldH;
    final buttonH = g.lc(140, 52, 74);
    final buttonTop = min(g.y(1385), size.height - pad.bottom - buttonH - 56);

    // Lift the foreground above the keyboard so the field stays visible.
    final lift = keyboard <= 0
        ? 0.0
        : max(0.0, fieldsBottom + g.l(60) - (size.height - keyboard));

    final name = _nameController.text.trim();

    SceneSprite sprite(String asset, double l, double t, double w, double aspect,
            {double from = 0.2,
            double to = 0.7,
            double bob = 0,
            double rot = 0,
            double phase = 0,
            int speed = 1,
            bool twinkle = false,
            Widget? overlay,
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
          overlay: overlay,
          jump: jump,
          onTap: onTap,
        );

    // Name written on the mascot's sign (sign interior ≈ 22–78 % × 57–76 %).
    final signText = LayoutBuilder(builder: (context, c) {
      return Stack(children: [
        Positioned(
          left: c.maxWidth * 0.245,
          right: c.maxWidth * 0.235,
          top: c.maxHeight * 0.6,
          bottom: c.maxHeight * 0.232,
          child: Center(
            // The board is held at a slight angle — tilt the name with it
            // and add a touch of perspective so it looks written on the sign.
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015)
                ..rotateZ(-0.085)
                ..rotateY(0.04),
              child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
              child: FittedBox(
                key: ValueKey(name.isEmpty),
                fit: BoxFit.scaleDown,
                child: Text(
                  name.isEmpty ? '?' : name,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w700,
                    fontSize: c.maxHeight * 0.105,
                    color: name.isEmpty ? KidColors.lavender : KidColors.purpleDeep,
                  ),
                ),
              ),
            ),
            ),
          ),
        ),
      ]);
    });

    return Scaffold(
      backgroundColor: KidColors.sky,
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            KidSceneBackground(asset: KidAssets.valleyBg, g: g),
            TweenAnimationBuilder<double>(
              tween: Tween(end: lift),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              builder: (context, dy, child) =>
                  Transform.translate(offset: Offset(0, -dy), child: child),
              child: Stack(
                children: [
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Stack(
                      children: [
                        sprite(KidAssets.island, 128, 828, 718, 0.382,
                            from: 0.1, to: 0.55, bob: 6, phase: 0.5),
                        sprite(KidAssets.mascotSign, 266, 330, 432, 1.3495,
                            from: 0.2, to: 0.65, bob: 6, rot: 0.015, phase: 0.5,
                            overlay: signText, jump: _jump, onTap: _onMascotTap),
                        sprite(KidAssets.star5Big, 186, 578, 94, 1.0163,
                            from: 0.45, to: 0.85, twinkle: true, phase: 0.1, speed: 2),
                        sprite(KidAssets.star5Small, 238, 738, 48, 1.0667,
                            from: 0.5, to: 0.9, twinkle: true, phase: 0.6, speed: 3),
                        sprite(KidAssets.star5Small, 734, 684, 54, 1.0667,
                            from: 0.5, to: 0.9, twinkle: true, phase: 0.35, speed: 2),
                        sprite(KidAssets.exclaim, 626, 578, 70, 1.0157,
                            from: 0.55, to: 0.95, bob: 6, rot: 0.08, phase: 0.2, speed: 2),
                        sprite(KidAssets.pencilYellow, 676, 583, 100, 1.1761,
                            from: 0.5, to: 0.9, bob: 9, rot: 0.12, phase: 0.75),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: headerShift,
                          height: g.y(200),
                          child: Stack(children: [
                            sprite(KidAssets.wordmark, 272, 62, 398, 0.2289,
                                from: 0, to: 0.45, bob: 4),
                          ]),
                        ),
                      ],
                    ),
                  ),

                  // Title + subtitle
                  Positioned(
                    left: g.visibleLeft + 16,
                    width: g.visibleWidth - 32,
                    top: g.y(176) + headerShift * 0.5,
                    child: KidIntro(
                      intro: _intro,
                      from: 0.15,
                      to: 0.6,
                      child: Column(
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(tr(context).nameTitle,
                                maxLines: 1, style: kidTitleStyle(g.lc(80, 26, 44))),
                          ),
                          SizedBox(height: g.l(8)),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(tr(context).nameSubtitle,
                                maxLines: 1,
                                style: kidBodyStyle(g.lc(36, 14, 20),
                                    color: KidColors.ink, weight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Form
                  Positioned(
                    left: (size.width - g.contentWidth(782, pad: 18)) / 2,
                    width: g.contentWidth(782, pad: 18),
                    top: labelTop,
                    child: KidIntro(
                      intro: _intro,
                      from: 0.45,
                      to: 0.9,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsetsDirectional.only(start: fieldH * 0.22),
                              child: Text(
                                isMinor ? tr(context).nameLabel : tr(context).firstName,
                                style: kidBodyStyle(g.lc(34, 14, 19),
                                    color: KidColors.ink, weight: FontWeight.w700),
                              ),
                            ),
                            SizedBox(height: max(4.0, field1Top - labelTop - g.lc(34, 14, 19) * 1.2)),
                            _KidTextField(
                              controller: _nameController,
                              focusNode: _nameFocus,
                              height: fieldH,
                              hint: isMinor ? tr(context).nameHint : tr(context).firstName,
                              textInputAction: isMinor ? TextInputAction.done : TextInputAction.next,
                              onTap: () => audioManager.playEventSound('PopButton'),
                              onSubmitted: (_) =>
                                  isMinor ? _continue() : _lastNameFocus.requestFocus(),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? tr(context).pleaseEnterName
                                  : null,
                            ),
                            if (!isMinor) ...[
                              SizedBox(height: g.l(22)),
                              _KidTextField(
                                controller: _lastNameController,
                                focusNode: _lastNameFocus,
                                height: fieldH,
                                hint: tr(context).lastName,
                                textInputAction: TextInputAction.done,
                                onTap: () => audioManager.playEventSound('PopButton'),
                                onSubmitted: (_) => _continue(),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? tr(context).pleaseEnterYourLastName
                                    : null,
                              ),
                            ],
                            if (isMinor) ...[
                              SizedBox(height: g.l(16)),
                              SizedBox(
                                width: double.infinity,
                                child: Text(
                                  tr(context).nameHelper,
                                  textAlign: TextAlign.center,
                                  style: kidBodyStyle(g.lc(30, 12, 17), color: KidColors.ink),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Back
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

            // Continue (hidden behind the keyboard while typing; "done" submits)
            Positioned(
              left: 0,
              right: 0,
              top: buttonTop,
              child: KidIntro(
                intro: _intro,
                from: 0.6,
                to: 1.0,
                child: Center(
                  child: KidButton(
                    label: tr(context).continueLabel,
                    width: g.contentWidth(722, pad: 24),
                    height: buttonH,
                    onPressed: _isFormValid ? _continue : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KidTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final double height;
  final String hint;
  final TextInputAction textInputAction;
  final VoidCallback? onTap;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;

  const _KidTextField({
    required this.controller,
    required this.focusNode,
    required this.height,
    required this.hint,
    required this.textInputAction,
    this.onTap,
    this.onSubmitted,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final h = height;
    final focused = focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(h * 0.42),
        border: Border.all(color: focused ? KidColors.purple : const Color(0xFFB79CF5), width: focused ? 3.5 : 3),
        boxShadow: [
          BoxShadow(
            color: KidColors.purple.withOpacity(focused ? 0.3 : 0.16),
            blurRadius: focused ? 18 : 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: h * 0.3),
      child: Row(
        children: [
          Image.asset(KidAssets.icPencilPurple, width: h * 0.4, height: h * 0.4),
          SizedBox(width: h * 0.2),
          Container(width: 3, height: h * 0.42, color: KidColors.purple.withOpacity(0.8)),
          SizedBox(width: h * 0.16),
          Expanded(
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              onTap: onTap,
              onFieldSubmitted: onSubmitted,
              validator: validator,
              textInputAction: textInputAction,
              textCapitalization: TextCapitalization.words,
              maxLength: 20,
              inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[0-9@#\$%^&*()_+=<>/\\{}\[\]|~`]'))],
              cursorColor: KidColors.purple,
              cursorWidth: 2.5,
              style: kidBodyStyle(h * 0.27, color: KidColors.ink, weight: FontWeight.w600),
              decoration: InputDecoration(
                counterText: '',
                isDense: true,
                border: InputBorder.none,
                errorStyle: const TextStyle(height: 0, fontSize: 0),
                hintText: hint,
                hintStyle: kidBodyStyle(h * 0.27,
                    color: const Color(0xFFA996D6), weight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
