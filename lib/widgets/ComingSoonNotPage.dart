import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mortaalim/main.dart';
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
      backgroundColor: Colors.black.withValues(alpha: 0.2),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Lottie.asset(
                  'assets/animations/UI_Animations/UnderMaintenance.json',
                  width: 250,
                  repeat: true,
                ),
                const SizedBox(height: 20),
                Text(
                  '${tr(context).comingSoon} !',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "${tr(context).weArePreparingSomethingAwesome} 🤩",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                const SizedBox(height: 30),
                Text(
                  "${tr(context).followUsOnSocialMedia} :",
                  style: TextStyle(fontSize: 16, color: Colors.white),
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
                  "${tr(context).thankYouForYourPatience} ❤️",
                  style: TextStyle(fontSize: 14, color: Colors.white),
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
