import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';

import '../../../core/utils/currency_formatter.dart';

class StatCardsSection extends StatelessWidget {
  final int todayRevenue;
  final int itemsSold;
  final int transactions;
  final int remainingStock;

  const StatCardsSection({
    super.key,
    required this.todayRevenue,
    required this.itemsSold,
    required this.transactions,
    required this.remainingStock,
  });

  String _formatCurrency(int amount) {
    return CurrencyFormatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Omzet Hari Ini Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: AppStyles.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.payments_outlined,
                    size: 19,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Omzet Hari Ini',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _formatCurrency(todayRevenue),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Row Terjual & Transaksi
        Row(
          children: [
            // Terjual
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: AppStyles.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Terjual',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        text: '$itemsSold ',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        children: const [
                          TextSpan(
                            text: 'item',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Transaksi
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: AppStyles.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Transaksi',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        text: '$transactions ',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        children: const [
                          TextSpan(
                            text: 'trx',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Stok Tersisa Card (with warning alert)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: AppStyles.cardDecoration(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Stok Tersisa',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      text: '$remainingStock ',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      children: const [
                        TextSpan(
                          text: 'Item',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFEDD5), width: 1),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warningIcon,
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
