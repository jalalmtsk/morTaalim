import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'CardConcept_resultPage.dart';

enum GameMode { local, online }


class CardGameApp extends StatelessWidget {
  const CardGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bright Cards',
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFF6F6F8),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF6ECF9A), elevation: 0),
      ),
      home: const GameLauncher(),
    );
  }
}

class GameLauncher extends StatefulWidget {
  const GameLauncher({super.key});
  @override
  State<GameLauncher> createState() => _GameLauncherState();
}

class _GameLauncherState extends State<GameLauncher> {

  GameMode mode = GameMode.local; // default

  int handSize = 7;
  int botCount = 2; // default 2 bots

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Bright Cards', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                'Match suit or rank. Special cards: 2 (draw2+skip), 1 (skip), 7 (change suit).',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Starting hand size:'),
                  const SizedBox(width: 10),
                  DropdownButton<int>(
                    value: handSize,
                    items: List.generate(11, (i) => i + 5)
                        .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                        .toList(),
                    onChanged: (v) => setState(() => handSize = v ?? 7),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Number of Bots:'),
                  const SizedBox(width: 10),
                  DropdownButton<int>(
                    value: botCount,
                    items: [1, 2, 3, 4].map((v) => DropdownMenuItem(value: v, child: Text('$v'))).toList(),
                    onChanged: (v) => setState(() => botCount = v ?? 2),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Mode:'),
                  const SizedBox(width: 10),
                  DropdownButton<GameMode>(
                    value: mode,
                    items: const [
                      DropdownMenuItem(value: GameMode.local, child: Text('Local (Bots)')),
                      DropdownMenuItem(value: GameMode.online, child: Text('Online (Players)')),
                    ],
                    onChanged: (v) => setState(() => mode = v ?? GameMode.local),
                  ),
                ],
              ),


              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GameScreen(
                      startHandSize: handSize,
                      botCount: botCount,
                      mode: mode, // <-- pass it here
                    ),
                  ),
                ),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start'),
              ),

            ],
          ),
        ),
      ),
    );
  }
}

// --- Models ---
class PlayingCard {
  final String suit; // Coins, Cups, Swords, Clubs
  final int rank; // 1..7,10,11,12
  final String id;
  PlayingCard({required this.suit, required this.rank}) : id = UniqueKey().toString();

  String get assetName => 'assets/images/cards/${suit.toLowerCase()}_${rank.toString()}.png';
  String get backAsset => 'assets/images/cards/backCard.png';
  String get label => '$rank of $suit';
}

class Deck {
  final List<PlayingCard> cards = [];
  Deck() { _build(); }
  void _build(){
    cards.clear();
    final suits = ['Coins','Cups','Swords','Clubs'];
    final ranks = [1,2,3,4,5,6,7,10,11,12];
    for(final s in suits) for(final r in ranks) cards.add(PlayingCard(suit: s, rank: r));
  }
  void shuffle() => cards.shuffle(Random());
  PlayingCard draw() => cards.removeLast();
  bool get isEmpty => cards.isEmpty;
  int get length => cards.length;
}

// --- Game Screen ---
class GameScreen extends StatefulWidget {
  final int startHandSize;
  final int botCount;
  final GameMode mode; // <-- new
  const GameScreen({required this.startHandSize, required this.botCount, super.key, required this.mode});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late Deck deck;
  final ScrollController handScrollController = ScrollController();
  final botKeys = List.generate(5, (_) => GlobalKey()); // index 0 unused
  late List<List<PlayingCard>> hands; // 0 = human, 1..botCount = bots

  PlayingCard? topCard;
  List<PlayingCard> discard = [];

  int currentPlayer = 0;
  bool isAnimating = false;
  OverlayEntry? moving;

  // gameplay state
  int pendingDraw = 0;
  bool skipNext = false;
  bool gameOver = false;
  String winner = '';

  // keys
  final GlobalKey deckKey = GlobalKey();
  final GlobalKey centerKey = GlobalKey();
  final GlobalKey handKey = GlobalKey();
  List<GlobalKey> playerCardKeys = [];


  // durations
  final Duration playDur = const Duration(milliseconds: 800);
  final Duration drawDur = const Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    hands = List.generate(widget.botCount + 1, (_) => []);

