/// The one list of profile banners in the app.
///
/// Every screen (onboarding, shop, collection, profile, themes) reads from
/// here. Saved data that still points at a removed banner is cleaned by
/// [BannerCatalog.resolve] / [BannerCatalog.sanitizeUnlocked], so old users
/// never see a missing image.
///
/// To add banners later: drop the file in `assets/images/Banners/Kids/`,
/// add a constant, put it in [all], and give it a price in [shop]
/// (cost 0 + in [starter] = free for everyone).
class BannerCatalog {
  BannerCatalog._();

  static const String dir = 'assets/images/Banners/Kids/';

  static const String space = '${dir}space.webp';
  static const String jungle = '${dir}jungle.webp';
  static const String mountains = '${dir}mountains.webp';
  static const String ocean = '${dir}ocean.webp';
  static const String rainbow = '${dir}rainbow.webp';
  static const String library = '${dir}library.webp';
  static const String candy = '${dir}candy.webp';
  static const String dinos = '${dir}dinos.webp';

  // Paid (shop)
  static const String winter = '${dir}winter.webp';
  static const String train = '${dir}train.webp';
  static const String skyIslands = '${dir}sky_islands.webp';
  static const String robotLab = '${dir}robot_lab.webp';
  static const String savanna = '${dir}savanna.webp';
  static const String mushroomVillage = '${dir}mushroom_village.webp';
  static const String beach = '${dir}beach.webp';
  static const String kites = '${dir}kites.webp';
  static const String crystalCave = '${dir}crystal_cave.webp';
  static const String gardenBugs = '${dir}garden_bugs.webp';

  static const List<String> all = [
    space, jungle, mountains, ocean, rainbow, library, candy, dinos,
    winter, train, skyIslands, robotLab,
    savanna, beach, kites, gardenBugs, mushroomVillage, crystalCave,
  ];

  /// Free & unlocked for every user (these are the ones offered in onboarding).
  static const List<String> starter = [
    space, jungle, mountains, ocean, rainbow, library, candy, dinos,
  ];

  static const String defaultBanner = space;

  /// Shop grid entries (same shape the shop's ImageBannerGrid expects).
  static const List<Map<String, dynamic>> shop = [
    {'image': space, 'rarity': 'COMMON', 'cost': 0},
    {'image': jungle, 'rarity': 'COMMON', 'cost': 0},
    {'image': mountains, 'rarity': 'COMMON', 'cost': 0},
    {'image': ocean, 'rarity': 'COMMON', 'cost': 0},
    {'image': rainbow, 'rarity': 'COMMON', 'cost': 0},
    {'image': library, 'rarity': 'COMMON', 'cost': 0},
    {'image': candy, 'rarity': 'COMMON', 'cost': 0},
    {'image': dinos, 'rarity': 'COMMON', 'cost': 0},
    {'image': winter, 'rarity': 'RARE', 'cost': 150},
    {'image': train, 'rarity': 'RARE', 'cost': 200},
    {'image': skyIslands, 'rarity': 'LEGENDARY', 'cost': 300},
    {'image': robotLab, 'rarity': 'LEGENDARY', 'cost': 400},
    {'image': savanna, 'rarity': 'COMMON', 'cost': 100},
    {'image': beach, 'rarity': 'COMMON', 'cost': 100},
    {'image': kites, 'rarity': 'RARE', 'cost': 150},
    {'image': gardenBugs, 'rarity': 'RARE', 'cost': 200},
    {'image': mushroomVillage, 'rarity': 'LEGENDARY', 'cost': 350},
    {'image': crystalCave, 'rarity': 'LEGENDARY', 'cost': 450},
  ];

  static bool isValid(String? path) => path != null && all.contains(path);

  /// A valid banner path: the given one if it still exists, else the default.
  static String resolve(String? path) => isValid(path) ? path! : defaultBanner;

  /// Keeps only banners that still exist, always including the starter set.
  static List<String> sanitizeUnlocked(Iterable<String>? unlocked) {
    final keep = <String>{...starter, ...?unlocked?.where(isValid)};
    return all.where(keep.contains).toList();
  }

  /// Banner shown on the profile page for a given level.
  static String forLevel(int level) {
    if (level >= 35) return library;
    if (level >= 25) return rainbow;
    if (level >= 15) return ocean;
    if (level >= 7) return mountains;
    if (level >= 5) return jungle;
    return space;
  }
}
