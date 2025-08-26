import 'package:flutter/material.dart';

class PlayingCard {
  final String suit;
  final int rank;
  final String id;

  PlayingCard({required this.suit, required this.rank}) : id = UniqueKey().toString();

  String get assetName => 'assets/images/cards/${suit.toLowerCase()}_${rank.toString()}.png';
  String get backAsset => 'assets/images/cards/backCard.png';
  String get label => '$rank of $suit';
}