    if (widget.mode == GameMode.online) {
      _connectOnline();
    } else {
      _start(); // local bots
    }
  }

  WebSocketChannel? channel;

  void _connectOnline() {
    channel = WebSocketChannel.connect(Uri.parse('ws://YOUR_SERVER_IP:8080'));

    // Join game message
    channel!.sink.add(jsonEncode({
      'type': 'join_game',
      'gameId': 'game123', // generate or select a game
      'player': 'Player_${Random().nextInt(1000)}',
    }));

    channel!.stream.listen((message) {
      final data = jsonDecode(message);
      _handleOnlineMessage(data);
    });
  }

  void _handleOnlineMessage(Map<String, dynamic> data) {
    // Here you can update hands, topCard, etc., based on online messages
    // This keeps your local game logic intact
  }

  @override
  void dispose() {
    channel?.sink.close();
    super.dispose();
  }



  Future<void> _start() async {
    isAnimating = true; // block input during shuffling/deal

    deck = Deck();
    deck.shuffle();
    for (var h in hands) h.clear();
    discard.clear();
    currentPlayer = 0;
    pendingDraw = 0;
    skipNext = false;
    gameOver = false;
    winner = '';

    // precache assets
    await _precacheAssets(context);

    final toDeal = widget.startHandSize;

    // --- Initial deal with draw animation ---
    for (int round = 0; round < toDeal; round++) {
      for (int p = 0; p <= widget.botCount; p++) {
        if (deck.isEmpty) _recycle();
        if (deck.isEmpty) break;

        final c = deck.draw();
        hands[p].add(c);

        // compute positions
        final start = _rectFor(deckKey)?.center;
        Offset? end;
        if (p == 0) {
          // human: last card in hand
          final idx = hands[0].length - 1;
          if (idx < playerCardKeys.length) {
            end = _rectFor(playerCardKeys[idx])?.center;
          }
          end ??= Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height - 90);
          if (start != null && end != null) await _animateMoveFaceDown(c, start, end);
        } else {
          // bots: face-down animation
          final botPos = _cardStartForPlayer(p, hands[p].length - 1);
          if (start != null && botPos != null) await _animateMoveFaceDown(c, start, botPos);
        }

        setState(() {});
        await Future.delayed(const Duration(milliseconds: 90));
      }
    }

    // initial top card
    if (deck.isEmpty) _recycle();
    topCard = deck.draw();
    discard.add(topCard!);
    setState(() {});

    // start bot loop
    await Future.delayed(const Duration(milliseconds: 400));
    isAnimating = false; // unblock input after initial deal
    _maybeAutoPlay();
  }



  Future<void> _precacheAssets(BuildContext ctx) async{
    // Precache back and a few front images
    try{
      await precacheImage(const AssetImage('assets/images/cards/backCard.png'), ctx);
      final sample = PlayingCard(suit: 'Coins', rank: 1);
      await precacheImage(AssetImage(sample.assetName), ctx);
    }catch(_){/*silent*/}
  }

  void _recycle(){
    if(discard.length<=1) return;
    final top = discard.removeLast();
    deck.cards.addAll(discard);
    discard.clear();
    discard.add(top);
    deck.shuffle();
  }

  Rect? _rectFor(GlobalKey key){
    final ctx = key.currentContext; if(ctx==null) return null;
    final box = ctx.findRenderObject() as RenderBox; final p = box.localToGlobal(Offset.zero);
    return Rect.fromLTWH(p.dx,p.dy,box.size.width,box.size.height);
  }

  Offset? _cardStartForPlayer(int p, int idx){
    if (p == 0) {
      if (idx >= playerCardKeys.length) return null;
      final rect = _rectFor(playerCardKeys[idx]);
      if (rect == null) return null;
      return rect.center; // start from the tapped card
    } else {
      final rect = _rectFor(botKeys[p]);
      if(rect==null) return null;
      final center = rect.center;
      return center;
    }
  }

  Future<void> _animateMove(PlayingCard card, Offset from, Offset to, {required bool cinematic}) async{
    final overlay = Overlay.of(context); if(overlay==null) return;
    final dur = cinematic ? playDur : drawDur; final ctrl = AnimationController(vsync: this, duration: dur);
    final curve = CurvedAnimation(parent: ctrl, curve: Curves.easeInOutCubic);
    moving = OverlayEntry(builder: (_){
      return AnimatedBuilder(animation: curve, builder: (_,__){
        final pos = Offset.lerp(from,to,curve.value)!; final scale = cinematic ? (1.0 + 0.06*sin(curve.value*pi)) : 1.0; final op = cinematic ? (0.5 + curve.value*0.5) : 1.0;
        return Positioned(left: pos.dx-43, top: pos.dy-60, child: Opacity(opacity: op, child: Transform.scale(scale: scale, child: SizedBox(width:70,height:110,child: Image.asset(card.assetName, fit: BoxFit.cover)))));
      });
    });
    overlay.insert(moving!);
    await ctrl.forward(); moving?.remove(); moving=null; ctrl.dispose();
  }


  Future<void> _playCardByHuman(int idx) async{
    if(gameOver||isAnimating) return; if(currentPlayer!=0) return; if(idx<0||idx>=hands[0].length) return;
    final card = hands[0][idx]; if(!_isPlayable(card)){ _showSnack('Card not playable'); return; }
    await _playCard(0, idx);
  }

  bool _isPlayable(PlayingCard card){
    if(pendingDraw>0) return card.rank==2; if(topCard==null) return true; return card.suit==topCard!.suit || card.rank==topCard!.rank;
  }

  Future<void> _playCard(int player, int idx) async{
    if(isAnimating) return; isAnimating=true;
    final card = hands[player][idx];
    final start = _cardStartForPlayer(player, idx); final centerRect = _rectFor(centerKey);
    final to = centerRect?.center ?? Offset(MediaQuery.of(context).size.width/2, MediaQuery.of(context).size.height*0.38);
    if(start!=null){ await _animateMove(card, start, to, cinematic: true); }
    setState((){ hands[player].removeAt(idx); topCard = card; discard.add(card); });
    await _handleSpecial(player, card);
    isAnimating=false; _checkWin(player); if(!gameOver) _advanceTurn();
  }

  Future<void> _handleSpecial(int player, PlayingCard card) async {
    if (card.rank == 2) {
      pendingDraw += 2;
      _showCenterBanner('+2', Colors.redAccent);
      // Do NOT set skipNext here
    } else if (card.rank == 1) {
      skipNext = true;
      _showCenterBanner('Skip', Colors.orangeAccent);
    } else if (card.rank == 7) {
      if (player == 0) {
        final choice = await _askSuit();
        if (choice != null) {
          setState(() => topCard = PlayingCard(suit: choice, rank: 7));
          discard.removeLast();
          discard.add(topCard!);
        }
      } else {
        final suit = _botPickSuit(player);
        _showCenterBanner('Suit: $suit', Colors.blueAccent);
        await Future.delayed(const Duration(milliseconds: 600));
        setState(() => topCard = PlayingCard(suit: suit, rank: 7));
        discard.removeLast();
        discard.add(topCard!);
      }
    }
  }



  Future<String?> _askSuit(){ return showDialog<String>(context: context, builder: (ctx){ return AlertDialog(title: const Text('Choose suit'), content: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: ['Coins','Cups','Swords','Clubs'].map((s)=>ElevatedButton(onPressed: ()=>Navigator.of(ctx).pop(s), child: Text(s))).toList()),); }); }

  String _botPickSuit(int bot){ final counts={'Coins':0,'Cups':0,'Swords':0,'Clubs':0}; for(final c in hands[bot]) counts[c.suit]=counts[c.suit]!+1; var best='Coins'; var b=-1; counts.forEach((k,v){ if(v>b){b=v;best=k;}}); return best; }

  void _showCenterBanner(String text, Color col){ final overlay = Overlay.of(context); if(overlay==null) return; final entry = OverlayEntry(builder: (_){ final c = _rectFor(centerKey)?.center ?? Offset(MediaQuery.of(context).size.width/2, MediaQuery.of(context).size.height*0.35); return Positioned(left:c.dx-70,top:c.dy-120, child: Material(color:Colors.transparent,child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color:col.withOpacity(0.9), borderRadius: BorderRadius.circular(8)), child: Text(text, style: const TextStyle(color:Colors.white,fontWeight: FontWeight.bold))))); }); overlay.insert(entry); Future.delayed(const Duration(milliseconds:800), ()=>entry.remove()); }

  void _showSnack(String t){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t), duration: const Duration(milliseconds:700))); }

  void _advanceTurn() {
    int next = (currentPlayer + 1) % (widget.botCount + 1);
    if (skipNext) {
      skipNext = false;
      next = (next + 1) % (widget.botCount + 1);
    }
    currentPlayer = next;
    setState(() {});
    _maybeAutoPlay();
  }

  void _maybeAutoPlay() {
    if (gameOver) return;
    if (currentPlayer == 0) return;
    if (widget.mode == GameMode.online) return; // skip bots if online
    if (currentPlayer > widget.botCount) return; // safety
    Future.delayed(Duration(milliseconds: 600 + Random().nextInt(700)), () async {
      if (gameOver) return;
      await _botTurn(currentPlayer);
    });
  }

  Future<void> _botTurn(int bot) async {
    if (deck.isEmpty) _recycle();
    if (deck.isEmpty) return;

    // --- Handle pending +2 chain ---
    if (pendingDraw > 0) {
      final chainable = hands[bot].indexWhere((c) => c.rank == 2);
      if (chainable != -1) {
        // Bot chains +2
        await Future.delayed(Duration(milliseconds: 400 + Random().nextInt(400)));
        await _playCard(bot, chainable);
        return;
      } else {
        // No 2 -> draw all pending cards
        for (int i = 0; i < pendingDraw; i++) {
          if (deck.isEmpty) _recycle();
          if (deck.isEmpty) break;
          final d = deck.draw();
          hands[bot].add(d);
          final start = _rectFor(deckKey)?.center;
          final botPos = _cardStartForPlayer(bot, hands[bot].length - 1);
          if (start != null && botPos != null) await _animateMoveFaceDown(d, start, botPos);
          await Future.delayed(const Duration(milliseconds: 90));
        }
        _showCenterBanner('Drew $pendingDraw cards', Colors.purpleAccent);
        pendingDraw = 0;
        await Future.delayed(const Duration(milliseconds: 300));
        _advanceTurn();
        return;
      }
    }

    // --- Normal playable card ---
    final playable = <int>[];
    for (int i = 0; i < hands[bot].length; i++) {
      if (_isPlayable(hands[bot][i])) playable.add(i);
    }

    if (playable.isEmpty) {
      // Draw one card if nothing playable, then skip turn
      if (deck.isEmpty) _recycle();
      if (deck.isEmpty) {
        _advanceTurn();
        return;
      }
      final d = deck.draw();
      hands[bot].add(d);
      final start = _rectFor(deckKey)?.center;
      final botPos = _cardStartForPlayer(bot, hands[bot].length - 1);
      if (start != null && botPos != null) await _animateMoveFaceDown(d, start, botPos);

      // Show banner & skip turn
      _showCenterBanner('Drew & skipped', Colors.purpleAccent);
      await Future.delayed(const Duration(milliseconds: 300));
      _advanceTurn(); // Skip bot turn after drawing
      return;
    }

    // --- Play best playable card ---
    int choice = playable.first;
    for (final i in playable) {
      final r = hands[bot][i].rank;
      if (r == 2 || r == 1 || r == 7) {
        choice = i;
        break;
      }
    }

    await Future.delayed(Duration(milliseconds: 350 + Random().nextInt(450)));
    await _playCard(bot, choice);
  }


  Future<void> _animateMoveFaceDown(PlayingCard card, Offset from, Offset to) async {
    final overlay = Overlay.of(context);
    if (overlay == null) return;
    final ctrl = AnimationController(vsync: this, duration: drawDur);
    final curve = CurvedAnimation(parent: ctrl, curve: Curves.easeInOutCubic);
    final movingEntry = OverlayEntry(builder: (_) {
      return AnimatedBuilder(
        animation: curve,
        builder: (_, __) {
          final pos = Offset.lerp(from, to, curve.value)!;
          return Positioned(
            left: pos.dx - 43,
            top: pos.dy - 60,
            child: SizedBox(
              width: 70,
              height: 110,
              child: Image.asset(card.backAsset, fit: BoxFit.cover),
            ),
          );
        },
      );
    });
    overlay.insert(movingEntry);
    await ctrl.forward();
    movingEntry.remove();
    ctrl.dispose();
  }



  Future<void> _playerDraw() async {
    if (isAnimating || gameOver) return; // block input during animation
    if (currentPlayer != 0) return;

    if (deck.isEmpty) _recycle();
    if (deck.isEmpty) {
      _showSnack('Deck empty');
      return;
    }

    isAnimating = true; // disable input

    int drawCount = pendingDraw > 0 ? pendingDraw : 1; // draw pending or 1
    for (int i = 0; i < drawCount; i++) {
      if (deck.isEmpty) _recycle();
      if (deck.isEmpty) break;

      final d = deck.draw();

      // animate from deck to end of hand
      final start = _rectFor(deckKey)?.center;

      final idx = hands[0].length; // last position
      Offset handPos;
      if (idx < playerCardKeys.length) {
        handPos = _rectFor(playerCardKeys[idx])?.center ??
            Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height - 90);
      } else {
        final w = MediaQuery.of(context).size.width;
        handPos = Offset(w * 0.5 + idx * 86 / 2, MediaQuery.of(context).size.height - 90);
      }

      if (start != null) {
        await _animateMoveFaceDownToFaceUp(d, start, handPos);
      }

      setState(() {
        hands[0].add(d);
      });

      await Future.delayed(const Duration(milliseconds: 50));
    }

    pendingDraw = 0; // reset pending draw
    isAnimating = false;

    // scroll to end so new cards are visible
    handScrollController.animateTo(
      handScrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );

    _showSnack('Drew $drawCount card${drawCount > 1 ? 's' : ''} & skipped');

    _advanceTurn(); // skip turn automatically after drawing
  }


  Future<void> _animateMoveFaceDownToFaceUp(PlayingCard card, Offset from, Offset to) async {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    final curve = CurvedAnimation(parent: ctrl, curve: Curves.easeInOutCubic);

    OverlayEntry? entry;
    entry = OverlayEntry(builder: (_) {
      return AnimatedBuilder(
        animation: curve,
        builder: (_, __) {
          final pos = Offset.lerp(from, to, curve.value)!;
          final flip = curve.value < 0.5 ? pi * curve.value : pi * (1 - curve.value); // flip effect
          final showFront = curve.value > 0.5;

          return Positioned(
            left: pos.dx - 43,
            top: pos.dy - 60,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(flip),
              child: SizedBox(
                width: 70,
                height: 110,
                child: Image.asset(showFront ? card.assetName : card.backAsset, fit: BoxFit.cover),
              ),
            ),
          );
        },
      );
    });
    overlay.insert(entry);
    await ctrl.forward();
    entry.remove();
    ctrl.dispose();
  }



  void _checkWin(int p){ if(hands[p].isEmpty){ gameOver=true; winner = p==0 ? 'You' : 'Bot $p'; _showEnd(); }}

  void _showEnd() {
    int winnerIndex = hands.indexWhere((h) => h.isEmpty);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EndGameScreen(
          hands: hands,
          winnerIndex: winnerIndex,
        ),
      ),
    );
  }

  List<Widget> _buildBotWidgets(double h) {
    List<Widget> widgets = [];
    for (int b = 1; b <= widget.botCount; b++) {
      if (b == 1) {
        widgets.add(Positioned(left: 12, top: h * 0.42, child: _botStack(b, vertical: true)));
      } else if (b == 4) {
        widgets.add(Positioned(right: 12, top: h * 0.42, child: _botStack(b, vertical: true)));
      } else {
        widgets.add(_botStack(b));
      }
    }
    return widgets;
  }

  // UI build
  @override
  Widget build(BuildContext context){ final w = MediaQuery.of(context).size.width; final h = MediaQuery.of(context).size.height;
  return Scaffold(
    appBar: AppBar(title: const Text('Bright Cards'), actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: ()=>_start())]),
    body: SafeArea(child: Stack(children: [
      // soft background
      Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF6F6F8), Color(0xFFECF9F0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)))),

      // top bots row
      Positioned(
        top: 12,
        left: 0,
        right: 0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            if (widget.botCount >= 2) _botStack(2),
            if (widget.botCount >= 3) _botStack(3),
          ],
        ),
      ),

