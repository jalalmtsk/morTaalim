import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class Hezz2App extends StatelessWidget {
  const Hezz2App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hezz2',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        scaffoldBackgroundColor: const Color(0xFF083D2B),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const PlayerSelectionPage(),
    );
  }
}

// ========================= MODELS & DECK =========================
enum Suit { cups, swords, coins, clubs }

class HezzCard {
  final Suit suit;
  final int rank;
  const HezzCard({required this.suit, required this.rank});

  bool get isSkip => rank == 1;
  bool get isDrawTwo => rank == 2;
  bool get isChangeSuit => rank == 7;

  String get suitLabel => suit.name.toUpperCase();
  String get label => switch (rank) { 1 => 'SKIP', 2 => '+2', 7 => '7', _ => '$rank' };
  @override
  String toString() => '${suit.name}_$rank';
}

class DeckBuilder {
  static List<HezzCard> buildDeck() {
    final ranks = [1, 2, 3, 4, 5, 6, 7, 10, 11, 12];
    final deck = <HezzCard>[];
    for (final s in Suit.values) {
      for (final r in ranks) {
        deck.add(HezzCard(suit: s, rank: r));
      }
    }
    deck.shuffle(Random());
    return deck;
  }
}

// ========================= GAME ENGINE =========================
class GameState {
  final int playerCount;
  final List<List<HezzCard>> hands;
  final List<HezzCard> drawPile;
  final List<HezzCard> discardPile;
  int currentPlayer;
  int direction;
  Suit activeSuit;
  int pendingDraw;
  bool forceSkip;

  GameState._({
    required this.playerCount,
    required this.hands,
    required this.drawPile,
    required this.discardPile,
    required this.currentPlayer,
    required this.direction,
    required this.activeSuit,
    required this.pendingDraw,
    required this.forceSkip,
  });

  factory GameState.newGame({int players = 2}) {
    final deck = DeckBuilder.buildDeck();
    final hands = List.generate(players, (_) => <HezzCard>[]);
    return GameState._(
      playerCount: players,
      hands: hands,
      drawPile: deck,
      discardPile: [],
      currentPlayer: 0,
      direction: 1,
      activeSuit: Suit.cups,
      pendingDraw: 0,
      forceSkip: false,
    );
  }

  HezzCard get topCard => discardPile.last;

  int nextIndex([int steps = 1]) {
    int idx = currentPlayer;
    for (int i = 0; i < steps; i++) {
      idx = (idx + direction) % playerCount;
      if (idx < 0) idx += playerCount;
    }
    return idx;
  }

  void advanceTurn([int steps = 1]) { currentPlayer = nextIndex(steps); }

  bool canPlay(HezzCard card) {
    if (discardPile.isEmpty) return true;
    if (pendingDraw > 0) return false;
    if (card.isChangeSuit) return true;
    return card.suit == activeSuit || card.rank == topCard.rank;
  }

  void reshuffleIfNeeded() {
    if (drawPile.isEmpty) {
      if (discardPile.length <= 1) return;
      final top = discardPile.removeLast();
      drawPile.addAll(discardPile);
      discardPile.clear();
      discardPile.add(top);
      drawPile.shuffle(Random());
    }
  }

  List<HezzCard> drawCards(int count) {
    final drawn = <HezzCard>[];
    for (int i = 0; i < count; i++) {
      reshuffleIfNeeded();
      if (drawPile.isEmpty) break;
      drawn.add(drawPile.removeLast());
    }
    return drawn;
  }

  bool playCard(int player, HezzCard card, {Suit? chosenSuit}) {
    if (player != currentPlayer) return false;
    if (!canPlay(card)) return false;

    hands[player].remove(card);
    discardPile.add(card);

    if (card.isChangeSuit) activeSuit = chosenSuit ?? activeSuit;
    else activeSuit = card.suit;

    if (card.isDrawTwo) { pendingDraw += 2; forceSkip = true; }
    else if (card.isSkip) forceSkip = true;

    advanceTurn();
    return true;
  }
}


