import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Mystery Quest — a hidden-object adventure.
//
// The game is built from PLACES (the house today; garden, school, … later),
// each with ROOMS. Each room has a background picture, a rectangle on the
// place picture (used for the "fly into the room" zoom) and a list of items
// that can be hidden in it.
//
// To add a place: add pictures to assets/images/Games/MysteryQuest/, then add
// an [MqPlace] to [mqPlaces] with its rooms. Nothing else needs to change.
// ═══════════════════════════════════════════════════════════════════════════

const String mqDir = 'assets/images/Games/MysteryQuest/';
String mq(String name) => '$mqDir$name.webp';

const Color mqInk = Color(0xFF241466);
const Color mqInkSoft = Color(0xFF5F5592);
const Color mqBlue = Color(0xFF1E7BF0);
const Color mqCream = Color(0xFFFFF8EA);
const Color mqGreen = Color(0xFF22C55E);

TextStyle mqText(double size, {Color color = mqInk, FontWeight weight = FontWeight.w700, double? height}) =>
    TextStyle(fontFamily: 'Fredoka', fontSize: size, color: color, fontWeight: weight, height: height);

// ── model ───────────────────────────────────────────────────────────────────

/// A place in a room picture where an item can sit: bottom-centre of the
/// item at (x, y) (fractions of the picture), [scale] = depth (far = small).
class MqSpot {
  final double x, y, scale;
  const MqSpot(this.x, this.y, this.scale);
}

class MqRoom {
  final String id;
  final Map<String, String> name;
  final String bg; // full-screen picture (null-like '' = coming soon)
  final String card; // small picture for the room cards
  final Rect rect; // where the room is on the place picture (fractions)
  final List<String> items; // item ids that can be hidden here
  final List<MqSpot> spots; // surfaces where items can be put
  const MqRoom({
    required this.spots,
    required this.id,
    required this.name,
    required this.bg,
    required this.card,
    required this.rect,
    required this.items,
  });
  bool get open => bg.isNotEmpty && items.length >= 9;
}

class MqPlace {
  final String id;
  final Map<String, String> name;
  final String picture; // the big picture shown on the menu ('' = coming soon)
  final double aspect; // picture height / width
  final IconData icon;
  final List<MqRoom> rooms;
  const MqPlace({
    required this.id,
    required this.name,
    required this.picture,
    required this.aspect,
    required this.icon,
    required this.rooms,
  });
  bool get open => picture.isNotEmpty && rooms.any((r) => r.open);
}

/// Difficulty: how many things to find, how many decoys, how big they are.
class MqLevel {
  final int find, decoys, seconds;
  final double size; // item size as a fraction of the scene width
  final bool silhouettes; // the list shows shadows instead of pictures
  const MqLevel(this.find, this.decoys, this.seconds, this.size, this.silhouettes);
}

const List<MqLevel> mqLevels = [
  MqLevel(5, 0, 120, 0.115, false),
  MqLevel(7, 3, 110, 0.1, false),
  MqLevel(9, 4, 100, 0.088, true),
];

// ── places ──────────────────────────────────────────────────────────────────

