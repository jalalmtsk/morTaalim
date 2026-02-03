import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Manager/Services/CardVisibiltyManager.dart';
import '../main.dart';

import '../tools/audio_tool/Audio_Manager.dart';
import 'Setting_cards/BackUp_card.dart';
import 'Setting_cards/GoogleAccount.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});
  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  bool bgExpanded = true;
  bool sfxExpanded = false;
  bool buttonExpanded = false;
  bool alertExpanded = false;

  Widget buildVolumeControl({
    required String title,
    required bool expanded,
    required Function(bool) onExpandChanged,
    required bool isMuted,
    required Function toggleMute,
    required double volume,
    required Function(double) onVolumeChanged,
    required IconData icon,
    required Color color,
    bool showTestButton = false,
    VoidCallback? onTest,
  }) {
    final audioManager = Provider.of<AudioManager>(context, listen: false);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 3,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: expanded,
          onExpansionChanged: (v) {
            audioManager.playEventSound("PopClick");
            onExpandChanged(v);
          },
          leading: CircleAvatar(
            backgroundColor: color.withAlpha(40),
            child: Icon(icon, color: color),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          trailing: Switch(
            value: !isMuted,
            onChanged: (_) {
              audioManager.playEventSound('toggleButton');
              toggleMute();
            },
            activeColor: color,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                      icon:
                      Icon(Icons.volume_down, color: isMuted ? Colors.grey : color),
                      onPressed: isMuted
                          ? null
                          : () {
                        audioManager.playEventSound('clickButton2');
                        onVolumeChanged((volume - 0.1).clamp(0.0, 1.0));
                      }),
                  Expanded(
                    child: Slider(
                      value: volume,
                      min: 0,
                      max: 1,
                      divisions: 10,
                      activeColor: color,
                      onChanged: isMuted ? null : (v) => onVolumeChanged(v),
                    ),
                  ),
                  Text(
                    "${(volume * 100).round()}%",
                    style: TextStyle(
                        color: isMuted ? Colors.grey : color, fontWeight: FontWeight.w500),
                  ),
                  IconButton(
                    icon: Icon(Icons.volume_up, color: isMuted ? Colors.grey : color),
                    onPressed: isMuted
                        ? null
                        : () {
                      audioManager.playEventSound('clickButton2');
                      onVolumeChanged((volume + 0.1).clamp(0.0, 1.0));
                    },
                  ),
                  if (showTestButton)
                    IconButton(
                      icon: Icon(Icons.play_arrow, color: color),
                      onPressed: isMuted ? null : onTest,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioManager = Provider.of<AudioManager>(context);
    final user = FirebaseAuth.instance.currentUser;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 100),
      backgroundColor: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                    tr(context).settings,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      audioManager.playEventSound('cancelButton');
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close, size: 26, color: Colors.grey),
                  ),
                ],
              ),
              const Divider(),
              // Content
              Expanded(
                child: ListView(
                  children: [
                    // === AUDIO SETTINGS ===
                    buildSectionTitle(tr(context).audioSettings),
                    buildVolumeControl(
                      title: tr(context).backgroundMusic,
                      expanded: bgExpanded,
                      onExpandChanged: (v) => setState(() => bgExpanded = v),
                      isMuted: audioManager.isBgMuted,
                      toggleMute: audioManager.toggleBgMute,
                      volume: audioManager.bgVolume,
                      onVolumeChanged: audioManager.setBgVolume,
                      icon: Icons.music_note,
                      color: Colors.deepOrange,
                    ),
                    buildVolumeControl(
                      title: tr(context).soundEffects,
                      expanded: sfxExpanded,
                      onExpandChanged: (v) => setState(() => sfxExpanded = v),
                      isMuted: audioManager.isSfxMuted,
                      toggleMute: audioManager.toggleSfxMute,
                      volume: audioManager.sfxVolume,
                      onVolumeChanged: audioManager.setSfxVolume,
                      icon: Icons.speaker,
                      color: Colors.blue,
                      showTestButton: true,
                      onTest: () => audioManager.playSfx(
                        'assets/audios/UI_Audio/SFX_Audio/MarimbaWin_SFX.mp3',
                      ),
                    ),
                    buildVolumeControl(
                      title: tr(context).buttonSounds,
                      expanded: buttonExpanded,
                      onExpandChanged: (v) => setState(() => buttonExpanded = v),
                      isMuted: audioManager.isButtonMuted,
                      toggleMute: audioManager.toggleButtonMute,
                      volume: audioManager.buttonVolume,
                      onVolumeChanged: audioManager.setButtonVolume,
                      icon: Icons.touch_app,
                      color: Colors.green,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label:  Text(tr(context).resetAudioSettings),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size(double.infinity, 45),
                        ),
                        onPressed: () => audioManager.resetAudioSettings(),
                      ),
                    ),

                    // === UI ELEMENTS ===
                    buildSectionTitle(tr(context).duaaAndAyat),
                    buildAyatCardToggle(
                      title: tr(context).showAyat,
                      expanded: ayatExpanded,
                      onExpandChanged: (v) => setState(() => ayatExpanded = v),
                      isEnabled: context.watch<CardVisibilityManager>().showAyatCard,
                      onToggle: (value) {
                        context.read<CardVisibilityManager>().toggleAyatCard(value);
                        audioManager.playEventSound('toggleButton');
                      },
                      content: tr(context).enableordisabletheAyatcardfromappearinginyourapp,
                      icon: Icons.menu_book,
                      color: Colors.orange,
                    ),

                    buildAyatCardToggle(
                      title: tr(context).showDuaa,
                      expanded: DuaaDialogExpanded,
                      onExpandChanged: (v) => setState(() => DuaaDialogExpanded = v),
                      isEnabled: context.watch<CardVisibilityManager>().showDuaaDialog,
                      onToggle: (value) {
                        context.read<CardVisibilityManager>().toggleDuaaDialog(value);
                        audioManager.playEventSound('toggleButton');
                      },
                      content: tr(context).enableorDisableDuaaEveryTimeYouEnter,
                      icon: Icons.border_outer,
                      color: Colors.deepOrange,
                    ),

                    // === ACCOUNT & BACKUP ===
                    buildSectionTitle(tr(context).accountAndBackup),
                    BackupCard(),

                    const SizedBox(height: 22),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.exit_to_app),
                      label:  Text(tr(context).close),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      onPressed: () {
                        audioManager.playEventSound("cancelButton");
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(height: 12),
                    Center(child: Text("${tr(context).version} $appVersion")),
                  ],
                )

              ),
            ],
          ),
        ),
      ),
    );
  }

  bool ayatExpanded = false; // collapsed by default
  bool DuaaDialogExpanded = false; // collapsed by default


  Widget buildAyatCardToggle({
    required String title,
    required bool expanded,
    required Function(bool) onExpandChanged,
    required bool isEnabled,
    required Function(bool) onToggle,
    required IconData icon,
    required Color color,
    required String content,
  }) {
    final audioManager = Provider.of<AudioManager>(context, listen: false);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 3,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: expanded,
          onExpansionChanged: (v) {
            audioManager.playEventSound("PopClick");
            onExpandChanged(v);
          },
          leading: CircleAvatar(
            backgroundColor: color.withAlpha(40),
            child: Icon(icon, color: color),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          trailing: Switch(
            value: isEnabled,
            onChanged: (value) {
              audioManager.playEventSound('toggleButton');
              onToggle(value);
            },
            activeColor: color,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
              content,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

}