// ========================= WIDGETS =========================
class AnimatedCard extends StatelessWidget {
  final HezzCard card;
  final bool faceUp;
  final double width;
  final double height;
  const AnimatedCard({super.key, required this.card, this.faceUp = true, this.width = 60, this.height = 100});

  String get assetPath {
    if (!faceUp) return 'assets/images/cards/backCard.png';
    final s = card.suit.name.toLowerCase();
    return 'assets/images/cards/${s}_${card.rank}.png';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: Image.asset(assetPath, fit: BoxFit.cover),
    );
  }
}

class AnimatedCardFly extends StatefulWidget {
  final Offset start;
  final Offset end;
  final Duration duration;
  final VoidCallback? onComplete;
  final Widget child;
  const AnimatedCardFly({super.key, required this.start, required this.end, required this.child, this.duration = const Duration(milliseconds: 500), this.onComplete});
  @override
  State<AnimatedCardFly> createState() => _AnimatedCardFlyState();
}

class _AnimatedCardFlyState extends State<AnimatedCardFly> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<Offset> _pos;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((s) { if (s == AnimationStatus.completed && widget.onComplete != null) widget.onComplete!(); });
    _pos = Tween<Offset>(begin: widget.start, end: widget.end).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
    _c.forward();
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final p = _pos.value;
        return Positioned(left: p.dx, top: p.dy, child: child!);
      },
      child: widget.child,
    );
  }
}

class ConfettiBurst extends StatefulWidget {
  final Offset center;
  final int count;
  const ConfettiBurst({super.key, required this.center, this.count = 20});
  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_Particle> parts;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..forward();
    final rnd = Random();
    parts = List.generate(widget.count, (_) {
      final angle = rnd.nextDouble() * pi * 2;
      final dist = 40 + rnd.nextDouble() * 120;
      final dx = cos(angle) * dist;
      final dy = sin(angle) * dist;
      return _Particle(offset: Offset(dx, dy), size: 6 + rnd.nextDouble() * 8);
    });
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = Curves.easeOut.transform(_c.value);
        return Stack(children: [
          for (final p in parts)
            Positioned(
              left: widget.center.dx + p.offset.dx * t,
              top: widget.center.dy + p.offset.dy * t,
              child: Opacity(
                opacity: 1 - _c.value,
                child: Container(width: p.size, height: p.size, decoration: BoxDecoration(color: _randColor(p), shape: BoxShape.circle)),
              ),
            ),
        ]);
      },
    );
  }

  Color _randColor(_Particle p) {
    final colors = [Colors.yellow, Colors.redAccent, Colors.lightBlue, Colors.pinkAccent, Colors.greenAccent];
    return colors[p.size.round() % colors.length];
  }
}

class _Particle { final Offset offset; final double size; _Particle({required this.offset, required this.size}); }

class TurnGlow extends StatefulWidget {
  final bool active;
  final double size;
  final Widget child;
  const TurnGlow({super.key, required this.active, required this.child, this.size = 64});
  @override
  State<TurnGlow> createState() => _TurnGlowState();
}

class _TurnGlowState extends State<TurnGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final glow = widget.active ? (0.5 + 0.5 * sin(_c.value * 2 * pi)) : 0.0;
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [if (widget.active) BoxShadow(color: Colors.yellow.withOpacity(0.4 + glow * 0.4), blurRadius: 12 + glow * 18)],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ========================= PAGES =========================

class PlayerSelectionPage extends StatefulWidget {
  const PlayerSelectionPage({super.key});
  @override
  State<PlayerSelectionPage> createState() => _PlayerSelectionPageState();
}

class _PlayerSelectionPageState extends State<PlayerSelectionPage> {
  int selectedPlayers = 2;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hezz2 — New Game')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF0C5B3D), Color(0xFF05261B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Center(
          child: Card(
            elevation: 10,
            color: Colors.white.withOpacity(0.95),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Select Players', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ToggleButtons(
                    isSelected: [2,3,4].map((n) => n == selectedPlayers).toList(),
                    onPressed: (i) => setState(() => selectedPlayers = [2,3,4][i]),
                    children: const [Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('2')), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('3')), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('4'))],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => Hezz2GamePage(players: selectedPlayers))),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Hezz2GamePage extends StatefulWidget {
  final int players;
  const Hezz2GamePage({super.key, required this.players});
  @override
  State<Hezz2GamePage> createState() => _Hezz2GamePageState();
}

