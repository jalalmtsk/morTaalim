// input_output_exercise.dart
// Route: IT_InputOutput
//
// ╔══════════════════════════════════════════════════════════╗
// ║  "THE COMPUTER FACTORY" — Grade 1–2                    ║
// ║                                                          ║
// ║  A cartoon factory has two glowing conveyor belts:      ║
// ║  🟦 INPUT  — devices that SEND data IN (keyboard, mic)  ║
// ║  🟨 OUTPUT — devices that SEND data OUT (monitor, spkr) ║
// ║                                                          ║
// ║  Device cards fly in from the top, one at a time.       ║
// ║  Child drags (or taps a side button) to sort them.      ║
// ║  Correct → belt animates, Robo cheers                   ║
// ║  Wrong   → card bounces back, Robo explains             ║
// ║  3 rounds — more cards, more speed                      ║
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

enum _IOType { input, output }

class _IODevice {
  final String id, emoji;
  final _IOType type;
  final Map<String, String> name, explanation;
  const _IODevice({
    required this.id, required this.emoji, required this.type,
    required this.name, required this.explanation,
  });
}

const _devices = <_IODevice>[
  // ── INPUTS ──────────────────────────────────────────────────────────────
  _IODevice(id:'keyboard', emoji:'⌨️', type:_IOType.input,
    name:{'en':'Keyboard','fr':'Clavier','ar':'لوحة المفاتيح'},
    explanation:{'en':'You TYPE on it → data goes INTO the computer! ✍️','fr':'Tu tapes dessus → les données ENTRENT dans l\'ordi ! ✍️','ar':'تكتب عليها → البيانات تدخل الحاسوب! ✍️'},
  ),
  _IODevice(id:'mouse', emoji:'🖱️', type:_IOType.input,
    name:{'en':'Mouse','fr':'Souris','ar':'الفأرة'},
    explanation:{'en':'You CLICK and MOVE it → commands go INTO the computer! 🖱️','fr':'Tu cliques et bouges → les commandes ENTRENT dans l\'ordi ! 🖱️','ar':'تنقر وتحرك → الأوامر تدخل الحاسوب! 🖱️'},
  ),
  _IODevice(id:'microphone', emoji:'🎤', type:_IOType.input,
    name:{'en':'Microphone','fr':'Microphone','ar':'ميكروفون'},
    explanation:{'en':'You SPEAK into it → your voice goes INTO the computer! 🎤','fr':'Tu parles dedans → ta voix ENTRE dans l\'ordi ! 🎤','ar':'تتحدث فيه → صوتك يدخل الحاسوب! 🎤'},
  ),
  _IODevice(id:'webcam', emoji:'📷', type:_IOType.input,
    name:{'en':'Webcam','fr':'Webcam','ar':'كاميرا الويب'},
    explanation:{'en':'It RECORDS your face → images go INTO the computer! 📷','fr':'Elle filme ton visage → les images ENTRENT dans l\'ordi ! 📷','ar':'تسجل وجهك → الصور تدخل الحاسوب! 📷'},
  ),
  _IODevice(id:'scanner', emoji:'🖨️', type:_IOType.input,
    name:{'en':'Scanner','fr':'Scanner','ar':'الماسح الضوئي'},
    explanation:{'en':'It READS paper documents → sends them INTO the computer! 📄','fr':'Il LIT les documents → les envoie dans l\'ordi ! 📄','ar':'يقرأ الوثائق الورقية → يرسلها إلى الحاسوب! 📄'},
  ),
  // ── OUTPUTS ─────────────────────────────────────────────────────────────
  _IODevice(id:'monitor', emoji:'🖥️', type:_IOType.output,
    name:{'en':'Monitor','fr':'Écran','ar':'الشاشة'},
    explanation:{'en':'The computer SHOWS images OUT on the screen! 🖥️','fr':'L\'ordi AFFICHE les images vers l\'écran ! 🖥️','ar':'الحاسوب يُظهر الصور على الشاشة! 🖥️'},
  ),
  _IODevice(id:'speaker', emoji:'🔊', type:_IOType.output,
    name:{'en':'Speaker','fr':'Haut-parleur','ar':'مكبر الصوت'},
    explanation:{'en':'The computer sends SOUND OUT through the speaker! 🎵','fr':'L\'ordi envoie du SON par le haut-parleur ! 🎵','ar':'الحاسوب يرسل الصوت من خلال مكبر الصوت! 🎵'},
  ),
  _IODevice(id:'printer', emoji:'📠', type:_IOType.output,
    name:{'en':'Printer','fr':'Imprimante','ar':'الطابعة'},
    explanation:{'en':'The computer sends a document OUT to be printed! 🖨️','fr':'L\'ordi envoie un document vers l\'imprimante ! 🖨️','ar':'الحاسوب يرسل المستند للطباعة! 🖨️'},
  ),
  _IODevice(id:'headphones', emoji:'🎧', type:_IOType.output,
    name:{'en':'Headphones','fr':'Casque','ar':'سماعات الرأس'},
    explanation:{'en':'Sound goes OUT of the computer into your ears! 👂','fr':'Le son sort de l\'ordi dans tes oreilles ! 👂','ar':'الصوت يخرج من الحاسوب إلى أذنيك! 👂'},
  ),
  _IODevice(id:'projector', emoji:'📽️', type:_IOType.output,
    name:{'en':'Projector','fr':'Projecteur','ar':'جهاز العرض'},
    explanation:{'en':'The computer sends images OUT to the projector wall! 📽️','fr':'L\'ordi envoie des images vers le projecteur ! 📽️','ar':'الحاسوب يرسل الصور إلى جهاز العرض! 📽️'},
  ),
];

