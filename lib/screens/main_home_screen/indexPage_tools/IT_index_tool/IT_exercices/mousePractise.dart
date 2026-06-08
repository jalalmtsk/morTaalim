// mouse_practice_exercise.dart
// Route: IT_MousePractice
//
// ╔══════════════════════════════════════════════════════════╗
// ║  "BUG CATCHER" — Grade 1–2                             ║
// ║                                                          ║
// ║  Glowing bugs crawl around a garden scene.              ║
// ║  Tap bugs before they escape off-screen.                ║
// ║  5 waves, each faster + more bugs.                      ║
// ║  Accuracy & speed = star rating.                        ║
// ║  Educational: teaches cursor control, click precision.  ║
// ║  Localized: EN / FR / AR + RTL                          ║
// ╚══════════════════════════════════════════════════════════╝

import 'dart:async';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../XpSystem.dart';
import '../../../../../tools/audio_tool/Audio_Manager.dart';


// ─────────────────────────────────────────────────────────────────────────────
//  BUG MODEL
// ─────────────────────────────────────────────────────────────────────────────

class _Bug {
  final String id, emoji;
  double x, y, vx, vy;
  bool alive;
  double size;
  int points;

  _Bug({
    required this.id, required this.emoji,
    required this.x, required this.y,
    required this.vx, required this.vy,
    this.alive = true, this.size = 52, this.points = 10,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  WAVE CONFIG
// ─────────────────────────────────────────────────────────────────────────────

class _Wave {
  final int bugCount, durationSec;
  final double speed;
  final int stars, xp;
  final Map<String,String> name;
  const _Wave({
    required this.bugCount, required this.durationSec, required this.speed,
    required this.stars, required this.xp, required this.name,
  });
}

const _waves = [
  _Wave(bugCount:4, durationSec:20, speed:1.2, stars:1, xp:15, name:{'en':'Wave 1 🐌 Easy!','fr':'Vague 1 🐌 Facile !','ar':'موجة 1 🐌 سهل!'}),
  _Wave(bugCount:6, durationSec:18, speed:1.8, stars:1, xp:20, name:{'en':'Wave 2 🐛 Getting faster!','fr':'Vague 2 🐛 Plus vite !','ar':'موجة 2 🐛 أسرع!'}),
  _Wave(bugCount:8, durationSec:16, speed:2.5, stars:2, xp:30, name:{'en':'Wave 3 🐝 Zoom zoom!','fr':'Vague 3 🐝 Zoum zoum !','ar':'موجة 3 🐝 سريع سريع!'}),
  _Wave(bugCount:9, durationSec:15, speed:3.2, stars:2, xp:40, name:{'en':'Wave 4 🦗 Very fast!','fr':'Vague 4 🦗 Très rapide !','ar':'موجة 4 🦗 سريع جداً!'}),
  _Wave(bugCount:12,durationSec:15, speed:4.0, stars:3, xp:60, name:{'en':'Wave 5 🦟 Expert mode!','fr':'Vague 5 🦟 Mode expert !','ar':'موجة 5 🦟 وضع الخبير!'}),
];

const _bugEmojis = ['🐛','🐝','🦋','🐞','🦗','🦟','🐜','🐢','🐸'];

// ─────────────────────────────────────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class MousePracticeExercise extends StatefulWidget {
  const MousePracticeExercise({super.key});
  @override State<MousePracticeExercise> createState() => _MPState();
}

class _MPState extends State<MousePracticeExercise> with TickerProviderStateMixin {

  int _wi = 0;            // wave index
  List<_Bug> _bugs = [];
  int _caught = 0, _missed = 0, _score = 0;
  int _totStars = 0, _totXp = 0;
  bool _waveActive = false, _waveOver = false, _gameOver = false, _countdown = false;
  int _countdownVal = 3, _timeLeft = 20;

  Timer? _gameTimer, _bugTimer, _cdTimer;

  // tap burst visuals
  final List<_TapBurst> _bursts = [];

  // animations
  late AnimationController _countCtrl, _pulseCtrl, _bounceCtrl;
  late Animation<double> _countScale, _pulseAnim, _bounceAnim;
  late ConfettiController _confetti;

  final _rng = Random();
  double _gameW = 360, _gameH = 480;

  String get _lang { final c = Localizations.localeOf(context).languageCode; return ['ar','fr'].contains(c)?c:'en'; }
  bool get _rtl => _lang == 'ar';

  @override
  void initState() {
    super.initState();

    _countCtrl = AnimationController(vsync:this, duration:const Duration(milliseconds:600));
    _countScale = Tween(begin:1.5,end:.5).animate(CurvedAnimation(parent:_countCtrl, curve:Curves.easeIn));

    _pulseCtrl = AnimationController(vsync:this, duration:const Duration(milliseconds:800))..repeat(reverse:true);
    _pulseAnim = Tween(begin:.7,end:1.0).animate(CurvedAnimation(parent:_pulseCtrl, curve:Curves.easeInOut));

    _bounceCtrl = AnimationController(vsync:this, duration:const Duration(milliseconds:600));
    _bounceAnim = Tween(begin:0.0,end:-15.0).animate(CurvedAnimation(parent:_bounceCtrl, curve:Curves.elasticOut));

    _confetti = ConfettiController(duration:const Duration(seconds:3));

    WidgetsBinding.instance.addPostFrameCallback((_) => _startCountdown());
  }

  @override
  void dispose() {
    _gameTimer?.cancel(); _bugTimer?.cancel(); _cdTimer?.cancel();
    _countCtrl.dispose(); _pulseCtrl.dispose(); _bounceCtrl.dispose();
    _confetti.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  GAME LOGIC
  // ─────────────────────────────────────────────────────────────────────────

  void _startCountdown() {
    setState(() { _countdown=true; _countdownVal=3; });
    _cdTimer = Timer.periodic(const Duration(seconds:1), (t) {
      _countCtrl.forward(from:0);
      if (_countdownVal > 1) {
        setState(() => _countdownVal--);
      } else {
        t.cancel();
        setState(() => _countdown=false);
        _startWave();
      }
    });
  }

  void _startWave() {
    final w = _waves[_wi];
    setState(() {
      _bugs = [];
      _caught = 0; _missed = 0; _score = 0;
      _waveActive = true; _waveOver = false;
      _timeLeft = w.durationSec;
    });
    _spawnBugs(w);
    // countdown timer
    _gameTimer = Timer.periodic(const Duration(seconds:1), (t) {
      if (_timeLeft <= 1) { t.cancel(); _endWave(); return; }
      setState(() => _timeLeft--);
    });
    // bug movement ticker
    _bugTimer = Timer.periodic(const Duration(milliseconds:16), (_) => _tick());
  }

  void _spawnBugs(_Wave w) {
    for (int i = 0; i < w.bugCount; i++) {
      Future.delayed(Duration(milliseconds: i * 800 + _rng.nextInt(400)), () {
        if (!mounted || !_waveActive) return;
        final angle = _rng.nextDouble() * 2 * pi;
        final speed = w.speed * (.7 + _rng.nextDouble() * .6);
        final side = _rng.nextInt(4);
        double bx, by;
        switch(side) {
          case 0: bx=_rng.nextDouble()*_gameW; by=-40; break;
          case 1: bx=_gameW+40; by=_rng.nextDouble()*_gameH; break;
          case 2: bx=_rng.nextDouble()*_gameW; by=_gameH+40; break;
          default: bx=-40; by=_rng.nextDouble()*_gameH;
        }
        // aim roughly at center with some deviation
        final tx = _gameW*.3 + _rng.nextDouble()*_gameW*.4;
        final ty = _gameH*.3 + _rng.nextDouble()*_gameH*.4;
        final dx = tx-bx, dy = ty-by;
        final len = sqrt(dx*dx+dy*dy);
        setState(() => _bugs.add(_Bug(
          id:'bug_${DateTime.now().microsecondsSinceEpoch}_$i',
          emoji:_bugEmojis[_rng.nextInt(_bugEmojis.length)],
          x:bx, y:by,
          vx:(dx/len)*speed, vy:(dy/len)*speed,
          size:48-_wi*4.0, points:10+_wi*5,
        )));
      });
    }
  }

  void _tick() {
    if (!_waveActive || !mounted) return;
    bool changed = false;
    final toRemove = <_Bug>[];
    for (final b in _bugs) {
      if (!b.alive) continue;
      // wiggle
      b.vx += (_rng.nextDouble()-.5)*.3;
      b.vy += (_rng.nextDouble()-.5)*.3;
      // cap speed
      final spd = sqrt(b.vx*b.vx+b.vy*b.vy);
      final maxSpd = _waves[_wi].speed * 1.5;
      if (spd > maxSpd) { b.vx = b.vx/spd*maxSpd; b.vy = b.vy/spd*maxSpd; }
      b.x += b.vx; b.y += b.vy;
      changed = true;
      // escape check
      if (b.x < -80 || b.x > _gameW+80 || b.y < -80 || b.y > _gameH+80) {
        toRemove.add(b); _missed++;
      }
    }
    for (final b in toRemove) { _bugs.remove(b); }
    if (changed) setState((){});
  }

  void _tapBug(_Bug bug) {
    if (!bug.alive || !_waveActive) return;
    final audio = Provider.of<AudioManager>(context, listen:false);
    audio.playSfx('assets/audios/sound_effects/correct_anwser.mp3');
    bug.alive = false;
    _caught++; _score += bug.points;
    _bounceCtrl.forward(from:0);
    final burst = _TapBurst(x:bug.x, y:bug.y, color:_bugColor(bug.emoji));
    setState(() => _bursts.add(burst));
    Future.delayed(const Duration(milliseconds:700), (){ if(mounted) setState(()=>_bursts.remove(burst)); });
    setState((){});
  }

  Color _bugColor(String emoji) {
    switch(emoji){
      case '🐛': return Colors.greenAccent;
      case '🐝': return Colors.amber;
      case '🦋': return Colors.purpleAccent;
      case '🐞': return Colors.redAccent;
      default: return Colors.cyanAccent;
    }
  }

  void _endWave() {
    _bugTimer?.cancel(); _gameTimer?.cancel();
    setState(() { _waveActive=false; _waveOver=true; });
    final w = _waves[_wi];
    final accuracy = _caught / max(1, _caught+_missed);
    final s = accuracy>.8?w.stars:accuracy>.5?max(1,w.stars-1):1;
    final x = (w.xp * accuracy).round();
    _totStars+=s; _totXp+=x;
    final xpMgr = Provider.of<ExperienceManager>(context, listen:false);
    final audio  = Provider.of<AudioManager>(context, listen:false);
    xpMgr.addStarBanner(context, s);
    xpMgr.addXP(x, context:context);
    if (accuracy>.7) { _confetti.play(); audio.playSfx('assets/audios/UI_Audio/SFX_Audio/victory1_SFX.mp3'); }
  }

  void _nextWave() {
    if (_wi < _waves.length-1) {
      setState(() { _wi++; _waveOver=false; });
      _startCountdown();
    } else {
      setState(() => _gameOver=true);
      _confetti.play();
    }
  }

  void _restart() {
    _gameTimer?.cancel(); _bugTimer?.cancel(); _cdTimer?.cancel();
    setState(() { _wi=0; _totStars=0; _totXp=0; _gameOver=false; _bugs=[]; _bursts.clear(); });
    _startCountdown();
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext ctx) => Directionality(
    textDirection:_rtl?TextDirection.rtl:TextDirection.ltr,
    child:Scaffold(body:Stack(children:[
      _bg(),
      SafeArea(child: _gameOver?_winScreen():Column(children:[
        _topBar(),
        const SizedBox(height:6),
        Expanded(child: LayoutBuilder(builder:(_,c){
          _gameW=c.maxWidth; _gameH=c.maxHeight;
          return Stack(children:[
            // garden background
            Positioned.fill(child:CustomPaint(painter:_GardenPainter())),
            // bugs
            ..._bugs.where((b)=>b.alive).map((b)=>_bugWidget(b)),
            // tap bursts
            ..._bursts.map((t)=>_burstWidget(t)),
            // countdown overlay
            if (_countdown) _countdownOverlay(),
            // wave over overlay
            if (_waveOver) _waveOverlay(),
            // HUD
            _hud(),
          ]);
        })),
      ])),
      _confettiW(),
    ])),
  );

  // ── Background ────────────────────────────────────────────────────────────

  Widget _bg() => Container(
    decoration: const BoxDecoration(gradient:LinearGradient(
        colors:[Color(0xFF071A10),Color(0xFF0B2A18),Color(0xFF071A10)],
        begin:Alignment.topLeft, end:Alignment.bottomRight)),
  );

  Widget _confettiW() => Positioned.fill(child:IgnorePointer(child:Align(
    alignment:Alignment.topCenter,
    child:ConfettiWidget(confettiController:_confetti,
        blastDirectionality:BlastDirectionality.explosive,
        emissionFrequency:.06, numberOfParticles:28, gravity:.25,
        colors:const [Color(0xFFFFD700),Color(0xFF69F0AE),Color(0xFFFF4081),Color(0xFF00E5FF)]),
  )));

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _topBar() => Container(
    margin:const EdgeInsets.fromLTRB(12,10,12,0),
    padding:const EdgeInsets.symmetric(horizontal:14,vertical:10),
    decoration:BoxDecoration(color:Colors.black.withOpacity(.4),borderRadius:BorderRadius.circular(20),border:Border.all(color:Colors.greenAccent.withOpacity(.2))),
    child:Row(children:[
      GestureDetector(onTap:()=>Navigator.pop(context),
          child:Container(padding:const EdgeInsets.all(6),decoration:BoxDecoration(color:Colors.white.withOpacity(.1),borderRadius:BorderRadius.circular(10)),
              child:const Icon(Icons.arrow_back_ios_new,color:Colors.white70,size:16))),
      const SizedBox(width:10),
      Expanded(child:Text({'en':'🐛 Bug Catcher','fr':'🐛 Chasseur de Bugs','ar':'🐛 صياد الحشرات'}[_lang]!,
          style:const TextStyle(color:Colors.white,fontSize:16,fontWeight:FontWeight.bold))),
      // wave pills
      Row(children:List.generate(5,(i)=>AnimatedContainer(duration:const Duration(milliseconds:300),
          margin:const EdgeInsets.only(left:4),width:i==_wi?20:8,height:8,
          decoration:BoxDecoration(borderRadius:BorderRadius.circular(4),
              color:i<_wi?Colors.greenAccent:i==_wi?Colors.amber:Colors.white24)))),
    ]),
  );

  // ── HUD ───────────────────────────────────────────────────────────────────

  Widget _hud() => Positioned(top:10,left:12,right:12,
      child:Row(children:[
        _hudPill('🎯 $_caught',Colors.greenAccent),
        const SizedBox(width:8),
        _hudPill('❌ $_missed',Colors.redAccent),
        const Spacer(),
        _hudPill('⏱ $_timeLeft s',_timeLeft<=5?Colors.redAccent:Colors.amber),
      ]));

  Widget _hudPill(String t,Color c) => Container(
      padding:const EdgeInsets.symmetric(horizontal:10,vertical:5),
      decoration:BoxDecoration(color:Colors.black.withOpacity(.55),borderRadius:BorderRadius.circular(20),border:Border.all(color:c.withOpacity(.5))),
      child:Text(t,style:TextStyle(color:c,fontSize:13,fontWeight:FontWeight.bold)));

  // ── Bug widget ────────────────────────────────────────────────────────────

  Widget _bugWidget(_Bug bug) {
    final r = _rng.nextDouble()*.1-.05;
    return Positioned(
      left:bug.x - bug.size/2,
      top: bug.y - bug.size/2,
      child:GestureDetector(
        onTap:()=>_tapBug(bug),
        child:AnimatedBuilder(animation:_pulseAnim,builder:(_,__)=>Transform.scale(
          scale:_pulseAnim.value*(.95+r),
          child:Container(
            width:bug.size, height:bug.size,
            decoration:BoxDecoration(
              shape:BoxShape.circle,
              color:_bugColor(bug.emoji).withOpacity(.15),
              boxShadow:[BoxShadow(color:_bugColor(bug.emoji).withOpacity(.6*_pulseAnim.value),blurRadius:12,spreadRadius:2)],
            ),
            child:Center(child:Text(bug.emoji,style:TextStyle(fontSize:bug.size*.55))),
          ),
        )),
      ),
    );
  }

  // ── Tap burst ─────────────────────────────────────────────────────────────

  Widget _burstWidget(_TapBurst t) => Positioned(
    left:t.x-40, top:t.y-40,
    child:IgnorePointer(child:_TapBurstWidget(color:t.color)),
  );

  // ── Countdown overlay ──────────────────────────────────────────────────────

  Widget _countdownOverlay() => Positioned.fill(
    child:Container(color:Colors.black.withOpacity(.65),child:Center(child:AnimatedBuilder(
      animation:_countScale,
      builder:(_,__)=>Transform.scale(scale:_countScale.value,child:Column(mainAxisSize:MainAxisSize.min,children:[
        Text('$_countdownVal',style:const TextStyle(color:Colors.amber,fontSize:100,fontWeight:FontWeight.bold)),
        Text({'en':'Get ready to catch bugs!','fr':'Prépare-toi à attraper des bugs !','ar':'استعد لاصطياد الحشرات!'}[_lang]!,
            style:const TextStyle(color:Colors.white,fontSize:16),textAlign:TextAlign.center),
      ])),
    ))),
  );

  // ── Wave over overlay ─────────────────────────────────────────────────────

  Widget _waveOverlay() {
    final l=_lang;
    final accuracy = _caught/max(1,_caught+_missed);
    final stars = accuracy>.8?_waves[_wi].stars:accuracy>.5?max(1,_waves[_wi].stars-1):1;
    final isLast = _wi==_waves.length-1;

    return Positioned.fill(child:Container(
      color:Colors.black.withOpacity(.75),
      child:Center(child:Container(
        margin:const EdgeInsets.all(24),
        padding:const EdgeInsets.all(24),
        decoration:BoxDecoration(color:const Color(0xFF071A10),borderRadius:BorderRadius.circular(28),
            border:Border.all(color:Colors.greenAccent.withOpacity(.5),width:2)),
        child:Column(mainAxisSize:MainAxisSize.min,children:[
          Text(accuracy>.7?'🎉':'😅',style:const TextStyle(fontSize:60)),
          const SizedBox(height:10),
          Text(accuracy>.7
              ?{'en':'Great catching!','fr':'Super attrapage !','ar':'اصطياد رائع!'}[l]!
              :{'en':'Keep practicing!','fr':'Continue à pratiquer !','ar':'استمر في التدريب!'}[l]!,
              style:const TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.bold)),
          const SizedBox(height:16),
          // stats
          Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[
            _waveStat('🎯','${_caught}',{'en':'Caught','fr':'Attrapés','ar':'مصيد'}[l]!,Colors.greenAccent),
            _waveStat('❌','${_missed}',{'en':'Missed','fr':'Ratés','ar':'فائت'}[l]!,Colors.redAccent),
            _waveStat('💯','${(accuracy*100).round()}%',{'en':'Accuracy','fr':'Précision','ar':'دقة'}[l]!,Colors.amber),
          ]),
          const SizedBox(height:16),
          // stars
          Row(mainAxisAlignment:MainAxisAlignment.center,children:List.generate(3,(i)=>
              Padding(padding:const EdgeInsets.symmetric(horizontal:4),
                  child:Icon(Icons.star_rounded,size:40,color:i<stars?Colors.amber:Colors.white24)))),
          const SizedBox(height:16),
          // tip
          Container(padding:const EdgeInsets.all(12),
              decoration:BoxDecoration(color:Colors.greenAccent.withOpacity(.08),borderRadius:BorderRadius.circular(14),border:Border.all(color:Colors.greenAccent.withOpacity(.3))),
              child:Text(_tip(l),style:const TextStyle(color:Colors.white,fontSize:13,fontStyle:FontStyle.italic),textAlign:TextAlign.center)),
          const SizedBox(height:16),
          SizedBox(width:double.infinity,child:ElevatedButton(
            onPressed:_nextWave,
            style:ElevatedButton.styleFrom(backgroundColor:Colors.greenAccent,foregroundColor:Colors.black,
                padding:const EdgeInsets.symmetric(vertical:14),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16)),
                textStyle:const TextStyle(fontSize:15,fontWeight:FontWeight.bold)),
            child:Text(isLast
                ?{'en':'🏆 Finish!','fr':'🏆 Terminer !','ar':'🏆 إنهاء!'}[l]!
                :{'en':'▶ Next Wave','fr':'▶ Vague suivante','ar':'▶ الموجة التالية'}[l]!),
          )),
        ]),
      )),
    ));
  }

  String _tip(String l) {
    final tips = {
      'en':['🖱️ In real life, moving a mouse moves the cursor!','💡 Tapping = clicking your mouse button!','🎯 The faster you click, the better your score!','👆 Practice makes perfect — just like using a real mouse!'],
      'fr':['🖱️ Bouger la souris = bouger le curseur !','💡 Taper = cliquer sur le bouton de la souris !','🎯 Plus vite tu cliques, meilleur est ton score !','👆 La pratique rend parfait — comme une vraie souris !'],
      'ar':['🖱️ تحريك الفأرة يحرك المؤشر في الحقيقة!','💡 الضغط = النقر على زر الفأرة!','🎯 كلما كنت أسرع، كان نقاطك أفضل!','👆 الممارسة تصنع الكمال — مثل الفأرة الحقيقية!'],
    };
    final list = tips[l]!;
    return list[_wi % list.length];
  }

  Widget _waveStat(String em,String val,String label,Color c)=>Column(children:[
    Text(em,style:const TextStyle(fontSize:24)),
    Text(val,style:TextStyle(color:c,fontSize:20,fontWeight:FontWeight.bold)),
    Text(label,style:const TextStyle(color:Colors.white54,fontSize:11)),
  ]);

  // ─────────────────────────────────────────────────────────────────────────
  //  WIN SCREEN
  // ─────────────────────────────────────────────────────────────────────────

  Widget _winScreen() {
    final l=_lang;
    return SingleChildScrollView(padding:const EdgeInsets.all(20),child:Column(children:[
      const SizedBox(height:16),
      const Text('🏆',style:TextStyle(fontSize:80)),
      const SizedBox(height:12),
      Text({'en':'Bug Catcher Champion! 🐛','fr':'Champion Chasseur de Bugs ! 🐛','ar':'بطل صياد الحشرات! 🐛'}[l]!,
          style:const TextStyle(color:Colors.amber,fontSize:24,fontWeight:FontWeight.bold),textAlign:TextAlign.center),
      const SizedBox(height:6),
      Text({'en':'You mastered mouse-click precision!','fr':'Tu as maîtrisé la précision du clic !','ar':'أتقنت دقة النقر بالفأرة!'}[l]!,
          style:const TextStyle(color:Colors.white70,fontSize:14),textAlign:TextAlign.center),
      const SizedBox(height:22),
      // what you learned
      Container(padding:const EdgeInsets.all(18),
          decoration:BoxDecoration(color:const Color(0xFF071A10),borderRadius:BorderRadius.circular(20),border:Border.all(color:Colors.greenAccent.withOpacity(.4))),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text({'en':'🖱️ What you practiced:','fr':'🖱️ Ce que tu as pratiqué :','ar':'🖱️ ما تدربت عليه:'}[l]!,
                style:const TextStyle(color:Colors.greenAccent,fontSize:14,fontWeight:FontWeight.bold)),
            const SizedBox(height:12),
            ...[
              {'en':'✅ Pointing accuracy — moving toward a target','fr':'✅ Précision de pointage — viser une cible','ar':'✅ دقة التأشير — التحرك نحو هدف'},
              {'en':'✅ Click timing — hitting at the right moment','fr':'✅ Timing du clic — cliquer au bon moment','ar':'✅ توقيت النقر — الضغط في اللحظة المناسبة'},
              {'en':'✅ Focus — tracking multiple moving targets','fr':'✅ Concentration — suivre plusieurs cibles','ar':'✅ التركيز — تتبع أهداف متحركة متعددة'},
              {'en':'✅ Speed — reacting quickly to what you see','fr':'✅ Vitesse — réagir rapidement','ar':'✅ السرعة — التفاعل السريع مع ما تراه'},
            ].map((m)=>Padding(padding:const EdgeInsets.only(bottom:6),child:Text(m[l]!,style:const TextStyle(color:Colors.white,fontSize:13,height:1.4)))),
          ])),
      const SizedBox(height:18),
      Container(padding:const EdgeInsets.all(16),
          decoration:BoxDecoration(color:Colors.white.withOpacity(.06),borderRadius:BorderRadius.circular(16)),
          child:Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[
            Column(children:[const Icon(Icons.star_rounded,color:Colors.amber,size:28),Text('$_totStars',style:const TextStyle(color:Colors.amber,fontWeight:FontWeight.bold,fontSize:20)),const Text('Stars',style:TextStyle(color:Colors.white54,fontSize:12))]),
            Column(children:[const Icon(Icons.bolt,color:Colors.cyanAccent,size:28),Text('$_totXp',style:const TextStyle(color:Colors.cyanAccent,fontWeight:FontWeight.bold,fontSize:20)),const Text('XP',style:TextStyle(color:Colors.white54,fontSize:12))]),
          ])),
      const SizedBox(height:20),
      SizedBox(width:double.infinity,child:ElevatedButton.icon(
        icon:const Icon(Icons.replay), label:Text({'en':'Play Again','fr':'Rejouer','ar':'العب مجدداً'}[l]!),
        onPressed:_restart,
        style:ElevatedButton.styleFrom(backgroundColor:Colors.greenAccent,foregroundColor:Colors.black,
            padding:const EdgeInsets.symmetric(vertical:15),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16)),
            textStyle:const TextStyle(fontSize:15,fontWeight:FontWeight.bold)),
      )),
      const SizedBox(height:12),
      SizedBox(width:double.infinity,child:OutlinedButton(
        onPressed:()=>Navigator.pop(context),
        style:OutlinedButton.styleFrom(foregroundColor:Colors.white70,side:const BorderSide(color:Colors.white24),
            padding:const EdgeInsets.symmetric(vertical:14),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16))),
        child:Text({'en':'← Back','fr':'← Retour','ar':'← العودة'}[l]!),
      )),
    ]));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TAP BURST WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _TapBurst { final double x,y; final Color color; _TapBurst({required this.x,required this.y,required this.color}); }

