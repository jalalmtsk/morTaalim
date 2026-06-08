// what_is_computer_exercise.dart
// Route: IT_WhatIsComputer
//
// ╔══════════════════════════════════════════════════════════╗
// ║  "TECH DETECTIVE" — Grade 1–2                           ║
// ║                                                          ║
// ║  A robo-detective's scanner hovers over 4 devices.      ║
// ║  The child taps the ONE that is a computer.             ║
// ║  Wrong tap → device wiggles + red X flash               ║
// ║  Correct tap → scanner locks on + green pulse +         ║
// ║               animated "WHY it's a computer" card        ║
// ║  5 progressive rounds with rotating distractor sets      ║
// ║  Localized: EN / FR / AR + RTL                          ║
// ╚══════════════════════════════════════════════════════════╝

import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../XpSystem.dart';
import '../../../../../tools/audio_tool/Audio_Manager.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DATA
// ─────────────────────────────────────────────────────────────────────────────

class _Device {
  final String id, emoji;
  final bool isComputer;
  final Map<String, String> name, whyComputer, whyNot;
  final Color color;
  const _Device({
    required this.id, required this.emoji, required this.isComputer,
    required this.name, required this.color,
    this.whyComputer = const {}, this.whyNot = const {},
  });
}

// The one true computers
const _computers = <_Device>[
  _Device(id:'desktop', emoji:'🖥️', isComputer:true, color:Color(0xFF1565C0),
    name:{'en':'Desktop Computer','fr':'Ordinateur de bureau','ar':'حاسوب مكتبي'},
    whyComputer:{'en':'It has a CPU, memory, and can run any program you want! 🧠','fr':'Il a un CPU, de la mémoire et peut faire n\'importe quoi ! 🧠','ar':'له معالج وذاكرة ويمكنه تشغيل أي برنامج! 🧠'},
  ),
  _Device(id:'laptop', emoji:'💻', isComputer:true, color:Color(0xFF1565C0),
    name:{'en':'Laptop Computer','fr':'Ordinateur portable','ar':'حاسوب محمول'},
    whyComputer:{'en':'A laptop is a portable computer — it folds and goes anywhere with you! 🎒','fr':'Un laptop est un ordinateur portable qui se plie et voyage avec toi ! 🎒','ar':'الحاسوب المحمول ينطوي ويذهب معك في كل مكان! 🎒'},
  ),
  _Device(id:'server', emoji:'🗄️', isComputer:true, color:Color(0xFF1565C0),
    name:{'en':'Server Computer','fr':'Serveur','ar':'خادم الحاسوب'},
    whyComputer:{'en':'A server is a super-powerful computer that stores websites and games! 🌐','fr':'Un serveur est un ordinateur puissant qui stocke des sites web ! 🌐','ar':'الخادم حاسوب قوي يخزن المواقع والألعاب! 🌐'},
  ),
];

