import 'package:flutter/material.dart';

class MusicButton extends StatelessWidget {
  final bool isOn;
  final VoidCallback onPressed;

  const MusicButton({super.key, required this.isOn, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: isOn ? Icon(Icons.music_note, color:Colors.deepOrange) : Icon(Icons.music_off),
    );
  }
}
