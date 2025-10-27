import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:intl/intl.dart' as intl;

class MarqueeText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final double height;
  final double velocity;

  const MarqueeText({
    Key? key,
    required this.text,
    this.style,
    this.height = 25,
    this.velocity = 35.0,
  }) : super(key: key);

  // Detects if the text language is right-to-left
  bool _isRtl(String text) {
    if (text.isEmpty) return false;
    final firstChar = text.characters.first;
    final code = firstChar.codeUnitAt(0);
    return (code >= 0x0600 && code <= 0x06FF) || // Arabic
        (code >= 0x0750 && code <= 0x077F) || // Arabic Supplement
        (code >= 0x08A0 && code <= 0x08FF) || // Arabic Extended-A
        (code >= 0x2D30 && code <= 0x2D7F);   // Tifinagh
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = _isRtl(text);
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textPainter = TextPainter(
              text: TextSpan(text: text, style: style),
              maxLines: 1,
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            )..layout(maxWidth: constraints.maxWidth);

            if (textPainter.width > constraints.maxWidth) {
              return Marquee(
                text: text,
                style: style,
                velocity: velocity,
                blankSpace: 16.0,
                pauseAfterRound: const Duration(seconds: 1),
                startPadding: 4.0,
                accelerationDuration: const Duration(milliseconds: 600),
                decelerationDuration: const Duration(milliseconds: 600),
                scrollAxis: Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.center,
              );
            } else {
              return Text(
                text,
                style: style,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              );
            }
          },
        ),
      ),
    );
  }
}
