import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart'; // to access navigatorKey and audioManager

class AppLifecycleManager extends StatefulWidget {
  final Widget child;

  const AppLifecycleManager({Key? key, required this.child}) : super(key: key);

  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager> with WidgetsBindingObserver {
  Timer? _resetTimer;
  bool _shouldRestart = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resetTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _resetTimer?.cancel();

      // 60 SECONDS TO GO TO SPLASH SCREEN AND REBUILD UI
      _resetTimer = Timer(const Duration(seconds: 60), () {
        _shouldRestart = true;
      });
    } else if (state == AppLifecycleState.resumed) {
      _resetTimer?.cancel();

      if (_shouldRestart) {
        _shouldRestart = false;

        // Stop background music before restart
        audioManager.stopMusic();

        // Restart app from splash, clearing history
        navigatorKey.currentState?.pushNamedAndRemoveUntil('Splash', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
