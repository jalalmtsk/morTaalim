import 'package:flutter/material.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:provider/provider.dart';
import '../../Manager/Services/CardVisibiltyManager.dart';

class DuaaDialog extends StatefulWidget {
  const DuaaDialog({Key? key}) : super(key: key);

  @override
  _DuaaDialogState createState() => _DuaaDialogState();
}

class _DuaaDialogState extends State<DuaaDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _buttonFadeAnimation;

  Map<String, dynamic> _getDuaaConfig() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return {
        'duaa': "🌅 Morning Duaa:\nالحمد لله الذي أحيانا بعدما أماتنا وإليه النشور",
        'icon': Icons.wb_sunny,
        'colors': [Colors.orange.shade200, Colors.orange.shade400],
      };
    } else if (hour >= 12 && hour < 18) {
      return {
        'duaa': "☀️ Afternoon Duaa:\nاللهم أعني على ذكرك وشكرك وحسن عبادتك",
        'icon': Icons.cloud,
        'colors': [Colors.blue.shade200, Colors.blue.shade400],
      };
    } else {
      return {
        'duaa': "🌙 Night Duaa:\nاللهم بك أمسينا وبك أصبحنا وبك نحيا وبك نموت وإليك المصير",
        'icon': Icons.nightlight_round,
        'colors': [Colors.indigo.shade200, Colors.indigo.shade400],
      };
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeInOut),
    );

    _textFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.7, curve: Curves.easeIn),
    );

    _buttonFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    // Delay the appearance by 800ms
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _getDuaaConfig();
    final audioManager = Provider.of<AudioManager>(context, listen: false);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: config['colors'],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: Icon(config['icon'], size: 48, color: Colors.white),
              ),
              const SizedBox(height: 16),
              FadeTransition(
                opacity: _textFadeAnimation,
                child: Text(
                  config['duaa'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _buttonFadeAnimation,
                child: Consumer<CardVisibilityManager>(
                  builder: (context, manager, _) => Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: !manager.showDuaaDialog,
                            onChanged: (value) {
                              audioManager.playEventSound('toggleButton');
                              manager.toggleDuaaDialog(!(value ?? false));
                            },
                            activeColor: Colors.white,
                            checkColor: Colors.black87,
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              tr(context).dontShowAgain,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            audioManager.playEventSound('cancelButton');
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            tr(context).awesome,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
