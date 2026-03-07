import 'package:flutter/material.dart';

import 'package:first_project/core/constants/route_names.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  static const _bgPath = 'assets/images/Login.jpg';

  InputDecoration _fieldStyle({
    required String label,
    required String hint,
    required IconData suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFFBDE6FF), fontSize: 10),
      hintText: hint,
      hintStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: const Color(0x2233C6FF),
      suffixIcon: Icon(suffix, color: const Color(0xFF7ED8FF), size: 16),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _authShell(BuildContext context, Widget child) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          _bgPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2D7DD0), Color(0xFF031C5A)],
              ),
            ),
          ),
        ),
        Container(color: const Color(0x6600143B)),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _orDivider() {
    return Row(
      children: const [
        Expanded(child: Divider(color: Color(0x447ECBFF))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'OR',
            style: TextStyle(
              color: Color(0xFFB4DFFF),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Divider(color: Color(0x447ECBFF))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    void openHome() {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(RouteNames.home, (route) => false);
    }

    return Scaffold(
      body: _authShell(
        context,
        Container(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
          decoration: BoxDecoration(
            color: const Color(0x22000000),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x2AFFFFFF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Sign Up',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFD9F0FF),
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Center(
                child: SizedBox(
                  width: 72,
                  child: Divider(color: Color(0x886FD4FF), thickness: 1),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: _fieldStyle(
                  label: 'Email',
                  hint: 'mulimah.gmail.com',
                  suffix: Icons.email,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                obscureText: true,
                decoration: _fieldStyle(
                  label: 'Password',
                  hint: '........',
                  suffix: Icons.visibility_off,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                obscureText: true,
                decoration: _fieldStyle(
                  label: 'Confirm Password',
                  hint: '........',
                  suffix: Icons.visibility_off,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: const [
                  Icon(Icons.toggle_on, color: Color(0xFF6CDFFF), size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Save my info ?',
                    style: TextStyle(
                      color: Color(0xFFB9E4FF),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF28CDEA),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: openHome,
                  child: const Text(
                    'SIGN UP',
                    style: TextStyle(
                      letterSpacing: 1.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _orDivider(),
              const SizedBox(height: 14),
              SizedBox(
                height: 38,
                child: FilledButton.tonalIcon(
                  onPressed: openHome,
                  icon: const Icon(Icons.phone_android, size: 18),
                  label: const Text('Continue With Phone'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 38,
                child: FilledButton.tonalIcon(
                  onPressed: openHome,
                  icon: const Icon(Icons.g_mobiledata, size: 20),
                  label: const Text('Continue With Google'),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(color: Color(0xFFB9E4FF), fontSize: 12),
                  ),
                  GestureDetector(
                    onTap: () =>
                        Navigator.of(context).pushNamed(RouteNames.signIn),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: Color(0xFF50DCFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
