import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../firebase_options.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();

    // Initialize app and navigate
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    final startTime = DateTime.now();

    try {
      // Initialize Firebase if not already initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      // Check current authentication state
      final User? user = FirebaseAuth.instance.currentUser;

      // Ensure minimum splash duration for branding
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed.inMilliseconds < 1500) {
        await Future.delayed(Duration(milliseconds: 1500 - elapsed.inMilliseconds));
      }

      if (!mounted) return;

      // Navigate based on auth state
      if (user != null) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    } catch (e) {
      debugPrint("Initialization Error: $e");
      // Fallback to login on error
      if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.mustGradient),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'comat',
                style: TextStyle(
                  color: AppTheme.mustGold,
                  fontSize: 80,
                  fontWeight: FontWeight.w100,
                  letterSpacing: 4.0,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'COMRADE MARKETPLACE',
                style: TextStyle(
                  color: AppTheme.mustGold.withOpacity(0.5),
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}