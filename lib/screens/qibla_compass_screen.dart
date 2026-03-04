import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../app/app_globals.dart';
import '../app/brand_colors.dart';
import '../widgets/bottom_nav.dart';

class QiblaCompassScreen extends StatefulWidget {
  const QiblaCompassScreen({super.key});

  @override
  State<QiblaCompassScreen> createState() => _QiblaCompassScreenState();
}

class _QiblaCompassScreenState extends State<QiblaCompassScreen> {
  static const _kaabaLat = 21.422487;
  static const _kaabaLng = 39.826206;
  static const _baitulMukarramLat = 23.7286;
  static const _baitulMukarramLng = 90.4106;

  StreamSubscription<CompassEvent>? _compassSub;
  double? _heading;
  double? _qiblaBearing;
  double? _distanceKm;
  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = true;
  bool _usingFallback = false;
  String? _sensorError;
  String _locationLabel = 'Locating...';

  @override
  void initState() {
    super.initState();
    _startCompassListener();
    _loadLocationAndQibla();
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
    final stream = FlutterCompass.events;
    if (stream == null) {
      _safeSetState(() {
        _sensorError = 'Compass is not available on this device';
      });
      return;
    }

    _compassSub = stream.listen(
      (event) {
        final heading = event.heading;
        if (heading == null || heading.isNaN) return;
        _safeSetState(() => _heading = _normalizeAngle(heading));
      },
      onError: (_) {
        _safeSetState(() {
          _sensorError = 'Could not read compass sensor';
        });
      },
    );
  }

  Future<void> _loadLocationAndQibla() async {
    _safeSetState(() {
      _isLoadingLocation = true;
      _usingFallback = false;
    });

    double lat;
    double lng;
    String label;
    bool fallback = false;

    if (!useDeviceLocationNotifier.value) {
      lat = _baitulMukarramLat;
      lng = _baitulMukarramLng;
      label = 'Baitul Mukarram, Dhaka';
      fallback = true;
    } else {
      try {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          lat = _baitulMukarramLat;
          lng = _baitulMukarramLng;
          label = 'Baitul Mukarram, Dhaka';
          fallback = true;
        } else {
          var permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }

          if (permission == LocationPermission.denied ||
              permission == LocationPermission.deniedForever) {
            lat = _baitulMukarramLat;
            lng = _baitulMukarramLng;
            label = 'Baitul Mukarram, Dhaka';
            fallback = true;
          } else {
            final position = await Geolocator.getCurrentPosition();
            lat = position.latitude;
            lng = position.longitude;
            label = await _resolveLocationLabel(lat, lng);
          }
        }
      } catch (_) {
        lat = _baitulMukarramLat;
        lng = _baitulMukarramLng;
        label = 'Baitul Mukarram, Dhaka';
        fallback = true;
      }
    }

    final qiblaBearing = _normalizeAngle(
      Geolocator.bearingBetween(lat, lng, _kaabaLat, _kaabaLng),
    );
    final distanceKm =
        Geolocator.distanceBetween(lat, lng, _kaabaLat, _kaabaLng) / 1000;

    _safeSetState(() {
      _latitude = lat;
      _longitude = lng;
      _qiblaBearing = qiblaBearing;
      _distanceKm = distanceKm;
      _locationLabel = label;
      _usingFallback = fallback;
      _isLoadingLocation = false;
    });
  }

  Future<String> _resolveLocationLabel(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return 'Current location';
      final place = placemarks.first;
      final city =
          place.locality ??
          place.subAdministrativeArea ??
          place.administrativeArea ??
          'Current location';
      final area = place.administrativeArea ?? place.country ?? '';
      return area.isEmpty ? city : '$city, $area';
    } catch (_) {
      return 'Current location';
    }
  }

  double _normalizeAngle(double degrees) {
    final normalized = degrees % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }

  double _signedDelta(double target, double current) {
    return ((target - current + 540) % 360) - 180;
  }

  String _turnHint() {
    if (_heading == null || _qiblaBearing == null) {
      return 'Move your phone in a figure-8 to calibrate compass';
    }

    final delta = _signedDelta(_qiblaBearing!, _heading!);
    final absDelta = delta.abs();
    if (absDelta < 4) return 'Perfect. You are facing Qibla';
    final angle = absDelta.toStringAsFixed(0);
    return delta > 0 ? 'Turn right $angle°' : 'Turn left $angle°';
  }

  String _angleText(double? value) {
    if (value == null) return '--';
    return '${value.toStringAsFixed(0)}°';
  }

  @override
  Widget build(BuildContext context) {
    final deltaTurns = (_heading != null && _qiblaBearing != null)
        ? _signedDelta(_qiblaBearing!, _heading!) / 360
        : 0.0;

    return Scaffold(
      backgroundColor: BrandColors.screenBackground,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                children: [
                  Text(
                    'Qibla Compass',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: BrandColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dynamic direction from your location to Kaaba',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: BrandColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF16AFC2), Color(0xFF1A8B9B)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        _locationLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: _loadLocationAndQibla,
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.22,
                                ),
                              ),
                              icon: const Icon(
                                Icons.refresh_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        if (_usingFallback) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Using fallback location (Dhaka)',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        SizedBox(
                          width: 288,
                          height: 288,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 288,
                                height: 288,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0x22000000),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    width: 1.4,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 262,
                                height: 262,
                                child: CustomPaint(
                                  painter: _CompassTicksPainter(),
                                ),
                              ),
                              const Positioned(
                                top: 32,
                                child: Text(
                                  'N',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              AnimatedRotation(
                                turns: deltaTurns,
                                duration: const Duration(milliseconds: 240),
                                curve: Curves.easeOut,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.navigation_rounded,
                                      size: 96,
                                      color: Color(0xFFFFDD7D),
                                    ),
                                    Text(
                                      'QIBLA',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: const Color(0x66000000),
                                    width: 2,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _turnHint(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        if (_sensorError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _sensorError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingLocation)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: BrandColors.primary,
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          title: 'Heading',
                          value: _angleText(_heading),
                          icon: Icons.explore_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InfoCard(
                          title: 'Qibla Bearing',
                          value: _angleText(_qiblaBearing),
                          icon: Icons.my_location_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          title: 'Distance to Kaaba',
                          value: _distanceKm == null
                              ? '--'
                              : '${_distanceKm!.toStringAsFixed(0)} km',
                          icon: Icons.public_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InfoCard(
                          title: 'Coordinates',
                          value: (_latitude == null || _longitude == null)
                              ? '--'
                              : '${_latitude!.toStringAsFixed(3)}, ${_longitude!.toStringAsFixed(3)}',
                          icon: Icons.pin_drop_outlined,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            bottomNav(context, 3),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BrandColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: BrandColors.primary),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: BrandColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: BrandColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompassTicksPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final majorTickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round;
    final minorTickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.24)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 72; i++) {
      final angle = (i * 5) * math.pi / 180;
      final major = i % 3 == 0;
      final inner = radius - (major ? 14 : 8);
      final p1 = Offset(
        center.dx + inner * math.sin(angle),
        center.dy - inner * math.cos(angle),
      );
      final p2 = Offset(
        center.dx + radius * math.sin(angle),
        center.dy - radius * math.cos(angle),
      );
      canvas.drawLine(p1, p2, major ? majorTickPaint : minorTickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
