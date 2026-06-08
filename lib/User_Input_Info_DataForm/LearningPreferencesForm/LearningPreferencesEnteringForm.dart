import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Replace these imports with your actual paths ───────────────────────────
import '../../Manager/models/LearningPrefrences.dart';
import '../../l10n/app_localizations.dart';
import '../../tools/audio_tool/Audio_Manager.dart';
import '../../main.dart'; // for tr(context)
// ────────────────────────────────────────────────────────────────────────────

// ═══════════════════════════════════════════════════════════════════════════
//  THEME CONSTANTS  — Orange & Warm-Amber palette
// ═══════════════════════════════════════════════════════════════════════════
class _KidTheme {
  // Primary orange ramp
  static const orange       = Color(0xFFEA580C); // orange-600
  static const orangeLight  = Color(0xFFFFF7ED); // orange-50
  static const orangeMid    = Color(0xFFFDBA74); // orange-300
  static const orangeDark   = Color(0xFF9A3412); // orange-800

  // Accent warm yellow
  static const yellow       = Color(0xFFFEF08A); // yellow-200
  static const yellowDark   = Color(0xFF92400E); // amber-800

  // Complementary teal (symmetric / cool contrast)
  static const teal         = Color(0xFF0D9488); // teal-600
  static const tealLight    = Color(0xFFCCFBF1); // teal-100

  // Green for success / checkmark
  static const green        = Color(0xFF16A34A);
  static const greenLight   = Color(0xFFDCFCE7);

  // Neutrals
  static const white        = Color(0xFFFFFFFF);
  static const bgLight      = Color(0xFFFFF7ED); // warm orange tint

  // Dashed divider
  static const dashed       = Color(0xFFFED7AA); // orange-200