class _Round {
  final List<String> deviceIds;
  final int stars, xp;
  final Map<String, String> name;
  const _Round({required this.deviceIds, required this.stars, required this.xp, required this.name});
}

const _rounds = [
  _Round(deviceIds:['keyboard','monitor','mouse','speaker'],           stars:1,xp:20,name:{'en':'Level 1 🌱','fr':'Niveau 1 🌱','ar':'المستوى 1 🌱'}),
  _Round(deviceIds:['keyboard','monitor','mouse','speaker','microphone','printer'], stars:2,xp:35,name:{'en':'Level 2 🚀','fr':'Niveau 2 🚀','ar':'المستوى 2 🚀'}),
  _Round(deviceIds:['keyboard','monitor','mouse','speaker','microphone','printer','webcam','headphones','scanner','projector'], stars:3,xp:60,name:{'en':'Level 3 🏆','fr':'Niveau 3 🏆','ar':'المستوى 3 🏆'}),
];

// ─────────────────────────────────────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class InputOutputExercise extends StatefulWidget {
  const InputOutputExercise({super.key});
  @override State<InputOutputExercise> createState() => _IOState();
}

class _IOState extends State<InputOutputExercise> with TickerProviderStateMixin {

  int _ri = 0;
  late List<_IODevice> _queue;
  int _qi = 0;              // index into queue
  int _correct = 0, _mistakes = 0, _totStars = 0, _totXp = 0;
  bool _showResult = false, _gameOver = false;
  String? _feedbackType; // 'correct'|'wrong'
  _IODevice? _feedbackDevice;

  // belt animations
  late AnimationController _inputBeltCtrl, _outputBeltCtrl, _cardDropCtrl, _wrongCtrl, _cardCtrl;
  late Animation<double> _inputBeltAnim, _outputBeltAnim, _cardDropAnim, _wrongAnim, _cardScale;
  late AnimationController _bounceCtrl, _pulseCtrl;
  late Animation<double> _bounceAnim, _pulseAnim;
  late ConfettiController _confetti;

  // drag state
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;

  String get _lang { final c = Localizations.localeOf(context).languageCode; return ['ar','fr'].contains(c)?c:'en'; }
  bool get _rtl => _lang == 'ar';

  _IODevice? get _current => _qi < _queue.length ? _queue[_qi] : null;

  @override
  void initState() {
    super.initState();

    _inputBeltCtrl = AnimationController(vsync:this, duration:const Duration(milliseconds:600));
    _inputBeltAnim = Tween(begin:0.0,end:1.0).animate(_inputBeltCtrl);

    _outputBeltCtrl = AnimationController(vsync:this, duration:const Duration(milliseconds:600));
    _outputBeltAnim = Tween(begin:0.0,end:1.0).animate(_outputBeltCtrl);

    _cardDropCtrl = AnimationController(vsync:this, duration:const Duration(milliseconds:500));
    _cardDropAnim = Tween(begin:-1.0,end:0.0).animate(CurvedAnimation(parent:_cardDropCtrl,curve:Curves.bounceOut));

    _wrongCtrl = AnimationController(vsync:this, duration:const Duration(milliseconds:450));
    _wrongAnim = TweenSequence([
      TweenSequenceItem(tween:Tween(begin:0.0,end:-14.0),weight:1),
      TweenSequenceItem(tween:Tween(begin:-14.0,end:14.0),weight:2),
      TweenSequenceItem(tween:Tween(begin:14.0,end:-10.0),weight:2),
      TweenSequenceItem(tween:Tween(begin:-10.0,end:0.0),weight:1),
    ]).animate(_wrongCtrl);

    _cardCtrl = AnimationController(vsync:this, duration:const Duration(milliseconds:380));
    _cardScale = Tween(begin:.6,end:1.0).animate(CurvedAnimation(parent:_cardCtrl,curve:Curves.elasticOut));

    _bounceCtrl = AnimationController(vsync:this, duration:const Duration(milliseconds:600));
    _bounceAnim = Tween(begin:0.0,end:-16.0).animate(CurvedAnimation(parent:_bounceCtrl,curve:Curves.elasticOut));

    _pulseCtrl = AnimationController(vsync:this, duration:const Duration(milliseconds:900))..repeat(reverse:true);
    _pulseAnim = Tween(begin:.85,end:1.0).animate(CurvedAnimation(parent:_pulseCtrl,curve:Curves.easeInOut));

    _confetti = ConfettiController(duration:const Duration(seconds:3));

    _initRound();
  }

