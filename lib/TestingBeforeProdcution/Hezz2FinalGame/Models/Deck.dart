import 'dart:math';
import 'package:mortaalim/TestingBeforeProdcution/Hezz2FinalGame/Models/Cards.dart';

class Deck {
  final List<PlayingCard> cards = [];

  Deck() { _build(); }

  void _build() {
    cards.clear();
    final suits = ['Coins','Cups','Swords','Clubs'];
    final ranks = [1,2,3,4,5,6,7,10,11,12];

    for(final s in suits) {
      for(final r in ranks) {
        cards.add(PlayingCard(suit: s, rank: r));
      }
    }
  }

  void shuffle() => cards.shuffle(Random());
  PlayingCard draw() => cards.removeLast();
  bool get isEmpty => cards.isEmpty;
  int get length => cards.length;
}