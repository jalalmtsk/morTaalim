import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/Manager/models/avatar_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Profile titles the child can pick from (unlocked by level).
class ProfileTitleStore {
  ProfileTitleStore._();
  static const _key = 'profile_title_tier';

  /// Chosen title tier, or -1 = "follow my level".
  static int choice = -1;

  /// Level needed for each title tier.
  static const List<int> minLevel = [1, 3, 5, 8, 12];

  static int tierFor(int level) {
    var t = 0;
    for (var i = 0; i < minLevel.length; i++) {
      if (level >= minLevel[i]) t = i;
    }
    return t;
  }

  /// The tier actually shown for [level] (choice if still unlocked, else the level's own).
  static int shownTier(int level) {
    final max = tierFor(level);
    return (choice >= 0 && choice <= max) ? choice : max;
  }

  static Future<void> load() async {
    choice = (await SharedPreferences.getInstance()).getInt(_key) ?? -1;
  }

  static Future<void> save(int tier) async {
    choice = tier;
    await (await SharedPreferences.getInstance()).setInt(_key, tier);
  }
}

/// One decorative frame sprite. The hole (where the avatar shows) is given as
/// fractions of the sprite width/height, measured from the artwork.
class AvatarFrame {
  final String id;
  final double cx, cy, r, aspect; // hole centre x/y (fractions), hole radius (fraction of width), height/width
  final int level; // unlocked by reaching this level (0 = not a level frame)
  final int gems; // or bought with gems (0 = not for sale)
  const AvatarFrame(this.id, this.cx, this.cy, this.r, this.aspect, {this.level = 0, this.gems = 0});

  String get asset => 'assets/images/UI/Frames/frame_$id.webp';
}

class AvatarFrames {
  AvatarFrames._();
  static const String none = '';

  static const List<AvatarFrame> all = [
  AvatarFrame('sky', 0.4987, 0.5124, 0.3593, 0.9441, level: 1),
  AvatarFrame('star', 0.4991, 0.5461, 0.3166, 0.8932, level: 2),
  AvatarFrame('leaf', 0.498, 0.5054, 0.3174, 0.8776, level: 3),
  AvatarFrame('ocean', 0.5051, 0.4985, 0.2976, 0.8282, level: 4),
  AvatarFrame('sun', 0.4996, 0.5303, 0.2928, 0.8329, level: 5),
  AvatarFrame('rainbow', 0.5177, 0.5425, 0.259, 0.8649, level: 6),
  AvatarFrame('origami', 0.4916, 0.5287, 0.22, 0.9721, level: 7),
  AvatarFrame('garden', 0.5383, 0.4709, 0.1926, 0.9399, level: 8),
  AvatarFrame('snow', 0.5005, 0.5009, 0.2671, 0.8325, level: 9),
  AvatarFrame('space', 0.4855, 0.5117, 0.3151, 0.8397, level: 10),
  AvatarFrame('morocco', 0.4696, 0.5014, 0.2542, 1.0058, level: 12),
  AvatarFrame('royal', 0.4971, 0.4831, 0.2897, 0.8837, level: 15),
  AvatarFrame('phoenix', 0.5178, 0.4211, 0.2107, 1.0411, level: 20),
  AvatarFrame('candy', 0.5075, 0.487, 0.3093, 0.929, gems: 30),
  AvatarFrame('strawberry', 0.5102, 0.4777, 0.2788, 0.9093, gems: 30),
  AvatarFrame('bee', 0.4903, 0.4555, 0.2752, 0.9711, gems: 35),
  AvatarFrame('sweets', 0.535, 0.554, 0.2389, 1.0112, gems: 35),
  AvatarFrame('butterfly', 0.5123, 0.5036, 0.257, 0.8443, gems: 40),
  AvatarFrame('music', 0.5083, 0.5082, 0.2741, 0.9231, gems: 45),
  AvatarFrame('art', 0.512, 0.4901, 0.2703, 0.8822, gems: 45),
  AvatarFrame('soccer', 0.4994, 0.531, 0.3031, 0.9545, gems: 45),
  AvatarFrame('jungle', 0.5449, 0.5045, 0.235, 1.009, gems: 50),
  AvatarFrame('mermaid', 0.5042, 0.4569, 0.2521, 0.964, gems: 50),
  AvatarFrame('cozy', 0.5405, 0.4496, 0.2289, 1.0029, gems: 50),
  AvatarFrame('explorer', 0.4898, 0.512, 0.2833, 0.8864, gems: 60),
  AvatarFrame('robot', 0.501, 0.5224, 0.2902, 0.9639, gems: 60),
  AvatarFrame('science', 0.5115, 0.5515, 0.1946, 1.0316, gems: 60),
  AvatarFrame('racing', 0.5, 0.4913, 0.2736, 0.9885, gems: 70),
  AvatarFrame('story', 0.5121, 0.4851, 0.27, 0.9164, gems: 70),
  AvatarFrame('pirate', 0.5203, 0.4742, 0.2137, 0.9564, gems: 80),
  AvatarFrame('spaceship', 0.4986, 0.4925, 0.2429, 0.928, gems: 80),
  AvatarFrame('dragon', 0.5146, 0.5316, 0.247, 0.7677, gems: 100),
  AvatarFrame('wizard', 0.4644, 0.5114, 0.2749, 0.9573, gems: 120),
  ];

  static AvatarFrame? of(String id) {
    for (final f in all) {
      if (f.id == id) return f;
    }
    return null;
  }

  /// Owned = level reached, or bought (stored in ExperienceManager.unlockedAvatarFrames).
  static bool owned(AvatarFrame f, int level, List<String> bought) =>
      (f.level > 0 && level >= f.level) || bought.contains(f.id);

  /// A frame id that still exists ('' = no frame).
  static String resolve(String? id) => of(id ?? '') == null ? none : id!;
}

/// Round avatar, optionally inside a decorative frame sprite.
/// The widget takes [size]×[size]; frame decorations may spill slightly outside.
class FramedAvatar extends StatelessWidget {
  final String avatar;
  final String frame;
  final double size;
  final Color fill;
  const FramedAvatar({super.key, required this.avatar, required this.frame, required this.size, this.fill = const Color(0xFFE6F7FF)});

  @override
  Widget build(BuildContext context) {
    final f = AvatarFrames.of(frame);
    final img = ClipOval(
      child: ColoredBox(
        color: fill,
        child: Image.asset(AvatarCatalog.resolve(avatar), fit: BoxFit.cover, width: size, height: size),
      ),
    );
    if (f == null) {
      return Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.045),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: size * 0.08, offset: Offset(0, size * 0.03))],
        ),
        child: img,
      );
    }
    // Frame fits inside ~1.18× the widget; the avatar shrinks to the hole if needed,
    // so frames with small holes / big decorations never look oversized.
    const maxF = 1.18;
    var d = size * 0.74; // avatar circle
    var fw = d * 1.06 / (2 * f.r);
    final limit = min(size * maxF, size * maxF / f.aspect);
    if (fw > limit) {
      fw = limit;
      d = fw * 2 * f.r / 1.06;
    }
    final fh = fw * f.aspect;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: (size - d) / 2, top: (size - d) / 2, width: d, height: d, child: img),
          Positioned(
            left: size / 2 - f.cx * fw,
            top: size / 2 - f.cy * fh,
            width: fw,
            height: fh,
            child: IgnorePointer(child: Image.asset(f.asset, fit: BoxFit.fill, filterQuality: FilterQuality.medium)),
          ),
        ],
      ),
    );
  }
}
