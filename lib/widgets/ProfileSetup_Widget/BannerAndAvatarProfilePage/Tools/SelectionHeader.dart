import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(width: 2),
        Text(
            textAlign: TextAlign.center,
            title,
            style: TextStyle(fontSize: 22, color: Colors.white)
        ),
      ],
    );
  }
}
