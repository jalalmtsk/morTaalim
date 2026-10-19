import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mortaalim/Manager/lesson_progress.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/KidScene/kid_page_parts.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _d = 'assets/images/UI/KidScene/';
const _ink = Color(0xFF2D1A7A);
const _teal = Color(0xFF0F7A72);
const _tealDeep = Color(0xFF0A5A55);
const _green = Color(0xFF13915A);
const LessonTracker _tracker = LessonTracker('religion');

String _lang(BuildContext c) {
  final l = Localizations.localeOf(c).languageCode;
  return const ['fr', 'en', 'ar', 'de'].contains(l) ? l : 'fr';
}

String _t(BuildContext c, Map<String, String> m) => m[_lang(c)] ?? m['fr'] ?? '';

/// One good manner: art, what the character says, the rule, and the child's task.
class Manner {
  final String id;
  final Map<String, String> title, bubble, rule, task;
  const Manner(this.id, this.title, this.bubble, this.rule, this.task);
  String get art => '${_d}mn_$id.webp';
}

const List<Manner> manners = [
  Manner('bonjour',
      {'fr': 'Dire bonjour', 'en': 'Say hello', 'ar': 'إلقاء السلام', 'de': 'Hallo sagen'},
      {'fr': 'Assalamu alaykum !', 'en': 'Assalamu alaykum!', 'ar': 'السلام عليكم!', 'de': 'Assalamu alaykum!'},
      {'fr': 'Je salue avec le sourire !', 'en': 'I greet with a smile!', 'ar': 'أُسلّم بابتسامة!', 'de': 'Ich grüße mit einem Lächeln!'},
      {'fr': 'À toi de dire bonjour !', 'en': 'Your turn to say hello!', 'ar': 'دورك لتلقي السلام!', 'de': 'Jetzt sagst du Hallo!'}),
  Manner('partager',
      {'fr': 'Partager', 'en': 'Share', 'ar': 'المشاركة', 'de': 'Teilen'},
      {'fr': 'Tiens, on partage !', 'en': 'Here, let’s share!', 'ar': 'تفضّل، لنتشارك!', 'de': 'Hier, wir teilen!'},
      {'fr': 'Je partage mes affaires avec les autres.', 'en': 'I share my things with others.', 'ar': 'أشارك أغراضي مع الآخرين.', 'de': 'Ich teile meine Sachen mit anderen.'},
      {'fr': 'À toi de partager un jouet !', 'en': 'Your turn to share a toy!', 'ar': 'دورك لتشارك لعبة!', 'de': 'Jetzt teilst du ein Spielzeug!'}),
  Manner('merci',
      {'fr': 'Dire merci', 'en': 'Say thank you', 'ar': 'قول شكراً', 'de': 'Danke sagen'},
      {'fr': 'Jazak Allahu khayran !', 'en': 'Jazak Allahu khayran!', 'ar': 'جزاك الله خيراً!', 'de': 'Jazak Allahu khayran!'},
      {'fr': 'Je dis merci quand on m’aide ou qu’on me donne quelque chose.', 'en': 'I say thank you when someone helps me or gives me something.', 'ar': 'أقول شكراً عندما يساعدني أحد أو يعطيني شيئاً.', 'de': 'Ich sage Danke, wenn mir jemand hilft oder etwas schenkt.'},
      {'fr': 'À toi de dire merci !', 'en': 'Your turn to say thank you!', 'ar': 'دورك لتقول شكراً!', 'de': 'Jetzt sagst du Danke!'}),
  Manner('respect',
      {'fr': 'Respecter les autres', 'en': 'Respect others', 'ar': 'احترام الآخرين', 'de': 'Andere respektieren'},
      {'fr': 'Je t’écoute.', 'en': 'I’m listening.', 'ar': 'أنا أسمعك.', 'de': 'Ich höre dir zu.'},
      {'fr': 'J’écoute les autres et je parle gentiment.', 'en': 'I listen to others and speak kindly.', 'ar': 'أستمع إلى الآخرين وأتكلم بلطف.', 'de': 'Ich höre anderen zu und spreche freundlich.'},
      {'fr': 'À toi d’écouter un ami !', 'en': 'Your turn to listen to a friend!', 'ar': 'دورك لتستمع إلى صديق!', 'de': 'Jetzt hörst du einem Freund zu!'}),
  Manner('aider',
      {'fr': 'Aider à la maison', 'en': 'Help at home', 'ar': 'المساعدة في البيت', 'de': 'Zu Hause helfen'},
      {'fr': 'Je t’aide, maman !', 'en': 'I’ll help you, Mum!', 'ar': 'سأساعدك يا أمي!', 'de': 'Ich helfe dir, Mama!'},
      {'fr': 'J’aide à ranger mes jouets et à mettre la table.', 'en': 'I help tidy my toys and set the table.', 'ar': 'أساعد في ترتيب ألعابي وتجهيز المائدة.', 'de': 'Ich räume meine Spielsachen auf und decke den Tisch.'},
      {'fr': 'À toi de ranger un jouet !', 'en': 'Your turn to tidy a toy!', 'ar': 'دورك لترتيب لعبة!', 'de': 'Jetzt räumst du ein Spielzeug auf!'}),
  Manner('vivant',
      {'fr': 'Prendre soin du vivant', 'en': 'Care for living things', 'ar': 'الرفق بالكائنات', 'de': 'Lebewesen pflegen'},
      {'fr': 'Bismillah, je t’arrose !', 'en': 'Bismillah, here’s some water!', 'ar': 'بسم الله، سأسقيكِ!', 'de': 'Bismillah, hier ist Wasser!'},
      {'fr': 'Je prends soin des plantes et des animaux.', 'en': 'I take care of plants and animals.', 'ar': 'أعتني بالنباتات والحيوانات.', 'de': 'Ich kümmere mich um Pflanzen und Tiere.'},
      {'fr': 'À toi d’arroser une plante !', 'en': 'Your turn to water a plant!', 'ar': 'دورك لتسقي نبتة!', 'de': 'Jetzt gießt du eine Pflanze!'}),
];

