import 'package:flutter/cupertino.dart';
import 'package:mortaalim/screens/main_shop_screen/Tools/watchAdButton.dart';
import 'package:provider/provider.dart';

import '../../../XpSystem.dart';

class TokenAndAdSection extends StatelessWidget {
  const TokenAndAdSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<ExperienceManager>(
      builder: (context, xpManager, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            WatchAdButton(),
          ],
        ),
      ),
    );
  }
}
