import 'dart:math';

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


// Characters standing between the title and the mode cards of each menu.
Widget _scene(List<(String, double, double)> items, double w, double h) => Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < items.length; i++)
          M1PopIn(
            delay: 120 * i,
            child: M1Float(
              phase: i * 0.3,
              amp: 3,
              child: Image.asset(m1(items[i].$1), height: min(h * items[i].$2, w * items[i].$3 * m1Ratio(items[i].$1)), fit: BoxFit.contain),
            ),
          ),
      ],
    );

Widget arLettersScene(BuildContext c, double w, double h, int r) => _scene([('ar_robot_welcome', 0.9, 0.5)], w, h);
Widget arSoundsScene(BuildContext c, double w, double h, int r) => _scene([('ar_robot_detective', 0.92, 0.36), ('ar_speaker', 0.7, 0.26), ('ar_duckling', 0.6, 0.24)], w, h);
Widget arHarakatScene(BuildContext c, double w, double h, int r) => M1SlideIn(dy: 0, child: _scene([('ar_train_robot', 0.95, 0.94)], w, h));
/// The open picture book of كلمتي وصورتي: three pictures with their word, by theme
/// (follows the selected tab), the robot pointing at it. Tap = hear the word.
const _wordsBook = {
  0: [('ar_p_rabbit', 'أَرْنَب'), ('ar_p_duck', 'بَطَّة'), ('ar_p_fish', 'سَمَك')],
  1: [('ar_w_book', 'كِتَاب'), ('ar_pencil', 'قَلَم'), ('ar_w_bag', 'حَقِيبَة')],
  2: [('ar_w_house', 'بَيْت'), ('ar_tree_green', 'شَجَرَة'), ('ar_flowers', 'وَرْدَة')],
};

Widget arWordsScene(BuildContext c, double w, double h, int r) {
  final br = m1Ratio('ar_book_big');
  final bw = min(w * 0.96, h * 0.9 / br);
  final bh = bw * br;
  final items = _wordsBook[r.clamp(0, 2)]!;
  return Directionality(
    textDirection: TextDirection.ltr,
    child: SizedBox(
      width: w,
      height: h,
      child: Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
        // wooden stump under the book
        Positioned(
          bottom: 0,
          child: Container(
            width: bw * 0.86,
            height: bh * 0.2,
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB9783F), Color(0xFF8A5229)]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(bh * 0.06), bottom: Radius.circular(bh * 0.1)),
              border: Border.all(color: const Color(0xFF6E3E1C), width: 2),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
            ),
          ),
        ),
        // robot pointing at the book (behind it)
        Positioned(
          left: (w - bw) / 2 - bw * 0.02,
          bottom: bh * 0.72,
          child: M1PopIn(
            child: M1Float(amp: 3, child: Image.asset(m1('ar_robot_point'), height: min(h - bh * 0.72, bw * 0.42), fit: BoxFit.contain)),
          ),
        ),
        // the book
        Positioned(
          bottom: bh * 0.1,
          child: M1PopIn(
            from: 0.7,
            child: SizedBox(
              width: bw,
              height: bh,
              child: Stack(children: [
                Positioned.fill(child: Image.asset(m1('ar_book_big'), fit: BoxFit.fill)),
                Positioned(
                  left: bw * 0.07,
                  right: bw * 0.07,
                  top: bh * 0.1,
                  bottom: bh * 0.2,
                  child: Row(children: [
                    for (var i = 0; i < 3; i++)
                      Expanded(
                        child: M1PopIn(
                          key: ValueKey('wb_${r}_$i'),
                          delay: 150 + 140 * i,
                          child: M1Press(
                            onTap: () => M1Voice.say(c, items[i].$2),
                            sound: 'PopButton',
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: bw * 0.012),
                              child: Column(children: [
                                Expanded(
                                  child: M1Float(phase: i * 0.33, amp: 2, child: Image.asset(m1(items[i].$1), fit: BoxFit.contain)),
                                ),
                                SizedBox(height: bh * 0.03),
                                Container(
                                  height: bh * 0.2,
                                  width: double.infinity,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFCF4),
                                    borderRadius: BorderRadius.circular(bh * 0.1),
                                    border: Border.all(color: const Color(0xFF7B3FE4), width: 2),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(items[i].$2, textDirection: TextDirection.rtl, style: m1Text(bh * 0.12, color: const Color(0xFF4A1E8C), weight: FontWeight.w800, height: 1.3)),
                                    ),
                                  ),
                                ),
                              ]),
                            ),
                          ),
                        ),
                      ),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ]),
    ),
  );
}

Widget arSentencesScene(BuildContext c, double w, double h, int r) => _scene([('ar_kid_robot_book', 0.95, 0.86)], w, h);

const arWorld = M1World(
  id: 'arabic',
  prefix: 'ar',
  lang: 'ar',
  homeExtra: arDictButton,
  games: _arabicGames,
  subject: 'arabic',
  homeBg: 'ar_bg_home',
  homeSign: 'ar_sign',
  homeTitle: 'ar_title_home',
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
    menuTitle: 'ar_title_letters',
    menuScene: arLettersScene,
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
    menuTitle: 'ar_title_sounds',
    menuScene: arSoundsScene,
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
    menuTitle: 'ar_title_harakat',
    menuScene: arHarakatScene,
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
    menuTitle: 'ar_title_words',
    menuScene: arWordsScene,
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
    menuTitle: 'ar_title_sentences',
    menuScene: arSentencesScene,
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
