import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../models/stock_item.dart';

import '../../../core/utils/currency_formatter.dart';

class StockDetailModal extends StatelessWidget {
  final StockItem item;
  final VoidCallback onAdjust;
  final VoidCallback onReturn;

  const StockDetailModal({
    super.key,
    required this.item,
    required this.onAdjust,
    required this.onReturn,
  });

  String _formatCurrency(int amount) {
    return CurrencyFormatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final totalAssetValue = item.availableStock * item.price;

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

            // Header Title & Close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Kartu Mutasi Stok Barang',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Product Hero Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Penitip: ${item.penitipName} • ${_formatCurrency(item.price)} / pcs',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Mutasi Movement Breakdown Grid
            const Text(
              'Rincian Mutasi Hari Ini',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.login_rounded,
                              size: 16, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text('Titipan Masuk'),
                        ],
                      ),
                      Text(
                        '+${item.initialStock + item.stockInToday} pcs',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.point_of_sale_rounded,
                              size: 16, color: Color(0xFF0F766E)),
                          SizedBox(width: 6),
                          Text('Terjual di Kasir'),
                        ],
                      ),
                      Text(
                        '-${item.stockSoldToday} pcs',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.assignment_return_rounded,
                              size: 16, color: AppColors.danger),
                          SizedBox(width: 6),
                          Text('Diretur / Kembali'),
                        ],
                      ),
                      Text(
                        '-${item.stockReturnedToday} pcs',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: AppColors.divider),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sisa Stok Siap Jual',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: item.status == StockStatus.habis
                              ? AppColors.danger.withValues(alpha: 0.1)
                              : (item.status == StockStatus.menipis
                                  ? const Color(0xFFFFFBEB)
                                  : AppColors.primaryLight),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${item.availableStock} pcs (${item.statusLabel})',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: item.status == StockStatus.habis
                                ? AppColors.danger
                                : (item.status == StockStatus.menipis
                                    ? AppColors.warningText
                                    : AppColors.primaryDark),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Total Nilai Aset Stok
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nilai Aset Stok Berjalan',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    _formatCurrency(totalAssetValue),
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons (Sesuaikan Stok & Retur Sisa)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: AppStyles.outlinedButtonStyle(),
                    onPressed: () {
                      Navigator.pop(context);
                      onAdjust();
                    },
                    icon: const Icon(Icons.tune_rounded, size: 18),
                    label: const Text('Koreksi Stok'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppStyles.radiusMedium),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      onReturn();
                    },
                    icon: const Icon(Icons.assignment_return_rounded,
                        size: 18, color: Colors.white),
                    label: const Text('Retur Titipan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
