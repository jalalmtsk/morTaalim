import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import 'package:mortaalim/tools/Ads_Manager.dart';
import '../../XpSystem.dart';

// ═══════════════════════════════════════════════════════════════
//  🎹 PIANO TILES — KIDS EDITION
//  Brighter palette · userStatutBar · Banner + Interstitial ads
//  XP rewards · Back button with confirmation · All 9 tile types
// ═══════════════════════════════════════════════════════════════

// ─── BRIGHT KIDS PALETTE ─────────────────────────────────────
class Pal {
  // BG: warm cream instead of cold white
  static const bg        = Color(0xFFFFF8F0);
  static const hud       = Color(0xFFFFFFFF);
  static const hudShadow = Color(0x14000000);
  static const playBg    = Color(0xFFFFF3E8);
  static const divider   = Color(0xFFFFD8B0);
  static const hitZone   = Color(0xFFFFF0DC);
  static const hitBorder = Color(0xFFFFB347);

  // Tile colours — vivid, child-friendly
  static const tileBlack  = Color(0xFF3D2B8C); // rich indigo
  static const tileBlackH = Color(0xFF7C5CBF);
  static const tileRed    = Color(0xFFFF3D5A);
  static const tileRedH   = Color(0xFFFF8A9A);
  static const tileHold   = Color(0xFF00BFA5);
  static const tileHoldF  = Color(0xFF64FFDA);
  static const tileDouble = Color(0xFFFF8F00);
  static const tileDoubleT= Color(0xFFFFD740);
  static const tileShield = Color(0xFF8E24AA);
  static const tileShieldT= Color(0xFFE040FB);
  static const tileBomb   = Color(0xFF37474F);
  static const tileBombH  = Color(0xFFFF6D00);
  static const tileGhost  = Color(0xFF78909C);
  static const tileBonus  = Color(0xFF2E7D32);
  static const tileBonusT = Color(0xFFA5D6A7);
  static const tileFreeze = Color(0xFF0288D1);
  static const tileFreezeT= Color(0xFFB3E5FC);
  static const heart      = Color(0xFFFF4081);
  static const heartEmpty = Color(0xFFFFCDD2);
  static const comboBg    = Color(0xFF6C63FF);
  static const comboTxt   = Color(0xFFFFFFFF);
  static const speedBar   = Color(0xFFFF8F00);
  static const missFlash  = Color(0xFFFF5252);
  static const accent     = Color(0xFF6C63FF);

  static Color particleFor(TileKind k) => switch(k) {
    TileKind.black  => const Color(0xFF7C5CBF),
    TileKind.red    => const Color(0xFFFF5252),
    TileKind.hold   => const Color(0xFF64FFDA),
    TileKind.double_=> const Color(0xFFFFD740),
    TileKind.shield => const Color(0xFFE040FB),
    TileKind.bomb   => const Color(0xFFFF6D00),
    TileKind.ghost  => const Color(0xFFB0BEC5),
    TileKind.bonus  => const Color(0xFFA5D6A7),
    TileKind.freeze => const Color(0xFFB3E5FC),
    TileKind.empty  => Colors.white,
  };
}

// ─── CONSTANTS ───────────────────────────────────────────────
const int    kCols        = 4;
const double kTileH       = 108.0;
const double kGap         = 4.0;
const double kHitZoneH    = 86.0;
const double kRadius      = 12.0;
const double kHoldFrames  = 16.0;
const double kSpeedStart  = 1.8;
const double kSpeedCap    = 5.5;
const double kSpeedRamp   = 0.012;
const double kFreezeSpeed = 1.2;

// ─── TILE KINDS ──────────────────────────────────────────────
enum TileKind { black, hold, red, double_, shield, bomb, ghost, bonus, freeze, empty }

// ─── PARTICLE ────────────────────────────────────────────────
class _Particle {
  _Particle(double cx, double cy, Color color, Random rng)
      : x=cx, y=cy,
        vx=(rng.nextDouble()-.5)*7,
        vy=(rng.nextDouble()-.5)*7-2.5,
        r=rng.nextDouble()*4+2,
        color=color;
  double x,y,vx,vy,r,life=1.0;
  final Color color;
  bool update(){x+=vx;y+=vy;vy+=0.2;life-=0.042;return life>0;}
}

// ─── RIPPLE ──────────────────────────────────────────────────
class _Ripple {
  _Ripple(this.x,this.y,this.color);
  double x,y,radius=5,life=1.0;
  final Color color;
  bool update(){radius+=5;life-=0.07;return life>0;}
}

// ─── MISS FLASH ──────────────────────────────────────────────
class _MissFlash {
  _MissFlash(this.rect);
  final Rect rect; double alpha=1.0;
  bool update(){alpha-=0.07;return alpha>0;}
}

// ─── TILE ────────────────────────────────────────────────────
class GameTile {
  GameTile({required this.col,required this.kind,required this.y});
  final int col; final TileKind kind; double y;
  bool hit=false,missed=false,redTouched=false;
  double hitAlpha=1.0,tapFlash=0.0;
  bool holding=false,holdCompleted=false; double holdProgress=0.0;
  int bombTaps=0; bool bombDone=false;
  double ghostAlpha=1.0;

  bool get isDone => hit||missed||holdCompleted||
      (kind==TileKind.red&&redTouched)||bombDone;

  Rect rect(double colW)=>Rect.fromLTWH(col*colW+kGap,y+kGap,colW-kGap*2,kTileH-kGap*2);
}

