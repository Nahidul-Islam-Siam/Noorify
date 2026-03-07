import 'package:flutter/material.dart';

class HomeActivePrayerGauge extends StatelessWidget {
  const HomeActivePrayerGauge({
    super.key,
    required this.prayerName,
    required this.subtitle,
    required this.remainingTime,
    required this.progress,
  });

  final String prayerName;
  final String subtitle;
  final String remainingTime;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(170, 100),
            painter: _ActivePrayerGaugePainter(progress: progress),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  prayerName,
                  style: const TextStyle(
                    color: Color(0xFF18363A),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF18363A),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  remainingTime,
                  style: const TextStyle(
                    color: Color(0xFF18363A),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivePrayerGaugePainter extends CustomPainter {
  _ActivePrayerGaugePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 8.0;
    final radius = (size.width / 2) - stroke;
    final center = Offset(size.width / 2, size.height * 0.95);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..color = const Color(0x33FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = const Color(0xFF14383E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 3.14159, 3.14159, false, bgPaint);
    canvas.drawArc(
      rect,
      3.14159,
      3.14159 * progress.clamp(0.0, 1.0),
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ActivePrayerGaugePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class HomePrayerTile extends StatelessWidget {
  const HomePrayerTile({
    super.key,
    required this.title,
    required this.time,
    this.active = false,
  });

  final String title;
  final String time;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      width: active ? 80 : 68,
      padding: EdgeInsets.symmetric(vertical: active ? 14 : 10),
      decoration: BoxDecoration(
        color: active ? const Color(0x44FFFFFF) : const Color(0x22FFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: active ? Border.all(color: const Color(0x66FFFFFF)) : null,
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: active ? 14 : 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Icon(
            active ? Icons.wb_sunny_rounded : Icons.cloud_rounded,
            size: active ? 18 : 16,
            color: Colors.white,
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(
              color: Colors.white,
              fontSize: active ? 13 : 12,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class HomeChecklistRow extends StatelessWidget {
  const HomeChecklistRow({
    super.key,
    required this.title,
    required this.status,
    required this.isDone,
    required this.onTapDone,
  });

  final String title;
  final String status;
  final bool isDone;
  final VoidCallback onTapDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E8EC)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Color(0xFF1F252D),
              ),
            ),
          ),
          Text(
            status,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF1D98A9),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onTapDone,
            borderRadius: BorderRadius.circular(16),
            child: Icon(
              isDone
                  ? Icons.check_circle_outline
                  : Icons.radio_button_unchecked,
              color: const Color(0xFF6F8DA1),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
