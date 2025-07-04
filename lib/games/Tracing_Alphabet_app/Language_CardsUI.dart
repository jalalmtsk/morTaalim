import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../XpSystem.dart';
import 'TracingAlphabetPage.dart';

class LanguageOption {
  final String name;
  final String languageCode;
  final IconData icon;
  final Color color;
  final bool locked;
  final int cost;

  LanguageOption({
    required this.name,
    required this.languageCode,
    required this.icon,
    required this.color,
    this.locked = false,
    this.cost = 10,
  });
}


class LanguageCard extends StatefulWidget {
  final LanguageOption language;

  const LanguageCard({super.key, required this.language});

  @override
  State<LanguageCard> createState() => _LanguageCardState();
}

class _LanguageCardState extends State<LanguageCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _scaleAnim = Tween<double>(begin: 0.9, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {

    final xpManager = Provider.of<ExperienceManager>(context, listen: false);
    final lang = widget.language;

    final isUnlocked = !lang.locked || xpManager.isLanguageUnlocked(lang.languageCode);

    if (isUnlocked) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AlphabetTracingPage(language: lang.languageCode),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Language Locked"),
          content: Text("Unlock ${lang.name} for ${lang.cost} ⭐?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (xpManager.stars >= lang.cost) {
                  xpManager.unlockLanguage(lang.languageCode, lang.cost);
                  Navigator.pop(context);
                  setState(() {}); // rebuild to reflect unlocked state
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Not enough stars!")),
                  );
                }
              },
              child: const Text("Unlock"),
            )
          ],
        ),
      );
    }

  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.language;
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTap: _onTap,
        child: Container(
          decoration: BoxDecoration(
            color: lang.color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: lang.color.withOpacity(0.5),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(lang.icon, size: 52, color: Colors.white),
                    if (lang.locked &&
                        !Provider.of<ExperienceManager>(context).isLanguageUnlocked(lang.languageCode))
                      const Positioned(
                        bottom: 0,
                        right: 0,
                        child: Icon(Icons.lock, color: Colors.white, size: 20),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  lang.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(blurRadius: 4, color: Colors.black38, offset: Offset(1, 1))
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                if (lang.locked &&
                    !Provider.of<ExperienceManager>(context).isLanguageUnlocked(lang.languageCode))
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, size: 18, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          "${lang.cost}",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
