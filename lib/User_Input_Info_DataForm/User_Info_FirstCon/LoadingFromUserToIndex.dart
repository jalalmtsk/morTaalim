import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/IndexPage.dart';
import 'package:mortaalim/main.dart';

class LoadingFromUserToIndex extends StatefulWidget {
  const LoadingFromUserToIndex({Key? key}) : super(key: key);

  @override
  State<LoadingFromUserToIndex> createState() => _LoadingFromUserToIndexState();
}

class _LoadingFromUserToIndexState extends State<LoadingFromUserToIndex> {
  double progress = 0;

  @override
  void initState() {
    super.initState();
    // Simulate loading progress from 1 to 100 over 6 seconds
    Timer.periodic(const Duration(milliseconds: 90), (timer) {
      setState(() {
        progress += 100 / 100; // increments by 1%
      });
      if (progress >= 100) {
        timer.cancel();
        // Navigate after loading completes
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=> Index()));
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        backgroundColor: const Color(0xFFFDFCFB),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Lottie.asset(
                    'assets/animations/UI_Animations/CuteBrainMediating.json',
                    fit: BoxFit.contain,
                    repeat: true,
                    animate: true,
                  ),
                ),
                const SizedBox(height: 20),
                 Text(
                  "${tr(context).motivationalPhrase1}...",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: Colors.brown,
                  ),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Text(
                    "${progress.toInt()}%",
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.brown,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Lottie.asset(
                    'assets/animations/UI_Animations/MagicLoading.json',
                    width: 200,
                    height: 200,
                    repeat: true,
                    animate: true,
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
