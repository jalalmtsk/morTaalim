import 'dart:math';
import 'package:flutter/material.dart';


// === GAME MODEL ===

enum CardColor { red, yellow, green, blue, wild }

enum CardType { number, skip, reverse, drawTwo, wild, wildDrawFour }

class UnoCard {
  final CardColor color; // wild for wild/wildDrawFour
  final CardType type;
  final int? number; // 0..9 for number cards

  const UnoCard({required this.color, required this.type, this.number});

  bool get isWild => type == CardType.wild || type == CardType.wildDrawFour;

  String get label {
    switch (type) {
      case CardType.number:
        return number?.toString() ?? '';
      case CardType.skip:
        return '⛔';
      case CardType.reverse:
        return '🔁';
      case CardType.drawTwo:
        return '+2';
      case CardType.wild:
        return 'WILD';
      case CardType.wildDrawFour:
        return 'WILD +4';
    }
  }
}

class DeckBuilder {
  static List<UnoCard> buildDeck() {
    final List<UnoCard> deck = [];
    // Standard UNO-like counts (approximate):
    // For each color: one 0, two each of 1..9, two Skip, two Reverse, two +2
    for (final color in [CardColor.red, CardColor.yellow, CardColor.green, CardColor.blue]) {
      deck.add(UnoCard(color: color, type: CardType.number, number: 0));
      for (int n = 1; n <= 9; n++) {
        deck.add(UnoCard(color: color, type: CardType.number, number: n));
        deck.add(UnoCard(color: color, type: CardType.number, number: n));
      }
      for (int i = 0; i < 2; i++) {
        deck.add(UnoCard(color: color, type: CardType.skip));
        deck.add(UnoCard(color: color, type: CardType.reverse));
        deck.add(UnoCard(color: color, type: CardType.drawTwo));
      }
    }
    // Wild cards: 4 Wild, 4 Wild Draw Four
    for (int i = 0; i < 4; i++) {
      deck.add(const UnoCard(color: CardColor.wild, type: CardType.wild));
      deck.add(const UnoCard(color: CardColor.wild, type: CardType.wildDrawFour));
    }
    deck.shuffle(Random());
    return deck;
  }
}

class GameState {
  final int playerCount;
  final List<List<UnoCard>> hands;
  final List<UnoCard> drawPile;
  final List<UnoCard> discardPile;
  int currentPlayer;
  int direction; // 1 clockwise, -1 counter-clockwise
  CardColor activeColor; // after wild, can be set to chosen color
  int pendingDraw; // accumulation of +2 or +4 to be applied to next player
  bool forceSkip; // for Skip

  GameState._({
    required this.playerCount,
    required this.hands,
    required this.drawPile,
    required this.discardPile,
    required this.currentPlayer,
    required this.direction,
    required this.activeColor,
    required this.pendingDraw,
    required this.forceSkip,
  });

  factory GameState.newGame({int players = 4, int startingCards = 7}) {
    assert(players >= 2);
    final deck = DeckBuilder.buildDeck();
    final hands = List.generate(players, (_) => <UnoCard>[]);
    for (int i = 0; i < startingCards; i++) {
      for (int p = 0; p < players; p++) {
        hands[p].add(deck.removeLast());
      }
    }
    // Flip first non-wild as starting discard; if wild appears, set random color
    UnoCard first = deck.removeLast();
    while (first.isWild) {
      // put it back at random position to avoid wild start
      deck.insert(Random().nextInt(deck.length + 1), first);
      first = deck.removeLast();
    }

    final discard = <UnoCard>[first];

    return GameState._(
      playerCount: players,
      hands: hands,
      drawPile: deck,
      discardPile: discard,
      currentPlayer: 0,
      direction: 1,
      activeColor: first.color,
      pendingDraw: 0,
      forceSkip: false,
    );
  }

  UnoCard get topCard => discardPile.last;

  int nextIndex([int steps = 1]) {
    final n = playerCount;
    int idx = currentPlayer;
    for (int i = 0; i < steps; i++) {
      idx = (idx + direction) % n;
      if (idx < 0) idx += n;
    }
    return idx;
  }

  void advanceTurn({int steps = 1}) {
    currentPlayer = nextIndex(steps);
  }

