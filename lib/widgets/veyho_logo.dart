import 'package:flutter/material.dart';

class VeyhoLogo extends StatelessWidget {
  final double scale;
  final double? fontSize;

  const VeyhoLogo({
    super.key,
    this.scale = 1.0,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveFontSize = fontSize ?? (48.0 * scale);

    return SizedBox(
      height: effectiveFontSize * 1.5,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'vey',
                style: TextStyle(
                  color: const Color(0xFF0A1D6E),
                  fontSize: effectiveFontSize,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Text(
                    'h',
                    style: TextStyle(
                      color: const Color(0xFF1D70B8),
                      fontSize: effectiveFontSize,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                  // Curving swoosh arrow positioned above 'h'
                  Positioned(
                    top: -effectiveFontSize * 0.45,
                    left: effectiveFontSize * 0.05,
                    child: CustomPaint(
                      size: Size(effectiveFontSize * 0.7, effectiveFontSize * 0.7),
                      painter: SwooshPainter(),
                    ),
                  ),
                ],
              ),
              Text(
                'o',
                style: TextStyle(
                  color: const Color(0xFF1D70B8),
                  fontSize: effectiveFontSize,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SwooshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF3BE4C4), Color(0xFF1DBEE2)],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(rect);

    // Curl shadow fold paint
    final shadowPaint = Paint()
      ..color = const Color(0xFF0A8276)
      ..style = PaintingStyle.fill;

    // Draw fold shadow
    final shadowPath = Path()
      ..moveTo(size.width * 0.1, size.height * 0.8)
      ..lineTo(size.width * 0.2, size.height * 0.8)
      ..lineTo(size.width * 0.1, size.height * 0.7)
      ..close();
    canvas.drawPath(shadowPath, shadowPaint);

    // Draw swoosh arrow
    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.8)
      ..cubicTo(
        size.width * 0.25, size.height * 0.7,
        size.width * 0.48, size.height * 0.52,
        size.width * 0.7, size.height * 0.3,
      )
      ..lineTo(size.width * 0.62, size.height * 0.22)
      ..lineTo(size.width * 0.92, size.height * 0.12)
      ..lineTo(size.width * 0.82, size.height * 0.42)
      ..lineTo(size.width * 0.74, size.height * 0.34)
      ..cubicTo(
        size.width * 0.52, size.height * 0.56,
        size.width * 0.28, size.height * 0.72,
        size.width * 0.2, size.height * 0.8,
      )
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
