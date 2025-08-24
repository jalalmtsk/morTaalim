import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';


// --- Room Launcher ---
class RoomLauncher extends StatefulWidget {
  const RoomLauncher({super.key});
  @override
  State<RoomLauncher> createState() => _RoomLauncherState();
}

class _RoomLauncherState extends State<RoomLauncher> {
  String? roomId;
  String playerName = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Online Tic-Tac-Toe')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Your Name'),
              onChanged: (v) => playerName = v,
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: const InputDecoration(labelText: 'Room ID (leave blank to create)'),
              onChanged: (v) => roomId = v,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (playerName.isEmpty) return;
                final id = roomId ?? 'room_${DateTime.now().millisecondsSinceEpoch}';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TicTacToeGame(roomId: id, playerName: playerName),
                  ),
                );
              },
              child: const Text('Join / Create Room'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Tic-Tac-Toe Game ---
class TicTacToeGame extends StatefulWidget {
  final String roomId;
  final String playerName;
  const TicTacToeGame({required this.roomId, required this.playerName, super.key});

  @override
  State<TicTacToeGame> createState() => _TicTacToeGameState();
}

class _TicTacToeGameState extends State<TicTacToeGame> {
  late DatabaseReference dbRef;
  List<String?> board = List.filled(9, null);
  String currentTurn = 'X';
  String? winner;
  String? mySymbol;

  @override
  void initState() {
    super.initState();
    dbRef = FirebaseDatabase.instance.ref('tic_tac_toe/${widget.roomId}');
    _joinRoom();
    dbRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return;
      setState(() {
        board = List<String?>.from(data['board'] ?? List.filled(9, null));
        currentTurn = data['currentTurn'] ?? 'X';
        winner = data['winner'];
        final players = data['players'] as Map<dynamic, dynamic>? ?? {};
        mySymbol = players[widget.playerName]?['symbol'];
      });
    });
  }

  Future<void> _joinRoom() async {
    final snapshot = await dbRef.get();
    if (!snapshot.exists) {
      await dbRef.set({
        'players': {},
        'board': List.filled(9, null),
        'currentTurn': 'X',
        'winner': null,
      });
    }

    final playersSnapshot = await dbRef.child('players').get();
    final players = playersSnapshot.value as Map<dynamic, dynamic>? ?? {};
    String symbol = players.isEmpty ? 'X' : 'O';
    await dbRef.child('players/${widget.playerName}').set({'symbol': symbol});
  }

  void _makeMove(int index) {
    if (winner != null || currentTurn != mySymbol || board[index] != null) return;
    board[index] = mySymbol;
    currentTurn = mySymbol == 'X' ? 'O' : 'X';
    winner = _checkWinner(board);
    dbRef.update({'board': board, 'currentTurn': currentTurn, 'winner': winner});
  }

  String? _checkWinner(List<String?> b) {
    const winPositions = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];
    for (var pos in winPositions) {
      if (b[pos[0]] != null && b[pos[0]] == b[pos[1]] && b[pos[0]] == b[pos[2]]) {
        return b[pos[0]];
      }
    }
    if (b.every((e) => e != null)) return 'Draw';
    return null;
  }

  void _resetGame() {
    board = List.filled(9, null);
    currentTurn = 'X';
    winner = null;
    dbRef.update({'board': board, 'currentTurn': currentTurn, 'winner': winner});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Room: ${widget.roomId}')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('You are: $mySymbol', style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 20),
          if (winner != null)
            Text(winner == 'Draw' ? 'It\'s a Draw!' : '$winner Wins!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            itemCount: 9,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
            itemBuilder: (context, i) => GestureDetector(
              onTap: () => _makeMove(i),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(board[i] ?? '', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _resetGame, child: const Text('Reset Game')),
        ],
      ),
    );
  }
}
