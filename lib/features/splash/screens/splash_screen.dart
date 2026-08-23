import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../admin/screens/admin_main_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../../navigation/screens/main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleRouting();
  }

  Future<void> _handleRouting() async {
    final startTime = DateTime.now();

    final user = AuthService.currentUser;
    Widget destination;

    if (user == null) {
      destination = const LoginScreen();
    } else {
      try {
        final profile = await AuthService.getCurrentProfile();
        if (profile != null && profile.isAdmin) {
          destination = const AdminMainScreen();
        } else {
          destination = const MainNavigationScreen();
        }
      } catch (_) {
        destination = const LoginScreen();
      }
    }

    // Durasi splash screen 4 detik
    final elapsed = DateTime.now().difference(startTime);
    const minDuration = Duration(milliseconds: 4000);
    if (elapsed < minDuration) {
      await Future.delayed(minDuration - elapsed);
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Spacer atas agar logo berada di tengah
            const Spacer(),

            // Center: Logo & Brand Name
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.point_of_sale_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'TitipKasir',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Aplikasi Kasir & Titipan Produk',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Spacer bawah
            const Spacer(),

            // Bottom: Powered By PT RYNZ DIGITAL CREATIVE
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'powered by',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'PT RYNZ DIGITAL CREATIVE',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
