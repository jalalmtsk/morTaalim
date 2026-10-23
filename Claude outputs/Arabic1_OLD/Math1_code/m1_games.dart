import 'package:flutter/material.dart';

import 'm1_add.dart';
import 'm1_basket.dart';
import 'm1_kit.dart';
import 'm1_shape.dart';
import 'm1_shell.dart';
import 'm1_train.dart';
import 'm1_treasure.dart';

// The five maths games and how their menus look.

Widget _numTile(String sprite, int n, double s) => SizedBox(
      width: s,
      height: s,
      child: Stack(children: [
        Positioned.fill(child: Image.asset(m1(sprite), fit: BoxFit.contain)),
        Positioned.fill(child: Padding(padding: EdgeInsets.all(s * 0.24), child: FittedBox(child: m1Number(n, 40)))),
      ]),
    );

Widget _row(List<Widget> c) => FittedBox(child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: c));

Widget _trainIcon(int m, double s) => switch (m) {
      0 => _row([_numTile('tile_r', 1, s * 0.36), _numTile('tile_y', 2, s * 0.36), _numTile('tile_b', 3, s * 0.36)]),
      1 => Stack(clipBehavior: Clip.none, children: [
          Image.asset(m1('apples3'), height: s * 0.7),
          Positioned(right: -s * 0.12, bottom: -s * 0.08, child: Image.asset(m1('hand_point'), height: s * 0.42)),
        ]),
      _ => Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.redo_rounded, color: m1Orange, size: s * 0.28),
          _row([_numTile('tile_r', 1, s * 0.32), _numTile('tile_b', 2, s * 0.32), _numTile('tile_y', 3, s * 0.32)]),
        ]),
    };

Widget _basketIcon(int m, double s) => switch (m) {
      0 => Image.asset(m1('basket_red'), height: s * 0.8),
      1 => Stack(clipBehavior: Clip.none, children: [
          Image.asset(m1('basket_empty'), height: s * 0.72),
          Positioned(right: -s * 0.15, top: -s * 0.1, child: Image.asset(m1('hand_apple2'), height: s * 0.4)),
        ]),
      _ => Column(mainAxisSize: MainAxisSize.min, children: [
          m1Outlined('< >', s * 0.24, color: m1Purple),
          _row([Image.asset(m1('basket_red'), height: s * 0.5), Image.asset(m1('basket_pears'), height: s * 0.5)]),
        ]),
    };

Widget _addIcon(int m, double s) => switch (m) {
      0 => Image.asset(m1('cube_stack'), height: s * 0.62),
      1 => Image.asset(m1('numline'), width: s * 1.1),
      _ => _row([Image.asset(m1('basket_red'), height: s * 0.48), Image.asset(m1('ic_plus'), height: s * 0.24), Image.asset(m1('basket_green'), height: s * 0.48)]),
    };

Widget _treasureIcon(int m, double s) => switch (m) {
      0 => _row([Image.asset(m1('gem_b'), height: s * 0.36), Image.asset(m1('hand_gem'), height: s * 0.62), Image.asset(m1('gem_o'), height: s * 0.36)]),
      1 => _row([Image.asset(m1('gem_b'), height: s * 0.5), Image.asset(m1('gem_g'), height: s * 0.5), Image.asset(m1('gem_o'), height: s * 0.5)]),
      _ => Stack(clipBehavior: Clip.none, children: [
          Image.asset(m1('basket_gems'), height: s * 0.74),
          Positioned(left: 0, right: 0, top: s * 0.02, child: Center(child: m1Outlined('?', s * 0.24, color: m1Purple))),
        ]),
    };