  // Gradient: orange → warm amber
  static const headerGradient = LinearGradient(
    colors: [Color(0xFFF97316), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Gradient: orange → teal (symmetric contrast)
  static const buttonGradient = LinearGradient(
    colors: [Color(0xFFEA580C), Color(0xFF0D9488)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static BorderRadius get cardRadius  => BorderRadius.circular(36);
  static BorderRadius get chipRadius  => BorderRadius.circular(22);
  static BorderRadius get inputRadius => BorderRadius.circular(18);
  static BorderRadius get btnRadius   => BorderRadius.circular(20);
}

// ═══════════════════════════════════════════════════════════════════════════
//  DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════
class _StepChoice {
  final String emoji;
  final String labelKey; // localization key suffix
  const _StepChoice(this.emoji, this.labelKey);
}

class _StepData {
  final String mascot;
  final String headerTitleKey;
  final String questionKey;
  final String hintKey;
  final List<_StepChoice> choices;
  final bool hasTextFields;

  const _StepData({
    required this.mascot,
    required this.headerTitleKey,
    required this.questionKey,
    required this.hintKey,
    required this.choices,
    this.hasTextFields = false,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
//  PAGE WIDGET
// ═══════════════════════════════════════════════════════════════════════════
class LearningPreferencesPages extends StatefulWidget {
  final LearningPreferences? initialPreferences;
  const LearningPreferencesPages({Key? key, this.initialPreferences})
      : super(key: key);

  @override
  State<LearningPreferencesPages> createState() =>
      _LearningPreferencesPagesState();
}

class _LearningPreferencesPagesState extends State<LearningPreferencesPages>
    with TickerProviderStateMixin {

  // ── State ────────────────────────────────────────────────────────────────
  int _currentStep = 0;
  bool _showCelebration = false;
  late LearningPreferences _prefs;

  final _weeklyGoalCtrl   = TextEditingController();
  final _longTermGoalCtrl = TextEditingController();

  // ── Animation controllers ────────────────────────────────────────────────
  late final AnimationController _mascotCtrl;
  late final AnimationController _pageCtrl;
  late final AnimationController _celebCtrl;
  late final Animation<double> _mascotBounce;
  late final Animation<Offset>  _pageSlide;
  late final Animation<double>  _celebScale;

  // ── Step definitions — keys resolved via tr(context) at build time ────────
  static const List<_StepData> _steps = [
    _StepData(
      mascot: '🦁',
      headerTitleKey: 'prefStep1Title',
      questionKey:    'prefStep1Question',
      hintKey:        'prefStep1Hint',
      choices: [
        _StepChoice('🔢', 'subjectMath'),
        _StepChoice('📖', 'subjectArabic'),
        _StepChoice('🌍', 'subjectEnglish'),
        _StepChoice('🥐', 'subjectFrench'),
        _StepChoice('🔬', 'subjectScience'),
        _StepChoice('🌙', 'subjectIslamicEd'),
        _StepChoice('🎨', 'subjectArt'),
      ],
    ),
    _StepData(
      mascot: '🦊',
      headerTitleKey: 'prefStep2Title',
      questionKey:    'prefStep2Question',
      hintKey:        'prefStep2Hint',
      choices: [
        _StepChoice('👀', 'styleVisual'),
        _StepChoice('👂', 'styleAudio'),
        _StepChoice('🤸', 'styleHandsOn'),
      ],
    ),
    _StepData(
      mascot: '🐨',
      headerTitleKey: 'prefStep3Title',
      questionKey:    'prefStep3Question',
      hintKey:        'prefStep3Hint',
      choices: [
        _StepChoice('🌅', 'timeMorning'),
        _StepChoice('☀️', 'timeAfternoon'),
        _StepChoice('🌙', 'timeEvening'),
      ],
    ),
    _StepData(
      mascot: '🐯',
      headerTitleKey: 'prefStep4Title',
      questionKey:    'prefStep4Question',
      hintKey:        'prefStep4Hint',
      choices: [
        _StepChoice('😊', 'difficultyEasy'),
        _StepChoice('🚀', 'difficultyChallenge'),
        _StepChoice('🤖', 'difficultyAdaptive'),
      ],
    ),
    _StepData(
      mascot: '🦋',
      headerTitleKey: 'prefStep5Title',
      questionKey:    'prefStep5Question',
      hintKey:        'prefStep5Hint',
      hasTextFields: true,
      choices: [
        _StepChoice('📝', 'goalExam'),
        _StepChoice('📈', 'goalImprove'),
        _StepChoice('🏅', 'goalCertificate'),
      ],
    ),
  ];

  // ── Selections map keyed by step index ───────────────────────────────────
  final Map<int, String> _selected = {};

  // ═══════════════════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  void initState() {
    super.initState();
    _prefs = widget.initialPreferences ?? LearningPreferences();
    _weeklyGoalCtrl.text   = _prefs.weeklyGoal;
    _longTermGoalCtrl.text = _prefs.longTermGoal;

    // Mascot bounce
    _mascotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _mascotBounce = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _mascotCtrl, curve: Curves.easeInOut),
    );

    // Page slide-in
    _pageCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _pageSlide = Tween<Offset>(
      begin: const Offset(0.09, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _pageCtrl, curve: Curves.elasticOut));
    _pageCtrl.forward();

    // Celebration pop
    _celebCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _celebScale = CurvedAnimation(parent: _celebCtrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _mascotCtrl.dispose();
    _pageCtrl.dispose();
    _celebCtrl.dispose();
    _weeklyGoalCtrl.dispose();
    _longTermGoalCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  HELPERS — localization via tr(context).propertyName pattern
  // ═══════════════════════════════════════════════════════════════════════════

  /// Resolves a step localization key to a human string.
  /// The [key] must match a getter on your AppLocalizations class.
  String _loc(BuildContext ctx, String key) {
    final l = tr(ctx);
    switch (key) {
    // ── Step titles ───────────────────────────────────────
      case 'prefStep1Title':       return l.prefStep1Title;
      case 'prefStep2Title':       return l.prefStep2Title;
      case 'prefStep3Title':       return l.prefStep3Title;
      case 'prefStep4Title':       return l.prefStep4Title;
      case 'prefStep5Title':       return l.prefStep5Title;
    // ── Step questions ────────────────────────────────────
      case 'prefStep1Question':    return l.prefStep1Question;
      case 'prefStep2Question':    return l.prefStep2Question;
      case 'prefStep3Question':    return l.prefStep3Question;
      case 'prefStep4Question':    return l.prefStep4Question;
      case 'prefStep5Question':    return l.prefStep5Question;
    // ── Step hints ────────────────────────────────────────
      case 'prefStep1Hint':        return l.prefStep1Hint;
      case 'prefStep2Hint':        return l.prefStep2Hint;
      case 'prefStep3Hint':        return l.prefStep3Hint;
      case 'prefStep4Hint':        return l.prefStep4Hint;
      case 'prefStep5Hint':        return l.prefStep5Hint;
    // ── Subjects ──────────────────────────────────────────
      case 'subjectMath':          return l.subjectMath;
      case 'subjectArabic':        return l.subjectArabic;
      case 'subjectEnglish':       return l.subjectEnglish;
      case 'subjectFrench':        return l.subjectFrench;
      case 'subjectScience':       return l.subjectScience;
      case 'subjectIslamicEd':     return l.subjectIslamicEd;
      case 'subjectArt':           return l.subjectArt;
    // ── Learning styles ───────────────────────────────────
      case 'styleVisual':          return l.styleVisual;
      case 'styleAudio':           return l.styleAudio;
      case 'styleHandsOn':         return l.styleHandsOn;
    // ── Study times ───────────────────────────────────────
      case 'timeMorning':          return l.timeMorning;
      case 'timeAfternoon':        return l.timeAfternoon;
      case 'timeEvening':          return l.timeEvening;
    // ── Difficulty ────────────────────────────────────────
      case 'difficultyEasy':       return l.difficultyEasy;
      case 'difficultyChallenge':  return l.difficultyChallenge;
      case 'difficultyAdaptive':   return l.difficultyAdaptive;
    // ── Goals ─────────────────────────────────────────────
      case 'goalExam':             return l.goalExam;
      case 'goalImprove':          return l.goalImprove;
      case 'goalCertificate':      return l.goalCertificate;
    // ── Misc ──────────────────────────────────────────────
      default:                     return key;
    }
  }

  bool get _isCurrentComplete {
    if (_selected[_currentStep] == null) return false;
    if (_currentStep == 4) {
      return _weeklyGoalCtrl.text.trim().isNotEmpty &&
          _longTermGoalCtrl.text.trim().isNotEmpty;
    }
    return true;
  }

  Future<void> _savePrefs() async {
    final sp = await SharedPreferences.getInstance();
    await _prefs.saveToPrefs(sp);
  }

  void _applySelectionToPrefs() {
    if (_selected[0] != null) _prefs.betterSubjects          = [_selected[0]!];
    if (_selected[1] != null) _prefs.preferredLearningStyle  = _selected[1]!;
    if (_selected[2] != null) _prefs.studyTimePreference     = _selected[2]!;
    if (_selected[3] != null) _prefs.difficultyPreference    = _selected[3]!;
    if (_selected[4] != null) _prefs.goalType                = _selected[4]!;
    _prefs.weeklyGoal   = _weeklyGoalCtrl.text.trim();
    _prefs.longTermGoal = _longTermGoalCtrl.text.trim();
  }

  void _animateToStep(int next) {
    _pageCtrl.reset();
    setState(() => _currentStep = next);
    _pageCtrl.forward();
  }

  void _onNext(AudioManager audio) {
    if (!_isCurrentComplete) return;
    audio.playEventSound('clickButton');
    HapticFeedback.lightImpact();
    if (_currentStep < _steps.length - 1) {
      _animateToStep(_currentStep + 1);
    } else {
      _applySelectionToPrefs();
      _savePrefs();
      setState(() => _showCelebration = true);
      _celebCtrl.forward();
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pop(context, _prefs);
      });
    }
  }

  void _onBack(AudioManager audio) {
    if (_currentStep == 0) return;
    audio.playEventSound('clickButton');
    HapticFeedback.selectionClick();
    _animateToStep(_currentStep - 1);
  }

  void _pickChoice(int stepIndex, String labelKey, AudioManager audio) {
    audio.playEventSound('clickButton');
    HapticFeedback.selectionClick();
    setState(() => _selected[stepIndex] = labelKey);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final audio = Provider.of<AudioManager>(context, listen: false);

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: _KidTheme.bgLight,
        body: Stack(
          children: [
            _buildBgBubbles(),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: _buildWizardCard(audio, context),
              ),
            ),
            if (_showCelebration) _buildCelebration(context),
          ],
        ),
      ),
    );
  }

