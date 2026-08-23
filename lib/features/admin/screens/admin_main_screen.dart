import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../penitip/screens/penitip_list_screen.dart';
import '../../product/screens/product_list_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_settlement_screen.dart';
import 'barcode_generator_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const AdminDashboardScreen(),
      const BarcodeGeneratorScreen(),
      const ProductListScreen(),
      const PenitipListScreen(),
      const AdminSettlementScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(
              color: AppColors.divider,
              width: 1.2,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, 'Dashboard', Icons.dashboard_rounded),
              _buildNavItem(1, 'Barcode', Icons.qr_code_2_rounded),
              _buildNavItem(2, 'Produk', Icons.grid_view_rounded),
              _buildNavItem(3, 'Penitip', Icons.handshake_outlined),
              _buildNavItem(4, 'Bagi Hasil', Icons.account_balance_wallet_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon) {
    final isSelected = _currentIndex == index;

    if (isSelected) {
      return InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(AppStyles.radiusPill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppStyles.radiusPill),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: AppColors.textMuted,
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
