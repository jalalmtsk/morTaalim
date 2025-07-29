import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../XpSystem.dart';
import '../main.dart';
import '../tools/audio_tool/Audio_Manager.dart';

String appVersion = "1.0.0";

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final xpManager = Provider.of<ExperienceManager>(context);
    final audioManager = Provider.of<AudioManager>(context);

    void changeVolume({required String type, required bool increase}) {
      double delta = increase ? 0.1 : -0.1;
      switch (type) {
        case 'bg':
          audioManager.setBgVolume((audioManager.bgVolume + delta).clamp(0.0, 1.0));
          break;
        case 'sfx':
          audioManager.setSfxVolume((audioManager.sfxVolume + delta).clamp(0.0, 1.0));
          break;
        case 'button':
          audioManager.setButtonVolume((audioManager.buttonVolume + delta).clamp(0.0, 1.0));
          break;
      }
    }

    Widget buildVolumeControl({
      required String label,
      required bool isMuted,
      required VoidCallback onMuteToggle,
      required double volume,
      required ValueChanged<double> onVolumeChanged,
      required IconData icon,
      required Color color,
      required String type,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: Text('Mute $label'),
            value: isMuted,
            onChanged: (_) => onMuteToggle(),
            secondary: Icon(icon, color: color),
          ),
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
              SizedBox(width: 40, child: Text("${(volume * 100).round()}%", textAlign: TextAlign.center)),
              IconButton(
                icon: Icon(Icons.volume_up, color: color),
                onPressed: isMuted ? null : () => changeVolume(type: type, increase: true),
              ),
            ],
          ),
        ],
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 200),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Text('Settings', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),

            // Background Music
            buildVolumeControl(
              label: 'Background Music',
              isMuted: audioManager.isBgMuted,
              onMuteToggle: audioManager.toggleBgMute,
              volume: audioManager.bgVolume,
              onVolumeChanged: audioManager.setBgVolume,
              icon: Icons.music_note,
              color: Colors.deepOrange,
              type: 'bg',
            ),

            const Divider(),

            // SFX
            buildVolumeControl(
              label: 'SFX',
              isMuted: audioManager.isSfxMuted,
              onMuteToggle: audioManager.toggleSfxMute,
              volume: audioManager.sfxVolume,
              onVolumeChanged: audioManager.setSfxVolume,
              icon: Icons.speaker,
              color: Colors.blue,
              type: 'sfx',
            ),

            const Divider(),

            // Button sounds
            buildVolumeControl(
              label: 'Button Sounds',
              isMuted: audioManager.isButtonMuted,
              onMuteToggle: audioManager.toggleButtonMute,
              volume: audioManager.buttonVolume,
              onVolumeChanged: audioManager.setButtonVolume,
              icon: Icons.touch_app,
              color: Colors.purple,
              type: 'button',
            ),

            const Divider(height: 20),

            ListTile(
              title: Text(tr(context).progressReports),
              leading: const Icon(Icons.insert_chart),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(tr(context).progressReportsComingSoon)),
                );
              },
            ),

            const Divider(height: 20),
            SwitchListTile(
              title: const Text('Enable Ads'),
              value: context.watch<ExperienceManager>().adsEnabled,
              onChanged: (value) {
                context.read<ExperienceManager>().setAdsEnabled(value);
              },
            ),

            ListTile(
              title: Text(tr(context).rateApp),
              leading: const Icon(Icons.star_rate, color: Colors.amber),
            ),

            ListTile(
              title: Text(tr(context).aboutApp),
              subtitle: Text(appVersion),
              leading: const Icon(Icons.info_outline, color: Colors.blueGrey),
            ),

            const Divider(height: 32),

            ElevatedButton.icon(
              icon: const Icon(Icons.exit_to_app),
              label: const Text('Exit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: const Size(double.infinity, 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
