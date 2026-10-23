import 'dart:math';

import 'package:flutter/material.dart';

import 'fr_imagier.dart';
import 'fr_play.dart';
import 'm1_kit.dart';
import 'm1_shell.dart';
import 'm1_text.dart';

// Français — 1re année primaire: the world and its five games.

Widget frImagierButton(BuildContext c) => M1OutlineButton(
      label: m1T(c, 'fi_title'),
      icon: Image.asset(m1('fr_book_purple')),
      onTap: () => Navigator.of(c).push(m1Route(const FrImagierPage())),
      width: 230,
      height: 46,
    );

const frWorld = M1World(
  id: 'french',
  prefix: 'fr',
  lang: 'fr',
  homeExtra: frImagierButton,
  games: _frenchGames,
  subject: 'french',
  homeBg: 'fr_bg_home',
  homeSign: 'fr_sign',
  homeMascot: 'fr_robot',
  homeBack: 'fr_btn_back',
  homeSound: 'fr_btn_sound',
  footerSprite: 'fr_plank',
  mapBg: 'art_bg_map',
  mapMascot: 'fr_robot_cond',
  endBg: 'fr_bg_end',
  endLeft: 'fr_robot_cheer',
  endRight: 'fr_kid_jump',
  mapRatio: 890 / 941,
  mapPath: [
    Offset(0.308, 0.893), Offset(0.528, 0.787), Offset(0.81, 0.68), Offset(0.792, 0.466), Offset(0.542, 0.556),
    Offset(0.627, 0.258), Offset(0.494, 0.157), Offset(0.342, 0.073),
  ],
);
List<M1Game> _frenchGames() => frGames;

Widget _pic(String s, double size) => Image.asset(m1(s), height: size, fit: BoxFit.contain);
Widget _txt(String t, double size, Color c) => FittedBox(child: Text(t, style: m1Text(size, color: c, height: 1.1)));

// ── characters standing between the title and the mode cards ──

Widget _row(List<(String, double)> items, double w, double h) => Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < items.length; i++)
          Flexible(
            child: M1PopIn(
              delay: 120 * i,
              child: M1Float(phase: i * 0.3, amp: 3, child: Image.asset(m1(items[i].$1), height: h * items[i].$2, fit: BoxFit.contain)),
            ),
          ),
      ],
    );

Widget frLettersScene(BuildContext c, double w, double h, int r) =>
    _row([('fr_robot_pack', 0.92), ('fr_a_orange', 0.5), ('fr_a_purple', 0.5), ('fr_a_teal', 0.5)], w, h);
Widget frSoundsScene(BuildContext c, double w, double h, int r) => _row([('fr_detective', 0.9), ('fr_ear', 0.55), ('fr_waves', 0.5)], w, h);
Widget frSyllablesScene(BuildContext c, double w, double h, int r) => _row([('fr_robot_cond', 0.9), ('fr_train_face', 0.42)], w, h);
Widget frWordsScene(BuildContext c, double w, double h, int r) {
  const sets = [
    ['fr_cat2', 'fr_dog', 'fr_rabbit'],
    ['fr_bag', 'fr_book_purple', 'fr_moto2'],
    ['ar_w_house', 'fr_flowers2', 'fr_mushroom'],
  ];
  final s = sets[r.clamp(0, 2)];
  return _row([('fr_robot_point', 0.9), (s[0], 0.55), (s[1], 0.55), (s[2], 0.55)], w, h);
}

/// The open book of "Ma première phrase": the sleeping cat and « Le chat dort. »
Widget frSentencesScene(BuildContext c, double w, double h, int r) {
  final bw = min(w * 0.98, h * 1.5);
  final bh = bw * m1Ratio('fr_book_big');
  const tiles = ['fr_t_le', 'fr_t_chat', 'fr_t_dort'];
  return SizedBox(
    width: w,
    height: h,
    child: Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
      Positioned(left: 0, bottom: bh * 0.5, child: M1PopIn(child: M1Float(amp: 3, child: Image.asset(m1('fr_robot_right'), height: h * 0.62)))),
      Positioned(right: 0, bottom: bh * 0.4, child: M1PopIn(delay: 150, child: M1Float(phase: 0.4, amp: 3, child: Image.asset(m1('fr_kid_read'), height: h * 0.48)))),
      Positioned(bottom: 0, child: Image.asset(m1('fr_book_big'), width: bw)),
      Positioned(bottom: bh * 0.7, child: M1PopIn(delay: 250, child: Image.asset(m1('fr_cat_sleep'), height: h * 0.34))),
      Positioned(
        bottom: bh * 0.15,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < tiles.length; i++)
            M1PopIn(
              delay: 400 + 150 * i,
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: Image.asset(m1(tiles[i]), height: min(h * 0.2, 54.0))),
            ),
        ]),
      ),
    ]),
  );
}

