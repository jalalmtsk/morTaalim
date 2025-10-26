// tools/update_checker.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateChecker {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String collectionName;
  final String documentName;

  UpdateChecker({
    this.collectionName = 'app_settings',
    this.documentName = 'version',
  });

  /// Call this in your SplashScreen or main initState
  Future<void> checkForUpdate(BuildContext context) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version.trim();

      final doc = await firestore.collection(collectionName)
          .doc(documentName)
          .get();
      if (!doc.exists) return;

      final latestVersion = doc.get('latest_version')?.toString().trim() ?? '';
      final updateMessage =
          doc.get('update_message')?.toString() ??
              "A new version is available!";
      final androidUrl = doc.get('android_url')?.toString() ?? '';
      final iosUrl = doc.get('ios_url')?.toString() ?? '';
      final forceUpdate = doc.data()?['force_update'] ??
          true; // default to true

      debugPrint(
          "📦 Current app version: $currentVersion | 🔄 Latest: $latestVersion | ⛔ Force: $forceUpdate");

      if (latestVersion.isNotEmpty &&
          _isNewVersion(currentVersion, latestVersion)) {
        if (forceUpdate) {
          _showForceUpdatePage(context, updateMessage, androidUrl, iosUrl);
        } else {
          _showOptionalUpdatePage(context, updateMessage, androidUrl, iosUrl);
        }
      } else {
        debugPrint("✅ App is up to date: $currentVersion");
      }
    } catch (e) {
      debugPrint("❌ Update check failed: $e");
    }
  }

  bool _isNewVersion(String current, String latest) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final latestParts = latest.split('.').map(int.parse).toList();
      for (int i = 0; i < latestParts.length; i++) {
        final latestPart = latestParts[i];
        final currentPart = i < currentParts.length ? currentParts[i] : 0;
        if (latestPart > currentPart) return true;
        if (latestPart < currentPart) return false;
      }
      return false;
    } catch (e) {
      debugPrint("⚠️ Version parse error: $e");
      return latest.trim() != current.trim();
    }
  }

  void _showForceUpdatePage(BuildContext context, String message,
      String androidUrl, String iosUrl) {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.7),
        pageBuilder: (_, __, ___) =>
            _ForceUpdatePage(
              message: message,
              androidUrl: androidUrl,
              iosUrl: iosUrl,
              skippable: false,
            ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
          (route) => false,
    );
  }

  void _showOptionalUpdatePage(BuildContext context,
      String message,
      String androidUrl,
      String iosUrl,) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "UpdateDialog",
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, __, ___) {
        return Center(
          child: _OptionalUpdateDialog(
            message: message,
            androidUrl: androidUrl,
            iosUrl: iosUrl,
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim.value),
          child: Opacity(opacity: anim.value, child: child),
        );
      },
    );
  }
}

  class _ForceUpdatePage extends StatelessWidget {
  final String message;
  final String androidUrl;
  final String iosUrl;
  final bool skippable;

  const _ForceUpdatePage({
    Key? key,
    required this.message,
    required this.androidUrl,
    required this.iosUrl,
    this.skippable = false,
  }) : super(key: key);

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final platformUrl =
    Theme.of(context).platform == TargetPlatform.android ? androidUrl : iosUrl;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/UI/BackGrounds/bg10.jpg', fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.75), Colors.black.withOpacity(0.4)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 25),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Lottie.asset('assets/animations/rabbit_boat.json', width: 220, repeat: true),
                      const SizedBox(height: 14),
                      Text(
                        "🚀 Update Available!",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
                      ),
                      const SizedBox(height: 30),

                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrangeAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 10,
                        ),
                        icon: const Icon(Icons.system_update, color: Colors.white, size: 24),
                        label: const Text("Update Now",
                            style: TextStyle(color: Colors.white, fontSize: 18)),
                        onPressed: () => _openUrl(platformUrl),
                      ),
                      const SizedBox(height: 20),

                      if (skippable)
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Maybe Later",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      const SizedBox(height: 30),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSocialButton(
                            icon: FontAwesomeIcons.instagram,
                            color: Colors.pinkAccent,
                            onTap: () => _openUrl("https://www.instagram.com/moortaalim/"),
                          ),
                          const SizedBox(width: 40),
                          _buildSocialButton(
                            icon: FontAwesomeIcons.facebookF,
                            color: Colors.blueAccent,
                            onTap: () =>
                                _openUrl("https://web.facebook.com/profile.php?id=61580174915584"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Follow us for more updates ❤️",
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [color.withOpacity(0.9), color.withOpacity(0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(child: FaIcon(icon, color: Colors.white, size: 26)),
      ),
    );
  }
}



class _OptionalUpdateDialog extends StatelessWidget {
  final String message;
  final String androidUrl;
  final String iosUrl;
  final bool skippable;

  const _OptionalUpdateDialog({
    Key? key,
    required this.message,
    required this.androidUrl,
    required this.iosUrl,
    this.skippable = false,
  }) : super(key: key);

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final platformUrl =
    Theme.of(context).platform == TargetPlatform.android ? androidUrl : iosUrl;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/UI/BackGrounds/bg10.jpg', fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.75), Colors.black.withOpacity(0.4)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 25),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Lottie.asset('assets/animations/rabbit_boat.json', width: 220, repeat: true),
                      const SizedBox(height: 14),
                      Text(
                        "🚀 Update Available!",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
                      ),
                      const SizedBox(height: 30),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orangeAccent,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 10,
                            ),
                            icon: const Icon(Icons.download_rounded, color: Colors.white),
                            label: const Text(
                              "Update Now",
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            onPressed: () => _openUrl(platformUrl),
                          ),
                          const SizedBox(width: 10),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "Later",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (skippable)
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Maybe Later",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      const SizedBox(height: 30),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSocialButton(
                            icon: FontAwesomeIcons.instagram,
                            color: Colors.pinkAccent,
                            onTap: () => _openUrl("https://www.instagram.com/moortaalim/"),
                          ),
                          const SizedBox(width: 40),
                          _buildSocialButton(
                            icon: FontAwesomeIcons.facebookF,
                            color: Colors.blueAccent,
                            onTap: () =>
                                _openUrl("https://web.facebook.com/profile.php?id=61580174915584"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Follow us for more updates ❤️",
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [color.withOpacity(0.9), color.withOpacity(0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(child: FaIcon(icon, color: Colors.white, size: 26)),
      ),
    );
  }
}

