import 'package:flutter/material.dart';

import '../../../Manager/models/avatar_catalog.dart';
import '../Widgets/ImageAvatarGrid.dart';

/// Shop → Avatars. One grid fed by [AvatarCatalog] (new avatars get added there).
class IndexFunMojiPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFff9966), Color(0xFFff5e62)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const SafeArea(
          child: ImageAvatarGrid(imageAvatars: AvatarCatalog.shop),
        ),
      ),
    );
  }
}