// Distractors grouped by category
const _distractors = <_Device>[
  // phones & tablets
  _Device(id:'phone', emoji:'📱', isComputer:false, color:Color(0xFF6A1B9A),
    name:{'en':'Smartphone','fr':'Smartphone','ar':'هاتف ذكي'},
    whyNot:{'en':'A phone is smart, but it can\'t run all computer programs — it\'s a phone! 📞','fr':'Un smartphone est intelligent, mais ce n\'est pas un ordinateur complet ! 📞','ar':'الهاتف الذكي ذكي لكنه لا يستطيع تشغيل برامج الحاسوب! 📞'},
  ),
  _Device(id:'tablet', emoji:'📲', isComputer:false, color:Color(0xFF6A1B9A),
    name:{'en':'Tablet','fr':'Tablette','ar':'جهاز لوحي'},
    whyNot:{'en':'A tablet is great for watching videos but it\'s not a full computer! 🎬','fr':'Une tablette est super pour les vidéos mais n\'est pas un vrai ordinateur ! 🎬','ar':'الجهاز اللوحي رائع للفيديو لكنه ليس حاسوباً كاملاً! 🎬'},
  ),
  // entertainment
  _Device(id:'tv', emoji:'📺', isComputer:false, color:Color(0xFF2E7D32),
    name:{'en':'Television','fr':'Télévision','ar':'تلفاز'},
    whyNot:{'en':'A TV shows movies and cartoons — but you can\'t type or run programs on it! 🎞️','fr':'Une TV montre des films — mais tu ne peux pas taper ou coder dessus ! 🎞️','ar':'التلفاز يعرض الأفلام والكرتون لكن لا يمكنك الكتابة عليه! 🎞️'},
  ),
  _Device(id:'radio', emoji:'📻', isComputer:false, color:Color(0xFF2E7D32),
    name:{'en':'Radio','fr':'Radio','ar':'راديو'},
    whyNot:{'en':'A radio plays music and news — but it has no screen or programs! 🎵','fr':'La radio joue de la musique — mais elle n\'a ni écran ni programmes ! 🎵','ar':'الراديو يشغل الموسيقى لكن ليس له شاشة أو برامج! 🎵'},
  ),
  // kitchen / home
  _Device(id:'microwave', emoji:'📦', isComputer:false, color:Color(0xFFBF360C),
    name:{'en':'Microwave','fr':'Micro-ondes','ar':'ميكروويف'},
    whyNot:{'en':'A microwave heats food — it\'s not a computer even though it has buttons! 🍕','fr':'Un micro-ondes chauffe la nourriture — ce n\'est pas un ordinateur ! 🍕','ar':'الميكروويف يسخن الطعام — ليس حاسوباً رغم أن له أزرار! 🍕'},
  ),
  _Device(id:'fridge', emoji:'🧊', isComputer:false, color:Color(0xFF0277BD),
    name:{'en':'Refrigerator','fr':'Réfrigérateur','ar':'ثلاجة'},
    whyNot:{'en':'A fridge keeps food cold — it can\'t run programs or browse the internet! ❄️','fr':'Un frigo garde la nourriture fraîche — il ne peut pas naviguer sur internet ! ❄️','ar':'الثلاجة تحفظ الطعام بارداً — لا تستطيع تصفح الإنترنت! ❄️'},
  ),
  // toys
  _Device(id:'calculator', emoji:'🔢', isComputer:false, color:Color(0xFF4527A0),
    name:{'en':'Calculator','fr':'Calculatrice','ar':'آلة حاسبة'},
    whyNot:{'en':'A calculator only does math — a computer can do math AND write stories AND draw! ✏️','fr':'Une calculatrice fait des maths — un ordinateur fait tout ça et bien plus ! ✏️','ar':'الآلة الحاسبة تحسب الأرقام فقط — الحاسوب يفعل كل شيء! ✏️'},
  ),
  _Device(id:'camera', emoji:'📷', isComputer:false, color:Color(0xFF00695C),
    name:{'en':'Camera','fr':'Appareil photo','ar':'كاميرا'},
    whyNot:{'en':'A camera takes photos, but it can\'t run games or programs like a computer! 🖼️','fr':'Un appareil photo prend des photos, mais ne peut pas faire des jeux ! 🖼️','ar':'الكاميرا تلتقط الصور لكن لا تشغل الألعاب! 🖼️'},
  ),
];

// 5 rounds: each has 1 computer + 3 distractors
class _Round {
  final _Device computer;
  final List<_Device> distractors;
  final int stars, xp;
  final Map<String, String> title;
  const _Round({required this.computer, required this.distractors,
    required this.stars, required this.xp, required this.title});
}

// ─────────────────────────────────────────────────────────────────────────────
//  EXERCISE SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class WhatIsComputerExercise extends StatefulWidget {
  const WhatIsComputerExercise({super.key});
  @override State<WhatIsComputerExercise> createState() => _WICState();
}