const Map<String, Map<String, String>> _ui = {
  'title': {'fr': 'Bonnes manières', 'en': 'Good Manners', 'ar': 'الأخلاق الحميدة', 'de': 'Gutes Benehmen'},
  'sheetTitle': {'fr': 'Les bonnes manières', 'en': 'Good manners', 'ar': 'الأخلاق الحميدة', 'de': 'Gutes Benehmen'},
  'heroTop': {'fr': 'La gentillesse', 'en': 'Kindness', 'ar': 'اللطف', 'de': 'Freundlichkeit'},
  'heroBottom': {'fr': 'au quotidien', 'en': 'every day', 'ar': 'كل يوم', 'de': 'jeden Tag'},
  'heroSub': {'fr': 'De petits gestes qui font du bien', 'en': 'Little gestures that do good', 'ar': 'لفتات صغيرة تُسعد القلوب', 'de': 'Kleine Gesten, die guttun'},
  'gesture': {'fr': 'Mon petit geste du jour', 'en': 'My little gesture of the day', 'ar': 'لفتتي الصغيرة اليوم', 'de': 'Meine kleine Geste heute'},
  'discover': {'fr': 'Découvrir', 'en': 'Discover', 'ar': 'اكتشف', 'de': 'Entdecken'},
  'smile': {'fr': 'Un sourire peut illuminer une journée', 'en': 'A smile can light up a day', 'ar': 'ابتسامة قد تُنير يوماً كاملاً', 'de': 'Ein Lächeln kann einen Tag erhellen'},
  'iDiscover': {'fr': 'Je découvre', 'en': 'Let’s go', 'ar': 'أكتشف', 'de': 'Los geht’s'},
  'listen': {'fr': 'Écouter', 'en': 'Listen', 'ar': 'استمع', 'de': 'Anhören'},
  'understood': {'fr': 'J’ai compris !', 'en': 'I understand!', 'ar': 'فهمت!', 'de': 'Verstanden!'},
  'learned': {'fr': 'Bravo, tu connais ce geste !', 'en': 'Well done, you know this one!', 'ar': 'أحسنت، تعرف هذه اللفتة!', 'de': 'Super, das kannst du schon!'},
};

String _u(BuildContext c, String k) => _t(c, _ui[k] ?? const {});

class _Store {
  static String _k(String id) => 'manner_done_$id';
  static Future<Set<String>> learned() async {
    final p = await SharedPreferences.getInstance();
    return {for (final m in manners) if (p.getBool(_k(m.id)) ?? false) m.id};
  }

  /// True the first time.
  static Future<bool> learn(String id) async {
    final p = await SharedPreferences.getInstance();
    if (p.getBool(_k(id)) ?? false) return false;
    await p.setBool(_k(id), true);
    return true;
  }
}

