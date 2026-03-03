import 'package:flutter/material.dart';

import 'daily_activity_screen.dart';
import 'edit_profile_screen.dart';
import 'profile_preferences_screen.dart';
import 'ramadan_splash_screen.dart';
import 'signup_screen.dart';

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
