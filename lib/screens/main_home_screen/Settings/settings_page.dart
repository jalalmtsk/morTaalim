import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/Authentification/BackUp/BackUpPage.dart';
import 'package:mortaalim/Manager/Services/CardVisibiltyManager.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/AboutMoorTaalim/AboutMoorTaalim.dart';
import 'package:mortaalim/widgets/AboutMoorTaalim/PrivacyPolicyPage.dart';
import 'package:mortaalim/widgets/KidScene/kid_form.dart';
import 'package:mortaalim/widgets/KidScene/kid_page_parts.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:mortaalim/widgets/ProfileSetup_Widget/MainProfile_Page/Widgets/UserDataProfileEntering.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsAssets {
  SettingsAssets._();
  static const String dir = 'assets/images/UI/KidScene/';
  static const String gear = '${dir}set_gear.webp';
  static const String music = '${dir}set_music.webp';
  static const String speaker = '${dir}set_speaker.webp';
  static const String speakerSmall = '${dir}set_speaker_small.webp';
  static const String tap = '${dir}set_tap.webp';
  static const String globe = '${dir}set_globe.webp';
  static const String book = '${dir}set_book.webp';
  static const String duaa = '${dir}set_duaa.webp';
  static const String cloud = '${dir}set_cloud.webp';
  static const String bell = '${dir}set_bell.webp';
  static const String lock = '${dir}set_lock.webp';
  static const String help = '${dir}set_help.webp';
  static const String info = '${dir}set_info.webp';

  static const all = [gear, music, speaker, speakerSmall, tap, globe, book, duaa, cloud, bell, lock, help, info];
}

/// Announcements from the app team (read by NotificationManager).
const String kAppNotificationsPref = 'app_notifications_enabled';
const String _supportEmail = 'moortaalim@gmail.com';

const _languages = <(String, String)>[
  ('en', 'English'),
  ('fr', 'Français'),
  ('ar', 'العربية'),
  ('de', 'Deutsch'),
  ('zgh', 'ⵜⴰⵎⴰⵣⵉⵖⵜ'),
];

