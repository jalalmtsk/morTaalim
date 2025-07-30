import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CreditItem {
  final String title;
  final String artist;
  final String license;
  final String licenseUrl;

  CreditItem({
    required this.title,
    required this.artist,
    required this.license,
    required this.licenseUrl,
  });
}

class CreditsPage extends StatelessWidget {
  CreditsPage({super.key});

  // 🎵 Music Credits
  final List<CreditItem> musicCredits = [
    CreditItem(
      title: 'Happy Happy Game Show',
      artist: 'Kevin MacLeod (incompetech.com)',
      license: 'Creative Commons: By Attribution 4.0',
      licenseUrl: 'http://creativecommons.org/licenses/by/4.0/',
    ),
    CreditItem(
      title: 'Daisy',
      artist: 'Sakura Girl (SoundCloud)',
      license: 'Creative Commons: By Attribution 3.0',
      licenseUrl: 'https://creativecommons.org/licenses/by/3.0/',
    ),
    CreditItem(
      title: 'Upbeat Background Music',
      artist: 'Andrii Poradovskyi (Pixabay)',
      license: 'Pixabay License',
      licenseUrl: 'https://pixabay.com/music/',
    ),
    CreditItem(
      title: 'Index Theme',
      artist: 'Cyberwave Orchestra (Pixabay)',
      license: 'Pixabay License',
      licenseUrl: 'https://pixabay.com/music/',
    ),
    CreditItem(
      title: 'Happy Vibes',
      artist: 'SunnyVibesAudio (Pixabay)',
      license: 'Pixabay License',
      licenseUrl: 'https://pixabay.com/music/',
    ),
  ];

  // 🔊 SFX Credits
  // Updated SFX Credits List (only the list part):

  final List<CreditItem> sfxCredits = [
    CreditItem(
      title: 'Various Effects',
      artist: 'floraphonic (Pixabay)',
      license: 'Pixabay License',
      licenseUrl: 'https://pixabay.com/sound-effects/',
    ),
    CreditItem(
      title: 'Button Clicks',
      artist: 'freesound_community (Pixabay)',
      license: 'Pixabay License',
      licenseUrl: 'https://pixabay.com/sound-effects/',
    ),
    CreditItem(
      title: 'Game Effects',
      artist: 'u_it78ck90s3 (Pixabay)',
      license: 'Pixabay License',
      licenseUrl: 'https://pixabay.com/sound-effects/',
    ),
    CreditItem(
      title: 'Win Effect',
      artist: 'Nussaraporn Haleebut (Pixabay)',
      license: 'Pixabay License',
      licenseUrl: 'https://pixabay.com/sound-effects/',
    ),
    CreditItem(
      title: 'Error Sound',
      artist: 'Benjamin Adams (Pixabay)',
      license: 'Pixabay License',
      licenseUrl: 'https://pixabay.com/sound-effects/',
    ),
    CreditItem(
      title: 'Notification',
      artist: 'Universfield (Pixabay)',
      license: 'Pixabay License',
      licenseUrl: 'https://pixabay.com/sound-effects/',
    ),
    CreditItem(
      title: 'Magic Effect',
      artist: 'Paul (PWLPL) (Pixabay)',
      license: 'Pixabay License',
      licenseUrl: 'https://pixabay.com/sound-effects/',
    ),
    CreditItem(
      title: 'Menu Select',
      artist: 'Koi Roylers (Pixabay)',
      license: 'Pixabay License',
      licenseUrl: 'https://pixabay.com/sound-effects/',
    ),

    // New button sounds
    CreditItem(
      title: 'Button Sound Effect',
      artist: 'Rusu Gabriel (Pixabay)',
      license: 'Pixabay License',
      licenseUrl: 'https://pixabay.com/sound-effects/',
    ),
    CreditItem(
      title: 'Button Sound Effect',
      artist: 'Rusu Gabriel (Pixabay)',
      license: 'Pixabay License',
      licenseUrl: 'https://pixabay.com/sound-effects/',
    ),
    CreditItem(
      title: 'Button Sound Effect',
      artist: 'มัลวาร์ มะดีเยาะ (Pixabay)',
      license: 'Pixabay License',
      licenseUrl: 'https://pixabay.com/sound-effects/',
    ),
    CreditItem(
      title: 'Button Sound Effect',
      artist: 'floraphonic (Pixabay)',
      license: 'Pixabay License',
      licenseUrl: 'https://pixabay.com/sound-effects/',
    ),
    CreditItem(
      title: 'Button Sound Effect',
      artist: 'floraphonic (Pixabay)',
      license: 'Pixabay License',
      licenseUrl: 'https://pixabay.com/sound-effects/',
    ),
    CreditItem(
      title: 'Button Sound Effect',
      artist: 'floraphonic (Pixabay)',
      license: 'Pixabay License',
      licenseUrl: 'https://pixabay.com/sound-effects/',
    ),
  ];


  Future<void> _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildCreditCard(CreditItem credit, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 6,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
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