/// Manner of the day (changes every day).
Manner get _today => manners[DateTime.now().difference(DateTime(2024)).inDays % manners.length];

Route _fade(Widget page) => PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      transitionDuration: const Duration(milliseconds: 320),
    );

Widget _roundBtn(double size, IconData icon, VoidCallback onTap) => KidPressable(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF9B5CFF), Color(0xFF6A2BE0)]),
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [BoxShadow(color: const Color(0xFF4A1BA8).withOpacity(0.35), blurRadius: 6, offset: const Offset(0, 3))],
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.52),
      ),
    );

Widget _greenPill(double s, String label, VoidCallback onTap, {double h = 46}) => KidPressable(
      onTap: onTap,
      pressedScale: 0.94,
      child: Container(
        height: h * s,
        padding: EdgeInsets.symmetric(horizontal: 16 * s),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2CC07A), Color(0xFF0B7A45)]),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [BoxShadow(color: const Color(0xFF075A33), offset: Offset(0, 3 * s))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: kidBodyStyle(17 * s, color: Colors.white, weight: FontWeight.w700)))),
          Icon(Icons.chevron_right_rounded, color: Colors.white, size: 24 * s),
        ]),
      ),
    );

// ═══════════════════════════════════════════════════════════════════════════
// Menu
// ═══════════════════════════════════════════════════════════════════════════

class MannersPage extends StatefulWidget {
  const MannersPage({super.key});
  @override
  State<MannersPage> createState() => _MannersPageState();
}

