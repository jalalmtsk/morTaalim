import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Authentification/BackUp/BackUpPage.dart';
import '../XpSystem.dart';
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
              color: Colors.black.withOpacity(0.2),
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
                  const Text(
                    "Settings",
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
                    buildVolumeControl(
                      title: "Background Music",
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
                      title: "Sound Effects",
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
                          'assets/audios/UI_Audio/SFX_Audio/MarimbaWin_SFX.mp3'),
                    ),
                    buildVolumeControl(
                      title: "Button Sounds",
                      expanded: buttonExpanded,
                      onExpandChanged: (v) => setState(() => buttonExpanded = v),
                      isMuted: audioManager.isButtonMuted,
                      toggleMute: audioManager.toggleButtonMute,
                      volume: audioManager.buttonVolume,
                      onVolumeChanged: audioManager.setButtonVolume,
                      icon: Icons.touch_app,
                      color: Colors.green,
                    ),
                   /* buildVolumeControl(
                      title: "Alerts & Notifications",
                      expanded: alertExpanded,
                      onExpandChanged: (v) => setState(() => alertExpanded = v),
                      isMuted: audioManager.isAlertMuted,
                      toggleMute: audioManager.toggleAlertMute,
                      volume: audioManager.alertVolume,
                      onVolumeChanged: audioManager.setAlertVolume,
                      icon: Icons.notifications,
                      color: Colors.purple,
                    ),*/
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text("Reset Audio Settings"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      onPressed: () => audioManager.resetAudioSettings(),
                    ),
                    const SizedBox(height: 16),

                    GoogleAccountCard(
                      onDisconnectCallback: () {
                        setState(() {});
                      },
                    ),

                    BackupCard(),
                    const SizedBox(height: 22),

                    ElevatedButton.icon(
                        icon: const Icon(Icons.exit_to_app),
                        label: const Text('Close'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size(double.infinity, 45),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        }),
                    const SizedBox(height: 12),

                    Center(child: Text("Version $appVersion")),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
