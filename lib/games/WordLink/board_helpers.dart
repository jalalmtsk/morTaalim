import 'dart:math';
import 'dart:ui';

bool canPlaceWord(List<List<String>> board, String word, int row, int col, int dx, int dy, int boardSize) {
  for (int i = 0; i < word.length; i++) {
    int newRow = row + i * dx;
    int newCol = col + i * dy;
    if (newRow < 0 || newRow >= boardSize || newCol < 0 || newCol >= boardSize) return false;
    if (board[newRow][newCol].isNotEmpty && board[newRow][newCol] != word[i]) return false;
  }
  return true;
}

List<List<String>> generateBoardWithWords(List<String> displayedWords, int boardSize) {
  final rand = Random();
  List<List<String>> board = List.generate(
    boardSize,
        (_) => List.generate(boardSize, (_) => ''),
  );

  for (var word in displayedWords.take(5)) {
    int attempts = 0;
    const maxAttempts = 100;

    while (true) {
      if (attempts++ > maxAttempts) {
        // If too many attempts, regenerate board recursively (or handle as you want)
        return generateBoardWithWords(displayedWords, boardSize);
      }

      int direction = rand.nextInt(8); // 0:→ 1:↓ 2:↘ 3:↙ 4:↖ 5:↗ 6:↑ 7:←
      int dx = 0, dy = 0;
      switch (direction) {
        case 0:
          dx = 0;
          dy = 1;
          break;
        case 1:
          dx = 1;
          dy = 0;
          break;
        case 2:
          dx = 1;
          dy = 1;
          break;
        case 3:
          dx = 1;
          dy = -1;
          break;
        case 4:
          dx = -1;
          dy = -1;
          break;
        case 5:
          dx = -1;
          dy = 1;
          break;
        case 6:
          dx = -1;
          dy = 0;
          break;
        case 7:
          dx = 0;
          dy = -1;
          break;
      }

      int row = rand.nextInt(boardSize);
      int col = rand.nextInt(boardSize);

      if (canPlaceWord(board, word, row, col, dx, dy, boardSize)) {
        for (int i = 0; i < word.length; i++) {
          board[row + i * dx][col + i * dy] = word[i];
        }
        break;
      }
    }
  }

  for (int r = 0; r < boardSize; r++) {
    for (int c = 0; c < boardSize; c++) {
      if (board[r][c].isEmpty) {
        board[r][c] = String.fromCharCode(65 + rand.nextInt(26));
      }
    }
  }

  return board;
}

bool isValidCell(int row, int col, int boardSize) => row >= 0 && row < boardSize && col >= 0 && col < boardSize;

bool isNeighbor(Offset a, Offset b) {
  int dx = (a.dx - b.dx).abs().toInt();
  int dy = (a.dy - b.dy).abs().toInt();
  return dx <= 1 && dy <= 1 && !(dx == 0 && dy == 0);
}
