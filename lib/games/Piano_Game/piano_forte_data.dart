import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Piano Forte — data: the 13 keys (Do → Do aigu), instruments, songs,
/// texts and what is saved on the device.

const String pfDir = 'assets/images/UI/KidScene/';
const String _soundDir = 'assets/audios/piano_notes/';

// ── keys ──────────────────────────────────────────────────────────────────

/// Key index = semitones above middle C (0 = Do … 12 = Do aigu).
const int pfKeyCount = 13;
const List<int> pfWhiteKeys = [0, 2, 4, 5, 7, 9, 11, 12];
const List<int> pfBlackKeys = [1, 3, 6, 8, 10];
bool pfIsBlack(int k) => pfBlackKeys.contains(k);

/// White key index (0‥7) that a black key sits after.
int pfBlackAfter(int k) => const {1: 0, 3: 1, 6: 3, 8: 4, 10: 5}[k]!;

const List<String> _fileNames = ['C4', 'Cs4', 'D4', 'Ds4', 'E4', 'F4', 'Fs4', 'G4', 'Gs4', 'A4', 'As4', 'B4', 'C5'];

/// Rainbow colour of each white key (black keys use the deep purple).
const Map<int, Color> pfKeyColor = {
  0: Color(0xFFFF3B30),
  2: Color(0xFFFF8A00),
  4: Color(0xFFFFCC00),
  5: Color(0xFF2DBE3C),
  7: Color(0xFF1FC8F0),
  9: Color(0xFF2563EB),
  11: Color(0xFFA43BE8),
  12: Color(0xFFFF3B30),
};
const Color pfSharpColor = Color(0xFF5B3FA0);
Color pfColorOf(int k) => pfKeyColor[k] ?? pfSharpColor;

enum PfNaming { solfege, letters }

const _solfegeFr = ['Do', 'Do♯', 'Ré', 'Ré♯', 'Mi', 'Fa', 'Fa♯', 'Sol', 'Sol♯', 'La', 'La♯', 'Si', 'Do'];
const _solfegeAr = ['دو', 'دو♯', 'ري', 'ري♯', 'مي', 'فا', 'فا♯', 'صول', 'صول♯', 'لا', 'لا♯', 'سي', 'دو'];
const _lettersEn = ['C', 'C♯', 'D', 'D♯', 'E', 'F', 'F♯', 'G', 'G♯', 'A', 'A♯', 'B', 'C'];
const _lettersDe = ['C', 'Cis', 'D', 'Dis', 'E', 'F', 'Fis', 'G', 'Gis', 'A', 'Ais', 'H', 'C'];

/// Note names for the current UI language and naming style.
List<String> pfNoteNames(BuildContext c, PfNaming naming) {
  final l = pfLang(c);
  if (naming == PfNaming.letters) return l == 'de' ? _lettersDe : _lettersEn;
  return l == 'ar' ? _solfegeAr : _solfegeFr;
}

// ── instruments ───────────────────────────────────────────────────────────

enum PfInstrument { piano, xylophone, bells }

String pfNoteAsset(PfInstrument i, int key) {
  final n = _fileNames[key];
  switch (i) {
    case PfInstrument.piano:
      return '$_soundDir$n.mp3'; // naturals are the original samples, sharps were added beside them
    case PfInstrument.xylophone:
      return '${_soundDir}xylo_$n.mp3';
    case PfInstrument.bells:
      return '${_soundDir}bells_$n.mp3';
  }
}

String pfInstrumentArt(PfInstrument i) => switch (i) {
      PfInstrument.piano => '${pfDir}pf_piano.webp',
      PfInstrument.xylophone => '${pfDir}pf_xylo.webp',
      PfInstrument.bells => '${pfDir}pf_bells.webp',
    };

// ── songs ─────────────────────────────────────────────────────────────────

enum PfLevel { easy, medium }

