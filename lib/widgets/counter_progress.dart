import 'dart:math';

import 'package:counter/utils/utils.dart';
import 'package:flutter/material.dart';

class CounterProgress extends StatelessWidget {
  // Inspired by these : https://www.youtube.com/watch?v=TiH0HYBFMMI
  // https://dev.to/danko56666/creating-a-custom-progress-indicator-346e
  final double size;
  final double circleWidth;
  final double progress;
  final bool isInfinite;
  final String? color;
  final Widget? content;
  final Function() onTap;

  const CounterProgress({
    super.key,
    required this.circleWidth,
    required this.color,
    this.content,
    required this.onTap,
    required this.progress,
    required this.size,
    this.isInfinite = false,
  });

  @override
  Widget build(BuildContext context) {
    var fillColor = Utils.hexToColor(color);
    double startAngle;
    double endAngle;
    if (isInfinite) {
      startAngle = -pi / 2 + progress * 2 * pi;
      endAngle = 3 / 2 * pi + progress * 2 * pi;
    } else {
      startAngle = -pi / 2;
      endAngle = progress * 2 * pi;
    }
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.grey.withAlpha(20),
              width: circleWidth,
            ),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: ProgressIndicatorPainter(
                width: circleWidth,
                startAngle: startAngle,
                sweepAngle: endAngle,
                color: fillColor,
                useGradient: isInfinite,
              ),
              child: Center(
                child: content,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ProgressIndicatorPainter extends CustomPainter {
  const ProgressIndicatorPainter({
    required this.width,
    required this.startAngle,
    required this.sweepAngle,
    required this.color,
    required this.useGradient,
  }) : super();

  final double width;
  final double startAngle;
  final double sweepAngle;
  final Color color;
  final bool useGradient;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.butt
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    if (useGradient) {
      final rect = Rect.fromLTWH(0.0, 0.0, size.width, size.height);
      final gradient = SweepGradient(
        startAngle: startAngle,
        endAngle: sweepAngle,
        tileMode: TileMode.repeated,
        colors: [color, Colors.white],
      );
      paint.shader = gradient.createShader(rect);
    }
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (width / 2);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      useGradient ? 0 : startAngle,
      useGradient ? 2 * pi : sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
