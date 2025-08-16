import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'Credit_Data.dart';


class CreditsPage extends StatelessWidget {
  CreditsPage({super.key});

  // 🎵 Music Credits

  Future<void> _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildCreditCard(CreditItem credit, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 6,
      shadowColor: color.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    credit.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text("🎼 ${credit.artist}", style: const TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => _launchURL(credit.licenseUrl),
              child: Text(
                credit.license,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title, IconData icon, List<Color> colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(12),
      child: const Text(
        "© 2025 MoorTaalim. All rights reserved.",
        style: TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('Credits'),
        backgroundColor: Colors.deepOrange,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildHeader("Music Credits", Icons.library_music, [Colors.deepOrange, Colors.orangeAccent]),
          Expanded(
            child: ListView(
              children: [
                _buildHeader("BackGround Music", Icons.music_note, [Colors.orangeAccent, Colors.orangeAccent.shade200]),
                ...musicCredits.map((credit) => _buildCreditCard(credit, Icons.music_note, Colors.deepOrange)),
                const SizedBox(height: 20),
                _buildHeader("Sound Effects", Icons.surround_sound, [Colors.blue, Colors.lightBlueAccent]),
                ...sfxCredits.map((credit) => _buildCreditCard(credit, Icons.surround_sound, Colors.blue)),
                const SizedBox(height: 20),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
