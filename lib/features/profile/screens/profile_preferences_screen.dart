import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:first_project/features/admin/services/admin_role_service.dart';
import 'package:first_project/features/auth/services/auth_service.dart';
import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/core/constants/route_names.dart';
import 'package:first_project/shared/widgets/bottom_nav.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class ProfilePreferencesScreen extends StatefulWidget {
  const ProfilePreferencesScreen({super.key});

  @override
  State<ProfilePreferencesScreen> createState() =>
      _ProfilePreferencesScreenState();
}

class _ProfilePreferencesScreenState extends State<ProfilePreferencesScreen> {
  static const _teal = Color(0xFF14A3B8);

  bool get _isBangla => appLanguageNotifier.value == AppLanguage.bangla;

  bool _looksMojibake(String value) {
    for (final unit in value.codeUnits) {
      if (unit == 0x00C3 ||
          unit == 0x00C2 ||
          unit == 0x00E0 ||
          unit == 0x00D8 ||
          unit == 0x00D9 ||
          unit == 0x00D0 ||
          unit == 0x00E2) {
        return true;
      }
    }
    return false;
  }

  String _repairMojibake(String value) {
    var output = value;
    for (var i = 0; i < 5; i++) {
      if (!_looksMojibake(output)) break;
      try {
        output = utf8.decode(latin1.encode(output));
      } catch (_) {
        break;
      }
    }
    return output;
  }

  bool _containsBangla(String value) {
    return RegExp(r'[\u0980-\u09FF]').hasMatch(value);
  }

  String _text(String english, String bangla) {
    if (!_isBangla) return english;
    final repaired = _repairMojibake(bangla);
    if (_looksMojibake(repaired)) return english;
    return _containsBangla(repaired) ? repaired : english;
  }

