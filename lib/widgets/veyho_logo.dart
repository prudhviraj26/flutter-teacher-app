import 'package:flutter/material.dart';

class VeyhoLogo extends StatelessWidget {
  final double scale;

  const VeyhoLogo({
    super.key,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = 48.0 * scale;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
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
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0A1D6E),
                    height: 1,
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Text(
                      'h',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1D70B8),
                        height: 1,
                      ),
                    ),
                    Positioned(
                      top: -fontSize * 0.5,
                      left: fontSize * 0.05,
                      child: SizedBox(
                        width: fontSize * 0.9,
                        height: fontSize * 0.9,
                        child: CustomPaint(
                          painter: SwooshPainter(),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'o',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1D70B8),
                    height: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
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
