import 'package:flutter/material.dart';

import 'ar_dict.dart';
import 'ar_play.dart';
import 'm1_kit.dart';
import 'm1_shell.dart';
import 'm1_text.dart';

// اللغة العربية — السنة الأولى ابتدائي: the world and its five games.

Widget arDictButton(BuildContext c) => M1OutlineButton(
      label: m1T(c, 'ar_dict'),
      icon: Image.asset(m1('ar_w_dict')),
      onTap: () => Navigator.of(c).push(m1Route(const ArDictPage())),
      width: 230,
      height: 46,
    );

const arWorld = M1World(
  id: 'arabic',
  prefix: 'ar',
  lang: 'ar',
  homeExtra: arDictButton,
  games: _arabicGames,
  subject: 'arabic',
  homeBg: 'ar_bg_home',
  homeSign: 'ar_sign',
  homeBack: 'ar_btn_back',
  homeSound: 'ar_btn_sound',
  footerSprite: 'ar_plank',
  mapBg: 'ar_bg_map',
  mapMascot: 'ar_robot_conductor2',
  endBg: 'ar_bg_end',
  endLeft: 'ar_robot_cheer',
  endRight: 'ar_kid_jump',
  mapRatio: 970 / 941,
  mapPath: [
    Offset(0.808, 0.892), Offset(0.744, 0.827), Offset(0.685, 0.763), Offset(0.489, 0.644), Offset(0.595, 0.515),
    Offset(0.824, 0.369), Offset(0.67, 0.256), Offset(0.436, 0.149), Offset(0.242, 0.054),
  ],
);
List<M1Game> _arabicGames() => arGames;

Widget _pic(String s, double size) => Image.asset(m1(s), height: size, fit: BoxFit.contain);
Widget _txt(String t, double size, Color c) => FittedBox(child: Text(t, textDirection: TextDirection.rtl, style: m1Text(size, color: c, height: 1.3)));

final List<M1Game> arGames = [
  M1Game(
    id: 'letters',
    world: arWorld,
    menuSign: 'ar_sign_leafy',
    playSign: 'ar_sign_wood',
    back: 'ar_btn_back',
    sound: 'ar_btn_sound',
    playButton: 'btn_play',
    modes: const ['recognize', 'find', 'twins'],
    ranges: const [0, 1, 2],
    rangeStyle: M1RangeStyle.teal,
    tabIcon: 'ar_l_ba',
    helpIcons: const ['ar_sound_wave', 'ar_l_alif', 'ar_l_ta'],
    checkIcons: const ['ar_l_alif', 'ar_l_ba', 'ar_l_ta'],
    robot: 'ar_robot_book',
    modeIcon: (m, s) => switch (m) {
      0 => _pic('ar_l_alif', s * 0.8),
      1 => _pic('ar_l_ba', s * 0.6),
      _ => _txt('ب ت ث', s * 0.4, m1Purple),
    },
    play: (lv) => ArLettersPlay(lv: lv),
  ),
  M1Game(
    id: 'sounds',
    world: arWorld,
    menuSign: 'ar_sign_sound',
    playSign: 'ar_sign_purple2',
    back: 'ar_btn_back_p',
    sound: 'ar_btn_sound_p',
    playButton: 'btn_play',
    modes: const ['listen', 'first', 'same'],
    ranges: const [0, 1, 2],
    rangeStyle: M1RangeStyle.purple,
    tabIcon: 'ar_ear',
    helpIcons: const ['ar_ear', 'ar_cards', 'ar_megaphone'],
    checkIcons: const ['ar_ear', 'ar_megaphone', 'ar_cards'],
    robot: 'ar_robot_detective',
    modeIcon: (m, s) => _pic(const ['ar_ear', 'ar_duckling', 'ar_cards'][m], s * 0.8),
    play: (lv) => ArSoundsPlay(lv: lv),
  ),
  M1Game(
    id: 'harakat',
    world: arWorld,
    menuSign: 'ar_sign_purple',
    playSign: 'ar_sign_purple2',
    back: 'ar_btn_back_p',
    sound: 'ar_btn_sound_p',
    playButton: 'btn_play',
    modes: const ['listen', 'build', 'read'],
    ranges: const [0, 1, 2],
    rangeStyle: M1RangeStyle.stars,
    tabIcon: 'ar_cap',
    helpIcons: const ['ar_sound_wave', 'ar_hand', 'ar_book_open'],
    checkIcons: const ['ar_ear', 'ar_train', 'ar_book_open'],
    robot: 'ar_robot_conductor',
    modeIcon: (m, s) => switch (m) {
      0 => _pic('ar_megaphone', s * 0.75),
      1 => _txt('بُ', s * 0.6, const Color(0xFF7B3FE4)),
      _ => _pic('ar_train', s * 0.4),
    },
    play: (lv) => ArHarakatPlay(lv: lv),
  ),
  M1Game(
    id: 'words',
    world: arWorld,
    menuSign: 'ar_sign_leafy',
    playSign: 'ar_sign_wood',
    back: 'ar_btn_back',
    sound: 'ar_btn_sound_b',
    playButton: 'btn_play',
    modes: const ['match', 'read', 'listen'],
    ranges: const [0, 1, 2],
    rangeStyle: M1RangeStyle.blue,
    tabIcon: 'ar_w_rabbit',
    helpIcons: const ['ar_p_rabbit', 'ar_book_open', 'ar_hand'],
    checkIcons: const ['ar_w_book', 'ar_puzzle', 'ar_w_dict'],
    robot: 'ar_robot_welcome',
    modeIcon: (m, s) => _pic(const ['ar_puzzle', 'ar_w_book', 'ar_megaphone'][m], m == 0 ? s * 0.32 : s * 0.75),
    play: (lv) => ArWordsPlay(lv: lv),
  ),
  M1Game(
    id: 'sentences',
    world: arWorld,
    menuSign: 'ar_sign_purple2',
    playSign: 'ar_sign_wood',
    back: 'ar_btn_back_p',
    sound: 'ar_btn_sound_p',
    playButton: 'btn_play',
    modes: const ['listen', 'order', 'understand'],
    ranges: const [0, 1, 2],
    rangeStyle: M1RangeStyle.stars,
    tabIcon: 'ar_kid_read',
    helpIcons: const ['ar_sound_wave', 'ar_hand', 'ar_kid_read'],
    checkIcons: const ['ar_ear', 'ar_puzzle', 'ar_book_open'],
    robot: 'ar_robot_hint',
    modeIcon: (m, s) => _pic(const ['ar_megaphone', 'ar_puzzle', 'ar_kid_robot_book'][m], m == 1 ? s * 0.32 : s * 0.7),
    play: (lv) => ArSentencesPlay(lv: lv),
  ),
];
