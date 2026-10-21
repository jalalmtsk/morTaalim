/// The one list of avatars in the app.
///
/// Onboarding, the shop, the collection and the profile all read from here.
/// Saved data that still points at a removed avatar (old images, emojis,
/// animated avatars) is cleaned by [AvatarCatalog.resolve] /
/// [AvatarCatalog.sanitizeUnlocked], so old users never see a broken avatar.
///
/// 2026-10: the whole set was redrawn (512×512). The 18 original file names
/// were kept (same character, new art) so every saved choice still works, and
/// 22 new characters were added.
///
/// To add avatars later: drop a square 512×512 image in
/// `assets/images/AvatarImage/Kids/`, add a constant, put it in [all],
/// give it a name in [_names], mark it in [companions] if it is not a child,
/// and give it a price in [shop] (cost 0 + in [starter] = free for everyone).
class AvatarCatalog {
  AvatarCatalog._();

  static const String dir = 'assets/images/AvatarImage/Kids/';

  // ── Original 18 (redrawn, same files) ──────────────────────────────────
  static const String mascot = '${dir}mascot.webp';
  static const String boyCurly = '${dir}boy_curly.webp';
  static const String girlGlasses = '${dir}girl_glasses.webp';
  static const String girlHijab = '${dir}girl_hijab.webp';
  static const String boyGinger = '${dir}boy_ginger.webp';
  static const String fox = '${dir}fox.webp';
  static const String robot = '${dir}robot.webp';
  static const String girlPuffs = '${dir}girl_puffs.webp';
  static const String boyBlackHair = '${dir}boy_black_hair.webp';
  static const String boyHoodie = '${dir}boy_hoodie.webp';
  static const String girlBraids = '${dir}girl_braids.webp';
  static const String robotBlue = '${dir}robot_blue.webp';
  static const String foxCub = '${dir}fox_cub.webp';
  static const String panda = '${dir}panda.webp';
  static const String kitty = '${dir}kitty.webp';
  static const String astronaut = '${dir}astronaut.webp';
  static const String girlHijabPurple = '${dir}girl_hijab_purple.webp';
  static const String dragon = '${dir}dragon.webp';

  // ── New 22 ─────────────────────────────────────────────────────────────
  static const String girlWavy = '${dir}girl_wavy.webp';
  static const String redPanda = '${dir}red_panda.webp';
  static const String boyGlasses = '${dir}boy_glasses.webp';
  static const String unicorn = '${dir}unicorn.webp';
  static const String girlHijabCoral = '${dir}girl_hijab_coral.webp';
  static const String penguin = '${dir}penguin.webp';
  static const String girlBuns = '${dir}girl_buns.webp';
  static const String puppy = '${dir}puppy.webp';
  static const String girlInventor = '${dir}girl_inventor.webp';
  static const String axolotl = '${dir}axolotl.webp';
  static const String robotScreen = '${dir}robot_screen.webp';
  static const String lionExplorer = '${dir}lion_explorer.webp';
  static const String boyChef = '${dir}boy_chef.webp';
  static const String otter = '${dir}otter.webp';
  static const String girlElf = '${dir}girl_elf.webp';
  static const String triceratops = '${dir}triceratops.webp';
  static const String koala = '${dir}koala.webp';
  static const String girlAviator = '${dir}girl_aviator.webp';
  static const String bunny = '${dir}bunny.webp';
  static const String boyWizard = '${dir}boy_wizard.webp';
  static const String turtle = '${dir}turtle.webp';
  static const String owl = '${dir}owl.webp';

  /// Display order: kids and buddies mixed so every row feels fun.
  static const List<String> all = [
    boyHoodie, girlBraids, foxCub, astronaut,
    girlHijabPurple, panda, boyCurly, kitty,
    girlGlasses, dragon, boyGinger, puppy,
    girlPuffs, robotBlue, boyBlackHair, unicorn,
    girlHijab, fox, boyGlasses, penguin,
    girlWavy, redPanda, girlBuns, koala,
    girlHijabCoral, bunny, boyWizard, owl,
    girlInventor, axolotl, boyChef, turtle,
    girlAviator, lionExplorer, girlElf, otter,
    robot, triceratops, robotScreen, mascot,
  ];

