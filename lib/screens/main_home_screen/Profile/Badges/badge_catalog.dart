import 'dart:math';
import 'package:mortaalim/screens/parents/parent_data.dart' show ActivityFeed;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Badge sprites (sliced from the two badge design sheets).
class BadgeAssets {
  BadgeAssets._();
  static const String dir = 'assets/images/UI/Badges/';
  static String of(String key) => '${dir}badge_$key.webp';
  static const String hero = '${dir}badge_hero.webp';
  static const String check = '${dir}badge_check.webp';
  static const String lock = '${dir}badge_lock.webp';
  static const String sparkle = '${dir}badge_sparkle.webp';
}

/// Everything the badge rules read, pulled from what the app already saves.
class BadgeStats {
  final Map<String, int> lessons; // "scope/subject" → lessons done ("" scope = school courses)
  final Map<String, int> plays; // game title → times opened
  final int streak, level, bbStars, bbCleared;

  const BadgeStats(this.lessons, this.plays, this.streak, this.level, this.bbStars, this.bbCleared);
  static const empty = BadgeStats({}, {}, 0, 1, 0, 0);

  int lesson(String scope, String subject) => lessons['$scope/$subject'] ?? 0;
  int scope(String scope) =>
      lessons.entries.where((e) => e.key.startsWith('$scope/')).fold(0, (a, e) => a + e.value);
  int play(String game) => plays[game] ?? 0;
  int get courseLessons => scope('');
  int get itLessons => scope('it');
  int get totalPlays => plays.values.fold(0, (a, b) => a + b);
  int get distinctGames => plays.values.where((v) => v > 0).length;
  int get artPlays => play('MagicPainting') + play('drawingAlphabet');

  static Future<BadgeStats> load({required int level}) async {
    final p = await SharedPreferences.getInstance();
    final lessons = <String, int>{};
    final plays = <String, int>{};
    var bbStars = 0, bbCleared = 0;
    for (final k in p.getKeys()) {
      final i = k.indexOf('lessons_done_');
      if (i >= 0 && (i == 0 || k[i - 1] == '_')) {
        final scope = i == 0 ? '' : k.substring(0, i - 1);
        final subject = k.substring(i + 'lessons_done_'.length);
        final n = (p.getStringList(k) ?? const []).length;
        lessons['$scope/$subject'] = (lessons['$scope/$subject'] ?? 0) + n;
      } else if (k.startsWith('games_plays_')) {
        plays[k.substring('games_plays_'.length)] = p.getInt(k) ?? 0;
      } else if (k.startsWith('bb2_stars_')) {
        final s = p.getInt(k) ?? 0;
        bbStars += s;
        if (s > 0) bbCleared++;
      }
    }
    return BadgeStats(lessons, plays, await _streak(p), level, bbStars, bbCleared);
  }

  /// Same rule as ActivityLog.streak (consecutive active days up to today/yesterday).
  static Future<int> _streak(SharedPreferences p) async {
    final days = (p.getStringList('activity_days') ?? const []).toSet();
    String key(DateTime d) => '${d.year}-${d.month}-${d.day}';
    var d = DateTime.now();
    if (!days.contains(key(d))) d = d.subtract(const Duration(days: 1));
    var n = 0;
    while (days.contains(key(d))) {
      n++;
      d = d.subtract(const Duration(days: 1));
    }
    return n;
  }
}

class AppBadge {
  final String id;
  final String art; // sprite key
  final int target;
  final int Function(BadgeStats) value;
  const AppBadge(this.id, this.art, this.target, this.value);

  String get asset => BadgeAssets.of(art);
  int progress(BadgeStats s) => min(value(s), target);
  bool earned(BadgeStats s) => value(s) >= target;
  double ratio(BadgeStats s) => progress(s) / target;
  String name(BuildContext c) => _text(c, id, 0);
  String how(BuildContext c) => _text(c, id, 1).replaceAll('{n}', '$target');
  String story(BuildContext c) => _text(c, id, 2);
}