const List<MqPlace> mqPlaces = [
  MqPlace(
    id: 'house',
    name: {'fr': 'La maison', 'en': 'The house', 'ar': 'البيت', 'de': 'Das Haus'},
    picture: '${mqDir}mq_house.webp',
    aspect: 1.1371,
    icon: Icons.home_rounded,
    rooms: [
      MqRoom(
        id: 'living',
        name: {'fr': 'Le salon', 'en': 'Living room', 'ar': 'الصالون', 'de': 'Wohnzimmer'},
        bg: '${mqDir}mq_room_living.webp',
        card: '${mqDir}mq_card_living.webp',
        rect: Rect.fromLTRB(0.171, 0.389, 0.443, 0.609),
        spots: [
          MqSpot(0.50, 0.245, 0.55), MqSpot(0.62, 0.272, 0.55), MqSpot(0.82, 0.245, 0.6), MqSpot(0.93, 0.245, 0.6),
          MqSpot(0.13, 0.395, 0.75), MqSpot(0.31, 0.39, 0.75), MqSpot(0.40, 0.44, 0.7), MqSpot(0.56, 0.44, 0.7),
          MqSpot(0.86, 0.43, 0.75), MqSpot(0.93, 0.49, 0.7), MqSpot(0.12, 0.535, 0.8), MqSpot(0.42, 0.512, 0.72),
          MqSpot(0.25, 0.57, 0.9), MqSpot(0.55, 0.575, 0.9), MqSpot(0.80, 0.63, 0.95), MqSpot(0.15, 0.72, 1.05),
          MqSpot(0.47, 0.70, 1.0), MqSpot(0.72, 0.79, 1.1), MqSpot(0.62, 0.66, 0.95), MqSpot(0.33, 0.64, 0.95),
        ],
        items: ['teddy', 'rocket', 'clock', 'star', 'bow', 'top', 'ball', 'umbrella', 'dino', 'car', 'duck', 'sock', 'book', 'vase', 'mitten'],
      ),
      MqRoom(
        id: 'kitchen',
        name: {'fr': 'La cuisine', 'en': 'Kitchen', 'ar': 'المطبخ', 'de': 'Küche'},
        bg: '${mqDir}mq_room_kitchen.webp',
        card: '${mqDir}mq_card_kitchen.webp',
        rect: Rect.fromLTRB(0.571, 0.392, 0.886, 0.590),
        spots: [
          MqSpot(0.12, 0.43, 0.65), MqSpot(0.29, 0.425, 0.65), MqSpot(0.83, 0.415, 0.6), MqSpot(0.46, 0.285, 0.5),
          MqSpot(0.47, 0.355, 0.5), MqSpot(0.80, 0.255, 0.5), MqSpot(0.40, 0.49, 0.65), MqSpot(0.62, 0.49, 0.65),
          MqSpot(0.30, 0.575, 0.75), MqSpot(0.82, 0.585, 0.75), MqSpot(0.35, 0.67, 0.9), MqSpot(0.60, 0.70, 0.9),
          MqSpot(0.86, 0.71, 0.95), MqSpot(0.47, 0.80, 1.05), MqSpot(0.76, 0.84, 1.1), MqSpot(0.62, 0.92, 1.15),
          MqSpot(0.20, 0.66, 0.9), MqSpot(0.92, 0.79, 1.05),
        ],
        items: ['apple', 'banana', 'carrot', 'grapes', 'croissant', 'teapot_k', 'mug', 'spoon', 'mitt', 'scale', 'honey', 'lemon', 'cup'],
      ),
      MqRoom(
        id: 'attic',
        name: {'fr': 'Le grenier', 'en': 'Attic', 'ar': 'العلّية', 'de': 'Dachboden'},
        bg: '${mqDir}mq_room_attic.webp',
        card: '${mqDir}mq_card_attic.webp',
        rect: Rect.fromLTRB(0.536, 0.157, 0.879, 0.362),
        spots: [
          MqSpot(0.26, 0.40, 0.6), MqSpot(0.12, 0.40, 0.6), MqSpot(0.26, 0.468, 0.6), MqSpot(0.60, 0.345, 0.5),
          MqSpot(0.60, 0.405, 0.5), MqSpot(0.84, 0.31, 0.55), MqSpot(0.90, 0.235, 0.5), MqSpot(0.86, 0.395, 0.55),
          MqSpot(0.62, 0.462, 0.65), MqSpot(0.90, 0.54, 0.65), MqSpot(0.50, 0.39, 0.55), MqSpot(0.12, 0.61, 0.8),
          MqSpot(0.32, 0.60, 0.85), MqSpot(0.56, 0.63, 0.9), MqSpot(0.78, 0.70, 0.95), MqSpot(0.42, 0.72, 1.0),
          MqSpot(0.66, 0.82, 1.05), MqSpot(0.88, 0.90, 1.1), MqSpot(0.22, 0.67, 0.9),
        ],
        items: ['telescope', 'violin', 'camera', 'compass', 'binoculars', 'plane', 'watch', 'quill', 'hat', 'padlock', 'map', 'yoyo', 'key', 'magnifier'],
      ),
      MqRoom(
        id: 'bedroom',
        name: {'fr': 'La chambre', 'en': 'Bedroom', 'ar': 'غرفة النوم', 'de': 'Schlafzimmer'},
        bg: '${mqDir}mq_room_bedroom.webp',
        card: '${mqDir}mq_card_bed.webp',
        rect: Rect.fromLTRB(0.171, 0.157, 0.514, 0.371),
        spots: [
          MqSpot(0.33, 0.47, 0.75), MqSpot(0.53, 0.465, 0.75), MqSpot(0.70, 0.48, 0.75), MqSpot(0.30, 0.42, 0.7),
          MqSpot(0.10, 0.46, 0.6), MqSpot(0.75, 0.40, 0.5), MqSpot(0.75, 0.345, 0.5), MqSpot(0.74, 0.29, 0.5),
          MqSpot(0.92, 0.445, 0.6), MqSpot(0.88, 0.535, 0.7), MqSpot(0.18, 0.335, 0.55), MqSpot(0.25, 0.63, 0.9),
          MqSpot(0.50, 0.66, 0.9), MqSpot(0.76, 0.68, 0.95), MqSpot(0.42, 0.75, 1.0), MqSpot(0.66, 0.80, 1.05),
          MqSpot(0.86, 0.76, 1.0), MqSpot(0.60, 0.585, 0.85),
        ],
        items: ['bunny', 'clock2', 'slipper', 'brush', 'backpack', 'train', 'pyjama', 'crayons', 'headphones', 'piggy', 'globe', 'drum', 'book', 'sock'],
      ),
    ],
  ),
  // Next adventures (shown as "coming soon")
  MqPlace(
    id: 'garden',
    name: {'fr': 'Le jardin', 'en': 'The garden', 'ar': 'الحديقة', 'de': 'Der Garten'},
    picture: '',
    aspect: 1,
    icon: Icons.local_florist_rounded,
    rooms: <MqRoom>[],
  ),
  MqPlace(
    id: 'school',
    name: {'fr': 'L’école', 'en': 'The school', 'ar': 'المدرسة', 'de': 'Die Schule'},
    picture: '',
    aspect: 1,
    icon: Icons.school_rounded,
    rooms: <MqRoom>[],
  ),
];