class _TapBurstWidget extends StatefulWidget {
  final Color color; const _TapBurstWidget({required this.color});
  @override State<_TapBurstWidget> createState()=>_TBWState();
}
class _TBWState extends State<_TapBurstWidget> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late List<({double angle,double speed,Color color})> _ps;
  @override void initState(){
    super.initState();
    final r=Random();
    _ps=List.generate(14,(_){final h=HSLColor.fromColor(widget.color);
    return (angle:r.nextDouble()*2*pi,speed:.3+r.nextDouble()*.7,color:h.withLightness((h.lightness+.2).clamp(0,1)).toColor());});
    _c=AnimationController(vsync:this,duration:const Duration(milliseconds:650))..forward();
  }
  @override void dispose(){_c.dispose();super.dispose();}
  @override Widget build(BuildContext ctx)=>AnimatedBuilder(animation:_c,builder:(_,__)=>CustomPaint(painter:_TBPainter(ps:_ps,t:_c.value),child:const SizedBox(width:80,height:80)));
}
class _TBPainter extends CustomPainter {
  final List<({double angle,double speed,Color color})> ps; final double t;
  const _TBPainter({required this.ps,required this.t});
  @override void paint(Canvas c,Size s){
    for(final p in ps){final d=p.speed*t*38;c.drawCircle(Offset(40+cos(p.angle)*d,40+sin(p.angle)*d),5*(1-t*.5),Paint()..color=p.color.withOpacity((1-t).clamp(0,1)));}
  }
  @override bool shouldRepaint(_TBPainter o)=>o.t!=t;
}

