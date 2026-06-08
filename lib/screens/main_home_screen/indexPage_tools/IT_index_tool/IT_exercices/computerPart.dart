// computer_parts_exercise.dart
// Route: IT_ComputerParts
//
// ╔══════════════════════════════════════════════════════╗
// ║  THREE-PHASE EXPERIENCE                             ║
// ║  Phase 1 — EXPLORE  : illustrated room scene        ║
// ║             tap glowing parts → pop-up card         ║
// ║             with animated educational content       ║
// ║  Phase 2 — QUIZ     : drag-label game (3 rounds)    ║
// ║  Phase 3 — WIN      : trophy + glossary             ║
// ╚══════════════════════════════════════════════════════╝
//
// • CustomPainter room (desk, monitor, keyboard, mouse,
//   CPU tower, speaker, printer, webcam, headphones,
//   posters, window, plant)
// • Robo mascot (CustomPainter, 4 moods)
// • Per-part animated teaching card (fun fact + how it works)
// • Particle burst on correct drop
// • Shake + red flash on wrong drop
// • Pulsing chip animation in label bank
// • Localized: EN / FR / AR  +  RTL Directionality
// • Rewards: XP + Stars via ExperienceManager

import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../XpSystem.dart';
import '../../../../../tools/audio_tool/Audio_Manager.dart';


// ─────────────────────────────────────────────────────────────────────────────
//  CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

const _kBlue   = Color(0xFF1565C0);
const _kPurple = Color(0xFF6A1B9A);
const _kGreen  = Color(0xFF2E7D32);
const _kRed    = Color(0xFFBF360C);
const _kTeal   = Color(0xFF00695C);
const _kIndigo = Color(0xFF4527A0);
const _kCyan   = Color(0xFF0277BD);
const _kLime   = Color(0xFF558B2F);

// ─────────────────────────────────────────────────────────────────────────────
//  DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────

class _Part {
  final String id, emoji;
  final Color color;
  final Map<String,String> label, funFact, howWorks;
  // hotspot in the room scene (fractional coords 0..1)
  final Offset hotspot;
  const _Part({
    required this.id, required this.emoji, required this.color,
    required this.label, required this.funFact, required this.howWorks,
    required this.hotspot,
  });
}

const _allParts = <_Part>[
  _Part(
    id:'monitor', emoji:'🖥️', color:_kBlue, hotspot: Offset(.50,.30),
    label:     {'en':'Monitor',         'fr':'Écran',             'ar':'الشاشة'},
    funFact:   {'en':'The first monitor was as big as a fridge! 🧊',
      'fr':'Le premier écran était aussi grand qu\'un frigo ! 🧊',
      'ar':'كانت أول شاشة بحجم الثلاجة! 🧊'},
    howWorks:  {'en':'It shows pictures and videos sent by the CPU — like a magic window! 🪟',
      'fr':'Il affiche les images et vidéos envoyées par le CPU — comme une fenêtre magique ! 🪟',
      'ar':'تعرض الصور والفيديو المُرسلة من المعالج — مثل نافذة سحرية! 🪟'},
  ),
  _Part(
    id:'keyboard', emoji:'⌨️', color:_kPurple, hotspot: Offset(.48,.60),
    label:     {'en':'Keyboard',        'fr':'Clavier',           'ar':'لوحة المفاتيح'},
    funFact:   {'en':'A keyboard has about 104 keys — that\'s more than a piano! 🎹',
      'fr':'Un clavier a environ 104 touches — plus qu\'un piano ! 🎹',
      'ar':'لوحة المفاتيح بها حوالي 104 مفتاحاً — أكثر من البيانو! 🎹'},
    howWorks:  {'en':'Each key press sends an electric signal to the computer — like pressing a doorbell! 🔔',
      'fr':'Chaque touche envoie un signal électrique — comme appuyer sur une sonnette ! 🔔',
      'ar':'كل ضغطة على مفتاح ترسل إشارة كهربائية — مثل ضغط جرس الباب! 🔔'},
  ),
  _Part(
    id:'mouse', emoji:'🖱️', color:_kGreen, hotspot: Offset(.74,.60),
    label:     {'en':'Mouse',           'fr':'Souris',            'ar':'الفأرة'},
    funFact:   {'en':'The first mouse was made of wood in 1964! 🪵',
      'fr':'La première souris était en bois en 1964 ! 🪵',
      'ar':'كانت أول فأرة مصنوعة من الخشب عام 1964! 🪵'},
    howWorks:  {'en':'It tracks your hand movement and moves the cursor — like a magic wand! 🪄',
      'fr':'Elle suit le mouvement de ta main et déplace le curseur — comme une baguette magique ! 🪄',
      'ar':'تتبع حركة يدك وتحرك المؤشر — مثل عصا سحرية! 🪄'},
  ),
  _Part(
    id:'cpu', emoji:'🗄️', color:_kRed, hotspot: Offset(.18,.45),
    label:     {'en':'CPU Tower',       'fr':'Tour CPU',          'ar':'برج المعالج'},
    funFact:   {'en':'The CPU does billions of calculations every second! 🤯',
      'fr':'Le CPU fait des milliards de calculs par seconde ! 🤯',
      'ar':'يجري المعالج مليارات العمليات الحسابية في الثانية! 🤯'},
    howWorks:  {'en':'It\'s the brain of the computer — it thinks and makes decisions for everything! 🧠',
      'fr':'C\'est le cerveau de l\'ordinateur — il pense et décide de tout ! 🧠',
      'ar':'إنه عقل الحاسوب — يفكر ويتخذ القرارات لكل شيء! 🧠'},
  ),
  _Part(
    id:'speaker', emoji:'🔊', color:_kTeal, hotspot: Offset(.83,.42),
    label:     {'en':'Speaker',         'fr':'Haut-parleur',     'ar':'مكبر الصوت'},
    funFact:   {'en':'Speakers vibrate the air so fast you can\'t even see it! 💨',
      'fr':'Les haut-parleurs font vibrer l\'air si vite qu\'on ne le voit pas ! 💨',
      'ar':'تُذبذب مكبرات الصوت الهواء بسرعة لا ترى! 💨'},
    howWorks:  {'en':'Electric signals make a tiny magnet move super fast — that makes sound waves! 🌊',
      'fr':'Des signaux électriques font bouger un aimant très vite — ça crée des ondes sonores ! 🌊',
      'ar':'إشارات كهربائية تحرك مغناطيساً صغيراً بسرعة — هذا يصنع موجات الصوت! 🌊'},
  ),
  _Part(
    id:'printer', emoji:'🖨️', color:_kIndigo, hotspot: Offset(.12,.70),
    label:     {'en':'Printer',         'fr':'Imprimante',       'ar':'الطابعة'},
    funFact:   {'en':'Color printers mix only 4 colors to make millions of shades! 🎨',
      'fr':'Les imprimantes couleur mélangent 4 couleurs pour faire des millions de nuances ! 🎨',
      'ar':'الطابعات الملونة تخلط 4 ألوان فقط لتصنع ملايين الدرجات! 🎨'},
    howWorks:  {'en':'It sprays tiny drops of ink on paper — smaller than a raindrop! 💧',
      'fr':'Elle projette de minuscules gouttes d\'encre sur du papier — plus petites qu\'une goutte de pluie ! 💧',
      'ar':'ترش قطرات حبر صغيرة جداً على الورق — أصغر من قطرة المطر! 💧'},
  ),
  _Part(
    id:'webcam', emoji:'📷', color:_kCyan, hotspot: Offset(.50,.15),
    label:     {'en':'Webcam',          'fr':'Webcam',           'ar':'الكاميرا'},
    funFact:   {'en':'A webcam takes 30 photos every single second! 📸📸📸',
      'fr':'Une webcam prend 30 photos par seconde ! 📸📸📸',
      'ar':'الكاميرا تلتقط 30 صورة في كل ثانية! 📸📸📸'},
    howWorks:  {'en':'Millions of tiny light sensors capture each frame — like thousands of eyes! 👁️',
      'fr':'Des millions de capteurs de lumière capturent chaque image — comme des milliers d\'yeux ! 👁️',
      'ar':'ملايين من أجهزة استشعار الضوء الصغيرة تلتقط كل إطار — مثل آلاف العيون! 👁️'},
  ),
  _Part(
    id:'headphones', emoji:'🎧', color:_kLime, hotspot: Offset(.82,.20),
    label:     {'en':'Headphones',      'fr':'Casque',           'ar':'السماعات'},
    funFact:   {'en':'Headphones were invented to let telephone operators work hands-free! 📞',
      'fr':'Le casque a été inventé pour les opérateurs téléphoniques ! 📞',
      'ar':'اخترعت السماعات لمشغلي الهاتف للعمل بأيدٍ حرة! 📞'},
    howWorks:  {'en':'Tiny speakers sit right next to your ears — the sound travels almost zero distance! 👂',
      'fr':'De minuscules haut-parleurs sont placés près de tes oreilles ! 👂',
      'ar':'مكبرات صوت صغيرة تجلس بجوار أذنيك — الصوت يقطع مسافة تقريباً صفر! 👂'},
  ),
];