class _Hezz2GamePageState extends State<Hezz2GamePage> {
  late GameState game;
  bool playerTurn = false; // human = 0
  bool choosingSuit = false;
  HezzCard? pendingChangeSuit;
  bool dealing = true;

  // Animation anchors
  final GlobalKey _drawPileKey = GlobalKey();
  final GlobalKey _playerHandKey = GlobalKey();
  final GlobalKey _topBotKey = GlobalKey();
  final GlobalKey _leftBotKey = GlobalKey();
  final GlobalKey _rightBotKey = GlobalKey();

  OverlayEntry? _confetti;

  @override
  void initState() {
    super.initState();
    game = GameState.newGame(players: widget.players);
    WidgetsBinding.instance.addPostFrameCallback((_) => _dealAndRun());
  }

  // ========================= TURN ENGINE (No Stalls) =========================
  Future<void> _dealAndRun() async {
    await _dealCards();
    await _runUntilHumanTurn();
  }

  Future<void> _runUntilHumanTurn() async {
    // Central loop: resolves effects, bots act, repeats until human interaction is needed.
    for (int guard = 0; guard < 200; guard++) {
      // 1) Resolve start-of-turn effects for whoever's turn it is
      final changed = await _resolveStartEffectsAnimated();
      if (changed && game.hands.any((h) => h.isEmpty)) { return; }

      // 2) If now it's human's turn, stop and wait for input
      if (game.currentPlayer == 0) {
        setState(() => playerTurn = true);
        return;
      }

      // 3) Otherwise, let that bot play exactly one turn
      await _botOneTurn(game.currentPlayer);

      // 4) Check win after bot act
      if (game.hands.any((h) => h.isEmpty)) { return; }
    }
  }

  Future<bool> _resolveStartEffectsAnimated() async {
    bool progressed = false;
    if (game.pendingDraw > 0) {
      final victim = game.currentPlayer;
      final n = game.pendingDraw;
      await _flyDeckToPlayer(victim, times: n);
      setState(() => game.hands[victim].addAll(game.drawCards(n)));
      game.pendingDraw = 0;
      if (game.forceSkip) {
        game.forceSkip = false;
        game.advanceTurn();
      }
      progressed = true;
    } else if (game.forceSkip) {
      game.forceSkip = false;
      game.advanceTurn();
      progressed = true;
    }
    return progressed;
  }

  Future<void> _botOneTurn(int i) async {
    // Pick/play one card or draw one.
    final hand = game.hands[i];
    // Compute playable after effects are already resolved.
    final playable = hand.where((c) => game.canPlay(c)).toList();

    if (playable.isNotEmpty) {
      // Prefer impactful cards, then match rank, then suit, then 7
      playable.sort((a, b) {
        int score(HezzCard c) {
          if (c.isDrawTwo) return 4;
          if (c.isSkip) return 3;
          if (c.isChangeSuit) return 1; // keep if possible
          if (c.rank == game.topCard.rank) return 2;
          if (c.suit == game.activeSuit) return 1;
          return 0;
        }
        return score(b) - score(a);
      });
      final card = playable.first;
      await _flyHandToCenter(i);
      setState(() {
        hand.remove(card);
        game.discardPile.add(card);
        if (card.isChangeSuit) {
          final counts = <Suit, int>{ for (var s in Suit.values) s: 0 };
          for (final c in hand) { counts[c.suit] = (counts[c.suit] ?? 0) + 1; }
          final bestSuit = counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
          game.activeSuit = bestSuit;
        } else {
          game.activeSuit = card.suit;
        }
        if (card.isDrawTwo) { game.pendingDraw += 2; game.forceSkip = true; }
        if (card.isSkip) { game.forceSkip = true; }
        game.advanceTurn();
      });
    } else {
      // Draw one and pass
      final drawn = game.drawCards(1);
      if (drawn.isNotEmpty) {
        await _flyDeckToPlayer(i);
        setState(() => hand.add(drawn.first));
      }
      setState(() => game.advanceTurn());
    }
  }

