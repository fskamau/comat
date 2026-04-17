import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comat/core/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  final RegExp _phoneRegex = RegExp(r'^(?:254|\+254|0)?(7|1)\d{8}$');
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> _handleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final String email = googleUser.email.toLowerCase();

      // Ensure user is from the allowed organization domain
      if (!email.endsWith('@students.must.ac.ke') && !email.endsWith('@must.ac.ke')) {
        await _googleSignIn.signOut();
        if (mounted) {
          UIUtils.showError(context, 'Access Denied: Organization email required.');
          setState(() => _isLoading = false);
        }
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null && mounted) {
        // Check if user has already completed profile registration
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (userDoc.exists && userDoc.data()!.containsKey('phoneNumber')) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        } else {
          _showPhoneRegistration(context, user);
        }
      }
    } catch (e) {
      if (mounted) UIUtils.showError(context, 'Sign-in failed. Check connection.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPhoneRegistration(BuildContext context, User user) {
    final TextEditingController phoneController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppTheme.mustGreenSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 30, right: 30, top: 30
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.mustGold, size: 40),
            const SizedBox(height: 15),
            const Text(
              'FINAL STEP: CONTACT INFO',
              style: TextStyle(color: AppTheme.mustGold, letterSpacing: 2, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Enter your WhatsApp number for buyers to reach you.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 25),

            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '07xx xxx xxx',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                prefixIcon: const Icon(Icons.phone_iphone, color: AppTheme.mustGold, size: 20),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.mustGold)),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.mustGold,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final String phone = phoneController.text.trim();

                  // Validate phone number format
                  if (!_phoneRegex.hasMatch(phone)) {
                    UIUtils.showError(context, "Invalid format. Please use a valid phone number.", 3);
                    return;
                  }

                  try {
                    // Save user profile information to Firestore
                    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                      'displayName': user.displayName,
                      'email': user.email,
                      'phoneNumber': phone,
                      'joinedAt': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));

                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, AppRoutes.home);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      UIUtils.showError(context, "Network error: Could not save information. Try again.", 3);
                    }
                  }
                },
                child: const Text('ENTER MARKET', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.mustGreenBody,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(color: AppTheme.mustGreenBody),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50),
          child: Column(
            children: [
              const Spacer(flex: 7),

              const Text(
                'comat',
                style: TextStyle(
                  color: AppTheme.mustGold,
                  fontSize: 84,
                  fontWeight: FontWeight.w100,
                  letterSpacing: -4,
                ),
              ),

              Transform.translate(
                offset: const Offset(0, -10),
                child: Text(
                  'comrade market',
                  style: TextStyle(
                    color: AppTheme.mustGold.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              const Spacer(flex: 3),

              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.mustGold,
                  side: BorderSide(
                    color: AppTheme.mustGold.withOpacity(0.4),
                    width: 0.8,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: AppTheme.mustGreenSurface.withOpacity(0.5),
                ),
                onPressed: _isLoading ? null : _handleSignIn,
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.mustGold,
                    ),
                  )
                      : const Text(
                    'LOGIN',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Organization domains only',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}