// ── items ───────────────────────────────────────────────────────────────────

String mqItemAsset(String id) => '${mqDir}it_$id.webp';

const Map<String, double> _itemAspect = {
  'teddy': 1.17, 'rocket': 1.36, 'clock': 1.26, 'magnifier': 0.97, 'mitten': 1.24, 'star': 0.92, 'umbrella': 1.24,
  'dino': 1.03, 'teapot': 0.92, 'bow': 0.85, 'top': 1.15, 'ball': 0.99, 'apple': 1.1, 'banana': 0.77, 'carrot': 1.35,
  'grapes': 1.13, 'croissant': 0.73, 'teapot_k': 0.88, 'mug': 0.88, 'spoon': 0.84, 'mitt': 1.07, 'scale': 1.26,
  'honey': 1.24, 'lemon': 1.05, 'telescope': 0.9, 'violin': 0.82, 'camera': 0.7, 'compass': 0.93, 'binoculars': 0.69,
  'plane': 0.7, 'watch': 0.84, 'quill': 0.79, 'hat': 0.75, 'padlock': 1.25, 'map': 0.63, 'yoyo': 1.04, 'car': 0.63,
  'bunny': 0.94, 'clock2': 1.32, 'slipper': 0.63, 'brush': 0.71, 'backpack': 1.02, 'train': 0.79, 'pyjama': 0.82,
  'crayons': 0.87, 'headphones': 0.91, 'piggy': 0.95, 'globe': 1.14, 'drum': 0.75,
  'duck': 1.06, 'sock': 1.11, 'book': 0.8, 'key': 2.0, 'cup': 0.86, 'vase': 0.88,
};

/// height / width of an item picture.
double mqItemAspect(String id) => _itemAspect[id] ?? 1.0;

String mqItemName(BuildContext c, String id) => _itemNames[id]?[mqLang(c)] ?? _itemNames[id]?['en'] ?? id;

