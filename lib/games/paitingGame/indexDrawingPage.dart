import 'package:flutter/material.dart';
import 'package:mortaalim/games/paitingGame/paintOnSketch/paintonSketchPage.dart';
import 'package:mortaalim/games/paitingGame/paint_main.dart';
import 'package:mortaalim/widgets/ComingSoon.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import '../../main.dart';


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DrawingIndex();
  }
}

class DrawingIndex extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      body: SafeArea(
        child: Column(
          children: [
            Userstatutbar(),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.orange.shade700),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 50,),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    _buildOptionCard(
                      context,
                      title: "🎨 ${tr(context).freeDrawing}",
                      description: "${tr(context).drawWhateverYouLike} !",
                      icon: Icons.brush,
                      color: Colors.orangeAccent,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DrawingApp()),
                      ),
                    ),
                    SizedBox(height: 20),

                    _buildOptionCard(
                      context,
                      title: "🖼️ ${tr(context).paintOnSketches}",
                      description: " ${tr(context).colorBeautifulTemplates}",
                      icon: Icons.image,
                      color: Colors.deepOrange.shade400,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SketchSelectorPage()),
                      ),
                    ),
                    SizedBox(height: 20),
                    _buildOptionCard(
                      context,
                      title: "📚 ${tr(context).learningProgram}",
                      description: "${tr(context).stepByStepPaintingLessons}",
                      icon: Icons.school,
                      color: Colors.orange.shade300,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ComingSoonPage()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
      BuildContext context, {
        required String title,
        required String description,
        required IconData icon,
        required Color color,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Icon(icon, size: 32, color: Colors.white),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