  // ========================= DEALING & ANIMS =========================
  Future<void> _dealCards() async {
    const delay = Duration(milliseconds: 180);
    for (int i = 0; i < 7; i++) {
      for (int p = 0; p < game.playerCount; p++) {
        final card = game.drawCards(1).first;
        await _flyDeckToPlayer(p);
        setState(() => game.hands[p].add(card));
        await Future.delayed(delay);
      }
    }
    final first = game.drawCards(1).first;
    setState(() {
      game.discardPile.add(first);
      game.activeSuit = first.suit;
      dealing = false;
    });
  }

  Offset _posOf(GlobalKey key) {
    final rb = key.currentContext?.findRenderObject() as RenderBox?;
    return rb?.localToGlobal(Offset.zero) ?? Offset.zero;
  }

  Future<void> _flyDeckToPlayer(int playerIndex, {int times = 1}) async {
    for (int k = 0; k < times; k++) {
      final start = _posOf(_drawPileKey);
      final GlobalKey endKey = switch (playerIndex) {
        0 => _playerHandKey,
        1 => _topBotKey,
        2 => _leftBotKey,
        3 => _rightBotKey,
        _ => _playerHandKey,
      };
      final end = _posOf(endKey);
      final overlay = Overlay.of(context);
      if (overlay == null) return;
      final entry = OverlayEntry(
        builder: (_) => AnimatedCardFly(
          start: start,
          end: end,
          child: Image.asset('assets/images/cards/backCard.png', width: 48, height: 72),
        ),
      );
      overlay.insert(entry);
      await Future.delayed(const Duration(milliseconds: 420));
      entry.remove();
    }
  }

  Future<void> _flyHandToCenter(int playerIndex) async {
    final GlobalKey startKey = switch (playerIndex) {
      0 => _playerHandKey,
      1 => _topBotKey,
      2 => _leftBotKey,
      3 => _rightBotKey,
      _ => _playerHandKey,
    };
    final start = _posOf(startKey);
    final screen = MediaQuery.of(context).size;
    final center = Offset(screen.width / 2 - 35, screen.height / 2 - 80);
    final overlay = Overlay.of(context);
    if (overlay == null) return;
    final entry = OverlayEntry(
      builder: (_) => AnimatedCardFly(
        start: start,
        end: center,
        child: Image.asset('assets/images/cards/backCard.png', width: 60, height: 90),
      ),
    );
    overlay.insert(entry);
    await Future.delayed(const Duration(milliseconds: 420));
    entry.remove();
  }

  void _showConfetti() {
    final screen = MediaQuery.of(context).size;
    _confetti?.remove();
    _confetti = OverlayEntry(builder: (_) => ConfettiBurst(center: Offset(screen.width/2, screen.height/2)));
    Overlay.of(context)?.insert(_confetti!);
    Future.delayed(const Duration(milliseconds: 1200), () { _confetti?.remove(); _confetti = null; });
  }

  // ========================= PLAYER INPUT =========================
  Future<void> _onTapPlayerCard(HezzCard card) async {
    if (!playerTurn || choosingSuit) return;
    if (game.pendingDraw > 0) return; // cannot play during pending draw

    if (card.isChangeSuit) {
      pendingChangeSuit = card;
      setState(() => choosingSuit = true);
      await _chooseSuit();
      return;
    }
    if (!game.canPlay(card)) return;

    await _flyHandToCenter(0);
    setState(() {
      game.hands[0].remove(card);
      game.discardPile.add(card);
      game.activeSuit = card.suit;
      if (card.isDrawTwo) { game.pendingDraw += 2; game.forceSkip = true; }
      if (card.isSkip) { game.forceSkip = true; }
      playerTurn = false;
      game.advanceTurn();
    });

    // Win check
    final winner = _winnerIndex();
    if (winner != null) { await _onWin(winner); return; }

    await _runUntilHumanTurn();
    // After loop, if someone finished:
    final winner2 = _winnerIndex();
    if (winner2 != null) { await _onWin(winner2); return; }
  }

