import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../models/stock_item.dart';

import '../../../core/utils/currency_formatter.dart';

class StockCardTile extends StatelessWidget {
  final StockItem item;
  final VoidCallback? onTap;

  const StockCardTile({
    super.key,
    required this.item,
    this.onTap,
  });

  String _formatCurrency(int amount) {
    return CurrencyFormatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    Color badgeBgColor;
    Color badgeTextColor;

    switch (item.status) {
      case StockStatus.aman:
        badgeBgColor = AppColors.successBg;
        badgeTextColor = AppColors.successText;
        break;
      case StockStatus.menipis:
        badgeBgColor = AppColors.warningBg;
        badgeTextColor = AppColors.warningText;
        break;
      case StockStatus.habis:
        badgeBgColor = AppColors.dangerBg;
        badgeTextColor = AppColors.dangerText;
        break;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppStyles.radiusCard),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: AppStyles.cardDecoration(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Product Thumbnail / Image Placeholder
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 68,
                height: 68,
                color: AppColors.surfaceMuted,
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 32,
                            color: AppColors.textMuted,
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 32,
                          color: AppColors.textMuted,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatCurrency(item.price),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${item.availableStock} tersedia',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),

            // Status Badge (Aman / Menipis / Habis)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: badgeBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                item.statusLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: badgeTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
