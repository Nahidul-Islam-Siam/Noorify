import 'package:flutter/material.dart';

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
