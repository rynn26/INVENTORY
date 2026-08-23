import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/services/auth_service.dart';
import '../../admin/screens/admin_main_screen.dart';
import '../../navigation/screens/main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final profile = await AuthService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      // Arahkan sesuai role
      if (profile.isAdmin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminMainScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
          ),
          content: Text('Selamat datang, ${profile.fullName.isEmpty ? profile.roleName : profile.fullName}!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
          ),
          content: Text(_friendlyError(e.toString())),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('Invalid login') || raw.contains('invalid_credentials')) {
      return 'Email atau password salah. Coba lagi.';
    }
    if (raw.contains('Email not confirmed')) {
      return 'Email belum dikonfirmasi. Cek inbox kamu.';
    }
    if (raw.contains('network') || raw.contains('SocketException')) {
      return 'Tidak ada koneksi internet.';
    }
    return 'Login gagal. Coba lagi.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Logo & Branding
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00B048), AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.point_of_sale_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Brand Name
                  const Text(
                    'TitipKasir',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sistem Kasir & Konsinyasi Makanan Titipan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Info card: role otomatis dari DB
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: AppColors.primary, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Role kasir / admin diatur otomatis dari akun Anda.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Form Container Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppStyles.cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Login ke TitipKasir',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Masukkan email dan password akun Anda',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Email Field
                        const Text(
                          'Email',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: 'kasir@toko.com',
                            hintStyle: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13.5,
                            ),
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: AppColors.background,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppStyles.radiusMedium),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppStyles.radiusMedium),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppStyles.radiusMedium),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Wajib diisi';
                            if (!val.contains('@')) return 'Format email tidak valid';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password / PIN Field
                        const Text(
                          'Password / PIN',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Masukkan password / PIN',
                            hintStyle: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13.5,
                            ),
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.textMuted,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: AppColors.background,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppStyles.radiusMedium),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppStyles.radiusMedium),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppStyles.radiusMedium),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: (val) =>
                              val == null || val.isEmpty ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 14),

                        // Lupa Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  content: Text(
                                    'Hubungi administrator untuk reset password.',
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              'Lupa Password?',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: AppStyles.primaryButtonStyle(),
                            onPressed: _isLoading ? null : _handleLogin,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Masuk ke Aplikasi',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15.5,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),
                  const Text(
                    'Versi 1.0.0 • TitipKasir POS & Admin',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}
