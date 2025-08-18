import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mortaalim/games/AnimalSound/AnimalSound_ListenMode.dart';
import 'package:mortaalim/games/AnimalSound/AnimalSound_GuessTheSound.dart';
import 'package:mortaalim/games/AnimalSound/MatchTheSound_Mode/AnimalSound_MatchAndDrop.dart';

import '../../tools/Ads_Manager.dart';

class AnimalsoundIndex extends StatefulWidget {
  @override
  State<AnimalsoundIndex> createState() => _AnimalsoundIndexState();
}

class _AnimalsoundIndexState extends State<AnimalsoundIndex> {
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    AdHelper.initializeAds();

    // Load banner ad
    _bannerAd = AdHelper.getBannerAd(() {
      setState(() => _isBannerLoaded = true);
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _handleGameTap(Widget page) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.deepOrange),
      ),
    );

    // Load & show interstitial ad
    await AdHelper.showInterstitialAd(onDismissed: () {
      Navigator.of(context).pop(); // Close loading dialog
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => page),
      );
    });

    // Ensure loading dialog is closed if ad fails to load
    if (Navigator.canPop(context)) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🐾 Animal Sound Game'),
        centerTitle: true,
        backgroundColor: Colors.green[700],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade100, Colors.green.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GameModeCard(
                        title: '🎧 Listen Mode',
                        description: 'Tap animals to hear their sounds!',
                        color: Colors.orangeAccent,
                        onTap: () => _handleGameTap(ListenMode()),
                      ),
                      const SizedBox(height: 20),
                      GameModeCard(
                        title: '❓ Guess the Sound',
                        description: 'Listen and select the correct animal!',
                        color: Colors.lightBlueAccent,
                        onTap: () => _handleGameTap(GuessSound()),
                      ),
                      const SizedBox(height: 20),
                      GameModeCard(
                        title: '🖐 Match & Drop',
                        description: 'Drag animals to match their sounds!',
                        color: Colors.pinkAccent,
                        onTap: () => _handleGameTap(AS_MatchDrop()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Banner Ad
          if (_isBannerLoaded && _bannerAd != null)
            Container(
              color: Colors.transparent,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }
}

class GameModeCard extends StatelessWidget {
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const GameModeCard({
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.pets,
              size: 50,
              color: Colors.white,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(height: 5),
                  Text(description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      )),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
            )
          ],
        ),
      ),
    );
  }
}