// ─── HAPTIC ──────────────────────────────────────────────────
void _light()  => HapticFeedback.lightImpact();
void _medium() => HapticFeedback.mediumImpact();
void _heavy()  => HapticFeedback.heavyImpact();
void _select() => HapticFeedback.selectionClick();
void _vibe()   => HapticFeedback.vibrate();

// ─── GAME STATE ──────────────────────────────────────────────
class PianoGameState extends ChangeNotifier {
  final Random _rng=Random();
  List<GameTile>   tiles=[];
  List<_Particle>  particles=[];
  List<_Ripple>    ripples=[];
  List<_MissFlash> missFlashes=[];

  int    score=0,lives=3,multiplier=1,combo=0,bestScore=0;
  double speed=kSpeedStart,_spawnAccum=0,_spawnInterval=210;

  bool running=false,gameOver=false,started=false;
  bool doubleActive=false,shieldActive=false,freezeActive=false;
  Timer? _doubleTimer,_shieldTimer,_freezeTimer;
  String? comboMessage; Timer? _comboMsgTimer;
  final Map<int,GameTile?> _held={};

  void startGame(){
    tiles.clear();particles.clear();ripples.clear();missFlashes.clear();
    score=0;lives=3;multiplier=1;combo=0;
    speed=kSpeedStart;_spawnAccum=0;_spawnInterval=210;
    running=true;gameOver=false;started=true;
    doubleActive=false;shieldActive=false;freezeActive=false;
    _doubleTimer?.cancel();_shieldTimer?.cancel();_freezeTimer?.cancel();
    comboMessage=null;_comboMsgTimer?.cancel();_held.clear();
    _medium();notifyListeners();
  }

  void tick(double canvasH,double canvasW){
    if(!running) return;
    final colW=canvasW/kCols;
    final effectiveSpeed=freezeActive?kFreezeSpeed:speed;

    for(final t in tiles){
      if(t.isDone){
        if(t.tapFlash>0) t.tapFlash=(t.tapFlash-0.06).clamp(0,1);
        if(t.hitAlpha>0) t.hitAlpha=(t.hitAlpha-0.055).clamp(0,1);
        continue;
      }
      if(!t.holding) t.y+=effectiveSpeed;

      if(t.kind==TileKind.ghost&&!t.hit){
        t.ghostAlpha=(t.ghostAlpha-0.008).clamp(0,1);
        if(t.ghostAlpha<=0){t.missed=true;_onMiss();}
      }

      if(t.kind==TileKind.hold&&t.holding){
        t.holdProgress=(t.holdProgress+1/kHoldFrames).clamp(0,1);
        if(t.holdProgress>=1.0){
          t.holdCompleted=true;t.holding=false;t.tapFlash=1.0;t.hitAlpha=1.0;
          _burst(t.col*colW+colW/2,t.y+kTileH/2,TileKind.hold,10);
          _scorePoint(bonus:1);_medium();
        }
      }

      if(!t.missed&&t.kind!=TileKind.empty&&t.kind!=TileKind.red){
        if(t.y>canvasH+10){
          t.missed=true;
          missFlashes.add(_MissFlash(Rect.fromLTWH(
              t.col*colW+kGap,canvasH-kHitZoneH+kGap,colW-kGap*2,kHitZoneH-kGap*2)));
          _onMiss();
        }
      }
      if(t.kind==TileKind.red&&t.y>canvasH+10&&!t.redTouched) t.missed=true;
    }

    particles =particles .where((p)=>p.update()).toList();
    ripples   =ripples   .where((r)=>r.update()).toList();
    missFlashes=missFlashes.where((f)=>f.update()).toList();

    tiles.removeWhere((t)=>
    t.y>canvasH+30||(t.isDone&&t.hitAlpha<=0&&t.tapFlash<=0));

    _spawnAccum+=effectiveSpeed;
    if(_spawnAccum>=_spawnInterval){_spawnAccum=0;_spawnRow();}

    speed=(kSpeedStart+score*kSpeedRamp).clamp(kSpeedStart,kSpeedCap);
    _spawnInterval=(210-score*1.2).clamp(115,210);

    notifyListeners();
  }

  void _spawnRow(){
    final roll=_rng.nextDouble();
    int specCol=-1; TileKind specKind=TileKind.empty;

    if      (score>3  &&roll<0.06) {specKind=TileKind.hold;   specCol=_rng.nextInt(kCols);}
    else if (score>4  &&roll<0.14) {specKind=TileKind.red;    specCol=_rng.nextInt(kCols);}
    else if (score>6  &&roll<0.20) {specKind=TileKind.bomb;   specCol=_rng.nextInt(kCols);}
    else if (score>8  &&roll<0.25) {specKind=TileKind.double_;specCol=_rng.nextInt(kCols);}
    else if (score>10 &&roll<0.29) {specKind=TileKind.shield; specCol=_rng.nextInt(kCols);}
    else if (score>12 &&roll<0.33) {specKind=TileKind.ghost;  specCol=_rng.nextInt(kCols);}
    else if (score>5  &&roll<0.37) {specKind=TileKind.bonus;  specCol=_rng.nextInt(kCols);}
    else if (score>15 &&roll<0.40) {specKind=TileKind.freeze; specCol=_rng.nextInt(kCols);}

    final twoBlack=_rng.nextDouble()<(0.10+score*0.003).clamp(0,0.35);
    final shuffled=List.generate(kCols,(i)=>i)..shuffle(_rng);
    final blackCols=shuffled.where((c)=>c!=specCol).take(twoBlack?2:1).toSet();

    for(int c=0;c<kCols;c++){
      TileKind kind=TileKind.empty;
      if(c==specCol) kind=specKind;
      else if(blackCols.contains(c)) kind=TileKind.black;
      tiles.add(GameTile(col:c,kind:kind,y:-kTileH));
    }
  }