class _Round {
  final List<String> ids; final int stars, xp;
  final Map<String,String> name;
  const _Round({required this.ids, required this.stars, required this.xp, required this.name});
}
const _rounds = [
  _Round(ids:['monitor','keyboard','mouse'],                                          stars:1,xp:20, name:{'en':'Beginner 🌱','fr':'Débutant 🌱','ar':'مبتدئ 🌱'}),
  _Round(ids:['monitor','keyboard','mouse','cpu','speaker'],                          stars:2,xp:35, name:{'en':'Explorer 🚀','fr':'Explorateur 🚀','ar':'مستكشف 🚀'}),
  _Round(ids:['monitor','keyboard','mouse','cpu','speaker','printer','webcam','headphones'], stars:3,xp:60, name:{'en':'Expert 🏆','fr':'Expert 🏆','ar':'خبير 🏆'}),
];

enum _Mood { idle, happy, sad, cheer }
enum _Phase { explore, quiz, win }

// ─────────────────────────────────────────────────────────────────────────────
//  MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class ComputerPartsExercise extends StatefulWidget {
  const ComputerPartsExercise({super.key});
  @override State<ComputerPartsExercise> createState() => _CPState();
}

class _CPState extends State<ComputerPartsExercise> with TickerProviderStateMixin {

  _Phase _phase = _Phase.explore;

  // ── explore phase ─────────────────────────────────────────────────────────
  final Set<String> _discovered = {};
  _Part? _openCard;                    // currently shown info card
  late AnimationController _cardCtrl;
  late Animation<double> _cardScale, _cardFade;

  // ── quiz phase ────────────────────────────────────────────────────────────
  int _ri = 0;
  late List<_Part> _rParts, _bank;
  final Map<String,String?> _placed = {};
  final Set<String> _ok = {}, _bad = {};
  int _mistakes = 0, _totStars = 0, _totXp = 0;
  bool _showResult = false;
  String? _hintId;

  // ── mascot ────────────────────────────────────────────────────────────────
  _Mood _mood = _Mood.idle;
  String _speech = '';

  // ── animations ────────────────────────────────────────────────────────────
  late AnimationController _bounceCtrl, _shakeCtrl, _scaleCtrl, _pulseCtrl, _glowCtrl;
  late Animation<double>   _bounceAnim, _shakeAnim, _scaleAnim, _pulseAnim, _glowAnim;
  late ConfettiController  _confetti;
  final List<String> _bursts = [];
  final _rng = Random();

  String get _lang { final c = Localizations.localeOf(context).languageCode; return ['ar','fr'].contains(c) ? c : 'en'; }
  bool get _rtl => _lang == 'ar';

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _cardCtrl  = AnimationController(vsync:this, duration:const Duration(milliseconds:350));
    _cardScale = Tween(begin:.7,end:1.0).animate(CurvedAnimation(parent:_cardCtrl, curve:Curves.elasticOut));
    _cardFade  = Tween(begin:0.0,end:1.0).animate(CurvedAnimation(parent:_cardCtrl, curve:Curves.easeOut));

    _bounceCtrl = AnimationController(vsync:this, duration:const Duration(milliseconds:700));
    _bounceAnim = Tween(begin:0.0,end:-18.0).animate(CurvedAnimation(parent:_bounceCtrl, curve:Curves.elasticOut));