class _MannersPageState extends State<MannersPage> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 7))..repeat();
  final FlutterTts _tts = FlutterTts();
  Set<String> _learned = {};
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      KidAssets.precache(context, [
        '${_d}it_page_bg.webp', '${_d}mn_hero.webp', '${_d}mn_heart_green.webp', '${_d}mn_heart_gold.webp',
        for (final m in manners) m.art,
      ]);
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _intro.dispose();
    _idle.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final l = await _Store.learned();
    if (mounted) setState(() => _learned = l);
  }

  AudioManager get _audio => Provider.of<AudioManager>(context, listen: false);

  Future<void> _say(Manner m) async {
    _audio.playEventSound('clickButton2');
    await speakManner(_tts, context, m);
  }

  Future<void> _open(int i) async {
    _audio.playEventSound('PopButton');
    await _tts.stop();
    await Navigator.push(context, _fade(MannerDetailPage(start: i)));
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final w = min(size.width, 600.0) - 28;
    final s = (w / 380).clamp(0.8, 1.4);
    Widget step(int i, Widget c) => KidIntro(intro: _intro, from: 0.06 * i, to: min(1.0, 0.45 + 0.06 * i), rise: 22, child: c);
    final today = _today;
    final nextUnlearned = manners.indexWhere((m) => !_learned.contains(m.id));

    return Scaffold(
      backgroundColor: KidColors.sky,
      body: Stack(children: [
        const Positioned.fill(child: KidPageBackground(asset: '${_d}it_page_bg.webp', wash: 0.04)),
        SafeArea(
          bottom: false,
          child: Center(
            child: SizedBox(
              width: w,
              child: Column(children: [
                const SizedBox(height: 6),
                step(0, _header(s)),
                SizedBox(height: 10 * s),
                Expanded(
                  child: CustomScrollView(physics: const BouncingScrollPhysics(), slivers: [
                    SliverToBoxAdapter(child: step(1, _hero(s))),
                    SliverToBoxAdapter(child: SizedBox(height: 12 * s)),
                    SliverToBoxAdapter(child: step(2, _gestureCard(s, today))),
                    SliverToBoxAdapter(child: SizedBox(height: 12 * s)),
                    SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: size.width >= 700 ? 3 : 2,
                        mainAxisSpacing: 12 * s,
                        crossAxisSpacing: 12 * s,
                        childAspectRatio: 1.42,
                      ),
                      delegate: SliverChildBuilderDelegate((c, i) => step(3 + min(i, 5), _card(s, i)), childCount: manners.length),
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: 12 * s)),
                    SliverToBoxAdapter(child: step(9, _smileCard(s, nextUnlearned < 0 ? 0 : nextUnlearned))),
                    SliverToBoxAdapter(child: SizedBox(height: 20 * s + pad.bottom)),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _header(double s) => Container(
        height: 62 * s,
        padding: EdgeInsets.symmetric(horizontal: 6 * s),
        decoration: kidCardDecoration(40 * s, shadow: 0.18),
        child: Row(children: [
          _roundBtn(48 * s, Icons.arrow_back_rounded, () {
            _audio.playEventSound('cancelButton');
            Navigator.of(context).maybePop();
          }),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(_u(context, 'title'), style: kidTitleStyle(30 * s, color: _ink).copyWith(shadows: const [])),
            ),
          ),
          Consumer<AudioManager>(
            builder: (_, a, __) => _roundBtn(48 * s, a.isBgMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded, () {
              a.playEventSound('toggleButton');
              a.toggleBgMute();
            }),
          ),
        ]),
      );

  Widget _hero(double s) => AspectRatio(
        aspectRatio: 2.15,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26 * s),
          child: LayoutBuilder(builder: (c, b) {
            final h = b.maxHeight, w = b.maxWidth;
            TextStyle big(double size) => TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w700,
                  fontSize: size,
                  height: 1.0,
                  color: const Color(0xFFFFF4C2),
                  shadows: const [
                    Shadow(color: Color(0xFF0B6B40), offset: Offset(0, -2)),
                    Shadow(color: Color(0xFF0B6B40), offset: Offset(2, 0)),
                    Shadow(color: Color(0xFF0B6B40), offset: Offset(-2, 0)),
                    Shadow(color: Color(0xFF0B6B40), offset: Offset(0, 3)),
                    Shadow(color: Color(0xFF0B6B40), offset: Offset(0, 4.5)),
                    Shadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 5)),
                  ],
                );
            return Stack(children: [
              Positioned.fill(child: Image.asset('${_d}it_page_bg.webp', fit: BoxFit.cover, alignment: const Alignment(0, -0.4))),
              PositionedDirectional(
                end: 0,
                top: 0,
                bottom: 0,
                width: w * 0.62,
                child: ShaderMask(
                  shaderCallback: (r) => const LinearGradient(colors: [Colors.transparent, Colors.black], stops: [0, 0.25]).createShader(r),
                  blendMode: BlendMode.dstIn,
                  child: Image.asset('${_d}mn_hero.webp', fit: BoxFit.cover),
                ),
              ),
              PositionedDirectional(
                start: w * 0.04,
                top: h * 0.12,
                bottom: h * 0.12,
                width: w * 0.5,
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  FittedBox(fit: BoxFit.scaleDown, child: Text(_u(context, 'heroTop'), style: big(h * 0.18))),
                  FittedBox(fit: BoxFit.scaleDown, child: Text(_u(context, 'heroBottom'), style: big(h * 0.18))),
                  SizedBox(height: h * 0.05),
                  Flexible(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 3 * s),
                      decoration: BoxDecoration(color: const Color(0xFF0B4F36).withOpacity(0.85), borderRadius: BorderRadius.circular(30)),
                      child: FittedBox(fit: BoxFit.scaleDown, child: Text(_u(context, 'heroSub'), style: kidBodyStyle(11.5 * s, color: Colors.white, weight: FontWeight.w600))),
                    ),
                  ),
                ]),
              ),
            ]);
          }),
        ),
      );

  Widget _gestureCard(double s, Manner m) => Container(
        padding: EdgeInsetsDirectional.fromSTEB(6 * s, 8 * s, 10 * s, 8 * s),
        decoration: kidCardDecoration(30 * s, shadow: 0.18),
        child: Row(children: [
          AnimatedBuilder(
            animation: _idle,
            builder: (_, c) => Transform.scale(scale: 1 + 0.05 * sin(_idle.value * 8 * pi), child: c),
            child: Image.asset('${_d}mn_heart_green.webp', width: 84 * s, height: 84 * s * 0.56),
          ),
          SizedBox(width: 6 * s),
          Expanded(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              FittedBox(fit: BoxFit.scaleDown, child: Text(_u(context, 'gesture'), style: kidBodyStyle(15 * s, color: _ink, weight: FontWeight.w700))),
              FittedBox(fit: BoxFit.scaleDown, child: Text(_t(context, m.task), style: kidBodyStyle(13.5 * s, color: _green, weight: FontWeight.w700))),
            ]),
          ),
          SizedBox(width: 6 * s),
          _greenPill(s, _u(context, 'discover'), () => _open(manners.indexOf(m)), h: 42),
        ]),
      );

  Widget _card(double s, int i) {
    final m = manners[i];
    final done = _learned.contains(m.id);
    return KidPressable(
      onTap: () => _open(i),
      pressedScale: 0.95,
      child: Container(
        padding: EdgeInsets.all(5 * s),
        decoration: kidCardDecoration(22 * s, shadow: 0.18),
        child: Column(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16 * s),
              child: Stack(fit: StackFit.expand, children: [
                Image.asset(m.art, fit: BoxFit.cover),
                if (done)
                  PositionedDirectional(
                    top: 6 * s,
                    end: 6 * s,
                    child: Container(
                      padding: EdgeInsets.all(2 * s),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(Icons.check_circle_rounded, color: _green, size: 22 * s),
                    ),
                  ),
              ]),
            ),
          ),
          SizedBox(height: 5 * s),
          Row(children: [
            KidPressable(
              onTap: () => _say(m),
              child: Container(
                width: 34 * s,
                height: 34 * s,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF9B5CFF), Color(0xFF6A2BE0)])),
                child: Icon(Icons.volume_up_rounded, color: Colors.white, size: 19 * s),
              ),
            ),
            SizedBox(width: 6 * s),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(_t(context, m.title), maxLines: 1, style: kidBodyStyle(16 * s, color: _ink, weight: FontWeight.w700)),
              ),
            ),
            Container(
              width: 32 * s,
              height: 32 * s,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF2CC07A), Color(0xFF0B7A45)])),
              child: Transform.flip(
                flipX: Directionality.of(context) == TextDirection.rtl,
                child: Icon(Icons.chevron_right_rounded, color: Colors.white, size: 24 * s),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _smileCard(double s, int target) => Container(
        padding: EdgeInsetsDirectional.fromSTEB(6 * s, 8 * s, 10 * s, 8 * s),
        decoration: kidCardDecoration(30 * s, shadow: 0.18),
        child: Row(children: [
          AnimatedBuilder(
            animation: _idle,
            builder: (_, c) => Transform.rotate(angle: sin(_idle.value * 4 * pi) * 0.06, child: c),
            child: Image.asset('${_d}mn_heart_gold.webp', width: 84 * s, height: 84 * s * 0.51),
          ),
          SizedBox(width: 6 * s),
          Expanded(
            child: Text(_u(context, 'smile'),
                textAlign: TextAlign.center, maxLines: 2, style: kidBodyStyle(14.5 * s, color: _ink, weight: FontWeight.w700)),
          ),
          SizedBox(width: 6 * s),
          KidPressable(
            onTap: () => _open(target),
            pressedScale: 0.94,
            child: Container(
              height: 44 * s,
              padding: EdgeInsets.symmetric(horizontal: 14 * s),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFE45C), Color(0xFFFFC21A)]),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [BoxShadow(color: const Color(0xFFD08A00), offset: Offset(0, 3 * s))],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_u(context, 'iDiscover'), style: kidBodyStyle(16 * s, color: const Color(0xFF4A2A00), weight: FontWeight.w700)),
                Icon(Icons.chevron_right_rounded, color: const Color(0xFF4A2A00), size: 22 * s),
              ]),
            ),
          ),
        ]),
      );
}