  // ── Decorative floating background bubbles ────────────────────────────────
  Widget _buildBgBubbles() {
    return Stack(children: [
      Positioned(
        top: -40, left: -40,
        child: _Bubble(size: 160, color: _KidTheme.orangeMid.withOpacity(0.18)),
      ),
      Positioned(
        top: 120, right: -50,
        child: _Bubble(size: 120, color: _KidTheme.tealLight.withOpacity(0.30)),
      ),
      Positioned(
        bottom: 80, left: 20,
        child: _Bubble(size: 80, color: _KidTheme.yellow.withOpacity(0.35)),
      ),
      Positioned(
        bottom: -30, right: -20,
        child: _Bubble(size: 140, color: _KidTheme.orangeMid.withOpacity(0.14)),
      ),
      const Positioned(top: 28, left: 18,  child: _FloatingStar('⭐', delay: 0)),
      const Positioned(top: 40, right: 22, child: _FloatingStar('🌟', delay: 500)),
      const Positioned(top: 88, left: 160, child: _FloatingStar('✨', delay: 250)),
    ]);
  }

  // ── Main wizard card ──────────────────────────────────────────────────────
  Widget _buildWizardCard(AudioManager audio, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _KidTheme.white,
        borderRadius: _KidTheme.cardRadius,
        border: Border.all(color: _KidTheme.orangeMid, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x28EA580C),
            blurRadius: 40,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: _KidTheme.cardRadius,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            _buildBody(audio, context),
          ],
        ),
      ),
    );
  }

  // ── Gradient header ───────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final step     = _steps[_currentStep];
    final progress = (_currentStep + 1) / _steps.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: const BoxDecoration(gradient: _KidTheme.headerGradient),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bouncing mascot
          AnimatedBuilder(
            animation: _mascotBounce,
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _mascotBounce.value),
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  step.mascot,
                  style: const TextStyle(fontSize: 40, height: 1),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _loc(context, step.headerTitleKey),
                  style: const TextStyle(
                    fontFamily: 'Fredoka One',
                    fontSize: 20,
                    color: _KidTheme.white,
                    shadows: [Shadow(color: Color(0x44000000), blurRadius: 6)],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${tr(context).step} ${_currentStep + 1} ${tr(context).ofContext} ${_steps.length} • ${tr(context).keepGoing} 🌈',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 11,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor:
                    const AlwaysStoppedAnimation<Color>(_KidTheme.white),
                  ),
                ),
                const SizedBox(height: 10),
                // Step dots
                Row(
                  children: List.generate(_steps.length, (i) {
                    final isDone   = i < _currentStep;
                    final isActive = i == _currentStep;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 7),
                      width:  isActive ? 16 : 10,
                      height: isActive ? 16 : 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? _KidTheme.yellow
                            : isDone
                            ? _KidTheme.white
                            : Colors.white.withOpacity(0.35),
                        boxShadow: isActive
                            ? [
                          BoxShadow(
                            color: _KidTheme.yellow.withOpacity(0.5),
                            blurRadius: 8,
                          )
                        ]
                            : null,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step body ─────────────────────────────────────────────────────────────
  Widget _buildBody(AudioManager audio, BuildContext context) {
    final step = _steps[_currentStep];

    return SlideTransition(
      position: _pageSlide,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Question ──────────────────────────────────────────────────
            Text(
              _loc(context, step.questionKey),
              style: const TextStyle(
                fontFamily: 'Fredoka One',
                fontSize: 22,
                color: _KidTheme.orangeDark,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 12),

            // ── Hint bubble ───────────────────────────────────────────────
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _KidTheme.tealLight,
                border: Border.all(color: _KidTheme.teal, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _loc(context, step.hintKey),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _KidTheme.teal.withBlue(120),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── Choice grid ───────────────────────────────────────────────
            _buildChoiceGrid(step, audio, context),

            // ── Text fields (step 4 only) ─────────────────────────────────
            if (step.hasTextFields) ...[
              const SizedBox(height: 18),
              _buildKidInput(
                controller: _weeklyGoalCtrl,
                placeholder: tr(context).weeklyGoalHint,
              ),
              const SizedBox(height: 10),
              _buildKidInput(
                controller: _longTermGoalCtrl,
                placeholder: tr(context).longTermGoalHint,
              ),
            ],

            const SizedBox(height: 22),
            _DashedDivider(),
            const SizedBox(height: 18),

            // ── Navigation row ────────────────────────────────────────────
            _buildNavRow(audio, context),
          ],
        ),
      ),
    );
  }

  // ── Choice grid ───────────────────────────────────────────────────────────
  Widget _buildChoiceGrid(
      _StepData step, AudioManager audio, BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 14,
      children: step.choices.map((c) {
        final isSelected = _selected[_currentStep] == c.labelKey;
        return _ChoiceChip(
          emoji: c.emoji,
          label: _loc(context, c.labelKey),
          isSelected: isSelected,
          onTap: () => _pickChoice(_currentStep, c.labelKey, audio),
        );
      }).toList(),
    );
  }

  // ── Text input ────────────────────────────────────────────────────────────
  Widget _buildKidInput({
    required TextEditingController controller,
    required String placeholder,
  }) {
    return TextField(
      controller: controller,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 15,
        color: _KidTheme.orangeDark,
      ),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: const TextStyle(
          color: _KidTheme.orangeMid,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: _KidTheme.orangeLight,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: _KidTheme.inputRadius,
          borderSide:
          const BorderSide(color: _KidTheme.orangeMid, width: 2.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: _KidTheme.inputRadius,
          borderSide:
          const BorderSide(color: _KidTheme.orange, width: 2.5),
        ),
      ),
    );
  }

  // ── Navigation row ────────────────────────────────────────────────────────
  Widget _buildNavRow(AudioManager audio, BuildContext context) {
    final isLast = _currentStep == _steps.length - 1;
    final canGo  = _isCurrentComplete;

    return Row(
      children: [
        if (_currentStep > 0) ...[
          _KidOutlineButton(
            label: '👈 ${tr(context).back}',
            onTap: () => _onBack(audio),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: _KidGradientButton(
            label: isLast
                ? '🎉 ${tr(context).allDone}'
                : '${tr(context).next}  👉',
            enabled: canGo,
            onTap: () => _onNext(audio),
          ),
        ),
      ],
    );
  }

  // ── Celebration overlay ───────────────────────────────────────────────────
  Widget _buildCelebration(BuildContext context) {
    return ScaleTransition(
      scale: _celebScale,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF97316), Color(0xFFF59E0B), Color(0xFF0D9488)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Confetti
          ...[
            Positioned(top: 60,  left: 30,  child: _ConfettiItem('🎉', delay: 0)),
            Positioned(top: 80,  left: 160, child: _ConfettiItem('🌈', delay: 400)),
            Positioned(top: 40,  right: 50, child: _ConfettiItem('⭐', delay: 200)),
            Positioned(top: 120, right: 20, child: _ConfettiItem('🎊', delay: 600)),
            Positioned(top: 90,  left: 250, child: _ConfettiItem('🦋', delay: 100)),
          ],
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _SpinEmoji('🎉'),
                const SizedBox(height: 20),
                Text(
                  tr(context).celebrationTitle,
                  style: const TextStyle(
                    fontFamily: 'Fredoka One',
                    fontSize: 36,
                    color: _KidTheme.white,
                    shadows: [
                      Shadow(color: Color(0x44000000), blurRadius: 12)
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  tr(context).celebrationSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.95),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  REUSABLE SMALL WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

/// Plain circular background bubble for decoration
class _Bubble extends StatelessWidget {
  final double size;
  final Color color;
  const _Bubble({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// Animated choice chip — orange theme
class _ChoiceChip extends StatefulWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChoiceChip({
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ChoiceChip> createState() => _ChoiceChipState();
}

class _ChoiceChipState extends State<_ChoiceChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
  }

  @override
  void didUpdateWidget(_ChoiceChip old) {
    super.didUpdateWidget(old);
    if (widget.isSelected && !old.isSelected) {
      _ctrl.forward(from: 0);
    } else if (!widget.isSelected && old.isSelected) {
      _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 118,
        padding:
        const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        transform: widget.isSelected
            ? (Matrix4.identity()
          ..translate(0.0, -5.0)
          ..scale(1.07))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          gradient: widget.isSelected ? _KidTheme.buttonGradient : null,
          color: widget.isSelected ? null : _KidTheme.orangeLight,
          borderRadius: _KidTheme.chipRadius,
          border: Border.all(
            color: widget.isSelected
                ? _KidTheme.orangeDark
                : _KidTheme.orangeMid,
            width: 2.5,
          ),
          boxShadow: widget.isSelected
              ? [
            const BoxShadow(
              color: Color(0x55EA580C),
              blurRadius: 18,
              offset: Offset(0, 6),
            )
          ]
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.emoji,
                  style: const TextStyle(fontSize: 34, height: 1),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: widget.isSelected
                        ? _KidTheme.white
                        : _KidTheme.orangeDark,
                    height: 1.2,
                  ),
                ),
              ],
            ),
            // Green checkmark badge
            if (widget.isSelected)
              Positioned(
                top: -12,
                right: -12,
                child: ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: _KidTheme.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _KidTheme.green.withOpacity(0.4),
                          blurRadius: 8,
                        )
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '✓',
                      style: TextStyle(
                        color: _KidTheme.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
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

/// Orange-to-teal gradient "Next / Done" button
class _KidGradientButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _KidGradientButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        decoration: BoxDecoration(
          gradient: enabled ? _KidTheme.buttonGradient : null,
          color: enabled ? null : const Color(0xFFD1D5DB),
          borderRadius: _KidTheme.btnRadius,
          boxShadow: enabled
              ? [
            const BoxShadow(
              color: Color(0x55EA580C),
              blurRadius: 16,
              offset: Offset(0, 5),
            )
          ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Fredoka One',
            fontSize: 19,
            color: enabled ? _KidTheme.white : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}

/// Outlined "Back" button — teal accent
class _KidOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _KidOutlineButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: _KidTheme.tealLight,
          borderRadius: _KidTheme.btnRadius,
          border: Border.all(color: _KidTheme.teal, width: 2.5),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Fredoka One',
            fontSize: 16,
            color: _KidTheme.teal,
          ),
        ),
      ),
    );
  }
}

/// Dashed orange divider
class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      const dashW = 8.0, gap = 6.0;
      final count = (constraints.maxWidth / (dashW + gap)).floor();
      return Row(
        children: List.generate(
          count,
              (_) => Container(
            width: dashW,
            height: 2.5,
            margin: const EdgeInsets.only(right: gap),
            decoration: BoxDecoration(
              color: _KidTheme.dashed,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );
    });
  }
}

