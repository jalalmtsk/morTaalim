import 'package:flutter/material.dart';

class AppTheme {
  final String name;
  final Color primaryColor;
  final Color backgroundColor;
  final Color textColor;
  final Color accentColor;
  final Gradient gradient;
  final String bannerImage;
  final String backgroundImage; // ✅ New field
  final double borderRadius;
  final BoxShadow boxShadow;
  final TextStyle headlineStyle;
  final TextStyle bodyStyle;
  final ButtonStyle buttonStyle;

  AppTheme({
    required this.name,
    required this.primaryColor,
    required this.backgroundColor,
    required this.textColor,
    required this.accentColor,
    required this.gradient,
    required this.bannerImage,
    required this.backgroundImage, // ✅ Required
    required this.borderRadius,
    required this.boxShadow,
    required this.headlineStyle,
    required this.bodyStyle,
    required this.buttonStyle,
  });
}


final List<AppTheme> appThemes = [
  // 1. Ocean Breeze 🌊
  AppTheme(
    name: "Ocean Breeze",
    primaryColor: Colors.blue.shade600,
    backgroundColor: Colors.blue.shade50,
    textColor: Colors.blueGrey.shade900,
    accentColor: Colors.cyanAccent,
    gradient: LinearGradient(colors: [Colors.blue.shade400, Colors.cyan.shade200]),
    bannerImage: "assets/banners/ocean.png",
    backgroundImage: "assets/images/UI/BackGrounds/bg6.jpg", // ✅
    borderRadius: 20,
    boxShadow: BoxShadow(color: Colors.blue.shade200, blurRadius: 12, spreadRadius: 2),
    headlineStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
    bodyStyle: TextStyle(fontSize: 16, color: Colors.blueGrey.shade700),
    buttonStyle: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue.shade600,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),

  // 2. Sunset Glow 🌅
  AppTheme(
    name: "Sunset Glow",
    primaryColor: Colors.deepOrange.shade400,
    backgroundColor: Colors.orange.shade50,
    textColor: Colors.brown.shade800,
    accentColor: Colors.amber,
    gradient: LinearGradient(colors: [Colors.deepOrange.shade400, Colors.pink.shade200]),
    bannerImage: "assets/banners/sunset.png",
    backgroundImage: "assets/images/UI/BackGrounds/bg6.jpg", // ✅
    borderRadius: 18,
    boxShadow: BoxShadow(color: Colors.orange.shade200, blurRadius: 10, spreadRadius: 2),
    headlineStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepOrange.shade700),
    bodyStyle: TextStyle(fontSize: 16, color: Colors.brown.shade700),
    buttonStyle: ElevatedButton.styleFrom(
      backgroundColor: Colors.deepOrange.shade400,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),

  // 3. Forest Green 🌲
  AppTheme(
    name: "Forest Green",
    primaryColor: Colors.green.shade700,
    backgroundColor: Colors.green.shade50,
    textColor: Colors.green.shade900,
    accentColor: Colors.tealAccent,
    gradient: LinearGradient(colors: [Colors.green.shade600, Colors.teal.shade200]),
    bannerImage: "assets/banners/forest.png",
    backgroundImage: "assets/images/UI/BackGrounds/bg8.jpg", // ✅
    borderRadius: 22,
    boxShadow: BoxShadow(color: Colors.green.shade200, blurRadius: 12, spreadRadius: 2),
    headlineStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green.shade800),
    bodyStyle: TextStyle(fontSize: 16, color: Colors.green.shade900),
    buttonStyle: ElevatedButton.styleFrom(
      backgroundColor: Colors.green.shade700,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  ),

  // 4. Royal Purple 👑
  AppTheme(
    name: "Royal Purple",
    primaryColor: Colors.deepPurple.shade500,
    backgroundColor: Colors.deepPurple.shade50,
    textColor: Colors.deepPurple.shade900,
    accentColor: Colors.purpleAccent,
    gradient: LinearGradient(colors: [Colors.deepPurple.shade400, Colors.purple.shade200]),
    bannerImage: "assets/banners/purple.png",
    backgroundImage: "assets/images/UI/BackGrounds/bg9.jpg", // ✅
    borderRadius: 20,
    boxShadow: BoxShadow(color: Colors.purple.shade200, blurRadius: 14, spreadRadius: 2),
    headlineStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple.shade700),
    bodyStyle: TextStyle(fontSize: 16, color: Colors.deepPurple.shade900),
    buttonStyle: ElevatedButton.styleFrom(
      backgroundColor: Colors.deepPurple.shade500,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  ),

  // 5. Elegant Dark 🌌
  AppTheme(
    name: "Elegant Dark",
    primaryColor: Colors.black,
    backgroundColor: Colors.grey.shade900,
    textColor: Colors.white,
    accentColor: Colors.blueAccent,
    gradient: LinearGradient(colors: [Colors.black87, Colors.grey.shade800]),
    bannerImage: "assets/banners/dark.png",
    backgroundImage: "assets/images/UI/BackGrounds/bg10.jpg", // ✅
    borderRadius: 16,
    boxShadow: BoxShadow(color: Colors.black45, blurRadius: 20, spreadRadius: 3),
    headlineStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
    bodyStyle: TextStyle(fontSize: 16, color: Colors.grey.shade300),
    buttonStyle: ElevatedButton.styleFrom(
      backgroundColor: Colors.blueAccent,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
];
