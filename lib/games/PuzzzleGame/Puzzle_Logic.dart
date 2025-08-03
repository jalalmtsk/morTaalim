class PuzzleLogic {
  final int size;
  late List<int> tiles;

  PuzzleLogic({this.size = 4}) {
    _generatePuzzle();
  }

  void _generatePuzzle() {
    tiles = List.generate(size * size, (i) => i);
    tiles.shuffle();
  }

  bool canMove(int index) {
    int emptyIndex = tiles.indexOf(0);
    int row = index ~/ size;
    int col = index % size;
    int emptyRow = emptyIndex ~/ size;
    int emptyCol = emptyIndex % size;

    return (row == emptyRow && (col - emptyCol).abs() == 1) ||
        (col == emptyCol && (row - emptyRow).abs() == 1);
  }

  void moveTile(int index) {
    if (canMove(index)) {
      int emptyIndex = tiles.indexOf(0);
      tiles[emptyIndex] = tiles[index];
      tiles[index] = 0;
    }
  }

  bool isSolved() {
    for (int i = 0; i < tiles.length - 1; i++) {
      if (tiles[i] != i + 1) return false;
    }
    return tiles.last == 0;
  }

  void shuffle() {
    tiles.shuffle();
  }
}
