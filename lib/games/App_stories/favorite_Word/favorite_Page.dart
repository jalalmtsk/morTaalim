import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/games/App_stories/favorite_Word/favorite_word_dictionnary.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';

import '../../../main.dart';

class FavoriteWordsPage extends StatefulWidget {
  const FavoriteWordsPage({super.key});

  @override
  State<FavoriteWordsPage> createState() => _FavoriteWordsPageState();
}

class _FavoriteWordsPageState extends State<FavoriteWordsPage> with SingleTickerProviderStateMixin {
  List<FavoriteWord> favoriteWords = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    setState(() => isLoading = true);
    final words = await FavoriteWordsManager.getWords();
    setState(() {
      favoriteWords = words;
      isLoading = false;
    });
  }

  Future<void> _removeWord(FavoriteWord fav) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Favorite?'),
        content: Text('Are you sure you want to remove "${fav.word}" from favorites?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    await FavoriteWordsManager.removeWord(fav.word);
    await _loadWords();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('💔 "${fav.word}" removed from favorites'),
        backgroundColor: Colors.deepOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/catInBox.json',
              width: 280,
              height: 280,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            Text(
              tr(context).noFavoriteWordsYetAddNewWordsHere,
              style: const TextStyle(
                fontSize: 22,
                color: Colors.deepOrange,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline, size: 26),
              label: const Text(
                "Add Your First Word",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 6,
              ),
              onPressed: () => Navigator.of(context).pushReplacementNamed("AppStories"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteList() {
    return RefreshIndicator(
      onRefresh: _loadWords,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: favoriteWords.length,
        itemBuilder: (_, index) {
          final fav = favoriteWords[index];
          return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutQuad,
            child: Dismissible(
              key: ValueKey(fav.word),
              direction: DismissDirection.endToStart,
              background: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.only(right: 24),
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(
                  color: Colors.redAccent.shade700,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.delete, color: Colors.white, size: 32),
              ),
              onDismissed: (_) => _removeWord(fav),
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 4,
                shadowColor: Colors.deepOrange.withOpacity(0.25),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  title: Text(
                    fav.word,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.deepOrange,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      fav.definition,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 28),
                    onPressed: () => _removeWord(fav),
                    tooltip: 'Remove from favorites',
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F3),
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        elevation: 0,
        title: const Text(
          "⭐ Favorite Words",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 28),
          onPressed: () => Navigator.of(context).pushReplacementNamed("AppStories"),
          tooltip: 'Back',
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Userstatutbar(),
          const SizedBox(height: 10),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.deepOrange))
                : (favoriteWords.isEmpty ? _buildEmptyState() : _buildFavoriteList()),
          ),
        ],
      ),
    );
  }
}
