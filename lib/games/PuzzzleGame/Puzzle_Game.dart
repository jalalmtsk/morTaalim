import 'package:flutter/material.dart';

// Home Page to select image and grid size
class PuzzleGame extends StatefulWidget {
  const PuzzleGame({super.key});

  @override
  State<PuzzleGame> createState() => _HomePageState();
}

class _HomePageState extends State<PuzzleGame> {
  final List<String> mainImages = ['Puzz1', 'Puzz2', 'Puzz3', 'Puzz4'];

  String? selectedImage;
  int? selectedGridSize;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Puzzle Settings'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text(
              'Choose an Image',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: GridView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: mainImages.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final imageName = mainImages[index];
                  final isSelected = imageName == selectedImage;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedImage = imageName;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? Colors.deepOrange : Colors.grey,
                          width: isSelected ? 3 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.asset(
                          'assets/images/Puzz/PuzzMainImages/$imageName.webp',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Choose Grid Size',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: [2, 3, 4, 5, 6].map((size) {
                final isSelected = size == selectedGridSize;
                return ChoiceChip(
                  label: Text('${size} x $size'),
                  selected: isSelected,
                  selectedColor: Colors.deepOrange,
                  onSelected: (_) {
                    setState(() {
                      selectedGridSize = size;
                    });
                  },
                );
              }).toList(),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: (selectedImage != null && selectedGridSize != null)
                  ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PuzzlePage(
                      mainImage: selectedImage!,
                      gridSize: selectedGridSize!,
                    ),
                  ),
                );
              }
                  : null,
              child: const Text('Start Puzzle', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

// Puzzle Page to play the puzzle
class PuzzlePage extends StatefulWidget {
  final String mainImage;
  final int gridSize;

  const PuzzlePage({super.key, required this.mainImage, required this.gridSize});

  @override
  State<PuzzlePage> createState() => _PuzzlePageState();
}

class _PuzzlePageState extends State<PuzzlePage> {
  late PuzzleLogic puzzle;

  @override
  void initState() {
    super.initState();
    puzzle = PuzzleLogic(size: widget.gridSize);
    puzzle.shuffle();
  }

  void _onTileTap(int index) {
    setState(() {
      puzzle.moveTile(index);
    });

    if (puzzle.isSolved()) {
      _showWinDialog();
    }
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("🎉 You Win!"),
        content: const Text("You solved the puzzle!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                puzzle.shuffle();
              });
            },
            child: const Text("Play Again"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Back to Home"),
          ),
        ],
      ),
    );
  }

  List<String> _getTileImages() {
    final totalTiles = widget.gridSize * widget.gridSize;
    final folderName =
        'Puzz/${widget.mainImage}/${widget.mainImage}_${widget.gridSize}x${widget.gridSize}';
    return List.generate(
      totalTiles - 1, // Only tiles, no blank tile
          (index) =>
      'assets/images/$folderName/${widget.mainImage}_tile${index + 1}.jpg',
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double tileSize = (screenWidth / widget.gridSize) - 8;
    final tileImages = _getTileImages();

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.mainImage} - ${widget.gridSize}x${widget.gridSize} Puzzle"),
        backgroundColor: Colors.deepOrange,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                puzzle.shuffle();
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 4),
            Center(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.deepOrange, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(10),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: puzzle.tiles.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: widget.gridSize,
                    crossAxisSpacing: 3,
                    mainAxisSpacing: 3,
                  ),
                  padding: EdgeInsets.zero,
                  itemBuilder: (_, index) {
                    final tileValue = puzzle.tiles[index];

                    if (tileValue == 0) return Container(color: Colors.transparent);

                    final imageIndex = tileValue - 1;
                    final tileImagePath = tileImages[imageIndex];

                    return GestureDetector(
                      onTap: () => _onTileTap(index),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: tileSize,
                          height: tileSize,
                          child: Stack(
                            children: [
                              Image.asset(
                                tileImagePath,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white, width: 1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Reference Image',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/Puzz/PuzzMainImages/${widget.mainImage}.webp',
                  width: screenWidth * 0.8,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Puzzle Logic class with solvable shuffle
class PuzzleLogic {
  final int size;
  late List<int> tiles;

  PuzzleLogic({this.size = 3}) {
    _generatePuzzle();
  }

  void _generatePuzzle() {
    // Generate tiles 1..N then add 0 for blank tile
    tiles = List.generate(size * size, (i) => i + 1);
    tiles[tiles.length - 1] = 0;
  }

  int _getInversions(List<int> list) {
    int inversions = 0;
    for (int i = 0; i < list.length; i++) {
      for (int j = i + 1; j < list.length; j++) {
        if (list[i] != 0 && list[j] != 0 && list[i] > list[j]) {
          inversions++;
        }
      }
    }
    return inversions;
  }

  bool _isSolvable(List<int> list) {
    int inversions = _getInversions(list);
    int emptyRowFromBottom = size - (list.indexOf(0) ~/ size);

    if (size.isOdd) {
      return inversions.isEven;
    } else {
      if (emptyRowFromBottom.isOdd) {
        return inversions.isEven;
      } else {
        return inversions.isOdd;
      }
    }
  }

  void shuffle() {
    do {
      tiles.shuffle();
    } while (!_isSolvable(tiles) || isSolved());
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
}