    _shakeCtrl = AnimationController(vsync:this, duration:const Duration(milliseconds:450));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween:Tween(begin:0.0, end:-12.0), weight:1),
      TweenSequenceItem(tween:Tween(begin:-12.0,end:12.0), weight:2),
      TweenSequenceItem(tween:Tween(begin:12.0, end:-9.0), weight:2),
      TweenSequenceItem(tween:Tween(begin:-9.0, end:9.0),  weight:2),
      TweenSequenceItem(tween:Tween(begin:9.0,  end:0.0),  weight:1),
    ]).animate(_shakeCtrl);

    _scaleCtrl = AnimationController(vsync:this, duration:const Duration(milliseconds:350));
    _scaleAnim = Tween(begin:1.0,end:1.3).animate(CurvedAnimation(parent:_scaleCtrl, curve:Curves.elasticOut));

    _pulseCtrl = AnimationController(vsync:this, duration:const Duration(milliseconds:900))..repeat(reverse:true);
    _pulseAnim = Tween(begin:1.0,end:1.07).animate(CurvedAnimation(parent:_pulseCtrl, curve:Curves.easeInOut));

    _glowCtrl = AnimationController(vsync:this, duration:const Duration(milliseconds:1200))..repeat(reverse:true);
    _glowAnim = Tween(begin:.4,end:1.0).animate(CurvedAnimation(parent:_glowCtrl, curve:Curves.easeInOut));

    _confetti = ConfettiController(duration:const Duration(seconds:3));

    _initRound();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setMood(_Mood.idle, _greet));
  }

  String get _greet => {'en':'Welcome to the Computer Lab! 🏫\nTap each part to learn about it!',
    'fr':'Bienvenue au labo informatique ! 🏫\nTape sur chaque pièce pour l\'apprendre !',
    'ar':'مرحباً في مختبر الحاسوب! 🏫\nاضغط على كل جزء لتتعلم عنه!'}[_lang]!;

  void _initRound() {
    final r = _rounds[_ri];
    _rParts = _allParts.where((p)=>r.ids.contains(p.id)).toList();
    _bank   = List.from(_rParts)..shuffle(_rng);
    _placed.clear(); _ok.clear(); _bad.clear();
    _mistakes=0; _showResult=false; _hintId=null;
  }

  @override void dispose() {
    _cardCtrl.dispose(); _bounceCtrl.dispose(); _shakeCtrl.dispose();
    _scaleCtrl.dispose(); _pulseCtrl.dispose(); _glowCtrl.dispose();
    _confetti.dispose();
    super.dispose();
  }

  // ── mascot ────────────────────────────────────────────────────────────────
  void _setMood(_Mood m, String s) {
    setState(() { _mood=m; _speech=s; });
    if (m==_Mood.happy||m==_Mood.cheer) _bounceCtrl.forward(from:0);
  }

  // ── explore phase logic ───────────────────────────────────────────────────
  void _tapPart(_Part p) {
    final audio = Provider.of<AudioManager>(context, listen:false);
    audio.playSfx('assets/audios/sound_effects/correct_anwser.mp3');
    setState(() { _discovered.add(p.id); _openCard=p; });
    _cardCtrl.forward(from:0);
    _setMood(_Mood.happy, p.funFact[_lang]!);
  }

  void _closeCard() {
    setState(() => _openCard = null);
    _cardCtrl.reverse();
  }

  void _startQuiz() {
    final l = _lang;
    if (_discovered.length < 3) {
      _setMood(_Mood.sad, {'en':'Explore at least 3 parts first! 🔍','fr':'Explore au moins 3 pièces d\'abord ! 🔍','ar':'استكشف 3 أجزاء على الأقل أولاً! 🔍'}[l]!);
      return;
    }
    setState(() => _phase = _Phase.quiz);
    _setMood(_Mood.idle, {'en':'Now let\'s test what you know! 🎯','fr':'Maintenant testons ce que tu sais ! 🎯','ar':'الآن لنختبر ما تعلمته! 🎯'}[l]!);
  }

  // ── quiz logic ────────────────────────────────────────────────────────────
  void _drop(String slotId, String labelId) {
    if (_ok.contains(slotId)) return;
    final audio = Provider.of<AudioManager>(context, listen:false);
    setState(() => _placed[slotId] = labelId);
    if (slotId == labelId) {
      _ok.add(slotId);
      audio.playSfx('assets/audios/sound_effects/correct_anwser.mp3');
      _scaleCtrl.forward(from:0).then((_)=>_scaleCtrl.reverse());
      final ws = {'en':['Awesome! 🎉','Perfect! ⭐','You got it! 🚀','Brilliant! 💡'],
        'fr':['Super ! 🎉','Parfait ! ⭐','Excellent ! 🚀','Génial ! 💡'],
        'ar':['رائع! 🎉','ممتاز! ⭐','أحسنت! 🚀','بارع! 💡']}[_lang]!;
      _setMood(_Mood.happy, ws[_rng.nextInt(ws.length)]);
      setState(() => _bursts.add(slotId));
      Future.delayed(const Duration(milliseconds:900), (){ if(mounted) setState(()=>_bursts.remove(slotId)); });
      if (_ok.length == _rParts.length) Future.delayed(const Duration(milliseconds:600), _roundDone);
    } else {
      _mistakes++;
      audio.playSfx('assets/audios/sound_effects/wrong_answer.mp3');
      _setMood(_Mood.sad, {'en':'Try again! 💪','fr':'Réessaie ! 💪','ar':'حاول مجدداً! 💪'}[_lang]!);
      setState(() => _bad.add(slotId));
      _shakeCtrl.forward(from:0);
      Future.delayed(const Duration(milliseconds:680), (){
        if(!mounted) return;
        setState((){ _bad.remove(slotId); _placed.remove(slotId); });
      });
    }
  }

  void _roundDone() {
    final xpMgr = Provider.of<ExperienceManager>(context, listen:false);
    final audio  = Provider.of<AudioManager>(context, listen:false);
    final r = _rounds[_ri];
    final s = _mistakes<=1 ? r.stars : max(1,r.stars-1);
    final x = _mistakes<=1 ? r.xp   : (r.xp*.65).round();
    _totStars+=s; _totXp+=x;
    xpMgr.addStarBanner(context, s);
    xpMgr.addXP(x, context:context);
    audio.playSfx('assets/audios/UI_Audio/SFX_Audio/victory1_SFX.mp3');
    _confetti.play();
    _setMood(_Mood.cheer, {'en':'Amazing! Round done! 🏆','fr':'Incroyable ! Terminé ! 🏆','ar':'مذهل! اكتملت الجولة! 🏆'}[_lang]!);
    setState(() => _showResult=true);
  }

  void _next() {
    if (_ri < _rounds.length-1) {
      setState((){ _ri++; _initRound(); });
      _setMood(_Mood.idle, {'en':'Ready for round ${_ri+1}? 🚀','fr':'Prêt pour le tour ${_ri+1} ? 🚀','ar':'جاهز للجولة ${_ri+1}؟ 🚀'}[_lang]!);
    } else {
      setState(() => _phase=_Phase.win);
      _confetti.play();
      _setMood(_Mood.cheer, {'en':'You\'re a Computer Champion! 🏆','fr':'Tu es champion de l\'informatique ! 🏆','ar':'أنت بطل الحاسوب! 🏆'}[_lang]!);
    }
  }

  void _restart() => setState((){
    _phase=_Phase.explore; _discovered.clear(); _openCard=null;
    _ri=0; _totStars=0; _totXp=0;
    _initRound();
    WidgetsBinding.instance.addPostFrameCallback((_)=>_setMood(_Mood.idle, _greet));
  });

  // ─────────────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext ctx) => Directionality(
    textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
    child: Scaffold(
      body: Stack(children: [
        _bg(),
        SafeArea(child: switch(_phase){
          _Phase.explore => _buildExplore(),
          _Phase.quiz    => _showResult ? _buildResult() : _buildQuiz(),
          _Phase.win     => _buildWin(),
        }),
        _confettiWidget(),
      ]),
    ),
  );

  // ── background ────────────────────────────────────────────────────────────
  Widget _bg() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF0A0E1A), Color(0xFF0B2137), Color(0xFF071E3A)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
    ),
    child: CustomPaint(painter: _StarPainter(), child: const SizedBox.expand()),
  );

  Widget _confettiWidget() => Positioned.fill(child: IgnorePointer(child: Align(
    alignment: Alignment.topCenter,
    child: ConfettiWidget(
      confettiController: _confetti,
      blastDirectionality: BlastDirectionality.explosive,
      emissionFrequency:.07, numberOfParticles:30, gravity:.26,
      colors: const [Color(0xFFFFD700),Color(0xFF00E5FF),Color(0xFFFF4081),Color(0xFF69F0AE),Color(0xFFE040FB)],
    ),
  )));

  // ═════════════════════════════════════════════════════════════════════════
  //  PHASE 1 — EXPLORE
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildExplore() {
    final l = _lang;
    final discovered = _discovered.length;
    final total = _allParts.length;

    return Column(children: [
      // ── top bar ──────────────────────────────────────────────────────────
      _appBar(
        title: {'en':'🏫 Computer Lab','fr':'🏫 Labo Info','ar':'🏫 مختبر الحاسوب'}[l]!,
        trailing: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal:10,vertical:4),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(.4)),
            ),
            child: Text('$discovered / $total 🔍',
                style: const TextStyle(color:Colors.amber,fontSize:13,fontWeight:FontWeight.bold)),
          ),
        ]),
      ),

      const SizedBox(height:6),

      // ── mascot + speech ───────────────────────────────────────────────────
      _mascotRow(),

      const SizedBox(height:8),

      // ── room scene ────────────────────────────────────────────────────────
      Expanded(
        child: Stack(children: [
          // Room painting
          Positioned.fill(child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: CustomPaint(painter: _RoomPainter()),
          )),

          // Hotspot buttons
          LayoutBuilder(builder: (ctx, constraints) {
            final rw = constraints.maxWidth;
            final rh = constraints.maxHeight;
            return Stack(children: _allParts.map((p) => Positioned(
              left: p.hotspot.dx * rw - 22,
              top:  p.hotspot.dy * rh - 22,
              child: GestureDetector(
                onTap: () => _tapPart(p),
                child: AnimatedBuilder(
                  animation: _glowAnim,
                  builder: (_,__) {
                    final done = _discovered.contains(p.id);
                    return Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done ? p.color.withOpacity(.7) : p.color.withOpacity(.3*_glowAnim.value),
                        border: Border.all(color: done ? Colors.white : p.color.withOpacity(_glowAnim.value), width: done?2.5:2),
                        boxShadow: done ? [] : [BoxShadow(color:p.color.withOpacity(.5*_glowAnim.value), blurRadius:12, spreadRadius:2)],
                      ),
                      child: Center(child: Text(p.emoji, style:const TextStyle(fontSize:20))),
                    );
                  },
                ),
              ),
            )).toList());
          }),

          // Info card overlay
          if (_openCard != null) _infoCard(_openCard!),
        ]),
      ),

      const SizedBox(height:12),

      // ── progress + start quiz ─────────────────────────────────────────────
      Padding(
        padding: const EdgeInsets.symmetric(horizontal:16),
        child: Column(children: [
          // discovery progress
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: discovered/total,
              minHeight: 8,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation(Colors.amber),
            ),
          ),
          const SizedBox(height:10),
          SizedBox(width:double.infinity, child: ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text({'en':discovered>=3?'Start Quiz! 🎯':'Discover ${ 3-discovered} more parts...','fr':discovered>=3?'Commencer le quiz ! 🎯':'Découvris encore ${3-discovered} pièces...','ar':discovered>=3?'ابدأ الاختبار! 🎯':'اكتشف ${3-discovered} أجزاء أخرى...'}[l]!),
            onPressed: discovered>=3 ? _startQuiz : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: discovered>=3 ? Colors.amber : Colors.white24,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical:14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(fontSize:15,fontWeight:FontWeight.bold),
            ),
          )),
        ]),
      ),
      const SizedBox(height:14),
    ]);
  }


  // ── info card (appears over room on tap) ──────────────────────────────────
  Widget _infoCard(_Part p) {
    final l = _lang;
    return Positioned.fill(
      child: GestureDetector(
        onTap: _closeCard,
        child: Container(
          color: Colors.black.withOpacity(.6),
          child: Center(
            child: AnimatedBuilder(
              animation: _cardCtrl,
              builder:(_,__) => Opacity(
                opacity: _cardFade.value,
                child: Transform.scale(
                  scale: _cardScale.value,
                  child: GestureDetector(
                    onTap: (){}, // prevent bubble-up close
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1E32),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: p.color, width: 2.5),
                        boxShadow: [BoxShadow(color:p.color.withOpacity(.35), blurRadius:24)],
                      ),
                      child: Column(mainAxisSize:MainAxisSize.min, children:[

                        // header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical:18, horizontal:20),
                          decoration: BoxDecoration(
                            color: p.color.withOpacity(.18),
                            borderRadius: const BorderRadius.only(topLeft:Radius.circular(26), topRight:Radius.circular(26)),
                          ),
                          child: Row(children:[
                            Text(p.emoji, style:const TextStyle(fontSize:42)),
                            const SizedBox(width:14),
                            Expanded(child: Text(p.label[l]!,
                                style:const TextStyle(color:Colors.white, fontSize:22, fontWeight:FontWeight.bold))),
                            GestureDetector(onTap:_closeCard,
                                child: const Icon(Icons.close_rounded, color:Colors.white54, size:24)),
                          ]),
                        ),

                        // fun fact
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20,16,20,8),
                          child: _infoSection(
                            icon:'🤩', title:{'en':'Fun fact!','fr':'Le saviez-vous ?','ar':'حقيقة مثيرة!'}[l]!,
                            text: p.funFact[l]!, color: Colors.amber,
                          ),
                        ),

                        // how it works
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20,4,20,20),
                          child: _infoSection(
                            icon:'⚙️', title:{'en':'How it works','fr':'Comment ça marche','ar':'كيف يعمل'}[l]!,
                            text: p.howWorks[l]!, color: p.color,
                          ),
                        ),

                        // "Got it!" button
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20,0,20,20),
                          child: SizedBox(width:double.infinity, child: ElevatedButton(
                            onPressed: _closeCard,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: p.color,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical:14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              textStyle: const TextStyle(fontSize:15, fontWeight:FontWeight.bold),
                            ),
                            child: Text({'en':'Got it! 👍','fr':'Compris ! 👍','ar':'فهمت! 👍'}[l]!),
                          )),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoSection({required String icon, required String title, required String text, required Color color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color:color.withOpacity(.3)),
      ),
      child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
        Row(children:[
          Text(icon, style:const TextStyle(fontSize:18)),
          const SizedBox(width:8),
          Text(title, style:TextStyle(color:color, fontSize:13, fontWeight:FontWeight.bold)),
        ]),
        const SizedBox(height:8),
        Text(text, style:const TextStyle(color:Colors.white, fontSize:14, height:1.5)),
      ]),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  PHASE 2 — QUIZ
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildQuiz() => Column(children: [
    _appBar(title: _rounds[_ri].name[_lang]!, trailing: _roundDots()),
    const SizedBox(height:6),
    _mascotRow(),
    const SizedBox(height:8),
    _progressBar(),
    const SizedBox(height:10),
    Expanded(child: _dropGrid()),
    const SizedBox(height:10),
    _bankWidget(),
    const SizedBox(height:14),
  ]);

  Widget _roundDots() => Row(children:[
    ...List.generate(_rounds.length,(i) => AnimatedContainer(
      duration:const Duration(milliseconds:300),
      margin:const EdgeInsets.symmetric(horizontal:3),
      width: i==_ri?22:10, height:10,
      decoration:BoxDecoration(borderRadius:BorderRadius.circular(5),
          color: i<_ri ? Colors.greenAccent : i==_ri ? Colors.amber : Colors.white24),
    )),
    const SizedBox(width:8),
    AnimatedContainer(
      duration:const Duration(milliseconds:200),
      padding:const EdgeInsets.symmetric(horizontal:8,vertical:4),
      decoration:BoxDecoration(color:_mistakes>0?Colors.redAccent.withOpacity(.2):Colors.transparent, borderRadius:BorderRadius.circular(10)),
      child:Row(children:[
        Icon(Icons.close, color:_mistakes>0?Colors.redAccent:Colors.white30, size:14),
        Text(' $_mistakes', style:TextStyle(color:_mistakes>0?Colors.redAccent:Colors.white30, fontSize:13,fontWeight:FontWeight.bold)),
      ]),
    ),
  ]);

  Widget _progressBar() {
    final done=_ok.length, total=_rParts.length;
    return Padding(padding:const EdgeInsets.symmetric(horizontal:16), child:Column(children:[
      Row(children:[
        Text('$done', style:const TextStyle(color:Colors.amber,fontSize:20,fontWeight:FontWeight.bold)),
        Text(' / $total', style:const TextStyle(color:Colors.white54,fontSize:14)),
        const Spacer(),
        Text({'en':'Drag label → box','fr':'Étiquette → case','ar':'اسحب البطاقة → المربع'}[_lang]!,
            style:const TextStyle(color:Colors.white38,fontSize:12,fontStyle:FontStyle.italic)),
      ]),
      const SizedBox(height:6),
      ClipRRect(borderRadius:BorderRadius.circular(10), child:TweenAnimationBuilder<double>(
        tween:Tween(begin:0,end:done/total),
        duration:const Duration(milliseconds:400),
        builder:(_,v,__)=>LinearProgressIndicator(value:v, minHeight:10, backgroundColor:Colors.white10,
            valueColor:AlwaysStoppedAnimation(v>=1.0?Colors.greenAccent:Colors.amber)),
      )),
    ]));
  }

  Widget _dropGrid() {
    final cols = _rParts.length<=3?3:_rParts.length<=6?3:4;
    return GridView.builder(
      padding:const EdgeInsets.symmetric(horizontal:14),
      gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:cols,mainAxisSpacing:10,crossAxisSpacing:10,childAspectRatio:.88),
      itemCount:_rParts.length,
      itemBuilder:(_,i)=>_slot(_rParts[i]),
    );
  }

  Widget _slot(_Part part) {
    final isOk=_ok.contains(part.id), isBad=_bad.contains(part.id), isHint=_hintId==part.id;
    return AnimatedBuilder(
      animation:_shakeAnim,
      builder:(_,child)=>Transform.translate(offset:Offset(isBad?_shakeAnim.value:0,0), child:child),
      child: DragTarget<String>(
        onWillAcceptWithDetails:(_)=>!isOk,
        onAcceptWithDetails:(d)=>_drop(part.id,d.data),
        builder:(ctx,cand,_){
          final hov=cand.isNotEmpty;
          return GestureDetector(
            onLongPress:()=>setState(()=>_hintId=isHint?null:part.id),
            child:AnimatedContainer(
              duration:const Duration(milliseconds:200),
              decoration:BoxDecoration(
                borderRadius:BorderRadius.circular(20),
                color: isOk?part.color.withOpacity(.28):isBad?Colors.red.withOpacity(.22):hov?part.color.withOpacity(.22):Colors.white.withOpacity(.07),
                border:Border.all(width:isOk||isBad||hov?2.5:1.5,
                    color:isOk?Colors.greenAccent:isBad?Colors.redAccent:hov?part.color:Colors.white.withOpacity(.18)),
                boxShadow:isOk?[BoxShadow(color:part.color.withOpacity(.45),blurRadius:14,spreadRadius:1)]:hov?[BoxShadow(color:part.color.withOpacity(.3),blurRadius:10)]:null,
              ),
              child:Stack(children:[
                Center(child:isHint?_hintOverlay(part):_slotBody(part,isOk,isBad)),
                if (_bursts.contains(part.id)) Positioned.fill(child:IgnorePointer(child:_Burst(color:part.color))),
                if (!isOk&&!isHint) Positioned(top:6,right:6,child:Icon(Icons.touch_app,size:12,color:Colors.white.withOpacity(.25))),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _slotBody(_Part p, bool ok, bool bad) => Column(mainAxisAlignment:MainAxisAlignment.center, children:[
    AnimatedBuilder(animation:_scaleAnim, builder:(_,__)=>Transform.scale(
        scale:ok&&_scaleCtrl.isAnimating?_scaleAnim.value:1.0,
        child:Text(p.emoji,style:const TextStyle(fontSize:36)))),
    const SizedBox(height:6),
    AnimatedSwitcher(duration:const Duration(milliseconds:300), child:
    ok  ? _okBadge(p) :
    bad ? _badBadge() :
    _emptyBadge()),
  ]);

  Widget _okBadge(_Part p) => Container(key:const ValueKey('ok'),
      margin:const EdgeInsets.symmetric(horizontal:4),
      padding:const EdgeInsets.symmetric(horizontal:6,vertical:3),
      decoration:BoxDecoration(color:Colors.greenAccent.withOpacity(.18),borderRadius:BorderRadius.circular(8),border:Border.all(color:Colors.greenAccent.withOpacity(.5))),
      child:Row(mainAxisSize:MainAxisSize.min,children:[
        const Icon(Icons.check_circle,color:Colors.greenAccent,size:12),
        const SizedBox(width:3),
        Flexible(child:Text(p.label[_lang]!,style:const TextStyle(color:Colors.greenAccent,fontSize:11,fontWeight:FontWeight.bold),overflow:TextOverflow.ellipsis)),
      ]));

  Widget _badBadge() => Container(key:const ValueKey('bad'),
      padding:const EdgeInsets.symmetric(horizontal:8,vertical:3),
      decoration:BoxDecoration(color:Colors.redAccent.withOpacity(.2),borderRadius:BorderRadius.circular(8)),
      child:const Icon(Icons.close,color:Colors.redAccent,size:14));

  Widget _emptyBadge() => Container(key:const ValueKey('empty'),
      margin:const EdgeInsets.symmetric(horizontal:4),
      padding:const EdgeInsets.symmetric(horizontal:8,vertical:3),
      decoration:BoxDecoration(borderRadius:BorderRadius.circular(8),border:Border.all(color:Colors.white.withOpacity(.18))),
      child:Text('— ? —',style:TextStyle(color:Colors.white.withOpacity(.3),fontSize:11)));

  Widget _hintOverlay(_Part p) => GestureDetector(onTap:()=>setState(()=>_hintId=null),
      child:Container(
        margin:const EdgeInsets.all(5),
        padding:const EdgeInsets.all(8),
        decoration:BoxDecoration(color:Colors.black.withOpacity(.92),borderRadius:BorderRadius.circular(14),border:Border.all(color:p.color.withOpacity(.7),width:1.5)),
        child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
          const Icon(Icons.lightbulb,color:Colors.amber,size:18),
          const SizedBox(height:4),
          Text(p.howWorks[_lang]!,style:const TextStyle(color:Colors.white,fontSize:9,fontStyle:FontStyle.italic),textAlign:TextAlign.center),
          const SizedBox(height:5),
          Text(p.label[_lang]!,style:TextStyle(color:p.color,fontSize:13,fontWeight:FontWeight.bold)),
        ]),
      ));

  Widget _bankWidget() {
    final rem = _bank.where((p)=>!_ok.contains(p.id)).toList();
    return Container(
      margin:const EdgeInsets.symmetric(horizontal:14),
      padding:const EdgeInsets.fromLTRB(12,8,12,12),
      decoration:BoxDecoration(color:Colors.white.withOpacity(.05),borderRadius:BorderRadius.circular(22),border:Border.all(color:Colors.white.withOpacity(.1))),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Padding(padding:const EdgeInsets.only(bottom:8),child:Row(children:[
          const Icon(Icons.drag_indicator,color:Colors.white38,size:16),
          const SizedBox(width:6),
          Text({'en':'Drag a label to its matching box','fr':'Fais glisser vers la case','ar':'اسحب البطاقة إلى المربع'}[_lang]!,
              style:const TextStyle(color:Colors.white38,fontSize:12)),
        ])),
        rem.isEmpty
            ? Center(child:Text({'en':'✅ All placed!','fr':'✅ Tout placé !','ar':'✅ تم وضع الكل!'}[_lang]!,
            style:const TextStyle(color:Colors.greenAccent,fontSize:13,fontWeight:FontWeight.bold)))
            : Wrap(spacing:8,runSpacing:8,children:rem.map(_draggable).toList()),
      ]),
    );
  }

  Widget _draggable(_Part p) => Draggable<String>(
    data:p.id,
    feedback:Material(color:Colors.transparent,child:Transform.scale(scale:1.15,child:_chip(p,true))),
    childWhenDragging:Opacity(opacity:.25,child:_chip(p,false)),
    child:AnimatedBuilder(animation:_pulseAnim,builder:(_,__)=>Transform.scale(scale:_pulseAnim.value,child:_chip(p,false))),
  );

  Widget _chip(_Part p, bool drag) => AnimatedContainer(
    duration:const Duration(milliseconds:150),
    padding:const EdgeInsets.symmetric(horizontal:12,vertical:8),
    decoration:BoxDecoration(
      color:drag?p.color:p.color.withOpacity(.2),
      borderRadius:BorderRadius.circular(30),
      border:Border.all(color:drag?Colors.white:p.color,width:drag?2:1.5),
      boxShadow:drag?[BoxShadow(color:p.color.withOpacity(.55),blurRadius:14)]:[],
    ),
    child:Row(mainAxisSize:MainAxisSize.min,children:[
      Text(p.emoji,style:const TextStyle(fontSize:17)),
      const SizedBox(width:6),
      Text(p.label[_lang]!,style:TextStyle(color:drag?Colors.white:Colors.white.withOpacity(.9),fontSize:13,fontWeight:FontWeight.w700)),
    ]),
  );

  // ─────────────────────────────────────────────────────────────────────────
  //  RESULT SCREEN
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildResult() {
    final l=_lang; final r=_rounds[_ri]; final isLast=_ri==_rounds.length-1;
    final stars=_mistakes<=1?r.stars:max(1,r.stars-1);
    return Center(child:SingleChildScrollView(child:Container(
      margin:const EdgeInsets.all(20),
      padding:const EdgeInsets.all(28),
      decoration:BoxDecoration(color:const Color(0xFF0B1A2E).withOpacity(.98),
          borderRadius:BorderRadius.circular(30),border:Border.all(color:Colors.amber.withOpacity(.55),width:2)),
      child:Column(mainAxisSize:MainAxisSize.min,children:[
        _RoboFace(mood:_Mood.cheer, size:80),
        const SizedBox(height:12),
        Text({'en':'Round Complete! 🎉','fr':'Tour terminé ! 🎉','ar':'اكتملت الجولة! 🎉'}[l]!,
            style:const TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.bold),textAlign:TextAlign.center),
        const SizedBox(height:20),
        Row(mainAxisAlignment:MainAxisAlignment.center,children:List.generate(r.stars,(i)=>TweenAnimationBuilder<double>(
            tween:Tween(begin:0,end:i<stars?1.0:.15),
            duration:Duration(milliseconds:300+i*250),
            builder:(_,v,__)=>Transform.scale(scale:.7+.5*v,
                child:Opacity(opacity:max(v,.15),child:Padding(padding:const EdgeInsets.symmetric(horizontal:4),
                    child:Icon(Icons.star_rounded,color:Colors.amber,size:46))))))),
        const SizedBox(height:20),
        _rStat('⭐','$stars ${l=='ar'?'نجوم':l=='fr'?'étoiles':'stars'}',Colors.amber),
        const SizedBox(height:8),
        _rStat('❌','$_mistakes ${l=='ar'?'أخطاء':l=='fr'?'erreurs':'mistakes'}',Colors.redAccent),
        const SizedBox(height:24),
        SizedBox(width:double.infinity,child:ElevatedButton(onPressed:_next,
            style:ElevatedButton.styleFrom(backgroundColor:Colors.amber,foregroundColor:Colors.black,
                padding:const EdgeInsets.symmetric(vertical:16),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18)),
                textStyle:const TextStyle(fontSize:16,fontWeight:FontWeight.bold)),
            child:Text(isLast
                ?{'en':'🏆 Finish','fr':'🏆 Terminer','ar':'🏆 إنهاء'}[l]!
                :{'en':'▶ Next Round','fr':'▶ Tour suivant','ar':'▶ الجولة التالية'}[l]!))),
      ]),
    )));
  }

  Widget _rStat(String e,String t,Color c)=>Row(mainAxisAlignment:MainAxisAlignment.center,children:[
    Text(e,style:const TextStyle(fontSize:20)),const SizedBox(width:8),
    Text(t,style:TextStyle(color:c,fontSize:16,fontWeight:FontWeight.w600)),
  ]);

  // ═════════════════════════════════════════════════════════════════════════
  //  PHASE 3 — WIN
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildWin() {
    final l=_lang;
    return SingleChildScrollView(padding:const EdgeInsets.all(20),child:Column(children:[
      const SizedBox(height:8),
      _RoboFace(mood:_Mood.cheer,size:100),
      const SizedBox(height:14),
      Text({'en':'🏆 Computer Champion!','fr':'🏆 Champion Informatique !','ar':'🏆 بطل الحاسوب!'}[l]!,
          style:const TextStyle(color:Colors.amber,fontSize:26,fontWeight:FontWeight.bold),textAlign:TextAlign.center),
      const SizedBox(height:6),
      Text({'en':'You explored & mastered all computer parts!','fr':'Tu as exploré et maîtrisé toutes les pièces !','ar':'استكشفت وأتقنت جميع أجزاء الحاسوب!'}[l]!,
          style:const TextStyle(color:Colors.white70,fontSize:14),textAlign:TextAlign.center),
      const SizedBox(height:22),
      // Glossary
      ..._allParts.map((p) => Container(
        margin:const EdgeInsets.only(bottom:10),
        padding:const EdgeInsets.all(14),
        decoration:BoxDecoration(color:p.color.withOpacity(.14),borderRadius:BorderRadius.circular(16),border:Border.all(color:p.color.withOpacity(.4))),
        child:Row(children:[
          Text(p.emoji,style:const TextStyle(fontSize:26)),
          const SizedBox(width:12),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(p.label[l]!,style:TextStyle(color:p.color,fontWeight:FontWeight.bold,fontSize:15)),
            const SizedBox(height:4),
            Text(p.howWorks[l]!,style:const TextStyle(color:Colors.white60,fontSize:12,height:1.4)),
          ])),
        ]),
      )),
      const SizedBox(height:20),
      Container(padding:const EdgeInsets.all(18),
          decoration:BoxDecoration(color:Colors.white.withOpacity(.06),borderRadius:BorderRadius.circular(18),border:Border.all(color:Colors.white.withOpacity(.1))),
          child:Column(children:[
            _wStat(Icons.star_rounded,Colors.amber,{'en':'Total Stars','fr':'Étoiles totales','ar':'مجموع النجوم'}[l]!,'$_totStars'),
            const SizedBox(height:10),
            _wStat(Icons.bolt,Colors.cyanAccent,{'en':'Total XP','fr':'XP total','ar':'مجموع نقاط الخبرة'}[l]!,'$_totXp XP'),
          ])),
      const SizedBox(height:22),
      SizedBox(width:double.infinity,child:ElevatedButton.icon(
        icon:const Icon(Icons.replay), label:Text({'en':'Play Again','fr':'Rejouer','ar':'العب مجدداً'}[l]!),
        onPressed:_restart,
        style:ElevatedButton.styleFrom(backgroundColor:Colors.amber,foregroundColor:Colors.black,
            padding:const EdgeInsets.symmetric(vertical:16),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18)),
            textStyle:const TextStyle(fontSize:16,fontWeight:FontWeight.bold)),
      )),
      const SizedBox(height:12),
      SizedBox(width:double.infinity,child:OutlinedButton(
        onPressed:()=>Navigator.pop(context),
        style:OutlinedButton.styleFrom(foregroundColor:Colors.white70,side:const BorderSide(color:Colors.white24),
            padding:const EdgeInsets.symmetric(vertical:14),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18))),
        child:Text({'en':'← Back to IT','fr':'← Retour','ar':'← العودة'}[l]!),
      )),
    ]));
  }

  Widget _wStat(IconData icon,Color c,String lbl,String val)=>Row(children:[
    Icon(icon,color:c,size:22),const SizedBox(width:10),
    Expanded(child:Text(lbl,style:const TextStyle(color:Colors.white60,fontSize:13))),
    Text(val,style:TextStyle(color:c,fontWeight:FontWeight.bold,fontSize:17)),
  ]);

  // ─────────────────────────────────────────────────────────────────────────
  //  SHARED WIDGETS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _appBar({required String title, required Widget trailing}) => Container(
    margin:const EdgeInsets.fromLTRB(12,10,12,0),
    padding:const EdgeInsets.symmetric(horizontal:14,vertical:10),
    decoration:BoxDecoration(color:Colors.white.withOpacity(.07),borderRadius:BorderRadius.circular(20),border:Border.all(color:Colors.white.withOpacity(.1))),
    child:Row(children:[
      GestureDetector(onTap:()=>Navigator.pop(context),
          child:Container(padding:const EdgeInsets.all(6),
              decoration:BoxDecoration(color:Colors.white.withOpacity(.1),borderRadius:BorderRadius.circular(10)),
              child:const Icon(Icons.arrow_back_ios_new,color:Colors.white70,size:16))),
      const SizedBox(width:10),
      Expanded(child:Text(title,style:const TextStyle(color:Colors.white,fontSize:16,fontWeight:FontWeight.bold))),
      trailing,
    ]),
  );

  Widget _mascotRow() => AnimatedBuilder(
    animation:_bounceAnim,
    builder:(_,__)=>Transform.translate(
      offset:Offset(0,_bounceCtrl.isAnimating?_bounceAnim.value:0),
      child:Padding(padding:const EdgeInsets.symmetric(horizontal:16),
        child:Row(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.end,children:[
          if(_speech.isNotEmpty) Flexible(child:Container(
            constraints:const BoxConstraints(maxWidth:210),
            padding:const EdgeInsets.symmetric(horizontal:12,vertical:9),
            decoration:BoxDecoration(
              color:Colors.white.withOpacity(.1),
              borderRadius:const BorderRadius.only(topLeft:Radius.circular(16),topRight:Radius.circular(16),bottomLeft:Radius.circular(16),bottomRight:Radius.circular(4)),
              border:Border.all(color:Colors.white.withOpacity(.18)),
            ),
            child:Text(_speech,style:const TextStyle(color:Colors.white,fontSize:12,fontWeight:FontWeight.w500),textAlign:TextAlign.center),
          )),
          const SizedBox(width:8),
          _RoboFace(mood:_mood,size:58),
        ]),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  ROOM PAINTER — draws the computer lab scene
// ─────────────────────────────────────────────────────────────────────────────

class _RoomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final w=s.width, h=s.height;

    // ── floor ──────────────────────────────────────────────────────────────
    canvas.drawRect(Rect.fromLTWH(0,h*.62,w,h*.38),
        Paint()..color=const Color(0xFF1A3A2A));
    // floor tiles
    final tp = Paint()..color=Colors.white.withOpacity(.04)..strokeWidth=1..style=PaintingStyle.stroke;
    for(double x=0;x<w;x+=w/5) canvas.drawLine(Offset(x,h*.62),Offset(x,h),tp);
    for(double y=h*.62;y<h;y+=(h*.38)/3) canvas.drawLine(Offset(0,y),Offset(w,y),tp);

    // ── back wall ─────────────────────────────────────────────────────────
    canvas.drawRect(Rect.fromLTWH(0,0,w,h*.63), Paint()..color=const Color(0xFF1B2D42));
    // wall stripe
    canvas.drawRect(Rect.fromLTWH(0,h*.55,w,h*.08), Paint()..color=const Color(0xFF162438));
    // baseboard
    canvas.drawRect(Rect.fromLTWH(0,h*.60,w,h*.04), Paint()..color=const Color(0xFF0E1C2C));

    // ── window (back wall) ────────────────────────────────────────────────
    _rect(canvas, Rect.fromLTWH(w*.05,h*.04,w*.25,h*.30), const Color(0xFF1E4060), radius:6);
    _rect(canvas, Rect.fromLTWH(w*.06,h*.05,w*.23,h*.28), const Color(0xFF87CEEB).withOpacity(.25), radius:5);
    // window cross
    final wcp = Paint()..color=const Color(0xFF1B3A55)..strokeWidth=3;
    canvas.drawLine(Offset(w*.175,h*.05),Offset(w*.175,h*.33),wcp);
    canvas.drawLine(Offset(w*.06,h*.19),Offset(w*.29,h*.19),wcp);
    // sun through window
    canvas.drawCircle(Offset(w*.24,h*.12),w*.04,Paint()..color=Colors.amber.withOpacity(.5));

    // ── educational poster ────────────────────────────────────────────────
    _rect(canvas, Rect.fromLTWH(w*.34,h*.04,w*.30,h*.20), const Color(0xFF7B1FA2), radius:4);
    _rect(canvas, Rect.fromLTWH(w*.36,h*.06,w*.26,h*.16), const Color(0xFF9C27B0).withOpacity(.5), radius:3);
    // ABC text hint
    final tp2 = Paint()..color=Colors.white.withOpacity(.7);
    // draw "ABC" manually with tiny rects representing text blocks
    for(int i=0;i<3;i++){
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w*.39+i*w*.07,h*.10,w*.05,h*.03),const Radius.circular(2)), tp2);
    }
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w*.39,h*.14,w*.22,h*.015),const Radius.circular(2)),
        Paint()..color=Colors.white.withOpacity(.4));

    // ── second poster ─────────────────────────────────────────────────────
    _rect(canvas, Rect.fromLTWH(w*.68,h*.04,w*.27,h*.18), const Color(0xFF1565C0), radius:4);
    // circuit dots pattern
    final cdp = Paint()..color=Colors.cyanAccent.withOpacity(.3);
    for(int r=0;r<3;r++) for(int c=0;c<4;c++) {
      canvas.drawCircle(Offset(w*.72+c*w*.055, h*.08+r*w*.045), 3, cdp);
    }
    // connector lines
    final clp = Paint()..color=Colors.cyanAccent.withOpacity(.2)..strokeWidth=1.5;
    canvas.drawLine(Offset(w*.72,h*.08),Offset(w*.775,h*.08),clp);
    canvas.drawLine(Offset(w*.775,h*.08),Offset(w*.775,h*.125),clp);

    // ── desk ──────────────────────────────────────────────────────────────
    _rect(canvas, Rect.fromLTWH(w*.08,h*.55,w*.86,h*.08), const Color(0xFF4A3520), radius:4);
    _rect(canvas, Rect.fromLTWH(w*.10,h*.56,w*.82,h*.05), const Color(0xFF5D4428), radius:3);

    // desk legs
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w*.10,h*.62,w*.04,h*.12),const Radius.circular(2)), Paint()..color=const Color(0xFF3D2B14));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w*.86,h*.62,w*.04,h*.12),const Radius.circular(2)), Paint()..color=const Color(0xFF3D2B14));

    // ── CPU tower (left side) ──────────────────────────────────────────────
    _rect(canvas, Rect.fromLTWH(w*.09,h*.28,w*.10,h*.28), const Color(0xFF263238), radius:4);
    _rect(canvas, Rect.fromLTWH(w*.10,h*.30,w*.08,h*.04), const Color(0xFF37474F), radius:2);
    _rect(canvas, Rect.fromLTWH(w*.10,h*.36,w*.08,h*.015), const Color(0xFF37474F), radius:1);
    canvas.drawCircle(Offset(w*.14,h*.41),w*.015,Paint()..color=Colors.blue.withOpacity(.7));
    canvas.drawCircle(Offset(w*.14,h*.41),w*.008,Paint()..color=Colors.lightBlueAccent);
    // power light blink simulation
    canvas.drawCircle(Offset(w*.14,h*.44),w*.01,Paint()..color=Colors.greenAccent.withOpacity(.8));
    // usb slots
    _rect(canvas, Rect.fromLTWH(w*.105,h*.47,w*.07,h*.015), const Color(0xFF455A64), radius:1);
    _rect(canvas, Rect.fromLTWH(w*.105,h*.50,w*.07,h*.015), const Color(0xFF455A64), radius:1);

    // ── monitor ───────────────────────────────────────────────────────────
    _rect(canvas, Rect.fromLTWH(w*.30,h*.12,w*.42,h*.38), const Color(0xFF1C2833), radius:8);
    _rect(canvas, Rect.fromLTWH(w*.32,h*.14,w*.38,h*.33), const Color(0xFF0A1628), radius:6);
    // screen content — simple "desktop"
    _rect(canvas, Rect.fromLTWH(w*.33,h*.15,w*.36,h*.30), const Color(0xFF1565C0).withOpacity(.8), radius:5);
    // fake desktop icons
    final ip = Paint()..color=Colors.white.withOpacity(.6);
    for(int i=0;i<3;i++) canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w*.35+i*w*.08,h*.25,w*.05,h*.04),const Radius.circular(3)),ip);
    // taskbar
    _rect(canvas, Rect.fromLTWH(w*.33,h*.42,w*.36,h*.025), const Color(0xFF0D47A1), radius:0);
    // monitor stand
    canvas.drawRect(Rect.fromLTWH(w*.495,h*.49,w*.02,h*.06),Paint()..color=const Color(0xFF263238));
    canvas.drawRect(Rect.fromLTWH(w*.46,h*.54,w*.08,h*.015),Paint()..color=const Color(0xFF263238));
    // monitor power dot
    canvas.drawCircle(Offset(w*.51,h*.13),w*.007,Paint()..color=Colors.greenAccent.withOpacity(.9));

    // ── webcam (top of monitor) ────────────────────────────────────────────
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w*.49,h*.115,w*.025,h*.018),const Radius.circular(3)),Paint()..color=const Color(0xFF212121));
    canvas.drawCircle(Offset(w*.502,h*.124),w*.007,Paint()..color=Colors.blue.withOpacity(.9));
    canvas.drawCircle(Offset(w*.502,h*.124),w*.003,Paint()..color=Colors.black);

    // ── keyboard ──────────────────────────────────────────────────────────
    _rect(canvas, Rect.fromLTWH(w*.28,h*.575,w*.42,h*.045), const Color(0xFF263238), radius:4);
    // key grid
    final kp = Paint()..color=const Color(0xFF37474F)..style=PaintingStyle.stroke..strokeWidth=.5;
    for(int r=0;r<2;r++) for(int c=0;c<10;c++) {
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(w*.295+c*w*.037,h*.579+r*h*.015,w*.031,h*.012),const Radius.circular(1)),kp);
    }

    // ── mouse ─────────────────────────────────────────────────────────────
    _rect(canvas, Rect.fromLTWH(w*.73,h*.565,w*.07,h*.055), const Color(0xFF37474F), radius:20);
    canvas.drawLine(Offset(w*.765,h*.567),Offset(w*.765,h*.585),Paint()..color=Colors.black26..strokeWidth=1);

    // ── speaker (right side) ──────────────────────────────────────────────
    _rect(canvas, Rect.fromLTWH(w*.82,h*.38,w*.09,h*.17), const Color(0xFF1A2A1A), radius:6);
    // speaker grill dots
    final sp = Paint()..color=Colors.greenAccent.withOpacity(.3);
    for(int r=0;r<4;r++) for(int c=0;c<3;c++) {
      canvas.drawCircle(Offset(w*.835+c*w*.022,h*.40+r*h*.025),2.5,sp);
    }
    canvas.drawCircle(Offset(w*.865,h*.52),w*.02,Paint()..color=const Color(0xFF2E7D32).withOpacity(.7));

    // ── printer (left lower) ──────────────────────────────────────────────
    _rect(canvas, Rect.fromLTWH(w*.09,h*.57,w*.17,h*.055), const Color(0xFF37474F), radius:4);
    _rect(canvas, Rect.fromLTWH(w*.10,h*.575,w*.15,h*.01), const Color(0xFF455A64), radius:1);
    canvas.drawCircle(Offset(w*.245,h*.583),w*.01,Paint()..color=Colors.greenAccent.withOpacity(.8));

    // ── headphones (hanging right upper) ─────────────────────────────────
    // arc
    final hp = Paint()..color=const Color(0xFF4CAF50)..strokeWidth=3..style=PaintingStyle.stroke..strokeCap=StrokeCap.round;
    canvas.drawArc(Rect.fromLTWH(w*.79,h*.14,w*.10,h*.08), pi, pi, false, hp);
    // ear cups
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w*.785,h*.19,w*.025,h*.04),const Radius.circular(4)),Paint()..color=const Color(0xFF388E3C));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w*.875,h*.19,w*.025,h*.04),const Radius.circular(4)),Paint()..color=const Color(0xFF388E3C));

    // ── plant (left corner decoration) ────────────────────────────────────
    // pot
    _rect(canvas, Rect.fromLTWH(w*.02,h*.58,w*.055,h*.05), const Color(0xFFBF360C), radius:3);
    // stem
    canvas.drawLine(Offset(w*.047,h*.58),Offset(w*.047,h*.50),Paint()..color=const Color(0xFF2E7D32)..strokeWidth=2.5);
    // leaves
    final lp = Paint()..color=const Color(0xFF43A047);
    final leaf1 = Path()..moveTo(w*.047,h*.55)..quadraticBezierTo(w*.00,h*.52,w*.01,h*.50)..quadraticBezierTo(w*.03,h*.50,w*.047,h*.55);
    final leaf2 = Path()..moveTo(w*.047,h*.52)..quadraticBezierTo(w*.09,h*.49,w*.09,h*.47)..quadraticBezierTo(w*.06,h*.49,w*.047,h*.52);
    canvas.drawPath(leaf1,lp); canvas.drawPath(leaf2,lp);

    // ── chair (in front of desk) ──────────────────────────────────────────
    _rect(canvas, Rect.fromLTWH(w*.38,h*.72,w*.22,h*.14), const Color(0xFF1A237E), radius:8);
    _rect(canvas, Rect.fromLTWH(w*.40,h*.70,w*.18,h*.14), const Color(0xFF283593), radius:6);
    // chair legs
    final clp2 = Paint()..color=const Color(0xFF37474F)..strokeWidth=3..strokeCap=StrokeCap.round;
    canvas.drawLine(Offset(w*.42,h*.86),Offset(w*.38,h*.94),clp2);
    canvas.drawLine(Offset(w*.56,h*.86),Offset(w*.60,h*.94),clp2);
    canvas.drawLine(Offset(w*.49,h*.86),Offset(w*.49,h*.94),clp2);

    // ── ambient glow under monitor ────────────────────────────────────────
    final aura = Paint()..color=const Color(0xFF1565C0).withOpacity(.12);
    canvas.drawOval(Rect.fromLTWH(w*.25,h*.49,w*.50,h*.06),aura);
  }

  void _rect(Canvas c, Rect r, Color col, {double radius=0}) {
    c.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(radius)), Paint()..color=col);
  }

  @override bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
