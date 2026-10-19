import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'magic_paint_pages.dart';

// ── assets ─────────────────────────────────────────────────────────────────

const String mpDir = 'assets/images/UI/KidScene/';
const String mpPagesDir = 'assets/images/magic_paint/';
const String mpImgBg = '${mpDir}it_page_bg.webp';
const String mpImgBack = '${mpDir}qz_back.webp';
const String mpImgGear = '${mpDir}qz_gear.webp';
const String mpImgStar = '${mpDir}qz_star.webp';
const String mpImgEaselTall = '${mpDir}mp_easel_tall.webp';
const String mpImgEaselWide = '${mpDir}mp_easel_wide.webp';
const String mpImgRobotSwirl = '${mpDir}mp_robot_swirl.webp';
const String mpImgRobotSmall = '${mpDir}mp_robot_small.webp';
const String mpImgRobotGallery = '${mpDir}mp_robot_gallery.webp';
const String mpImgBubble = '${mpDir}mp_bubble.webp';
const String mpImgBanner = '${mpDir}mp_banner_leaves.webp';
const String mpImgNewCard = '${mpDir}mp_new_card.webp';
const String mpImgZoom = '${mpDir}mp_zoom.webp';
const String mpImgBucket = '${mpDir}mp_i_bucket.webp';
const String mpImgBrushIcon = '${mpDir}mp_i_brush.webp';
const String mpImgWand = '${mpDir}mp_i_wand.webp';
const String mpImgEraserIcon = '${mpDir}mp_i_eraser.webp';
const String mpImgSave = '${mpDir}mp_i_save.webp';
const String mpImgNew = '${mpDir}mp_i_new.webp';
const String mpImgFolder = '${mpDir}mp_i_folder.webp';
const String mpImgBrushPlus = '${mpDir}mp_i_brushplus.webp';
const String mpImgPencil = '${mpDir}mp_t_pencil.webp';
const String mpImgBrush = '${mpDir}mp_t_brush.webp';
const String mpImgCrayon = '${mpDir}mp_t_crayon.webp';
const String mpImgEraser = '${mpDir}mp_t_eraser.webp';
const String mpImgStarTool = '${mpDir}mp_t_star.webp';

const List<String> mpAllImages = [
  mpImgBg, mpImgBack, mpImgGear, mpImgStar, mpImgEaselTall, mpImgEaselWide, mpImgRobotSwirl, mpImgRobotSmall,
  mpImgRobotGallery, mpImgBubble, mpImgBanner, mpImgNewCard, mpImgZoom, mpImgBucket, mpImgBrushIcon, mpImgWand,
  mpImgEraserIcon, mpImgSave, mpImgNew, mpImgFolder, mpImgBrushPlus, mpImgPencil, mpImgBrush, mpImgCrayon,
  mpImgEraser, mpImgStarTool,
];

// ── texts ──────────────────────────────────────────────────────────────────

String mpLang(BuildContext c) {
  final l = Localizations.localeOf(c).languageCode;
  return const {'fr', 'en', 'ar', 'de', 'es'}.contains(l) ? l : 'fr';
}

