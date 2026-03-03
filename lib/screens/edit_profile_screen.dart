import 'package:flutter/material.dart';

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