class PfSong {
  final String id;
  final Map<String, String> titles;
  final String art;
  final PfLevel level;
  final List<int> notes; // key indexes
  final List<double> beats; // length of each note
  final int bpm;
  const PfSong(this.id, this.titles, this.art, this.level, this.notes, this.beats, this.bpm);

  String title(BuildContext c) => titles[pfLang(c)] ?? titles['fr']!;
  int get length => notes.length;
}

const List<PfSong> pfSongs = [
  PfSong(
    'clair_lune',
    {'fr': 'Au clair de la lune', 'en': 'Au clair de la lune', 'ar': 'في ضوء القمر', 'de': 'Au clair de la lune'},
    '${pfDir}pf_art_moon.webp',
    PfLevel.easy,
    [0, 0, 0, 2, 4, 2, 0, 4, 2, 2, 0],
    [1, 1, 1, 1, 2, 2, 1, 1, 1, 1, 3],
    108,
  ),
  PfSong(
    'frere_jacques',
    {'fr': 'Frère Jacques', 'en': 'Are You Sleeping?', 'ar': 'الأخ جاك', 'de': 'Bruder Jakob'},
    '${pfDir}pf_art_star.webp',
    PfLevel.easy,
    [0, 2, 4, 0, 0, 2, 4, 0, 4, 5, 7, 4, 5, 7, 7, 9, 7, 5, 4, 0, 7, 9, 7, 5, 4, 0],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 2, .5, .5, .5, .5, 1, 1, .5, .5, .5, .5, 1, 2],
    112,
  ),
  // in F so it fits Do → Do aigu (uses the black La♯ / Si♭)
  PfSong(
    'anniversaire',
    {'fr': 'Joyeux anniversaire', 'en': 'Happy Birthday', 'ar': 'عيد ميلاد سعيد', 'de': 'Zum Geburtstag viel Glück'},
    '${pfDir}pf_art_cake.webp',
    PfLevel.medium,
    [0, 0, 2, 0, 5, 4, 0, 0, 2, 0, 7, 5, 0, 0, 12, 9, 5, 4, 2, 10, 10, 9, 5, 7, 5],
    [.75, .25, 1, 1, 1, 2, .75, .25, 1, 1, 1, 2, .75, .25, 1, 1, 1, 1, 2, .75, .25, 1, 1, 1, 2],
    100,
  ),
  PfSong(
    'avignon',
    {'fr': 'Sur le pont d\'Avignon', 'en': 'Sur le pont d\'Avignon', 'ar': 'على جسر أفينيون', 'de': 'Sur le pont d\'Avignon'},
    '${pfDir}pf_art_mill.webp',
    PfLevel.medium,
    [5, 5, 5, 7, 7, 7, 9, 10, 12, 5, 4, 5, 7, 0, 5, 5, 5, 7, 7, 7, 9, 10, 12, 5, 7, 4, 5],
    [.5, .5, 1, .5, .5, 1, .5, .5, 1, .5, .5, .5, .5, 1, .5, .5, 1, .5, .5, 1, .5, .5, 1, .5, .5, .5, 1.5],
    116,
  ),
];

PfSong pfSongById(String? id) => pfSongs.firstWhere((s) => s.id == id, orElse: () => pfSongs.first);

/// Note start times (ms) for a song at the given speed.
List<int> pfSchedule(List<double> beats, int bpm, {double slow = 1}) {
  final ms = 60000 / bpm * slow;
  final out = <int>[];
  var t = 0.0;
  for (final b in beats) {
    out.add(t.round());
    t += b * ms;
  }
  return out;
}

// ── saved melodies ────────────────────────────────────────────────────────

class PfMelody {
  final String name;
  final PfInstrument instrument;
  final List<int> keys;
  final List<int> times; // ms from the first note
  const PfMelody(this.name, this.instrument, this.keys, this.times);

  int get durationMs => times.isEmpty ? 0 : times.last + 600;

  Map<String, dynamic> toJson() => {'n': name, 'i': instrument.name, 'k': keys, 't': times};

