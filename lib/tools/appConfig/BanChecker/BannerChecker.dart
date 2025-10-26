// tools/banner_checker.dart
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
class BannerChecker {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Returns true if user is banned and banner was shown
  Future<bool> checkAndShowBanner(BuildContext context, String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return false;

      final data = doc.data();
      final isLocked = data?['isLocked'] ?? false;

      if (isLocked && context.mounted) {
        await _showBannerPage(
          context,
          "Your account has been locked by the admin.",
          null,
          null,
        );
        return true; // Banner was shown, user is banned
      }
      return false; // Not banned
    } catch (e) {
      if (kDebugMode) print("Error checking banner: $e");
      return false;
    }
  }

  Future<void> _showBannerPage(
      BuildContext context,
      String message,
      String? lottieAsset,
      String? url,
      ) async {
    await Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.7),
        pageBuilder: (_, __, ___) => _BannerPage(
          message: message,
          lottieAsset: lottieAsset,
          url: url,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
          (route) => false,
    );
  }
}


class _BannerPage extends StatelessWidget {
  final String message;
  final String? lottieAsset;
  final String? url;
  final String contactEmail;

  const _BannerPage({
    Key? key,
    required this.message,
    this.lottieAsset,
    this.url,
    this.contactEmail = "jalnixstudio@gmail.com",
  }) : super(key: key);

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/UI/BackGrounds/bannedBg.png',
            fit: BoxFit.cover,
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black87, Colors.black54],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      border: Border.all(color: Colors.white.withOpacity(0.25)),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 25,
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (lottieAsset != null)
                            Lottie.asset(lottieAsset!, width: 220, repeat: true),
                          const SizedBox(height: 20),
                          Text(
                            "📢 Important Notice",
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 17,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 30),
                          if (url != null)
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.deepOrangeAccent,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 40, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              onPressed: () => _openUrl(url),
                              icon: const Icon(Icons.link, color: Colors.white),
                              label: const Text(
                                "Open Link",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          const SizedBox(height: 40),
                          Divider(color: Colors.white.withOpacity(0.3)),
                          const SizedBox(height: 10),
                          Text(
                            "If you believe this is an error, please contact us:",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () async {
                              final uri = Uri(
                                scheme: 'mailto',
                                path: contactEmail,
                              );
                              await launchUrl(uri);
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.email_outlined,
                                    color: Colors.deepOrangeAccent),
                                const SizedBox(width: 8),
                                Text(
                                  contactEmail,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 25),
                          TextButton(
                            onPressed: () => SystemNavigator.pop(),
                            child: const Text(
                              "Dismiss",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
