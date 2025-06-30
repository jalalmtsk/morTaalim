import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mortaalim/indexPage_tools/course_data.dart';
import 'package:mortaalim/indexPage_tools/course_grid.dart';
import 'package:mortaalim/indexPage_tools/language_menu.dart';
import 'package:mortaalim/indexPage_tools/music_button.dart';
import 'package:mortaalim/tools/audio_tool.dart';


class Index extends StatefulWidget {
  final void Function(Locale) onChangeLocale;
  const Index({super.key, required this.onChangeLocale});

  @override
  State<Index> createState() => _IndexState();
}
bool musicisOn = true;

class _IndexState extends State<Index> {
  final MusicPlayer _musicPlayer = MusicPlayer();

  @override
  void initState() {
    super.initState();
    _musicPlayer.play("assets/audios/intro_music.mp3", loop: true);
  }

  @override
  void dispose() {
    _musicPlayer.dispose();
    super.dispose();
  }

  void toggleMusic() async {
    setState(() {
      musicisOn = !musicisOn;
    });
    if (musicisOn) {
      await _musicPlayer.play("assets/audios/intro_music.mp3", loop: true);
    } else {
      await _musicPlayer.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    if (tr == null) {
      return Center(child: Text('Localization data not loaded'));
    }
    return Scaffold(
      appBar: AppBar(
        leading: MusicButton(isOn: musicisOn, onPressed: toggleMusic),
        actions: [LanguageMenu(onChangeLocale: widget.onChangeLocale)],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xfff8fafc), Color(0xfffcefe6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr.welcome,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrangeAccent)),
              const SizedBox(height: 8),
              Text(tr.chooseLevel,
                  style: TextStyle(fontSize: 18, color: Colors.grey[700])),
              const SizedBox(height: 20),
              Expanded(
                child: CourseGrid(
                    highCourses: highCourses, musicPlayer: _musicPlayer),
              ),
              ElevatedButton(onPressed: (){
  Navigator.of(context).pushReplacementNamed('DrawingAlphabet');
              }, child: Text("DrawingAlphabet")),

              ElevatedButton(onPressed: (){
                Navigator.of(context).pushReplacementNamed('QuizGameApp');
              }, child: Text("Quiz Game")),

              ElevatedButton(onPressed: (){
                Navigator.of(context).pushReplacementNamed('AppStories');
              }, child: Text("App Stories")),

              ElevatedButton(onPressed: (){
                Navigator.of(context).pushReplacementNamed('SpotTheDifference');
              }, child: Text("Spot The Difference")),


            ],
          ),
        ),
      ),
    );
  }
}