/// All badges, easiest first.
final List<AppBadge> appBadges = [
  AppBadge('first_steps', 'star', 1, (s) => s.courseLessons + s.itLessons + s.scope('religion') + s.totalPlays),
  AppBadge('book_lover', 'book', 10, (s) => s.courseLessons),
  AppBadge('code_starter', 'robot', 1, (s) => s.itLessons),
  AppBadge('kind_heart', 'heart', 3, (s) => s.lesson('religion', 'manners') + s.scope('kindness')),
  AppBadge('young_artist', 'palette', 5, (s) => s.artPlays),
  AppBadge('puzzle_pro', 'puzzle', 15, (s) => s.bbStars),
  AppBadge('early_bird', 'sun', 3, (s) => s.streak),
  AppBadge('math_wizard', 'math', 8, (s) => s.lesson('', 'math')),
  AppBadge('word_explorer', 'abc', 10, (s) => s.play('WordExplorer') + s.play('WordLink') + s.lesson('', 'french')),
  AppBadge('nature_friend', 'leaf', 6, (s) => s.lesson('', 'science') + s.play('AnimalSounds')),
  AppBadge('quiz_champion', 'trophy', 10, (s) => s.play('quizGame')),
  AppBadge('music_maker', 'music', 5, (s) => s.play('Piano')),
  AppBadge('pure_drop', 'water', 3, (s) => s.lesson('religion', 'prayer')),
  AppBadge('little_scientist', 'microscope', 4, (s) => s.lesson('', 'science')),
  AppBadge('world_explorer', 'globe', 5, (s) => s.level),
  AppBadge('space_explorer', 'rocket', 8, (s) => s.distinctGames),
  AppBadge('quran_reader', 'lantern', 6, (s) => s.lesson('religion', 'quran')),
  AppBadge('adventurer', 'compass', 7, (s) => s.streak),
  AppBadge('creative_hands', 'hand', 15, (s) => s.artPlays),
  AppBadge('team_player', 'handshake', 30, (s) => s.totalPlays),
  AppBadge('little_muslim', 'mosque', 12,
      (s) => s.lesson('religion', 'quran') + s.lesson('religion', 'duas') + s.lesson('religion', 'prayer')),
  AppBadge('star_gazer', 'telescope', 45, (s) => s.bbStars),
  AppBadge('graduate', 'cap', 18, (s) => s.courseLessons),
  AppBadge('brain_master', 'crane', 72, (s) => s.bbCleared),
];

/// The locked badge the child is closest to (null when all are earned).
AppBadge? nextBadge(BadgeStats s) {
  AppBadge? best;
  for (final b in appBadges) {
    if (b.earned(s)) continue;
    if (best == null || b.ratio(s) > best.ratio(s)) best = b;
  }
  return best;
}

/// 3 badges for the profile preview: earned first, then the closest locked ones.
List<AppBadge> previewBadges(BadgeStats s) {
  final earned = appBadges.where((b) => b.earned(s)).toList();
  final locked = appBadges.where((b) => !b.earned(s)).toList()..sort((a, b) => b.ratio(s).compareTo(a.ratio(s)));
  return [...earned.reversed, ...locked].take(3).toList();
}

/// Badges earned since the last time the child looked; marks them as seen.
/// The very first call only records what is already earned (no flood of popups).
Future<List<AppBadge>> takeNewBadges(BadgeStats s) async {
  const key = 'badges_seen';
  final p = await SharedPreferences.getInstance();
  final earned = appBadges.where((b) => b.earned(s)).map((b) => b.id).toList();
  final seen = p.getStringList(key);
  await p.setStringList(key, earned);
  if (seen == null) return const [];
  final fresh = appBadges.where((b) => earned.contains(b.id) && !seen.contains(b.id)).toList();
  for (final b in fresh) {
    await ActivityFeed.add('badge', b.id);
  }
  return fresh;
}

// ─── Text ──────────────────────────────────────────────────────────────────

String _lang(BuildContext c) {
  final code = Localizations.localeOf(c).languageCode;
  if (_badgeText.containsKey(code)) return code;
  return code == 'zgh' ? 'fr' : 'en';
}

String _text(BuildContext c, String id, int field) {
  final v = _badgeText[_lang(c)]?[id] ?? _badgeText['en']![id]!;
  return field < v.length ? v[field] : _badgeText['en']![id]![field];
}

