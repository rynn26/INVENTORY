import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../models/cart_item.dart';

import '../../../core/utils/currency_formatter.dart';

class CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  const CartItemTile({
    super.key,
    required this.item,
    this.onIncrement,
    this.onDecrement,
  });

  String _formatCurrency(int amount) {
    return CurrencyFormatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: AppStyles.cardDecoration(),
      child: Row(
        children: [
          // Thumbnail Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 52,
              height: 52,
              child: Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.primaryLight,
                    child: const Icon(
                      Icons.fastfood_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Title and Quantity Breakdown
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (item.penitipName != null &&
                    item.penitipName!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.storefront_rounded,
                        size: 11,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Penitip: ${item.penitipName}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      '${_formatCurrency(item.price)} × ${item.quantity}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (onIncrement != null && onDecrement != null) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: onDecrement,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.remove,
                            size: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: onIncrement,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Total Price
          Text(
            _formatCurrency(item.totalPrice),
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
