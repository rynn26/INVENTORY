import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../models/penitip_item.dart';

import '../../../core/utils/currency_formatter.dart';

class PenitipDetailModal extends StatelessWidget {
  final PenitipItem penitip;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onWhatsAppShare;

  const PenitipDetailModal({
    super.key,
    required this.penitip,
    required this.onEdit,
    required this.onDelete,
    required this.onWhatsAppShare,
  });

  String _formatCurrency(int amount) {
    return CurrencyFormatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final commission = (penitip.totalRevenue * (penitip.commissionRate / 100)).round();
    final netPayout = penitip.totalRevenue - commission;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Profile
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        penitip.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        penitip.phoneNumber != null && penitip.phoneNumber!.isNotEmpty
                            ? 'WA: ${penitip.phoneNumber}'
                            : 'Nomor belum didaftarkan',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Summary Financial Grid
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Makanan Dititipkan',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      Text(
                        '${penitip.totalProducts} jenis (${penitip.totalItems} pcs)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Omzet Penjualan',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      Text(
                        _formatCurrency(penitip.totalRevenue),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: AppColors.divider),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Komisi Toko (${penitip.commissionRate}%)',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                      Text(
                        _formatCurrency(commission),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Bersih Hak Penitip (Payout)',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                      Text(
                        _formatCurrency(netPayout),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (penitip.notes != null && penitip.notes!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 16, color: AppColors.primaryDark),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        penitip.notes!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: AppStyles.outlinedButtonStyle(),
                    onPressed: () {
                      Navigator.pop(context);
                      onEdit();
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit Profil'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: AppStyles.primaryButtonStyle(),
                    onPressed: () {
                      Navigator.pop(context);
                      onWhatsAppShare();
                    },
                    icon: const Icon(Icons.chat_bubble_outline_rounded,
                        size: 18, color: Colors.white),
                    label: const Text('Kirim Rekap WA'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Delete Button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  onDelete();
                },
                icon: const Icon(Icons.person_remove_outlined, size: 18),
                label: const Text('Hapus Mitra Penitip Ini'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