/// Simple multiplication question so only grown-ups get through.
Future<bool> kidParentGate(BuildContext context) async {
  final rnd = Random();
  final a = 3 + rnd.nextInt(7), b = 3 + rnd.nextInt(7);
  final answer = a * b;
  final options = <int>{answer};
  while (options.length < 3) {
    final delta = (rnd.nextInt(3) + 1) * (rnd.nextBool() ? a : b);
    final v = rnd.nextBool() ? answer + delta : answer - delta;
    if (v > 0) options.add(v);
  }
  final shuffled = options.toList()..shuffle(rnd);
  return await showDialog<bool>(
        context: context,
        barrierColor: KidColors.purpleDeep.withOpacity(0.35),
        builder: (ctx) => KidDialog(
          title: tr(ctx).parentGateTitle,
          message: tr(ctx).parentGateQuestion(a, b),
          content: Row(children: [
            for (int i = 0; i < shuffled.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: KidOutlineButton(
                  label: '${shuffled[i]}',
                  height: 56,
                  onTap: () {
                    final am = Provider.of<AudioManager>(ctx, listen: false);
                    am.playEventSound(shuffled[i] == answer ? 'clickButton' : 'invalid');
                    Navigator.of(ctx).pop(shuffled[i] == answer);
                  },
                ),
              ),
            ],
          ]),
        ),
      ) ??
      false;
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with TickerProviderStateMixin {
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  bool _notifications = true;
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => _notifications = p.getBool(kAppNotificationsPref) ?? true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      KidAssets.precache(context, [...SettingsAssets.all, KidAssets.valleyBg, KidAssets.backBtn]);
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _spin.dispose();
    super.dispose();
  }

  AudioManager get _audio => Provider.of<AudioManager>(context, listen: false);

  void _toggleSound() => _audio.playEventSound('toggleButton');

  Future<void> _pickLanguage() async {
    _audio.playEventSound('clickButton');
    final xp = Provider.of<ExperienceManager>(context, listen: false);
    final current = Localizations.localeOf(context).languageCode;
    final code = await showKidOptionSheet<String>(
      context: context,
      title: tr(context).language,
      options: [for (final l in _languages) l.$1],
      label: (c) => _languages.firstWhere((l) => l.$1 == c).$2,
      selected: current,
    );
    if (code == null || code == current || !mounted) return;
    await xp.changeLanguage(Locale(code));
    if (code == 'zgh' && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: KidColors.purpleDeep,
        content: Text(tr(context).zghNotice, style: kidBodyStyle(14, color: Colors.white, weight: FontWeight.w600)),
      ));
    }
  }

  Future<void> _behindGate(Future<void> Function() action) async {
    _audio.playEventSound('clickButton');
    if (await kidParentGate(context) && mounted) await action();
  }

  Future<void> _openBackup() => _behindGate(() async {
        final xp = Provider.of<ExperienceManager>(context, listen: false);
        await Navigator.push(context, MaterialPageRoute(builder: (_) => BackupPage(experienceManager: xp)));
      });

  Future<void> _openHelp() => _behindGate(() async {
        final uri = Uri(scheme: 'mailto', path: _supportEmail, query: 'subject=MoorTaalim%20$appVersion');
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_supportEmail)));
        }
      });

  Future<void> _openParental() => _behindGate(() async {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => KidSheetFrame(
            title: tr(ctx).parentalArea,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _SheetRow(
                icon: SettingsAssets.book,
                label: tr(ctx).editProfile,
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const UserAndSchoolInfoPage()));
                },
              ),
              _SheetRow(
                icon: SettingsAssets.cloud,
                label: tr(ctx).manageBackup,
                onTap: () {
                  Navigator.pop(ctx);
                  final xp = Provider.of<ExperienceManager>(context, listen: false);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => BackupPage(experienceManager: xp)));
                },
              ),
              _SheetRow(
                icon: SettingsAssets.speaker,
                label: tr(ctx).resetAudioSettings,
                onTap: () {
                  Navigator.pop(ctx);
                  _audio.resetAudioSettings();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: KidColors.purpleDeep,
                    content: Text(tr(context).resetAudioSettings,
                        style: kidBodyStyle(14, color: Colors.white, weight: FontWeight.w600)),
                  ));
                },
              ),
              _SheetRow(
                icon: SettingsAssets.help,
                label: tr(ctx).contactSupport,
                onTap: () async {
                  Navigator.pop(ctx);
                  await launchUrl(Uri(scheme: 'mailto', path: _supportEmail), mode: LaunchMode.externalApplication);
                },
              ),
            ]),
          ),
        );
      });

  @override
  Widget build(BuildContext context) {
    final audio = Provider.of<AudioManager>(context);
    final cards = context.watch<CardVisibilityManager>();
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final w = min(size.width, 600.0) - 28;
    final s = (w / 380).clamp(0.8, 1.4);
    final t = tr(context);
    final langCode = Localizations.localeOf(context).languageCode;
    final langName = _languages.firstWhere((l) => l.$1 == langCode, orElse: () => _languages.first).$2;

    Widget step(int i, Widget child) =>
        KidIntro(intro: _intro, from: 0.07 * i, to: min(1.0, 0.45 + 0.07 * i), rise: 22, child: child);

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
                step(0, _TitleBar(scale: s, spin: _spin)),
                SizedBox(height: 10 * s),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(bottom: pad.bottom + 20),
                    children: [
                      step(
                        1,
                        _Section(scale: s, title: t.secAudio, rows: [
                          _Row(
                            scale: s,
                            icon: SettingsAssets.music,
                            label: t.backgroundMusic,
                            trailing: _VolumeControl(
                              scale: s,
                              value: audio.isBgMuted ? 0 : audio.bgVolume,
                              muted: audio.isBgMuted,
                              onChanged: (v) {
                                if (audio.isBgMuted && v > 0) audio.toggleBgMute();
                                audio.setBgVolume(v);
                              },
                              onMute: () {
                                _toggleSound();
                                audio.toggleBgMute();
                              },
                            ),
                          ),
                          _Row(
                            scale: s,
                            icon: SettingsAssets.speaker,
                            label: t.soundEffects,
                            trailing: _VolumeControl(
                              scale: s,
                              value: audio.isSfxMuted ? 0 : audio.sfxVolume,
                              muted: audio.isSfxMuted,
                              onChanged: (v) {
                                if (audio.isSfxMuted && v > 0) audio.toggleSfxMute();
                                audio.setSfxVolume(v);
                              },
                              onChangeEnd: (_) =>
                                  audio.playSfx('assets/audios/UI_Audio/SFX_Audio/victory2_SFX.mp3'),
                              onMute: () {
                                _toggleSound();
                                audio.toggleSfxMute();
                              },
                            ),
                          ),
                          _Row(
                            scale: s,
                            icon: SettingsAssets.tap,
                            label: t.buttonSounds,
                            trailing: _KidToggle(
                              scale: s,
                              value: !audio.isButtonMuted,
                              onChanged: (_) async {
                                await audio.toggleButtonMute();
                                _toggleSound();
                              },
                            ),
                          ),
                        ]),
                      ),
                      SizedBox(height: 14 * s),
                      step(
                        2,
                        _Section(scale: s, title: t.secLanguageHome, rows: [
                          _Row(
                            scale: s,
                            icon: SettingsAssets.globe,
                            label: t.language,
                            onTap: _pickLanguage,
                            trailing: Container(
                              constraints: BoxConstraints(maxWidth: 130 * s),
                              padding: EdgeInsetsDirectional.only(start: 14 * s, end: 6 * s),
                              height: 40 * s,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: const Color(0xFFE9DEC8), width: 1.5),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(langName, style: kidBodyStyle(16 * s, color: KidColors.ink, weight: FontWeight.w700)),
                                  ),
                                ),
                                SizedBox(width: 4 * s),
                                _chevron(context, s),
                              ]),
                            ),
                          ),
                          _Row(
                            scale: s,
                            icon: SettingsAssets.book,
                            label: t.showVerseOfDay,
                            trailing: _KidToggle(
                              scale: s,
                              value: cards.showAyatCard,
                              onChanged: (v) {
                                context.read<CardVisibilityManager>().toggleAyatCard(v);
                                _toggleSound();
                              },
                            ),
                          ),
                          _Row(
                            scale: s,
                            icon: SettingsAssets.duaa,
                            label: t.showDailyDuaa,
                            trailing: _KidToggle(
                              scale: s,
                              value: cards.showDuaaDialog,
                              onChanged: (v) {
                                context.read<CardVisibilityManager>().toggleDuaaDialog(v);
                                _toggleSound();
                              },
                            ),
                          ),
                        ]),
                      ),
                      SizedBox(height: 14 * s),
                      step(
                        3,
                        _Section(scale: s, title: t.secSaveProgress, rows: [
                          Container(
                            padding: EdgeInsets.fromLTRB(10 * s, 10 * s, 10 * s, 10 * s),
                            decoration: _rowDeco(s),
                            child: Row(children: [
                              Image.asset(SettingsAssets.cloud, width: 56 * s, height: 56 * s * 0.9349),
                              SizedBox(width: 10 * s),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: AlignmentDirectional.centerStart,
                                      child: Text(t.backupAccount,
                                          style: kidBodyStyle(17 * s, color: KidColors.ink, weight: FontWeight.w700)),
                                    ),
                                    SizedBox(height: 2 * s),
                                    Text(t.backupSub,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: kidBodyStyle(11.5 * s, color: KidColors.muted, weight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8 * s),
                              Column(mainAxisSize: MainAxisSize.min, children: [
                                _PurpleButton(scale: s, label: t.manageBackup, onTap: _openBackup),
                                SizedBox(height: 4 * s),
                                Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.lock_rounded, size: 12 * s, color: KidColors.muted),
                                  SizedBox(width: 3 * s),
                                  Text(t.parentsOnly,
                                      style: kidBodyStyle(11 * s, color: KidColors.muted, weight: FontWeight.w600)),
                                ]),
                              ]),
                            ]),
                          ),
                        ]),
                      ),
                      SizedBox(height: 14 * s),
                      step(
                        4,
                        _Section(scale: s, title: t.secMore, rows: [
                          _Row(
                            scale: s,
                            icon: SettingsAssets.bell,
                            label: t.notifications,
                            trailing: _KidToggle(
                              scale: s,
                              value: _notifications,
                              onChanged: (v) async {
                                _toggleSound();
                                setState(() => _notifications = v);
                                (await SharedPreferences.getInstance()).setBool(kAppNotificationsPref, v);
                              },
                            ),
                          ),
                          _Row(scale: s, icon: SettingsAssets.lock, label: t.parentalArea, onTap: _openParental,
                              trailing: _chevron(context, s)),
                          _Row(scale: s, icon: SettingsAssets.help, label: t.helpSupport, onTap: _openHelp,
                              trailing: _chevron(context, s)),
                          _Row(
                            scale: s,
                            icon: SettingsAssets.info,
                            label: t.aboutMoorTaalim,
                            onTap: () {
                              _audio.playEventSound('clickButton');
                              Navigator.push(context, MaterialPageRoute(builder: (_) => AboutMoorTaalimPage()));
                            },
                            trailing: _chevron(context, s),
                          ),
                        ]),
                      ),
                      SizedBox(height: 16 * s),
                      step(
                        5,
                        Column(children: [
                          Text('${t.version} $appVersion',
                              style: kidBodyStyle(13 * s, color: KidColors.inkSoft, weight: FontWeight.w600)
                                  .copyWith(shadows: [Shadow(color: Colors.white.withOpacity(0.9), blurRadius: 6)])),
                          SizedBox(height: 4 * s),
                          KidPressable(
                            onTap: () {
                              _audio.playEventSound('clickButton');
                              Navigator.push(context, MaterialPageRoute(builder: (_) => PrivacyPolicyPage()));
                            },
                            child: Text(t.privacyPolicy,
                                style: kidBodyStyle(14 * s, color: KidColors.purpleDeep, weight: FontWeight.w700).copyWith(
                                  decoration: TextDecoration.underline,
                                  decorationColor: KidColors.purpleDeep,
                                  shadows: [Shadow(color: Colors.white.withOpacity(0.9), blurRadius: 6)],
                                )),
                          ),
                        ]),
                      ),
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

