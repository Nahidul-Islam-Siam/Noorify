import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';

import '../app/brand_colors.dart';
import '../widgets/bottom_nav.dart';

class QiblaCompassScreen extends StatefulWidget {
  const QiblaCompassScreen({super.key});

  @override
  State<QiblaCompassScreen> createState() => _QiblaCompassScreenState();
}

class _QiblaCompassScreenState extends State<QiblaCompassScreen> {
  StreamSubscription<CompassEvent>? _compassSub;
  double? _heading;
  String? _sensorError;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _startCompassListener();
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  void _startCompassListener() {
    _compassSub?.cancel();
    final stream = FlutterCompass.events;
    if (stream == null) {
      _safeSetState(() {
        _sensorError = 'Compass is not available on this device.';
        _isListening = false;
      });
      return;
    }

    _safeSetState(() {
      _sensorError = null;
      _isListening = true;
    });

    _compassSub = stream.listen(
      (event) {
        final heading = event.heading;
        if (heading == null || heading.isNaN) return;
        _safeSetState(() {
          _heading = _normalizeAngle(heading);
          _sensorError = null;
          _isListening = true;
        });
      },
      onError: (_) {
        _safeSetState(() {
          _sensorError = 'Could not read compass sensor.';
          _isListening = false;
        });
      },
      onDone: () {
        _safeSetState(() {
          _isListening = false;
        });
      },
    );
  }

  double _normalizeAngle(double degrees) {
    final normalized = degrees % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }

  String _headingText(double? value) {
    if (value == null) return '--';
    return '${value.round()}°';
  }

  String _directionText(double? value) {
    if (value == null) return '--';
    final angle = _normalizeAngle(value);
    const labels = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((angle + 22.5) ~/ 45) % 8;
    return labels[index];
  }

  String _statusHint() {
    if (_sensorError != null) return _sensorError!;
    if (_heading == null) {
      return 'Move your phone in a figure-8 to calibrate the compass.';
    }
    return 'Hold phone flat and away from metal objects.';
  }

  @override
  Widget build(BuildContext context) {
    final dialTurns = _heading == null ? 0.0 : -_heading! / 360;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 20,
                            color: Color(0xFF7E98AE),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Compass',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: BrandColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Rotate your phone naturally to find direction',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF7E98AE),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: 332,
                      height: 332,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 306,
                            height: 306,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8ECEF),
                              shape: BoxShape.circle,
                            ),
                          ),
                          AnimatedRotation(
                            turns: dialTurns,
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            child: SizedBox(
                              width: 288,
                              height: 288,
                              child: CustomPaint(
                                painter: _CompassDialMarksPainter(),
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: dialTurns,
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            child: const SizedBox(
                              width: 272,
                              height: 272,
                              child: Stack(
                                children: [
                                  Align(
                                    alignment: Alignment.topCenter,
                                    child: _CardinalLabel('N'),
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: _CardinalLabel('E'),
                                  ),
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: _CardinalLabel('S'),
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: _CardinalLabel('W'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 260,
                            height: 260,
                            child: CustomPaint(painter: _NeedlePainter()),
                          ),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Color(0xFF6E90A6),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _headingText(_heading),
                      style: const TextStyle(
                        fontSize: 56,
                        height: 1,
                        color: Color(0xFF289AAD),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _directionText(_heading),
                      style: const TextStyle(
                        fontSize: 24,
                        color: Color(0xFF4F6678),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _startCompassListener,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF289AAD),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: const StadiumBorder(),
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text(
                        'Refresh',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    if (!_isListening && _sensorError == null) ...[
                      const SizedBox(height: 14),
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: BrandColors.primary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      _statusHint(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: _sensorError == null
                            ? const Color(0xFF7E98AE)
                            : const Color(0xFFB65757),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottomNav(context, 3),
          ],
        ),
      ),
    );
  }
}

class _CardinalLabel extends StatelessWidget {
  const _CardinalLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 26,
        color: Color(0xFF6F8FA5),
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _CompassDialMarksPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final majorTickPaint = Paint()
      ..color = const Color(0xFF8AA4B8)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final minorTickPaint = Paint()
      ..color = const Color(0xFF9CB3C3)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 36; i++) {
      final angle = (i * 10) * math.pi / 180;
      final major = i % 3 == 0;
      final inner = radius - (major ? 14 : 9);
      final p1 = Offset(
        center.dx + inner * math.sin(angle),
        center.dy - inner * math.cos(angle),
      );
      final p2 = Offset(
        center.dx + (radius - 2) * math.sin(angle),
        center.dy - (radius - 2) * math.cos(angle),
      );
      canvas.drawLine(p1, p2, major ? majorTickPaint : minorTickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NeedlePainter extends CustomPainter {
  const _NeedlePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const northY = 20.0;

    final stemPaint = Paint()
      ..color = const Color(0xFF289AAD)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, Offset(center.dx, northY + 20), stemPaint);

    final triangle = Path()
      ..moveTo(center.dx, northY)
      ..lineTo(center.dx - 9, northY + 16)
      ..lineTo(center.dx + 9, northY + 16)
      ..close();
    canvas.drawPath(triangle, Paint()..color = const Color(0xFF289AAD));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