  /// Animals, robots and creatures (shown in the "Buddies" tab).
  static const Set<String> companions = {
    foxCub, panda, kitty, dragon, puppy, robotBlue, unicorn, fox, penguin, redPanda, koala, bunny, owl,
    axolotl, turtle, lionExplorer, otter, robot, triceratops, robotScreen, mascot,
  };

  static bool isCompanion(String path) => companions.contains(path);

  /// Unlocked for every user: the 9 avatars offered during onboarding.
  /// All the others are locked and bought with gems ([costOf]).
  static const List<String> starter = [
    boyHoodie, girlBraids, foxCub, astronaut,
    girlHijabPurple, panda, boyCurly, kitty, girlGlasses,
  ];

  static bool isStarter(String path) => starter.contains(path);

  /// Gem price of an avatar (0 for the starter ones).
  static int costOf(String path) {
    for (final e in shop) {
      if (e['image'] == path) return e['cost'] as int;
    }
    return 0;
  }

  static const String defaultAvatar = boyHoodie;

  /// Shop grid entries (same shape the shop's ImageAvatarGrid expects).
  static const List<Map<String, dynamic>> shop = [
    {'image': boyHoodie, 'cost': 0},
    {'image': girlBraids, 'cost': 0},
    {'image': foxCub, 'cost': 0},
    {'image': astronaut, 'cost': 0},
    {'image': girlHijabPurple, 'cost': 0},
    {'image': panda, 'cost': 0},
    {'image': boyCurly, 'cost': 0},
    {'image': kitty, 'cost': 0},
    {'image': girlGlasses, 'cost': 0},
    {'image': dragon, 'cost': 10},
    {'image': boyGinger, 'cost': 10},
    {'image': puppy, 'cost': 10},
    {'image': girlPuffs, 'cost': 10},
    {'image': robotBlue, 'cost': 10},
    {'image': boyBlackHair, 'cost': 10},
    {'image': unicorn, 'cost': 10},
    {'image': girlHijab, 'cost': 10},
    {'image': fox, 'cost': 10},
    {'image': boyGlasses, 'cost': 15},
    {'image': penguin, 'cost': 15},
    {'image': girlWavy, 'cost': 15},
    {'image': redPanda, 'cost': 15},
    {'image': girlBuns, 'cost': 15},
    {'image': koala, 'cost': 15},
    {'image': girlHijabCoral, 'cost': 15},
    {'image': bunny, 'cost': 15},
    {'image': boyWizard, 'cost': 15},
    {'image': owl, 'cost': 20},
    {'image': girlInventor, 'cost': 20},
    {'image': axolotl, 'cost': 20},
    {'image': boyChef, 'cost': 20},
    {'image': turtle, 'cost': 20},
    {'image': girlAviator, 'cost': 20},
    {'image': lionExplorer, 'cost': 20},
    {'image': girlElf, 'cost': 20},
    {'image': otter, 'cost': 20},
    {'image': robot, 'cost': 25},
    {'image': triceratops, 'cost': 25},
    {'image': robotScreen, 'cost': 25},
    {'image': mascot, 'cost': 25},
  ];

  static bool isValid(String? path) => path != null && all.contains(path);

  /// A valid avatar: the given one if it still exists, else the default.
  static String resolve(String? path) => isValid(path) ? path! : defaultAvatar;

  /// Keeps only avatars that still exist, always including the starter set.
  static List<String> sanitizeUnlocked(Iterable<String>? unlocked) {
    var saved = unlocked?.where(isValid).toSet() ?? <String>{};
    // Older builds unlocked every avatar for free: go back to the starter set.
    if (saved.length == all.length) saved = <String>{};
    final keep = <String>{...starter, ...saved};
    return all.where(keep.contains).toList();
  }

