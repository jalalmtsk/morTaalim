import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:mortaalim/tools/audio_tool/audio_tool.dart';

class CourseGrid extends StatelessWidget {
  final List<Map<String, dynamic>> highCourses;

  const CourseGrid({super.key, required this.highCourses});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return GridView.builder(
      itemCount: highCourses.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 18,
        crossAxisSpacing: 18,
        childAspectRatio: 4 / 3,
      ),
      itemBuilder: (context, index) {
        final course = highCourses[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => course['widget'],
            ));
          },
          child: Container(
            decoration: BoxDecoration(
              color: course['color'].withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: course['color'].withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(2, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(course['icon'], size: 48, color: Colors.white),
                const SizedBox(height: 10),
                Text(
                  _getCourseTitle(tr, course['titleKey']),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getCourseTitle(AppLocalizations tr, String key) {
    switch (key) {
      case 'class1':
        return tr.class1;
      case 'class2':
        return tr.class2;
      case 'class3':
        return tr.class3;
      case 'class4':
        return tr.class4;
      case 'class5':
        return tr.class5;
      case 'class6':
      default:
        return tr.class6;
    }
  }
}