  static PfMelody? fromJson(Map<String, dynamic> j) {
    try {
      return PfMelody(
        j['n'] as String,
        PfInstrument.values.firstWhere((e) => e.name == j['i'], orElse: () => PfInstrument.piano),
        (j['k'] as List).cast<int>(),
        (j['t'] as List).cast<int>(),
      );
    } catch (_) {
      return null;
    }
  }
}

class PfStore {
  static const _kSong = 'pf_song';
  static const _kVolume = 'pf_volume';
  static const _kInstrument = 'pf_instrument';
  static const _kNaming = 'pf_naming';
  static const _kNames = 'pf_show_names';
  static const _kMelodies = 'pf_melodies';
  static const _kHintSeen = 'pf_hint_seen';
  static String _kBest(String id) => 'pf_best_$id';
  static String _kDone(String id) => 'pf_done_$id';

  static Future<SharedPreferences> get _p => SharedPreferences.getInstance();

  static Future<String?> song() async => (await _p).getString(_kSong);
  static Future<void> setSong(String id) async => (await _p).setString(_kSong, id);

  static Future<double> volume() async => (await _p).getDouble(_kVolume) ?? 0.8;
  static Future<void> setVolume(double v) async => (await _p).setDouble(_kVolume, v);

  static Future<PfInstrument> instrument() async {
    final n = (await _p).getString(_kInstrument);
    return PfInstrument.values.firstWhere((e) => e.name == n, orElse: () => PfInstrument.piano);
  }

  static Future<void> setInstrument(PfInstrument i) async => (await _p).setString(_kInstrument, i.name);

  static Future<PfNaming> naming() async =>
      (await _p).getString(_kNaming) == 'letters' ? PfNaming.letters : PfNaming.solfege;
  static Future<void> setNaming(PfNaming n) async => (await _p).setString(_kNaming, n.name);

  static Future<bool> showNames() async => (await _p).getBool(_kNames) ?? true;
  static Future<void> setShowNames(bool v) async => (await _p).setBool(_kNames, v);

  static Future<bool> hintSeen() async => (await _p).getBool(_kHintSeen) ?? false;
  static Future<void> setHintSeen() async => (await _p).setBool(_kHintSeen, true);

  /// Best share of the song reached (0‥1), for the dots in the song list.
  static Future<Map<String, double>> bests() async {
    final p = await _p;
    return {for (final s in pfSongs) s.id: p.getDouble(_kBest(s.id)) ?? 0};
  }

  static Future<void> saveBest(String id, double v) async {
    final p = await _p;
    if (v > (p.getDouble(_kBest(id)) ?? 0)) await p.setDouble(_kBest(id), v);
  }

  /// True the first time a song is finished (bigger reward).
  static Future<bool> markDone(String id) async {
    final p = await _p;
    if (p.getBool(_kDone(id)) ?? false) return false;
    await p.setBool(_kDone(id), true);
    return true;
  }

  static Future<List<PfMelody>> melodies() async {
    final raw = (await _p).getString(_kMelodies);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => PfMelody.fromJson(Map<String, dynamic>.from(e as Map)))
          .whereType<PfMelody>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveMelodies(List<PfMelody> list) async =>
      (await _p).setString(_kMelodies, jsonEncode([for (final m in list) m.toJson()]));
}

// ── texts ─────────────────────────────────────────────────────────────────

/// UI language; Amazigh falls back to French.
String pfLang(BuildContext c) {
  final l = Localizations.localeOf(c).languageCode;
  return const ['fr', 'en', 'ar', 'de'].contains(l) ? l : 'fr';
}

