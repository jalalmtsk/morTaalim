import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import '../TestingBeforeProdcution/CardConcept_resultPage.dart';


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
      home: const GameLauncherOnline(),
    );
  }
}

class GameLauncherOnline extends StatefulWidget {
  const GameLauncherOnline({super.key});
  @override
  State<GameLauncherOnline> createState() => _GameLauncherState();
}

class _GameLauncherState extends State<GameLauncherOnline> {
  int handSize = 7;
  int playerCount = 2; // max 4 players including human
  String playerName = '';
  String? roomId;

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
              TextField(
                decoration: const InputDecoration(labelText: 'Your Name'),
                onChanged: (v) => playerName = v,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Hand Size:'),
                  const SizedBox(width: 10),
                  DropdownButton<int>(
                    value: handSize,
                    items: List.generate(11, (i) => i + 5).map((v) => DropdownMenuItem(value: v, child: Text('$v'))).toList(),
                    onChanged: (v) => setState(() => handSize = v ?? 7),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Players:'),
                  const SizedBox(width: 10),
                  DropdownButton<int>(
                    value: playerCount,
                    items: [2, 3, 4].map((v) => DropdownMenuItem(value: v, child: Text('$v'))).toList(),
                    onChanged: (v) => setState(() => playerCount = v ?? 2),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  // Generate room if empty
                  roomId ??= 'room_${Random().nextInt(9999)}';
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GameScreen(
                        startHandSize: handSize,
                        playerCount: playerCount,
                        playerName: playerName,
                        roomId: roomId,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start / Join Game'),
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
  final String suit;
  final int rank;
  final String id;
  PlayingCard({required this.suit, required this.rank}) : id = UniqueKey().toString();
  String get assetName => 'assets/images/cards/${suit.toLowerCase()}_$rank.png';
  String get backAsset => 'assets/images/cards/backCard.png';
}

class Deck {
  final List<PlayingCard> cards = [];
  Deck() { _build(); }
  void _build() {
    cards.clear();
    final suits = ['Coins','Cups','Swords','Clubs'];
    final ranks = [1,2,3,4,5,6,7,10,11,12];
    for(final s in suits) for(final r in ranks) cards.add(PlayingCard(suit: s, rank: r));
  }
  void shuffle() => cards.shuffle(Random());
  PlayingCard draw() => cards.removeLast();
  bool get isEmpty => cards.isEmpty;
}

// --- Game Screen ---
class GameScreen extends StatefulWidget {
  final int startHandSize;
  final int playerCount;
  final String playerName;
  final String? roomId;
  const GameScreen({
    required this.startHandSize,
    required this.playerCount,
    required this.playerName,
    this.roomId,
    super.key,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late Deck deck;
  late List<List<PlayingCard>> hands;
  PlayingCard? topCard;
  List<PlayingCard> discard = [];
  int currentPlayer = 0;
  bool isAnimating = false;
  bool gameOver = false;
  String winner = '';
  int pendingDraw = 0;
  bool skipNext = false;

  final deckKey = GlobalKey();
  final centerKey = GlobalKey();
  final playerHandKey = GlobalKey();
  final botKeys = List.generate(5, (_) => GlobalKey());

  late DatabaseReference dbRef;

  @override
  void initState() {
    super.initState();
    hands = List.generate(widget.playerCount, (_) => []);
    deck = Deck()..shuffle();

    // Firebase DB ref
    if (widget.roomId != null) {
      dbRef = FirebaseDatabase.instance.ref('games/${widget.roomId}');
      _setupOnlineListener();
      _joinRoom();
    } else {
      _startLocalGame();
    }
  }

  // --- Online Sync ---
  void _updateOnlineState() {
    dbRef.set({
      'hands': hands
          .map((h) => h.map((c) => {'suit': c.suit, 'rank': c.rank}).toList())
          .toList(),
      'topCard': topCard == null ? null : {'suit': topCard!.suit, 'rank': topCard!.rank},
      'discard': discard.map((c) => {'suit': c.suit, 'rank': c.rank}).toList(),
      'currentPlayer': currentPlayer,
      'pendingDraw': pendingDraw,
      'skipNext': skipNext,
    });
  }

  void _setupOnlineListener() {
    dbRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return;

      final rawHands = data['hands'] as List<dynamic>?;
      if (rawHands != null) {
        hands = rawHands.map<List<PlayingCard>>((h) {
          final list = h as List<dynamic>;
          return list.map((c) => PlayingCard(suit: c['suit'], rank: c['rank'])).toList();
        }).toList();
      }

      final top = data['topCard'];
      if (top != null) topCard = PlayingCard(suit: top['suit'], rank: top['rank']);
      discard = (data['discard'] as List<dynamic>?)
          ?.map((c) => PlayingCard(suit: c['suit'], rank: c['rank']))
          .toList() ??
          [];
      currentPlayer = data['currentPlayer'] ?? 0;
      pendingDraw = data['pendingDraw'] ?? 0;
      skipNext = data['skipNext'] ?? false;

      setState(() {});
    });
  }

  void _joinRoom() {
    dbRef.child('players/${widget.playerName}').set({'joinedAt': ServerValue.timestamp});
  }

  Future<void> _startLocalGame() async {
    hands.forEach((h) => h.clear());
    discard.clear();
    deck.shuffle();
    currentPlayer = 0;
    pendingDraw = 0;
    skipNext = false;
    gameOver = false;
    winner = '';

    // Deal
    for (int i = 0; i < widget.startHandSize; i++) {
      for (int p = 0; p < widget.playerCount; p++) {
        if (deck.isEmpty) _recycle();
        hands[p].add(deck.draw());
      }
    }

    topCard = deck.draw();
    discard.add(topCard!);
    setState(() {});
  }

  void _recycle() {
    if (discard.length <= 1) return;
    final top = discard.removeLast();
    deck.cards.addAll(discard);
    discard.clear();
    discard.add(top);
    deck.shuffle();
  }

  bool _isPlayable(PlayingCard c) {
    if (pendingDraw > 0) return c.rank == 2;
    if (topCard == null) return true;
    return c.suit == topCard!.suit || c.rank == topCard!.rank;
  }

  Future<void> _playCard(int player, int idx) async {
    if (gameOver) return;
    final card = hands[player][idx];
    hands[player].removeAt(idx);
    topCard = card;
    discard.add(card);
    _handleSpecial(player, card);
    _checkWin(player);
    _advanceTurn();
    setState(() {});
    _updateOnlineState();
  }

  void _handleSpecial(int player, PlayingCard card) {
    if (card.rank == 2) pendingDraw += 2;
    if (card.rank == 1) skipNext = true;
  }

  void _advanceTurn() {
    int next = (currentPlayer + 1) % widget.playerCount;
    if (skipNext) {
      skipNext = false;
      next = (next + 1) % widget.playerCount;
    }
    currentPlayer = next;
    setState(() {});
  }

  void _checkWin(int p) {
    if (hands[p].isEmpty) {
      gameOver = true;
      winner = p == 0 ? 'You' : 'Bot $p';
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: const Text('Bright Cards')),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF6F6F8), Color(0xFFECF9F0)],
                  ),
                ),
              ),
            ),
            // Top bots
            Align(
              alignment: Alignment.topCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.playerCount - 1,
                      (i) => Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 50,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        Text('${hands[i + 1].length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Center deck & discard
            Align(
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Deck
                  GestureDetector(
                    onTap: currentPlayer == 0 ? _drawCard : null,
                    child: Container(
                      width: 60,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.blueGrey,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Center(child: Text('Deck', style: TextStyle(color: Colors.white))),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Top card
                  if (topCard != null)
                    Image.asset(
                      topCard!.assetName,
                      width: 60,
                      height: 90,
                      fit: BoxFit.cover,
                    ),
                ],
              ),
            ),
            // Player hand
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: hands[0].length,
                  itemBuilder: (context, i) {
                    final card = hands[0][i];
                    return GestureDetector(
                      onTap: currentPlayer == 0 && _isPlayable(card) ? () => _playCard(0, i) : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Image.asset(
                          card.assetName,
                          width: 60,
                          height: 90,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Winner overlay
            if (gameOver)
              Center(
                child: Container(
                  color: Colors.black54,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      '$winner Wins!',
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _drawCard() {
    if (deck.isEmpty) _recycle();
    hands[0].add(deck.draw());
    _advanceTurn();
    _updateOnlineState();
    setState(() {});
  }
}


