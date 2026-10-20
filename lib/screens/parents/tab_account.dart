import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mortaalim/Authentification/BackUp/BackUpPage.dart';
import 'package:mortaalim/Manager/models/avatar_catalog.dart';
import 'package:mortaalim/User_Input_Info_DataForm/User_Info_FirstCon/UserInfoForm_Introduction.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/screens/profiles/profile_picker_page.dart';
import 'package:mortaalim/screens/profiles/profile_store.dart';
import 'package:mortaalim/widgets/AboutMoorTaalim/PrivacyPolicyPage.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:mortaalim/widgets/ProfileSetup_Widget/MainProfile_Page/Widgets/UserDataProfileEntering.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';

import 'parent_gate.dart';
import 'parent_strings.dart';
import 'parent_ui.dart';
import 'parents_space.dart';

const String _supportEmail = 'moortaalim@gmail.com';
const String _packageId = 'com.jalnix.moortaalim';

/// "Compte": child profiles, purchases, backup, legal and support.
class AccountTab extends StatefulWidget {
  const AccountTab({super.key});

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  List<KidProfile> _kids = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await ProfileStore.load(Provider.of<ExperienceManager>(context, listen: false));
    if (mounted) setState(() => _kids = list);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      physics: const BouncingScrollPhysics(),
      children: [
        TabHeader(title: pT(context, 'accountTitle'), sub: pT(context, 'accountSub'), robot: 'robot_hello', robotW: 120, showChild: false),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(children: [
            _profilesCard(),
            const SizedBox(height: 12),
            _purchasesCard(),
            const SizedBox(height: 12),
            _moreCard(),
            const SizedBox(height: 14),
            PGhostButton(pT(context, 'lockNow'), icon: Icons.lock_rounded, onTap: () {
              ParentGate.lock();
              Navigator.maybePop(context);
            }),
          ]),
        ),
      ],
    );
  }

  // ───────────────────────── profiles

  Widget _profilesCard() {
    return PCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PTitle(Icons.groups_rounded, pT(context, 'profiles'), sub: pT(context, 'profilesSub', {'n': ProfileStore.maxProfiles}),
            color: const Color(0xFF7C4DDB)),
        const SizedBox(height: 10),
        for (final k in _kids) _kidRow(k),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            child: PGhostButton(pT(context, 'switchPlayer'), icon: Icons.swap_horiz_rounded, onTap: () => openProfilePicker(context)),
          ),
          if (_kids.length < ProfileStore.maxProfiles) ...[
            const SizedBox(width: 10),
            Expanded(child: PGhostButton(pT(context, 'addPlayer'), icon: Icons.person_add_alt_1_rounded, onTap: _addKid)),
          ],
        ]),
      ]),
    );
  }

  Widget _kidRow(KidProfile k) {
    final active = k.id == ProfileStore.activeId;
    final xp = Provider.of<ExperienceManager>(context);
    final avatar = active ? xp.selectedAvatar : k.avatar;
    final name = active ? xp.userProfile.fullName.trim() : k.name;
    final level = active ? xp.level : k.level;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
      decoration: BoxDecoration(
        color: active ? PC.tealSoft : Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? PC.teal : PC.line, width: 2),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: PC.lav,
          backgroundImage: AssetImage(AvatarCatalog.isValid(avatar) ? avatar : AvatarCatalog.defaultAvatar),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name.isEmpty ? pT(context, 'newPlayer') : name, style: ps(17.5, w: FontWeight.w700)),
            Text(active ? '${pT(context, 'levelN', {'n': level})} · ${pT(context, 'playingNow')}' : pT(context, 'levelN', {'n': level}),
                style: ps(13.5, color: active ? PC.tealDeep : PC.sub, w: FontWeight.w600)),
          ]),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: PC.sub),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onSelected: (v) {
            if (v == 'rename') _rename(k, name);
            if (v == 'delete') _delete(k, name);
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'rename', child: Text(pT(context, 'rename'), style: ps(15))),
            if (!active) PopupMenuItem(value: 'delete', child: Text(pT(context, 'delete'), style: ps(15, color: const Color(0xFFD9214E)))),
          ],
        ),
      ]),
    );
  }

  Future<void> _rename(KidProfile k, String current) async {
    final c = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PC.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(pT(ctx, 'rename'), style: ps(22, w: FontWeight.w700)),
        content: TextField(controller: c, autofocus: true, style: ps(17), maxLength: 20),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(pT(ctx, 'cancel'), style: ps(16, color: PC.sub))),
          TextButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: Text(pT(ctx, 'ok'), style: ps(16, color: PC.tealDeep, w: FontWeight.w700))),
        ],
      ),
    );
    if (name == null || name.isEmpty || !mounted) return;
    if (k.id == ProfileStore.activeId) {
      Provider.of<ExperienceManager>(context, listen: false).setFullName(name);
    }
    await ProfileStore.rename(k.id, name);
    _load();
  }

  Future<void> _delete(KidProfile k, String name) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PC.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(pT(ctx, 'deleteKidTitle', {'name': name.isEmpty ? pT(ctx, 'newPlayer') : name}), style: ps(21, w: FontWeight.w700)),
        content: Text(pT(ctx, 'deleteKidSub'), style: ps(15, color: PC.sub, w: FontWeight.w500)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(pT(ctx, 'cancel'), style: ps(16, color: PC.sub))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(pT(ctx, 'delete'), style: ps(16, color: const Color(0xFFD9214E), w: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (yes != true) return;
    await ProfileStore.delete(k.id);
    _load();
  }

  Future<void> _addKid() async {
    final xp = Provider.of<ExperienceManager>(context, listen: false);
    final id = await ProfileStore.create();
    if (id == null || !mounted) return;
    await ProfileStore.switchTo(id, xp);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const UserInfoForm()),
      (_) => false,
    );
  }

  // ───────────────────────── purchases

  Widget _purchasesCard() {
    Widget row(String img, String title, String sub, Color c) => KidPressable(
          onTap: () => _soon(title),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.75), borderRadius: BorderRadius.circular(20), border: Border.all(color: PC.line, width: 2)),
            child: Row(children: [
              Container(
                width: 54,
                height: 54,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
                child: Image.asset(pa(img), fit: BoxFit.contain),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: ps(17, w: FontWeight.w700)),
                  Text(sub, style: ps(13, color: PC.sub, w: FontWeight.w500)),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded, color: PC.ink),
            ]),
          ),
        );
    return PCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PTitle(Icons.shopping_bag_rounded, pT(context, 'purchases'), sub: pT(context, 'purchasesSub'), color: PC.orange),
        const SizedBox(height: 10),
        row('noads', pT(context, 'removeAds'), pT(context, 'removeAdsSub'), const Color(0xFFE5484D)),
        row('crown', pT(context, 'premium'), pT(context, 'premiumSub'), const Color(0xFFF5B400)),
        row('gem_bag', pT(context, 'gems'), pT(context, 'gemsSub'), const Color(0xFF7C4DDB)),
        Row(children: [
          const Icon(Icons.verified_user_rounded, color: PC.sub, size: 18),
          const SizedBox(width: 6),
          Expanded(child: Text(pT(context, 'purchasesNote'), style: ps(12.5, color: PC.sub, w: FontWeight.w500))),
        ]),
      ]),
    );
  }

  void _soon(String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.paddingOf(ctx).bottom),
        decoration: const BoxDecoration(color: PC.cream, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Image.asset(pa('cloud_ok'), width: 110),
          const SizedBox(height: 8),
          Text(title, style: ps(22, w: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(pT(ctx, 'soonLong'), textAlign: TextAlign.center, style: ps(15, color: PC.sub, w: FontWeight.w500)),
          const SizedBox(height: 16),
          PButton(pT(ctx, 'ok'), onTap: () => Navigator.pop(ctx)),
        ]),
      ),
    );
  }

  // ───────────────────────── more

  Widget _moreCard() {
    Widget row(IconData i, String t, VoidCallback onTap, {Color c = PC.teal}) => KidPressable(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              PIcon(i, color: c, bg: c.withOpacity(0.12), size: 42),
              const SizedBox(width: 12),
              Expanded(child: Text(t, style: ps(16.5, w: FontWeight.w600))),
              const Icon(Icons.chevron_right_rounded, color: PC.ink),
            ]),
          ),
        );
    return PCard(
      child: Column(children: [
        row(Icons.badge_rounded, pT(context, 'editProfile'),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserAndSchoolInfoPage())), c: const Color(0xFF7C4DDB)),
        const Divider(height: 1, color: PC.line),
        row(Icons.volume_up_rounded, pT(context, 'resetAudio'), () {
          Provider.of<AudioManager>(context, listen: false).resetAudioSettings();
          pSnack(context, pT(context, 'savedTitle'));
        }, c: PC.orange),
        const Divider(height: 1, color: PC.line),
        row(Icons.cloud_upload_rounded, pT(context, 'backup'), () {
          final xp = Provider.of<ExperienceManager>(context, listen: false);
          Navigator.push(context, MaterialPageRoute(builder: (_) => BackupPage(experienceManager: xp)));
        }),
        const Divider(height: 1, color: PC.line),
        row(Icons.privacy_tip_rounded, pT(context, 'privacy'),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyPage())), c: const Color(0xFF6D5BD0)),
        const Divider(height: 1, color: PC.line),
        row(Icons.gavel_rounded, pT(context, 'terms'),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyPage())), c: const Color(0xFF6D5BD0)),
        const Divider(height: 1, color: PC.line),
        row(Icons.mail_rounded, pT(context, 'contact'), () async {
          final uri = Uri(scheme: 'mailto', path: _supportEmail, query: 'subject=MoorTaalim');
          var ok = false;
          try {
            ok = await launchUrl(uri);
          } catch (_) {}
          if (!ok && mounted) pSnack(context, _supportEmail);
        }, c: PC.orange),
        const Divider(height: 1, color: PC.line),
        row(Icons.star_rounded, pT(context, 'rateApp'), () async {
          try {
            if (await launchUrl(Uri.parse('market://details?id=$_packageId'), mode: LaunchMode.externalApplication)) return;
          } catch (_) {}
          try {
            await launchUrl(Uri.parse('https://play.google.com/store/apps/details?id=$_packageId'), mode: LaunchMode.externalApplication);
          } catch (_) {}
        }, c: const Color(0xFFF5B400)),
      ]),
    );
  }
}
