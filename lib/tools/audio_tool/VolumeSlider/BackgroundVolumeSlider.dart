import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Audio_Manager.dart'; // Adjust import path

class BgVolumeSlider extends StatelessWidget {
  const BgVolumeSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioManager>(
      builder: (context, audioManager, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Background Music Volume: ${(audioManager.bgVolume * 100).round()}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Slider(
              min: 0,
              max: 1,
              divisions: 10,
              value: audioManager.bgVolume,
              label: '${(audioManager.bgVolume * 100).round()}%',
              onChanged: (value) {
                audioManager.setBgVolume(value);
              },
            ),
          ],
        );
      },
    );
  }
}