class _WICState extends State<WhatIsComputerExercise>
    with TickerProviderStateMixin {

  late List<_Round> _rounds;
  int _ri = 0, _mistakes = 0, _totStars = 0, _totXp = 0;
  _Device? _tapped;   // which device was just tapped
  bool _correct = false, _showCard = false, _gameOver = false;

  // scanner beam animation
  late AnimationController _scanCtrl, _pulseCtrl, _bounceCtrl, _wrongCtrl, _cardCtrl;
  late Animation<double> _scanAnim, _pulseAnim, _bounceAnim, _wrongAnim, _cardScale;
  late ConfettiController _confetti;

  // which position is "scanning" (0-3)
  int _scanPos = 0;
  late List<_Device> _choices;
  final _rng = Random();
  String? _wrongId;

  String get _lang { final c = Localizations.localeOf(context).languageCode; return ['ar','fr'].contains(c)?c:'en'; }
  bool get _rtl => _lang == 'ar';

  @override
  void initState() {
    super.initState();
    _buildRounds();

    _scanCtrl = AnimationController(vsync:this, duration:const Duration(milliseconds:800));
    _scanAnim = Tween(begin:0.0,end:1.0).animate(CurvedAnimation(parent:_scanCtrl, curve:Curves.easeInOut));

    _pulseCtrl = AnimationController(vsync:this, duration:const Duration(milliseconds:1000))..repeat(reverse:true);
    _pulseAnim = Tween(begin:.6,end:1.0).animate(CurvedAnimation(parent:_pulseCtrl, curve:Curves.easeInOut));

    _bounceCtrl = AnimationController(vsync:this, duration:const Duration(milliseconds:700));
    _bounceAnim = Tween(begin:0.0,end:-16.0).animate(CurvedAnimation(parent:_bounceCtrl, curve:Curves.elasticOut));

    _wrongCtrl = AnimationController(vsync:this, duration:const Duration(milliseconds:400));
    _wrongAnim = TweenSequence([
      TweenSequenceItem(tween:Tween(begin:0.0,end:-10.0),weight:1),
      TweenSequenceItem(tween:Tween(begin:-10.0,end:10.0),weight:2),
      TweenSequenceItem(tween:Tween(begin:10.0,end:-7.0),weight:2),
      TweenSequenceItem(tween:Tween(begin:-7.0,end:0.0),weight:1),
    ]).animate(_wrongCtrl);

    _cardCtrl = AnimationController(vsync:this, duration:const Duration(milliseconds:400));
    _cardScale = Tween(begin:.6,end:1.0).animate(CurvedAnimation(parent:_cardCtrl, curve:Curves.elasticOut));

    _confetti = ConfettiController(duration:const Duration(seconds:3));

    _initRound();
    // start scanner sweep
    _startScan();
  }

  void _buildRounds() {
    final comps = List.from(_computers)..shuffle(_rng);
    final dists = List.from(_distractors)..shuffle(_rng);
    _rounds = List.generate(5, (i) {
      final comp = comps[i % comps.length];
      final d = <_Device>[];
      for(int j=0;j<3;j++) d.add(dists[(i*3+j)%dists.length]);
      return _Round(
        computer: comp, distractors: d,
        stars: i<2?1:i<4?2:3, xp: 15+i*10,
        title: {'en':'Round ${i+1} of 5','fr':'Tour ${i+1} sur 5','ar':'جولة ${i+1} من 5'},
      );
    });
  }

  void _initRound() {
    final r = _rounds[_ri];
    _choices = [r.computer, ...r.distractors]..shuffle(_rng);
    _tapped = null; _correct = false; _showCard = false; _wrongId = null; _mistakes = 0;
  }

  void _startScan() {
    Future.doWhile(() async {
      if (!mounted || _showCard) return false;
      await Future.delayed(const Duration(milliseconds:1200));
      if (!mounted || _showCard) return false;
      setState(() => _scanPos = (_scanPos + 1) % 4);
      _scanCtrl.forward(from:0);
      return true;
    });
  }

  @override
  void dispose() {
    _scanCtrl.dispose(); _pulseCtrl.dispose(); _bounceCtrl.dispose();
    _wrongCtrl.dispose(); _cardCtrl.dispose(); _confetti.dispose();
    super.dispose();
  }

  void _tap(_Device device) {
    if (_showCard) return;
    final audio = Provider.of<AudioManager>(context, listen:false);

    if (device.isComputer) {
      // CORRECT
      audio.playSfx('assets/audios/sound_effects/correct_anwser.mp3');
      _bounceCtrl.forward(from:0);
      setState(() { _tapped = device; _correct = true; _showCard = true; });
      _cardCtrl.forward(from:0);
      _confetti.play();
    } else {
      // WRONG
      _mistakes++;
      audio.playSfx('assets/audios/sound_effects/wrong_answer.mp3');
      setState(() { _wrongId = device.id; });
      _wrongCtrl.forward(from:0);
      Future.delayed(const Duration(milliseconds:700), () {
        if (mounted) setState(() => _wrongId = null);
      });
    }
  }

  void _nextRound() {
    final r = _rounds[_ri];
    final s = _mistakes==0?r.stars:_mistakes==1?max(1,r.stars-1):1;
    final x = _mistakes==0?r.xp:(_mistakes==1?(r.xp*.7).round():(r.xp*.4).round());
    _totStars+=s; _totXp+=x;
    final xpMgr = Provider.of<ExperienceManager>(context, listen:false);
    final audio  = Provider.of<AudioManager>(context, listen:false);
    xpMgr.addStarBanner(context, s);
    xpMgr.addXP(x, context:context);

    if (_ri < _rounds.length-1) {
      setState(() { _ri++; _initRound(); _scanPos=0; });
      _startScan();
      audio.playSfx('assets/audios/UI_Audio/SFX_Audio/victory2_SFX.mp3');
    } else {
      audio.playSfx('assets/audios/UI_Audio/SFX_Audio/victory1_SFX.mp3');
      _confetti.play();
      setState(() => _gameOver=true);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext ctx) => Directionality(
    textDirection: _rtl?TextDirection.rtl:TextDirection.ltr,
    child: Scaffold(body: Stack(children: [
      _bg(),
      SafeArea(child: _gameOver ? _winScreen() : _mainGame()),
      _confettiW(),
    ])),
  );

  Widget _bg() => Container(
    decoration: const BoxDecoration(gradient: LinearGradient(
      colors:[Color(0xFF050A15),Color(0xFF0A1628),Color(0xFF060E20)],
      begin:Alignment.topLeft, end:Alignment.bottomRight,
    )),
    child: CustomPaint(painter:_SpacePainter(), child:const SizedBox.expand()),
  );

  Widget _confettiW() => Positioned.fill(child:IgnorePointer(child:Align(
    alignment:Alignment.topCenter,
    child:ConfettiWidget(confettiController:_confetti,
        blastDirectionality:BlastDirectionality.explosive,
        emissionFrequency:.06, numberOfParticles:28, gravity:.25,
        colors:const [Color(0xFFFFD700),Color(0xFF00E5FF),Color(0xFFFF4081),Color(0xFF69F0AE),Color(0xFFE040FB)]),
  )));

  // ── MAIN GAME ─────────────────────────────────────────────────────────────

  Widget _mainGame() => Column(children:[
    _topBar(),
    const SizedBox(height:8),
    _question(),
    const SizedBox(height:12),
    _scannerBeam(),
    const SizedBox(height:8),
    Expanded(child: Stack(children:[
      _devicesGrid(),
      if (_showCard) _resultCard(),
    ])),
    const SizedBox(height:12),
  ]);

  Widget _topBar() {
    final r = _rounds[_ri];
    return Container(
      margin:const EdgeInsets.fromLTRB(12,10,12,0),
      padding:const EdgeInsets.symmetric(horizontal:14,vertical:10),
      decoration:BoxDecoration(color:Colors.white.withOpacity(.07),borderRadius:BorderRadius.circular(20),border:Border.all(color:Colors.white.withOpacity(.1))),
      child:Row(children:[
        GestureDetector(onTap:()=>Navigator.pop(context),
            child:Container(padding:const EdgeInsets.all(6),decoration:BoxDecoration(color:Colors.white.withOpacity(.1),borderRadius:BorderRadius.circular(10)),
                child:const Icon(Icons.arrow_back_ios_new,color:Colors.white70,size:16))),
        const SizedBox(width:10),
        Expanded(child:Text({'en':'🔍 Tech Detective','fr':'🔍 Détective Tech','ar':'🔍 المحقق التقني'}[_lang]!,
            style:const TextStyle(color:Colors.white,fontSize:16,fontWeight:FontWeight.bold))),
        // round pills
        Row(children:List.generate(5,(i)=>AnimatedContainer(duration:const Duration(milliseconds:300),
            margin:const EdgeInsets.only(left:4), width:i==_ri?20:8, height:8,
            decoration:BoxDecoration(borderRadius:BorderRadius.circular(4),
                color:i<_ri?Colors.greenAccent:i==_ri?Colors.amber:Colors.white24)))),
      ]),
    );
  }

  Widget _question() => Container(
    margin:const EdgeInsets.symmetric(horizontal:16),
    padding:const EdgeInsets.symmetric(horizontal:16,vertical:12),
    decoration:BoxDecoration(
      color:Colors.cyanAccent.withOpacity(.08),
      borderRadius:BorderRadius.circular(18),
      border:Border.all(color:Colors.cyanAccent.withOpacity(.3)),
    ),
    child:Row(children:[
      const Text('🤖',style:TextStyle(fontSize:28)),
      const SizedBox(width:12),
      Expanded(child:Text(
        {'en':'Which one is a COMPUTER? Tap it!',
          'fr':'Lequel est un ORDINATEUR ? Tape dessus !',
          'ar':'أيٌّ من هذه هو الحاسوب؟ اضغط عليه!'}[_lang]!,
        style:const TextStyle(color:Colors.cyanAccent,fontSize:15,fontWeight:FontWeight.bold),
      )),
      // mistake counter
      Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:4),
          decoration:BoxDecoration(color:_mistakes>0?Colors.redAccent.withOpacity(.2):Colors.transparent,borderRadius:BorderRadius.circular(10)),
          child:Row(children:[
            Icon(Icons.close,color:_mistakes>0?Colors.redAccent:Colors.white30,size:14),
            Text(' $_mistakes',style:TextStyle(color:_mistakes>0?Colors.redAccent:Colors.white30,fontSize:13,fontWeight:FontWeight.bold)),
          ])),
    ]),
  );

  // ── Scanner beam decoration ───────────────────────────────────────────────

  Widget _scannerBeam() => AnimatedBuilder(
    animation:_pulseAnim,
    builder:(_,__)=>Container(
      margin:const EdgeInsets.symmetric(horizontal:24),
      height:4,
      decoration:BoxDecoration(
        borderRadius:BorderRadius.circular(2),
        color:Colors.cyanAccent.withOpacity(.25),
      ),
      child:FractionallySizedBox(
        widthFactor:.25,
        alignment:Alignment((_scanPos/1.5)-1,0),
        child:Container(
          decoration:BoxDecoration(
            borderRadius:BorderRadius.circular(2),
            color:Colors.cyanAccent.withOpacity(_pulseAnim.value),
            boxShadow:[BoxShadow(color:Colors.cyanAccent.withOpacity(.6*_pulseAnim.value),blurRadius:8)],
          ),
        ),
      ),
    ),
  );

  // ── Devices grid ──────────────────────────────────────────────────────────

  Widget _devicesGrid() => GridView.builder(
    padding:const EdgeInsets.symmetric(horizontal:16),
    gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:2, mainAxisSpacing:14, crossAxisSpacing:14, childAspectRatio:.95),
    itemCount:4,
    itemBuilder:(_,i)=>_deviceCard(_choices[i], i),
  );

  Widget _deviceCard(_Device d, int idx) {
    final isWrong = _wrongId==d.id;
    final isCorrectTapped = _tapped?.id==d.id && _correct;

    return AnimatedBuilder(
      animation:_wrongAnim,
      builder:(_,child)=>Transform.translate(offset:Offset(isWrong?_wrongAnim.value:0,0),child:child),
      child:GestureDetector(
        onTap:()=>_tap(d),
        child:AnimatedContainer(
          duration:const Duration(milliseconds:250),
          decoration:BoxDecoration(
            borderRadius:BorderRadius.circular(22),
            color:isCorrectTapped?const Color(0xFF1565C0).withOpacity(.3)
                :isWrong?Colors.redAccent.withOpacity(.2)
                :Colors.white.withOpacity(.07),
            border:Border.all(
                width:2,
                color:isCorrectTapped?Colors.cyanAccent
                    :isWrong?Colors.redAccent
                    :Colors.white.withOpacity(.15)),
            boxShadow:isCorrectTapped?[const BoxShadow(color:Colors.cyanAccent,blurRadius:18,spreadRadius:1)]:
            isWrong?[BoxShadow(color:Colors.redAccent.withOpacity(.4),blurRadius:12)]:null,
          ),
          child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
            // scanner indicator
            if (!_showCard) AnimatedBuilder(animation:_pulseAnim,builder:(_,__)=>Icon(
                _scanPos==idx?Icons.document_scanner:Icons.radio_button_unchecked,
                color:_scanPos==idx?Colors.cyanAccent.withOpacity(_pulseAnim.value):Colors.white12,
                size:16)),
            const SizedBox(height:6),
            // device emoji
            Text(d.emoji,style:const TextStyle(fontSize:52)),
            const SizedBox(height:8),
            // name
            Padding(padding:const EdgeInsets.symmetric(horizontal:6),
                child:Text(d.name[_lang]!,
                    style:const TextStyle(color:Colors.white,fontSize:12,fontWeight:FontWeight.w600),
                    textAlign:TextAlign.center,maxLines:2,overflow:TextOverflow.ellipsis)),
            // wrong X
            if (isWrong) const Padding(padding:EdgeInsets.only(top:4),
                child:Icon(Icons.cancel,color:Colors.redAccent,size:20)),
            // correct check
            if (isCorrectTapped) const Padding(padding:EdgeInsets.only(top:4),
                child:Icon(Icons.verified,color:Colors.cyanAccent,size:20)),
          ]),
        ),
      ),
    );
  }

  // ── Result / explanation card ─────────────────────────────────────────────

  Widget _resultCard() {
    final l = _lang;
    final device = _tapped!;
    final isLast = _ri==_rounds.length-1;

    return Positioned.fill(child:Container(
      color:Colors.black.withOpacity(.7),
      child:Center(child:AnimatedBuilder(
        animation:_cardScale,
        builder:(_,__)=>Transform.scale(scale:_cardScale.value,child:Container(
          margin:const EdgeInsets.all(20),
          decoration:BoxDecoration(
            color:const Color(0xFF0A1628),
            borderRadius:BorderRadius.circular(28),
            border:Border.all(color:Colors.cyanAccent,width:2.5),
            boxShadow:[const BoxShadow(color:Colors.cyanAccent,blurRadius:20,spreadRadius:1)],
          ),
          child:Column(mainAxisSize:MainAxisSize.min,children:[
            // header
            Container(
              width:double.infinity,
              padding:const EdgeInsets.symmetric(vertical:16,horizontal:20),
              decoration:const BoxDecoration(
                color:Color(0xFF0D2040),
                borderRadius:BorderRadius.only(topLeft:Radius.circular(26),topRight:Radius.circular(26)),
              ),
              child:Row(children:[
                Text(device.emoji,style:const TextStyle(fontSize:40)),
                const SizedBox(width:12),
                Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:3),
                      decoration:BoxDecoration(color:Colors.greenAccent.withOpacity(.2),borderRadius:BorderRadius.circular(20),border:Border.all(color:Colors.greenAccent.withOpacity(.5))),
                      child:Text({'en':'✅ YES! This is a computer!','fr':'✅ OUI ! C\'est un ordinateur !','ar':'✅ نعم! هذا هو الحاسوب!'}[l]!,
                          style:const TextStyle(color:Colors.greenAccent,fontSize:12,fontWeight:FontWeight.bold))),
                  const SizedBox(height:4),
                  Text(device.name[l]!,style:const TextStyle(color:Colors.white,fontSize:18,fontWeight:FontWeight.bold)),
                ])),
              ]),
            ),
            // explanation
            Padding(padding:const EdgeInsets.all(18),child:Column(children:[
              Container(width:double.infinity,padding:const EdgeInsets.all(14),
                  decoration:BoxDecoration(color:Colors.cyanAccent.withOpacity(.08),borderRadius:BorderRadius.circular(16),border:Border.all(color:Colors.cyanAccent.withOpacity(.3))),
                  child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                    Row(children:[
                      const Text('💡',style:TextStyle(fontSize:18)),
                      const SizedBox(width:8),
                      Text({'en':'Why is it a computer?','fr':'Pourquoi c\'est un ordinateur ?','ar':'لماذا هو حاسوب؟'}[l]!,
                          style:const TextStyle(color:Colors.cyanAccent,fontSize:13,fontWeight:FontWeight.bold)),
                    ]),
                    const SizedBox(height:8),
                    Text(device.whyComputer[l]!,style:const TextStyle(color:Colors.white,fontSize:14,height:1.5)),
                  ])),
              const SizedBox(height:12),
              // "A computer can..." checklist
              Container(width:double.infinity,padding:const EdgeInsets.all(14),
                  decoration:BoxDecoration(color:Colors.amber.withOpacity(.08),borderRadius:BorderRadius.circular(16),border:Border.all(color:Colors.amber.withOpacity(.3))),
                  child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                    Text({'en':'A computer can...','fr':'Un ordinateur peut...','ar':'الحاسوب يستطيع...'}[l]!,
                        style:const TextStyle(color:Colors.amber,fontSize:13,fontWeight:FontWeight.bold)),
                    const SizedBox(height:8),
                    ...[
                      {'en':'🧠 Think and solve problems','fr':'🧠 Penser et résoudre des problèmes','ar':'🧠 التفكير وحل المسائل'},
                      {'en':'💾 Store information','fr':'💾 Stocker des informations','ar':'💾 تخزين المعلومات'},
                      {'en':'🖥️ Show things on a screen','fr':'🖥️ Afficher des choses sur un écran','ar':'🖥️ عرض الأشياء على الشاشة'},
                      {'en':'📡 Connect to the internet','fr':'📡 Se connecter à internet','ar':'📡 الاتصال بالإنترنت'},
                    ].map((m)=>Padding(padding:const EdgeInsets.only(bottom:4),
                        child:Text(m[l]!,style:const TextStyle(color:Colors.white70,fontSize:13)))),
                  ])),
            ])),
            // next button
            Padding(padding:const EdgeInsets.fromLTRB(20,0,20,20),
                child:SizedBox(width:double.infinity,child:ElevatedButton(
                  onPressed:_nextRound,
                  style:ElevatedButton.styleFrom(backgroundColor:Colors.cyanAccent,foregroundColor:Colors.black,
                      padding:const EdgeInsets.symmetric(vertical:14),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16)),
                      textStyle:const TextStyle(fontSize:15,fontWeight:FontWeight.bold)),
                  child:Text(isLast
                      ?{'en':'🏆 Finish!','fr':'🏆 Terminer !','ar':'🏆 إنهاء!'}[l]!
                      :{'en':'▶ Next Round','fr':'▶ Tour suivant','ar':'▶ الجولة التالية'}[l]!),
                ))),
          ]),
        )),
      )),
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  WIN SCREEN
  // ─────────────────────────────────────────────────────────────────────────

  Widget _winScreen() {
    final l = _lang;
    return SingleChildScrollView(padding:const EdgeInsets.all(20),child:Column(children:[
      const SizedBox(height:16),
      const Text('🕵️',style:TextStyle(fontSize:80)),
      const SizedBox(height:12),
      Text({'en':'Master Detective! 🏆','fr':'Maître Détective ! 🏆','ar':'المحقق الخبير! 🏆'}[l]!,
          style:const TextStyle(color:Colors.amber,fontSize:26,fontWeight:FontWeight.bold),textAlign:TextAlign.center),
      const SizedBox(height:6),
      Text({'en':'You can identify computers like a pro!','fr':'Tu identifies les ordinateurs comme un pro !','ar':'تستطيع التعرف على الحواسيب كالمحترفين!'}[l]!,
          style:const TextStyle(color:Colors.white70,fontSize:14),textAlign:TextAlign.center),
      const SizedBox(height:24),
      // recap — what IS a computer
      Container(padding:const EdgeInsets.all(18),
          decoration:BoxDecoration(color:const Color(0xFF0D2040),borderRadius:BorderRadius.circular(20),border:Border.all(color:Colors.cyanAccent.withOpacity(.4))),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text({'en':'🖥️ What makes something a computer?','fr':'🖥️ Qu\'est-ce qui fait un ordinateur ?','ar':'🖥️ ما الذي يجعل شيئاً ما حاسوباً؟'}[l]!,
                style:const TextStyle(color:Colors.cyanAccent,fontSize:14,fontWeight:FontWeight.bold)),
            const SizedBox(height:12),
            ...[
              {'en':'1️⃣  It has a CPU (brain) that thinks','fr':'1️⃣  Il a un CPU (cerveau) qui réfléchit','ar':'1️⃣  له معالج (عقل) يفكر'},
              {'en':'2️⃣  It has memory to remember things','fr':'2️⃣  Il a de la mémoire pour se souvenir','ar':'2️⃣  له ذاكرة لحفظ الأشياء'},
              {'en':'3️⃣  It can run different programs','fr':'3️⃣  Il peut lancer différents programmes','ar':'3️⃣  يستطيع تشغيل برامج مختلفة'},
              {'en':'4️⃣  It can connect to the internet','fr':'4️⃣  Il peut se connecter à internet','ar':'4️⃣  يستطيع الاتصال بالإنترنت'},
            ].map((m)=>Padding(padding:const EdgeInsets.only(bottom:8),
                child:Text(m[l]!,style:const TextStyle(color:Colors.white,fontSize:14,height:1.4)))),
          ])),
      const SizedBox(height:20),
      Container(padding:const EdgeInsets.all(16),
          decoration:BoxDecoration(color:Colors.white.withOpacity(.06),borderRadius:BorderRadius.circular(16)),
          child:Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[
            _wStat(Icons.star_rounded,Colors.amber,'$_totStars ⭐'),
            _wStat(Icons.bolt,Colors.cyanAccent,'$_totXp XP'),
          ])),
      const SizedBox(height:20),
      SizedBox(width:double.infinity,child:ElevatedButton.icon(
        icon:const Icon(Icons.replay), label:Text({'en':'Play Again','fr':'Rejouer','ar':'العب مجدداً'}[l]!),
        onPressed:(){setState((){_ri=0;_totStars=0;_totXp=0;_gameOver=false;_buildRounds();_initRound();_scanPos=0;});_startScan();},
        style:ElevatedButton.styleFrom(backgroundColor:Colors.cyanAccent,foregroundColor:Colors.black,
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

  Widget _wStat(IconData i,Color c,String t)=>Row(children:[Icon(i,color:c,size:22),const SizedBox(width:6),Text(t,style:TextStyle(color:c,fontWeight:FontWeight.bold,fontSize:16))]);
}

// ─────────────────────────────────────────────────────────────────────────────
//  SPACE BACKGROUND PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _SpacePainter extends CustomPainter {
  static final _r = Random(77);
  static final _stars = List.generate(80, (_) => Offset(_r.nextDouble(), _r.nextDouble()));
  static final _sizes = List.generate(80, (_) => .5+_r.nextDouble()*2.0);
  @override void paint(Canvas c, Size s) {
    final p = Paint()..color=Colors.white.withOpacity(.18);
    for(int i=0;i<_stars.length;i++) c.drawCircle(Offset(_stars[i].dx*s.width,_stars[i].dy*s.height),_sizes[i],p);
    // nebula hint
    c.drawCircle(Offset(s.width*.8,s.height*.2),s.width*.2,Paint()..color=Colors.cyanAccent.withOpacity(.04));
    c.drawCircle(Offset(s.width*.15,s.height*.7),s.width*.18,Paint()..color=Colors.purpleAccent.withOpacity(.05));
  }
  @override bool shouldRepaint(covariant CustomPainter _)=>false;
}