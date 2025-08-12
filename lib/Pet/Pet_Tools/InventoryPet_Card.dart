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
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 25),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(Icons.restaurant, "Food", foodLeft, Colors.orange),
            _buildDivider(),
            _buildStatItem(Icons.water_drop, "Water", waterLeft, Colors.blue),
            _buildDivider(),
            _buildStatItem(Icons.sports_esports, "Energy", energyLeft, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, int value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            )),
        const SizedBox(height: 2),
        Text(
          "$value",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 10,
      width: 1,
      color: Colors.grey[300],
    );
  }
}