Widget _chevron(BuildContext context, double s) => Transform.flip(
      flipX: Directionality.of(context) == TextDirection.rtl,
      child: Icon(Icons.chevron_right_rounded, color: KidColors.purple, size: 28 * s),
    );

BoxDecoration _rowDeco(double s) => BoxDecoration(
      color: const Color(0xFFFFFAEE),
      borderRadius: BorderRadius.circular(20 * s),
      border: Border.all(color: const Color(0xFFF1E6CF), width: 1.5),
    );

class _TitleBar extends StatelessWidget {
  final double scale;
  final Animation<double> spin;
  const _TitleBar({required this.scale, required this.spin});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      height: 72 * s,
      padding: EdgeInsets.symmetric(horizontal: 10 * s),
      decoration: BoxDecoration(
        color: KidColors.cream,
        borderRadius: BorderRadius.circular(40 * s),
        border: Border.all(color: const Color(0xFFFFD98A), width: 2.5),
        boxShadow: [BoxShadow(color: KidColors.purpleDeep.withOpacity(0.18), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        KidBackButton(
          size: 50 * s,
          onTap: () {
            Provider.of<AudioManager>(context, listen: false).playEventSound('cancelButton');
            Navigator.of(context).maybePop();
          },
        ),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(tr(context).settings, maxLines: 1, style: kidTitleStyle(36 * s).copyWith(shadows: const [])),
          ),
        ),
        RotationTransition(
          turns: spin,
          child: Image.asset(SettingsAssets.gear, width: 46 * s, height: 46 * s * 1.07),
        ),
      ]),
    );
  }
}

