import 'package:flutter/material.dart';

class RamadanSplashScreen extends StatelessWidget {
  const RamadanSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2951B9),
              Color(0xFF2A6D8A),
              Color(0xFF5F8D73),
              Color(0xFF0D6D78),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.nightlight_round,
                        color: Color(0xFF65DDFF),
                        size: 46,
                      ),
                      SizedBox(height: 8),
                      Icon(
                        Icons.menu_book_rounded,
                        color: Color(0xFF65DDFF),
                        size: 90,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 260,
                child: CustomPaint(painter: _MosqueSilhouettePainter()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MosqueSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final skyline = Paint()..color = const Color(0xFF0C5F6A);
    final glow = Paint()
      ..shader =
          const RadialGradient(
            colors: [Color(0xFFCFD978), Color(0x00CFD978)],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.6, size.height * 0.7),
              radius: 80,
            ),
          );

    canvas.drawCircle(Offset(size.width * 0.62, size.height * 0.74), 64, glow);

    final domePath = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.2, size.height)
      ..lineTo(size.width * 0.2, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.28,
        size.width * 0.5,
        size.height * 0.72,
      )
      ..lineTo(size.width * 0.5, size.height)
      ..lineTo(size.width * 0.74, size.height)
      ..lineTo(size.width * 0.74, size.height * 0.68)
      ..lineTo(size.width * 0.79, size.height * 0.68)
      ..lineTo(size.width * 0.79, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, size.height * 0.86)
      ..quadraticBezierTo(
        size.width * 0.9,
        size.height * 0.76,
        size.width * 0.8,
        size.height * 0.86,
      )
      ..lineTo(size.width * 0.55, size.height * 0.86)
      ..quadraticBezierTo(
        size.width * 0.36,
        size.height * 0.78,
        size.width * 0.16,
        size.height * 0.86,
      )
      ..lineTo(0, size.height * 0.86)
      ..close();
    canvas.drawPath(domePath, skyline);

    final minaret = Paint()..color = const Color(0xFF0C5F6A);
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.3,
        size.height * 0.34,
        10,
        size.height * 0.52,
      ),
      minaret,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.82,
        size.height * 0.3,
        10,
        size.height * 0.56,
      ),
      minaret,
    );

    final tip1 = Path()
      ..moveTo(size.width * 0.29, size.height * 0.34)
      ..lineTo(size.width * 0.35, size.height * 0.34)
      ..lineTo(size.width * 0.32, size.height * 0.2)
      ..close();
    canvas.drawPath(tip1, minaret);

    final tip2 = Path()
      ..moveTo(size.width * 0.81, size.height * 0.3)
      ..lineTo(size.width * 0.87, size.height * 0.3)
      ..lineTo(size.width * 0.84, size.height * 0.16)
      ..close();
    canvas.drawPath(tip2, minaret);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