const Map<String, Map<String, String>> _itemNames = {
  'teddy': {'fr': 'le nounours', 'en': 'the teddy bear', 'ar': 'الدبدوب', 'de': 'den Teddy'},
  'rocket': {'fr': 'la fusée', 'en': 'the rocket', 'ar': 'الصاروخ', 'de': 'die Rakete'},
  'clock': {'fr': 'le réveil', 'en': 'the alarm clock', 'ar': 'المنبّه', 'de': 'den Wecker'},
  'magnifier': {'fr': 'la loupe', 'en': 'the magnifier', 'ar': 'العدسة المكبّرة', 'de': 'die Lupe'},
  'mitten': {'fr': 'la moufle', 'en': 'the mitten', 'ar': 'القفاز الصوفي', 'de': 'den Fäustling'},
  'star': {'fr': 'le coussin étoile', 'en': 'the star pillow', 'ar': 'وسادة النجمة', 'de': 'das Sternkissen'},
  'umbrella': {'fr': 'le parapluie', 'en': 'the umbrella', 'ar': 'المظلّة', 'de': 'den Regenschirm'},
  'dino': {'fr': 'le petit dino', 'en': 'the toy dinosaur', 'ar': 'الديناصور', 'de': 'den Dino'},
  'teapot': {'fr': 'la théière', 'en': 'the teapot', 'ar': 'إبريق الشاي', 'de': 'die Teekanne'},
  'bow': {'fr': 'le nœud rose', 'en': 'the pink bow', 'ar': 'الشريطة الوردية', 'de': 'die rosa Schleife'},
  'top': {'fr': 'la toupie', 'en': 'the spinning top', 'ar': 'الدوّامة', 'de': 'den Kreisel'},
  'ball': {'fr': 'le ballon', 'en': 'the ball', 'ar': 'الكرة', 'de': 'den Ball'},
  'apple': {'fr': 'la pomme', 'en': 'the apple', 'ar': 'التفاحة', 'de': 'den Apfel'},
  'banana': {'fr': 'la banane', 'en': 'the banana', 'ar': 'الموزة', 'de': 'die Banane'},
  'carrot': {'fr': 'la carotte', 'en': 'the carrot', 'ar': 'الجزرة', 'de': 'die Karotte'},
  'grapes': {'fr': 'le raisin', 'en': 'the grapes', 'ar': 'العنب', 'de': 'die Trauben'},
  'croissant': {'fr': 'le croissant', 'en': 'the croissant', 'ar': 'الكرواسون', 'de': 'das Croissant'},
  'teapot_k': {'fr': 'la théière', 'en': 'the teapot', 'ar': 'إبريق الشاي', 'de': 'die Teekanne'},
  'mug': {'fr': 'la tasse à pois', 'en': 'the spotty mug', 'ar': 'الكوب المنقّط', 'de': 'die Tupfentasse'},
  'spoon': {'fr': 'la cuillère en bois', 'en': 'the wooden spoon', 'ar': 'الملعقة الخشبية', 'de': 'den Holzlöffel'},
  'mitt': {'fr': 'le gant de cuisine', 'en': 'the oven mitt', 'ar': 'قفاز الفرن', 'de': 'den Topfhandschuh'},
  'scale': {'fr': 'la balance', 'en': 'the scale', 'ar': 'الميزان', 'de': 'die Waage'},
  'honey': {'fr': 'le pot de miel', 'en': 'the honey jar', 'ar': 'برطمان العسل', 'de': 'das Honigglas'},
  'lemon': {'fr': 'le citron', 'en': 'the lemon', 'ar': 'الليمونة', 'de': 'die Zitrone'},
  'telescope': {'fr': 'le télescope', 'en': 'the telescope', 'ar': 'التلسكوب', 'de': 'das Teleskop'},
  'violin': {'fr': 'le violon', 'en': 'the violin', 'ar': 'الكمان', 'de': 'die Geige'},
  'camera': {'fr': 'l’appareil photo', 'en': 'the camera', 'ar': 'الكاميرا', 'de': 'die Kamera'},
  'compass': {'fr': 'la boussole', 'en': 'the compass', 'ar': 'البوصلة', 'de': 'den Kompass'},
  'binoculars': {'fr': 'les jumelles', 'en': 'the binoculars', 'ar': 'المنظار', 'de': 'das Fernglas'},
  'plane': {'fr': 'l’avion', 'en': 'the toy plane', 'ar': 'الطائرة', 'de': 'das Flugzeug'},
  'watch': {'fr': 'la montre à gousset', 'en': 'the pocket watch', 'ar': 'ساعة الجيب', 'de': 'die Taschenuhr'},
  'quill': {'fr': 'la plume', 'en': 'the quill', 'ar': 'الريشة', 'de': 'die Feder'},
  'hat': {'fr': 'le chapeau de magicien', 'en': 'the wizard hat', 'ar': 'قبعة الساحر', 'de': 'den Zauberhut'},
  'padlock': {'fr': 'le cadenas', 'en': 'the padlock', 'ar': 'القفل', 'de': 'das Vorhängeschloss'},
  'map': {'fr': 'la carte au trésor', 'en': 'the treasure map', 'ar': 'خريطة الكنز', 'de': 'die Schatzkarte'},
  'yoyo': {'fr': 'le yoyo', 'en': 'the yo-yo', 'ar': 'اليويو', 'de': 'das Jo-Jo'},
  'car': {'fr': 'la petite voiture', 'en': 'the toy car', 'ar': 'السيارة الصغيرة', 'de': 'das Spielzeugauto'},
  'duck': {'fr': 'le canard', 'en': 'the rubber duck', 'ar': 'البطة', 'de': 'die Quietscheente'},
  'sock': {'fr': 'la chaussette', 'en': 'the sock', 'ar': 'الجورب', 'de': 'die Socke'},
  'book': {'fr': 'le livre magique', 'en': 'the magic book', 'ar': 'الكتاب السحري', 'de': 'das Zauberbuch'},
  'key': {'fr': 'la clé dorée', 'en': 'the golden key', 'ar': 'المفتاح الذهبي', 'de': 'den goldenen Schlüssel'},
  'cup': {'fr': 'la tasse', 'en': 'the cup', 'ar': 'الفنجان', 'de': 'die Tasse'},
  'bunny': {'fr': 'le lapin en peluche', 'en': 'the toy bunny', 'ar': 'الأرنب المحشو', 'de': 'den Plüschhasen'},
  'clock2': {'fr': 'le réveil bleu', 'en': 'the blue alarm clock', 'ar': 'المنبّه الأزرق', 'de': 'den blauen Wecker'},
  'slipper': {'fr': 'le chausson', 'en': 'the slipper', 'ar': 'الخُفّ', 'de': 'den Hausschuh'},
  'brush': {'fr': 'la brosse', 'en': 'the hairbrush', 'ar': 'فرشاة الشعر', 'de': 'die Haarbürste'},
  'backpack': {'fr': 'le cartable', 'en': 'the backpack', 'ar': 'الحقيبة', 'de': 'den Rucksack'},
  'train': {'fr': 'le petit train', 'en': 'the toy train', 'ar': 'القطار الصغير', 'de': 'den Spielzeugzug'},
  'pyjama': {'fr': 'le pyjama', 'en': 'the pyjamas', 'ar': 'البيجامة', 'de': 'den Schlafanzug'},
  'crayons': {'fr': 'les crayons', 'en': 'the crayons', 'ar': 'أقلام التلوين', 'de': 'die Wachsmalstifte'},
  'headphones': {'fr': 'le casque', 'en': 'the headphones', 'ar': 'السماعات', 'de': 'die Kopfhörer'},
  'piggy': {'fr': 'la tirelire', 'en': 'the piggy bank', 'ar': 'الحصّالة', 'de': 'das Sparschwein'},
  'globe': {'fr': 'la boule à neige', 'en': 'the snow globe', 'ar': 'الكرة الثلجية', 'de': 'die Schneekugel'},
  'drum': {'fr': 'le tambour', 'en': 'the drum', 'ar': 'الطبل', 'de': 'die Trommel'},
  'vase': {'fr': 'le vase de fleurs', 'en': 'the flower vase', 'ar': 'مزهرية الورد', 'de': 'die Blumenvase'},
};

