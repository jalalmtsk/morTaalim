import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Animal Sounds — the 19 animals that have a real sound file, their art,
/// their scene, localized names and the "sound word" shown in the bubble.

const String asDir = 'assets/images/UI/KidScene/';
const String asSoundDir = 'assets/audios/Animals_sounds/Animals_sound/';

enum AsGroup { home, wild, sea, sky }

class AsAnimal {
  final String id;
  final AsGroup group;
  final String soundFile;
  final Map<String, String> names; // fr · en · ar · de
  final Map<String, String> says; // the bubble text
  const AsAnimal(this.id, this.group, this.soundFile, this.names, this.says);

  String get sprite => '${asDir}as_$id.webp';
  String get scene => '${asDir}as_bg_$id.webp';
  String get sound => '$asSoundDir$soundFile';

  String name(BuildContext c) => names[asLang(c)] ?? names['en']!;
  String bubble(BuildContext c) => says[asLang(c)] ?? says['en']!;
}

const List<AsAnimal> asAnimals = [
  AsAnimal('dog', AsGroup.home, 'Dog_sound.mp3',
      {'en': 'Dog', 'fr': 'Chien', 'ar': 'كلب', 'de': 'Hund'},
      {'en': 'Woof!', 'fr': 'Ouaf !', 'ar': 'هو هو!', 'de': 'Wuff!'}),
  AsAnimal('cat', AsGroup.home, 'Cat_Sound.mp3',
      {'en': 'Cat', 'fr': 'Chat', 'ar': 'قطة', 'de': 'Katze'},
      {'en': 'Meow!', 'fr': 'Miaou !', 'ar': 'مياو!', 'de': 'Miau!'}),
  AsAnimal('horse', AsGroup.home, 'Horse_sound.mp3',
      {'en': 'Horse', 'fr': 'Cheval', 'ar': 'حصان', 'de': 'Pferd'},
      {'en': 'Neigh!', 'fr': 'Hiii !', 'ar': 'هيييه!', 'de': 'Wieher!'}),
  AsAnimal('rabbit', AsGroup.home, 'Rabbit_sound.mp3',
      {'en': 'Rabbit', 'fr': 'Lapin', 'ar': 'أرنب', 'de': 'Hase'},
      {'en': 'Sniff!', 'fr': 'Snif !', 'ar': 'سنف!', 'de': 'Schnupper!'}),
  AsAnimal('lion', AsGroup.wild, 'Lion_sound.mp3',
      {'en': 'Lion', 'fr': 'Lion', 'ar': 'أسد', 'de': 'Löwe'},
      {'en': 'Roar!', 'fr': 'Groar !', 'ar': 'زئير!', 'de': 'Brüll!'}),
  AsAnimal('tiger', AsGroup.wild, 'Tiger_sound.mp3',
      {'en': 'Tiger', 'fr': 'Tigre', 'ar': 'نمر', 'de': 'Tiger'},
      {'en': 'Grrr!', 'fr': 'Grrr !', 'ar': 'غرر!', 'de': 'Grrr!'}),
  AsAnimal('elephant', AsGroup.wild, 'Elephant_sound.mp3',
      {'en': 'Elephant', 'fr': 'Éléphant', 'ar': 'فيل', 'de': 'Elefant'},
      {'en': 'Toot!', 'fr': 'Pouêt !', 'ar': 'بووو!', 'de': 'Törö!'}),
  AsAnimal('monkey', AsGroup.wild, 'Monkey_sound.mp3',
      {'en': 'Monkey', 'fr': 'Singe', 'ar': 'قرد', 'de': 'Affe'},
      {'en': 'Ooh ooh!', 'fr': 'Hou hou !', 'ar': 'أو أو!', 'de': 'Uh uh!'}),
  AsAnimal('gorilla', AsGroup.wild, 'Gorilla_sound.mp3',
      {'en': 'Gorilla', 'fr': 'Gorille', 'ar': 'غوريلا', 'de': 'Gorilla'},
      {'en': 'Hoo hoo!', 'fr': 'Ho ho !', 'ar': 'هوو!', 'de': 'Hu hu!'}),
  AsAnimal('bear', AsGroup.wild, 'Bear_sound.mp3',
      {'en': 'Bear', 'fr': 'Ours', 'ar': 'دب', 'de': 'Bär'},
      {'en': 'Growl!', 'fr': 'Grrr !', 'ar': 'غرر!', 'de': 'Brumm!'}),
  AsAnimal('wolf', AsGroup.wild, 'Wolf_sound.mp3',
      {'en': 'Wolf', 'fr': 'Loup', 'ar': 'ذئب', 'de': 'Wolf'},
      {'en': 'Awoo!', 'fr': 'Aouuu !', 'ar': 'عووو!', 'de': 'Auuu!'}),
  AsAnimal('fox', AsGroup.wild, 'Fox_sound.mp3',
      {'en': 'Fox', 'fr': 'Renard', 'ar': 'ثعلب', 'de': 'Fuchs'},
      {'en': 'Yip!', 'fr': 'Yip !', 'ar': 'ياب!', 'de': 'Kläff!'}),
  AsAnimal('deer', AsGroup.wild, 'Deer_sound.mp3',
      {'en': 'Deer', 'fr': 'Cerf', 'ar': 'غزال', 'de': 'Reh'},
      {'en': 'Mweh!', 'fr': 'Mêê !', 'ar': 'ماا!', 'de': 'Möh!'}),
  AsAnimal('snake', AsGroup.wild, 'Snake_sound.mp3',
      {'en': 'Snake', 'fr': 'Serpent', 'ar': 'أفعى', 'de': 'Schlange'},
      {'en': 'Hiss!', 'fr': 'Sss !', 'ar': 'ششش!', 'de': 'Zisch!'}),
  AsAnimal('dolphin', AsGroup.sea, 'Dolphin_sound.mp3',
      {'en': 'Dolphin', 'fr': 'Dauphin', 'ar': 'دلفين', 'de': 'Delfin'},
      {'en': 'Click click!', 'fr': 'Clic clic !', 'ar': 'تك تك!', 'de': 'Klick klick!'}),
  AsAnimal('whale', AsGroup.sea, 'Whale_sound.mp3',
      {'en': 'Whale', 'fr': 'Baleine', 'ar': 'حوت', 'de': 'Wal'},
      {'en': 'Wooo!', 'fr': 'Ouuuh !', 'ar': 'ووو!', 'de': 'Huuu!'}),
  AsAnimal('shark', AsGroup.sea, 'Shark_sound.mp3',
      {'en': 'Shark', 'fr': 'Requin', 'ar': 'قرش', 'de': 'Hai'},
      {'en': 'Chomp!', 'fr': 'Croc !', 'ar': 'قضم!', 'de': 'Schnapp!'}),
  AsAnimal('eagle', AsGroup.sky, 'Eagle_sound.mp3',
      {'en': 'Eagle', 'fr': 'Aigle', 'ar': 'نسر', 'de': 'Adler'},
      {'en': 'Screech!', 'fr': 'Kriii !', 'ar': 'كيييي!', 'de': 'Kreisch!'}),
  AsAnimal('owl', AsGroup.sky, 'Owl_sound.mp3',
      {'en': 'Owl', 'fr': 'Hibou', 'ar': 'بومة', 'de': 'Eule'},
      {'en': 'Hoo hoo!', 'fr': 'Hou hou !', 'ar': 'هو هو!', 'de': 'Huhu!'}),
];

