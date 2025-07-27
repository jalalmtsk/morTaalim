import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart';

class ComingSoonNotPage extends StatelessWidget {
  final double iconSize = 34;

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Impossible d’ouvrir le lien $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Lottie.asset(
                  'assets/animations/languageSwitch_Animation.json',
                  width: 250,
                  repeat: true,
                ),
                const SizedBox(height: 20),
                Text(
                  'Bientôt disponible !',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[800],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Nous préparons quelque chose de génial 🤩',
                  style: TextStyle(fontSize: 18, color: Colors.teal[700]),
                ),
                const SizedBox(height: 30),
                Text(
                  'Suivez-nous sur les réseaux sociaux :',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: FaIcon(FontAwesomeIcons.instagram),
                      iconSize: iconSize,
                      color: Colors.purple,
                      onPressed: () => _launchUrl('https://instagram.com/YOUR_USERNAME'),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: FaIcon(FontAwesomeIcons.youtube),
                      iconSize: iconSize,
                      color: Colors.red,
                      onPressed: () => _launchUrl('https://youtube.com/@YOUR_CHANNEL'),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: FaIcon(FontAwesomeIcons.tiktok),
                      iconSize: iconSize,
                      color: Colors.black,
                      onPressed: () => _launchUrl('https://tiktok.com/@YOUR_USERNAME'),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Text(
                  'Merci pour votre patience ❤️',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
