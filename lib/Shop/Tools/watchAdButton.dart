import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../XpSystem.dart';
import '../../tools/Ads_Manager.dart';

class WatchAdButton extends StatelessWidget {
  const WatchAdButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => AdHelper.showRewardedAdWithLoading(context, (){
        Provider.of<ExperienceManager>(context, listen: false).addStarBanner(context ,1);
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.green, Colors.lightGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.ads_click, color: Colors.white),
            SizedBox(width: 5),
            Text(
              'Ad for 1⭐ & 1 Token',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
