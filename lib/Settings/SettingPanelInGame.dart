import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../tools/audio_tool/Audio_Manager.dart';

String appVersion = "1.0.0";

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

  @override
  Widget build(BuildContext context) {
    final audioManager = Provider.of<AudioManager>(context);

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
      required String type,
      bool showTestButton = false,
      VoidCallback? onTest,
    }) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 6),
        elevation: 2,
        child: ExpansionTile(
          initiallyExpanded: expanded,
          onExpansionChanged: onExpandChanged,
          leading: Icon(icon, color: color),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
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
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.volume_down, color: color),
                    onPressed: isMuted
                        ? null
                        : () => onVolumeChanged((volume - 0.1).clamp(0.0, 1.0)),
                  ),
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
                  Text("${(volume * 100).round()}%",
                      style: TextStyle(color: isMuted ? Colors.grey : color)),
                  IconButton(
                    icon: Icon(Icons.volume_up, color: color),
                    onPressed: isMuted
                        ? null
                        : () => onVolumeChanged((volume + 0.1).clamp(0.0, 1.0)),
                  ),
                  if (showTestButton)
                    IconButton(
                      icon: Icon(Icons.play_arrow, color: color),
                      onPressed: isMuted ? null : onTest,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 35, vertical: 80),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Settings",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () {
                    audioManager.playEventSound('cancelButton');
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close, size: 28),
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
                    type: 'bg',
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
                    type: 'sfx',
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
                    type: 'button',
                  ),
                  buildVolumeControl(
                    title: "Alerts & Notifications",
                    expanded: alertExpanded,
                    onExpandChanged: (v) => setState(() => alertExpanded = v),
                    isMuted: audioManager.isAlertMuted,
                    toggleMute: audioManager.toggleAlertMute,
                    volume: audioManager.alertVolume,
                    onVolumeChanged: audioManager.setAlertVolume,
                    icon: Icons.notifications,
                    color: Colors.purple,
                    type: 'alert',
                  ),
                  const SizedBox(height: 10),

                  // Reset Button
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text("Reset Audio Settings"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    onPressed: () => audioManager.resetAudioSettings(),
                  ),

                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.info_outline, color: Colors.blueGrey),
                    title: const Text("About App"),
                    subtitle: Text("Version $appVersion"),
                  ),
                  const SizedBox(height: 10),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('Close'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