  void _initRound() {
    final r = _rounds[_ri];
    _queue = _devices.where((d)=>r.deviceIds.contains(d.id)).toList()..shuffle(Random());
    _qi = 0; _correct = 0; _mistakes = 0;
    _showResult = false; _feedbackType = null; _feedbackDevice = null;
    _cardDropCtrl.forward(from:0);
  }

  @override
  void dispose() {
    _inputBeltCtrl.dispose(); _outputBeltCtrl.dispose(); _cardDropCtrl.dispose();
    _wrongCtrl.dispose(); _cardCtrl.dispose(); _bounceCtrl.dispose();
    _pulseCtrl.dispose(); _confetti.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  GAME LOGIC
  // ─────────────────────────────────────────────────────────────────────────

  void _sort(_IOType guess) {
    final device = _current;
    if (device == null || _feedbackType != null) return;
    final audio = Provider.of<AudioManager>(context, listen:false);

    if (guess == device.type) {
      // CORRECT
      audio.playSfx('assets/audios/sound_effects/correct_anwser.mp3');
      _correct++;
      if (guess == _IOType.input) { _inputBeltCtrl.forward(from:0); }
      else { _outputBeltCtrl.forward(from:0); }
      _bounceCtrl.forward(from:0);
      setState(() { _feedbackType='correct'; _feedbackDevice=device; });
      _cardCtrl.forward(from:0);
      Future.delayed(const Duration(milliseconds:1400), _advance);
    } else {
      // WRONG
      audio.playSfx('assets/audios/sound_effects/wrong_answer.mp3');
      _mistakes++;
      _wrongCtrl.forward(from:0);
      setState(() { _feedbackType='wrong'; _feedbackDevice=device; });
      _cardCtrl.forward(from:0);
      Future.delayed(const Duration(milliseconds:2000), _advance);
    }
  }

  void _advance() {
    if (!mounted) return;
    setState(() { _qi++; _feedbackType=null; _feedbackDevice=null; });
    if (_qi >= _queue.length) {
      _roundDone();
    } else {
      _cardDropCtrl.forward(from:0);
    }
  }

  void _roundDone() {
    final r = _rounds[_ri];
    final s = _mistakes==0?r.stars:_mistakes<=2?max(1,r.stars-1):1;
    final x = _mistakes==0?r.xp:(_mistakes<=2?(r.xp*.65).round():(r.xp*.35).round());
    _totStars+=s; _totXp+=x;
    final xpMgr = Provider.of<ExperienceManager>(context, listen:false);
    final audio  = Provider.of<AudioManager>(context, listen:false);
    xpMgr.addStarBanner(context, s);
    xpMgr.addXP(x, context:context);
    audio.playSfx('assets/audios/UI_Audio/SFX_Audio/victory1_SFX.mp3');
    _confetti.play();
    setState(() => _showResult=true);
  }

  void _nextRound() {
    if (_ri < _rounds.length-1) {
      setState(() { _ri++; _initRound(); });
    } else {
      setState(() => _gameOver=true);
      _confetti.play();
    }
  }

  void _restart() => setState((){
    _ri=0; _totStars=0; _totXp=0; _gameOver=false; _initRound();
  });

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext ctx) => Directionality(
    textDirection:_rtl?TextDirection.rtl:TextDirection.ltr,
    child:Scaffold(body:Stack(children:[
      _bg(),
      SafeArea(child:_gameOver?_winScreen():_showResult?_resultScreen():_mainGame()),
      _confettiW(),
    ])),
  );

  Widget _bg() => Container(
    decoration:const BoxDecoration(gradient:LinearGradient(
        colors:[Color(0xFF0A0A1A),Color(0xFF111130),Color(0xFF0A0A1A)],
        begin:Alignment.topLeft, end:Alignment.bottomRight)),
    child:CustomPaint(painter:_FactoryBgPainter(),child:const SizedBox.expand()),
  );

  Widget _confettiW() => Positioned.fill(child:IgnorePointer(child:Align(alignment:Alignment.topCenter,
    child:ConfettiWidget(confettiController:_confetti,blastDirectionality:BlastDirectionality.explosive,
        emissionFrequency:.06,numberOfParticles:28,gravity:.25,
        colors:const [Color(0xFF00E5FF),Color(0xFFFFD700),Color(0xFFFF4081),Color(0xFF69F0AE)]),
  )));

