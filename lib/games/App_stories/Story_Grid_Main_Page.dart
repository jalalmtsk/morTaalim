import 'package:flutter/material.dart';
import 'Stories.dart';
import 'story_book_page.dart';

class StoriesGridPage extends StatefulWidget {
  final List<Story> stories;

  const StoriesGridPage({super.key, required this.stories});

  @override
  State<StoriesGridPage> createState() => _StoriesGridPageState();
}

class _StoriesGridPageState extends State<StoriesGridPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<Animation<double>> _animations = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Create staggered animations for each item
    final count = widget.stories.length;
    for (int i = 0; i < count; i++) {
      final start = i / count;
      final end = (i + 1) / count;
      _animations.add(
        Tween<double>(begin: 50, end: 0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        ),
      );
    }

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildAnimatedItem(int index) {
    final story = widget.stories[index];
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offsetY = _animations[index].value;
        final opacity =
            (_controller.value - (index / widget.stories.length)) * widget.stories.length;
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, offsetY),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StoryBookPage(story: story),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.deepOrange.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                story.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.deepOrange,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('Index');
            },
            icon: const Icon(Icons.arrow_back)),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed("FavoriteWords");
              },
              icon: const Icon(
                Icons.bookmark,
                color: Colors.white,
              ))
        ],
        title: const Text('Stories Library'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Column(
        children: [
          Container(
            height: 300,
            width: 400,
            margin: const EdgeInsets.all(10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                "assets/images/ents.png",
                fit: BoxFit.cover,
                scale: 0.9,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.stories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 3 / 2,
              ),
              itemBuilder: (context, index) => _buildAnimatedItem(index),
            ),
          ),
        ],
      ),
    );
  }
}
