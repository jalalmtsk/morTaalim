import 'package:flutter/material.dart';

import 'm1_kit.dart';
import 'm1_shell.dart';
import 'sc_play.dart';

// Sciences — 1re année primaire: the world and its five games.

const scWorld = M1World(
  id: 'science',
  games: _scienceGames,
  subject: 'science',
  homeBg: 'sc_bg_home',
  homeSign: 'sc_sign_wood',
  homeBack: 'sc_btn_back',
  homeSound: 'sc_btn_sound',
  footerSprite: 'sc_plank_label',
  mapBg: 'sc_bg_map',
  mapMascot: 'sc_robot_straw',
  endBg: 'sc_bg_end',
  mapRatio: 719 / 720,
  mapPath: [
    Offset(0.128, 0.074), Offset(0.313, 0.151), Offset(0.34, 0.314), Offset(0.571, 0.509),
    Offset(0.81, 0.571), Offset(0.65, 0.713), Offset(0.305, 0.748), Offset(0.561, 0.89),
  ],
);
List<M1Game> _scienceGames() => scGames;

Widget _pic(String s, double size) => Image.asset(m1(s), height: size, fit: BoxFit.contain);

final List<M1Game> scGames = [
  M1Game(
    id: 'senses',
    world: scWorld,
    menuSign: 'sc_sign_leafy4',
    playSign: 'sc_sign_leafy3',
    back: 'sc_btn_back_pp',
    sound: 'sc_btn_sound',
    playButton: 'btn_play',
    modes: const ['discover', 'match', 'missions'],
    ranges: const [0, 1, 2],
    rangeStyle: M1RangeStyle.stars,
    tabIcon: 'sc_ic_eye',
    helpIcons: const ['sc_robot_listen', 'sc_s_eye', 'sc_s_hand'],
    checkIcons: const ['sc_ic_leaf', 'sc_ic_mag', 'sc_ic_bulb'],
    robot: 'sc_robot_listen',
    modeIcon: (m, s) => _pic(const ['sc_bird_song', 'sc_c_eye', 'sc_robot_ladybug'][m], s * 0.9),
    play: (lv) => ScSensesPlay(lv: lv),
  ),
  M1Game(
    id: 'seed',
    world: scWorld,
    menuSign: 'sc_sign_leafy2',
    playSign: 'sc_sign_leafy',
    back: 'sc_btn_back_teal',
    sound: 'sc_btn_sound_teal',
    playButton: 'btn_play_leaf',
    modes: const ['observe', 'order', 'care'],
    ranges: const [0, 1, 2],
    rangeStyle: M1RangeStyle.stars,
    tabIcon: 'sc_ic_sprout',
    helpIcons: const ['sc_ic_observe', 'sc_soil_root', 'sc_can'],
    checkIcons: const ['sc_ic_leaf', 'sc_ic_mag', 'sc_ic_bulb'],
    robot: 'sc_robot_farmer',
    modeIcon: (m, s) => _pic(const ['sc_ic_observe', 'sc_germ_strip', 'sc_can'][m], m == 1 ? s * 0.5 : s * 0.85),
    play: (lv) => ScSeedPlay(lv: lv),
  ),
  M1Game(
    id: 'habitat',
    world: scWorld,
    menuSign: 'sc_sign_purple',
    playSign: 'sc_sign_leafp',
    back: 'sc_btn_back_leaf',
    sound: 'sc_btn_sound_leaf',
    playButton: 'btn_play',
    modes: const ['discover', 'match', 'missions'],
    ranges: const [0, 1, 2],
    rangeStyle: M1RangeStyle.stars,
    tabIcon: 'sc_ic_paw',
    helpIcons: const ['sc_a_frog', 'sc_hab_forest', 'sc_ic_match'],
    checkIcons: const ['sc_ic_leaf', 'sc_ic_mag', 'sc_ic_bulb'],
    robot: 'sc_robot_explorer',
    modeIcon: (m, s) => _pic(const ['sc_a_frog', 'sc_ic_match', 'sc_paws'][m], s * 0.85),
    play: (lv) => ScHabitatPlay(lv: lv),
  ),
  M1Game(
    id: 'weather',
    world: scWorld,
    menuSign: 'sc_sign_cloud2',
    playSign: 'sc_sign_cloud',
    back: 'sc_btn_back',
    sound: 'sc_btn_sound',
    playButton: 'btn_play',
    modes: const ['recognize', 'observe', 'dress'],
    ranges: const [0, 1, 2],
    rangeStyle: M1RangeStyle.stars,
    tabIcon: 'sc_ic_weather',
    helpIcons: const ['sc_win_sun', 'sc_w_rain', 'sc_raincoat'],
    checkIcons: const ['sc_w_sun', 'sc_w_rain', 'sc_raincoat'],
    robot: 'sc_robot_weather',
    modeIcon: (m, s) => m == 0
        ? FittedBox(child: Row(mainAxisSize: MainAxisSize.min, children: [_pic('sc_w_sun', s * 0.5), _pic('sc_w_rain', s * 0.5)]))
        : _pic(const ['', 'sc_win_sun', 'sc_raincoat'][m], s * 0.85),
    play: (lv) => ScWeatherPlay(lv: lv),
  ),
  M1Game(
    id: 'matter',
    world: scWorld,
    menuSign: 'sc_sign_wood',
    playSign: 'sc_sign_wood2',
    back: 'sc_btn_back',
    sound: 'sc_btn_sound',
    playButton: 'btn_play',
    modes: const ['recognize', 'sort', 'observe'],
    ranges: const [0, 1, 2],
    rangeStyle: M1RangeStyle.stars,
    tabIcon: 'sc_ic_matter',
    helpIcons: const ['sc_m_cube', 'sc_bin_metal', 'sc_lens_fabric'],
    checkIcons: const ['sc_ic_leaf', 'sc_ic_mag', 'sc_ic_bulb'],
    robot: 'sc_robot_lab',
    modeIcon: (m, s) => m == 0
        ? FittedBox(child: Row(mainAxisSize: MainAxisSize.min, children: [_pic('sc_m_cube', s * 0.55), _pic('sc_m_spoon', s * 0.6), _pic('sc_m_towel', s * 0.45)]))
        : m == 1
            ? FittedBox(child: Row(mainAxisSize: MainAxisSize.min, children: [for (final b in ['wood', 'metal', 'fabric']) _pic('sc_bin_$b', s * 0.5)]))
            : _pic('sc_lens_wood', s * 0.75),
    play: (lv) => ScMatterPlay(lv: lv),
  ),
];