/// Floating star with bobbing animation
class _FloatingStar extends StatefulWidget {
  final String emoji;
  final int delay;
  const _FloatingStar(this.emoji, {required this.delay});

  @override
  State<_FloatingStar> createState() => _FloatingStarState();
}

class _FloatingStarState extends State<_FloatingStar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Opacity(
          opacity: 0.5,
          child: Text(widget.emoji,
              style: const TextStyle(fontSize: 22)),
        ),
      ),
    );
  }
}

/// Confetti item with falling + rotating animation
class _ConfettiItem extends StatefulWidget {
  final String emoji;
  final int delay;
  const _ConfettiItem(this.emoji, {required this.delay});

  @override
  State<_ConfettiItem> createState() => _ConfettiItemState();
}

class _ConfettiItemState extends State<_ConfettiItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fall;
  late final Animation<double> _rotate;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
    _fall   = Tween<double>(begin: -60, end: 620)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _rotate = Tween<double>(begin: 0, end: 6.28 * 2).animate(_ctrl);
    Future.delayed(Duration(milliseconds: widget.delay));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform(
        transform: Matrix4.identity()
          ..translate(0.0, _fall.value)
          ..rotateZ(_rotate.value),
        child: Opacity(
          opacity: (1 - _ctrl.value).clamp(0.0, 1.0),
          child: Text(widget.emoji,
              style: const TextStyle(fontSize: 28)),
        ),
      ),
    );
  }
}

/// Spin-in emoji for celebration screen
class _SpinEmoji extends StatefulWidget {
  final String emoji;
  const _SpinEmoji(this.emoji);

  @override
  State<_SpinEmoji> createState() => _SpinEmojiState();
}

class _SpinEmojiState extends State<_SpinEmoji>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _spin;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
    _spin  = Tween<double>(begin: -0.35, end: 0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _scale = Tween<double>(begin: 0.4, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..rotateZ(_spin.value)
          ..scale(_scale.value),
        child: Text(widget.emoji,
            style: const TextStyle(fontSize: 90)),
      ),
    );
  }
}