// ── progress ────────────────────────────────────────────────────────────────

class MqStore {
  static String _k(String place, String room, int level) => 'mq_${place}_${room}_$level';

  static Future<int> stars(String place, String room, int level) async =>
      (await SharedPreferences.getInstance()).getInt(_k(place, room, level)) ?? 0;

  /// Best stars per level for a room ([easy, medium, hard]).
  static Future<List<int>> roomStars(String place, String room) async {
    final p = await SharedPreferences.getInstance();
    return [for (var l = 0; l < mqLevels.length; l++) p.getInt(_k(place, room, l)) ?? 0];
  }

  /// Saves if better; returns how many NEW stars were won.
  static Future<int> record(String place, String room, int level, int stars) async {
    final p = await SharedPreferences.getInstance();
    final old = p.getInt(_k(place, room, level)) ?? 0;
    if (stars > old) await p.setInt(_k(place, room, level), stars);
    return max(0, stars - old);
  }

  static Future<bool> timer() async => (await SharedPreferences.getInstance()).getBool('mq_timer') ?? false;
  static Future<void> setTimer(bool v) async => (await SharedPreferences.getInstance()).setBool('mq_timer', v);
  static Future<int> level() async => (await SharedPreferences.getInstance()).getInt('mq_level') ?? 0;
  static Future<void> setLevel(int v) async => (await SharedPreferences.getInstance()).setInt('mq_level', v);
}