  void pointerDown(int pid,Offset pos,Size playSize){
    if(!running) return;
    final colW=playSize.width/kCols;
    GameTile? target;
    for(final t in tiles){
      if(t.isDone||t.kind==TileKind.empty) continue;
      if(t.rect(colW).contains(pos)){
        if(target==null||t.y>target.y) target=t;
      }
    }
    if(target!=null){
      _held[pid]=target;
      _activateTile(target,pos,colW,playSize.height);
    } else {
      _held[pid]=null;
      missFlashes.add(_MissFlash(Rect.fromLTWH(pos.dx-30,pos.dy-20,60,40)));
      _onMiss(isWrongTap:true);
    }
  }

  void pointerUp(int pid){
    final t=_held.remove(pid);
    if(t!=null&&t.kind==TileKind.hold&&t.holding){
      t.holding=false;
      if(t.holdProgress<1.0){t.missed=true;_onMiss();}
    }
    notifyListeners();
  }

  void _activateTile(GameTile t,Offset pos,double colW,double canvasH){
    final cx=t.col*colW+colW/2;
    final cy=t.y+kTileH/2;

    if(t.kind==TileKind.red){
      t.redTouched=true;t.tapFlash=1.0;t.hitAlpha=1.0;
      _burst(cx,cy,TileKind.red,14);
      ripples.add(_Ripple(cx,cy,Pal.tileRed));
      _heavy();_onMiss(isRed:true);return;
    }
    if(t.kind==TileKind.hold){
      t.holding=true;t.tapFlash=1.0;t.hitAlpha=1.0;_light();return;
    }
    if(t.kind==TileKind.bomb){
      t.bombTaps++;
      _burst(cx,cy,TileKind.bomb,6);
      ripples.add(_Ripple(cx,cy,Pal.tileBombH));
      _light();
      if(t.bombTaps>=2){
        t.bombDone=true;t.tapFlash=1.0;t.hitAlpha=1.0;
        _burst(cx,cy,TileKind.bomb,18);
        _medium();_scorePoint(bonus:1);
      }
      return;
    }
    if(t.kind==TileKind.ghost){
      t.hit=true;t.tapFlash=1.0;t.hitAlpha=1.0;
      _burst(cx,cy,TileKind.ghost,8);
      ripples.add(_Ripple(cx,cy,Pal.tileGhost));
      _light();_scorePoint(bonus:1);return;
    }
    if(t.kind==TileKind.bonus){
      t.hit=true;t.tapFlash=1.0;t.hitAlpha=1.0;
      _burst(cx,cy,TileKind.bonus,12);
      ripples.add(_Ripple(cx,cy,Pal.tileBonus));
      _medium();_scorePoint(bonus:2);
      _showCombo('+3 BONUS! ⭐');return;
    }
    if(t.kind==TileKind.freeze){
      t.hit=true;t.tapFlash=1.0;t.hitAlpha=1.0;
      _burst(cx,cy,TileKind.freeze,12);
      ripples.add(_Ripple(cx,cy,Pal.tileFreeze));
      _select();_activateFreeze();return;
    }

    t.hit=true;t.tapFlash=1.0;t.hitAlpha=1.0;
    _burst(cx,cy,t.kind,8);
    ripples.add(_Ripple(cx,cy,Pal.particleFor(t.kind)));
    _light();

    if(t.kind==TileKind.double_) _activateDouble();
    else if(t.kind==TileKind.shield) _activateShield();
    else _scorePoint();
  }

  void _burst(double cx,double cy,TileKind kind,int count){
    final c=Pal.particleFor(kind);
    for(int i=0;i<count;i++) particles.add(_Particle(cx,cy,c,_rng));
  }

  void _scorePoint({int bonus=0}){
    final pts=(doubleActive?multiplier*2:multiplier)+bonus;
    score+=pts;combo++;
    if(combo%5==0){
      multiplier=(multiplier+1).clamp(1,8);
      _showCombo('×$multiplier COMBO! 🔥');_medium();
    }
  }

  void _onMiss({bool isRed=false,bool isWrongTap=false}){
    if(shieldActive&&!isRed){
      shieldActive=false;_shieldTimer?.cancel();
      _showCombo('SHIELD BLOCKED! 🛡️');_select();return;
    }
    combo=0;multiplier=1;
    lives=(lives-1).clamp(0,3);
    _heavy();notifyListeners();
    if(lives<=0) _endGame();
  }

  void _activateDouble(){
    doubleActive=true;_doubleTimer?.cancel();
    _showCombo('2× POINTS! ⚡');
    _doubleTimer=Timer(const Duration(seconds:5),(){doubleActive=false;notifyListeners();});
  }
  void _activateShield(){
    shieldActive=true;_shieldTimer?.cancel();
    _showCombo('SHIELD ON! 🛡️');
    _shieldTimer=Timer(const Duration(seconds:5),(){shieldActive=false;notifyListeners();});
  }
  void _activateFreeze(){
    freezeActive=true;_freezeTimer?.cancel();
    _showCombo('❄️ FREEZE!');
    _freezeTimer=Timer(const Duration(seconds:4),(){freezeActive=false;notifyListeners();});
  }

  void _showCombo(String msg){
    comboMessage=msg;notifyListeners();
    _comboMsgTimer?.cancel();
    _comboMsgTimer=Timer(const Duration(milliseconds:1300),(){comboMessage=null;notifyListeners();});
  }

