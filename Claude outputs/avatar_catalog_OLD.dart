/// The one list of avatars in the app.
///
/// Onboarding, the shop, the collection and the profile all read from here.
/// Saved data that still points at a removed avatar (old images, emojis,
/// animated avatars) is cleaned by [AvatarCatalog.resolve] /
/// [AvatarCatalog.sanitizeUnlocked], so old users never see a broken avatar.
///
/// To add avatars later: drop a round 256×256 image in
/// `assets/images/AvatarImage/Kids/`, add a constant, put it in [all], and
/// give it a price in [shop] (cost 0 + in [starter] = free for everyone).
class AvatarCatalog {
  AvatarCatalog._();

  static const String dir = 'assets/images/AvatarImage/Kids/';

  static const String mascot = '${dir}mascot.webp';
  static const String boyCurly = '${dir}boy_curly.webp';
  static const String girlGlasses = '${dir}girl_glasses.webp';
  static const String girlHijab = '${dir}girl_hijab.webp';
  static const String boyGinger = '${dir}boy_ginger.webp';
  static const String fox = '${dir}fox.webp';
  static const String robot = '${dir}robot.webp';
  static const String girlPuffs = '${dir}girl_puffs.webp';
  static const String boyBlackHair = '${dir}boy_black_hair.webp';

  // 2026 set
  static const String boyHoodie = '${dir}boy_hoodie.webp';
  static const String girlBraids = '${dir}girl_braids.webp';
  static const String robotBlue = '${dir}robot_blue.webp';
  static const String foxCub = '${dir}fox_cub.webp';
  static const String panda = '${dir}panda.webp';
  static const String kitty = '${dir}kitty.webp';
  static const String astronaut = '${dir}astronaut.webp';
  static const String girlHijabPurple = '${dir}girl_hijab_purple.webp';
  static const String dragon = '${dir}dragon.webp';

  static const List<String> all = [
    boyHoodie, girlBraids, robotBlue,
    foxCub, panda, kitty,
    astronaut, girlHijabPurple, dragon,
    mascot, boyCurly, girlGlasses,
    girlHijab, boyGinger, fox,
    robot, girlPuffs, boyBlackHair,
  ];

  /// Unlocked for every user.
  static const List<String> starter = all;

  static const String defaultAvatar = mascot;

  /// Shop grid entries (same shape the shop's ImageAvatarGrid expects).
  static const List<Map<String, dynamic>> shop = [
    {'image': mascot, 'cost': 0},
    {'image': boyCurly, 'cost': 0},
    {'image': girlGlasses, 'cost': 0},
    {'image': girlHijab, 'cost': 0},
    {'image': boyGinger, 'cost': 0},
    {'image': fox, 'cost': 0},
    {'image': robot, 'cost': 0},
    {'image': girlPuffs, 'cost': 0},
    {'image': boyBlackHair, 'cost': 0},
    {'image': boyHoodie, 'cost': 0},
    {'image': girlBraids, 'cost': 0},
    {'image': robotBlue, 'cost': 0},
    {'image': foxCub, 'cost': 0},
    {'image': panda, 'cost': 0},
    {'image': kitty, 'cost': 0},
    {'image': astronaut, 'cost': 0},
    {'image': girlHijabPurple, 'cost': 0},
    {'image': dragon, 'cost': 0},
  ];

  static bool isValid(String? path) => path != null && all.contains(path);

  /// A valid avatar: the given one if it still exists, else the default.
  static String resolve(String? path) => isValid(path) ? path! : defaultAvatar;

  /// Keeps only avatars that still exist, always including the starter set.
  static List<String> sanitizeUnlocked(Iterable<String>? unlocked) {
    final keep = <String>{...starter, ...?unlocked?.where(isValid)};
    return all.where(keep.contains).toList();
  }
}