const Map<String, Map<String, String>> _ui = {
  'by': {'fr': 'par MoorTaalim', 'en': 'by MoorTaalim', 'ar': 'من MoorTaalim', 'de': 'von MoorTaalim'},
  'learn': {'fr': 'Apprendre', 'en': 'Learn', 'ar': 'تعلّم', 'de': 'Lernen'},
  'free': {'fr': 'Jeu libre', 'en': 'Free play', 'ar': 'لعب حر', 'de': 'Freies Spiel'},
  'followKeys': {'fr': 'Suis les touches lumineuses !', 'en': 'Follow the glowing keys!', 'ar': 'اتبع المفاتيح المضيئة!', 'de': 'Folge den leuchtenden Tasten!'},
  'notes': {'fr': '{A} / {B} notes', 'en': '{A} / {B} notes', 'ar': '{A} / {B} نغمات', 'de': '{A} / {B} Noten'},
  'yourTurn': {'fr': 'À toi de jouer !', 'en': 'Your turn!', 'ar': 'دورك الآن!', 'de': 'Du bist dran!'},
  'bravo': {'fr': 'Bravo !', 'en': 'Great!', 'ar': 'أحسنت!', 'de': 'Super!'},
  'tryGlow': {'fr': 'Essaie la touche qui brille !', 'en': 'Try the glowing key!', 'ar': 'جرّب المفتاح المضيء!', 'de': 'Probier die leuchtende Taste!'},
  'listen': {'fr': 'Écoute bien…', 'en': 'Listen carefully…', 'ar': 'استمع جيدًا…', 'de': 'Hör gut zu…'},
  'wonderful': {'fr': 'Magnifique !', 'en': 'Wonderful!', 'ar': 'رائع جدًا!', 'de': 'Wunderbar!'},
  'changeSong': {'fr': 'Changer de chanson', 'en': 'Change song', 'ar': 'تغيير الأغنية', 'de': 'Lied wechseln'},
  'footerLearn': {'fr': 'Chaque note est une aventure !', 'en': 'Every note is an adventure!', 'ar': 'كل نغمة مغامرة!', 'de': 'Jede Note ist ein Abenteuer!'},
  'create': {'fr': 'Crée ta mélodie !', 'en': 'Create your melody!', 'ar': 'اصنع لحنك!', 'de': 'Erfinde deine Melodie!'},
  'createSub': {'fr': 'Joue les notes que tu aimes.', 'en': 'Play the notes you like.', 'ar': 'اعزف النغمات التي تحبها.', 'de': 'Spiel die Noten, die du magst.'},
  'piano': {'fr': 'Piano', 'en': 'Piano', 'ar': 'بيانو', 'de': 'Klavier'},
  'xylophone': {'fr': 'Xylophone', 'en': 'Xylophone', 'ar': 'إكسيليفون', 'de': 'Xylofon'},
  'bells': {'fr': 'Clochettes', 'en': 'Bells', 'ar': 'أجراس', 'de': 'Glöckchen'},
  'firstNote': {'fr': 'Tout commence par une note !', 'en': 'It all starts with one note!', 'ar': 'كل شيء يبدأ بنغمة!', 'de': 'Alles beginnt mit einer Note!'},
  'record': {'fr': 'Enregistrer', 'en': 'Record', 'ar': 'تسجيل', 'de': 'Aufnehmen'},
  'stop': {'fr': 'Arrêter', 'en': 'Stop', 'ar': 'إيقاف', 'de': 'Stopp'},
  'play': {'fr': 'Écouter', 'en': 'Listen', 'ar': 'استمع', 'de': 'Anhören'},
  'clear': {'fr': 'Effacer', 'en': 'Clear', 'ar': 'مسح', 'de': 'Löschen'},
  'recording': {'fr': 'J\'enregistre… joue !', 'en': 'Recording… play!', 'ar': 'أسجّل… اعزف!', 'de': 'Ich nehme auf… spiel!'},
  'saved': {'fr': 'Mélodie enregistrée !', 'en': 'Melody saved!', 'ar': 'تم حفظ اللحن!', 'de': 'Melodie gespeichert!'},
  'playingYours': {'fr': 'Écoute ta mélodie !', 'en': 'Listen to your melody!', 'ar': 'استمع إلى لحنك!', 'de': 'Hör deine Melodie!'},
  'myMelodies': {'fr': 'Mes mélodies', 'en': 'My melodies', 'ar': 'ألحاني', 'de': 'Meine Melodien'},
  'footerFree': {'fr': 'Amuse-toi à inventer !', 'en': 'Have fun inventing!', 'ar': 'استمتع بالابتكار!', 'de': 'Viel Spaß beim Erfinden!'},
  'pickTitle': {'fr': 'Choisis ta chanson', 'en': 'Pick your song', 'ar': 'اختر أغنيتك', 'de': 'Wähle dein Lied'},
  'pickSub': {'fr': 'Écoute, choisis et joue !', 'en': 'Listen, pick and play!', 'ar': 'استمع، اختر واعزف!', 'de': 'Hör zu, wähle und spiel!'},
  'all': {'fr': 'Toutes', 'en': 'All', 'ar': 'الكل', 'de': 'Alle'},
  'easy': {'fr': 'Facile', 'en': 'Easy', 'ar': 'سهل', 'de': 'Leicht'},
  'medium': {'fr': 'Moyen', 'en': 'Medium', 'ar': 'متوسط', 'de': 'Mittel'},
  'current': {'fr': 'En cours', 'en': 'Playing', 'ar': 'الحالية', 'de': 'Aktuell'},
  'oneAtATime': {'fr': 'Une note à la fois', 'en': 'One note at a time', 'ar': 'نغمة تلو الأخرى', 'de': 'Eine Note nach der anderen'},
  'go': {'fr': 'Jouer', 'en': 'Play', 'ar': 'العب', 'de': 'Spielen'},
  'noMelodies': {'fr': 'Appuie sur le bouton rouge pour enregistrer ta première mélodie !', 'en': 'Press the red button to record your first melody!', 'ar': 'اضغط الزر الأحمر لتسجيل لحنك الأول!', 'de': 'Drück den roten Knopf, um deine erste Melodie aufzunehmen!'},
  'melody': {'fr': 'Mélodie {N}', 'en': 'Melody {N}', 'ar': 'لحن {N}', 'de': 'Melodie {N}'},
  'noteCount': {'fr': '{N} notes', 'en': '{N} notes', 'ar': '{N} نغمات', 'de': '{N} Noten'},
  'songDone': {'fr': 'Chanson réussie !', 'en': 'Song complete!', 'ar': 'أتممت الأغنية!', 'de': 'Lied geschafft!'},
  'again': {'fr': 'Rejouer', 'en': 'Play again', 'ar': 'العب مجددًا', 'de': 'Nochmal'},
  'settings': {'fr': 'Réglages', 'en': 'Settings', 'ar': 'الإعدادات', 'de': 'Einstellungen'},
  'noteNames': {'fr': 'Noms des notes', 'en': 'Note names', 'ar': 'أسماء النغمات', 'de': 'Notennamen'},
  'showNames': {'fr': 'Afficher sur les touches', 'en': 'Show on the keys', 'ar': 'إظهار على المفاتيح', 'de': 'Auf den Tasten zeigen'},
  'yes': {'fr': 'Oui', 'en': 'Yes', 'ar': 'نعم', 'de': 'Ja'},
  'no': {'fr': 'Non', 'en': 'No', 'ar': 'لا', 'de': 'Nein'},
  'close': {'fr': 'Fermer', 'en': 'Close', 'ar': 'إغلاق', 'de': 'Schließen'},
  'slowOn': {'fr': 'Tout doux, comme une tortue !', 'en': 'Nice and slow, like a turtle!', 'ar': 'ببطء مثل السلحفاة!', 'de': 'Schön langsam wie eine Schildkröte!'},
};

String pfText(BuildContext c, String k) {
  final m = _ui[k];
  if (m == null) return k;
  return m[pfLang(c)] ?? m['fr']!;
}