  void _endGame(){
    running=false;gameOver=true;
    if(score>bestScore) bestScore=score;
    _doubleTimer?.cancel();_shieldTimer?.cancel();_freezeTimer?.cancel();
    _held.clear();_vibe();notifyListeners();
  }

  @override
  void dispose(){
    _doubleTimer?.cancel();_shieldTimer?.cancel();
    _freezeTimer?.cancel();_comboMsgTimer?.cancel();
    super.dispose();
  }
}

// ─── ENTRY WIDGET ────────────────────────────────────────────
class PianoTilesBoard extends StatelessWidget {
  const PianoTilesBoard({super.key});
  @override
  Widget build(BuildContext context) => const _PianoTilesGame();
}

// ─── ROOT GAME WIDGET ────────────────────────────────────────
class _PianoTilesGame extends StatefulWidget {
  const _PianoTilesGame();
  @override
  State<_PianoTilesGame> createState()=>_PianoTilesGameState();
}

class _PianoTilesGameState extends State<_PianoTilesGame>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {

  late final PianoGameState _state;
  late final Ticker          _ticker;
  Size _lastSize=Size.zero;

  // ── Ads ────────────────────────────────────────────────────
  BannerAd? _bannerAd;
  bool      _bannerLoaded=false;

  @override
  void initState(){
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _state=PianoGameState();
    _ticker=createTicker((_){
      if(_state.running&&_lastSize!=Size.zero)
        _state.tick(_lastSize.height,_lastSize.width);
    });
    _ticker.start();
    _loadBannerAd();
  }

  @override
  void dispose(){
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _state.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state){
    if(state==AppLifecycleState.resumed) _loadBannerAd();
  }

  void _loadBannerAd(){
    _bannerAd?.dispose(); _bannerLoaded=false;
    if(!mounted) return;
    if(!Provider.of<ExperienceManager>(context,listen:false).adsEnabled) return;
    _bannerAd=AdHelper.getBannerAd((){
      if(mounted) setState(()=>_bannerLoaded=true);
    });
  }

  // ── Quit confirmation ───────────────────────────────────────
  Future<bool> _confirmQuit() async {
    // Pause the game while dialog is open
    _state.running=false;
    final quit=await showDialog<bool>(
      context:context, barrierDismissible:true,
      builder:(_)=>Dialog(
        backgroundColor:Colors.transparent,
        child:Container(
          padding:const EdgeInsets.all(26),
          decoration:BoxDecoration(
            gradient:const LinearGradient(
                colors:[Color(0xFF6C63FF),Color(0xFF3D2B8C)],
                begin:Alignment.topLeft,end:Alignment.bottomRight),
            borderRadius:BorderRadius.circular(28),
            boxShadow:[BoxShadow(
                color:const Color(0xFF6C63FF).withOpacity(0.45),
                blurRadius:28)],
          ),
          child:Column(mainAxisSize:MainAxisSize.min,children:[
            const Text('🎹',style:TextStyle(fontSize:48)),
            const SizedBox(height:8),
            const Text('Quit this game?',textAlign:TextAlign.center,
                style:TextStyle(fontFamily:'Fredoka One',
                    fontSize:22,color:Colors.white)),
            const SizedBox(height:6),
            Text('Your score will be lost!',textAlign:TextAlign.center,
                style:TextStyle(fontSize:13,
                    color:Colors.white.withOpacity(0.60))),
            const SizedBox(height:22),
            Row(children:[
              Expanded(child:GestureDetector(
                onTap:(){_state.running=!_state.gameOver;Navigator.pop(context,false);},
                child:Container(
                    padding:const EdgeInsets.symmetric(vertical:13),
                    decoration:BoxDecoration(
                        color:Colors.white.withOpacity(0.18),
                        borderRadius:BorderRadius.circular(16),
                        border:Border.all(color:Colors.white.withOpacity(0.40),width:1.5)),
                    alignment:Alignment.center,
                    child:const Text('▶ Keep Playing',
                        style:TextStyle(fontFamily:'Fredoka One',
                            fontSize:14,color:Colors.white))),
              )),
              const SizedBox(width:10),
              Expanded(child:GestureDetector(
                onTap:(){Navigator.pop(context,true);},
                child:Container(
                    padding:const EdgeInsets.symmetric(vertical:13),
                    decoration:BoxDecoration(
                        color:Pal.tileRed,
                        borderRadius:BorderRadius.circular(16),
                        boxShadow:[BoxShadow(
                            color:Pal.tileRed.withOpacity(0.45),blurRadius:10)]),
                    alignment:Alignment.center,
                    child:const Text('🏠 Quit',
                        style:TextStyle(fontFamily:'Fredoka One',
                            fontSize:14,color:Colors.white))),
              )),
            ]),
          ]),
        ),
      ),
    );
    return quit??false;
  }

