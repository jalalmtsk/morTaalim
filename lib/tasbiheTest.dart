import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class TasbihApp extends StatefulWidget {
  const TasbihApp({super.key});

  @override
  State<TasbihApp> createState() => _TasbihAppState();
}

class _TasbihAppState extends State<TasbihApp> {
  bool _isDarkMode = false;

  void toggleTheme(bool isDark) {
    setState(() {
      _isDarkMode = isDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tasbih Counter',
      theme: _isDarkMode
          ? ThemeData.dark().copyWith(
        primaryColor: Colors.deepOrange,
        scaffoldBackgroundColor: Colors.black,
        progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: Colors.deepOrange),
      )
          : ThemeData(
        primarySwatch: Colors.deepOrange,
        scaffoldBackgroundColor: Colors.orange.shade50,
      ),
      home: TasbihHomePage(
        isDarkMode: _isDarkMode,
        onThemeChanged: toggleTheme,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TasbihHomePage extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const TasbihHomePage({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<TasbihHomePage> createState() => _TasbihHomePageState();
}

class _TasbihHomePageState extends State<TasbihHomePage>
    with SingleTickerProviderStateMixin {
  int _count = 0;
  int _goal = 33;
  bool _celebrating = false;
  late SharedPreferences _prefs;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  List<int> _history = [];
  String _currentDhikr = "";

  final List<String> _dhikrList = [
    "سُبْحَانَ الله",
    "الْحَمْدُ لِلَّه",
    "اللَّهُ أَكْبَر",
    "لَا إِلَهَ إِلَّا اللَّه",
    "أَسْتَغْفِرُ اللَّه",
    "سُبْحَانَ اللهِ وَبِحَمْدِهِ سُبْحَانَ اللهِ الْعَظِيم"
  ];

  @override
  void initState() {
    super.initState();
    _loadPrefs();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.05)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _scaleAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
  }

  Future<void> _loadPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _count = _prefs.getInt('count') ?? 0;
      _goal = _prefs.getInt('goal') ?? 33;
      _history = _prefs.getStringList('history')?.map(int.parse).toList() ?? [];
      widget.onThemeChanged(_prefs.getBool('darkMode') ?? false);
      _currentDhikr = _dhikrList[Random().nextInt(_dhikrList.length)];
    });
  }

  Future<void> _savePrefs() async {
    await _prefs.setInt('count', _count);
    await _prefs.setInt('goal', _goal);
    await _prefs.setStringList('history', _history.map((e) => e.toString()).toList());
    await _prefs.setBool('darkMode', widget.isDarkMode);
  }

  Future<void> _incrementCount() async {
    if (_count < _goal) {
      setState(() {
        _count++;
      });
      _controller.forward(from: 0);

      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 20);
      }
    }
    if (_count == _goal) {
      _celebrate();
      _history.add(_goal);
      _savePrefs();
    }
    _savePrefs();
  }

  void _celebrate() {
    setState(() {
      _celebrating = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _celebrating = false;
      });
    });
  }

  void _resetCount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Counter?'),
        content: const Text('Are you sure you want to reset your count?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: const Text('Reset'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _history.add(_count);
        _count = 0;
      });
      _savePrefs();
    }
  }

  void _changeGoal(double value) {
    setState(() {
      _goal = value.toInt();
      if (_count > _goal) _count = _goal;
    });
    _savePrefs();
  }

  void _nextDhikr() {
    setState(() {
      _currentDhikr = _dhikrList[Random().nextInt(_dhikrList.length)];
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildBeads() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: List.generate(
        33,
            (index) => Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: index < _count ? Colors.deepOrange : Colors.grey[400],
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 2,
                offset: const Offset(1, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double progress = _count / _goal;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasbih Counter'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
            onPressed: () {
              widget.onThemeChanged(!widget.isDarkMode);
              _prefs.setBool('darkMode', !widget.isDarkMode);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetCount,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Daily Dhikr
            Card(
              elevation: 4,
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text("Daily Dhikr",
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(
                      _currentDhikr,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _nextDhikr,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Next Dhikr"),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Beads
            _buildBeads(),
            const SizedBox(height: 20),

            // Circular progress
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 14,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                  ),
                ),
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: GestureDetector(
                    onTap: _incrementCount,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.7),
                            blurRadius: 15,
                            spreadRadius: 1,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$_count',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Slider(
              value: _goal.toDouble(),
              min: 10,
              max: 100,
              divisions: 90,
              label: '$_goal',
              onChanged: _changeGoal,
            ),

            const SizedBox(height: 20),

            // History
            if (_history.isNotEmpty)
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("History",
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ..._history.reversed.take(5).map((h) => Text("✔️ $h Tasbihs completed")),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