  Future<void> _chooseSuit() async {
    final card = pendingChangeSuit; if (card == null) return;
    final chosen = await showModalBottomSheet<Suit>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: Suit.values.map((s) => ListTile(
            leading: const Icon(Icons.style),
            title: Text(s.name.toUpperCase()),
            onTap: () => Navigator.pop(context, s),
          )).toList(),
        ),
      ),
    );
    if (chosen != null) {
      await _flyHandToCenter(0);
      setState(() {
        game.hands[0].remove(card);
        game.discardPile.add(card);
        game.activeSuit = chosen;
        playerTurn = false;
        game.advanceTurn();
        choosingSuit = false;
        pendingChangeSuit = null;
      });
      // Win check
      final winner = _winnerIndex();
      if (winner != null) { await _onWin(winner); return; }
      await _runUntilHumanTurn();
      final winner2 = _winnerIndex();
      if (winner2 != null) { await _onWin(winner2); return; }
    } else {
      setState(() { choosingSuit = false; pendingChangeSuit = null; });
    }
  }

  Future<void> _playerDrawOne() async {
    if (!playerTurn || choosingSuit) return;
    final drawn = game.drawCards(1);
    if (drawn.isEmpty) return;
    await _flyDeckToPlayer(0);
    setState(() => game.hands[0].addAll(drawn));
    setState(() { playerTurn = false; game.advanceTurn(); });
    // After drawing, continue engine
    await _runUntilHumanTurn();
    final winner = _winnerIndex();
    if (winner != null) { await _onWin(winner); return; }
  }

  int? _winnerIndex() {
    for (int i=0;i<game.playerCount;i++) { if (game.hands[i].isEmpty) return i; }
    return null;
  }

  Future<void> _onWin(int winner) async {
    _showConfetti();
    // Navigate to ResultPage showing winner and remaining cards
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ResultPage(winner: winner, hands: game.hands)));
  }

  // ========================= UI =========================
  Widget _avatar(int index, GlobalKey key, String label, IconData icon) {
    final active = game.currentPlayer == index;

    // Randomize bot names only for bots (index != 0)
    final List<String> botNames = ['Rex', 'Zara', 'Milo', 'Luna', 'Neo', 'Kira', 'Finn', 'Jax', 'Nova', 'Leo'];
    if (index != 0) {
      label = botNames[Random().nextInt(botNames.length)];
    }

    return Column(
      key: key,
      children: [
        TurnGlow(
          active: active,
          child: CircleAvatar(
            radius: 22,
            backgroundColor: index == 0 ? Colors.teal : Colors.blueGrey,
            child: Icon(icon, color: Colors.white),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$label • ${game.hands[index].length}', style: const TextStyle(color: Colors.white, fontSize: 12)),
            const SizedBox(width: 4),
            // Face-down card showing remaining deck
            AnimatedCard(
              card: HezzCard(suit: Suit.cups, rank: 1), // dummy card for visual
              faceUp: false,
              width: 40,
              height: 55,
            ),
          ],
        ),
      ],
    );
  }



  @override
  Widget build(BuildContext context) {

    final suitImages = {
      Suit.coins: 'assets/images/UI/BackGrounds/bg2.jpg',
      Suit.clubs: 'assets/images/UI/BackGrounds/bg2.jpg',
      Suit.cups: 'assets/images/UI/BackGrounds/bg2.jpg',
      Suit.swords: 'assets/images/SugarSmash/candy_yellow.png',
    };
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hezz2 — Table'),
        backgroundColor: Colors.black26,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: dealing ? null : _resetGame),
        ],
      ),
      body: Stack(
        children: [
          // Felt background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF0C5B3D), Color(0xFF05261B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
          ),
          // Table circle
          Align(
            alignment: Alignment.center,
            child: Container(
              width: min(size.width, 820),
              height: min(size.width, 820) * 0.62,
              decoration: BoxDecoration(
                color: const Color(0xFF0E4C33),
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 30, spreadRadius: 6)],
              ),
            ),
          ),
          // Main content
          Column(
            children: [
              const SizedBox(height: 20),
              // Top row: top bot avatar
              if (widget.players > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [ _avatar(1, _topBotKey, 'Top', Icons.smart_toy) ],
                ),
              const SizedBox(height: 6),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 10),
                    if (widget.players > 2) _avatar(2, _leftBotKey, 'Left', Icons.smart_toy),
                    const Spacer(),
                    // Center area: discard & draw
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 80,),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Suit: ', style: TextStyle(color: Colors.white70)),
                            if (game.activeSuit != null)
                              Image.asset(
                                suitImages[game.activeSuit]!,
                                width: 28, // adjust size as needed
                                height: 28,
                                color: Colors.white70, // optional tint
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              children: [
                                const Text('TOP', style: TextStyle(color: Colors.white70)),
                                const SizedBox(height: 4),
                                if (game.discardPile.isNotEmpty) AnimatedCard(card: game.topCard, width: 80, height: 120),
                              ],
                            ),
                            const SizedBox(width: 20),
                            Column(
                              children: [
                                const Text('DRAW', style: TextStyle(color: Colors.white70)),
                                const SizedBox(height: 4),
                                Container(
                                  key: _drawPileKey,
                                  width: 75,
                                  height: 110,
                                  alignment: Alignment.center,
                                  child: Image.asset('assets/images/cards/backCard.png'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (widget.players > 3) _avatar(3, _rightBotKey, 'Right', Icons.smart_toy),
                    const SizedBox(width: 10),
                  ],
                ),
              ),
              // Player hand + controls
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A3C2F),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Player info row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TurnGlow(
                          size: 80,
                          active: game.currentPlayer == 0,
                          child: Row(
                            children: const [
                              Icon(Icons.person, color: Colors.white, size: 28),
                              SizedBox(width: 6),
                              Text(
                                'You',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Hand: ${game.hands[0].length}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Player hand
                    SizedBox(
                      key: _playerHandKey,
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: game.hands[0].length,
                        itemBuilder: (context, index) {
                          final card = game.hands[0][index];
                          final playable = game.pendingDraw == 0 && game.canPlay(card);
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Opacity(
                              opacity: playable ? 1 : 0.5,
                              child: GestureDetector(
                                onTap: () => _onTapPlayerCard(card),
                                child: AnimatedCard(card: card, width: 95, height: 142),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: (!dealing && playerTurn && !choosingSuit) ? _playerDrawOne : null,
                          icon: const Icon(Icons.download),
                          label: const Text('Draw'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: dealing ? null : _resetGame,
                          icon: const Icon(Icons.restart_alt),
                          label: const Text('Restart'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Turn status
                    Text(
                      dealing ? 'Dealing Cards…' : (playerTurn ? 'Your Turn' : 'Bot Turn'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              )

            ],
          ),
        ],
      ),
    );
  }

  Future<void> _resetGame() async {
    setState(() {
      game = GameState.newGame(players: widget.players);
      dealing = true; playerTurn = false; choosingSuit = false; pendingChangeSuit = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async { await _dealCards(); await _runUntilHumanTurn(); });
  }
}

// ========================= RESULT PAGE =========================

class ResultPage extends StatelessWidget {
  final int winner;
  final List<List<HezzCard>> hands;
  const ResultPage({super.key, required this.winner, required this.hands});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Result')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              winner == 0 ? 'You Win!' : 'Player ${winner + 1} Wins!',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text('Cards Remaining:', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 12),
            for (int i = 0; i < hands.length; i++)
              Text(
                i == 0 ? 'You: ${hands[i].length}' : 'Player ${i + 1}: ${hands[i].length}',
                style: const TextStyle(fontSize: 18),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const PlayerSelectionPage()), (route) => false),
              child: const Text('Back to Menu'),
            ),
          ],
        ),
      ),
    );
  }
}
