import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin localNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
const int maghribNotificationId = 1001;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeNotifications();
  runApp(const MyApp());
}

Future<void> _initializeNotifications() async {
  tz_data.initializeTimeZones();

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();

  await localNotificationsPlugin.initialize(
    const InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    ),
  );

  await localNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.requestNotificationsPermission();
  await localNotificationsPlugin
      .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(alert: true, badge: true, sound: true);
}

enum AppLanguage { english, bangla }

final ValueNotifier<AppLanguage> appLanguageNotifier =
    ValueNotifier<AppLanguage>(AppLanguage.english);
final ValueNotifier<bool> maghribAlertEnabledNotifier =
    ValueNotifier<bool>(true);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {  
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Design Preview',
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      ),
      home: const UiPreviewHome(),
    );
  }
}

class UiPreviewHome extends StatelessWidget {
  const UiPreviewHome({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <({String title, Widget page})>[
      (title: 'Splash Screen', page: const RamadanSplashScreen()),
      (title: 'Sign Up Screen', page: const SignupScreen()),
      (title: 'Profile Preferences', page: const ProfilePreferencesScreen()),
      (title: 'Edit Profile', page: const EditProfileScreen()),
      (title: 'Daily Activity', page: const DailyActivityScreen()),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('UI Mock Screens')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return FilledButton.tonal(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => item.page),
              );
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(item.title),
          );
        },
      ),
    );
  }
}

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

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  InputDecoration _fieldStyle(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF8BC8E1), fontSize: 11),
      filled: true,
      fillColor: const Color(0x22A9D9FF),
      suffixIcon: icon != null
          ? Icon(icon, size: 14, color: const Color(0xFF7DDDF2))
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2C8BC8), Color(0xFF0A2D72)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0x22000000),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'Sign Up',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      decoration: _fieldStyle(
                        'muslim@gmail.com',
                        icon: Icons.alternate_email,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: _fieldStyle(
                        'Name',
                        icon: Icons.person_outline,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: _fieldStyle(
                        'Confirm Password',
                        icon: Icons.visibility_outlined,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: const [
                        Icon(
                          Icons.toggle_on,
                          color: Color(0xFF84E4F5),
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Save my info?',
                          style: TextStyle(
                            color: Color(0xFF8ECFE4),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6CF1FF), Color(0xFF15C9E4)],
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'SIGN UP',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Center(
                      child: Text(
                        'OR',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _socialBtn('Continue with Phone', Icons.phone_android),
                    const SizedBox(height: 8),
                    _socialBtn('Continue with Google', Icons.g_mobiledata),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialBtn(String text, IconData icon) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0x1FFFFFFF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(width: 6),
          Icon(icon, size: 16, color: Colors.white),
        ],
      ),
    );
  }
}

class ProfilePreferencesScreen extends StatefulWidget {
  const ProfilePreferencesScreen({super.key});

  @override
  State<ProfilePreferencesScreen> createState() =>
      _ProfilePreferencesScreenState();
}

class _ProfilePreferencesScreenState extends State<ProfilePreferencesScreen> {
  final values = <String, bool>{
    'Prayer Time': true,
    'Quran Verses': true,
    'Prayer Learning': false,
    'Daily Tasbeeh': true,
    'Zikir Times': false,
    'Daily Newsfeed': true,
    'Dua Reminder': false,
    'Hadith Notification': true,
    'Email Notification': true,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    child: Icon(Icons.person, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Nuha Mvhed Zunader',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Done namaj 30/30',
                        style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE1E8EC)),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Language',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    ValueListenableBuilder<AppLanguage>(
                      valueListenable: appLanguageNotifier,
                      builder: (context, language, _) {
                        return ToggleButtons(
                          borderRadius: BorderRadius.circular(8),
                          isSelected: [
                            language == AppLanguage.english,
                            language == AppLanguage.bangla,
                          ],
                          onPressed: (index) {
                            appLanguageNotifier.value = index == 0
                                ? AppLanguage.english
                                : AppLanguage.bangla;
                          },
                          children: const [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('English'),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('Bangla'),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE1E8EC)),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Maghrib Alert',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    ValueListenableBuilder<bool>(
                      valueListenable: maghribAlertEnabledNotifier,
                      builder: (context, enabled, _) {
                        return Switch(
                          value: enabled,
                          onChanged: (v) => maghribAlertEnabledNotifier.value = v,
                          activeThumbColor: const Color(0xFF14A3B8),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  const Text(
                    'General',
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                  ...values.entries.map(
                    (e) => SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(e.key, style: const TextStyle(fontSize: 13)),
                      subtitle: const Text(
                        'Lorem ipsum description',
                        style: TextStyle(fontSize: 10),
                      ),
                      value: e.value,
                      activeThumbColor: const Color(0xFF14A3B8),
                      onChanged: (v) => setState(() => values[e.key] = v),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 38),
                  backgroundColor: const Color(0xFFE74A5A),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {},
                child: const Text('Logout'),
              ),
            ),
            _bottomNav(2),
          ],
        ),
      ),
    );
  }
}

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.arrow_back_ios, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Edit Profile',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                const CircleAvatar(
                  radius: 42,
                  backgroundColor: Color(0xFFD9DEE3),
                  child: Icon(Icons.person, size: 42, color: Color(0xFF6F8DA1)),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF14A3B8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8ECEF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Text('Nuha Mvhed Zunader', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                  backgroundColor: const Color(0xFF14A3B8),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {},
                child: const Text('Save Change'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DailyActivityScreen extends StatefulWidget {
  const DailyActivityScreen({super.key});

  @override
  State<DailyActivityScreen> createState() => _DailyActivityScreenState();
}

class _DailyActivityScreenState extends State<DailyActivityScreen> {
  static const _dhakaLat = 23.8103;
  static const _dhakaLng = 90.4125;
  static const _headerHeight = 330.0;

  late final Timer _clockTimer;
  DateTime _now = DateTime.now();
  double? _latitude;
  double? _longitude;
  DateTime? _lastPrayerCalcDate;
  DateTime? _todayMaghrib;
  bool _maghribModalShownToday = false;
  String _locationLabel = 'Detecting location...';
  String _countdownLabel = 'Calculating prayer...';
  String _activePrayer = 'Dzuhr';
  Duration _activeRemaining = Duration.zero;
  double _activeProgress = 0.0;
  Map<String, String> _prayerTimes = const {
    'Fajr': '--:--',
    'Dzuhr': '--:--',
    'Ashr': '--:--',
    'Maghrib': '--:--',
    'Isha': '--:--',
  };

  int _completedDaily = 3;
  final int _dailyGoal = 6;
  final List<String> _prayerOrder = const [
    'Fajr',
    'Dzuhr',
    'Ashr',
    'Maghrib',
    'Isha',
  ];
  late final PageController _prayerPageController;
  String? _selectedPrayer;

  final List<_ActivityItem> _activities = [
    _ActivityItem(title: 'Alms', done: 4, total: 10),
    _ActivityItem(title: 'Recite the Al Quran', done: 8, total: 10),
  ];

  @override
  void initState() {
    super.initState();
    _prayerPageController = PageController(
      viewportFraction: 0.23,
      initialPage: _prayerOrder.indexOf(_activePrayer),
    );
    appLanguageNotifier.addListener(_onLanguageChanged);
    maghribAlertEnabledNotifier.addListener(_onMaghribAlertToggleChanged);
    _loadPrayerData();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      _updateCountdown();
      _maybeShowMaghribModal();
      if (_lastPrayerCalcDate == null ||
          _lastPrayerCalcDate!.day != _now.day ||
          _lastPrayerCalcDate!.month != _now.month ||
          _lastPrayerCalcDate!.year != _now.year) {
        _recalculatePrayerTimesForToday();
      }
    });
  }

  @override
  void dispose() {
    appLanguageNotifier.removeListener(_onLanguageChanged);
    maghribAlertEnabledNotifier.removeListener(_onMaghribAlertToggleChanged);
    _clockTimer.cancel();
    _prayerPageController.dispose();
    super.dispose();
  }

  void _onLanguageChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _onMaghribAlertToggleChanged() async {
    if (maghribAlertEnabledNotifier.value) {
      if (_todayMaghrib != null) {
        await _scheduleMaghribNotification(_todayMaghrib!);
      }
    } else {
      await _cancelMaghribNotification();
    }
    if (mounted) setState(() {});
  }

  String get _formattedTime {
    final hour12 = (_now.hour % 12 == 0) ? 12 : _now.hour % 12;
    final minute = _now.minute.toString().padLeft(2, '0');
    final value = '$hour12:$minute';
    return _isBangla ? _toBanglaDigits(value) : value;
  }

  bool get _isBangla => appLanguageNotifier.value == AppLanguage.bangla;

  String _toBanglaDigits(String input) {
    const latin = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bangla = [
      '\u09e6',
      '\u09e7',
      '\u09e8',
      '\u09e9',
      '\u09ea',
      '\u09eb',
      '\u09ec',
      '\u09ed',
      '\u09ee',
      '\u09ef',
    ];
    var output = input;
    for (var i = 0; i < latin.length; i++) {
      output = output.replaceAll(latin[i], bangla[i]);
    }
    return output;
  }

  String _localizedPrayerName(String name) {
    if (!_isBangla) return name;
    const map = {
      'Fajr': '\u09ab\u099c\u09b0',
      'Dzuhr': '\u09af\u09cb\u09b9\u09b0',
      'Ashr': '\u0986\u09b8\u09b0',
      'Maghrib': '\u09ae\u09be\u0997\u09b0\u09bf\u09ac',
      'Isha': '\u0987\u09b6\u09be',
    };
    return map[name] ?? name;
  }

  String _localizedCountdownLabel() {
    if (!_isBangla) return _countdownLabel;
    final parts = _countdownLabel.split(' in ');
    if (parts.length == 2) {
      return '${_localizedPrayerName(parts[0])} \u09ac\u09be\u0995\u09bf ${_toBanglaDigits(parts[1])}';
    }
    return _toBanglaDigits(_countdownLabel);
  }

  String _localizedActiveRemainingLabel() =>
      _isBangla ? '\u09b6\u09c7\u09b7 \u09b9\u0993\u09df\u09be\u09b0 \u09ac\u09be\u0995\u09bf' : 'Time Left';

  String _localizedPrayerTimeLabel() =>
      _isBangla ? '\u09aa\u09cd\u09b0\u09be\u09b0\u09cd\u09a5\u09a8\u09be\u09b0 \u09b8\u09ae\u09df' : 'Prayer Time';

  String _localizedMaghribTitle() =>
      _isBangla ? '\u09ae\u09be\u0997\u09b0\u09bf\u09ac \u098f\u09b2\u09be\u09b0\u09cd\u099f' : 'Maghrib Alert';

  String _localizedMaghribBody() => _isBangla
      ? '\u09ae\u09be\u0997\u09b0\u09bf\u09ac\u09c7\u09b0 \u09b8\u09ae\u09df \u09b9\u09df\u09c7\u099b\u09c7\u0964'
      : 'It is time for Maghrib prayer.';

  String _localizedStopAlerts() =>
      _isBangla ? '\u098f\u09b2\u09be\u09b0\u09cd\u099f \u09ac\u09a8\u09cd\u09a7' : 'Stop Alerts';

  String _localizedClose() => _isBangla ? '\u09ac\u09a8\u09cd\u09a7' : 'Close';

  String _localizedPrayerTime(String value) =>
      _isBangla ? _toBanglaDigits(value) : value;

  Future<void> _scheduleMaghribNotification(DateTime maghribTime) async {
    if (!maghribAlertEnabledNotifier.value) return;

    var scheduled = tz.TZDateTime.from(maghribTime, tz.local);
    final nowTz = tz.TZDateTime.now(tz.local);
    if (scheduled.isBefore(nowTz)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'maghrib_alert_channel',
        'Maghrib Alerts',
        channelDescription: 'Alert when Maghrib time starts',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await localNotificationsPlugin.zonedSchedule(
      maghribNotificationId,
      _localizedMaghribTitle(),
      _localizedMaghribBody(),
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'maghrib',
    );
  }

  Future<void> _cancelMaghribNotification() async {
    await localNotificationsPlugin.cancel(maghribNotificationId);
  }

  void _maybeShowMaghribModal() {
    if (!maghribAlertEnabledNotifier.value) return;
    if (_todayMaghrib == null || _maghribModalShownToday) return;
    if (!mounted) return;

    final now = DateTime.now();
    final start = _todayMaghrib!;
    final end = start.add(const Duration(minutes: 1));
    if (now.isBefore(start) || now.isAfter(end)) return;

    _maghribModalShownToday = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(_localizedMaghribTitle()),
          content: Text(_localizedMaghribBody()),
          actions: [
            TextButton(
              onPressed: () async {
                maghribAlertEnabledNotifier.value = false;
                await _cancelMaghribNotification();
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Text(_localizedStopAlerts()),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_localizedClose()),
            ),
          ],
        );
      },
    );
  }

  String get _displayPrayer => _selectedPrayer ?? _activePrayer;
  bool get _isShowingActivePrayer => _displayPrayer == _activePrayer;

  void _syncPrayerPageToActive({required bool animate}) {
    if (!_prayerPageController.hasClients) return;
    final target = _prayerOrder.indexOf(_activePrayer);
    if (target == -1) return;
    if (animate) {
      _prayerPageController.animateToPage(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    } else {
      _prayerPageController.jumpToPage(target);
    }
  }

  Future<void> _loadPrayerData() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _latitude = _dhakaLat;
        _longitude = _dhakaLng;
        if (mounted) {
          setState(() => _locationLabel = 'Dhaka, Bangladesh');
        }
        _recalculatePrayerTimesForToday();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _latitude = _dhakaLat;
        _longitude = _dhakaLng;
        if (mounted) {
          setState(() => _locationLabel = 'Dhaka, Bangladesh');
        }
        _recalculatePrayerTimesForToday();
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      _latitude = position.latitude;
      _longitude = position.longitude;

      await _resolveLocationLabel(position.latitude, position.longitude);
      _recalculatePrayerTimesForToday();
    } catch (_) {
      _latitude = _dhakaLat;
      _longitude = _dhakaLng;
      if (!mounted) return;
      setState(() => _locationLabel = 'Dhaka, Bangladesh');
      _recalculatePrayerTimesForToday();
    }
  }

  Future<void> _resolveLocationLabel(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty || !mounted) return;
      final place = placemarks.first;
      final city =
          place.locality ??
          place.subAdministrativeArea ??
          place.administrativeArea ??
          'Your location';
      final area = place.administrativeArea ?? place.country ?? '';
      final label = area.isNotEmpty ? '$city, $area' : city;
      setState(() => _locationLabel = label);
    } catch (_) {
      if (!mounted) return;
      setState(() => _locationLabel = 'Current location');
    }
  }

  void _recalculatePrayerTimesForToday() {
    if (_latitude == null || _longitude == null) return;
    final isNewDay =
        _lastPrayerCalcDate == null ||
        _lastPrayerCalcDate!.day != _now.day ||
        _lastPrayerCalcDate!.month != _now.month ||
        _lastPrayerCalcDate!.year != _now.year;

    final params = CalculationMethodParameters.karachi();
    params.madhab = Madhab.hanafi;
    final prayers = PrayerTimes(
      date: DateTime.now(),
      coordinates: Coordinates(_latitude!, _longitude!),
      calculationParameters: params,
    );

    final fajr = prayers.fajr.toLocal();
    final dzuhr = prayers.dhuhr.toLocal();
    final ashr = prayers.asr.toLocal();
    final maghrib = prayers.maghrib.toLocal();
    final isha = prayers.isha.toLocal();
    final ishaBefore = prayers.ishaBefore.toLocal();
    final activeData = _buildActivePrayerData(
      now: _now,
      fajr: fajr,
      dzuhr: dzuhr,
      ashr: ashr,
      maghrib: maghrib,
      isha: isha,
      ishaBefore: ishaBefore,
    );

    setState(() {
      _lastPrayerCalcDate = DateTime.now();
      _todayMaghrib = maghrib;
      if (isNewDay) _maghribModalShownToday = false;
      _prayerTimes = {
        'Fajr': _formatPrayerTime(fajr),
        'Dzuhr': _formatPrayerTime(dzuhr),
        'Ashr': _formatPrayerTime(ashr),
        'Maghrib': _formatPrayerTime(maghrib),
        'Isha': _formatPrayerTime(isha),
      };
      _activePrayer = activeData.name;
      _countdownLabel = activeData.countdownLabel;
      _activeRemaining = activeData.remaining;
      _activeProgress = activeData.progress;
    });
    if (maghribAlertEnabledNotifier.value) {
      _scheduleMaghribNotification(maghrib);
    } else {
      _cancelMaghribNotification();
    }
    if (_selectedPrayer == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _syncPrayerPageToActive(animate: false);
      });
    }
  }

  void _updateCountdown() {
    if (_prayerTimes['Fajr'] == '--:--') return;
    if (_latitude == null || _longitude == null) return;
    final params = CalculationMethodParameters.karachi();
    params.madhab = Madhab.hanafi;
    final prayers = PrayerTimes(
      date: DateTime.now(),
      coordinates: Coordinates(_latitude!, _longitude!),
      calculationParameters: params,
    );

    final fajr = prayers.fajr.toLocal();
    final dzuhr = prayers.dhuhr.toLocal();
    final ashr = prayers.asr.toLocal();
    final maghrib = prayers.maghrib.toLocal();
    final isha = prayers.isha.toLocal();
    final ishaBefore = prayers.ishaBefore.toLocal();
    final activeData = _buildActivePrayerData(
      now: _now,
      fajr: fajr,
      dzuhr: dzuhr,
      ashr: ashr,
      maghrib: maghrib,
      isha: isha,
      ishaBefore: ishaBefore,
    );

    if (mounted &&
        (activeData.name != _activePrayer ||
            activeData.countdownLabel != _countdownLabel ||
            activeData.progress != _activeProgress ||
            activeData.remaining != _activeRemaining)) {
      setState(() {
        _activePrayer = activeData.name;
        _countdownLabel = activeData.countdownLabel;
        _activeRemaining = activeData.remaining;
        _activeProgress = activeData.progress;
      });
      if (_selectedPrayer == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _syncPrayerPageToActive(animate: true);
        });
      }
    }
  }

  String _formatPrayerTime(DateTime time) {
    final h = (time.hour % 12 == 0 ? 12 : time.hour % 12).toString();
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  _ActivePrayerData _buildActivePrayerData({
    required DateTime now,
    required DateTime fajr,
    required DateTime dzuhr,
    required DateTime ashr,
    required DateTime maghrib,
    required DateTime isha,
    required DateTime ishaBefore,
  }) {
    final schedule = <MapEntry<String, DateTime>>[
      MapEntry('Fajr', fajr),
      MapEntry('Dzuhr', dzuhr),
      MapEntry('Ashr', ashr),
      MapEntry('Maghrib', maghrib),
      MapEntry('Isha', isha),
    ];

    MapEntry<String, DateTime>? activePrayer;
    int activeIndex = -1;
    for (int i = 0; i < schedule.length; i++) {
      if (schedule[i].value.isAfter(now)) {
        activePrayer = schedule[i];
        activeIndex = i;
        break;
      }
    }

    DateTime previousBoundary;
    if (activePrayer == null) {
      activePrayer = MapEntry('Fajr', fajr.add(const Duration(days: 1)));
      previousBoundary = isha;
    } else if (activeIndex == 0) {
      previousBoundary = ishaBefore;
    } else {
      previousBoundary = schedule[activeIndex - 1].value;
    }

    final remaining = activePrayer.value.difference(now);
    final totalWindow = activePrayer.value.difference(previousBoundary);
    final elapsed = totalWindow - remaining;
    final progress = totalWindow.inMilliseconds <= 0
        ? 0.0
        : (elapsed.inMilliseconds / totalWindow.inMilliseconds).clamp(0.0, 1.0);
    final hh = remaining.inHours.toString().padLeft(2, '0');
    final mm = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return _ActivePrayerData(
      name: activePrayer.key,
      countdownLabel: '${activePrayer.key} in $hh:$mm:$ss',
      remaining: remaining.isNegative ? Duration.zero : remaining,
      progress: progress,
    );
  }

  String _formattedActiveRemaining() {
    final d = _activeRemaining.isNegative ? Duration.zero : _activeRemaining;
    final hh = d.inHours.toString().padLeft(2, '0');
    final mm = (d.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    final value = '$hh:$mm:$ss';
    return _isBangla ? _toBanglaDigits(value) : value;
  }

  @override
  Widget build(BuildContext context) {
    final gaugePrayerName = _localizedPrayerName(_displayPrayer);
    final gaugeSubtitle = _isShowingActivePrayer
        ? _localizedActiveRemainingLabel()
        : _localizedPrayerTimeLabel();
    final gaugeValue = _isShowingActivePrayer
        ? _formattedActiveRemaining()
        : _localizedPrayerTime(_prayerTimes[_displayPrayer] ?? '--:--');
    final gaugeProgress = _isShowingActivePrayer ? _activeProgress : 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: _headerHeight,
              decoration: const BoxDecoration(
                color: Color(0xFF1D98A9),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/header-bg.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              _formattedTime,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
                            ),
                            Spacer(),
                            const Text(
                              '10 Ramadhan 1446 H',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              _localizedCountdownLabel(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x33FFFFFF),
                                borderRadius: BorderRadius.circular(1000),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  SizedBox(
                                    width: 132,
                                    child: Text(
                                      _locationLabel,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _ActivePrayerGauge(
                          prayerName: gaugePrayerName,
                          subtitle: gaugeSubtitle,
                          remainingTime: gaugeValue,
                          progress: gaugeProgress,
                        ),
                        const SizedBox(height: 6),
                        if (!_isShowingActivePrayer)
                          Align(
                            alignment: Alignment.center,
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () {
                                setState(() => _selectedPrayer = null);
                                _syncPrayerPageToActive(animate: true);
                              },
                              icon: const Icon(Icons.my_location, size: 16),
                              label: Text(
                                _isBangla
                                    ? '\u09ac\u09b0\u09cd\u09a4\u09ae\u09be\u09a8 \u09aa\u09cd\u09b0\u09be\u09b0\u09cd\u09a5\u09a8\u09be'
                                    : 'Back to current',
                              ),
                            ),
                          ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: -12,
                    child: SizedBox(
                      height: 102,
                      child: PageView.builder(
                        controller: _prayerPageController,
                        itemCount: _prayerOrder.length,
                        onPageChanged: (index) {
                          setState(() => _selectedPrayer = _prayerOrder[index]);
                        },
                        itemBuilder: (context, index) {
                          final prayer = _prayerOrder[index];
                          return Center(
                            child: _PrayerTile(
                              title: _localizedPrayerName(prayer),
                              time: _localizedPrayerTime(
                                _prayerTimes[prayer] ?? '--:--',
                              ),
                              active: prayer == _displayPrayer,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE1E8EC)),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Last Read',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6F8DA1),
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.menu_book_rounded,
                                    size: 16,
                                    color: Color(0xFF1D98A9),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Al Baqarah : 120',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF1F252D),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Juz 1',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF6F8DA1),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        FilledButton(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1D98A9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(1000),
                            ),
                          ),
                          child: const Text(
                            'Continue',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE1E8EC)),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Locate',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF1F252D),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Qibla',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D98A9),
                            borderRadius: BorderRadius.circular(1000),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.explore,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const SizedBox(
                          height: 48,
                          child: VerticalDivider(
                            color: Color(0xFFE1E8EC),
                            thickness: 1,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Find nearest',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF1F252D),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Mosque',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D98A9),
                            borderRadius: BorderRadius.circular(1000),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.location_city,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text(
                        'Daily Activity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F252D),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC95C16),
                          borderRadius: BorderRadius.circular(1000),
                        ),
                        child: const Text(
                          '50%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Complete the daily activity checklist',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6F8DA1)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (int i = 0; i < _dailyGoal; i++) ...[
                        Expanded(
                          child: Container(
                            height: 6,
                            margin: EdgeInsets.only(
                              right: i == _dailyGoal - 1 ? 0 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: i < _completedDaily
                                  ? const Color(0xFF1D98A9)
                                  : const Color(0xFFE1E8EC),
                              borderRadius: BorderRadius.circular(1000),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      Text(
                        '$_completedDaily/$_dailyGoal',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1D98A9),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._activities.map(
                    (activity) => _ChecklistRow(
                      title: activity.title,
                      status: '${activity.done}/${activity.total}',
                      isDone: activity.done >= activity.total,
                      onTapDone: () {
                        setState(() {
                          if (activity.done < activity.total) {
                            activity.done += 1;
                          }
                          if (_completedDaily < _dailyGoal) {
                            _completedDaily += 1;
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 46),
                      backgroundColor: const Color(0xFF1D98A9),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Daily activity saved locally'),
                        ),
                      );
                    },
                    child: const Text('Go to Checklist'),
                  ),
                ],
              ),
            ),
            _bottomNav(0),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem {
  _ActivityItem({required this.title, required this.done, required this.total});

  final String title;
  int done;
  final int total;
}

class _ActivePrayerData {
  const _ActivePrayerData({
    required this.name,
    required this.countdownLabel,
    required this.remaining,
    required this.progress,
  });

  final String name;
  final String countdownLabel;
  final Duration remaining;
  final double progress;
}

class _ActivePrayerGauge extends StatelessWidget {
  const _ActivePrayerGauge({
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
    canvas.drawArc(rect, 3.14159, 3.14159 * progress.clamp(0.0, 1.0), false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _ActivePrayerGaugePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _PrayerTile extends StatelessWidget {
  const _PrayerTile({
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

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
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

Widget _bottomNav(int active) {
  final items = [
    ('Home', Icons.home_filled),
    ('Discover', Icons.explore_outlined),
    ('Quran', Icons.menu_book_outlined),
    ('Prayer', Icons.calendar_month_outlined),
    ('Profile', Icons.person_outline),
  ];

  return Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(items.length, (index) {
        final item = items[index];
        final isActive = index == active;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.$2,
              size: 20,
              color: isActive ? const Color(0xFF14A3B8) : Colors.black45,
            ),
            const SizedBox(height: 2),
            Text(
              item.$1,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? const Color(0xFF14A3B8) : Colors.black45,
              ),
            ),
          ],
        );
      }),
    ),
  );
}

