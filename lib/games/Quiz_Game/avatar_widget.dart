import 'package:flutter/material.dart';

Widget avatarWithHighlight(String emoji, bool isActive) {
  return Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: isActive
          ? [BoxShadow(color: Colors.deepOrange, blurRadius: 12, spreadRadius: 2)]
          : [],
    ),
    child: CircleAvatar(
      radius: 30,
      backgroundColor: Colors.white,
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 30),
      ),
    ),
  );
}