/// Lavender header band + cream body holding the rows.
class _Section extends StatelessWidget {
  final double scale;
  final String title;
  final List<Widget> rows;
  const _Section({required this.scale, required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final r = 28 * s;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE3DAFF), Color(0xFFD7CCFA)],
        ),
        border: Border.all(color: const Color(0xFFB79CF5), width: 2.5),
        boxShadow: [BoxShadow(color: KidColors.purpleDeep.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(18 * s, 10 * s, 14 * s, 8 * s),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(title, maxLines: 1, style: kidTitleStyle(24 * s).copyWith(shadows: const [])),
          ),
        ),
        Container(
          width: double.infinity,
          margin: EdgeInsets.fromLTRB(6 * s, 0, 6 * s, 6 * s),
          padding: EdgeInsets.all(6 * s),
          decoration: BoxDecoration(
            color: KidColors.cream,
            borderRadius: BorderRadius.circular(r - 6 * s),
          ),
          child: Column(children: [
            for (int i = 0; i < rows.length; i++) ...[
              if (i > 0) SizedBox(height: 6 * s),
              rows[i],
            ],
          ]),
        ),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  final double scale;
  final String icon, label;
  final Widget trailing;
  final VoidCallback? onTap;
  const _Row({required this.scale, required this.icon, required this.label, required this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final row = Container(
      constraints: BoxConstraints(minHeight: 60 * s),
      padding: EdgeInsetsDirectional.fromSTEB(10 * s, 6 * s, 10 * s, 6 * s),
      decoration: _rowDeco(s),
      child: Row(children: [
        SizedBox(width: 44 * s, height: 44 * s, child: Image.asset(icon, fit: BoxFit.contain)),
        SizedBox(width: 10 * s),
        Expanded(
          child: Text(label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: kidBodyStyle(16.5 * s, color: KidColors.ink, weight: FontWeight.w700)),
        ),
        SizedBox(width: 8 * s),
        trailing,
      ]),
    );
    return onTap == null ? row : KidPressable(onTap: onTap, pressedScale: 0.97, semanticLabel: label, child: row);
  }
}

