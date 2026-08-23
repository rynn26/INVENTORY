import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';

class QuickActionsSection extends StatelessWidget {
  final VoidCallback onScanBarcode;
  final VoidCallback onAddTitipan;
  final VoidCallback onAddProduct;
  final VoidCallback onViewReport;

  const QuickActionsSection({
    super.key,
    required this.onScanBarcode,
    required this.onAddTitipan,
    required this.onAddProduct,
    required this.onViewReport,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aksi Cepat',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        // Grid 2 x 2
        Row(
          children: [
            // Item 1: Scan Barcode (Green Card)
            Expanded(
              child: _buildHeroActionCard(
                icon: Icons.qr_code_scanner_rounded,
                title: 'Scan Barcode',
                subtitle: 'Jual makanan dengan\ncepat',
                onTap: onScanBarcode,
              ),
            ),
            const SizedBox(width: 12),
            // Item 2: Tambah Titipan
            Expanded(
              child: _buildStandardActionCard(
                icon: Icons.add_box_outlined,
                title: 'Tambah Titipan',
                subtitle: 'Catat makanan baru',
                onTap: onAddTitipan,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Item 3: Tambah Produk
            Expanded(
              child: _buildStandardActionCard(
                icon: Icons.category_outlined,
                title: 'Tambah Produk',
                subtitle: 'Buat produk & barcode',
                onTap: onAddProduct,
              ),
            ),
            const SizedBox(width: 12),
            // Item 4: Laporan
            Expanded(
              child: _buildStandardActionCard(
                icon: Icons.bar_chart_rounded,
                title: 'Laporan',
                subtitle: 'Lihat hasil penjualan',
                onTap: onViewReport,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppStyles.radiusCard),
      child: Container(
        height: 125,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppStyles.radiusCard),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 10.5,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStandardActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppStyles.radiusCard),
      child: Container(
        height: 125,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: AppStyles.cardDecoration(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10.5,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