  bool canPlay(UnoCard card) {
    if (pendingDraw > 0) {
      // Only allow stacking same draw type (+2 on +2, +4 on +4)
      if (card.type == CardType.drawTwo && topCard.type == CardType.drawTwo) return true;
      if (card.type == CardType.wildDrawFour && (topCard.type == CardType.wildDrawFour)) return true;
      return false;
    }
    // Match color, number, or symbol; wilds always ok
    if (card.isWild) return true;
    if (card.color == activeColor) return true;
    if (card.type == topCard.type && card.type != CardType.number) return true;
    if (card.type == CardType.number && topCard.type == CardType.number && card.number == topCard.number) {
      return true;
    }
    return false;
  }

  void reshuffleIfNeeded() {
    if (drawPile.isEmpty) {
      if (discardPile.length <= 1) return; // nothing to reshuffle
      final top = discardPile.removeLast();
      drawPile.addAll(discardPile);
      discardPile.clear();
      discardPile.add(top);
      drawPile.shuffle(Random());
    }
  }

  List<UnoCard> drawCards(int count) {
    final drawn = <UnoCard>[];
    for (int i = 0; i < count; i++) {
      reshuffleIfNeeded();
      if (drawPile.isEmpty) break;
      drawn.add(drawPile.removeLast());
    }
    return drawn;
  }

  // Returns true if a color must be chosen after play (i.e., wild)
  bool playCard(int player, UnoCard card, {CardColor? chosenColor}) {
    assert(player == currentPlayer);
    if (!canPlay(card)) return false;

    // Remove from hand
    hands[player].remove(card);
    discardPile.add(card);

    // Update active color
    if (card.isWild) {
      activeColor = chosenColor ?? activeColor; // UI must set this if null
    } else {
      activeColor = card.color;
    }

    // Apply effects
    switch (card.type) {
      case CardType.reverse:
        direction *= -1;
        if (playerCount == 2) {
          // In 2-player, reverse acts as skip
          advanceTurn();
        }
        break;
      case CardType.skip:
        forceSkip = true;
        break;
      case CardType.drawTwo:
        pendingDraw += 2;
        break;
      case CardType.wildDrawFour:
        pendingDraw += 4;
        break;
      case CardType.number:
      case CardType.wild:
        break;
    }

    return true;
  }

  // Execute start-of-turn penalties/effects on the (currentPlayer)
  void resolveStartOfTurnEffects() {
    if (pendingDraw > 0) {
      final cards = drawCards(pendingDraw);
      hands[currentPlayer].addAll(cards);
      pendingDraw = 0;
      // After drawing, player is skipped
      advanceTurn();
      return;
    }
    if (forceSkip) {
      forceSkip = false;
      advanceTurn();
      return;
    }
  }
}

// === UI ===

class UnoGamePage extends StatefulWidget {
  const UnoGamePage({super.key});

  @override
  State<UnoGamePage> createState() => _UnoGamePageState();
}

class _UnoGamePageState extends State<UnoGamePage> {
  late GameState game;
  bool choosingColor = false;
  UnoCard? pendingWild;

  @override
  void initState() {
    super.initState();
    game = GameState.newGame(players: 4, startingCards: 7);
  }

  void resetGame() {
    setState(() {
      game = GameState.newGame(players: 4, startingCards: 7);
      choosingColor = false;
      pendingWild = null;
    });
  }

  Future<void> nextTurnAndMaybeBotPlay() async {
    // Advance to next player's turn
    game.advanceTurn();
    setState(() {});

    await Future.delayed(const Duration(milliseconds: 350));

    // If it's a bot (players 1..3), let them play automatically
    while (game.currentPlayer != 0) {
      // Resolve start-of-turn effects
      game.resolveStartOfTurnEffects();
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 350));
      if (game.currentPlayer == 0) break; // got skipped due to effects

      final played = await _botPlay(game.currentPlayer);
      setState(() {});

      if (_checkWinner() != null) return;

