import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../models/penitip_item.dart';

import '../../../core/utils/currency_formatter.dart';

class PenitipCardTile extends StatelessWidget {
  final PenitipItem penitip;
  final VoidCallback? onTap;

  const PenitipCardTile({
    super.key,
    required this.penitip,
    this.onTap,
  });

  String _formatCurrency(int amount) {
    return CurrencyFormatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppStyles.radiusCard),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: AppStyles.cardDecoration(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Store Avatar Icon
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.store_mall_directory_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),

            // Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    penitip.name,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${penitip.totalProducts} produk  •  ${penitip.totalItems} item',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatCurrency(penitip.totalRevenue),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Chevron Arrow
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
