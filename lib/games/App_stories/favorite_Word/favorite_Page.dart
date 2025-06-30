import 'package:flutter/material.dart';
import 'package:mortaalim/games/App_stories/favorite_Word/favorite_word_dictionnary.dart';

class FavoriteWordsPage extends StatefulWidget {
  const FavoriteWordsPage({super.key});

  @override
  State<FavoriteWordsPage> createState() => _FavoriteWordsPageState();
}

class _FavoriteWordsPageState extends State<FavoriteWordsPage> {
  List<FavoriteWord> favoriteWords = [];

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    final words = await FavoriteWordsManager.getWords();
    setState(() {
      favoriteWords = words;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        title: const Text("Favorite Words"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pushReplacementNamed("AppStories"),
          tooltip: 'Back',
        ),
      ),
      body: favoriteWords.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.star_border, size: 80, color: Colors.deepOrange),
              SizedBox(height: 16),
              Text(
                'No favorite words yet.',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.deepOrange,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: favoriteWords.length,
        itemBuilder: (_, index) {
          final fav = favoriteWords[index];
          return Dismissible(
            onDismissed: (val) async{
             await  FavoriteWordsManager.removeWord(fav.word);
              _loadWords();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${fav.word}" removed from favorites'),
                  backgroundColor: Colors.deepOrange,
                ),
              );
            },
            key: UniqueKey(),
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                title: Text(
                  fav.word,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.deepOrange,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    fav.definition,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () async {
                    await FavoriteWordsManager.removeWord(fav.word);
                    _loadWords();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('"${fav.word}" removed from favorites'),
                        backgroundColor: Colors.deepOrange,
                      ),
                    );
                  },
                  tooltip: 'Remove from favorites',
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