// ── small helpers ───────────────────────────────────────────────────────────

void mqSound(BuildContext context, String key) {
  try {
    Provider.of<AudioManager>(context, listen: false).playEventSound(key);
  } catch (_) {}
}

void mqSfx(BuildContext context, String file) {
  try {
    Provider.of<AudioManager>(context, listen: false).playSfx('assets/audios/UI_Audio/SFX_Audio/$file');
  } catch (_) {}
}

bool mqRtl(BuildContext c) => Directionality.of(c) == TextDirection.rtl;

class MqPress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final String? label;
  const MqPress({super.key, required this.child, required this.onTap, this.scale = 0.92, this.label});
  @override
  State<MqPress> createState() => _MqPressState();
}

class _MqPressState extends State<MqPress> {
  bool _down = false;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: widget.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
          onTapCancel: () => setState(() => _down = false),
          onTapUp: widget.onTap == null
              ? null
              : (_) {
                  setState(() => _down = false);
                  widget.onTap!();
                },
          child: AnimatedScale(scale: _down ? widget.scale : 1, duration: const Duration(milliseconds: 110), child: widget.child),
        ),
      );
}

/// Round sprite button.
Widget mqRound(BuildContext context, String sprite, double size, VoidCallback onTap, {bool flipRtl = false, String? label}) =>
    MqPress(
      onTap: onTap,
      label: label,
      child: Transform.flip(flipX: flipRtl && mqRtl(context), child: Image.asset(mq(sprite), width: size, height: size)),
    );

/// Big orange sprite button with text (and optional icon on the start side).
class MqBigButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final double width;
  final double s;
  final Widget? leading;
  final Animation<double>? pulse;
  const MqBigButton({super.key, required this.label, required this.onTap, required this.width, required this.s, this.leading, this.pulse});
  @override
  Widget build(BuildContext context) {
    Widget b = MqPress(
      onTap: onTap,
      label: label,
      child: SizedBox(
        width: width,
        height: width * 0.315,
        child: Stack(alignment: Alignment.center, children: [
          Positioned.fill(child: Image.asset(mq('mq_btn'), fit: BoxFit.fill)),
          Padding(
            padding: EdgeInsets.fromLTRB(18 * s, 0, 18 * s, 4 * s),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (leading != null) ...[leading!, SizedBox(width: 10 * s)],
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label,
                      style: mqText(width * 0.085, color: Colors.white)
                          .copyWith(shadows: const [Shadow(color: Color(0xFFB45309), offset: Offset(0, 2))])),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
    if (onTap == null) return Opacity(opacity: 0.5, child: b);
    if (pulse != null) {
      b = AnimatedBuilder(
        animation: pulse!,
        builder: (_, c) => Transform.scale(scale: 1 + 0.03 * sin(pulse!.value * 2 * pi * 4), child: c),
        child: b,
      );
    }
    return b;
  }
}

/// Speech bubble sprite with text (tail on the start side).
class MqBubble extends StatelessWidget {
  final String text;
  final double width;
  const MqBubble({super.key, required this.text, required this.width});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: width * 0.441,
        child: Stack(children: [
          Positioned.fill(child: Transform.flip(flipX: mqRtl(context), child: Image.asset(mq('mq_bubble'), fit: BoxFit.fill))),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(width * 0.1, width * 0.04, width * 0.05, width * 0.08),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: FittedBox(
                    key: ValueKey(text),
                    fit: BoxFit.scaleDown,
                    child: Text(text, textAlign: TextAlign.center, maxLines: 2, style: mqText(width * 0.075, color: mqInk)),
                  ),
                ),
              ),
            ),
          ),
        ]),
      );
}