  // ─────────────────────────────────────────────────────────────────────────
  //  MAIN GAME
  // ─────────────────────────────────────────────────────────────────────────

  Widget _mainGame() => Column(children:[
    _topBar(),
    const SizedBox(height:6),
    _progressBar(),
    const SizedBox(height:10),
    _factoryScene(),
    const SizedBox(height:8),
    _sortButtons(),
    const SizedBox(height:14),
  ]);

  Widget _topBar() {
    final r=_rounds[_ri];
    return Container(
      margin:const EdgeInsets.fromLTRB(12,10,12,0),
      padding:const EdgeInsets.symmetric(horizontal:14,vertical:10),
      decoration:BoxDecoration(color:Colors.white.withOpacity(.07),borderRadius:BorderRadius.circular(20),border:Border.all(color:Colors.white.withOpacity(.1))),
      child:Row(children:[
        GestureDetector(onTap:()=>Navigator.pop(context),
            child:Container(padding:const EdgeInsets.all(6),decoration:BoxDecoration(color:Colors.white.withOpacity(.1),borderRadius:BorderRadius.circular(10)),
                child:const Icon(Icons.arrow_back_ios_new,color:Colors.white70,size:16))),
        const SizedBox(width:10),
        Expanded(child:Text({'en':'🏭 The Computer Factory','fr':'🏭 L\'Usine Informatique','ar':'🏭 مصنع الحاسوب'}[_lang]!,
            style:const TextStyle(color:Colors.white,fontSize:15,fontWeight:FontWeight.bold))),
        Text(r.name[_lang]!,style:const TextStyle(color:Colors.amber,fontSize:12,fontWeight:FontWeight.bold)),
      ]),
    );
  }

  Widget _progressBar() => Padding(
    padding:const EdgeInsets.symmetric(horizontal:16),
    child:Column(children:[
      Row(children:[
        Text('$_correct',style:const TextStyle(color:Colors.greenAccent,fontSize:18,fontWeight:FontWeight.bold)),
        Text(' / ${_queue.length}',style:const TextStyle(color:Colors.white54,fontSize:13)),
        const Spacer(),
        Text({'en':'Sorted correctly','fr':'Triés correctement','ar':'مُرتَّب بشكل صحيح'}[_lang]!,
            style:const TextStyle(color:Colors.white38,fontSize:12,fontStyle:FontStyle.italic)),
      ]),
      const SizedBox(height:5),
      ClipRRect(borderRadius:BorderRadius.circular(8),child:TweenAnimationBuilder<double>(
        tween:Tween(begin:0,end:_queue.isEmpty?0:_qi/_queue.length),
        duration:const Duration(milliseconds:400),
        builder:(_,v,__)=>LinearProgressIndicator(value:v,minHeight:8,backgroundColor:Colors.white10,
            valueColor:const AlwaysStoppedAnimation(Colors.cyanAccent)),
      )),
    ]),
  );

  // ─────────────────────────────────────────────────────────────────────────
  //  FACTORY SCENE
  // ─────────────────────────────────────────────────────────────────────────

  Widget _factoryScene() => Expanded(child:Container(
    margin:const EdgeInsets.symmetric(horizontal:12),
    decoration:BoxDecoration(
      borderRadius:BorderRadius.circular(24),
      color:Colors.white.withOpacity(.04),
      border:Border.all(color:Colors.white.withOpacity(.08)),
    ),
    child:Stack(children:[
      Positioned.fill(child:ClipRRect(borderRadius:BorderRadius.circular(24),
          child:CustomPaint(painter:_FactoryScenePainter(inputAnim:_inputBeltAnim,outputAnim:_outputBeltAnim)))),

      // INPUT belt label (left)
      Positioned(left:12,top:12,child:_beltLabel(_IOType.input)),

      // OUTPUT belt label (right)
      Positioned(right:12,top:12,child:_beltLabel(_IOType.output)),

      // centre device card
      if (_current != null && _feedbackType==null)
        Positioned.fill(child:Center(child:_deviceCard(_current!))),

      // feedback card
      if (_feedbackType != null && _feedbackDevice != null)
        Positioned.fill(child:Center(child:_feedbackCard(_feedbackDevice!))),
    ]),
  ));

