import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Audio_Manager.dart';

class SfxVolumeSlider extends StatelessWidget {
  const SfxVolumeSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioManager>(
      builder: (context, audioManager, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sound Effects Volume: ${(audioManager.sfxVolume * 100).round()}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Slider(
              min: 0,
              max: 1,
              divisions: 10,
              value: audioManager.sfxVolume,
              label: '${(audioManager.sfxVolume * 100).round()}%',
              onChanged: (value) {
                audioManager.setSfxVolume(value);
              },
            ),
          ],
        );
      },
    );
  }
}