/// Burst of colourful stars at the centre of the box, driven by [t] (0→1).
class MqBurstPainter extends CustomPainter {
  final double t;
  final int seed;
  MqBurstPainter(this.t, {this.seed = 3});
  static const _c = [Color(0xFFFFC21A), Color(0xFFFF6FB5), Color(0xFF34D9CF), Color(0xFF8B5CFF), Color(0xFF7DDB5A)];
  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final c = size.center(Offset.zero);
    final r = Random(seed);
    final e = Curves.easeOutCubic.transform(t);
    for (var i = 0; i < 18; i++) {
      final a = i / 18 * 2 * pi + r.nextDouble() * 0.4;
      final d = (0.35 + r.nextDouble() * 0.45) * size.shortestSide * e;
      final p = c + Offset(cos(a), sin(a)) * d;
      final rad = (3 + r.nextDouble() * 4) * (1 - t * 0.5);
      final paint = Paint()..color = _c[i % _c.length].withOpacity((1 - t).clamp(0.0, 1.0));
      final path = Path()
        ..moveTo(p.dx, p.dy - rad * 1.6)
        ..quadraticBezierTo(p.dx, p.dy, p.dx + rad * 1.6, p.dy)
        ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy + rad * 1.6)
        ..quadraticBezierTo(p.dx, p.dy, p.dx - rad * 1.6, p.dy)
        ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy - rad * 1.6)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(MqBurstPainter o) => o.t != t;
}


// ── responsive frame ───────────────────────────────────────────────────────
// Lays the page out on a phone-sized design canvas (≈390 wide) and scales it
// to the real screen, so every device shows the same centred layout. The
// system font size is ignored here (big system fonts broke the layout).

class _MqFrameMark extends InheritedWidget {
  const _MqFrameMark({required super.child});
  @override
  bool updateShouldNotify(_MqFrameMark oldWidget) => false;
}

