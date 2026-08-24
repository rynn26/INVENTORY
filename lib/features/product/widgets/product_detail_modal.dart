import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../models/product_item.dart';

import '../../../core/utils/currency_formatter.dart';

class ProductDetailModal extends StatelessWidget {
  final ProductItem product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPrintBarcode;

  const ProductDetailModal({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.onPrintBarcode,
  });

  String _formatCurrency(int amount) {
    return CurrencyFormatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final isOwnProduct = product.penitipName.isEmpty;
    final barcodeDisplay = product.barcode != null && product.barcode!.isNotEmpty
        ? product.barcode!
        : 'TK-${product.id.replaceAll("-", "").substring(0, 8).toUpperCase()}';

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
                  'Detail Produk Makanan',
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      product.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        width: 80,
                        height: 80,
                        color: AppColors.surfaceMuted,
                        child: const Icon(
                          Icons.fastfood_rounded,
                          color: AppColors.textMuted,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product.category,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isOwnProduct ? 'Dagangan Sendiri' : product.penitipName,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isOwnProduct
                                ? const Color(0xFF16A34A)
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Pricing & Stock Grid
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Harga Jual',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatCurrency(product.price),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sisa Stok',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${product.stock} pcs',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: product.isOutOfStock
                                ? AppColors.danger
                                : (product.isLowStock
                                    ? AppColors.warningText
                                    : AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Info Box: Pemilik & Kode Barcode
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pemilik Produk',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                      ),
                      Row(
                        children: [
                          Icon(
                            isOwnProduct
                                ? Icons.store_rounded
                                : Icons.person_outline_rounded,
                            size: 14,
                            color: isOwnProduct
                                ? const Color(0xFF16A34A)
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isOwnProduct ? 'Dagangan Sendiri' : product.penitipName,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isOwnProduct
                                  ? const Color(0xFF16A34A)
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Komisi',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                      ),
                      Text(
                        isOwnProduct
                            ? 'Tidak ada (milik sendiri)'
                            : 'Lihat di Edit Penitip',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontStyle: isOwnProduct ? FontStyle.normal : FontStyle.italic,
                          color: isOwnProduct
                              ? const Color(0xFF16A34A)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Kode Barcode',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                      ),
                      Text(
                        barcodeDisplay,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons (Edit, Cetak Barcode, Delete)
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
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: AppStyles.primaryButtonStyle(),
                    onPressed: () {
                      Navigator.pop(context);
                      onPrintBarcode();
                    },
                    icon: const Icon(Icons.qr_code_2_rounded,
                        size: 18, color: Colors.white),
                    label: const Text('Sticker Barcode'),
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
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Hapus Produk Ini'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
