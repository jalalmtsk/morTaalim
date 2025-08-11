import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../XpSystem.dart';

class IstighfarReminderPage extends StatefulWidget {
  final ExperienceManager experienceManager;

  const IstighfarReminderPage({Key? key, required this.experienceManager}) : super(key: key);

  @override
  State<IstighfarReminderPage> createState() => _IstighfarReminderPageState();
}

class _IstighfarReminderPageState extends State<IstighfarReminderPage> {
  static const String _prefKeyToggle = 'istighfar_reminder_activated';
  bool _activated = false;
  late SharedPreferences _prefs;

  final Random _random = Random();

  final List<String> istighfarPhrases = [
    "أستغفر الله العظيم",
    "اللهم اغفر لي",
    "سبحان الله وبحمده",
    "رضيت بالله رباً وبالإسلام ديناً وبمحمد صلى الله عليه وسلم نبياً",
  ];

  final List<String> ayatList = [
    "رَبَّنَا ظَلَمْنَا أَنفُسَنَا وَإِن لَّمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ",
    "فَإِنَّ مَعَ الْعُسْرِ يُسْرًا",
    "وَاللَّهُ يُحِبُّ الْمُتَوَكِّلِينَ",
    "وَمَا تَوْفِيقِي إِلَّا بِاللَّهِ",
  ];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    widget.experienceManager.addListener(_onExperienceChanged);
  }

  @override
  void dispose() {
    widget.experienceManager.removeListener(_onExperienceChanged);
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _activated = _prefs.getBool(_prefKeyToggle) ?? false;
    });
  }

  void _onExperienceChanged() {
    // React to experience changes if needed
    // Example: could show notification if xp passes a threshold
  }

  Future<void> _toggleActivated(bool value) async {
    setState(() {
      _activated = value;
    });
    await _prefs.setBool(_prefKeyToggle, value);
  }

  void _showIstighfarModal() {
    // Choose randomly between Istighfar or Ayat
    bool showAyat = _random.nextBool();

    String textToShow = showAyat
        ? ayatList[_random.nextInt(ayatList.length)]
        : istighfarPhrases[_random.nextInt(istighfarPhrases.length)];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تذكير للاستغفار"),
        content: Text(
          textToShow,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("إغلاق"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("تذكير الاستغفار"),
        actions: [
          Row(
            children: [
              const Text("تشغيل", style: TextStyle(fontSize: 16)),
              Switch(
                value: _activated,
                onChanged: _toggleActivated,
                activeColor: Colors.orangeAccent,
              ),
            ],
          )
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Text(
              'XP: ${widget.experienceManager.xp}',
              style: const TextStyle(fontSize: 24),
            ),
          ),

          // Rounded banner at center-right
          if (_activated)
            Positioned(
              top: MediaQuery.of(context).size.height / 2 - 50,
              right: 8,
              child: GestureDetector(
                onTap: _showIstighfarModal,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orangeAccent.withOpacity(0.5),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.lightbulb_outline, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        "استغفر الآن",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}