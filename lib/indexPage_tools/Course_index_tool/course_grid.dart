import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../User_Input_Info_DataForm/LearningPreferencesForm/LearningPreferencesEnteringForm.dart';
import '../../l10n/app_localizations.dart';

class CourseGrid extends StatelessWidget {
  final List<Map<String, dynamic>> highCourses;

  const CourseGrid({super.key, required this.highCourses});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return AnimationLimiter(
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: highCourses.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 4 / 3,
        ),
        itemBuilder: (context, index) {
          final course = highCourses[index];

          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 800),
            columnCount: 2,
            child: ScaleAnimation(
              scale: 1,
              curve: Curves.easeOutBack,
              child: FadeInAnimation(
                child: _TiltCard(
                  course: course,
                  title: _getCourseTitle(tr, course['titleKey']),
                ),
              ),
            ),
          );
        },
      ),
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

class _TiltCard extends StatefulWidget {
  final Map<String, dynamic> course;
  final String title;

  const _TiltCard({required this.course, required this.title});

  @override
  State<_TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<_TiltCard> {
  double _tiltX = 0;
  double _tiltY = 0;
  bool _isPressed = false;

  void _onPointerMove(PointerEvent event, Size size) {
    final dx = (event.localPosition.dx - size.width / 2) / (size.width / 2);
    final dy = (event.localPosition.dy - size.height / 2) / (size.height / 2);

    setState(() {
      _tiltX = dy * 0.08;
      _tiltY = -dx * 0.08;
    });
  }

  void _resetTilt() {
    setState(() {
      _tiltX = 0;
      _tiltY = 0;
      _isPressed = false;
    });
  }

  Future<void> _handleTap() async {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = !(prefs.getBool('hasSetPreferences') ?? false);

    if (isFirstTime) {
      // Show learning preferences first
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LearningPreferencesPages()),
      );

      if (result != null) {
        await prefs.setBool('hasSetPreferences', true);
        await prefs.setString('userPreferences', result.toString());
      }
    }

    // Play audio and navigate to course
    audioManager.playEventSound('PopButton');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => widget.course['widget']),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: (event) {
        final size = context.size ?? const Size(150, 150);
        _onPointerMove(event, size);
      },
      onPointerUp: (_) => _resetTilt(),
      onPointerCancel: (_) => _resetTilt(),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => _resetTilt(),
        onTapCancel: _resetTilt,
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.identity()
            ..rotateX(_tiltX)
            ..rotateY(_tiltY)
            ..scale(_isPressed ? 0.97 : 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: widget.course['color'].withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: widget.course['color'].withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(2, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.course['icon'], size: 58, color: Colors.white),
                const SizedBox(height: 4),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