//  ROBO FACE
// ─────────────────────────────────────────────────────────────────────────────

class _RoboFace extends StatelessWidget {
  final _Mood mood; final double size;
  const _RoboFace({required this.mood, this.size=60});
  @override Widget build(BuildContext ctx)=>SizedBox(width:size,height:size*1.15,child:CustomPaint(painter:_RoboPainter(mood:mood)));
}

class _RoboPainter extends CustomPainter {
  final _Mood mood; const _RoboPainter({required this.mood});
  @override void paint(Canvas c, Size s) {
    final w=s.width,h=s.height,cx=w/2;
    // antenna
    c.drawLine(Offset(cx,h*.04),Offset(cx,h*.18),Paint()..color=const Color(0xFF90CAF9)..strokeWidth=w*.06..strokeCap=StrokeCap.round);
    c.drawCircle(Offset(cx,h*.04),w*.09,Paint()..color=mood==_Mood.cheer?Colors.amber:const Color(0xFF42A5F5));
    // head
    final head=RRect.fromRectAndRadius(Rect.fromLTWH(w*.08,h*.18,w*.84,h*.70),Radius.circular(w*.2));
    c.drawRRect(head,Paint()..color=const Color(0xFF172B45));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w*.1,h*.19,w*.8,h*.22),Radius.circular(w*.15)),Paint()..color=Colors.white.withOpacity(.07));
    c.drawRRect(head,Paint()..color=const Color(0xFF42A5F5)..style=PaintingStyle.stroke..strokeWidth=w*.045);
    // eyes
    _eye(c,Offset(cx-w*.22,h*.43),w*.14);
    _eye(c,Offset(cx+w*.22,h*.43),w*.14);
    c.drawCircle(Offset(cx-w*.165,h*.405),w*.036,Paint()..color=Colors.white.withOpacity(.85));
    c.drawCircle(Offset(cx+w*.275,h*.405),w*.036,Paint()..color=Colors.white.withOpacity(.85));
    // brows
    final bp=Paint()..color=const Color(0xFF90CAF9)..strokeWidth=w*.05..strokeCap=StrokeCap.round..style=PaintingStyle.stroke;
    if(mood==_Mood.happy||mood==_Mood.cheer){
      c.drawPath(Path()..moveTo(cx-w*.34,h*.32)..quadraticBezierTo(cx-w*.22,h*.27,cx-w*.10,h*.32),bp);
      c.drawPath(Path()..moveTo(cx+w*.10,h*.32)..quadraticBezierTo(cx+w*.22,h*.27,cx+w*.34,h*.32),bp);
    } else if(mood==_Mood.sad){
      c.drawPath(Path()..moveTo(cx-w*.34,h*.29)..quadraticBezierTo(cx-w*.22,h*.34,cx-w*.10,h*.29),bp);
      c.drawPath(Path()..moveTo(cx+w*.10,h*.29)..quadraticBezierTo(cx+w*.22,h*.34,cx+w*.34,h*.29),bp);
    }
    // mouth
    final mp=Paint()..color=const Color(0xFF42A5F5)..strokeWidth=w*.058..strokeCap=StrokeCap.round..style=PaintingStyle.stroke;
    final mp2=Path();
    if(mood==_Mood.sad){ mp2.moveTo(cx-w*.22,h*.73); mp2.quadraticBezierTo(cx,h*.67,cx+w*.22,h*.73); }
    else if(mood==_Mood.cheer){ mp2.moveTo(cx-w*.26,h*.68); mp2.quadraticBezierTo(cx,h*.80,cx+w*.26,h*.68); }
    else { mp2.moveTo(cx-w*.20,h*.69); mp2.quadraticBezierTo(cx,h*.77,cx+w*.20,h*.69); }
    c.drawPath(mp2,mp);
    if(mood==_Mood.cheer){
      c.drawRect(Rect.fromLTWH(cx-w*.13,h*.71,w*.105,h*.055),Paint()..color=Colors.white);
      c.drawRect(Rect.fromLTWH(cx+w*.025,h*.71,w*.105,h*.055),Paint()..color=Colors.white);
    }
    // blush
    if(mood==_Mood.happy||mood==_Mood.cheer){
      c.drawCircle(Offset(cx-w*.32,h*.59),w*.11,Paint()..color=Colors.pinkAccent.withOpacity(.38));
      c.drawCircle(Offset(cx+w*.32,h*.59),w*.11,Paint()..color=Colors.pinkAccent.withOpacity(.38));
    }
    // stars
    if(mood==_Mood.cheer){ _star(c,Offset(cx-w*.39,h*.3),w*.075); _star(c,Offset(cx+w*.39,h*.3),w*.075); }
  }
  void _eye(Canvas c,Offset center,double r){
    c.drawCircle(center,r,Paint()..color=const Color(0xFF0D1F35));
    c.drawCircle(center,r*.72,Paint()..color=mood==_Mood.sad?const Color(0xFF78909C):mood==_Mood.cheer?Colors.amber:const Color(0xFF42A5F5));
    c.drawCircle(center+(mood==_Mood.sad?Offset(0,r*.18):Offset.zero),r*.37,Paint()..color=const Color(0xFF0D1F35));
  }
  void _star(Canvas c,Offset center,double r){
    final path=Path();
    for(int i=0;i<5;i++){
      final o=Offset(center.dx+r*cos(pi/2+i*2*pi/5),center.dy-r*sin(pi/2+i*2*pi/5));
      final inn=Offset(center.dx+r*.4*cos(pi/2+(i+.5)*2*pi/5),center.dy-r*.4*sin(pi/2+(i+.5)*2*pi/5));
      if(i==0) path.moveTo(o.dx,o.dy); else path.lineTo(o.dx,o.dy);
      path.lineTo(inn.dx,inn.dy);
    }
    path.close();
    c.drawPath(path,Paint()..color=Colors.amber);
  }
  @override bool shouldRepaint(_RoboPainter o)=>o.mood!=mood;
}