final List<M1Game> frGames = [
  M1Game(
    id: 'lettres',
    world: frWorld,
    menuScene: frLettersScene,
    menuSign: 'fr_sign_wood',
    playSign: 'fr_sign_wood',
    back: 'fr_btn_back_c',
    sound: 'fr_btn_sound_c',
    playButton: 'btn_play',
    modes: const ['recognize', 'case', 'first'],
    ranges: const [0, 1, 2],
    rangeStyle: M1RangeStyle.stars,
    tabIcon: 'fr_l_a',
    helpIcons: const ['fr_spk_teal', 'fr_a_purple', 'fr_cat2'],
    checkIcons: const ['fr_a_orange', 'fr_a_purple', 'fr_a_teal'],
    robot: 'fr_robot_pack',
    modeIcon: (m, s) => switch (m) {
      0 => _pic('fr_l_a', s * 0.62),
      1 => _txt('A a', s * 0.42, m1Purple),
      _ => _pic('fr_cat2', s * 0.7),
    },
    play: (lv) => FrLettersPlay(lv: lv),
  ),
  M1Game(
    id: 'sons',
    world: frWorld,
    menuScene: frSoundsScene,
    menuSign: 'fr_sign_cloud',
    playSign: 'fr_sign_cloud',
    back: 'fr_btn_back',
    sound: 'fr_spk_teal',
    playButton: 'btn_play',
    modes: const ['listen', 'first', 'same'],
    ranges: const [0, 1, 2],
    rangeStyle: M1RangeStyle.teal,
    tabIcon: 'fr_ear',
    helpIcons: const ['fr_spk_teal', 'fr_ear', 'fr_detective'],
    checkIcons: const ['fr_ear', 'fr_waves', 'fr_detective'],
    robot: 'fr_detective',
    modeIcon: (m, s) => _pic(const ['fr_spk_teal', 'fr_ear', 'fr_card_mouse'][m], s * 0.66),
    play: (lv) => FrSoundsPlay(lv: lv),
  ),
  M1Game(
    id: 'syllabes',
    world: frWorld,
    menuScene: frSyllablesScene,
    menuSign: 'fr_sign_purple',
    playSign: 'fr_sign_purple',
    back: 'fr_btn_back_p',
    sound: 'fr_btn_sound_p',
    playButton: 'btn_play',
    modes: const ['listen', 'build', 'read'],
    ranges: const [0, 1, 2],
    rangeStyle: M1RangeStyle.purple,
    tabIcon: 'fr_engine',
    helpIcons: const ['fr_spk_teal', 'fr_wagon_teal', 'fr_train_face'],
    checkIcons: const ['fr_ear', 'fr_puzzle', 'fr_book_purple'],
    robot: 'fr_robot_cond',
    modeIcon: (m, s) => switch (m) {
      0 => _pic('fr_spk_teal', s * 0.62),
      1 => _txt('m + a', s * 0.36, m1Purple),
      _ => _pic('fr_train', s * 0.36),
    },
    play: (lv) => FrSyllablesPlay(lv: lv),
  ),
  M1Game(
    id: 'mots',
    world: frWorld,
    menuScene: frWordsScene,
    menuSign: 'fr_sign_cloud2',
    playSign: 'fr_sign_cloud2',
    back: 'fr_btn_back_p',
    sound: 'fr_btn_sound_p',
    playButton: 'btn_play',
    modes: const ['match', 'read', 'listen'],
    ranges: const [0, 1, 2],
    rangeStyle: M1RangeStyle.blue,
    tabIcon: 'fr_cat2',
    helpIcons: const ['fr_cat2', 'fr_glove', 'fr_btn_check'],
    checkIcons: const ['fr_book_purple', 'fr_puzzle', 'fr_badge'],
    robot: 'fr_robot_point',
    modeIcon: (m, s) => switch (m) {
      0 => _pic('fr_puzzle', s * 0.4),
      1 => _txt('chat', s * 0.36, const Color(0xFF1C2FB8)),
      _ => _pic('fr_btn_sound_p', s * 0.6),
    },
    play: (lv) => FrWordsPlay(lv: lv),
  ),
  M1Game(
    id: 'phrases',
    world: frWorld,
    menuScene: frSentencesScene,
    menuSign: 'fr_sign_cloud',
    playSign: 'fr_sign_cloud',
    back: 'fr_btn_back',
    sound: 'fr_btn_sound',
    playButton: 'btn_play',
    modes: const ['listen', 'order', 'understand'],
    ranges: const [0, 1, 2],
    rangeStyle: M1RangeStyle.stars,
    tabIcon: 'fr_cat_read',
    helpIcons: const ['fr_spk_teal', 'fr_t_chat', 'fr_cat_sleep'],
    checkIcons: const ['fr_ear', 'fr_puzzle', 'fr_magic_book'],
    robot: 'fr_robot_right',
    modeIcon: (m, s) => _pic(const ['fr_spk_teal', 'fr_t_chat', 'fr_cat_sleep'][m], m == 1 ? s * 0.42 : s * 0.62),
    play: (lv) => FrSentencesPlay(lv: lv),
  ),
];