Future<void> speakManner(FlutterTts tts, BuildContext context, Manner m) async {
  final lang = _lang(context);
  final code = switch (lang) { 'ar' => 'ar-SA', 'de' => 'de-DE', 'en' => 'en-US', _ => 'fr-FR' };
  final text = '${_t(context, m.title)}. ${_t(context, m.bubble)} ${_t(context, m.rule)}';
  try {
    await tts.stop();
    await tts.setLanguage(code);
    await tts.setSpeechRate(0.45);
    await tts.setPitch(1.1);
    await tts.speak(text);
  } catch (_) {}
}

// ═══════════════════════════════════════════════════════════════════════════
// Detail
// ═══════════════════════════════════════════════════════════════════════════

class MannerDetailPage extends StatefulWidget {
  final int start;
  const MannerDetailPage({super.key, this.start = 0});
  @override
  State<MannerDetailPage> createState() => _MannerDetailPageState();
}

class _MannerDetailPageState extends State<MannerDetailPage> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  late final AnimationController _pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
  final FlutterTts _tts = FlutterTts();
  final ScrollController _strip = ScrollController();
  late int _i = widget.start;
  Set<String> _learned = {};

  Manner get _m => manners[_i];

  @override
  void initState() {
    super.initState();
    _Store.learned().then((l) {
      if (mounted) setState(() => _learned = l);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_strip.hasClients) _strip.jumpTo((max(0, _i - 1) * 110.0).clamp(0.0, _strip.position.maxScrollExtent));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    KidAssets.precache(context, ['${_d}mn_courtyard.webp', '${_d}mn_boy.webp', '${_d}mn_girl.webp', '${_d}mn_bear.webp', '${_d}mn_medal.webp']);
  }

  @override
  void dispose() {
    _tts.stop();
    _idle.dispose();
    _pop.dispose();
    _strip.dispose();
    super.dispose();
  }

  AudioManager get _audio => Provider.of<AudioManager>(context, listen: false);

  void _select(int i) {
    if (i == _i) return;
    _audio.playEventSound('clickButton2');
    _tts.stop();
    setState(() => _i = i);
    _pop.forward(from: 0);
  }

  Future<void> _understood() async {
    final first = await _Store.learn(_m.id);
    await _tracker.record('manners', _i);
    if (!mounted) return;
    _audio.playSfx('assets/audios/UI_Audio/SFX_Audio/victory2_SFX.mp3');
    if (first) {
      final xp = Provider.of<ExperienceManager>(context, listen: false);
      xp.addTokenBanner(context, 10);
      xp.addXP(5, context: context);
    }
    setState(() => _learned.add(_m.id));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: _teal,
      duration: const Duration(milliseconds: 1400),
      content: Text(_u(context, 'learned'), style: kidBodyStyle(15, color: Colors.white, weight: FontWeight.w600)),
    ));
    final next = manners.indexWhere((m) => !_learned.contains(m.id));
    if (next >= 0) {
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) _select(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final w = min(size.width, 600.0);
    final s = ((w - 28) / 380).clamp(0.8, 1.4);
    final m = _m;
    final done = _learned.contains(m.id);

    return Scaffold(
      backgroundColor: const Color(0xFF6E8F6A),
      body: Stack(children: [
        Positioned.fill(
          child: ImageFiltered(
            imageFilter: _blur,
            child: Image.asset('${_d}mn_courtyard.webp', fit: BoxFit.cover),
          ),
        ),
        Positioned.fill(child: ColoredBox(color: Colors.black.withOpacity(0.12))),
        SafeArea(
          bottom: false,
          child: Center(
            child: SizedBox(
              width: w,
              child: Column(children: [
                SizedBox(height: 6 * s),
                _banner(s),
                SizedBox(height: 8 * s),
                SizedBox(
                  height: 108 * s,
                  child: ListView.separated(
                    controller: _strip,
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 14 * s),
                    itemCount: manners.length,
                    separatorBuilder: (_, __) => SizedBox(width: 8 * s),
                    itemBuilder: (_, i) => _thumb(s, i),
                  ),
                ),
                SizedBox(height: 8 * s),
                Expanded(child: _sheet(s, m, done, pad.bottom)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  static final ui.ImageFilter _blur = ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6);

  Widget _banner(double s) => Container(
        height: 50 * s,
        margin: EdgeInsets.symmetric(horizontal: 40 * s),
        padding: EdgeInsets.symmetric(horizontal: 16 * s),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16 * s),
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF15847B), _tealDeep]),
          border: Border.all(color: const Color(0xFFE9C46A), width: 2.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Icon(Icons.mosque_rounded, color: const Color(0xFFE9C46A), size: 26 * s),
          SizedBox(width: 8 * s),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(_u(context, 'sheetTitle'), style: kidBodyStyle(22 * s, color: const Color(0xFFFFF4D6), weight: FontWeight.w700)),
            ),
          ),
          SizedBox(width: 34 * s),
        ]),
      );

  Widget _thumb(double s, int i) {
    final m = manners[i];
    final sel = i == _i;
    final done = _learned.contains(m.id);
    return KidPressable(
      onTap: () => _select(i),
      pressedScale: 0.94,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 102 * s,
        padding: EdgeInsets.all(4 * s),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF0),
          borderRadius: BorderRadius.circular(16 * s),
          border: Border.all(color: sel ? const Color(0xFFFFD447) : const Color(0xFFE9DCC0), width: sel ? 3.5 : 2),
          boxShadow: [
            if (sel) BoxShadow(color: const Color(0xFFFFE066).withOpacity(0.8), blurRadius: 14),
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 3)),
          ],
        ),
        child: Opacity(
          opacity: sel ? 1 : 0.85,
          child: Column(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12 * s),
                child: Stack(fit: StackFit.expand, children: [
                  Image.asset(m.art, fit: BoxFit.cover),
                  if (done)
                    PositionedDirectional(
                      top: 3 * s,
                      end: 3 * s,
                      child: Container(
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(Icons.check_circle_rounded, color: _green, size: 17 * s),
                      ),
                    ),
                ]),
              ),
            ),
            SizedBox(height: 3 * s),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(_t(context, m.title), maxLines: 1, style: kidBodyStyle(12.5 * s, color: const Color(0xFF3A2A1A), weight: FontWeight.w700)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _sheet(double s, Manner m, bool done, double bottomPad) {
    final rtl = _lang(context) == 'ar';
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFBF5E6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(34 * s)),
        border: Border.all(color: const Color(0xFFE9C46A), width: 2.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 18, offset: const Offset(0, -4))],
      ),
      child: Column(children: [
        SizedBox(height: 8 * s),
        Container(width: 54 * s, height: 6 * s, decoration: BoxDecoration(color: const Color(0xFFD9CDB2), borderRadius: BorderRadius.circular(6))),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16 * s, 4 * s, 16 * s, 16 * s + bottomPad),
            child: Column(children: [
              // title row
              Row(children: [
                SizedBox(width: 36 * s),
                Expanded(
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Image.asset('${_d}mn_medal.webp', width: 58 * s, height: 58 * s * 0.95),
                    SizedBox(width: 8 * s),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(_t(context, m.title), style: kidTitleStyle(30 * s, color: const Color(0xFF173B3A)).copyWith(shadows: const [])),
                      ),
                    ),
                  ]),
                ),
                KidPressable(
                  onTap: () {
                    _audio.playEventSound('cancelButton');
                    Navigator.of(context).maybePop();
                  },
                  child: Container(
                    width: 36 * s,
                    height: 36 * s,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFF8E6),
                      border: Border.all(color: const Color(0xFFE9C46A), width: 2),
                    ),
                    child: Icon(Icons.close_rounded, color: const Color(0xFF7A4A12), size: 22 * s),
                  ),
                ),
              ]),
              SizedBox(height: 8 * s),
              // scene
              FadeTransition(
                opacity: _pop,
                child: ScaleTransition(
                  scale: Tween(begin: 0.96, end: 1.0).animate(CurvedAnimation(parent: _pop, curve: Curves.easeOutBack)),
                  child: _scene(s, m),
                ),
              ),
              SizedBox(height: 6 * s),
              Transform.translate(
                offset: Offset(0, -26 * s),
                child: KidPressable(
                  onTap: () {
                    _audio.playEventSound('clickButton2');
                    speakManner(_tts, context, m);
                  },
                  pressedScale: 0.94,
                  child: Container(
                    height: 56 * s,
                    padding: EdgeInsets.symmetric(horizontal: 26 * s),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C9C92), _tealDeep]),
                      border: Border.all(color: const Color(0xFFE9C46A), width: 3),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.volume_up_rounded, color: Colors.white, size: 30 * s),
                      SizedBox(width: 10 * s),
                      Text(_u(context, 'listen'), style: kidBodyStyle(22 * s, color: Colors.white, weight: FontWeight.w700)),
                    ]),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, -16 * s),
                child: Column(children: [
                  Text(_t(context, m.rule),
                      textAlign: TextAlign.center,
                      textDirection: rtl ? TextDirection.rtl : null,
                      style: kidBodyStyle(19 * s, color: const Color(0xFF173B3A), weight: FontWeight.w700)),
                  SizedBox(height: 12 * s),
                  // bear task
                  SizedBox(
                    height: 92 * s,
                    child: Stack(clipBehavior: Clip.none, children: [
                      Positioned.fill(
                        left: 20 * s,
                        right: 20 * s,
                        child: Container(
                          padding: EdgeInsetsDirectional.only(start: 92 * s, end: 14 * s),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4D6),
                            borderRadius: BorderRadius.circular(20 * s),
                            border: Border.all(color: const Color(0xFFE9C46A), width: 2.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(_t(context, m.task),
                              textAlign: TextAlign.center,
                              style: kidBodyStyle(17 * s, color: const Color(0xFF5A3410), weight: FontWeight.w700)),
                        ),
                      ),
                      PositionedDirectional(
                        start: 22 * s,
                        bottom: 0,
                        child: AnimatedBuilder(
                          animation: _idle,
                          builder: (_, c) => Transform.rotate(angle: sin(_idle.value * 6 * pi) * 0.05, alignment: Alignment.bottomCenter, child: c),
                          child: Image.asset('${_d}mn_bear.webp', height: 104 * s, width: 104 * s / 1.46),
                        ),
                      ),
                    ]),
                  ),
                  SizedBox(height: 14 * s),
                  KidPressable(
                    onTap: _understood,
                    pressedScale: 0.95,
                    child: Container(
                      height: 62 * s,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C9C92), _tealDeep]),
                        border: Border.all(color: const Color(0xFFE9C46A), width: 3),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 4))],
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          width: 38 * s,
                          height: 38 * s,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                          child: Icon(Icons.check_rounded, color: _teal, size: 28 * s),
                        ),
                        SizedBox(width: 10 * s),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(_u(context, 'understood'), style: kidBodyStyle(24 * s, color: Colors.white, weight: FontWeight.w700)),
                          ),
                        ),
                      ]),
                    ),
                  ),
                  SizedBox(height: 10 * s),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(width: 60 * s, height: 2, color: const Color(0xFFE9C46A)),
                    for (int k = 0; k < 3; k++)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2 * s),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: done ? 1 : 0.3,
                          child: Image.asset('${_d}mm_star.webp', width: (k == 1 ? 40 : 30) * s, height: (k == 1 ? 40 : 30) * s),
                        ),
                      ),
                    Container(width: 60 * s, height: 2, color: const Color(0xFFE9C46A)),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  /// "Dire bonjour" gets the courtyard scene with the two children; the
  /// others use their illustration. Each shows a speech bubble.
  Widget _scene(double s, Manner m) {
    final bubble = _t(context, m.bubble);
    return AspectRatio(
      aspectRatio: 1.25,
      child: ShaderMask(
        shaderCallback: (r) => const RadialGradient(radius: 0.78, colors: [Colors.black, Colors.black, Colors.transparent], stops: [0, 0.82, 1]).createShader(r),
        blendMode: BlendMode.dstIn,
        child: LayoutBuilder(builder: (c, b) {
          final W = b.maxWidth, H = b.maxHeight;
          final bonjour = m.id == 'bonjour';
          return Stack(children: [
            Positioned.fill(child: Image.asset(bonjour ? '${_d}mn_courtyard.webp' : m.art, fit: BoxFit.cover)),
            if (bonjour) ...[
              Positioned(
                left: W * 0.04,
                bottom: -H * 0.02,
                height: H * 0.82,
                child: AnimatedBuilder(
                  animation: _idle,
                  builder: (_, ch) => Transform.translate(offset: Offset(0, sin(_idle.value * 4 * pi) * 3), child: ch),
                  child: Image.asset('${_d}mn_boy.webp', fit: BoxFit.contain),
                ),
              ),
              Positioned(
                right: W * 0.04,
                bottom: -H * 0.02,
                height: H * 0.74,
                child: AnimatedBuilder(
                  animation: _idle,
                  builder: (_, ch) => Transform.translate(offset: Offset(0, sin(_idle.value * 4 * pi + 1.5) * 3), child: ch),
                  child: Image.asset('${_d}mn_girl.webp', fit: BoxFit.contain),
                ),
              ),
            ],
            Positioned(
              left: W * 0.3,
              right: W * 0.18,
              top: H * 0.06,
              child: AnimatedBuilder(
                animation: _idle,
                builder: (_, ch) => Transform.translate(offset: Offset(0, sin(_idle.value * 2 * pi) * 2), child: ch),
                child: CustomPaint(
                  painter: _BubblePainter(),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(14 * s, 10 * s, 14 * s, 22 * s),
                    child: Text(bubble,
                        textAlign: TextAlign.center,
                        style: kidBodyStyle(19 * s, color: const Color(0xFF173B3A), weight: FontWeight.w700).copyWith(height: 1.15)),
                  ),
                ),
              ),
            ),
          ]);
        }),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height - 12), Radius.circular(size.height * 0.4));
    final tail = Path()
      ..moveTo(size.width * 0.18, size.height - 16)
      ..lineTo(size.width * 0.08, size.height)
      ..lineTo(size.width * 0.32, size.height - 14)
      ..close();
    final path = Path()..addRRect(r)..addPath(tail, Offset.zero);
    canvas.drawShadow(path, Colors.black, 4, false);
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFFDF6));
    canvas.drawPath(path, Paint()
      ..color = const Color(0xFF1F5B57)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