  Widget _beltLabel(_IOType t) {
    final isInput = t==_IOType.input;
    final color = isInput?Colors.cyanAccent:Colors.amberAccent;
    final icon  = isInput?'📥':'📤';
    final label = isInput
        ?{'en':'INPUT','fr':'ENTRÉE','ar':'إدخال'}[_lang]!
        :{'en':'OUTPUT','fr':'SORTIE','ar':'إخراج'}[_lang]!;
    return Container(
      padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),
      decoration:BoxDecoration(
        color:color.withOpacity(.15),
        borderRadius:BorderRadius.circular(12),
        border:Border.all(color:color.withOpacity(.5)),
      ),
      child:Column(children:[
        Text(icon,style:const TextStyle(fontSize:18)),
        Text(label,style:TextStyle(color:color,fontSize:11,fontWeight:FontWeight.bold)),
      ]),
    );
  }

  Widget _deviceCard(_IODevice d) {
    return AnimatedBuilder(
      animation:_cardDropAnim,
      builder:(_,__)=>Transform.translate(
        offset:Offset(0,_cardDropAnim.value*80),
        child:GestureDetector(
          onHorizontalDragEnd:(details){
            if (details.primaryVelocity==null) return;
            if (details.primaryVelocity! < -100) _sort(_rtl?_IOType.output:_IOType.input);
            else if (details.primaryVelocity! > 100) _sort(_rtl?_IOType.input:_IOType.output);
          },
          child:AnimatedBuilder(animation:_pulseAnim,builder:(_,__)=>Transform.scale(
            scale:_pulseAnim.value,
            child:Container(
              width:170, padding:const EdgeInsets.all(18),
              decoration:BoxDecoration(
                color:const Color(0xFF111130),
                borderRadius:BorderRadius.circular(22),
                border:Border.all(color:Colors.cyanAccent.withOpacity(.5),width:2),
                boxShadow:[BoxShadow(color:Colors.cyanAccent.withOpacity(.3),blurRadius:20)],
              ),
              child:Column(mainAxisSize:MainAxisSize.min,children:[
                Text(d.emoji,style:const TextStyle(fontSize:56)),
                const SizedBox(height:10),
                Text(d.name[_lang]!,style:const TextStyle(color:Colors.white,fontSize:15,fontWeight:FontWeight.bold),textAlign:TextAlign.center),
                const SizedBox(height:8),
                Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:4),
                    decoration:BoxDecoration(color:Colors.white.withOpacity(.06),borderRadius:BorderRadius.circular(10)),
                    child:Text({'en':'← Drag to sort →','fr':'← Glisse pour trier →','ar':'← اسحب للفرز →'}[_lang]!,
                        style:const TextStyle(color:Colors.white38,fontSize:11))),
              ]),
            ),
          )),
        ),
      ),
    );
  }

  Widget _feedbackCard(_IODevice d) {
    final isCorrect = _feedbackType=='correct';
    final color = isCorrect?Colors.greenAccent:Colors.redAccent;
    final icon  = isCorrect?'✅':'❌';

    return AnimatedBuilder(animation:_cardScale,builder:(_,__)=>Transform.scale(
      scale:_cardScale.value,
      child:AnimatedBuilder(animation:_wrongAnim,builder:(_,ch)=>Transform.translate(
        offset:Offset(isCorrect?0:_wrongAnim.value,0),
        child:Container(
          margin:const EdgeInsets.all(20),
          padding:const EdgeInsets.all(18),
          decoration:BoxDecoration(
            color:const Color(0xFF0A0A20),
            borderRadius:BorderRadius.circular(24),
            border:Border.all(color:color,width:2.5),
            boxShadow:[BoxShadow(color:color.withOpacity(.35),blurRadius:20)],
          ),
          child:Column(mainAxisSize:MainAxisSize.min,children:[
            Text(icon,style:const TextStyle(fontSize:44)),
            const SizedBox(height:8),
            Text(d.emoji,style:const TextStyle(fontSize:36)),
            const SizedBox(height:6),
            Text(d.name[_lang]!,style:TextStyle(color:color,fontSize:16,fontWeight:FontWeight.bold),textAlign:TextAlign.center),
            const SizedBox(height:10),
            Container(padding:const EdgeInsets.all(12),
              decoration:BoxDecoration(color:color.withOpacity(.1),borderRadius:BorderRadius.circular(14),border:Border.all(color:color.withOpacity(.3))),
              child:Column(children:[
                // INPUT/OUTPUT badge
                Container(margin:const EdgeInsets.only(bottom:6),
                    padding:const EdgeInsets.symmetric(horizontal:10,vertical:3),
                    decoration:BoxDecoration(color:d.type==_IOType.input?Colors.cyanAccent.withOpacity(.2):Colors.amberAccent.withOpacity(.2),
                        borderRadius:BorderRadius.circular(20),
                        border:Border.all(color:d.type==_IOType.input?Colors.cyanAccent:Colors.amberAccent)),
                    child:Text(d.type==_IOType.input
                        ?{'en':'📥 INPUT device','fr':'📥 Appareil d\'ENTRÉE','ar':'📥 جهاز إدخال'}[_lang]!
                        :{'en':'📤 OUTPUT device','fr':'📤 Appareil de SORTIE','ar':'📤 جهاز إخراج'}[_lang]!,
                        style:TextStyle(color:d.type==_IOType.input?Colors.cyanAccent:Colors.amberAccent,fontSize:12,fontWeight:FontWeight.bold))),
                Text(d.explanation[_lang]!,style:const TextStyle(color:Colors.white,fontSize:13,height:1.4),textAlign:TextAlign.center),
              ]),
            ),
          ]),
        ),
      )),
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  SORT BUTTONS (tap alternative to drag)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _sortButtons() => Padding(
    padding:const EdgeInsets.symmetric(horizontal:14),
    child:Row(children:[
      Expanded(child:_sortBtn(_IOType.input)),
      const SizedBox(width:16),
      Expanded(child:_sortBtn(_IOType.output)),
    ]),
  );

  Widget _sortBtn(_IOType t) {
    final isInput=t==_IOType.input;
    final color=isInput?Colors.cyanAccent:Colors.amberAccent;
    final icon=isInput?'📥':'📤';
    final label=isInput
        ?{'en':'INPUT\nData comes IN','fr':'ENTRÉE\nDonnées entrent','ar':'إدخال\nالبيانات تدخل'}[_lang]!
        :{'en':'OUTPUT\nData goes OUT','fr':'SORTIE\nDonnées sortent','ar':'إخراج\nالبيانات تخرج'}[_lang]!;
    return GestureDetector(
      onTap:()=>_sort(t),
      child:AnimatedContainer(
        duration:const Duration(milliseconds:150),
        padding:const EdgeInsets.symmetric(vertical:16),
        decoration:BoxDecoration(
          color:color.withOpacity(.12),
          borderRadius:BorderRadius.circular(20),
          border:Border.all(color:color.withOpacity(.5),width:2),
        ),
        child:Column(children:[
          Text(icon,style:const TextStyle(fontSize:30)),
          const SizedBox(height:6),
          Text(label,style:TextStyle(color:color,fontSize:13,fontWeight:FontWeight.bold,height:1.3),textAlign:TextAlign.center),
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  RESULT SCREEN
  // ─────────────────────────────────────────────────────────────────────────

  Widget _resultScreen() {
    final l=_lang; final r=_rounds[_ri]; final isLast=_ri==_rounds.length-1;
    final stars=_mistakes==0?r.stars:_mistakes<=2?max(1,r.stars-1):1;
    return Center(child:SingleChildScrollView(child:Container(
      margin:const EdgeInsets.all(20),
      padding:const EdgeInsets.all(26),
      decoration:BoxDecoration(color:const Color(0xFF0A0A1E).withOpacity(.98),
          borderRadius:BorderRadius.circular(30),border:Border.all(color:Colors.cyanAccent.withOpacity(.5),width:2)),
      child:Column(mainAxisSize:MainAxisSize.min,children:[
        const Text('🏭',style:TextStyle(fontSize:60)),
        const SizedBox(height:10),
        Text({'en':'Level Complete! 🎉','fr':'Niveau terminé ! 🎉','ar':'اكتمل المستوى! 🎉'}[l]!,
            style:const TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.bold),textAlign:TextAlign.center),
        const SizedBox(height:18),
        Row(mainAxisAlignment:MainAxisAlignment.center,children:List.generate(r.stars,(i)=>
            Padding(padding:const EdgeInsets.symmetric(horizontal:4),
                child:Icon(Icons.star_rounded,size:44,color:i<stars?Colors.amber:Colors.white24)))),
        const SizedBox(height:18),
        Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[
          _rStat('✅','$_correct',{'en':'Correct','fr':'Corrects','ar':'صحيح'}[l]!,Colors.greenAccent),
          _rStat('❌','$_mistakes',{'en':'Mistakes','fr':'Erreurs','ar':'أخطاء'}[l]!,Colors.redAccent),
        ]),
        const SizedBox(height:22),
        SizedBox(width:double.infinity,child:ElevatedButton(
          onPressed:_nextRound,
          style:ElevatedButton.styleFrom(backgroundColor:Colors.cyanAccent,foregroundColor:Colors.black,
              padding:const EdgeInsets.symmetric(vertical:14),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16)),
              textStyle:const TextStyle(fontSize:15,fontWeight:FontWeight.bold)),
          child:Text(isLast?{'en':'🏆 Finish!','fr':'🏆 Terminer !','ar':'🏆 إنهاء!'}[l]!
              :{'en':'▶ Next Level','fr':'▶ Niveau suivant','ar':'▶ المستوى التالي'}[l]!),
        )),
      ]),
    )));
  }

  Widget _rStat(String e,String v,String l,Color c)=>Column(children:[
    Text(e,style:const TextStyle(fontSize:24)),
    Text(v,style:TextStyle(color:c,fontSize:22,fontWeight:FontWeight.bold)),
    Text(l,style:const TextStyle(color:Colors.white54,fontSize:12)),
  ]);

  // ─────────────────────────────────────────────────────────────────────────
  //  WIN SCREEN
  // ─────────────────────────────────────────────────────────────────────────

  Widget _winScreen() {
    final l=_lang;
    return SingleChildScrollView(padding:const EdgeInsets.all(20),child:Column(children:[
      const SizedBox(height:12),
      const Text('🏭',style:TextStyle(fontSize:80)),
      const SizedBox(height:10),
      Text({'en':'Factory Manager! 🏆','fr':'Gestionnaire d\'Usine ! 🏆','ar':'مدير المصنع! 🏆'}[l]!,
          style:const TextStyle(color:Colors.amber,fontSize:25,fontWeight:FontWeight.bold),textAlign:TextAlign.center),
      const SizedBox(height:8),
      Text({'en':'You sorted all devices perfectly!','fr':'Tu as trié tous les appareils !','ar':'فرزت جميع الأجهزة بشكل مثالي!'}[l]!,
          style:const TextStyle(color:Colors.white70,fontSize:14),textAlign:TextAlign.center),
      const SizedBox(height:22),
      // full device guide
      Container(padding:const EdgeInsets.all(16),
          decoration:BoxDecoration(color:Colors.cyanAccent.withOpacity(.07),borderRadius:BorderRadius.circular(20),border:Border.all(color:Colors.cyanAccent.withOpacity(.3))),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text({'en':'📥 INPUT devices (data goes IN):','fr':'📥 Appareils d\'ENTRÉE :','ar':'📥 أجهزة الإدخال (البيانات تدخل):'}[l]!,
                style:const TextStyle(color:Colors.cyanAccent,fontSize:13,fontWeight:FontWeight.bold)),
            const SizedBox(height:8),
            Wrap(spacing:8,runSpacing:8,children:_devices.where((d)=>d.type==_IOType.input).map((d)=>Container(
              padding:const EdgeInsets.symmetric(horizontal:10,vertical:5),
              decoration:BoxDecoration(color:Colors.cyanAccent.withOpacity(.1),borderRadius:BorderRadius.circular(20),border:Border.all(color:Colors.cyanAccent.withOpacity(.3))),
              child:Text('${d.emoji} ${d.name[l]}',style:const TextStyle(color:Colors.cyanAccent,fontSize:12,fontWeight:FontWeight.bold)),
            )).toList()),
            const SizedBox(height:14),
            Text({'en':'📤 OUTPUT devices (data goes OUT):','fr':'📤 Appareils de SORTIE :','ar':'📤 أجهزة الإخراج (البيانات تخرج):'}[l]!,
                style:const TextStyle(color:Colors.amberAccent,fontSize:13,fontWeight:FontWeight.bold)),
            const SizedBox(height:8),
            Wrap(spacing:8,runSpacing:8,children:_devices.where((d)=>d.type==_IOType.output).map((d)=>Container(
              padding:const EdgeInsets.symmetric(horizontal:10,vertical:5),
              decoration:BoxDecoration(color:Colors.amberAccent.withOpacity(.1),borderRadius:BorderRadius.circular(20),border:Border.all(color:Colors.amberAccent.withOpacity(.3))),
              child:Text('${d.emoji} ${d.name[l]}',style:const TextStyle(color:Colors.amberAccent,fontSize:12,fontWeight:FontWeight.bold)),
            )).toList()),
          ])),
      const SizedBox(height:18),
      Container(padding:const EdgeInsets.all(16),
          decoration:BoxDecoration(color:Colors.white.withOpacity(.05),borderRadius:BorderRadius.circular(16)),
          child:Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[
            Column(children:[const Icon(Icons.star_rounded,color:Colors.amber,size:28),Text('$_totStars',style:const TextStyle(color:Colors.amber,fontWeight:FontWeight.bold,fontSize:20)),const Text('Stars',style:TextStyle(color:Colors.white54,fontSize:12))]),
            Column(children:[const Icon(Icons.bolt,color:Colors.cyanAccent,size:28),Text('$_totXp',style:const TextStyle(color:Colors.cyanAccent,fontWeight:FontWeight.bold,fontSize:20)),const Text('XP',style:TextStyle(color:Colors.white54,fontSize:12))]),
          ])),
      const SizedBox(height:20),
      SizedBox(width:double.infinity,child:ElevatedButton.icon(
        icon:const Icon(Icons.replay),label:Text({'en':'Play Again','fr':'Rejouer','ar':'العب مجدداً'}[l]!),
        onPressed:_restart,
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
}

// ─────────────────────────────────────────────────────────────────────────────
//  FACTORY BACKGROUND PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _FactoryBgPainter extends CustomPainter {
  @override void paint(Canvas c, Size s) {
    // grid lines
    final gp=Paint()..color=Colors.white.withOpacity(.04)..strokeWidth=.8;
    for(double x=0;x<s.width;x+=40) c.drawLine(Offset(x,0),Offset(x,s.height),gp);
    for(double y=0;y<s.height;y+=40) c.drawLine(Offset(0,y),Offset(s.width,y),gp);
    // corner circuits
    final cp=Paint()..color=Colors.cyanAccent.withOpacity(.07)..strokeWidth=1.5;
    c.drawLine(const Offset(0,30),const Offset(60,30),cp);
    c.drawLine(const Offset(60,30),const Offset(60,0),cp);
    c.drawCircle(const Offset(60,30),4,Paint()..color=Colors.cyanAccent.withOpacity(.3));
  }
  @override bool shouldRepaint(covariant CustomPainter _)=>false;
}

// ─────────────────────────────────────────────────────────────────────────────
//  FACTORY SCENE PAINTER (belts, machine body)
// ─────────────────────────────────────────────────────────────────────────────

class _FactoryScenePainter extends CustomPainter {
  final Animation<double> inputAnim, outputAnim;
  const _FactoryScenePainter({required this.inputAnim, required this.outputAnim});

  @override void paint(Canvas c, Size s) {
    final w=s.width, h=s.height;

    // ── central machine ───────────────────────────────────────────────────
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w*.3,h*.25,w*.4,h*.5),const Radius.circular(12)),
        Paint()..color=const Color(0xFF1A1A3A));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w*.3,h*.25,w*.4,h*.5),const Radius.circular(12)),
        Paint()..color=Colors.cyanAccent.withOpacity(.15)..style=PaintingStyle.stroke..strokeWidth=1.5);
    // machine screen
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w*.34,h*.30,w*.32,h*.18),const Radius.circular(6)),
        Paint()..color=const Color(0xFF0A1628));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w*.35,h*.31,w*.30,h*.16),const Radius.circular(5)),
        Paint()..color=const Color(0xFF1565C0).withOpacity(.4));
    // machine logo
    c.drawCircle(Offset(w*.5,h*.39),w*.04,Paint()..color=Colors.cyanAccent.withOpacity(.6));
    c.drawCircle(Offset(w*.5,h*.39),w*.025,Paint()..color=const Color(0xFF0A1628));
    // gear dots
    for(int i=0;i<6;i++){
      final a=i*pi/3;
      c.drawCircle(Offset(w*.5+cos(a)*w*.055,h*.39+sin(a)*h*.055),w*.012,Paint()..color=Colors.cyanAccent.withOpacity(.4));
    }
    // status lights
    c.drawCircle(Offset(w*.38,h*.52),w*.015,Paint()..color=Colors.greenAccent);
    c.drawCircle(Offset(w*.5,h*.52),w*.015,Paint()..color=Colors.amber.withOpacity(.8));
    c.drawCircle(Offset(w*.62,h*.52),w*.015,Paint()..color=Colors.cyanAccent.withOpacity(.8));
    // slots
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w*.33,h*.58,w*.13,h*.06),const Radius.circular(4)),
        Paint()..color=Colors.cyanAccent.withOpacity(.25));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w*.54,h*.58,w*.13,h*.06),const Radius.circular(4)),
        Paint()..color=Colors.amberAccent.withOpacity(.25));

    // ── INPUT belt (left) ─────────────────────────────────────────────────
    _belt(c,Rect.fromLTWH(0,h*.38,w*.3,h*.24),Colors.cyanAccent,inputAnim.value,true);

    // ── OUTPUT belt (right) ───────────────────────────────────────────────
    _belt(c,Rect.fromLTWH(w*.7,h*.38,w*.3,h*.24),Colors.amberAccent,outputAnim.value,false);
  }

  void _belt(Canvas c, Rect r, Color col, double anim, bool ltr) {
    // belt body
    c.drawRRect(RRect.fromRectAndRadius(r,const Radius.circular(8)), Paint()..color=col.withOpacity(.1));
    c.drawRRect(RRect.fromRectAndRadius(r,const Radius.circular(8)), Paint()..color=col.withOpacity(.4)..style=PaintingStyle.stroke..strokeWidth=1.5);
    // moving stripes
    final sp=Paint()..color=col.withOpacity(.25+anim*.3)..strokeWidth=3;
    final stripeW=r.width/5;
    for(int i=-1;i<6;i++){
      final offset=ltr?(i*stripeW+anim*stripeW)%(r.width+stripeW)-stripeW
          :(r.width-(i*stripeW+anim*stripeW)%(r.width+stripeW));
      c.drawLine(Offset(r.left+offset,r.top+4),Offset(r.left+offset,r.bottom-4),sp);
    }
    // rollers
    c.drawCircle(Offset(r.left+10,r.center.dy),10,Paint()..color=col.withOpacity(.3));
    c.drawCircle(Offset(r.right-10,r.center.dy),10,Paint()..color=col.withOpacity(.3));
    // glow on activation
    if(anim>0.1){
      c.drawRRect(RRect.fromRectAndRadius(r,const Radius.circular(8)),
          Paint()..color=col.withOpacity(.12*anim)..maskFilter=const MaskFilter.blur(BlurStyle.normal,8));
    }
  }

  @override bool shouldRepaint(_FactoryScenePainter o)=>true; // repaints for belt animation
}