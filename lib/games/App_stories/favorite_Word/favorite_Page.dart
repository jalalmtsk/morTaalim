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

class _FavoriteWordsPageState extends State<FavoriteWordsPage>
    with TickerProviderStateMixin {
  List<FavoriteWord> _all = [];
  List<FavoriteWord> _filtered = [];
  bool isLoading = false;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  // Stagger controller for list items
  late AnimationController _staggerCtrl;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _loadWords();
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadWords() async {
    setState(() => isLoading = true);
    final words = await FavoriteWordsManager.getWords();
    setState(() {
      _all      = words;
      _filtered = words;
      isLoading = false;
    });
    _staggerCtrl.forward(from: 0);
  }

  void _applySearch(String query) {
    setState(() {
      _searchQuery = query;
      _filtered = _all
          .where((w) =>
      w.word.toLowerCase().contains(query.toLowerCase()) ||
          w.definition.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _removeWord(FavoriteWord fav) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFFFFF8F0),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('💔', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text(
                'Remove "${fav.word}"?',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A2000)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'It will be removed from your favorites.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black54,
                        side: const BorderSide(color: Colors.black12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Keep it'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Remove',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;
    await FavoriteWordsManager.removeWord(fav.word);
    await _loadWords();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('💔 "${fav.word}" removed'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/animations/catInBox.json',
                width: 240, height: 240),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No words match "$_searchQuery"'
                  : tr(context).noFavoriteWordsYetAddNewWordsHere,
              style: const TextStyle(
                fontSize: 20,
                color: Color(0xFFFF7043),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7043),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  elevation: 6,
                  shadowColor: const Color(0xFFFF7043).withOpacity(0.4),
                ),
                icon: const Icon(Icons.auto_stories_rounded,
                    color: Colors.white),
                label: const Text('Go to Stories',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, 'AppStories'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Word list ──────────────────────────────────────────────────────────────
  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _filtered.length,
      itemBuilder: (_, index) {
        final fav   = _filtered[index];
        final delay = (index / _filtered.length).clamp(0.0, 1.0);
        final anim  = CurvedAnimation(
          parent: _staggerCtrl,
          curve: Interval(delay, (delay + 0.4).clamp(0.0, 1.0),
              curve: Curves.easeOutBack),
        );

        return AnimatedBuilder(
          animation: anim,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, 30 * (1 - anim.value)),
            child: Opacity(
                opacity: anim.value.clamp(0.0, 1.0), child: child),
          ),
          child: Dismissible(
            key: ValueKey(fav.word),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.only(right: 24),
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                color: Colors.redAccent.shade400,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_rounded, color: Colors.white, size: 28),
                  SizedBox(height: 4),
                  Text('Remove',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            onDismissed: (_) => _removeWord(fav),
            child: _WordCard(fav: fav, onDelete: () => _removeWord(fav)),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasWords = _all.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: CustomScrollView(
        slivers: [
          // ── Cosy SliverAppBar ──────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color(0xFFFF7043),
            expandedHeight: 130,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, 'AppStories'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text(
                '⭐ Favorite Words',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF7043), Color(0xFFFF9800)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Text('📖', style: TextStyle(fontSize: 48)),
                ),
              ),
            ),
          ),

          // ── Status bar ────────────────────────────────────────────────
          SliverToBoxAdapter(child: Userstatutbar()),

          // ── Search bar ────────────────────────────────────────────────
          if (hasWords)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _applySearch,
                  decoration: InputDecoration(
                    hintText: '🔍 Search your words...',
                    hintStyle: const TextStyle(
                        color: Colors.black38, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Color(0xFFFF7043)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () {
                          _searchCtrl.clear();
                          _applySearch('');
                        })
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                          color: Color(0xFFFFDCC5), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                          color: Color(0xFFFF7043), width: 2),
                    ),
                  ),
                ),
              ),
            ),

          // ── Word count ────────────────────────────────────────────────
          if (hasWords)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                child: Text(
                  '${_filtered.length} word${_filtered.length == 1 ? "" : "s"}',
                  style: const TextStyle(
                      color: Colors.black38,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),

          // ── Content ───────────────────────────────────────────────────
          SliverFillRemaining(
            child: isLoading
                ? const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFFFF7043)))
                : (_all.isEmpty || _filtered.isEmpty)
                ? _buildEmpty()
                : _buildList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WORD CARD
// ─────────────────────────────────────────────────────────────────────────────
class _WordCard extends StatelessWidget {
  final FavoriteWord fav;
  final VoidCallback onDelete;
  const _WordCard({required this.fav, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7043).withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFFFDCC5), width: 1.5),
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF7043), Color(0xFFFF9800)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              fav.word.isNotEmpty ? fav.word[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20),
            ),
          ),
        ),
        title: Text(
          fav.word,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFFFF7043),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            fav.definition,
            style: const TextStyle(fontSize: 14, color: Colors.black54,
                height: 1.4),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: GestureDetector(
          onTap: onDelete,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.delete_rounded,
                color: Colors.redAccent, size: 22),
          ),
        ),
      ),
    );
  }
}