  @override
  Widget build(BuildContext context){
    final adsOn=context.watch<ExperienceManager>().adsEnabled;
    return WillPopScope(
      onWillPop: _confirmQuit,
      child: Scaffold(
        backgroundColor:Pal.bg,
        bottomNavigationBar:adsOn
            ?FamilyAdBanner(bannerAd:_bannerAd,isLoaded:_bannerLoaded)
            :null,
        body:SafeArea(
          child:ListenableBuilder(
            listenable:_state,
            builder:(ctx,_)=>Column(children:[
              // ── Userstatutbar ─────────────────────────────
              const Padding(
                  padding:EdgeInsets.fromLTRB(12,6,12,0),
                  child:Userstatutbar()),
              const SizedBox(height:4),
              // ── HUD ───────────────────────────────────────
              _HUD(state:_state,onBack:_handleBack),
              // ── Play area ─────────────────────────────────
              Expanded(child:LayoutBuilder(builder:(ctx,c){
                _lastSize=Size(c.maxWidth,c.maxHeight);
                return Stack(children:[
                  Listener(
                    behavior:HitTestBehavior.opaque,
                    onPointerDown:(e)=>_state.pointerDown(
                        e.pointer,e.localPosition,_lastSize),
                    onPointerUp:  (e)=>_state.pointerUp(e.pointer),
                    onPointerCancel:(e)=>_state.pointerUp(e.pointer),
                    child:CustomPaint(
                        size:_lastSize,
                        painter:_GamePainter(state:_state)),
                  ),
                  if(!_state.started||_state.gameOver)
                    _OverlayScreen(state:_state,
                        onReplay:_onReplay),
                  if(_state.comboMessage!=null)
                    _ComboPopup(message:_state.comboMessage!),
                  if(_state.freezeActive)
                    IgnorePointer(child:Container(
                        color:const Color(0x180288D1))),
                ]);
              })),
            ]),
          ),
        ),
      ),
    );
  }

  void _handleBack() async {
    final quit=await _confirmQuit();
    if(quit&&mounted) Navigator.pop(context);
  }

  // Show interstitial between games, then start new game + award XP
  void _onReplay(){
    AdHelper.showInterstitialAd(
      context:context,
      onDismissed:(){
        if(!mounted) return;
        // Award XP based on score at end
        if(_state.gameOver&&_state.score>0){
          Provider.of<ExperienceManager>(context,listen:false)
              .addXP((_state.score~/5).clamp(1,50),context:context);
        }
        _state.startGame();
      },
    );
  }
}

// ─── HUD ─────────────────────────────────────────────────────
class _HUD extends StatelessWidget {
  const _HUD({required this.state,required this.onBack});
  final PianoGameState state;
  final VoidCallback   onBack;

  @override
  Widget build(BuildContext context){
    return Container(
      height:62,
      decoration:BoxDecoration(
        color:Pal.hud,
        boxShadow:[BoxShadow(
            color:Pal.hudShadow,blurRadius:6,offset:const Offset(0,2))],
      ),
      padding:const EdgeInsets.symmetric(horizontal:12),
      child:Row(children:[
        // Back button
        GestureDetector(
          onTap:onBack,
          child:Container(
              width:36,height:36,
              decoration:BoxDecoration(
                  color:Pal.accent.withOpacity(0.10),
                  borderRadius:BorderRadius.circular(12),
                  border:Border.all(
                      color:Pal.accent.withOpacity(0.35),width:1.2)),
              child:Icon(Icons.arrow_back_ios_new_rounded,
                  size:16,color:Pal.accent)),
        ),
        const SizedBox(width:8),
        // Lives
        Row(children:List.generate(3,(i)=>Padding(
          padding:const EdgeInsets.only(right:3),
          child:Icon(i<state.lives
              ?Icons.favorite_rounded
              :Icons.favorite_outline_rounded,
              color:i<state.lives?Pal.heart:Pal.heartEmpty,size:20),
        ))),
        const Spacer(),
        // Score
        Column(mainAxisAlignment:MainAxisAlignment.center,children:[
          Text('${state.score}',style:const TextStyle(
              color:Color(0xFF3D2B8C),fontSize:28,
              fontWeight:FontWeight.w900,height:1)),
          const Text('SCORE',style:TextStyle(
              color:Color(0xFF9E9E9E),fontSize:8,letterSpacing:3)),
        ]),
        const Spacer(),
        // Multiplier + power-up pills
        Column(mainAxisAlignment:MainAxisAlignment.center,
            crossAxisAlignment:CrossAxisAlignment.end,children:[
              Text('×${state.multiplier}',style:const TextStyle(
                  color:Color(0xFF3D2B8C),fontSize:18,
                  fontWeight:FontWeight.w900,height:1)),
              Row(children:[
                if(state.doubleActive)  _Pill('2×',Pal.tileDouble),
                if(state.shieldActive)  _Pill('🛡',Pal.tileShield),
                if(state.freezeActive)  _Pill('❄',Pal.tileFreeze),
              ]),
            ]),
      ]),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text,this.color);
  final String text; final Color color;
  @override
  Widget build(BuildContext context)=>Container(
    margin:const EdgeInsets.only(left:4),
    padding:const EdgeInsets.symmetric(horizontal:6,vertical:2),
    decoration:BoxDecoration(
        color:color.withOpacity(0.18),
        borderRadius:BorderRadius.circular(20),
        border:Border.all(color:color.withOpacity(0.45),width:1)),
    child:Text(text,style:TextStyle(
        color:color,fontSize:9,fontWeight:FontWeight.w900)),
  );
}

// ─── PAINTER ─────────────────────────────────────────────────
class _GamePainter extends CustomPainter {
  const _GamePainter({required this.state});
  final PianoGameState state;

  @override
  void paint(Canvas canvas,Size size){
    final w=size.width,h=size.height,colW=w/kCols;
    final cutoff=h-kHitZoneH;

    // Warm play area with subtle gradient
    final bgPaint=Paint()..shader=LinearGradient(
      colors:[Pal.playBg,Pal.playBg.withOpacity(0.92)],
      begin:Alignment.topCenter,end:Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0,0,w,cutoff));
    canvas.drawRect(Rect.fromLTWH(0,0,w,cutoff),bgPaint);

    // Column dividers — warm orange-tinted
    final div=Paint()..color=Pal.divider..strokeWidth=1;
    for(int c=1;c<kCols;c++)
      canvas.drawLine(Offset(c*colW,0),Offset(c*colW,cutoff),div);