const Map<String, Map<String, String>> _mpUi = {
  'title': {'fr': 'Peinture magique', 'en': 'Magic painting', 'ar': 'الرسم السحري', 'de': 'Zaubermalerei', 'es': 'Pintura mágica'},
  'color': {'fr': 'Colorier', 'en': 'Color', 'ar': 'تلوين', 'de': 'Ausmalen', 'es': 'Colorear'},
  'draw': {'fr': 'Dessiner', 'en': 'Draw', 'ar': 'رسم', 'de': 'Zeichnen', 'es': 'Dibujar'},
  'mine': {'fr': 'Mes créations', 'en': 'My creations', 'ar': 'إبداعاتي', 'de': 'Meine Werke', 'es': 'Mis creaciones'},
  'tapZone': {'fr': 'Touche une zone pour la colorier', 'en': 'Tap an area to color it', 'ar': 'المس منطقة لتلوينها', 'de': 'Tippe auf eine Fläche zum Ausmalen', 'es': 'Toca una zona para colorearla'},
  'tapMagic': {'fr': 'La baguette met les couleurs du modèle !', 'en': 'The wand uses the model’s colors!', 'ar': 'العصا تضع ألوان النموذج!', 'de': 'Der Zauberstab nimmt die Farben vom Vorbild!', 'es': '¡La varita usa los colores del modelo!'},
  'tapBrush': {'fr': 'Peins librement avec le pinceau', 'en': 'Paint freely with the brush', 'ar': 'لوّن بحرية بالفرشاة', 'de': 'Male frei mit dem Pinsel', 'es': 'Pinta libremente con el pincel'},
  'tapEraser': {'fr': 'Touche une zone pour l’effacer', 'en': 'Tap an area to erase it', 'ar': 'المس منطقة لمسحها', 'de': 'Tippe auf eine Fläche zum Löschen', 'es': 'Toca una zona para borrarla'},
  'model': {'fr': 'Modèle', 'en': 'Model', 'ar': 'النموذج', 'de': 'Vorlage', 'es': 'Modelo'},
  'finish': {'fr': 'Terminer', 'en': 'Finish', 'ar': 'إنهاء', 'de': 'Fertig', 'es': 'Terminar'},
  'gallery': {'fr': 'Galerie', 'en': 'Gallery', 'ar': 'المعرض', 'de': 'Galerie', 'es': 'Galería'},
  'imagine': {'fr': 'Laisse parler ton imagination !', 'en': 'Let your imagination run free!', 'ar': 'أطلق العنان لخيالك!', 'de': 'Lass deiner Fantasie freien Lauf!', 'es': '¡Deja volar tu imaginación!'},
  'size': {'fr': 'Taille', 'en': 'Size', 'ar': 'الحجم', 'de': 'Größe', 'es': 'Tamaño'},
  'save': {'fr': 'Enregistrer', 'en': 'Save', 'ar': 'حفظ', 'de': 'Speichern', 'es': 'Guardar'},
  'new': {'fr': 'Nouveau', 'en': 'New', 'ar': 'جديد', 'de': 'Neu', 'es': 'Nuevo'},
  'yourTurn': {'fr': 'À toi de dessiner !', 'en': 'Your turn to draw!', 'ar': 'دورك لترسم!', 'de': 'Jetzt malst du!', 'es': '¡Te toca dibujar!'},
  'museum': {'fr': 'Mon petit musée', 'en': 'My little museum', 'ar': 'متحفي الصغير', 'de': 'Mein kleines Museum', 'es': 'Mi pequeño museo'},
  'museumSub': {'fr': 'Tes idées prennent des couleurs !', 'en': 'Your ideas come to life in color!', 'ar': 'أفكارك تتلون!', 'de': 'Deine Ideen werden bunt!', 'es': '¡Tus ideas se llenan de color!'},
  'all': {'fr': 'Tout', 'en': 'All', 'ar': 'الكل', 'de': 'Alle', 'es': 'Todo'},
  'inProgress': {'fr': 'En cours', 'en': 'In progress', 'ar': 'قيد الإنجاز', 'de': 'In Arbeit', 'es': 'En curso'},
  'doneMany': {'fr': 'Terminées', 'en': 'Finished', 'ar': 'منتهية', 'de': 'Fertig', 'es': 'Terminadas'},
  'done': {'fr': 'Terminée', 'en': 'Finished', 'ar': 'منتهية', 'de': 'Fertig', 'es': 'Terminada'},
  'continue': {'fr': 'Continuer', 'en': 'Continue', 'ar': 'متابعة', 'de': 'Weiter', 'es': 'Continuar'},
  'newCreation': {'fr': 'Nouvelle création', 'en': 'New creation', 'ar': 'إبداع جديد', 'de': 'Neues Werk', 'es': 'Nueva creación'},
  'createDrawing': {'fr': 'Créer un dessin', 'en': 'Create a drawing', 'ar': 'أنشئ رسمة', 'de': 'Bild malen', 'es': 'Crear un dibujo'},
  'talent': {'fr': 'Quel talent !', 'en': 'What talent!', 'ar': 'يا لها من موهبة!', 'de': 'Was für ein Talent!', 'es': '¡Qué talento!'},
  'bravo': {'fr': 'Bravo !', 'en': 'Great!', 'ar': 'أحسنت!', 'de': 'Super!', 'es': '¡Bravo!'},
  'magic': {'fr': 'Magique !', 'en': 'Magic!', 'ar': 'سحر!', 'de': 'Magisch!', 'es': '¡Mágico!'},
  'saved': {'fr': 'Bien rangé dans ton musée !', 'en': 'Saved in your museum!', 'ar': 'تم الحفظ في متحفك!', 'de': 'In deinem Museum gespeichert!', 'es': '¡Guardado en tu museo!'},
  'emptyMuseum': {'fr': 'Ton musée est encore vide. Crée ton premier chef-d’œuvre !', 'en': 'Your museum is still empty. Create your first masterpiece!', 'ar': 'متحفك فارغ. أنشئ تحفتك الأولى!', 'de': 'Dein Museum ist noch leer. Mal dein erstes Meisterwerk!', 'es': 'Tu museo está vacío. ¡Crea tu primera obra maestra!'},
  'choosePicture': {'fr': 'Choisis un dessin', 'en': 'Choose a picture', 'ar': 'اختر رسمة', 'de': 'Wähle ein Bild', 'es': 'Elige un dibujo'},
  'blankPage': {'fr': 'Page blanche', 'en': 'Blank page', 'ar': 'صفحة بيضاء', 'de': 'Leeres Blatt', 'es': 'Hoja en blanco'},
  'rename': {'fr': 'Renommer', 'en': 'Rename', 'ar': 'إعادة التسمية', 'de': 'Umbenennen', 'es': 'Renombrar'},
  'share': {'fr': 'Partager', 'en': 'Share', 'ar': 'مشاركة', 'de': 'Teilen', 'es': 'Compartir'},
  'delete': {'fr': 'Supprimer', 'en': 'Delete', 'ar': 'حذف', 'de': 'Löschen', 'es': 'Eliminar'},
  'deleteAsk': {'fr': 'Supprimer ce dessin ?', 'en': 'Delete this picture?', 'ar': 'حذف هذه الرسمة؟', 'de': 'Dieses Bild löschen?', 'es': '¿Eliminar este dibujo?'},
  'cancel': {'fr': 'Annuler', 'en': 'Cancel', 'ar': 'إلغاء', 'de': 'Abbrechen', 'es': 'Cancelar'},
  'ok': {'fr': 'OK', 'en': 'OK', 'ar': 'حسناً', 'de': 'OK', 'es': 'OK'},
  'settings': {'fr': 'Réglages', 'en': 'Settings', 'ar': 'الإعدادات', 'de': 'Einstellungen', 'es': 'Ajustes'},
  'showModel': {'fr': 'Montrer le modèle', 'en': 'Show the model', 'ar': 'إظهار النموذج', 'de': 'Vorlage zeigen', 'es': 'Mostrar el modelo'},
  'sounds': {'fr': 'Sons', 'en': 'Sounds', 'ar': 'الأصوات', 'de': 'Töne', 'es': 'Sonidos'},
  'myDrawing': {'fr': 'Mon dessin', 'en': 'My drawing', 'ar': 'رسمتي', 'de': 'Mein Bild', 'es': 'Mi dibujo'},
  'nameHint': {'fr': 'Nom du dessin', 'en': 'Picture name', 'ar': 'اسم الرسمة', 'de': 'Name des Bildes', 'es': 'Nombre del dibujo'},
};

