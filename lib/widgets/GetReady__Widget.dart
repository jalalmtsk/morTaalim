import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../tools/audio_tool/Audio_Manager.dart';


class GetReadyPage extends StatefulWidget {

  final VoidCallback onReadyComplete;
  const GetReadyPage({Key? key, required this.onReadyComplete}) : super(key: key);

  @override
  _GetReadyPageState createState() => _GetReadyPageState();
}

 class _GetReadyPageState extends State<GetReadyPage> {
   int countdown = 3;

  @override
  void initState() {
    super.initState();
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    audioManager.playSfx("assets/audios/QuizGame_Sounds/BeepCountDown3sec.mp3");
    _startCountdown();
  }

  void _startCountdown() {
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (countdown == 1) {
        timer.cancel();
        widget.onReadyComplete(); // call the callback to start the exercise
      }
      setState(() {
        countdown--;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Disable back button
      child: Scaffold(
        backgroundColor: Colors.deepPurple.shade50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/FirstTouchAnimations/BulbBook.json', // Add your Lottie animation
                width: 400,
                repeat: true,
              ),
              SizedBox(height: 20),
              Text(
                countdown > 0 ? '$countdown' : 'Go!',
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
