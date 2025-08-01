import 'package:flutter/material.dart';

class CustomPrimaireAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController tabController;
  final VoidCallback? onBack;

  const CustomPrimaireAppBar({
    Key? key,
    required this.tabController,
    this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final deepOrange = Colors.deepOrange;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [deepOrange.shade300, deepOrange.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: deepOrange.withValues(alpha: 0.6),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top row with back button and title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Back button
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: onBack ?? () => Navigator.of(context).pop(),
                  ),

                  // Title centered
                  Expanded(
                    child: Text(
                      '1ère Année Primaire',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),

                  // Invisible SizedBox for balance, same width as IconButton
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // TabBar with rounded pill indicator
            TabBar(
              controller: tabController,
              indicator: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(24),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
              indicatorPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              tabs: const [
                Tab(icon: Icon(Icons.menu_book), text: 'Cours'),
                Tab(icon: Icon(Icons.assignment), text: 'Examens'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Size of AppBar
  @override
  Size get preferredSize => const Size.fromHeight(110);
}
