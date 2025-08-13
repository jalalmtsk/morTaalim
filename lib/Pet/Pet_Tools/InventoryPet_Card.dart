import 'package:flutter/material.dart';

class InventoryCard extends StatelessWidget {
  final int foodLeft;
  final int waterLeft;
  final int energyLeft;

  const InventoryCard({
    Key? key,
    required this.foodLeft,
    required this.waterLeft,
    required this.energyLeft,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMiniItem("🍎", foodLeft, Colors.redAccent),
            _buildDivider(),
            _buildMiniItem("💧", waterLeft, Colors.blueAccent),
            _buildDivider(),
            _buildMiniItem("⚡", energyLeft, Colors.greenAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniItem(String emoji, int value, Color color) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 3),
        Text(
          "$value",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 14,
      width: 1,
      color: Colors.grey[300],
    );
  }
}
