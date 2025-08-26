import 'package:flutter/material.dart';
import 'package:mortaalim/TestingBeforeProdcution/Hezz2FinalGame/Models/Cards.dart';

class CardWidget extends StatelessWidget {
  final PlayingCard card;
  final bool isFaceUp;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const CardWidget({
    required this.card,
    this.isFaceUp = true,
    this.onTap,
    this.width = 70,
    this.height = 110,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: Image.asset(
          isFaceUp ? card.assetName : card.backAsset,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}