  @override
  void initState() {
    super.initState();
    appLanguageNotifier.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    appLanguageNotifier.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openEditProfile() async {
    await Navigator.of(context).pushNamed(RouteNames.editProfile);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(_text('Logout', '\u09b2\u0997\u0986\u0989\u099f')),
          content: Text(
            _text(
              'Are you sure you want to logout now?',
              '\u0986\u09aa\u09a8\u09bf \u0995\u09bf \u098f\u0996\u09a8 \u09b2\u0997\u0986\u0989\u099f \u0995\u09b0\u09a4\u09c7 \u099a\u09be\u09a8?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(_text('Cancel', '\u09ac\u09be\u09a4\u09bf\u09b2')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(_text('Logout', '\u09b2\u0997\u0986\u0989\u099f')),
            ),
          ],
        );
      },
    );
    if (confirm != true || !mounted) return;
    try {
      await AuthService.instance.signOut();
    } catch (_) {
      // Keep logout flow usable even if sign out fails on a local-only session.
    }
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(RouteNames.signIn, (route) => false);
  }

  Future<void> _openChangePassword() async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please sign in first.')));
      return;
    }

    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    var obscureCurrent = true;
    var obscureNew = true;
    var obscureConfirm = true;
    var submitting = false;

    final changed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> submitChange() async {
              final current = currentPasswordController.text;
              final next = newPasswordController.text;
              final confirm = confirmPasswordController.text;

              if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please complete all fields.')),
                );
                return;
              }
              if (next.length < 6) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'New password must be at least 6 characters.',
                    ),
                  ),
                );
                return;
              }
              if (next != confirm) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'New password and confirm password do not match.',
                    ),
                  ),
                );
                return;
              }
              if (current == next) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'New password must be different from current password.',
                    ),
                  ),
                );
                return;
              }

              setDialogState(() => submitting = true);
              try {
                await AuthService.instance.changePassword(
                  currentPassword: current,
                  newPassword: next,
                );
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop(true);
              } on FirebaseAuthException catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AuthService.instance.messageForException(e)),
                  ),
                );
              } catch (_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Failed to change password. Please try again.',
                    ),
                  ),
                );
              } finally {
                if (dialogContext.mounted) {
                  setDialogState(() => submitting = false);
                }
              }
            }

            return AlertDialog(
              title: Text(
                _text(
                  'Change Password',
                  'পাস�??o�Yার্ড পরিবর্তন',
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPasswordController,
                    obscureText: obscureCurrent,
                    decoration: InputDecoration(
                      labelText: _text(
                        'Current Password',
                        'বর্তমান পাস�??o�Yার্ড',
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setDialogState(
                            () => obscureCurrent = !obscureCurrent,
                          );
                        },
                        icon: Icon(
                          obscureCurrent
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: newPasswordController,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: _text(
                        'New Password',
                        'নতুন পাস�??o�Yার্ড',
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setDialogState(() => obscureNew = !obscureNew);
                        },
                        icon: Icon(
                          obscureNew
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: _text(
                        'Confirm Password',
                        'পাস�??o�Yার্ড নিশ্�sিত �???রুন',
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setDialogState(
                            () => obscureConfirm = !obscureConfirm,
                          );
                        },
                        icon: Icon(
                          obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(false),
                  child: Text(_text('Cancel', '\u09ac\u09be\u09a4\u09bf\u09b2')),
                ),
                FilledButton(
                  onPressed: submitting ? null : submitChange,
                  child: submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_text('Update', '�???পড�???�Y')),
                ),
              ],
            );
          },
        );
      },
    );

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();

    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully.')),
      );
    }
  }

  Future<void> _setFontSize(AppFontSize value) async {
    appFontSizeNotifier.value = value;
    await saveAppPreferences();
  }

  String _fontSizeLabel(AppFontSize size) {
    if (!_isBangla) return appFontSizeLabel(size);
    switch (size) {
      case AppFontSize.small:
        return '\u099b\u09cb\u099f';
      case AppFontSize.medium:
        return '\u09ae\u09be\u099d\u09be\u09b0\u09bf';
      case AppFontSize.large:
        return '\u09ac\u09dc';
    }
  }

  String _translationLanguageLabel(String value) {
    if (!_isBangla) return value;
    if (value == 'Bangla') return '\u09ac\u09be\u0982\u09b2\u09be';
    if (value == 'English') return '\u0987\u0982\u09b0\u09c7\u099c\u09bf';
    return value;
  }

  Future<void> _setDarkTheme(bool value) async {
    darkThemeEnabledNotifier.value = value;
    await saveAppPreferences();
  }

  Future<void> _setHapticFeedback(bool value) async {
    hapticFeedbackEnabledNotifier.value = value;
    await saveAppPreferences();
  }

  Future<void> _setUseDeviceLocation(bool value) async {
    try {
      if (!value) {
        useDeviceLocationNotifier.value = false;
        await saveAppPreferences();
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        useDeviceLocationNotifier.value = false;
        await saveAppPreferences();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _text(
                'Please enable phone location service first',
                'ÃƒÂ Ã‚Â¦Ã‚ÂªÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â¦Ã‚Â¥ÃƒÂ Ã‚Â¦Ã‚Â®ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ ÃƒÂ Ã‚Â¦Ã‚Â«ÃƒÂ Ã‚Â§Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¦Ã‚Â¨ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã‚Â° ÃƒÂ Ã‚Â¦Ã‚Â²ÃƒÂ Ã‚Â§Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã‚Â¶ÃƒÂ Ã‚Â¦Ã‚Â¨ ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â­ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã‚Â¸ ÃƒÂ Ã‚Â¦Ã…Â¡ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â²ÃƒÂ Ã‚Â§Ã‚Â ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¨',
              ),
            ),
          ),
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        useDeviceLocationNotifier.value = false;
        await saveAppPreferences();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _text(
                'Location permission is permanently denied. Enable it in app settings.',
                'ÃƒÂ Ã‚Â¦Ã‚Â²ÃƒÂ Ã‚Â§Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã‚Â¶ÃƒÂ Ã‚Â¦Ã‚Â¨ ÃƒÂ Ã‚Â¦Ã‚ÂªÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â¦Ã‚Â®ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã‚Â¶ÃƒÂ Ã‚Â¦Ã‚Â¨ ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¥ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â¯ÃƒÂ Ã‚Â¦Ã‚Â¼ÃƒÂ Ã‚Â§Ã¢â€šÂ¬ÃƒÂ Ã‚Â¦Ã‚Â­ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â¬ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ ÃƒÂ Ã‚Â¦Ã‚Â¬ÃƒÂ Ã‚Â¦Ã‚Â¨ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â§ÃƒÂ Ã‚Â¥Ã‚Â¤ ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¦ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¯ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Âª ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã…Â¸ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã¢â‚¬Å¡ÃƒÂ Ã‚Â¦Ã‚Â¸ ÃƒÂ Ã‚Â¦Ã‚Â¥ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ ÃƒÂ Ã‚Â¦Ã…Â¡ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â²ÃƒÂ Ã‚Â§Ã‚Â ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¨ÃƒÂ Ã‚Â¥Ã‚Â¤',
              ),
            ),
          ),
        );
        return;
      }
      if (permission == LocationPermission.denied) {
        useDeviceLocationNotifier.value = false;
        await saveAppPreferences();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _text(
                'Location permission is needed for accurate timings',
                'ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â¦Ã‚Â ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â¦Ã‚Â®ÃƒÂ Ã‚Â¦Ã‚Â¯ÃƒÂ Ã‚Â¦Ã‚Â¼ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã‚Â° ÃƒÂ Ã‚Â¦Ã…â€œÃƒÂ Ã‚Â¦Ã‚Â¨ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¯ ÃƒÂ Ã‚Â¦Ã‚Â²ÃƒÂ Ã‚Â§Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã‚Â¶ÃƒÂ Ã‚Â¦Ã‚Â¨ ÃƒÂ Ã‚Â¦Ã‚ÂªÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â¦Ã‚Â®ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã‚Â¶ÃƒÂ Ã‚Â¦Ã‚Â¨ ÃƒÂ Ã‚Â¦Ã‚ÂªÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â¦Ã‚Â¯ÃƒÂ Ã‚Â¦Ã‚Â¼ÃƒÂ Ã‚Â§Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¦Ã…â€œÃƒÂ Ã‚Â¦Ã‚Â¨',
              ),
            ),
          ),
        );
        return;
      }

      useDeviceLocationNotifier.value = value;
      await saveAppPreferences();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'Device location enabled',
              'ÃƒÂ Ã‚Â¦Ã‚Â¡ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã‚Â­ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã‚Â¸ ÃƒÂ Ã‚Â¦Ã‚Â²ÃƒÂ Ã‚Â§Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã‚Â¶ÃƒÂ Ã‚Â¦Ã‚Â¨ ÃƒÂ Ã‚Â¦Ã…Â¡ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â²ÃƒÂ Ã‚Â§Ã‚Â ÃƒÂ Ã‚Â¦Ã‚Â¹ÃƒÂ Ã‚Â¦Ã‚Â¯ÃƒÂ Ã‚Â¦Ã‚Â¼ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã¢â‚¬ÂºÃƒÂ Ã‚Â§Ã¢â‚¬Â¡',
            ),
          ),
        ),
      );
    } catch (e) {
      useDeviceLocationNotifier.value = false;
      await saveAppPreferences();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'Unable to enable location on this device right now',
              'ÃƒÂ Ã‚Â¦Ã‚ÂÃƒÂ Ã‚Â¦Ã¢â‚¬Â¡ ÃƒÂ Ã‚Â¦Ã‚Â¡ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã‚Â­ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ ÃƒÂ Ã‚Â¦Ã‚ÂÃƒÂ Ã‚Â¦Ã¢â‚¬â€œÃƒÂ Ã‚Â¦Ã‚Â¨ ÃƒÂ Ã‚Â¦Ã‚Â²ÃƒÂ Ã‚Â§Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã‚Â¶ÃƒÂ Ã‚Â¦Ã‚Â¨ ÃƒÂ Ã‚Â¦Ã…Â¡ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â²ÃƒÂ Ã‚Â§Ã‚Â ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â¦Ã‚Â¾ ÃƒÂ Ã‚Â¦Ã‚Â¯ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã…Â¡ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã¢â‚¬ÂºÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ ÃƒÂ Ã‚Â¦Ã‚Â¨ÃƒÂ Ã‚Â¦Ã‚Â¾',
            ),
          ),
        ),
      );
      debugPrint('Use device location toggle failed: $e');
    }
  }

  Future<void> _setShowLatinLetters(bool value) async {
    showLatinLettersNotifier.value = value;
    await saveAppPreferences();
  }

  Future<void> _setShowTranslation(bool value) async {
    showTranslationNotifier.value = value;
    await saveAppPreferences();
  }

  Future<void> _pickTranslationLanguage({
    required String currentLanguage,
  }) async {
    final currentOption = _isBangla && currentLanguage == 'Bangla'
        ? '\u09ac\u09be\u0982\u09b2\u09be'
        : currentLanguage;
    final selected = await _pickOption(
      title: _text(
        'Translation Language',
        '\u0985\u09a8\u09c1\u09ac\u09be\u09a6\u09c7\u09b0 \u09ad\u09be\u09b7\u09be',
      ),
      options: _isBangla
          ? const ['\u09ac\u09be\u0982\u09b2\u09be', 'English']
          : const ['English', 'Bangla'],
      current: currentOption,
    );
    if (selected == null) return;
    final normalizedSelected = selected == '\u09ac\u09be\u0982\u09b2\u09be'
        ? 'Bangla'
        : selected;
    if (normalizedSelected == currentLanguage) return;
    translationLanguageNotifier.value = normalizedSelected;
    await saveAppPreferences();
  }

  Future<void> _setShowTajweed(bool value) async {
    showTajweedNotifier.value = value;
    await saveAppPreferences();
  }

  Future<void> _setAdzanNotification(bool value) async {
    prayerAlertsEnabledNotifier.value = value;
    await saveAppPreferences();
  }

  Future<void> _setImsakNotification(bool value) async {
    sehriAlertEnabledNotifier.value = value;
    await saveAppPreferences();
  }

  Future<void> _setHifzMode(bool value) async {
    hifzModeEnabledNotifier.value = value;
    if (!value) {
      hifzHideBanglaMeaningNotifier.value = false;
    }
    await saveAppPreferences();
  }

  Future<void> _setHifzHideBanglaMeaning(bool value) async {
    hifzHideBanglaMeaningNotifier.value = value;
    await saveAppPreferences();
  }

  Future<void> _selectHifzRepeatCount() async {
    final current = '${hifzRepeatCountNotifier.value}x';
    final selected = await _pickOption(
      title: _text(
        'Hifz Repeat Count',
        'ÃƒÂ Ã‚Â¦Ã‚Â¹ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã‚Â«ÃƒÂ Ã‚Â¦Ã…â€œ ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã‚ÂªÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã…Â¸ ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â¦Ã¢â‚¬Å¡ÃƒÂ Ã‚Â¦Ã¢â‚¬â€œÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¯ÃƒÂ Ã‚Â¦Ã‚Â¾',
      ),
      options: const ['1x', '3x', '5x', '10x'],
      current: current,
    );
    if (selected == null) return;
    final parsed = int.tryParse(selected.replaceAll('x', ''));
    if (parsed == null || parsed == hifzRepeatCountNotifier.value) return;
    hifzRepeatCountNotifier.value = parsed;
    await saveAppPreferences();
  }

  Future<String?> _pickOption({
    required String title,
    required List<String> options,
    required String current,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const Divider(height: 1),
              ...options.map((option) {
                final selected = option == current;
                return ListTile(
                  title: Text(option),
                  trailing: selected
                      ? const Icon(Icons.check, color: _teal)
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(option),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectFontSize() async {
    final current = appFontSizeNotifier.value;
    final selected = await showModalBottomSheet<AppFontSize>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: Text(
                  _text(
                    'Font Size',
                    'ÃƒÂ Ã‚Â¦Ã‚Â«ÃƒÂ Ã‚Â¦Ã‚Â¨ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã…Â¸ ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã…â€œ',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const Divider(height: 1),
              ...AppFontSize.values.map((size) {
                final selected = size == current;
                return ListTile(
                  title: Text(_fontSizeLabel(size)),
                  trailing: selected
                      ? const Icon(Icons.check, color: _teal)
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(size),
                );
              }),
            ],
          ),
        );
      },
    );
    if (selected == null || selected == current) return;
    await _setFontSize(selected);
  }

  Uint8List? _decodeProfilePhoto(String? base64) {
    if (base64 == null || base64.isEmpty) return null;
    try {
      return base64Decode(base64);
    } catch (_) {
      return null;
    }
  }

  Widget _avatar() {
    return ValueListenableBuilder2<String?, String?>(
      first: profilePhotoBase64Notifier,
      second: profilePhotoUrlNotifier,
      builder: (context, encoded, photoUrl, _) {
        final glass = NoorifyGlassTheme(context);
        final bytes = _decodeProfilePhoto(encoded);
        final hasPhotoUrl = (photoUrl ?? '').trim().isNotEmpty;
        if (bytes != null) {
          return CircleAvatar(
            radius: 19,
            backgroundImage: MemoryImage(bytes),
            backgroundColor: Colors.white,
          );
        }
        if (hasPhotoUrl) {
          return CircleAvatar(
            radius: 19,
            backgroundImage: NetworkImage(photoUrl!.trim()),
            backgroundColor: Colors.white,
          );
        }
        return CircleAvatar(
          radius: 19,
          backgroundColor: glass.isDark
              ? const Color(0xFF2A3A4A)
              : const Color(0xFFCCD7E2),
          child: Icon(
            Icons.person,
            color: glass.isDark
                ? const Color(0xFFB6C9D8)
                : const Color(0xFF6B7A8A),
            size: 19,
          ),
        );
      },
    );
  }

  Widget _sectionCard({
    required Widget child,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) {
    return NoorifyGlassCard(
      radius: BorderRadius.circular(14),
      padding: padding,
      child: child,
    );
  }

  Widget _sectionLabel(String text) {
    final glass = NoorifyGlassTheme(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 12, 6, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10.5,
            color: glass.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _rowTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final glass = NoorifyGlassTheme(context);
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -2),
      leading: Icon(icon, size: 16, color: glass.textSecondary),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: glass.textPrimary,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: glass.textMuted,
                height: 1.2,
              ),
            ),
      trailing:
          trailing ??
          Icon(Icons.chevron_right_rounded, color: glass.textMuted, size: 18),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      horizontalTitleGap: 10,
      minVerticalPadding: 6,
    );
  }

  Widget _switchRow({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    VoidCallback? onTap,
  }) {
    final glass = NoorifyGlassTheme(context);
    return _rowTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap ?? () => onChanged(!value),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: glass.accent,
        activeThumbColor: Colors.white,
        inactiveTrackColor: glass.isDark
            ? const Color(0x335F7E94)
            : const Color(0xFFD4DCE3),
        inactiveThumbColor: glass.isDark
            ? const Color(0xFF8AA8BC)
            : const Color(0xFF90A2AF),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return Scaffold(
      backgroundColor: glass.bgBottom,
      body: NoorifyGlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                      child: Text(
                        _text(
                          'Profile',
                          'ÃƒÂ Ã‚Â¦Ã‚ÂªÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â§Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¦Ã‚Â«ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã‚Â²',
                        ),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: glass.textPrimary,
                        ),
                      ),
                    ),
                    _sectionCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          _avatar(),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ValueListenableBuilder<String>(
                                  valueListenable: profileNameNotifier,
                                  builder: (context, name, _) {
                                    final displayName = name.trim().isEmpty
                                        ? _text(
                                            'Add your name',
                                            '\u0986\u09aa\u09a8\u09be\u09b0 \u09a8\u09be\u09ae \u09af\u09cb\u0997 \u0995\u09b0\u09c1\u09a8',
                                          )
                                        : name.trim();
                                    return Text(
                                      displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: glass.textPrimary,
                                        fontSize: 13,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 1),
                                ValueListenableBuilder<String>(
                                  valueListenable: profileLocationNotifier,
                                  builder: (context, location, _) {
                                    return Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on_rounded,
                                          color: _teal,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 3),
                                        Expanded(
                                          child: Text(
                                            location,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              color: _teal,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          color: glass.textMuted,
                                          size: 16,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _openEditProfile,
                            icon: Icon(
                              Icons.edit_outlined,
                              size: 17,
                              color: glass.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _sectionLabel(_text('Nearby', '�???শ�???পাশ�???')),
                    _sectionCard(
                      child: _rowTile(
                        icon: Icons.mosque_rounded,
                        title: _text(
                          'Find Mosque',
                          'মস�?"িদ �??"ুঁ�?"ুন',
                        ),
                        subtitle: _text(
                          'Open nearest mosque and sync recent results',
                          '\u09a8\u09bf\u0995\u099f\u09ac\u09b0\u09cd\u09a4\u09c0 \u09ae\u09b8\u099c\u09bf\u09a6 \u0996\u09c1\u09b2\u09c1\u09a8 \u098f\u09ac\u0982 \u09b8\u09be\u09ae\u09cd\u09aa\u09cd\u09b0\u09a4\u09bf\u0995 \u09ab\u09b2\u09be\u09ab\u09b2 \u09b8\u09bf\u0999\u09cd\u0995 \u0995\u09b0\u09c1\u09a8',
                        ),
                        onTap: () {
                          Navigator.of(
                            context,
                          ).pushNamed(RouteNames.findMosque);
                        },
                      ),
                    ),
                    _sectionLabel(
                      _text('General', 'ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â§ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â¦Ã‚Â£'),
                    ),
                    _sectionCard(
                      child: Column(
                        children: [
                          ValueListenableBuilder<AppFontSize>(
                            valueListenable: appFontSizeNotifier,
                            builder: (context, size, _) {
                              return _rowTile(
                                icon: Icons.text_fields_rounded,
                                title: _text(
                                  'Font Size',
                                  'ÃƒÂ Ã‚Â¦Ã‚Â«ÃƒÂ Ã‚Â¦Ã‚Â¨ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã…Â¸ ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã…â€œ',
                                ),
                                subtitle: _fontSizeLabel(size),
                                onTap: _selectFontSize,
                              );
                            },
                          ),
                          Divider(height: 1, color: glass.glassBorder),
                          _rowTile(
                            icon: Icons.lock_outline_rounded,
                            title: _text(
                              'Change Password',
                              'পাস�??o�Yার্ড পরিবর্তন',
                            ),
                            subtitle: _text(
                              'Update your account password',
                              '\u0986\u09aa\u09a8\u09be\u09b0 \u0985\u09cd\u09af\u09be\u0995\u09be\u0989\u09a8\u09cd\u099f\u09c7\u09b0 \u09aa\u09be\u09b8\u0993\u09df\u09be\u09b0\u09cd\u09a1 \u0986\u09aa\u09a1\u09c7\u099f \u0995\u09b0\u09c1\u09a8',
                            ),
                            onTap: _openChangePassword,
                          ),
                          Divider(height: 1, color: glass.glassBorder),
                          ValueListenableBuilder<bool>(
                            valueListenable: darkThemeEnabledNotifier,
                            builder: (context, enabled, _) {
                              return _switchRow(
                                icon: Icons.dark_mode_outlined,
                                title: _text(
                                  'Dark Theme',
                                  'ÃƒÂ Ã‚Â¦Ã‚Â¡ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ ÃƒÂ Ã‚Â¦Ã‚Â¥ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã‚Â®',
                                ),
                                subtitle: _text(
                                  'Switch to dark color scheme',
                                  'ÃƒÂ Ã‚Â¦Ã‚Â¡ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â²ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â° ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã‚Â® ÃƒÂ Ã‚Â¦Ã…Â¡ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â²ÃƒÂ Ã‚Â§Ã‚Â ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¨',
                                ),
                                value: enabled,
                                onChanged: _setDarkTheme,
                              );
                            },
                          ),
                          Divider(height: 1, color: glass.glassBorder),
                          ValueListenableBuilder<bool>(
                            valueListenable: hapticFeedbackEnabledNotifier,
                            builder: (context, enabled, _) {
                              return _switchRow(
                                icon: Icons.vibration_rounded,
                                title: _text(
                                  'Vibration',
                                  'ভা�???ব্র�???শন',
                                ),
                                subtitle: _text(
                                  'Enable vibration feedback in app actions',
                                  '\u0985\u09cd\u09af\u09be\u09aa\u09c7\u09b0 \u0995\u09be\u099c\u0997\u09c1\u09b2\u09cb\u09a4\u09c7 \u09ad\u09be\u0987\u09ac\u09cd\u09b0\u09c7\u09b6\u09a8 \u09ab\u09bf\u09a1\u09ac\u09cd\u09af\u09be\u0995 \u099a\u09be\u09b2\u09c1 \u0995\u09b0\u09c1\u09a8',
                                ),
                                value: enabled,
                                onChanged: _setHapticFeedback,
                              );
                            },
                          ),
                          Divider(height: 1, color: glass.glassBorder),
                          ValueListenableBuilder<bool>(
                            valueListenable: useDeviceLocationNotifier,
                            builder: (context, enabled, _) {
                              return _switchRow(
                                icon: Icons.my_location_rounded,
                                title: _text(
                                  'Use Device Location',
                                  'ÃƒÂ Ã‚Â¦Ã‚Â¡ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã‚Â­ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã‚Â¸ ÃƒÂ Ã‚Â¦Ã‚Â²ÃƒÂ Ã‚Â§Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã‚Â¶ÃƒÂ Ã‚Â¦Ã‚Â¨ ÃƒÂ Ã‚Â¦Ã‚Â¬ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¯ÃƒÂ Ã‚Â¦Ã‚Â¬ÃƒÂ Ã‚Â¦Ã‚Â¹ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â°',
                                ),
                                subtitle: _text(
                                  'Accurate prayer/sehri/iftar by your area',
                                  'ÃƒÂ Ã‚Â¦Ã¢â‚¬Â ÃƒÂ Ã‚Â¦Ã‚ÂªÃƒÂ Ã‚Â¦Ã‚Â¨ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â° ÃƒÂ Ã‚Â¦Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â²ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â° ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â¦Ã‚Â ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â²ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â¤/ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã‚Â¹ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â¦Ã‚Â¿/ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã‚Â«ÃƒÂ Ã‚Â¦Ã‚Â¤ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â° ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â¦Ã‚Â®ÃƒÂ Ã‚Â¦Ã‚Â¯ÃƒÂ Ã‚Â¦Ã‚Â¼',
                                ),
                                value: enabled,
                                onChanged: _setUseDeviceLocation,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    _sectionLabel(
                      _text(
                        'Prayer Setting',
                        'ÃƒÂ Ã‚Â¦Ã‚ÂªÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¥ÃƒÂ Ã‚Â¦Ã‚Â¨ÃƒÂ Ã‚Â¦Ã‚Â¾ ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã…Â¸ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã¢â‚¬Å¡',
                      ),
                    ),
                    _sectionCard(
                      child: Column(
                        children: [
                          ValueListenableBuilder<bool>(
                            valueListenable: showLatinLettersNotifier,
                            builder: (context, enabled, _) {
                              return _switchRow(
                                icon: Icons.short_text_rounded,
                                title: _text(
                                  'Show English Transliteration',
                                  'Show English Transliteration',
                                ),
                                subtitle: _text(
                                  'Display English transliteration while reading Quran',
                                  'Display English transliteration while reading Quran',
                                ),
                                value: enabled,
                                onChanged: _setShowLatinLetters,
                              );
                            },
                          ),
                          Divider(height: 1, color: glass.glassBorder),
                          ValueListenableBuilder2<bool, String>(
                            first: showTranslationNotifier,
                            second: translationLanguageNotifier,
                            builder: (context, enabled, language, _) {
                              return _switchRow(
                                icon: Icons.translate_rounded,
                                title: _text(
                                  'Show Translation',
                                  'ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¦ÃƒÂ Ã‚Â¦Ã‚Â¨ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¬ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â¦ ÃƒÂ Ã‚Â¦Ã‚Â¦ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã¢â‚¬â€œÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â¨',
                                ),
                                subtitle: _translationLanguageLabel(language),
                                value: enabled,
                                onChanged: (value) async {
                                  await _setShowTranslation(value);
                                  if (!value) return;
                                  await _pickTranslationLanguage(
                                    currentLanguage: language,
                                  );
                                },
                                onTap: enabled
                                    ? () {
                                        _pickTranslationLanguage(
                                          currentLanguage: language,
                                        );
                                      }
                                    : null,
                              );
                            },
                          ),
                          Divider(height: 1, color: glass.glassBorder),
                          ValueListenableBuilder<bool>(
                            valueListenable: showTajweedNotifier,
                            builder: (context, enabled, _) {
                              return _switchRow(
                                icon: Icons.menu_book_outlined,
                                title: _text(
                                  'Show Tajweed',
                                  'ÃƒÂ Ã‚Â¦Ã‚Â¤ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã…â€œÃƒÂ Ã‚Â¦Ã‚Â¬ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã‚Â¦ ÃƒÂ Ã‚Â¦Ã‚Â¦ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã¢â‚¬â€œÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â¨',
                                ),
                                subtitle: _text(
                                  'Click to view the tajweed detail',
                                  'ÃƒÂ Ã‚Â¦Ã‚Â¤ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã…â€œÃƒÂ Ã‚Â¦Ã‚Â¬ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã‚Â¦ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã‚Â° ÃƒÂ Ã‚Â¦Ã‚Â¬ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¤ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã‚Â¤ ÃƒÂ Ã‚Â¦Ã‚Â¦ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã¢â‚¬â€œÃƒÂ Ã‚Â¦Ã‚Â¤ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ ÃƒÂ Ã‚Â¦Ã…Â¡ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â²ÃƒÂ Ã‚Â§Ã‚Â ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¨',
                                ),
                                value: enabled,
                                onChanged: _setShowTajweed,
                              );
                            },
                          ),
                          Divider(height: 1, color: glass.glassBorder),
                          ValueListenableBuilder<String>(
                            valueListenable: translatorNotifier,
                            builder: (context, translator, _) {
                              return _rowTile(
                                icon: Icons.person_outline,
                                title: _text(
                                  'Translator',
                                  'ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¦ÃƒÂ Ã‚Â¦Ã‚Â¨ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¬ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â¦ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢',
                                ),
                                subtitle: translator,
                                onTap: () async {
                                  final selected = await _pickOption(
                                    title: _text(
                                      'Translator',
                                      'ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¦ÃƒÂ Ã‚Â¦Ã‚Â¨ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¬ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â¦ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢',
                                    ),
                                    options: const [
                                      'Dr. Mustafa Khattab',
                                      'Muhiuddin Khan',
                                      'Tafsir Ibn Kathir (Brief)',
                                    ],
                                    current: translator,
                                  );
                                  if (selected == null ||
                                      selected == translator) {
                                    return;
                                  }
                                  translatorNotifier.value = selected;
                                  await saveAppPreferences();
                                },
                              );
                            },
                          ),
                          Divider(height: 1, color: glass.glassBorder),
                          ValueListenableBuilder<String>(
                            valueListenable: reciterNotifier,
                            builder: (context, reciter, _) {
                              return _rowTile(
                                icon: Icons.mic_none_rounded,
                                title: _text(
                                  'Reciters',
                                  'ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â§Ã¢â€šÂ¬',
                                ),
                                subtitle: reciter,
                                onTap: () async {
                                  final selected = await _pickOption(
                                    title: _text(
                                      'Reciter',
                                      'ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â§Ã¢â€šÂ¬',
                                    ),
                                    options: const [
                                      'Mishary Rashid Alafasy',
                                      'Saad Al-Ghamdi',
                                      'Maher Al Muaiqly',
                                    ],
                                    current: reciter,
                                  );
                                  if (selected == null || selected == reciter) {
                                    return;
                                  }
                                  reciterNotifier.value = selected;
                                  await saveAppPreferences();
                                },
                              );
                            },
                          ),
                          Divider(height: 1, color: glass.glassBorder),
                          ValueListenableBuilder2<bool, String>(
                            first: prayerAlertsEnabledNotifier,
                            second: adzanVoiceNotifier,
                            builder: (context, enabled, voice, _) {
                              return _switchRow(
                                icon: Icons.notifications_active_outlined,
                                title: _text(
                                  'Adzan Notification',
                                  'ÃƒÂ Ã‚Â¦Ã¢â‚¬Â ÃƒÂ Ã‚Â¦Ã‚Â¯ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â¨ ÃƒÂ Ã‚Â¦Ã‚Â¨ÃƒÂ Ã‚Â§Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¦Ã…Â¸ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã‚Â«ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã‚Â¶ÃƒÂ Ã‚Â¦Ã‚Â¨',
                                ),
                                subtitle: voice,
                                value: enabled,
                                onChanged: (value) async {
                                  await _setAdzanNotification(value);
                                  if (!value) return;
                                  final selected = await _pickOption(
                                    title: _text(
                                      'Adzan Voice',
                                      'ÃƒÂ Ã‚Â¦Ã¢â‚¬Â ÃƒÂ Ã‚Â¦Ã‚Â¯ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â¨ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã‚Â° ÃƒÂ Ã‚Â¦Ã‚Â­ÃƒÂ Ã‚Â¦Ã‚Â¯ÃƒÂ Ã‚Â¦Ã‚Â¼ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã‚Â¸',
                                    ),
                                    options: const [
                                      'Hanan Attaki',
                                      'Mishary Alafasy',
                                      'Maher Al Muaiqly',
                                    ],
                                    current: voice,
                                  );
                                  if (selected == null || selected == voice) {
                                    return;
                                  }
                                  adzanVoiceNotifier.value = selected;
                                  await saveAppPreferences();
                                },
                              );
                            },
                          ),
                          Divider(height: 1, color: glass.glassBorder),
                          ValueListenableBuilder2<bool, String>(
                            first: sehriAlertEnabledNotifier,
                            second: imsakVoiceNotifier,
                            builder: (context, enabled, voice, _) {
                              return _switchRow(
                                icon: Icons.alarm_on_outlined,
                                title: _text(
                                  'Imsak Notification',
                                  'ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã‚Â®ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ ÃƒÂ Ã‚Â¦Ã‚Â¨ÃƒÂ Ã‚Â§Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¦Ã…Â¸ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã‚Â«ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã‚Â¶ÃƒÂ Ã‚Â¦Ã‚Â¨',
                                ),
                                subtitle: voice,
                                value: enabled,
                                onChanged: (value) async {
                                  await _setImsakNotification(value);
                                  if (!value) return;
                                  final selected = await _pickOption(
                                    title: _text(
                                      'Imsak Tone',
                                      'ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã‚Â®ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ ÃƒÂ Ã‚Â¦Ã…Â¸ÃƒÂ Ã‚Â§Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¦Ã‚Â¨',
                                    ),
                                    options: const [
                                      'Default',
                                      'Gentle',
                                      'Beep',
                                    ],
                                    current: voice,
                                  );
                                  if (selected == null || selected == voice) {
                                    return;
                                  }
                                  imsakVoiceNotifier.value = selected;
                                  await saveAppPreferences();
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    _sectionLabel(
                      _text(
                        'Quran Learning',
                        'ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â¦Ã¢â‚¬Â ÃƒÂ Ã‚Â¦Ã‚Â¨ ÃƒÂ Ã‚Â¦Ã‚Â²ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¨ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã¢â‚¬Å¡',
                      ),
                    ),
                    _sectionCard(
                      child: ValueListenableBuilder<bool>(
                        valueListenable: hifzModeEnabledNotifier,
                        builder: (context, enabled, _) {
                          return Column(
                            children: [
                              _switchRow(
                                icon: Icons.self_improvement_outlined,
                                title: _text(
                                  'Enable Hifz Mode',
                                  'ÃƒÂ Ã‚Â¦Ã‚Â¹ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã‚Â«ÃƒÂ Ã‚Â¦Ã…â€œ ÃƒÂ Ã‚Â¦Ã‚Â®ÃƒÂ Ã‚Â§Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¦Ã‚Â¡ ÃƒÂ Ã‚Â¦Ã…Â¡ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â²ÃƒÂ Ã‚Â§Ã‚Â ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¨',
                                ),
                                subtitle: _text(
                                  'Use repeat mode for ayah memorization',
                                  'ÃƒÂ Ã‚Â¦Ã¢â‚¬Â ÃƒÂ Ã‚Â¦Ã‚Â¯ÃƒÂ Ã‚Â¦Ã‚Â¼ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â¤ ÃƒÂ Ã‚Â¦Ã‚Â®ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã¢â‚¬â€œÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¥ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã‚Â° ÃƒÂ Ã‚Â¦Ã…â€œÃƒÂ Ã‚Â¦Ã‚Â¨ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¯ ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã‚ÂªÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã…Â¸ ÃƒÂ Ã‚Â¦Ã‚Â®ÃƒÂ Ã‚Â§Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¦Ã‚Â¡ ÃƒÂ Ã‚Â¦Ã‚Â¬ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¯ÃƒÂ Ã‚Â¦Ã‚Â¬ÃƒÂ Ã‚Â¦Ã‚Â¹ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â° ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¨',
                                ),
                                value: enabled,
                                onChanged: _setHifzMode,
                              ),
                              if (enabled) ...[
                                Divider(height: 1, color: glass.glassBorder),
                                ValueListenableBuilder<int>(
                                  valueListenable: hifzRepeatCountNotifier,
                                  builder: (context, repeatCount, _) {
                                    return _rowTile(
                                      icon: Icons.repeat_rounded,
                                      title: _text(
                                        'Hifz Repeat Count',
                                        'ÃƒÂ Ã‚Â¦Ã‚Â¹ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã‚Â«ÃƒÂ Ã‚Â¦Ã…â€œ ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã‚ÂªÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã…Â¸ ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â¦Ã¢â‚¬Å¡ÃƒÂ Ã‚Â¦Ã¢â‚¬â€œÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¯ÃƒÂ Ã‚Â¦Ã‚Â¾',
                                      ),
                                      subtitle: _text(
                                        '${repeatCount}x per ayah',
                                        'ÃƒÂ Ã‚Â¦Ã‚ÂªÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â¦Ã‚Â¤ÃƒÂ Ã‚Â¦Ã‚Â¿ ÃƒÂ Ã‚Â¦Ã¢â‚¬Â ÃƒÂ Ã‚Â¦Ã‚Â¯ÃƒÂ Ã‚Â¦Ã‚Â¼ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â¤ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ ${repeatCount}x',
                                      ),
                                      onTap: _selectHifzRepeatCount,
                                    );
                                  },
                                ),
                                Divider(height: 1, color: glass.glassBorder),
                                ValueListenableBuilder<bool>(
                                  valueListenable:
                                      hifzHideBanglaMeaningNotifier,
                                  builder: (context, hideBangla, _) {
                                    return _switchRow(
                                      icon: Icons.visibility_off_outlined,
                                      title: _text(
                                        'Hide Bangla in Hifz',
                                        'ÃƒÂ Ã‚Â¦Ã‚Â¹ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã‚Â«ÃƒÂ Ã‚Â¦Ã…â€œÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ ÃƒÂ Ã‚Â¦Ã‚Â¬ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã¢â‚¬Å¡ÃƒÂ Ã‚Â¦Ã‚Â²ÃƒÂ Ã‚Â¦Ã‚Â¾ ÃƒÂ Ã‚Â¦Ã‚Â²ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â¨',
                                      ),
                                      subtitle: _text(
                                        'Show Arabic only while practicing',
                                        'ÃƒÂ Ã‚Â¦Ã‚ÂªÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¯ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¦Ã…Â¸ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ ÃƒÂ Ã‚Â¦Ã‚Â¶ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â§ÃƒÂ Ã‚Â§Ã‚Â ÃƒÂ Ã‚Â¦Ã¢â‚¬Â ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â¦Ã‚Â¬ÃƒÂ Ã‚Â¦Ã‚Â¿ ÃƒÂ Ã‚Â¦Ã‚Â¦ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã¢â‚¬â€œÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â¨',
                                      ),
                                      value: hideBangla,
                                      onChanged: _setHifzHideBanglaMeaning,
                                    );
                                  },
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                    StreamBuilder<bool>(
                      stream: AdminRoleService.instance.watchCurrentUserAdmin(),
                      builder: (context, snapshot) {
                        final isAdmin = snapshot.data ?? false;
                        if (!isAdmin) return const SizedBox.shrink();
                        return Column(
                          children: [
                            _sectionLabel(
                              _text('Admin', '�???্যাডমিন'),
                            ),
                            _sectionCard(
                              child: _rowTile(
                                icon: Icons.admin_panel_settings_outlined,
                                title: _text(
                                  'Admin Panel',
                                  '�???্যাডমিন প্যান�???ল',
                                ),
                                subtitle: _text(
                                  'Manage app announcements and modal banners',
                                  '\u0985\u09cd\u09af\u09be\u09aa\u09c7\u09b0 \u0985\u09cd\u09af\u09be\u09a8\u09be\u0989\u09a8\u09cd\u09b8\u09ae\u09c7\u09a8\u09cd\u099f \u0993 \u09ae\u09cb\u09a1\u09be\u09b2 \u09ac\u09cd\u09af\u09be\u09a8\u09be\u09b0 \u09aa\u09b0\u09bf\u099a\u09be\u09b2\u09a8\u09be \u0995\u09b0\u09c1\u09a8',
                                ),
                                onTap: () {
                                  Navigator.of(
                                    context,
                                  ).pushNamed(RouteNames.adminPanel);
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.center,
                      child: FilledButton.icon(
                        onPressed: _logout,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE64C5B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 9,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        icon: const Icon(Icons.logout_rounded, size: 14),
                        label: Text(
                          _text(
                            'Log Out',
                            'ÃƒÂ Ã‚Â¦Ã‚Â²ÃƒÂ Ã‚Â¦Ã¢â‚¬â€ ÃƒÂ Ã‚Â¦Ã¢â‚¬Â ÃƒÂ Ã‚Â¦Ã¢â‚¬Â°ÃƒÂ Ã‚Â¦Ã…Â¸',
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              bottomNav(context, 4),
            ],
          ),
        ),
      ),
    );
  }
}

class ValueListenableBuilder2<A, B> extends StatelessWidget {
  const ValueListenableBuilder2({
    super.key,
    required this.first,
    required this.second,
    required this.builder,
  });

  final ValueNotifier<A> first;
  final ValueNotifier<B> second;
  final Widget Function(BuildContext context, A a, B b, Widget? child) builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (context, a, child) {
        return ValueListenableBuilder<B>(
          valueListenable: second,
          builder: (context, b, child) => builder(context, a, b, child),
        );
      },
    );
  }
}