class _KidToggle extends StatelessWidget {
  final double scale;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _KidToggle({required this.scale, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final w = 78 * s, h = 40 * s, knob = 32 * s;
    final t = tr(context);
    return Semantics(
      toggled: value,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: w,
          height: h,
          padding: EdgeInsets.all((h - knob) / 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(h),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: value ? const [Color(0xFF3DDC7A), Color(0xFF16A34A)] : const [Color(0xFFB4B1C4), Color(0xFF7E7A94)],
            ),
            boxShadow: [
              BoxShadow(color: (value ? const Color(0xFF0E7A35) : const Color(0xFF5E5A72)), offset: Offset(0, 2.5 * s)),
            ],
          ),
          child: Stack(children: [
            Align(
              alignment: value ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6 * s),
                child: Text(value ? t.toggleOn : t.toggleOff,
                    style: kidBodyStyle(14 * s, color: Colors.white, weight: FontWeight.w700).copyWith(height: 1.0)),
              ),
            ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              alignment: value ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
              child: Container(
                width: knob,
                height: knob,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFE9E6F2)]),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 3, offset: const Offset(0, 1.5))],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _VolumeControl extends StatelessWidget {
  final double scale, value;
  final bool muted;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final VoidCallback onMute;
  const _VolumeControl({required this.scale, required this.value, required this.muted, required this.onChanged,
      this.onChangeEnd, required this.onMute});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return SizedBox(
      width: 150 * s,
      child: Row(children: [
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 12 * s,
              activeTrackColor: KidColors.purple,
              inactiveTrackColor: const Color(0xFFDCD3F7),
              thumbColor: const Color(0xFF8A44F0),
              overlayColor: KidColors.purple.withOpacity(0.15),
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12 * s, elevation: 3),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 18 * s),
              trackShape: const RoundedRectSliderTrackShape(),
            ),
            child: Slider(value: value.clamp(0.0, 1.0), onChanged: onChanged, onChangeEnd: onChangeEnd),
          ),
        ),
        KidPressable(
          onTap: onMute,
          child: Opacity(
            opacity: muted ? 0.4 : 1,
            child: Stack(alignment: Alignment.center, children: [
              Image.asset(SettingsAssets.speakerSmall, width: 26 * s, height: 26 * s * 0.9),
              if (muted) Icon(Icons.close_rounded, color: const Color(0xFFE11D48), size: 18 * s),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _PurpleButton extends StatelessWidget {
  final double scale;
  final String label;
  final VoidCallback onTap;
  const _PurpleButton({required this.scale, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return KidPressable(
      onTap: onTap,
      pressedScale: 0.94,
      semanticLabel: label,
      child: Container(
        height: 42 * s,
        constraints: BoxConstraints(maxWidth: 150 * s, minWidth: 96 * s),
        padding: EdgeInsets.symmetric(horizontal: 14 * s),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: const LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF9B5CFF), Color(0xFF6A2BE0)]),
          border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
          boxShadow: [BoxShadow(color: const Color(0xFF4A1BA8), offset: Offset(0, 3 * s))],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, maxLines: 1, style: kidBodyStyle(15 * s, color: Colors.white, weight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  final String icon, label;
  final VoidCallback onTap;
  const _SheetRow({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: KidPressable(
          onTap: onTap,
          pressedScale: 0.97,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: _rowDeco(1),
            child: Row(children: [
              SizedBox(width: 40, height: 40, child: Image.asset(icon, fit: BoxFit.contain)),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: kidBodyStyle(16, color: KidColors.ink, weight: FontWeight.w700))),
              _chevron(context, 1),
            ]),
          ),
        ),
      );
}
