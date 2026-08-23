import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../models/dashboard_data.dart';

import '../../../core/utils/currency_formatter.dart';

class TopProductsSection extends StatelessWidget {
  final List<TopProduct> products;
  final VoidCallback onViewAll;

  const TopProductsSection({
    super.key,
    required this.products,
    required this.onViewAll,
  });

  String _formatCurrency(int amount) {
    return CurrencyFormatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.cardDecoration(),
      child: Column(
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Produk Terlaris',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              InkWell(
                onTap: onViewAll,
                child: const Text(
                  'Lihat Semua',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Product List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = products[index];
              final isTop1 = item.rank == 1;

              return Row(
                children: [
                  // Rank badge
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isTop1
                          ? AppColors.primaryTint
                          : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${item.rank}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isTop1
                            ? AppColors.primaryDark
                            : const Color(0xFF334155),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title & Sold Count
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.soldCount} terjual',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Price
                  Text(
                    _formatCurrency(item.price),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
