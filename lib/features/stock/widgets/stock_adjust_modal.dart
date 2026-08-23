import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../models/stock_item.dart';

class StockAdjustModal extends StatefulWidget {
  final StockItem item;
  final Function(int newStock) onStockUpdated;

  const StockAdjustModal({
    super.key,
    required this.item,
    required this.onStockUpdated,
  });

  @override
  State<StockAdjustModal> createState() => _StockAdjustModalState();
}

class _StockAdjustModalState extends State<StockAdjustModal> {
  late int _currentStock;

  @override
  void initState() {
    super.initState();
    _currentStock = widget.item.availableStock;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Text(
              'Kelola Stok: ${widget.item.name}',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Perbarui sisa stok fisik di etalase/toko.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // Stepper Counter Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () {
                    if (_currentStock > 0) {
                      setState(() => _currentStock -= 1);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.remove, size: 22),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      Text(
                        '$_currentStock',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Text(
                        'Tersedia',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() => _currentStock += 1);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 22,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick add buttons (+5, +10, +20)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [5, 10, 20].map((qty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ActionChip(
                    label: Text('+$qty'),
                    onPressed: () {
                      setState(() => _currentStock += qty);
                    },
                    backgroundColor: AppColors.surfaceMuted,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Simpan Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: AppStyles.primaryButtonStyle(),
                onPressed: () {
                  widget.onStockUpdated(_currentStock);
                  Navigator.pop(context);
                },
                child: const Text('Simpan Perubahan Stok'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
