import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'Stories.dart';
import 'story_book_page.dart';

class StoriesGridPage extends StatefulWidget {
  final List<Story> stories;

  const StoriesGridPage({super.key, required this.stories});

  @override
  State<StoriesGridPage> createState() => _StoriesGridPageState();
}

class _StoriesGridPageState extends State<StoriesGridPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<Animation<double>> _animations = [];
  InterstitialAd? _interstitialAd;
  bool _isAdReady = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _loadInterstitialAd(); // 👈 Load it early

    // Create staggered animations for each item
    final count = widget.stories.length;
    for (int i = 0; i < count; i++) {
      final start = i / count;
      final end = (i + 1) / count;
      _animations.add(
        Tween<double>(begin: 50, end: 0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        ),
      );
    }
    _controller.forward();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-9936922975297046/8354774722', // ✅ your ad unit
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdReady = true;
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ Failed to preload interstitial ad: ${error.message}');
          _isAdReady = false;
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  DateTime? _lastAdTime;

  Widget _buildAnimatedItem(int index) {
    final story = widget.stories[index];
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offsetY = _animations[index].value;
        final opacity = (_controller.value - (index / widget.stories.length)) * widget.stories.length;
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, offsetY),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () async {
          final now = DateTime.now();
          final canShowAd = _isAdReady &&
              _interstitialAd != null &&
              (_lastAdTime == null || now.difference(_lastAdTime!) > const Duration(seconds: 10));

          if (canShowAd) {
            _lastAdTime = now;

            _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _interstitialAd = null;
                _isAdReady = false;
                _loadInterstitialAd(); // 👈 Preload next ad

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StoryBookPage(story: story)),
                );
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                _interstitialAd = null;
                _isAdReady = false;
                _loadInterstitialAd(); // 👈 Preload next ad

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StoryBookPage(story: story)),
                );
              },
            );

            _interstitialAd!.show();
            _interstitialAd = null;
            _isAdReady = false;

          } else {
            // Show loading spinner for a smoother transition
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const Center(
                child: CircularProgressIndicator(color: Colors.deepOrange),
              ),
            );

            await Future.delayed(const Duration(seconds: 1));
            Navigator.of(context).pop(); // Close the spinner

            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => StoryBookPage(story: story)),
            );
          }
        },

        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Local image
              Image.asset(
                story.thumbnail ?? 'assets/images/et.png',
                fit: BoxFit.cover,
              ),
              // Dark gradient overlay for readability
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black54, Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                padding: const EdgeInsets.all(8),
                alignment: Alignment.bottomCenter,
                child: Text(
                  story.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.arrow_back)),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed("FavoriteWords");
              },
              icon: const Icon(
                Icons.bookmark,
                color: Colors.white,
              ))
        ],
        title: const Text('Stories Library'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Column(
        children: [
          Container(
            height: 300,
            width: 400,
            margin: const EdgeInsets.all(10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                "assets/images/et.png",
                fit: BoxFit.cover,
                scale: 0.9,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.stories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 3 / 2,
              ),
              itemBuilder: (context, index) => _buildAnimatedItem(index),
            ),
          ),
        ],
      ),
    );
  }
}