Widget _shapeIcon(int m, double s) => switch (m) {
      0 => _row([
          Image.asset(m1('sh_circle_red2'), height: s * 0.42),
          SizedBox(width: s * 0.06),
          Image.asset(m1('sh_square_blue'), height: s * 0.4),
          SizedBox(width: s * 0.06),
          Image.asset(m1('sh_triangle_yellow'), height: s * 0.4),
        ]),
      1 => Image.asset(m1('sorter'), width: s * 1.3),
      2 => Image.asset(m1('block_house'), width: s * 1.2),
      _ => _row([
          Image.asset(m1('sh_circle_red'), height: s * 0.32),
          Image.asset(m1('sh_triangle_yellow'), height: s * 0.32),
          Image.asset(m1('sh_circle_red'), height: s * 0.32),
          Image.asset(m1('sh_triangle_yellow'), height: s * 0.32),
          Container(
            width: s * 0.3,
            height: s * 0.3,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: m1Purple, width: 2)),
          ),
        ]),
    };

final List<M1Game> m1Games = [
  M1Game(
    id: 'train',
    menuSign: 'sign_cloud2',
    playSign: 'sign_star',
    back: 'btn_back_p',
    sound: 'btn_sound_p',
    playButton: 'btn_play',
    modes: const ['recognize', 'count', 'order'],
    ranges: const [10, 20, 100],
    rangeStyle: M1RangeStyle.blue,
    tabIcon: 'engine2',
    helpIcons: const ['tile_b', 'apple2', 'wagon_dash'],
    checkIcons: const ['tile_y', 'apples3', 'trophy'],
    robot: 'conductor_wave',
    modeIcon: _trainIcon,
    play: (lv) => M1TrainPlay(lv: lv),
  ),
  M1Game(
    id: 'basket',
    menuSign: 'sign_leaf',
    playSign: 'sign_leaf2',
    back: 'btn_back_p',
    sound: 'btn_sound_p',
    playButton: 'btn_play_leaf',
    modes: const ['count', 'fill', 'compare'],
    ranges: const [5, 10, 20],
    rangeStyle: M1RangeStyle.teal,
    tabIcon: 'ic_basket',
    helpIcons: const ['basket_red', 'hand_apple', 'basket_pears'],
    checkIcons: const ['apples3', 'basket_3', 'trophy'],
    robot: 'robot_small',
    modeIcon: _basketIcon,
    play: (lv) => M1BasketPlay(lv: lv),
  ),
  M1Game(
    id: 'add',
    menuSign: 'sign_cloud',
    playSign: 'sign_cloud3',
    back: 'btn_back',
    sound: 'btn_sound',
    playButton: 'btn_play',
    modes: const ['objects', 'line', 'problems'],
    ranges: const [5, 10, 20],
    rangeStyle: M1RangeStyle.tealStars,
    tabIcon: 'ic_plus',
    helpIcons: const ['cube_stack', 'hand_r', 'numline'],
    checkIcons: const ['cube_blue', 'plus', 'trophy'],
    robot: 'robot_plus',
    modeIcon: _addIcon,
    play: (lv) => M1AddPlay(lv: lv),
  ),
  M1Game(
    id: 'treasure',
    menuSign: 'sign_jungle',
    playSign: 'sign_jungle2',
    back: 'btn_back_b',
    sound: 'btn_sound_p',
    playButton: 'btn_play_small',
    modes: const ['remove', 'rest', 'problems'],
    ranges: const [5, 10, 20],
    rangeStyle: M1RangeStyle.purple,
    tabIcon: 'ic_minus',
    helpIcons: const ['chest', 'hand_gem', 'gem_slot'],
    checkIcons: const ['gem_p', 'chest', 'trophy'],
    robot: 'explorer_point',
    modeIcon: _treasureIcon,
    play: (lv) => M1TreasurePlay(lv: lv),
  ),
  M1Game(
    id: 'shape',
    menuSign: 'sign_wood2',
    playSign: 'sign_wood',
    back: 'btn_back_p',
    sound: 'btn_sound_p',
    playButton: 'btn_play',
    modes: const ['recognize', 'sort', 'build', 'sequence'],
    ranges: const [0, 1, 2],
    rangeStyle: M1RangeStyle.stars,
    tabIcon: 'ic_shapes',
    helpIcons: const ['robot_tri', 'sorter', 'block_house'],
    checkIcons: const ['ic_shapes', 'hut_circle', 'trophy'],
    robot: 'robot_tri',
    modeIcon: _shapeIcon,
    play: (lv) => M1ShapePlay(lv: lv),
  ),
];