class MqFrame extends StatelessWidget {
  final Widget child;
  const MqFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (context.dependOnInheritedWidgetOfExactType<_MqFrameMark>() != null) return child;
    final mq = MediaQuery.of(context);
    final W = mq.size.width, H = mq.size.height;
    if (W <= 0 || H <= 0) return child;
    final k = min(min(W / 390, H / 780), 1.35).toDouble();
    final dw = W / k, dh = H / k;
    EdgeInsets d(EdgeInsets e) => EdgeInsets.fromLTRB(e.left / k, e.top / k, e.right / k, e.bottom / k);
    return _MqFrameMark(
      child: FittedBox(
        fit: BoxFit.fill,
        child: SizedBox(
          width: dw,
          height: dh,
          child: MediaQuery(
            data: mq.copyWith(
              size: Size(dw, dh),
              padding: d(mq.padding),
              viewPadding: d(mq.viewPadding),
              viewInsets: d(mq.viewInsets),
              textScaler: TextScaler.noScaling,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ── text ────────────────────────────────────────────────────────────────────

String mqLang(BuildContext c) {
  final l = Localizations.localeOf(c).languageCode;
  return const ['fr', 'en', 'ar', 'de'].contains(l) ? l : (l == 'zgh' ? 'fr' : 'en');
}

String mqPick(BuildContext c, Map<String, String> m) => m[mqLang(c)] ?? m['en'] ?? '';

String mqT(BuildContext c, String key, [Map<String, Object>? args]) {
  var s = _strings[mqLang(c)]?[key] ?? _strings['en']![key] ?? key;
  args?.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
  return s;
}

/// Game title for the games list.
String mqTitleFor(String localeName) {
  final code = localeName.split(RegExp('[_-]')).first;
  final lang = _strings.containsKey(code) ? code : (code == 'zgh' ? 'fr' : 'en');
  return _strings[lang]!['title']!;
}

const Map<String, Map<String, String>> _strings = {
  'en': {
    'title': 'Mystery Quest',
    'sub': 'Where will we search today?',
    'pickRoom': 'Pick a room to explore!',
    'soon': 'Soon',
    'easy': 'Easy',
    'medium': 'Medium',
    'hard': 'Hard',
    'timer': 'Race the clock',
    'play': 'Let’s explore!',
    'locked': 'This room is still locked… coming soon!',
    'find': 'Find {name}!',
    'start': 'Can you find all the hidden things?',
    'yes': 'Yes! Well spotted!',
    'oops': 'Not there… look again!',
    'notThis': 'Hmm, that’s not on the list',
    'hint': 'Look here! 👀',
    'noHint': 'No more hints!',
    'found': '{n} / {t}',
    'win': 'Mystery solved!',
    'timeUp': 'Time’s up!',
    'timeUpSub': 'You found {n} of {t}. Try again!',
    'again': 'Play again',
    'next': 'Next room',
    'backHouse': 'Back',
    'paused': 'Paused',
    'resume': 'Continue',
    'quit': 'Quit',
    'gold': '+{n} gold',
  },
  'fr': {
    'title': 'Quête des mystères',
    'sub': 'Où cherche-t-on aujourd’hui ?',
    'pickRoom': 'Choisis une pièce à explorer !',
    'soon': 'Bientôt',
    'easy': 'Facile',
    'medium': 'Moyen',
    'hard': 'Difficile',
    'timer': 'Course contre la montre',
    'play': 'On explore !',
    'locked': 'Cette pièce est encore fermée… bientôt !',
    'find': 'Trouve {name} !',
    'start': 'Trouveras-tu tous les objets cachés ?',
    'yes': 'Oui ! Bien vu !',
    'oops': 'Pas ici… regarde encore !',
    'notThis': 'Hmm, ce n’est pas sur la liste',
    'hint': 'Regarde ici ! 👀',
    'noHint': 'Plus d’indices !',
    'found': '{n} / {t}',
    'win': 'Mystère résolu !',
    'timeUp': 'Temps écoulé !',
    'timeUpSub': 'Tu en as trouvé {n} sur {t}. Réessaie !',
    'again': 'Rejouer',
    'next': 'Pièce suivante',
    'backHouse': 'Retour',
    'paused': 'Pause',
    'resume': 'Continuer',
    'quit': 'Quitter',
    'gold': '+{n} or',
  },
  'ar': {
    'title': 'مغامرة الأسرار',
    'sub': 'أين سنبحث اليوم؟',
    'pickRoom': 'اختر غرفة لتستكشفها!',
    'soon': 'قريباً',
    'easy': 'سهل',
    'medium': 'متوسط',
    'hard': 'صعب',
    'timer': 'سباق مع الوقت',
    'play': 'هيا نستكشف!',
    'locked': 'هذه الغرفة ما زالت مغلقة… قريباً!',
    'find': 'جد {name}!',
    'start': 'هل ستجد كل الأشياء المخفية؟',
    'yes': 'نعم! أحسنت!',
    'oops': 'ليس هنا… انظر مجدداً!',
    'notThis': 'همم، هذا ليس في القائمة',
    'hint': 'انظر هنا! 👀',
    'noHint': 'لا مزيد من التلميحات!',
    'found': '{n} / {t}',
    'win': 'تم حل اللغز!',
    'timeUp': 'انتهى الوقت!',
    'timeUpSub': 'وجدت {n} من {t}. حاول مجدداً!',
    'again': 'العب مجدداً',
    'next': 'الغرفة التالية',
    'backHouse': 'رجوع',
    'paused': 'استراحة',
    'resume': 'متابعة',
    'quit': 'خروج',
    'gold': '+{n} ذهب',
  },
  'de': {
    'title': 'Rätsel-Abenteuer',
    'sub': 'Wo suchen wir heute?',
    'pickRoom': 'Wähle einen Raum zum Erkunden!',
    'soon': 'Bald',
    'easy': 'Leicht',
    'medium': 'Mittel',
    'hard': 'Schwer',
    'timer': 'Gegen die Uhr',
    'play': 'Los, erkunden!',
    'locked': 'Dieser Raum ist noch zu… bald!',
    'find': 'Finde {name}!',
    'start': 'Findest du alle versteckten Dinge?',
    'yes': 'Ja! Gut gesehen!',
    'oops': 'Nicht da… schau nochmal!',
    'notThis': 'Hmm, das steht nicht auf der Liste',
    'hint': 'Schau hier! 👀',
    'noHint': 'Keine Tipps mehr!',
    'found': '{n} / {t}',
    'win': 'Rätsel gelöst!',
    'timeUp': 'Zeit um!',
    'timeUpSub': 'Du hast {n} von {t} gefunden. Nochmal!',
    'again': 'Nochmal',
    'next': 'Nächster Raum',
    'backHouse': 'Zurück',
    'paused': 'Pause',
    'resume': 'Weiter',
    'quit': 'Beenden',
    'gold': '+{n} Gold',
  },
};
