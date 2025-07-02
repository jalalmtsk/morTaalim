import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingPage extends StatefulWidget {
  final Future<void> loadingFuture;
  final String nextRouteName;

  const LoadingPage({
    super.key,
    required this.loadingFuture,
    required this.nextRouteName,
  });

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  void initState() {
    super.initState();

    widget.loadingFuture.then((_) {
      Navigator.of(context).pushReplacementNamed(widget.nextRouteName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // match your app theme
      body: Center(
        child: Lottie.asset(
          'assets/animations/hand_animation.json',
          width: 350,
          height: 350,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}


class FadeRoute extends PageRouteBuilder {
  final Widget page;
  FadeRoute({required this.page})
      : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
