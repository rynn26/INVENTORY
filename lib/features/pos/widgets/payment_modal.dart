import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../models/cart_item.dart';

import '../../../core/utils/currency_formatter.dart';

class PaymentModal extends StatefulWidget {
  final List<CartItem> cartItems;
  final int totalAmount;
  final VoidCallback onPaymentSuccess;

  const PaymentModal({
    super.key,
    required this.cartItems,
    required this.totalAmount,
    required this.onPaymentSuccess,
  });

  @override
  State<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal> {
  int _selectedMethod = 0; // 0: Tunai, 1: QRIS, 2: Transfer
  bool _isProcessing = false;
  bool _isSuccess = false;

  String _formatCurrency(int amount) {
    return CurrencyFormatter.format(amount);
  }

  void _handlePay() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _isSuccess = true;
    });
    widget.onPaymentSuccess();
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pembayaran Berhasil!',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Total ${_formatCurrency(widget.totalAmount)} telah diterima.',
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: AppStyles.outlinedButtonStyle(),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.receipt_long_rounded,
                      size: 20,
                    ),
                    label: const Text('Cetak Struk'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: AppStyles.primaryButtonStyle(),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Selesai'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pembayaran',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                _formatCurrency(widget.totalAmount),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Method Selector
          const Text(
            'Metode Pembayaran',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              _buildMethodCard(0, 'Tunai', Icons.money_rounded),
              const SizedBox(width: 8),
              _buildMethodCard(1, 'QRIS', Icons.qr_code_2_rounded),
              const SizedBox(width: 8),
              _buildMethodCard(2, 'Transfer', Icons.account_balance_rounded),
            ],
          ),
          const SizedBox(height: 24),

          // Pay Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: AppStyles.primaryButtonStyle(),
              onPressed: _isProcessing ? null : _handlePay,
              child: _isProcessing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Konfirmasi Bayar (${_formatCurrency(widget.totalAmount)})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard(int index, String label, IconData icon) {
    final isSelected = _selectedMethod == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedMethod = index),
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : AppColors.background,
            borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.6 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
