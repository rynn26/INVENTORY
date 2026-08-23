import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../models/product_item.dart';

import '../../../core/utils/currency_formatter.dart';

class ProductCard extends StatelessWidget {
  final ProductItem product;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
  });

  String _formatCurrency(int amount) {
    return CurrencyFormatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final isOut = product.isOutOfStock;
    final isLow = product.isLowStock;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppStyles.radiusCard),
      child: Container(
        decoration: AppStyles.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image with Penitip / Habis Badge
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Stack(
                children: [
                  SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.surfaceMuted,
                          child: const Center(
                            child: Icon(
                              Icons.fastfood_rounded,
                              size: 40,
                              color: AppColors.textMuted,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Penitip badge at top right
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        product.penitipName,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                  ),

                  // Out of Stock Dimmer & "Habis" Badge
                  if (isOut) ...[
                    Positioned.fill(
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.danger.withValues(alpha: 0.3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Text(
                            'Habis',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Card Body Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Stock indicator
                  if (isOut)
                    const Text(
                      'Stok: 0',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else if (isLow)
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 13,
                          color: AppColors.warningIcon,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Stok: ${product.stock}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.warningText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'Stok: ${product.stock}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                  const SizedBox(height: 10),

                  // Price badge
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isOut
                          ? AppColors.surfaceMuted
                          : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _formatCurrency(product.price),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isOut
                            ? AppColors.textMuted
                            : AppColors.primary,
                      ),
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