String mpText(BuildContext c, String key) {
  final m = _mpUi[key];
  if (m == null) return key;
  return m[mpLang(c)] ?? m['fr']!;
}

// ── palette & tools ────────────────────────────────────────────────────────

const List<Color> mpColors = [
  Color(0xFFFF3B3B), Color(0xFFFF8A1E), Color(0xFFFFD21A), Color(0xFF2FBF4A), Color(0xFF19C9E0), Color(0xFF2C5BFF),
  Color(0xFF8A2BE2), Color(0xFFFF5FB4), Color(0xFF8B5A2B), Color(0xFFFFD1B0), Color(0xFF9E9E9E), Color(0xFF212121),
  Color(0xFFFFFFFF),
];

/// Free-drawing tools (Dessiner) and the stroke kinds used by Colorier.
enum MpTool { pencil, brush, crayon, eraser, star }

/// Colorier tools.
enum MpColorTool { bucket, brush, wand, eraser }

const List<double> mpDrawSizes = [6, 13, 24];

// ── strokes ────────────────────────────────────────────────────────────────

class MpStroke {
  final MpTool tool;
  final int color;
  final double width;
  final List<Offset> points;
  MpStroke(this.tool, this.color, this.width, [List<Offset>? pts]) : points = pts ?? <Offset>[];

  Map<String, dynamic> toJson() => {
        't': tool.index,
        'c': color,
        'w': width,
        'p': [for (final p in points) ...[double.parse(p.dx.toStringAsFixed(1)), double.parse(p.dy.toStringAsFixed(1))]],
      };

  static MpStroke fromJson(Map<String, dynamic> j) {
    final raw = (j['p'] as List).cast<num>();
    final pts = <Offset>[for (var i = 0; i + 1 < raw.length; i += 2) Offset(raw[i].toDouble(), raw[i + 1].toDouble())];
    return MpStroke(MpTool.values[(j['t'] as int).clamp(0, MpTool.values.length - 1)], j['c'] as int, (j['w'] as num).toDouble(), pts);
  }
}

