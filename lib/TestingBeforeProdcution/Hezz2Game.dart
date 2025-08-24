/*
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';



// ================= Model =================
enum Suit { cups, swords, coins, clubs }

class HezzCard {
  final Suit suit;
  final int rank;
  const HezzCard({required this.suit, required this.rank});

  bool get isSkip => rank == 1;
  bool get isDrawTwo => rank == 2;
  bool get isChangeSuit => rank == 7;

  String get label {
    switch (rank) {
      case 1:
        return 'SKIP';
      case 2:
        return '+2';
      case 7:
        return '7';
      default:
        return '$rank';
    }
  }

  String get suitLabel {
    switch (suit) {
      case Suit.cups:
        return 'CUPS';
      case Suit.swords:
        return 'SWORDS';
      case Suit.coins:
        return 'COINS';
      case Suit.clubs:
        return 'CLUBS';
    }
  }
}

class DeckBuilder {
  static List<HezzCard> buildDeck() {
    final List<int> ranks = [1, 2, 3, 4, 5, 6, 7, 10, 11, 12];
    final List<HezzCard> deck = [];
    for (final suit in Suit.values) {
      for (final rank in ranks) {
        deck.add(HezzCard(suit: suit, rank: rank));
      }
    }
    deck.shuffle(Random());
    return deck;
  }
}

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

  factory GameState.newGame({int players = 4}) {
    final deck = DeckBuilder.buildDeck();
    final hands = List.generate(players, (_) => <HezzCard>[]);
    final discard = <HezzCard>[];
    return GameState._(
      playerCount: players,
      hands: hands,
      drawPile: deck,
      discardPile: discard,
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

  void advanceTurn([int steps = 1]) {
    currentPlayer = nextIndex(steps);
  }

  bool canPlay(HezzCard card) {
    if (pendingDraw > 0) {
      if (card.isDrawTwo && topCard.isDrawTwo) return true;
      return false;
    }
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
    if (!canPlay(card) || player != currentPlayer) return false;
    hands[player].remove(card);
    discardPile.add(card);
    if (card.isChangeSuit) activeSuit = chosenSuit ?? activeSuit;
    else activeSuit = card.suit;
    if (card.isDrawTwo) pendingDraw += 2;
    if (card.isSkip) forceSkip = true;
    advanceTurn();
    return true;
  }

  void resolveStartOfTurnEffects() {
    if (pendingDraw > 0) {
      hands[currentPlayer].addAll(drawCards(pendingDraw));
      pendingDraw = 0;
      advanceTurn();
    } else if (forceSkip) {
      forceSkip = false;
      advanceTurn();
    }
  }
}

// ================= UI =================
class AnimatedCard extends StatelessWidget {
  final HezzCard card;
  final bool faceUp;
  final double width;
  final double height;
  const AnimatedCard({
    required this.card,
    this.faceUp = true,
    this.width = 80,
    this.height = 120,
    super.key,
  });

  String get assetPath {
    if (!faceUp) return 'assets/images/cards/backCard.png';
    String suit = card.suitLabel.toLowerCase();
    return 'assets/images/cards/${suit}_${card.rank}.png';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: width,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Image.asset(assetPath, fit: BoxFit.cover),
    );
  }
}

// ================= Animated Flying Card =================
class AnimatedCardFly extends StatefulWidget {
  final Offset start;
  final Offset end;
  final VoidCallback? onComplete;
  const AnimatedCardFly({
    required this.start,
    required this.end,
    this.onComplete,
    super.key,
  });

  @override
  State<AnimatedCardFly> createState() => _AnimatedCardFlyState();
}

class _AnimatedCardFlyState extends State<AnimatedCardFly>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _animation = Tween<Offset>(
      begin: widget.start,
      end: widget.end,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && widget.onComplete != null) {
          widget.onComplete!();
        }
      });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offset = _animation.value;
        return Positioned(
          left: offset.dx,
          top: offset.dy,
          child: child!,
        );
      },
      child: Image.asset(
        'assets/images/cards/backCard.png',
        width: 50,
        height: 70,
      ),
    );
  }
}

// ================= Game Page =================
class Hezz2GamePage extends StatefulWidget {
  const Hezz2GamePage({super.key});

  @override
  State<Hezz2GamePage> createState() => _Hezz2GamePageState();
}

class _Hezz2GamePageState extends State<Hezz2GamePage> {
  late GameState game;
  bool dealingCards = true;
  bool playerTurn = false;
  bool choosingSuit = false;
  HezzCard? pending7;

  final GlobalKey drawPileKey = GlobalKey();
  final GlobalKey playerHandKey = GlobalKey();
  final GlobalKey topBotKey = GlobalKey();
  final GlobalKey leftBotKey = GlobalKey();
  final GlobalKey rightBotKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    game = GameState.newGame(players: 4);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      startDealingAnimation();
    });
  }

  Future<void> startDealingAnimation() async {
    const dealDelay = Duration(milliseconds: 250);

    for (int i = 0; i < 7; i++) {
      for (int p = 0; p < game.playerCount; p++) {
        final card = game.drawCards(1).first;
        await flyCardAnimation(p, card);
        setState(() => game.hands[p].add(card));
        await Future.delayed(dealDelay);
      }
    }

    final first = game.drawCards(1).first;
    setState(() {
      game.discardPile.add(first);
      game.activeSuit = first.suit;
      dealingCards = false;
      playerTurn = true;
    });
  }

  Future<void> flyCardAnimation(int player, HezzCard card) async {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    RenderBox? deckBox =
    drawPileKey.currentContext?.findRenderObject() as RenderBox?;
    Offset deckPos = deckBox?.localToGlobal(Offset.zero) ?? Offset.zero;

    GlobalKey targetKey;
    switch (player) {
      case 0:
        targetKey = playerHandKey;
        break;
      case 1:
        targetKey = topBotKey;
        break;
      case 2:
        targetKey = leftBotKey;
        break;
      case 3:
        targetKey = rightBotKey;
        break;
      default:
        targetKey = playerHandKey;
    }

    RenderBox? targetBox =
    targetKey.currentContext?.findRenderObject() as RenderBox?;
    Offset targetPos = targetBox?.localToGlobal(Offset.zero) ?? deckPos;

    final completer = Completer<void>();

    OverlayEntry entry = OverlayEntry(
      builder: (_) {
        return AnimatedCardFly(
          start: deckPos,
          end: targetPos,
          onComplete: () => completer.complete(),
        );
      },
    );

    overlay.insert(entry);
    await completer.future;
    entry.remove();
  }

  Future<void> drawCardAction(int player) async {
    if (!playerTurn || player != 0) return;
    final drawn = game.drawCards(1);
    if (drawn.isEmpty) return;

    setState(() {
      game.hands[player].addAll(drawn);
      playerTurn = false;
    });

    await flyCardAnimation(player, drawn.first);

    await Future.delayed(const Duration(milliseconds: 400));
    game.resolveStartOfTurnEffects();
    await botTurn();
    setState(() => playerTurn = true);
  }

  Future<void> botTurn() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Simple bot logic
    for (int i = 1; i < game.playerCount; i++) {
      final hand = game.hands[i];
      final playable = hand.where((c) => game.canPlay(c)).toList();
      if (playable.isNotEmpty) {
        final card = playable.first;
        hand.remove(card);
        game.discardPile.add(card);
        if (card.isChangeSuit) {
          game.activeSuit = Suit.values[Random().nextInt(4)];
        } else {
          game.activeSuit = card.suit;
        }
      } else {
        hand.addAll(game.drawCards(1));
      }
      game.resolveStartOfTurnEffects();
    }
  }

  void resetGame() {
    setState(() {
      game = GameState.newGame(players: 4);
      dealingCards = true;
      playerTurn = false;
      pending7 = null;
      choosingSuit = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      startDealingAnimation();
    });
  }

  Widget botCardBack(int count, String label, {Key? key}) {
    return Column(
      key: key,
      children: [
        Text('$label: $count', style: const TextStyle(fontSize: 14)),
        SizedBox(
          width: 50,
          height: 70,
          child: Stack(
            children: List.generate(
              count,
                  (i) => Positioned(
                left: i.toDouble() * 2,
                top: i.toDouble() * 2,
                child: Image.asset(
                  'assets/images/cards/backCard.png',
                  width: 50,
                  height: 70,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hezz2 Moroccan Card Game')),
      body: Stack(
        children: [
          Center(
            child: Column(
              children: [
                const SizedBox(height: 10),
                botCardBack(game.hands[1].length, 'Top Bot', key: topBotKey),
                const SizedBox(height: 20),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      botCardBack(game.hands[2].length, 'Left Bot', key: leftBotKey),
                      const Spacer(),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                              'Current Suit: ${game.activeSuit.toString().split('.').last.toUpperCase()}'),
                          const SizedBox(height: 4),
                          const Text("Top Card"),
                          if (game.discardPile.isNotEmpty)
                            AnimatedCard(card: game.topCard),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("Draw Pile"),
                          Container(
                            key: drawPileKey,
                            width: 60,
                            height: 90,
                            child: Image.asset('assets/images/cards/backCard.png'),
                          ),
                        ],
                      ),
                      const Spacer(),
                      botCardBack(game.hands[3].length, 'Right Bot', key: rightBotKey),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text('Your Cards: ${game.hands[0].length}'),
                    SizedBox(
                      key: playerHandKey,
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: game.hands[0].length,
                        itemBuilder: (context, index) {
                          final card = game.hands[0][index];
                          return GestureDetector(
                            onTap: playerTurn && !choosingSuit
                                ? () async {
                              if (card.isChangeSuit) {
                                pending7 = card;
                                setState(() => choosingSuit = true);
                              } else if (game.canPlay(card)) {
                                setState(() {
                                  game.hands[0].remove(card);
                                  game.discardPile.add(card);
                                  game.activeSuit = card.suit;
                                  playerTurn = false;
                                });
                                await Future.delayed(
                                    const Duration(milliseconds: 400));
                                game.resolveStartOfTurnEffects();
                                await botTurn();
                                setState(() => playerTurn = true);
                              }
                            }
                                : null,
                            child: AnimatedCard(card: card, width: 80, height: 120),
                          );
                        },
                      ),
                    ),
                    if (choosingSuit)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: Suit.values
                            .map(
                              (s) => Padding(
                            padding: const EdgeInsets.all(4),
                            child: ElevatedButton(
                              onPressed: () {
                                if (pending7 != null) {
                                  setState(() {
                                    game.hands[0].remove(pending7!);
                                    game.discardPile.add(pending7!);
                                    game.activeSuit = s;
                                    pending7 = null;
                                    choosingSuit = false;
                                    playerTurn = false;
                                  });
                                  Future.delayed(
                                      const Duration(milliseconds: 400), () async {
                                    game.resolveStartOfTurnEffects();
                                    await botTurn();
                                    setState(() => playerTurn = true);
                                  });
                                }
                              },
                              child: Text(s.toString().split('.').last.toUpperCase()),
                            ),
                          ),
                        )
                            .toList(),
                      ),
                    ElevatedButton(
                      onPressed:
                      (dealingCards || !playerTurn) ? null : () => drawCardAction(0),
                      child: const Text("Draw Card"),
                    ),
                    ElevatedButton(
                      onPressed: dealingCards ? null : resetGame,
                      child: const Text("Restart"),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      dealingCards
                          ? "Dealing Cards..."
                          : (playerTurn ? "Your Turn" : "Bot Turn"),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


 */