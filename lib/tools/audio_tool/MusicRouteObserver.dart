import 'package:flutter/material.dart';
import 'package:mortaalim/Shop/MainShopPageIndex.dart';
import 'package:provider/provider.dart';
import '../../IndexPage.dart';
import '../../courses/primaire1Page/index_1PrimairePage.dart';
import '../../games/Quiz_Game/ModeSelectorPage.dart';
import '../../games/Quiz_Game/quiz_Page.dart';
import '../../games/paitingGame/indexDrawingPage.dart';
import 'Audio_Manager.dart';

final Map<Type, String> widgetMusicMap = {
  Index: 'assets/audios/BackGround_Audio/IndexBackGroundMusic_BCG.mp3',
  MainShopPageIndex : 'assets/audios/BackGround_Audio/CuteBabyMusic2_BCG.mp3',
  DrawingIndex: 'assets/audios/BackGround_Audio/CuteBabyMusic2_BCG.mp3',
  QuizGameApp: 'assets/audios/BackGround_Audio/FunnyHappyMusic.mp3',
  Index1Primaire: 'assets/audios/BackGround_Audio/CuteBabyMusic2_BCG.mp3',
};

class MusicRouteObserver extends NavigatorObserver {
  void _handleMusic(Route<dynamic>? route) {
    if (route is MaterialPageRoute) {
      final widget = route.builder(route.navigator!.context);
      final musicPath = widgetMusicMap[widget.runtimeType];

      if (musicPath != null) {
        final audio = Provider.of<AudioManager>(route.navigator!.context, listen: false);

        // ✅ Only play if music is different
        if (audio.currentBgMusic != musicPath) {
          audio.playBackgroundMusic(musicPath);
        }
      }
    }
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    _handleMusic(route);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    _handleMusic(previousRoute); // Resume previous screen music without restarting
  }
}
