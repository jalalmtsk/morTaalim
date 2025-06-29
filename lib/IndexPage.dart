import 'package:flutter/material.dart';
import 'package:mortaalim/courses/primaire1Page/index_1PrimairePage.dart';
import 'package:mortaalim/courses/primaire2Page/index_2PrimairePage.dart';
import 'package:mortaalim/courses/primaire3Page/3_primaire.dart';
import 'package:mortaalim/courses/primaire4Page/4_primaire.dart';
import 'package:mortaalim/courses/primaire5Page/5_primaire.dart';
import 'package:mortaalim/courses/primaire6Page/6_primaire.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mortaalim/tools/audio_tool.dart';




class Index extends StatefulWidget {
  final void Function(Locale) onChangeLocale;

  Index({required this.onChangeLocale});

  @override
  State<Index> createState() => _IndexState();
}

class _IndexState extends State<Index> {
  final MusicPlayer _musicPlayer = MusicPlayer();

  @override

  void initState() {
    // TODO: implement initState
    super.initState();
    _musicPlayer.play("assets/audios/intro_music.mp3", loop: true);
  }
  @override
  void dispose() {
    _musicPlayer.dispose(); // stop and release resources
    super.dispose();
  }
  @override
  final List<Map<String, dynamic>> HighCourse = [
    {
      'titleKey': 'class1',
      'widget': index1Primaire(),
      'icon': Icons.looks_one,
      'color': Colors.orangeAccent,
    },
    {
      'titleKey': 'class2',
      'widget': index2Primaire(),
      'icon': Icons.looks_two,
      'color': Colors.teal,
    },
    {
      'titleKey': 'class3',
      'widget': primaire3(),
      'icon': Icons.looks_3,
      'color': Colors.pinkAccent,
    },
    {
      'titleKey': 'class4',
      'widget': primaire4(),
      'icon': Icons.looks_4,
      'color': Colors.cyan,
    },
    {
      'titleKey': 'class5',
      'widget': primaire5(),
      'icon': Icons.looks_5,
      'color': Colors.indigo,
    },
    {
      'titleKey': 'class6',
      'widget': primaire6(),
      'icon': Icons.looks_6,
      'color': Colors.deepPurple,
    },
  ];
  bool musicisOn = true;
  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    clickedOnMusic()async{
      setState(() {
        musicisOn = !musicisOn;
      });
      if(musicisOn){
       await _musicPlayer.play("assets/audios/into.mp3");
      }else{
        await _musicPlayer.stop();
      }
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () => clickedOnMusic(),
        icon: Icon(musicisOn ?  Icons.music_note : Icons.music_off)),
        actions: [
          IconButton(onPressed: (){
          }, icon: Icon(Icons.add)),
          PopupMenuButton<Locale>(
      icon: const Icon(Icons.language_outlined, color: Colors.deepOrange, size: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      elevation: 8,
      tooltip: 'Change Language',
      onSelected: widget.onChangeLocale,
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<Locale>(
          value: const Locale("en"),
          child: Row(
            children: const [
              Text("🇺🇸", style: TextStyle(fontSize: 20)),
              SizedBox(width: 10),
              Text("English", style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
        PopupMenuItem<Locale>(
          value: const Locale("ar"),
          child: Row(
            children: const [
              Text("🇲🇦", style: TextStyle(fontSize: 20)),
              SizedBox(width: 10),
              Text("العربية", style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
        PopupMenuItem<Locale>(
          value: const Locale("fr"),
          child: Row(
            children: const [
              Text("🇫🇷", style: TextStyle(fontSize: 20)),
              SizedBox(width: 10),
              Text("Français", style: TextStyle(fontSize: 16)),
            ],
          ),
        ),

        PopupMenuItem<Locale>(
          value: const Locale("it"),
          child: Row(
            children: const [
              Text("🇮🇹", style: TextStyle(fontSize: 20)),
              SizedBox(width: 10),
              Text("Italiano", style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ],
    )]
    ),
      // Gradient background
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
              ElevatedButton(onPressed: (){
                _musicPlayer.play("assets/audios/intro_music.mp3");
              }, child: Text("Play Sound")),
              Text(tr.welcome,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrangeAccent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.chooseLevel,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  itemCount: HighCourse.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 18,
                    childAspectRatio: 4 / 3,
                  ),
                  itemBuilder: (context, index) {
                    final course = HighCourse[index];
                    return GestureDetector(
                      onTap: () {
                        _musicPlayer.stop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => course['widget'],
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: course['color'].withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: course['color'].withOpacity(0.3),
                              blurRadius: 12,
                              offset: Offset(2, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              course['icon'],
                              size: 48,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              course['titleKey'] == 'class1' ? tr.class1
                                  : course['titleKey'] == 'class2' ? tr.class2
                                  : course['titleKey'] == 'class3' ? tr.class3
                                  : course['titleKey'] == 'class4' ? tr.class4
                                  : course['titleKey'] == 'class5' ? tr.class5
                                  : tr.class6,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