/// Paints a list of strokes (kid-friendly pencil / brush / crayon / eraser / stars).
void mpPaintStrokes(Canvas canvas, Size size, List<MpStroke> strokes) {
  canvas.saveLayer(Offset.zero & size, Paint());
  for (var i = 0; i < strokes.length; i++) {
    mpPaintStroke(canvas, strokes[i], i);
  }
  canvas.restore();
}

Path _smooth(List<Offset> pts) {
  final p = Path();
  if (pts.isEmpty) return p;
  p.moveTo(pts.first.dx, pts.first.dy);
  if (pts.length < 3) {
    for (final q in pts.skip(1)) {
      p.lineTo(q.dx, q.dy);
    }
    return p;
  }
  for (var i = 1; i < pts.length - 1; i++) {
    final mid = Offset((pts[i].dx + pts[i + 1].dx) / 2, (pts[i].dy + pts[i + 1].dy) / 2);
    p.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
  }
  p.lineTo(pts.last.dx, pts.last.dy);
  return p;
}

Path _starPath(Offset c, double r, double rot) {
  final p = Path();
  for (var i = 0; i < 10; i++) {
    final a = rot - pi / 2 + i * pi / 5;
    final rr = i.isEven ? r : r * 0.45;
    final o = Offset(c.dx + cos(a) * rr, c.dy + sin(a) * rr);
    if (i == 0) {
      p.moveTo(o.dx, o.dy);
    } else {
      p.lineTo(o.dx, o.dy);
    }
  }
  return p..close();
}

void mpPaintStroke(Canvas canvas, MpStroke s, int seed) {
  if (s.points.isEmpty) return;
  final color = Color(s.color);
  final base = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = s.width
    ..isAntiAlias = true;
  switch (s.tool) {
    case MpTool.pencil:
      if (s.points.length == 1) {
        canvas.drawCircle(s.points.first, s.width / 2, Paint()..color = color);
      } else {
        canvas.drawPath(_smooth(s.points), base);
      }
      break;
    case MpTool.brush:
      final w = s.width * 1.7;
      if (s.points.length == 1) {
        canvas.drawCircle(s.points.first, w / 2, Paint()..color = color.withOpacity(0.9));
      } else {
        canvas.drawPath(_smooth(s.points), base
          ..strokeWidth = w
          ..color = color.withOpacity(0.88)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.08));
      }
      break;
    case MpTool.crayon:
      // several thin, slightly offset passes give a waxy crayon texture
      final rnd = Random(seed * 7919 + 13);
      final passes = 5;
      for (var k = 0; k < passes; k++) {
        final dx = (rnd.nextDouble() - 0.5) * s.width * 0.7;
        final dy = (rnd.nextDouble() - 0.5) * s.width * 0.7;
        final pts = [for (final p in s.points) p.translate(dx, dy)];
        final paint = Paint()
          ..color = color.withOpacity(0.42 + rnd.nextDouble() * 0.2)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = s.width * (0.35 + rnd.nextDouble() * 0.25);
        if (pts.length == 1) {
          canvas.drawCircle(pts.first, paint.strokeWidth / 2, paint..style = PaintingStyle.fill);
        } else {
          canvas.drawPath(_smooth(pts), paint);
        }
      }
      break;
    case MpTool.eraser:
      final er = Paint()
        ..blendMode = BlendMode.clear
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = s.width * 2;
      if (s.points.length == 1) {
        canvas.drawCircle(s.points.first, s.width, er..style = PaintingStyle.fill);
      } else {
        canvas.drawPath(_smooth(s.points), er);
      }
      break;
    case MpTool.star:
      final r = s.width * 1.3;
      final gap = r * 2.2;
      final rnd = Random(seed * 31 + 7);
      final fill = Paint()..color = color;
      final rim = Paint()
        ..color = Colors.white.withOpacity(0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.0, r * 0.14);
      Offset? last;
      for (final p in s.points) {
        if (last != null && (p - last).distance < gap) continue;
        final path = _starPath(p, r * (0.8 + rnd.nextDouble() * 0.4), rnd.nextDouble() * pi);
        canvas.drawPath(path, fill);
        canvas.drawPath(path, rim);
        last = p;
      }
      break;
  }
}

// ── coloring pages ─────────────────────────────────────────────────────────

class MpPage {
  final String id;
  final int w, h;
  final Map<String, String> name;
  final List<int> modelColors; // index = region - 1
  const MpPage(this.id, this.w, this.h, this.name, this.modelColors);