  /// Full-body picture of an avatar (transparent cut-out, no background).
  static const String fullDir = 'assets/images/AvatarImage/KidsFull/';
  static String fullBody(String path) => '$fullDir${resolve(path).split('/').last}';

  /// width / height of the full-body picture.
  static double fullAspect(String path) {
    final key = resolve(path).split('/').last.replaceAll('.webp', '');
    return _fullAspects[key] ?? 0.5;
  }

  static const Map<String, double> _fullAspects = {'panda': 0.4526, 'girl_braids': 0.419, 'girl_glasses': 0.4329, 'girl_hijab': 0.3723, 'girl_hijab_purple': 0.4642, 'girl_puffs': 0.4499, 'kitty': 0.5836, 'mascot': 0.4745, 'astronaut': 0.444, 'fox': 0.5804, 'boy_black_hair': 0.4095, 'boy_curly': 0.4052, 'boy_ginger': 0.3954, 'boy_hoodie': 0.423, 'dragon': 0.4989, 'fox_cub': 0.547, 'girl_wavy': 0.5228, 'red_panda': 0.6086, 'boy_glasses': 0.4283, 'unicorn': 0.59, 'girl_hijab_coral': 0.4335, 'penguin': 0.7701, 'girl_buns': 0.4917, 'puppy': 0.6193, 'robot': 0.7156, 'robot_blue': 0.73, 'koala': 0.8333, 'girl_aviator': 0.6557, 'bunny': 0.8426, 'boy_wizard': 0.7281, 'turtle': 0.8396, 'owl': 0.8025, 'girl_inventor': 0.5219, 'axolotl': 0.7256, 'robot_screen': 0.531, 'lion_explorer': 0.5574, 'boy_chef': 0.4559, 'otter': 0.6321, 'girl_elf': 0.5534, 'triceratops': 0.7006};

  /// Friendly name of an avatar in [lang] ('fr', 'en', 'ar', 'de').
  static String nameOf(String path, String lang) {
    final key = path.split('/').last.replaceAll('.webp', '');
    final n = _names[key];
    if (n == null) return '';
    return n[lang] ?? n['en'] ?? '';
  }