      if (!played) {
        // Bot draws one card; if playable, it plays it immediately
        final draw = game.drawCards(1);
        game.hands[game.currentPlayer].addAll(draw);
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 350));

        final playable = draw.isNotEmpty ? draw.firstWhere(
              (c) => game.canPlay(c),
          orElse: () => const UnoCard(color: CardColor.wild, type: CardType.wild), // dummy
        ) : null;

        if (playable != null && game.canPlay(playable)) {
          await _playFromBot(playable);
          setState(() {});
        } else {
          // end turn
          game.advanceTurn();
          setState(() {});
        }
      }
    }
  }

  Future<bool> _botPlay(int player) async {
    // If effects already applied and they were skipped or forced to draw, we might already be on next turn.
    if (game.currentPlayer != player) return false;

    final hand = List<UnoCard>.from(game.hands[player]);

    // Try to play a legal card.
    for (final card in hand) {
      if (game.canPlay(card)) {
        if (card.isWild) {
          final chosen = _chooseBestColorForBot(player);
          game.playCard(player, card, chosenColor: chosen);
        } else {
          game.playCard(player, card);
        }
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 350));

        // After playing, apply any immediate effects to next player on their turn start
        await nextTurnAndMaybeBotPlay();
        return true;
      }
    }
    return false;
  }

  Future<void> _playFromBot(UnoCard card) async {
    final player = game.currentPlayer;
    if (card.isWild) {
      final chosen = _chooseBestColorForBot(player);
      game.playCard(player, card, chosenColor: chosen);
    } else {
      game.playCard(player, card);
    }
    await nextTurnAndMaybeBotPlay();
  }

  CardColor _chooseBestColorForBot(int player) {
    final counts = <CardColor, int>{
      CardColor.red: 0,
      CardColor.yellow: 0,
      CardColor.green: 0,
      CardColor.blue: 0,
    };
    for (final c in game.hands[player]) {
      if (c.color != CardColor.wild) {
        counts[c.color] = (counts[c.color] ?? 0) + 1;
      }
    }
    // Choose the color with max count; fallback activeColor
    CardColor best = game.activeColor;
    int bestCount = -1;
    counts.forEach((k, v) {
      if (v > bestCount) {
        bestCount = v;
        best = k;
      }
    });
    return best;
  }

  CardColor? _checkWinner() {
    for (int p = 0; p < game.playerCount; p++) {
      if (game.hands[p].isEmpty) return game.activeColor; // someone won
    }
    return null;
  }

  Future<void> _onPlayCard(UnoCard card) async {
    // Player turn only
    if (game.currentPlayer != 0) return;

    if (!game.canPlay(card)) {
      _snack('You cannot play that card.');
      return;
    }

    if (card.isWild) {
      setState(() {
        choosingColor = true;
        pendingWild = card;
      });
      return; // wait for color choice
    }

    game.playCard(0, card);
    setState(() {});

    if (_checkWinner() != null) return;

    await nextTurnAndMaybeBotPlay();
  }

  void _chooseColorAndPlay(CardColor chosen) async {
    final card = pendingWild;
    if (card == null) return;
    game.playCard(0, card, chosenColor: chosen);
    choosingColor = false;
    pendingWild = null;
    setState(() {});
    if (_checkWinner() != null) return;
    await nextTurnAndMaybeBotPlay();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(milliseconds: 900)),
    );
  }

  Future<void> _onDrawCard() async {
    if (game.currentPlayer != 0) return;

    // Resolve start-of-turn effects if any
    if (game.pendingDraw > 0 || game.forceSkip) {
      _snack('Effects will apply at the start of your turn.');
      return;
    }

    final drawn = game.drawCards(1);
    if (drawn.isNotEmpty) {
      final card = drawn.first;
      game.hands[0].add(card);
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 200));
      if (game.canPlay(card)) {
        // Auto-suggestion: tap to play
        _snack('You drew a playable card. Tap it to play.');
      } else {
        // end turn
        await nextTurnAndMaybeBotPlay();
      }
    }
  }

  Widget _pileCard(UnoCard card, {double width = 84, double height = 120}) {
    final Color bg;
    switch (card.color) {
      case CardColor.red:
        bg = Colors.red;
        break;
      case CardColor.yellow:
        bg = Colors.yellow.shade700;
        break;
      case CardColor.green:
        bg = Colors.green;
        break;
      case CardColor.blue:
        bg = Colors.blue;
        break;
      case CardColor.wild:
        bg = Colors.black87;
        break;
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(blurRadius: 6, offset: Offset(0, 3), spreadRadius: 1, color: Colors.black26)],
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Center(
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              card.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: card.color == CardColor.yellow ? Colors.black : Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cardBack({double width = 64, double height = 96}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.purple, Colors.indigo]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(blurRadius: 6, offset: Offset(0, 3), spreadRadius: 1, color: Colors.black26)],
      ),
      child: const Center(
        child: Icon(Icons.casino, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _handCard(UnoCard card) {
    final playable = game.canPlay(card) && game.currentPlayer == 0;
    return GestureDetector(
      onTap: () => _onPlayCard(card),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: playable ? 1.0 : 0.6,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: _pileCard(card, width: 68, height: 100),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = game.topCard;

    return Scaffold(
      appBar: AppBar(
        title: const Text('UNO-like (Flutter) – Demo'),
        actions: [
          IconButton(onPressed: resetGame, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Opponents row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(3, (i) {
                    final pIndex = (i + 1) % 4; // players 1,2,3 visual
                    final isTurn = game.currentPlayer == pIndex;
                    return Column(
                      children: [
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            _cardBack(width: 50, height: 76),
                            Positioned(
                              right: 0,
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: isTurn ? Colors.orange : Colors.grey.shade600,
                                child: Text('${game.hands[pIndex].length}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('BOT ${pIndex}', style: TextStyle(fontWeight: isTurn ? FontWeight.bold : FontWeight.normal)),
                      ],
                    );
                  }),
                ),
              ),

              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Piles
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              GestureDetector(
                                onTap: _onDrawCard,
                                child: _cardBack(width: 84, height: 120),
                              ),
                              Positioned(
                                bottom: 4,
                                child: Text('DRAW', style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                          const SizedBox(width: 24),
                          Column(
                            children: [
                              _pileCard(top, width: 84, height: 120),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _colorDot(CardColor.red),
                                  _colorDot(CardColor.yellow),
                                  _colorDot(CardColor.green),
                                  _colorDot(CardColor.blue),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text('Active: ${game.activeColor.name.toUpperCase()}  •  Dir: ${game.direction == 1 ? '↻' : '↺'}'),
                              if (game.pendingDraw > 0)
                                Text('Pending Draw: +${game.pendingDraw}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Player hand
              Container(
                height: 150,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black26)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 6),
                      child: Row(
                        children: [
                          Icon(game.currentPlayer == 0 ? Icons.play_arrow : Icons.pause_circle_filled),
                          const SizedBox(width: 6),
                          const Text('Your Hand', style: TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: (game.currentPlayer == 0) ? () {
                              // If you cannot play anything, allow skip (house rule)
                              final anyPlayable = game.hands[0].any((c) => game.canPlay(c));
                              if (anyPlayable) {
                                _snack('You have a playable card.');
                                return;
                              }
                              nextTurnAndMaybeBotPlay();
                            } : null,
                            icon: const Icon(Icons.skip_next),
                            label: const Text('Skip'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: game.hands[0].map(_handCard).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (choosingColor) _buildColorPickerOverlay(),

          if (_checkWinner() != null) _buildWinOverlay(),
        ],
      ),
    );
  }

  Widget _colorDot(CardColor color) {
    Color c;
    switch (color) {
      case CardColor.red:
        c = Colors.red;
        break;
      case CardColor.yellow:
        c = Colors.yellow.shade700;
        break;
      case CardColor.green:
        c = Colors.green;
        break;
      case CardColor.blue:
        c = Colors.blue;
        break;
      case CardColor.wild:
        c = Colors.black87;
        break;
    }
    final active = game.activeColor == color;
    return Container(
      width: 14,
      height: 14,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        border: Border.all(color: active ? Colors.white : Colors.black54, width: active ? 2 : 1),
      ),
    );
  }

  Widget _buildColorPickerOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Choose a color for WILD', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  children: [
                    _colorPickButton(CardColor.red, Colors.red),
                    _colorPickButton(CardColor.yellow, Colors.yellow.shade700),
                    _colorPickButton(CardColor.green, Colors.green),
                    _colorPickButton(CardColor.blue, Colors.blue),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _colorPickButton(CardColor color, Color visual) {
    return ElevatedButton(
      onPressed: () => _chooseColorAndPlay(color),
      style: ElevatedButton.styleFrom(
        backgroundColor: visual,
        foregroundColor: color == CardColor.yellow ? Colors.black : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(color.name.toUpperCase()),
    );
  }

  Widget _buildWinOverlay() {
    int winner = -1;
    for (int i = 0; i < game.playerCount; i++) {
      if (game.hands[i].isEmpty) winner = i;
    }
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉 Game Over!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(winner == 0 ? 'You won!' : 'BOT $winner won!'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: resetGame,
                  icon: const Icon(Icons.replay),
                  label: const Text('Play Again'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
