import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../tools/audio_tool/Audio_Manager.dart';

String appVersion = "1.0.0";

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  bool bgExpanded = false;
  bool sfxExpanded = false;
  bool buttonExpanded = false;
  bool alertExpanded = false;

  @override
  Widget build(BuildContext context) {
    final audioManager = Provider.of<AudioManager>(context);

    // Helper to change volume by +/- 10%
    void changeVolume({
      required String type,
      required bool increase,
    }) {
      const double step = 0.1;
      switch (type) {
        case 'bg':
          audioManager.playEventSound('clickButton2');
          audioManager.setBgVolume(
              (audioManager.bgVolume + (increase ? step : -step)).clamp(0.0, 1.0));
          break;
        case 'sfx':
          audioManager.playEventSound('clickButton2');
          audioManager.setSfxVolume(
              (audioManager.sfxVolume + (increase ? step : -step)).clamp(0.0, 1.0));
          break;
        case 'button':
          audioManager.playEventSound('clickButton2');
          audioManager.setButtonVolume(
              (audioManager.buttonVolume + (increase ? step : -step)).clamp(0.0, 1.0));
          break;
        case 'alert':
          audioManager.playEventSound('clickButton2');
          audioManager.setAlertVolume(
              (audioManager.alertVolume + (increase ? step : -step)).clamp(0.0, 1.0));
          break;
      }
    }

    // Widget to build each sound section
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
      return ExpansionTile(
        initiallyExpanded: expanded,
        onExpansionChanged: (expanded) {
          audioManager.playEventSound('clickButton');
          onExpandChanged(expanded);
        },
        leading: Icon(icon, color: color),
        title: Text(title),
        trailing: Switch(
          value: isMuted,
          onChanged: (_) {
            audioManager.playEventSound('toggleButton');
            toggleMute();
          },
          activeColor: color,
        ),
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.volume_down, color: color),
                onPressed: isMuted ? null : () => changeVolume(type: type, increase: false),
              ),
              Expanded(
                child: Slider(
                  value: volume,
                  onChanged: isMuted
                      ? null
                      : (value) {
                    final stepped = (value * 10).round() / 10;
                    onVolumeChanged(stepped);
                  },
                  min: 0,
                  max: 1,
                  divisions: 10,
                  activeColor: isMuted ? Colors.grey : color,
                  inactiveColor: Colors.grey[300],
                ),
              ),
              Text("${(volume * 100).round()}%",
                  style: TextStyle(
                      color: isMuted ? Colors.grey : color,
                      fontWeight: FontWeight.bold)),
              IconButton(
                icon: Icon(Icons.volume_up, color: color),
                onPressed: isMuted ? null : () => changeVolume(type: type, increase: true),
              ),
              if (showTestButton)
                IconButton(
                  icon: Icon(Icons.play_arrow, color: color),
                  tooltip: "Test",
                  onPressed: isMuted ? null : onTest,
                ),
            ],
          ),
        ],
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 120),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Title & Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Settings', style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  onPressed: () {
                    audioManager.playEventSound('cancelButton');
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.cancel, size: 30),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Settings List
            Expanded(
              child: ListView(
                children: [
                  // Background Music
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

                  // SFX
                  buildVolumeControl(
                    title: "SFX",
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
                    onTest: () => audioManager.playSfx('assets/audios/UI_Audio/SFX_Audio/MarimbaWin_SFX.mp3'),
                  ),

                  // Button Sounds
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
                    showTestButton: false,
                  ),

                  // Alerts
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
                    showTestButton: false,
                  ),

                  const Divider(),

                  // Reset Audio
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text("Reset Audio Settings"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      minimumSize: const Size(double.infinity, 40),
                    ),
                    onPressed: () => audioManager.resetAudioSettings(),
                  ),

                  const Divider(height: 30),

                  ListTile(
                    title: Text(tr(context).aboutApp),
                    subtitle: Text(appVersion),
                    leading: const Icon(Icons.info_outline, color: Colors.blueGrey),
                  ),

                  const SizedBox(height: 10),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('Close'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      minimumSize: const Size(double.infinity, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
