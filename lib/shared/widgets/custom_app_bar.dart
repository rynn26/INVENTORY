import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../features/auth/screens/login_screen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationTap;
  final bool isBrandTitle;
  final bool? showBackButton;

  const CustomAppBar({
    super.key,
    this.title = 'TitipKasir',
    this.leading,
    this.actions,
    this.onProfileTap,
    this.onNotificationTap,
    this.isBrandTitle = false,
    this.showBackButton,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1.0);

  void _showDefaultProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
                color: AppColors.primaryLight,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Profil Pengguna',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'TitipKasir Sistem Konsinyasi & POS',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: AppStyles.outlinedButtonStyle(),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                },
                icon: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                label: const Text('Ganti Akun / Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canPop = Navigator.canPop(context);
    final bool shouldShowBack = showBackButton ?? canPop;

    Widget? effectiveLeading = leading;
    if (effectiveLeading == null) {
      if (shouldShowBack) {
        effectiveLeading = IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.primary,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        );
      } else {
        effectiveLeading = Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onProfileTap ?? () => _showDefaultProfileSheet(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary,
                    width: 1.6,
                  ),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            ),
          ),
        );
      }
    }

    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      leading: effectiveLeading,
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: 18.5,
          letterSpacing: -0.3,
        ),
      ),
      actions: actions ??
          [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: onNotificationTap ??
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tidak ada notifikasi baru'),
                            duration: Duration(milliseconds: 1200),
                          ),
                        );
                      },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.border,
                        width: 1.2,
                      ),
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.textPrimary,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          color: AppColors.divider,
          height: 1.0,
        ),
      ),
    );
  }
}