/// The app languages that have texts here; Amazigh falls back to French.
String asLang(BuildContext c) {
  final l = Localizations.localeOf(c).languageCode;
  return const ['fr', 'en', 'ar', 'de'].contains(l) ? l : 'fr';
}

const Map<String, Map<String, String>> _ui = {
  'title': {'en': 'Animal Sounds', 'fr': 'Cris des animaux', 'ar': 'أصوات الحيوانات', 'de': 'Tierstimmen'},
  'sub': {'en': 'Tap an animal. Hear its sound!', 'fr': 'Touche un animal pour l\'entendre !', 'ar': 'المس حيوانًا لتسمع صوته!', 'de': 'Tippe ein Tier an und hör zu!'},
  'all': {'en': 'All', 'fr': 'Tous', 'ar': 'الكل', 'de': 'Alle'},
  'home': {'en': 'Home', 'fr': 'Maison', 'ar': 'البيت', 'de': 'Zuhause'},
  'wild': {'en': 'Wild', 'fr': 'Sauvages', 'ar': 'البرية', 'de': 'Wild'},
  'sea': {'en': 'Sea', 'fr': 'Mer', 'ar': 'البحر', 'de': 'Meer'},
  'sky': {'en': 'Sky', 'fr': 'Ciel', 'ar': 'السماء', 'de': 'Himmel'},
  'guess': {'en': 'Guess the sound', 'fr': 'Devine le son', 'ar': 'خمّن الصوت', 'de': 'Errate das Geräusch'},
  'guessSub': {'en': 'Listen, then find the animal.', 'fr': 'Écoute, puis trouve l\'animal.', 'ar': 'استمع ثم جد الحيوان.', 'de': 'Hör zu und finde das Tier.'},
  'play': {'en': 'Play', 'fr': 'Jouer', 'ar': 'العب', 'de': 'Spielen'},
  'found': {'en': 'Animals discovered', 'fr': 'Animaux découverts', 'ar': 'الحيوانات المكتشفة', 'de': 'Entdeckte Tiere'},
  'allFound': {'en': 'You met every animal!', 'fr': 'Tu as rencontré tous les animaux !', 'ar': 'تعرّفت على كل الحيوانات!', 'de': 'Du kennst jetzt alle Tiere!'},
  'who': {'en': 'Who makes this sound?', 'fr': 'Qui fait ce bruit ?', 'ar': 'من يصدر هذا الصوت؟', 'de': 'Wer macht dieses Geräusch?'},
  'again': {'en': 'Tap to hear it again', 'fr': 'Touche pour réécouter', 'ar': 'المس لتسمعه مجددًا', 'de': 'Tippe zum Nochmal-Hören'},
  'bravo': {'en': 'Bravo!', 'fr': 'Bravo !', 'ar': 'أحسنت!', 'de': 'Super!'},
  'itWas': {'en': 'It was the {N}!', 'fr': 'C\'était : {N} !', 'ar': 'إنه: {N}!', 'de': 'Es war: {N}!'},
  'done': {'en': 'Great listening!', 'fr': 'Belle écoute !', 'ar': 'استماع رائع!', 'de': 'Toll zugehört!'},
  'score': {'en': '{C} / {T} correct', 'fr': '{C} / {T} bonnes réponses', 'ar': '{C} / {T} إجابات صحيحة', 'de': '{C} / {T} richtig'},
  'replay': {'en': 'Play again', 'fr': 'Rejouer', 'ar': 'العب مجددًا', 'de': 'Nochmal'},
  'animals': {'en': 'Animals', 'fr': 'Animaux', 'ar': 'الحيوانات', 'de': 'Tiere'},
};

String asText(BuildContext c, String k) {
  final m = _ui[k];
  if (m == null) return k;
  return m[asLang(c)] ?? m['en']!;
}

/// Which animals the child has already listened to.
class AsStore {
  static const _kFound = 'as_found';
  static const _kBonus = 'as_all_found_bonus';

  static Future<Set<String>> found() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_kFound) ?? const []).toSet();
  }

  static Future<void> saveFound(Set<String> ids) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_kFound, ids.toList());
  }

  /// True only the first time it is called — for the one-off "met them all" reward.
  static Future<bool> claimAllFoundBonus() async {
    final p = await SharedPreferences.getInstance();
    if (p.getBool(_kBonus) ?? false) return false;
    await p.setBool(_kBonus, true);
    return true;
  }
}