/// Page strings.
String badgeUi(BuildContext c, String key, [Map<String, Object>? args]) {
  var s = _ui[_lang(c)]?[key] ?? _ui['en']![key] ?? key;
  args?.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
  return s;
}

const Map<String, Map<String, String>> _ui = {
  'en': {
    'title': 'My Badges',
    'hero': 'Every step is an achievement',
    'unlockedN': '{n} / {t} unlocked',
    'all': 'All',
    'unlocked': 'Unlocked',
    'locked': 'Locked',
    'next': 'Next adventure',
    'allDone': 'You collected every badge!',
    'allDoneSub': 'You are a true MoorTaalim hero',
    'tap': 'Tap a badge to discover its story',
    'newBadge': 'New badge!',
    'earned': 'You earned this badge!',
    'keepGoing': 'Keep going, you can do it!',
    'none': 'No badges here yet',
  },
  'fr': {
    'title': 'Mes badges',
    'hero': 'Chaque pas est une réussite',
    'unlockedN': '{n} / {t} débloqués',
    'all': 'Tous',
    'unlocked': 'Débloqués',
    'locked': 'Verrouillés',
    'next': 'Prochaine aventure',
    'allDone': 'Tu as tous les badges !',
    'allDoneSub': 'Tu es un vrai héros de MoorTaalim',
    'tap': 'Touche un badge pour découvrir son histoire',
    'newBadge': 'Nouveau badge !',
    'earned': 'Tu as gagné ce badge !',
    'keepGoing': 'Continue, tu peux le faire !',
    'none': 'Pas encore de badges ici',
  },
  'ar': {
    'title': 'أوسمتي',
    'hero': 'كل خطوة هي إنجاز',
    'unlockedN': '{n} / {t} مفتوحة',
    'all': 'الكل',
    'unlocked': 'المفتوحة',
    'locked': 'المقفلة',
    'next': 'المغامرة التالية',
    'allDone': 'جمعت كل الأوسمة!',
    'allDoneSub': 'أنت بطل حقيقي في مُرتعلّم',
    'tap': 'اضغط على وسام لتكتشف قصته',
    'newBadge': 'وسام جديد!',
    'earned': 'لقد ربحت هذا الوسام!',
    'keepGoing': 'استمر، يمكنك فعلها!',
    'none': 'لا توجد أوسمة هنا بعد',
  },
  'de': {
    'title': 'Meine Abzeichen',
    'hero': 'Jeder Schritt ist ein Erfolg',
    'unlockedN': '{n} / {t} freigeschaltet',
    'all': 'Alle',
    'unlocked': 'Offen',
    'locked': 'Gesperrt',
    'next': 'Nächstes Abenteuer',
    'allDone': 'Du hast alle Abzeichen!',
    'allDoneSub': 'Du bist ein echter MoorTaalim-Held',
    'tap': 'Tippe auf ein Abzeichen für seine Geschichte',
    'newBadge': 'Neues Abzeichen!',
    'earned': 'Du hast dieses Abzeichen verdient!',
    'keepGoing': 'Weiter so, du schaffst das!',
    'none': 'Hier gibt es noch keine Abzeichen',
  },
};

