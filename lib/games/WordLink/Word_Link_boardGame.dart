import 'package:flutter/material.dart';
import 'dart:math';

import 'Path_painter.dart';
import 'board_helpers.dart';

void main() => runApp(const WordGameApp());

class WordGameApp extends StatelessWidget {
  const WordGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const WordBoardGame();

  }
}

class WordBoardGame extends StatefulWidget {
  const WordBoardGame({super.key});

  @override
  State<WordBoardGame> createState() => _WordBoardGameState();
}

class _WordBoardGameState extends State<WordBoardGame> {
  final List<String> allWords = ['APPLE', 'DOG', 'HOUSE', 'CAT', 'FISH', 'SUN', 'MOON'];
  late List<String> displayedWords;
  late List<String> foundWords;
  late List<List<String>> board;
  final int boardSize = 6;

  List<Offset> selectedPath = [];
  String selectedWord = '';
  bool isDragging = false;

  late double tileSize;
  final GlobalKey _boardKey = GlobalKey();


  @override
  void initState() {
    super.initState();
    displayedWords = List.from(allWords)..shuffle();
    foundWords = [];
    board = generateBoardWithWords(displayedWords, boardSize);
  }

  void _generateBoardWithWords() {
    setState(() {
      board = generateBoardWithWords(displayedWords, boardSize);
    });
  }

  bool _canPlaceWord(String word, int row, int col, int dx, int dy) {
    return canPlaceWord(board, word, row, col, dx, dy, boardSize);
  }

  bool _isValidCell(int row, int col) => isValidCell(row, col, boardSize);

  bool _isNeighbor(Offset a, Offset b) => isNeighbor(a, b);


  void _startSelection(int row, int col) {
    if (_isValidCell(row, col)) {
      setState(() {
        selectedPath = [Offset(row.toDouble(), col.toDouble())];
        selectedWord = board[row][col];
        isDragging = true;
      });
    }
  }

  void _updateSelection(int row, int col) {
    if (!isDragging) return;
    final current = Offset(row.toDouble(), col.toDouble());
    if (_isValidCell(row, col)) {
      if (selectedPath.contains(current)) {
        final index = selectedPath.indexOf(current);
        setState(() {
          selectedPath = selectedPath.sublist(0, index + 1);
          selectedWord = selectedPath.map((p) => board[p.dx.toInt()][p.dy.toInt()]).join();
        });
      } else {
        final last = selectedPath.isNotEmpty ? selectedPath.last : null;
        if (last != null && _isNeighbor(last, current)) {
          setState(() {
            selectedPath.add(current);
            selectedWord += board[row][col];
          });
        }
      }
    }
  }

  void _endSelection() {
    if (selectedWord.length > 1) {
      if (displayedWords.contains(selectedWord)) {
        if (!foundWords.contains(selectedWord)) {
          setState(() {
            foundWords.add(selectedWord);
            displayedWords.remove(selectedWord);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Great! You found "$selectedWord".')),
          );
        }
      }
    }
    setState(() {
      selectedPath.clear();
      selectedWord = '';
      isDragging = false;
    });
  }

  Widget _buildBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        tileSize = constraints.maxWidth / boardSize;
        return GestureDetector(
          onPanStart: (details) => _handleTouch(details.localPosition),
          onPanUpdate: (details) => _handleTouch(details.localPosition),
          onPanEnd: (_) => _endSelection(),
          child: CustomPaint(
            painter: PathPainter(selectedPath, tileSize),
            child: GridView.builder(
              key: _boardKey,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(8),
              itemCount: boardSize * boardSize,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: boardSize,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final row = index ~/ boardSize;
                final col = index % boardSize;
                final isSelected = selectedPath.contains(Offset(row.toDouble(), col.toDouble()));

                return Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.orange : Colors.white,
                    border: Border.all(color: Colors.deepOrange),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      board[row][col],
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _handleTouch(Offset position) {
    final row = (position.dy ~/ tileSize);
    final col = (position.dx ~/ tileSize);

    if (!isDragging) {
      _startSelection(row, col);
    } else {
      _updateSelection(row, col);
    }
  }

  Widget _buildWordList() {
    return Column(
      children: [
        const Text('Words Found:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...foundWords.map((word) => Padding(
          padding: const EdgeInsets.all(4.0),
          child: Text(word, style: const TextStyle(fontSize: 18, color: Colors.green)),
        ))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasWon = foundWords.length >= 5;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back)),
        title: const Text('Word Tracing Game'),
        backgroundColor: Colors.deepOrange,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {
              _generateBoardWithWords();
              selectedPath.clear();
              selectedWord = '';
              foundWords.clear();
              displayedWords = List.from(allWords)..shuffle();
            }),
          )
        ],
      ),
      body: Column(
        children: [
          if (hasWon)
            Container(
              color: Colors.green.shade100,
              padding: const EdgeInsets.all(16),
              child: const Text('🎉 You found all 5 words! 🎉',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _buildBoard(),
                  ),
                ),
                const VerticalDivider(width: 2, color: Colors.grey),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _buildWordList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.orange.shade50,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text('Selected: $selectedWord', style: const TextStyle(fontSize: 16)),
              const Spacer(),
              OutlinedButton(
                onPressed: () => _endSelection(),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

