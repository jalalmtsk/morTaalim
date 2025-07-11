import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'RoomScreen.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Your Room", style: Theme.of(context).textTheme.titleLarge),
        Expanded(child: RoomGrid()),
      ],
    );
  }
}