    // Miss flashes
    for(final f in state.missFlashes){
      canvas.drawRRect(
          RRect.fromRectAndRadius(f.rect,const Radius.circular(kRadius)),
          Paint()..color=Pal.missFlash.withOpacity(f.alpha*0.40));
    }

    // Tiles
    for(final t in state.tiles){
      if(t.kind==TileKind.empty) continue;
      _drawTile(canvas,t,colW,h,cutoff);
    }

    // Particles
    for(final p in state.particles){
      canvas.drawCircle(Offset(p.x,p.y),p.r,
          Paint()..color=p.color.withOpacity(p.life));
    }

    // Ripples
    for(final r in state.ripples){
      canvas.drawCircle(Offset(r.x,r.y),r.radius,
          Paint()..color=r.color.withOpacity(r.life*0.45)
            ..style=PaintingStyle.stroke..strokeWidth=3);
    }

    // Hit zone — warm amber tint
    canvas.drawLine(Offset(0,cutoff),Offset(w,cutoff),
        Paint()..color=Pal.hitBorder..strokeWidth=2.5);
    canvas.drawRect(Rect.fromLTWH(0,cutoff,w,kHitZoneH),
        Paint()..color=Pal.hitZone);

    final hDiv=Paint()..color=Pal.hitBorder.withOpacity(0.35)..strokeWidth=1;
    for(int c=1;c<kCols;c++)
      canvas.drawLine(Offset(c*colW,cutoff),Offset(c*colW,h),hDiv);