  static const Map<String, Map<String, String>> _names = {
    'boy_hoodie': {'fr': 'Adam', 'en': 'Adam', 'ar': 'آدم', 'de': 'Adam'},
    'girl_braids': {'fr': 'Lina', 'en': 'Lina', 'ar': 'لينا', 'de': 'Lina'},
    'fox_cub': {'fr': 'Renardeau', 'en': 'Foxy', 'ar': 'ثعلوب', 'de': 'Füchslein'},
    'astronaut': {'fr': 'Astronaute', 'en': 'Astronaut', 'ar': 'رائد الفضاء', 'de': 'Astronaut'},
    'girl_hijab_purple': {'fr': 'Nour', 'en': 'Nour', 'ar': 'نور', 'de': 'Nour'},
    'panda': {'fr': 'Panda', 'en': 'Panda', 'ar': 'باندا', 'de': 'Panda'},
    'boy_curly': {'fr': 'Yassine', 'en': 'Yassine', 'ar': 'ياسين', 'de': 'Yassine'},
    'kitty': {'fr': 'Chaton', 'en': 'Kitty', 'ar': 'قطيطة', 'de': 'Kätzchen'},
    'girl_glasses': {'fr': 'Salma', 'en': 'Salma', 'ar': 'سلمى', 'de': 'Salma'},
    'dragon': {'fr': 'Dragon', 'en': 'Dragon', 'ar': 'التنين', 'de': 'Drache'},
    'boy_ginger': {'fr': 'Ilyes', 'en': 'Ilyes', 'ar': 'إلياس', 'de': 'Ilyes'},
    'puppy': {'fr': 'Toutou', 'en': 'Puppy', 'ar': 'جرو', 'de': 'Welpe'},
    'girl_puffs': {'fr': 'Maya', 'en': 'Maya', 'ar': 'مايا', 'de': 'Maya'},
    'robot_blue': {'fr': 'Robo', 'en': 'Robo', 'ar': 'روبو', 'de': 'Robo'},
    'boy_black_hair': {'fr': 'Omar', 'en': 'Omar', 'ar': 'عمر', 'de': 'Omar'},
    'unicorn': {'fr': 'Licorne', 'en': 'Unicorn', 'ar': 'وحيد القرن', 'de': 'Einhorn'},
    'girl_hijab': {'fr': 'Amina', 'en': 'Amina', 'ar': 'أمينة', 'de': 'Amina'},
    'fox': {'fr': 'Renard', 'en': 'Fox', 'ar': 'الثعلب', 'de': 'Fuchs'},
    'boy_glasses': {'fr': 'Karim', 'en': 'Karim', 'ar': 'كريم', 'de': 'Karim'},
    'penguin': {'fr': 'Pingouin', 'en': 'Penguin', 'ar': 'البطريق', 'de': 'Pinguin'},
    'girl_wavy': {'fr': 'Sara', 'en': 'Sara', 'ar': 'سارة', 'de': 'Sara'},
    'red_panda': {'fr': 'Panda roux', 'en': 'Red panda', 'ar': 'الباندا الحمراء', 'de': 'Roter Panda'},
    'girl_buns': {'fr': 'Hiba', 'en': 'Hiba', 'ar': 'هبة', 'de': 'Hiba'},
    'koala': {'fr': 'Koala', 'en': 'Koala', 'ar': 'كوالا', 'de': 'Koala'},
    'girl_hijab_coral': {'fr': 'Khadija', 'en': 'Khadija', 'ar': 'خديجة', 'de': 'Khadija'},
    'bunny': {'fr': 'Lapinou', 'en': 'Bunny', 'ar': 'أرنوب', 'de': 'Häschen'},
    'boy_wizard': {'fr': 'Petit mage', 'en': 'Little wizard', 'ar': 'الساحر الصغير', 'de': 'Kleiner Zauberer'},
    'owl': {'fr': 'Hibou', 'en': 'Owl', 'ar': 'البومة', 'de': 'Eule'},
    'girl_inventor': {'fr': 'Inventrice', 'en': 'Inventor', 'ar': 'المخترعة', 'de': 'Erfinderin'},
    'axolotl': {'fr': 'Axolotl', 'en': 'Axolotl', 'ar': 'أكسولوتل', 'de': 'Axolotl'},
    'boy_chef': {'fr': 'Petit chef', 'en': 'Little chef', 'ar': 'الطاهي الصغير', 'de': 'Kleiner Koch'},
    'turtle': {'fr': 'Tortue', 'en': 'Turtle', 'ar': 'السلحفاة', 'de': 'Schildkröte'},
    'girl_aviator': {'fr': 'Aviatrice', 'en': 'Pilot', 'ar': 'الطيّارة', 'de': 'Pilotin'},
    'lion_explorer': {'fr': 'Lionceau', 'en': 'Lion cub', 'ar': 'الشبل', 'de': 'Löwenjunges'},
    'girl_elf': {'fr': 'Fée des bois', 'en': 'Forest elf', 'ar': 'جنية الغابة', 'de': 'Waldelfe'},
    'otter': {'fr': 'Loutre', 'en': 'Otter', 'ar': 'ثعلب الماء', 'de': 'Otter'},
    'robot': {'fr': 'Bip', 'en': 'Beep', 'ar': 'بيب', 'de': 'Piep'},
    'triceratops': {'fr': 'Tricératops', 'en': 'Triceratops', 'ar': 'ترايسيراتوبس', 'de': 'Triceratops'},
    'robot_screen': {'fr': 'Pixel', 'en': 'Pixel', 'ar': 'بيكسل', 'de': 'Pixel'},
    'mascot': {'fr': 'Moori', 'en': 'Moori', 'ar': 'موري', 'de': 'Moori'},
  };
}
