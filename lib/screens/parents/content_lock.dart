import 'package:flutter/material.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';

import 'parent_data.dart';
import 'parent_strings.dart';
import 'parent_ui.dart' show pa;

/// True when the parent allows [section] (games, stories, religion,
/// creativity, ai). Otherwise shows a friendly "closed by your parents" popup.
Future<bool> sectionAllowed(BuildContext context, String section) async {
  await ParentSettings.I.load();
  if (ParentSettings.I.allows(section)) return true;
  if (!context.mounted) return false;
  await showDialog(
    context: context,
    barrierColor: KidColors.purpleDeep.withOpacity(0.35),
    builder: (ctx) => KidDialog(
      headerAsset: pa('gate_shield'),
      headerAspect: 0.8627,
      title: pT(ctx, 'lockedTitle'),
      message: pT(ctx, 'lockedMsg'),
      actions: [
        KidButton(
          label: pT(ctx, 'ok'),
          width: double.infinity,
          height: 50,
          showArrow: false,
          onPressed: () => Navigator.pop(ctx),
        ),
      ],
    ),
  );
  return false;
}