  String get lines => '${mpPagesDir}mp_page_${id}_lines.png';
  String get map => '${mpPagesDir}mp_page_${id}_map.png';
  String get model => '${mpPagesDir}mp_page_${id}_model.webp';
  String title(BuildContext c) => name[mpLang(c)] ?? name['fr']!;
}

MpPage? mpPageById(String? id) {
  for (final p in mpPages) {
    if (p.id == id) return p;
  }
  return null;
}

/// Drawing mode canvas, in logical units.
const Size mpDrawSize = Size(1000, 760);

// ── saved creations ────────────────────────────────────────────────────────

class MpCreation {
  final String id;
  final String kind; // 'color' | 'draw'
  final String? page;
  String title;
  bool done;
  int updated;
  MpCreation({required this.id, required this.kind, this.page, required this.title, this.done = false, required this.updated});

  Map<String, dynamic> toJson() => {'id': id, 'kind': kind, 'page': page, 'title': title, 'done': done, 'u': updated};
  static MpCreation fromJson(Map<String, dynamic> j) => MpCreation(
        id: j['id'] as String,
        kind: j['kind'] as String,
        page: j['page'] as String?,
        title: (j['title'] ?? '') as String,
        done: (j['done'] ?? false) as bool,
        updated: (j['u'] ?? 0) as int,
      );
}

/// What a creation contains, to continue it later.
class MpWork {
  final Map<int, int> fills; // region → colour (coloring pages)
  final List<MpStroke> strokes;
  MpWork(this.fills, this.strokes);

  Map<String, dynamic> toJson() => {
        'f': {for (final e in fills.entries) '${e.key}': e.value},
        's': [for (final s in strokes) s.toJson()],
      };
  static MpWork fromJson(Map<String, dynamic> j) => MpWork(
        {for (final e in ((j['f'] ?? {}) as Map).entries) int.parse(e.key as String): e.value as int},
        [for (final s in (j['s'] ?? []) as List) MpStroke.fromJson((s as Map).cast<String, dynamic>())],
      );
}

class MpStore {
  static const _key = 'mp_creations';
  static Directory? _dir;

  static Future<Directory> dir() async {
    if (_dir != null) return _dir!;
    final d = Directory('${(await getApplicationDocumentsDirectory()).path}/magic_paint');
    if (!await d.exists()) await d.create(recursive: true);
    return _dir = d;
  }

  static Future<List<MpCreation>> list() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_key) ?? const [];
    final out = <MpCreation>[];
    for (final r in raw) {
      try {
        out.add(MpCreation.fromJson(jsonDecode(r) as Map<String, dynamic>));
      } catch (_) {}
    }
    out.sort((a, b) => b.updated.compareTo(a.updated));
    return out;
  }

  static Future<void> _write(List<MpCreation> all) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_key, [for (final c in all) jsonEncode(c.toJson())]);
  }

  static Future<File> imageFile(String id) async => File('${(await dir()).path}/$id.png');
  static Future<File> _workFile(String id) async => File('${(await dir()).path}/$id.json');

  static Future<void> save(MpCreation c, MpWork work, ui.Image image) async {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes != null) await (await imageFile(c.id)).writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    await (await _workFile(c.id)).writeAsString(jsonEncode(work.toJson()), flush: true);
    final all = await list();
    all.removeWhere((x) => x.id == c.id);
    all.add(c);
    await _write(all);
    PaintingBinding.instance.imageCache.clear();
  }

  static Future<void> update(MpCreation c) async {
    final all = await list();
    final i = all.indexWhere((x) => x.id == c.id);
    if (i >= 0) all[i] = c;
    await _write(all);
  }

  static Future<MpWork?> work(String id) async {
    try {
      final f = await _workFile(id);
      if (!await f.exists()) return null;
      return MpWork.fromJson(jsonDecode(await f.readAsString()) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> delete(String id) async {
    final all = await list();
    all.removeWhere((x) => x.id == id);
    await _write(all);
    for (final f in [await imageFile(id), await _workFile(id)]) {
      if (await f.exists()) await f.delete();
    }
  }

  static String newId() => 'mp_${DateTime.now().millisecondsSinceEpoch}';

  static Future<bool> get showModel async => (await SharedPreferences.getInstance()).getBool('mp_show_model') ?? true;
  static Future<void> setShowModel(bool v) async => (await SharedPreferences.getInstance()).setBool('mp_show_model', v);
  static Future<bool> get sounds async => (await SharedPreferences.getInstance()).getBool('mp_sounds') ?? true;
  static Future<void> setSounds(bool v) async => (await SharedPreferences.getInstance()).setBool('mp_sounds', v);
}