// ─────────────────────────────────────────────────────────────────────────────
//  GARDEN BACKGROUND PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _GardenPainter extends CustomPainter {
  static final _r = Random(55);
  @override void paint(Canvas c, Size s) {
    // sky
    c.drawRect(Rect.fromLTWH(0,0,s.width,s.height*.4), Paint()..color=const Color(0xFF0B2218));
    // ground
    c.drawRect(Rect.fromLTWH(0,s.height*.4,s.width,s.height*.6), Paint()..color=const Color(0xFF143D1A));
    // grass stripe
    c.drawRect(Rect.fromLTWH(0,s.height*.38,s.width,s.height*.07), Paint()..color=const Color(0xFF1E5C24));
    // flowers
    final fp=Paint()..color=const Color(0xFFE91E8C);
    final fp2=Paint()..color=const Color(0xFFFFEB3B);
    for(int i=0;i<12;i++){
      final x=30.0+i*(s.width-60)/11; final y=s.height*.38+8;
      c.drawCircle(Offset(x,y),6,fp); c.drawCircle(Offset(x,y),3,fp2);
    }
    // trees
    void tree(double tx,double ty){
      c.drawRect(Rect.fromLTWH(tx-4,ty,8,25),Paint()..color=const Color(0xFF4E342E));
      c.drawCircle(Offset(tx,ty),22,Paint()..color=const Color(0xFF2E7D32));
      c.drawCircle(Offset(tx-10,ty+8),14,Paint()..color=const Color(0xFF388E3C));
    }
    tree(s.width*.1,s.height*.12); tree(s.width*.85,s.height*.10); tree(s.width*.5,s.height*.05);
    // fireflies
    final glp=Paint()..color=Colors.yellowAccent.withOpacity(.7);
    for(int i=0;i<8;i++) c.drawCircle(Offset(_r.nextDouble()*s.width,_r.nextDouble()*s.height*.4),2.5,glp);
    // soil texture dots
    final sp=Paint()..color=Colors.brown.withOpacity(.15);
    for(int i=0;i<30;i++) c.drawCircle(Offset(_r.nextDouble()*s.width,s.height*.45+_r.nextDouble()*s.height*.55),2,sp);
  }
  @override bool shouldRepaint(covariant CustomPainter _)=>false;
}