// left and right bots
      if (widget.botCount >= 1)
        Positioned(left: 12, top: h*0.42, child: _botStack(1, vertical:true)),
      if (widget.botCount >= 4)
        Positioned(right: 12, top: h*0.42, child: _botStack(4, vertical:true)),

      // center deck & top card
      Positioned(top: h*0.24, left: w*0.18, right: w*0.18,
          child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(onTap: _playerDraw,
                          child: Column(children: [
                            const Text('Draw Pile'),
                            const SizedBox(height:4),
                            SizedBox(key: deckKey, width:70,height:110,
                                child: deck.isEmpty ? Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.white70), child: const Center(child: Text('Empty'))) : Image.asset(deck.cards.last.backAsset, fit: BoxFit.cover) ),
        ],
      )), const SizedBox(width: 30), Column(children: [ const Text('Top Card'), const SizedBox(height:4), SizedBox(key: centerKey,width:70,height:110, child: topCard==null? Container(): Image.asset(topCard!.assetName, fit:BoxFit.cover)) ]) ]) ])),

      // player hand (Flat)
      Positioned(
        bottom: 12,
        left: 0,
        right: 0,
        child: Column(
          children: [
            Row( mainAxisAlignment :MainAxisAlignment.spaceAround,
              children: [
                Text(
                  'Your Hand '+
                      (currentPlayer == 0 ? '  (Your turn)' : ''),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Container(child: Text("${hands[0].length} cards"),),

                ElevatedButton(
                  onPressed: (!isAnimating && currentPlayer == 0) ? () => _playerDraw() : null,
                  child: const Text('Draw'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              key: handKey,
              height: 135,
              child: SingleChildScrollView(
                controller: handScrollController, // ScrollController defined in state
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: List.generate(hands[0].length, (i) {
                    if (i >= playerCardKeys.length) playerCardKeys.add(GlobalKey());
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: GestureDetector(
                        onTap: () => _playCardByHuman(i),
                        child: AnimatedContainer(
                          key: playerCardKeys[i], // assign the key here
                          duration: const Duration(milliseconds: 250),
                          width: currentPlayer == 0 ? 70 : 69,
                          height: currentPlayer == 0 ? 114 : 113,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.8),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ],
                            borderRadius: BorderRadius.circular(2),
                            border: currentPlayer == 0
                                ? Border.all(color: Colors.black.withOpacity(0.8), width: 0.6)
                                : Border.all(color: Colors.white, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.asset(
                              hands[0][i].assetName,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
      // HUD
      Positioned(top: 8,left: 8, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: Text('Deck: ${deck.length}  Discard: ${discard.length}'))),
    ])),
  );
  }

  Widget _botStack(int bot, {bool vertical = false}) {
    final isTurn = currentPlayer == bot;
    final key = botKeys[bot];
    return Container(
      key: key, // <-- assign key
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: isTurn ? Border.all(color: Colors.greenAccent, width: 3) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Bot $bot', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        SizedBox(
          width: vertical ? 50 : 60,
          height: vertical ? 70 : 80,
          child: Stack(
            children: [
              for (int i = 0; i < min(hands[bot].length, 4); i++)
                Positioned(
                  left: i * 4,
                  top: i * 2,
                  child: Image.asset(
                    hands[bot].isNotEmpty
                        ? hands[bot].first.backAsset
                        : 'assets/images/cards/backCard.png',
                    width: 86,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
            ],
          ),
        ),
        Text('${hands[bot].length} cards'),
      ]),
    );
  }


// Flat row player hand (replace _buildFannedHand)
  List<Widget> _buildFannedHand() {
    final list = <Widget>[];
    final count = hands[0].length;
    if (count == 0) return [Center(child: Text('No cards', style: TextStyle(color: Colors.black26)))];
    final width = MediaQuery.of(context).size.width;
    final cardW = 86.0;
    final spacing = 16.0;
    final startX = (width - (cardW + spacing) * count + spacing) / 2;

    for (int i = 0; i < count; i++) {
      final x = startX + i * (cardW + spacing);
      list.add(Positioned(
        left: x,
        top: 0,
        child: GestureDetector(
          onTap: () => _playCardByHuman(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: cardW,
            height: 120,
            decoration: BoxDecoration(
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6, offset: Offset(0, 4))],
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(hands[0][i].assetName, fit: BoxFit.cover),
            ),
          ),
        ),
      ));
    }
    return list;
  }

  void _pass(){ if(currentPlayer!=0) return; _advanceTurn(); }
}