/// id → [name, how to earn ({n} = target), story]
const Map<String, Map<String, List<String>>> _badgeText = {
  'en': {
    'first_steps': ['First Steps', 'Do your first lesson or game', 'Every big journey starts with one small step. You took yours!'],
    'book_lover': ['Book Lover', 'Finish {n} school lessons', 'Books are doors to new worlds, and you love opening them.'],
    'code_starter': ['Code Starter', 'Finish your first computer lesson', 'Robots and computers listen to people who learn to talk to them.'],
    'kind_heart': ['Kind Heart', 'Learn {n} good manners', 'A kind word and a smile make the whole world brighter.'],
    'young_artist': ['Young Artist', 'Draw or paint {n} times', 'Colors are your superpower. Keep creating beautiful things!'],
    'puzzle_pro': ['Puzzle Pro', 'Earn {n} stars in Brain Builder', 'You think, you try, you find the way. That is a real puzzle mind!'],
    'early_bird': ['Early Bird', 'Learn {n} days in a row', 'Like the sun, you show up every day and shine.'],
    'math_wizard': ['Math Wizard', 'Complete {n} math lessons', 'Numbers are magic spells, and you are learning them all.'],
    'word_explorer': ['Word Explorer', 'Complete {n} word activities', 'Every new word is a treasure you can keep forever.'],
    'nature_friend': ['Nature Friend', 'Complete {n} nature activities', 'Plants, animals and the sky: you care for all of them.'],
    'quiz_champion': ['Quiz Champion', 'Play {n} quizzes', 'Question after question, your brain grows stronger.'],
    'music_maker': ['Music Maker', 'Play the piano {n} times', 'Every note you play makes the day a little happier.'],
    'pure_drop': ['Pure Drop', 'Finish {n} prayer lessons', 'Clean hands and a clean heart are ready to pray.'],
    'little_scientist': ['Little Scientist', 'Finish {n} science lessons', 'You look closely and ask why. That is how scientists think!'],
    'world_explorer': ['World Explorer', 'Reach level {n}', 'You have travelled far on your learning map. Keep exploring!'],
    'space_explorer': ['Space Explorer', 'Try {n} different games', 'You blast off to new games and discover new planets of fun.'],
    'quran_reader': ['Quran Reader', 'Learn {n} surahs', 'The words of the Quran light up your heart like a lantern.'],
    'adventurer': ['Adventurer', 'Learn {n} days in a row', 'A whole week of learning! Your compass always points forward.'],
    'creative_hands': ['Creative Hands', 'Draw or paint {n} times', 'Your hands turn ideas into colorful art.'],
    'team_player': ['Team Player', 'Play {n} games', 'You play, you share, you have fun. Great friends do that!'],
    'little_muslim': ['Little Muslim', 'Finish {n} Islamic lessons', 'You learn your religion with love, step by step.'],
    'star_gazer': ['Star Gazer', 'Earn {n} stars in Brain Builder', 'You collected so many stars, the night sky is jealous!'],
    'graduate': ['Graduate', 'Finish all {n} school lessons', 'You finished every lesson. Hats off to you, champion!'],
    'brain_master': ['Brain Master', 'Finish all {n} Brain Builder levels', 'Mazes, stars and ice: you solved them all. True master!'],
  },
  'fr': {
    'first_steps': ['Premiers pas', 'Fais ta première leçon ou ton premier jeu', 'Chaque grand voyage commence par un petit pas. Tu as fait le tien !'],
    'book_lover': ['Ami des livres', 'Termine {n} leçons d\'école', 'Les livres ouvrent des portes vers de nouveaux mondes.'],
    'code_starter': ['Petit codeur', 'Termine ta première leçon d\'informatique', 'Les robots écoutent ceux qui apprennent à leur parler.'],
    'kind_heart': ['Cœur gentil', 'Apprends {n} bonnes manières', 'Un mot gentil et un sourire illuminent le monde.'],
    'young_artist': ['Jeune artiste', 'Dessine ou peins {n} fois', 'Les couleurs sont ton super-pouvoir. Continue à créer !'],
    'puzzle_pro': ['Pro des puzzles', 'Gagne {n} étoiles dans Brain Builder', 'Tu réfléchis, tu essaies, tu trouves le chemin. Bravo !'],
    'early_bird': ['Lève-tôt', 'Apprends {n} jours de suite', 'Comme le soleil, tu reviens chaque jour pour briller.'],
    'math_wizard': ['Magicien des maths', 'Termine {n} leçons de maths', 'Les nombres sont des formules magiques, et tu les apprends toutes.'],
    'word_explorer': ['Explorateur de mots', 'Fais {n} activités de mots', 'Chaque nouveau mot est un trésor à garder pour toujours.'],
    'nature_friend': ['Ami de la nature', 'Fais {n} activités nature', 'Plantes, animaux et ciel : tu prends soin de tout.'],
    'quiz_champion': ['Champion des quiz', 'Joue {n} quiz', 'Question après question, ton cerveau devient plus fort.'],
    'music_maker': ['Petit musicien', 'Joue du piano {n} fois', 'Chaque note rend la journée plus joyeuse.'],
    'pure_drop': ['Goutte pure', 'Termine {n} leçons de prière', 'Des mains propres et un cœur pur sont prêts pour la prière.'],
    'little_scientist': ['Petit scientifique', 'Termine {n} leçons de sciences', 'Tu observes et tu demandes pourquoi : comme un vrai scientifique !'],
    'world_explorer': ['Explorateur du monde', 'Atteins le niveau {n}', 'Tu as voyagé loin sur ta carte du savoir. Continue !'],
    'space_explorer': ['Explorateur de l\'espace', 'Essaie {n} jeux différents', 'Tu décolles vers de nouveaux jeux et de nouvelles planètes.'],
    'quran_reader': ['Lecteur du Coran', 'Apprends {n} sourates', 'Les paroles du Coran éclairent ton cœur comme une lanterne.'],
    'adventurer': ['Aventurier', 'Apprends {n} jours de suite', 'Une semaine entière ! Ta boussole pointe toujours vers l\'avant.'],
    'creative_hands': ['Mains créatives', 'Dessine ou peins {n} fois', 'Tes mains transforment les idées en œuvres colorées.'],
    'team_player': ['Bon camarade', 'Joue {n} parties', 'Tu joues, tu partages, tu t\'amuses. C\'est ça l\'amitié !'],
    'little_muslim': ['Petit musulman', 'Termine {n} leçons islamiques', 'Tu apprends ta religion avec amour, pas à pas.'],
    'star_gazer': ['Chasseur d\'étoiles', 'Gagne {n} étoiles dans Brain Builder', 'Tant d\'étoiles ! Le ciel est jaloux !'],
    'graduate': ['Diplômé', 'Termine les {n} leçons d\'école', 'Tu as fini toutes les leçons. Chapeau, champion !'],
    'brain_master': ['Maître du cerveau', 'Termine les {n} niveaux de Brain Builder', 'Labyrinthes, étoiles et glace : tu as tout résolu !'],
  },
  'ar': {
    'first_steps': ['الخطوات الأولى', 'أكمل أول درس أو لعبة', 'كل رحلة كبيرة تبدأ بخطوة صغيرة، وقد خطوتها!'],
    'book_lover': ['محب الكتب', 'أكمل {n} دروس مدرسية', 'الكتب أبواب لعوالم جديدة، وأنت تحب فتحها.'],
    'code_starter': ['المبرمج الصغير', 'أكمل أول درس في الحاسوب', 'الروبوتات تستمع لمن يتعلم التحدث معها.'],
    'kind_heart': ['القلب الطيب', 'تعلّم {n} آداب جميلة', 'كلمة طيبة وابتسامة تجعل العالم أجمل.'],
    'young_artist': ['الفنان الصغير', 'ارسم أو لوّن {n} مرات', 'الألوان قوتك الخارقة، استمر في الإبداع!'],
    'puzzle_pro': ['بطل الألغاز', 'اربح {n} نجمة في باني الذكاء', 'تفكر وتجرب وتجد الطريق، هذا عقل الأبطال!'],
    'early_bird': ['الطائر المبكر', 'تعلّم {n} أيام متتالية', 'مثل الشمس، تأتي كل يوم لتشرق.'],
    'math_wizard': ['ساحر الرياضيات', 'أكمل {n} دروس رياضيات', 'الأرقام تعويذات سحرية، وأنت تتعلمها كلها.'],
    'word_explorer': ['مستكشف الكلمات', 'أكمل {n} أنشطة كلمات', 'كل كلمة جديدة كنز تحتفظ به إلى الأبد.'],
    'nature_friend': ['صديق الطبيعة', 'أكمل {n} أنشطة عن الطبيعة', 'النباتات والحيوانات والسماء، أنت تهتم بها كلها.'],
    'quiz_champion': ['بطل المسابقات', 'العب {n} مسابقات', 'سؤالاً بعد سؤال، يصبح عقلك أقوى.'],
    'music_maker': ['صانع الموسيقى', 'اعزف على البيانو {n} مرات', 'كل نغمة تعزفها تجعل اليوم أسعد.'],
    'pure_drop': ['القطرة الطاهرة', 'أكمل {n} دروس عن الصلاة', 'يدان نظيفتان وقلب طاهر، مستعد للصلاة.'],
    'little_scientist': ['العالِم الصغير', 'أكمل {n} دروس علوم', 'تلاحظ وتسأل لماذا، هكذا يفكر العلماء!'],
    'world_explorer': ['مستكشف العالم', 'صل إلى المستوى {n}', 'سافرت بعيداً في خريطة تعلمك، واصل الاستكشاف!'],
    'space_explorer': ['مستكشف الفضاء', 'جرّب {n} ألعاب مختلفة', 'تنطلق نحو ألعاب جديدة وكواكب مليئة بالمرح.'],
    'quran_reader': ['قارئ القرآن', 'تعلّم {n} سور', 'كلمات القرآن تضيء قلبك مثل الفانوس.'],
    'adventurer': ['المغامر', 'تعلّم {n} أيام متتالية', 'أسبوع كامل من التعلم! بوصلتك دائماً إلى الأمام.'],
    'creative_hands': ['الأيدي المبدعة', 'ارسم أو لوّن {n} مرة', 'يداك تحولان الأفكار إلى فن ملوّن.'],
    'team_player': ['الصديق الوفي', 'العب {n} لعبة', 'تلعب وتشارك وتستمتع، هكذا يفعل الأصدقاء!'],
    'little_muslim': ['المسلم الصغير', 'أكمل {n} درساً إسلامياً', 'تتعلم دينك بحب، خطوة بخطوة.'],
    'star_gazer': ['صائد النجوم', 'اربح {n} نجمة في باني الذكاء', 'جمعت نجوماً كثيرة حتى غارت منك السماء!'],
    'graduate': ['المتخرج', 'أكمل كل الدروس المدرسية ({n})', 'أنهيت كل الدروس، تحية لك يا بطل!'],
    'brain_master': ['سيد الذكاء', 'أكمل كل مستويات باني الذكاء ({n})', 'المتاهات والنجوم والجليد، حللتها كلها!'],
  },
  'de': {
    'first_steps': ['Erste Schritte', 'Mach deine erste Lektion oder dein erstes Spiel'],
    'book_lover': ['Bücherfreund', 'Schaffe {n} Schullektionen'],
    'code_starter': ['Code-Starter', 'Schaffe deine erste Computerlektion'],
    'kind_heart': ['Gutes Herz', 'Lerne {n} gute Manieren'],
    'young_artist': ['Junger Künstler', 'Male {n} Mal'],
    'puzzle_pro': ['Rätsel-Profi', 'Sammle {n} Sterne in Brain Builder'],
    'early_bird': ['Frühaufsteher', 'Lerne {n} Tage am Stück'],
    'math_wizard': ['Mathe-Zauberer', 'Schaffe {n} Mathe-Lektionen'],
    'word_explorer': ['Wort-Entdecker', 'Schaffe {n} Wort-Aufgaben'],
    'nature_friend': ['Naturfreund', 'Schaffe {n} Natur-Aufgaben'],
    'quiz_champion': ['Quiz-Champion', 'Spiele {n} Quiz'],
    'music_maker': ['Musikmacher', 'Spiele {n} Mal Klavier'],
    'pure_drop': ['Reiner Tropfen', 'Schaffe {n} Gebetslektionen'],
    'little_scientist': ['Kleiner Forscher', 'Schaffe {n} Wissenschaftslektionen'],
    'world_explorer': ['Weltentdecker', 'Erreiche Level {n}'],
    'space_explorer': ['Weltraumforscher', 'Probiere {n} verschiedene Spiele'],
    'quran_reader': ['Koranleser', 'Lerne {n} Suren'],
    'adventurer': ['Abenteurer', 'Lerne {n} Tage am Stück'],
    'creative_hands': ['Kreative Hände', 'Male {n} Mal'],
    'team_player': ['Teamspieler', 'Spiele {n} Spiele'],
    'little_muslim': ['Kleiner Muslim', 'Schaffe {n} islamische Lektionen'],
    'star_gazer': ['Sternegucker', 'Sammle {n} Sterne in Brain Builder'],
    'graduate': ['Absolvent', 'Schaffe alle {n} Schullektionen'],
    'brain_master': ['Denkmeister', 'Schaffe alle {n} Brain-Builder-Level'],
  },
};