    // Hit zone cells — rounded + glowing border
    final cellP=Paint()..color=Pal.hitBorder.withOpacity(0.50)
      ..style=PaintingStyle.stroke..strokeWidth=2;
    for(int c=0;c<kCols;c++){
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(c*colW+kGap,cutoff+kGap,colW-kGap*2,kHitZoneH-kGap*2),
          const Radius.circular(kRadius+2)),cellP);
    }

    // Speed bar — amber gradient
    final frac=((state.speed-kSpeedStart)/(kSpeedCap-kSpeedStart)).clamp(0.0,1.0);
    canvas.drawRect(Rect.fromLTWH(0,h-5,w*frac,5),
        Paint()..shader=LinearGradient(
          colors:[Pal.speedBar.withOpacity(0.5),Pal.speedBar],
        ).createShader(Rect.fromLTWH(0,h-5,w,5)));
  }

  void _drawTile(Canvas canvas,GameTile t,double colW,double h,double cutoff){
    final r=t.rect(colW);
    final rr=RRect.fromRectAndRadius(r,const Radius.circular(kRadius));

    switch(t.kind){
      case TileKind.black:
        if(t.hit){
          canvas.drawRRect(rr,Paint()..color=Pal.tileBlackH.withOpacity(t.tapFlash));
          if(t.tapFlash>0.05){
            final exp=(1-t.tapFlash)*20;
            canvas.drawRRect(
                RRect.fromRectAndRadius(
                    Rect.fromLTWH(r.left-exp,r.top-exp,
                        r.width+exp*2,r.height+exp*2),
                    const Radius.circular(kRadius+4)),
                Paint()..color=Pal.tileBlackH.withOpacity(t.tapFlash*0.35)
                  ..style=PaintingStyle.stroke..strokeWidth=2.5);
          }
        } else {
          // Gradient black tile
          canvas.drawRRect(rr,Paint()..shader=LinearGradient(
            colors:[Pal.tileBlack,const Color(0xFF1A0A5C)],
            begin:Alignment.topCenter,end:Alignment.bottomCenter,
          ).createShader(r));
          // Shine
          canvas.drawRRect(RRect.fromRectAndRadius(
              Rect.fromLTWH(r.left,r.top,r.width,r.height*0.20),
              const Radius.circular(kRadius)),
              Paint()..color=Colors.white.withOpacity(0.14));
        }
        break;

      case TileKind.red:
        if(t.redTouched){
          canvas.drawRRect(rr,Paint()..color=Pal.tileRed.withOpacity(t.tapFlash*0.7));
        } else {
          canvas.drawRRect(rr,Paint()..color=Pal.tileRed);
          // Pulsing danger border
          canvas.drawRRect(RRect.fromRectAndRadius(
              Rect.fromLTWH(r.left-3,r.top-3,r.width+6,r.height+6),
              const Radius.circular(kRadius+3)),
              Paint()..color=Pal.tileRed.withOpacity(0.35)
                ..style=PaintingStyle.stroke..strokeWidth=3.5);
          _label(canvas,r,'✕',28,
              const TextStyle(color:Colors.white,fontSize:28,
                  fontWeight:FontWeight.w900));
        }
        break;

      case TileKind.hold:
        canvas.drawRRect(rr,Paint()..color=
        (t.holding||t.holdCompleted)?Pal.tileHold:Pal.tileHold.withOpacity(0.88));
        if(t.holdProgress>0){
          final bh=r.height*t.holdProgress;
          canvas.drawRRect(RRect.fromRectAndRadius(
              Rect.fromLTWH(r.left,r.top+r.height-bh,r.width,bh),
              const Radius.circular(kRadius)),
              Paint()..color=Pal.tileHoldF);
        }
        if(!t.holdCompleted)
          _label(canvas,r,'HOLD',10,
              const TextStyle(color:Colors.white,fontSize:10,
                  fontWeight:FontWeight.w900,letterSpacing:2));
        if(t.holdCompleted&&t.tapFlash>0)
          canvas.drawRRect(rr,Paint()..color=Pal.tileHoldF.withOpacity(t.tapFlash*0.6));
        break;

      case TileKind.double_:
        if(t.hit){
          canvas.drawRRect(rr,Paint()..color=Pal.tileDouble.withOpacity(t.tapFlash));
        } else {
          canvas.drawRRect(rr,Paint()..color=Pal.tileDouble);
          _label(canvas,r,'2×',24,
              TextStyle(color:Pal.tileDoubleT,fontSize:24,fontWeight:FontWeight.w900));
        }
        break;

      case TileKind.shield:
        if(t.hit){
          canvas.drawRRect(rr,Paint()..color=Pal.tileShield.withOpacity(t.tapFlash));
        } else {
          canvas.drawRRect(rr,Paint()..color=Pal.tileShield);
          _label(canvas,Rect.fromLTWH(r.left,r.top-6,r.width,r.height),'🛡',20,
              const TextStyle(fontSize:20));
          _label(canvas,Rect.fromLTWH(r.left,r.top+14,r.width,r.height),'SHIELD',8,
              TextStyle(color:Pal.tileShieldT,fontSize:8,
                  fontWeight:FontWeight.w900,letterSpacing:2));
        }
        break;

      case TileKind.bomb:
        if(t.bombDone){
          canvas.drawRRect(rr,Paint()..color=Pal.tileBombH.withOpacity(t.tapFlash));
        } else {
          canvas.drawRRect(rr,Paint()..color=Pal.tileBomb);
          if(t.bombTaps>0){
            canvas.drawArc(
                Rect.fromLTWH(r.left+6,r.top+6,r.width-12,r.height-12),
                -pi/2,pi,false,
                Paint()..color=Pal.tileBombH..style=PaintingStyle.stroke..strokeWidth=4);
          }
          _label(canvas,Rect.fromLTWH(r.left,r.top-6,r.width,r.height),'💣',20,
              const TextStyle(fontSize:20));
          _label(canvas,Rect.fromLTWH(r.left,r.top+12,r.width,r.height),
              t.bombTaps==0?'TAP ×2':'TAP!',9,
              TextStyle(color:t.bombTaps>0?Pal.tileBombH:Colors.white60,
                  fontSize:9,fontWeight:FontWeight.w900));
        }
        break;

      case TileKind.ghost:
        if(!t.hit){
          canvas.save();
          canvas.clipRRect(rr);
          canvas.drawRect(r,Paint()..color=Pal.tileGhost.withOpacity(t.ghostAlpha*0.80));
          canvas.restore();
          _label(canvas,r,'👻',22,
              TextStyle(fontSize:22,color:Colors.white.withOpacity(t.ghostAlpha)));
          canvas.drawRect(
              Rect.fromLTWH(r.left,r.bottom-5,r.width*t.ghostAlpha,5),
              Paint()..color=Colors.white.withOpacity(0.55));
        } else {
          canvas.drawRRect(rr,Paint()..color=Pal.tileGhost.withOpacity(t.tapFlash*0.5));
        }
        break;

      case TileKind.bonus:
        if(t.hit){
          canvas.drawRRect(rr,Paint()..color=Pal.tileBonus.withOpacity(t.tapFlash));
        } else {
          canvas.drawRRect(rr,Paint()..color=Pal.tileBonus);
          _label(canvas,Rect.fromLTWH(r.left,r.top-6,r.width,r.height),'⭐',22,
              const TextStyle(fontSize:22));
          _label(canvas,Rect.fromLTWH(r.left,r.top+12,r.width,r.height),'+3 PTS',9,
              TextStyle(color:Pal.tileBonusT,fontSize:9,
                  fontWeight:FontWeight.w900,letterSpacing:1));
        }
        break;

      case TileKind.freeze:
        if(t.hit){
          canvas.drawRRect(rr,Paint()..color=Pal.tileFreeze.withOpacity(t.tapFlash));
        } else {
          canvas.drawRRect(rr,Paint()..color=Pal.tileFreeze);
          canvas.drawRRect(rr,Paint()..color=Pal.tileFreezeT.withOpacity(0.50)
            ..style=PaintingStyle.stroke..strokeWidth=2);
          _label(canvas,Rect.fromLTWH(r.left,r.top-6,r.width,r.height),'❄',22,
              const TextStyle(fontSize:22));
          _label(canvas,Rect.fromLTWH(r.left,r.top+12,r.width,r.height),'SLOW',9,
              TextStyle(color:Pal.tileFreezeT,fontSize:9,
                  fontWeight:FontWeight.w900,letterSpacing:2));
        }
        break;

      case TileKind.empty: break;
    }
  }

  void _label(Canvas canvas,Rect r,String text,double fontSize,TextStyle style){
    final tp=TextPainter(
        text:TextSpan(text:text,style:style),
        textDirection:TextDirection.ltr)..layout();
    tp.paint(canvas,Offset(
        r.left+(r.width-tp.width)/2,
        r.top+(r.height-tp.height)/2));
  }

  @override bool shouldRepaint(_GamePainter old)=>true;
}

// ─── OVERLAY SCREEN ──────────────────────────────────────────
class _OverlayScreen extends StatelessWidget {
  const _OverlayScreen({required this.state,required this.onReplay});
  final PianoGameState state;
  final VoidCallback   onReplay;

