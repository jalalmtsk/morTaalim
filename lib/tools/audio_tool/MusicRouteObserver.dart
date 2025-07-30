import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../IndexPage.dart';
import '../../courses/primaire1Page/index_1PrimairePage.dart';
import '../../games/Quiz_Game/general_culture_game.dart';
import '../../games/paitingGame/indexDrawingPage.dart';
import 'Audio_Manager.dart';

final Map<Type, String> widgetMusicMap = {
  Index: 'assets/audios/sound_track/piano.mp3',
  DrawingIndex: 'assets/audios/sound_track/backGroundMusic8bit.mp3',
  QuizGameApp: 'assets/audios/sound_track/FoamRubber_BcG.mp3',
  index1Primaire: 'assets/audios/sound_track/SugarSprinkle_BcG.mp3',
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