// ─────────────────────────────────────────────────────────────────────────────
//  PARTICLE BURST
// ─────────────────────────────────────────────────────────────────────────────

class _Burst extends StatefulWidget {
  final Color color; const _Burst({required this.color});
  @override State<_Burst> createState()=>_BurstState();
}
class _BurstState extends State<_Burst> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late List<({double angle,double speed,Color color,double size})> _ps;
  @override void initState(){
    super.initState();
    final r=Random();
    _ps=List.generate(16,(_){
      final h=HSLColor.fromColor(widget.color);
      return (angle:r.nextDouble()*2*pi, speed:.35+r.nextDouble()*.65,
      color:h.withLightness((h.lightness+.1+r.nextDouble()*.3).clamp(.3,.9)).toColor(),
      size:4.0+r.nextDouble()*6);
    });
    _c=AnimationController(vsync:this,duration:const Duration(milliseconds:750));
    _c.forward();
  }
  @override void dispose(){_c.dispose();super.dispose();}
  @override Widget build(BuildContext ctx)=>AnimatedBuilder(animation:_c,builder:(_,__)=>CustomPaint(painter:_BurstPainter(ps:_ps,t:_c.value)));
}

class _BurstPainter extends CustomPainter {
  final List<({double angle,double speed,Color color,double size})> ps; final double t;
  const _BurstPainter({required this.ps,required this.t});
  @override void paint(Canvas canvas,Size s){
    final cx=s.width/2,cy=s.height/2;
    for(final p in ps){
      final d=p.speed*t*s.shortestSide*.58;
      canvas.drawCircle(Offset(cx+cos(p.angle)*d,cy+sin(p.angle)*d),p.size*(1-t*.45),Paint()..color=p.color.withOpacity((1-t).clamp(0,1)));
    }
  }
  @override bool shouldRepaint(_BurstPainter o)=>o.t!=t;
}

// ─────────────────────────────────────────────────────────────────────────────
//  STAR BACKGROUND
// ─────────────────────────────────────────────────────────────────────────────

class _StarPainter extends CustomPainter {
  static final _r=Random(99);
  static final _dots=List.generate(55,(_)=>Offset(_r.nextDouble(),_r.nextDouble()));
  static final _sz=List.generate(55,(_)=>.8+_r.nextDouble()*2.2);
  @override void paint(Canvas c,Size s){
    final p=Paint()..color=Colors.white.withOpacity(.12);
    for(int i=0;i<_dots.length;i++) c.drawCircle(Offset(_dots[i].dx*s.width,_dots[i].dy*s.height),_sz[i],p);
  }
  @override bool shouldRepaint(covariant CustomPainter _)=>false;
}