  @override
  Widget build(BuildContext context){
    final isOver=state.gameOver;
    return Container(
      decoration:BoxDecoration(
          gradient:LinearGradient(
              colors:[Colors.white.withOpacity(0.96),Pal.bg.withOpacity(0.94)],
              begin:Alignment.topCenter,end:Alignment.bottomCenter)),
      child:Center(child:SingleChildScrollView(child:Column(
        mainAxisSize:MainAxisSize.min,
        children:[
          const SizedBox(height:16),
          // Bouncing emoji
          Text(isOver?'🎹':'🎵',
              style:const TextStyle(fontSize:60)),
          const SizedBox(height:4),
          Text(
            isOver?'GAME OVER':'PIANO TILES',
            style:const TextStyle(fontFamily:'Fredoka One',
                color:Color(0xFF3D2B8C),fontSize:26,letterSpacing:4),
          ),
          if(isOver)...[
            const SizedBox(height:8),
            if(state.score>=state.bestScore&&state.bestScore>0)
              Container(
                padding:const EdgeInsets.symmetric(horizontal:14,vertical:5),
                decoration:BoxDecoration(
                    color:Colors.amber.withOpacity(0.15),
                    borderRadius:BorderRadius.circular(14),
                    border:Border.all(color:Colors.amber,width:1.5)),
                child:const Text('🏆 NEW BEST!',
                    style:TextStyle(color:Colors.amber,fontSize:13,
                        fontWeight:FontWeight.w900,letterSpacing:2)),
              ),
            const SizedBox(height:8),
            const Text('YOUR SCORE',
                style:TextStyle(color:Color(0xFF9E9E9E),fontSize:10,letterSpacing:5)),
            Text('${state.score}',style:const TextStyle(
                color:Color(0xFF3D2B8C),fontSize:72,
                fontWeight:FontWeight.w900,letterSpacing:3,height:1)),
            Text('BEST: ${state.bestScore}',
                style:const TextStyle(color:Color(0xFF9E9E9E),fontSize:11,letterSpacing:3)),
            const SizedBox(height:28),
          ] else ...[
            const SizedBox(height:12),
            _legend(),
            const SizedBox(height:6),
            Text('Tapping empty space = MISS ⚠️',
                style:TextStyle(color:Colors.grey.shade400,fontSize:10,letterSpacing:1)),
            const SizedBox(height:24),
          ],
          // Play / Retry button
          GestureDetector(
            onTap: onReplay,
            child:Container(
              padding:const EdgeInsets.symmetric(horizontal:44,vertical:15),
              decoration:BoxDecoration(
                  gradient:const LinearGradient(
                      colors:[Color(0xFF6C63FF),Color(0xFF3D2B8C)],
                      begin:Alignment.topLeft,end:Alignment.bottomRight),
                  borderRadius:BorderRadius.circular(32),
                  boxShadow:[BoxShadow(
                      color:const Color(0xFF6C63FF).withOpacity(0.45),
                      blurRadius:14,offset:const Offset(0,5))]),
              child:Text(isOver?'▶  RETRY':'▶  PLAY',
                  style:const TextStyle(fontFamily:'Fredoka One',
                      color:Colors.white,fontSize:16,letterSpacing:3)),
            ),
          ),
          const SizedBox(height:24),
        ],
      ))),
    );
  }

  Widget _legend()=>Column(
    children:[
      _Li('🖤','TAP',    'Tap the dark tile to score'),
      _Li('💣','BOMB',   'Tap TWICE to detonate'),
      _Li('👻','GHOST',  'Tap before it fades!'),
      _Li('⭐','BONUS',  '+3 points — grab it!'),
      _Li('❄️','FREEZE', 'Slows all tiles for 4s'),
      _Li('🚫','RED ✕',  'Do NOT touch!'),
      _Li('⏸','HOLD',   'Press and hold briefly'),
      _Li('⚡','2×',     'Double points for 5s'),
      _Li('🛡','SHIELD', 'Blocks one miss'),
    ],
  );
}

class _Li extends StatelessWidget {
  const _Li(this.emoji,this.tag,this.label);
  final String emoji,tag,label;
  @override
  Widget build(BuildContext context)=>Padding(
    padding:const EdgeInsets.symmetric(vertical:3,horizontal:28),
    child:Row(children:[
      Text(emoji,style:const TextStyle(fontSize:16)),
      const SizedBox(width:8),
      Container(
          width:52,
          padding:const EdgeInsets.symmetric(horizontal:6,vertical:3),
          decoration:BoxDecoration(
              color:Pal.accent.withOpacity(0.10),
              borderRadius:BorderRadius.circular(8),
              border:Border.all(color:Pal.accent.withOpacity(0.35),width:1)),
          child:Text(tag,style:TextStyle(
              color:Pal.accent,fontSize:9,
              fontWeight:FontWeight.w900,letterSpacing:1),
              textAlign:TextAlign.center)),
      const SizedBox(width:10),
      Expanded(child:Text(label,
          style:const TextStyle(color:Color(0xFF616161),fontSize:11))),
    ]),
  );
}

// ─── COMBO POPUP ─────────────────────────────────────────────
class _ComboPopup extends StatelessWidget {
  const _ComboPopup({required this.message});
  final String message;
  @override
  Widget build(BuildContext context)=>Positioned(
    top:30,left:0,right:0,
    child:Center(child:Container(
      padding:const EdgeInsets.symmetric(horizontal:22,vertical:10),
      decoration:BoxDecoration(
          gradient:const LinearGradient(
              colors:[Color(0xFF6C63FF),Color(0xFFFF6B9D)]),
          borderRadius:BorderRadius.circular(26),
          boxShadow:[BoxShadow(
              color:const Color(0xFF6C63FF).withOpacity(0.45),
              blurRadius:12,offset:const Offset(0,4))]),
      child:Text(message,style:const TextStyle(
          fontFamily:'Fredoka One',
          color:Colors.white,fontSize:14,letterSpacing:2)),
    )),
  );
}
