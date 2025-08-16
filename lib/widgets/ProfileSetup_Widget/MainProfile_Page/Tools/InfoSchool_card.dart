import 'package:flutter/material.dart';

class SwipableSchoolCard extends StatefulWidget {
  final String schoolName;
  final String schoolType;
  final String schoolGrade;
  final String lyceeTrack;

  const SwipableSchoolCard({
    Key? key,
    required this.schoolName,
    required this.schoolType,
    required this.schoolGrade,
    this.lyceeTrack = '',
  }) : super(key: key);

  @override
  State<SwipableSchoolCard> createState() => _SwipableSchoolCardState();
}

class _SwipableSchoolCardState extends State<SwipableSchoolCard> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  List<Map<String, String>> get _pages {
    final pages = [
      {"label": "School Name", "value": widget.schoolName},
      {"label": "School Type", "value": widget.schoolType},
      {"label": "Class/Grade", "value": widget.schoolGrade},
    ];
    if (widget.lyceeTrack.isNotEmpty) {
      pages.add({"label": "Lycée Track", "value": widget.lyceeTrack});
    }
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 120, // reduced height
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.shade300,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                offset: const Offset(0, 3),
                blurRadius: 6,
              ),
            ],
          ),
          child: PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              final page = _pages[index];
              IconData icon;
              switch (index) {
                case 0:
                  icon = Icons.school;
                  break;
                case 1:
                  icon = Icons.apartment;
                  break;
                case 2:
                  icon = Icons.class_;
                  break;
                default:
                  icon = Icons.track_changes;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 36, // smaller icon
                      color: Colors.white,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      page["label"]!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      page["value"]!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _pages.length,
                (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentIndex == index ? 14 : 10,
              height: 10,
              decoration: BoxDecoration(
                color: _currentIndex == index
                    ? Colors.orangeAccent
                    : Colors.orange.withOpacity(0.5),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
