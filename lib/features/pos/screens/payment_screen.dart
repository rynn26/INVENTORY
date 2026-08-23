import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/services/transaction_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/cart_item.dart';
import 'transaction_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  final int totalAmount;
  final List<CartItem> cartItems;

  const PaymentScreen({
    super.key,
    required this.totalAmount,
    required this.cartItems,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _selectedMethod = 0; // 0: Tunai, 1: QRIS, 2: Transfer
  final TextEditingController _cashController = TextEditingController();
  int _cashReceived = 20000;

  @override
  void initState() {
    super.initState();
    if (widget.totalAmount <= 20000) {
      _cashReceived = 20000;
    } else if (widget.totalAmount <= 50000) {
      _cashReceived = 50000;
    } else {
      _cashReceived = widget.totalAmount;
    }
    _cashController.text = _formatNumber(_cashReceived);
  }

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  String _formatNumber(int amount) {
    return CurrencyFormatter.format(amount, withSymbol: false);
  }

  String _formatCurrency(int amount) {
    return CurrencyFormatter.format(amount);
  }

  int get _changeAmount {
    if (_selectedMethod != 0) return 0;
    final change = _cashReceived - widget.totalAmount;
    return change >= 0 ? change : 0;
  }

  bool get _isPaymentValid {
    if (_selectedMethod != 0) return true;
    return _cashReceived >= widget.totalAmount;
  }

  void _onSelectQuickCash(int amount) {
    setState(() {
      _cashReceived = amount;
      _cashController.text = _formatNumber(amount);
    });
  }

  void _onCashChanged(String value) {
    final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    final parsed = int.tryParse(cleanValue) ?? 0;
    setState(() {
      _cashReceived = parsed;
    });
  }

  void _completeTransaction() {
    if (!_isPaymentValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          content: Text('Uang yang diterima kurang dari total tagihan!'),
        ),
      );
      return;
    }

    _saveAndNavigate();
  }

  Future<void> _saveAndNavigate() async {
    final paymentMethodStr = _selectedMethod == 0
        ? 'tunai'
        : (_selectedMethod == 1 ? 'qris' : 'transfer');

    String transactionId;
    try {
      final result = await TransactionService.createTransaction(
        items: widget.cartItems,
        totalAmount: widget.totalAmount,
        amountPaid: _selectedMethod == 0 ? _cashReceived : widget.totalAmount,
        paymentMethod: paymentMethodStr,
      );
      transactionId = result.receiptNumber;
    } catch (_) {
      // Fallback: tetap lanjut meski Supabase error
      transactionId =
          'TRX-${DateFormat('yyyyMMdd').format(DateTime.now())}-${DateTime.now().millisecondsSinceEpoch % 10000}';
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionSuccessScreen(
          transactionId: transactionId,
          totalAmount: widget.totalAmount,
          cashReceived:
              _selectedMethod == 0 ? _cashReceived : widget.totalAmount,
          changeAmount: _changeAmount,
          paymentMethod: _selectedMethod == 0
              ? 'Tunai'
              : (_selectedMethod == 1 ? 'QRIS' : 'Transfer Bank'),
          cartItems: widget.cartItems,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.primary,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pembayaran',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: 18.5,
            letterSpacing: -0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppColors.divider,
            height: 1.0,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total Tagihan Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    decoration: AppStyles.cardDecoration(),
                    child: Column(
                      children: [
                        const Text(
                          'Total Tagihan',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatCurrency(widget.totalAmount),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Metode Pembayaran Section
                  const Text(
                    'Metode Pembayaran',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3 Payment Method Cards
                  Row(
                    children: [
                      _buildMethodCard(
                        index: 0,
                        title: 'Tunai',
                        icon: Icons.payments_rounded,
                      ),
                      const SizedBox(width: 10),
                      _buildMethodCard(
                        index: 1,
                        title: 'QRIS',
                        icon: Icons.qr_code_2_rounded,
                      ),
                      const SizedBox(width: 10),
                      _buildMethodCard(
                        index: 2,
                        title: 'Transfer',
                        icon: Icons.account_balance_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Cash Received Section (Only if Tunai)
                  if (_selectedMethod == 0) ...[
                    const Text(
                      'Uang Diterima',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Input Field with clear button
                    Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppStyles.radiusMedium),
                        border: Border.all(
                          color: _isPaymentValid
                              ? AppColors.border
                              : AppColors.danger,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'Rp ',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _cashController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [RupiahInputFormatter()],
                              onChanged: _onCashChanged,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          if (_cashController.text.isNotEmpty)
                            InkWell(
                              onTap: () {
                                _cashController.clear();
                                setState(() => _cashReceived = 0);
                              },
                              child: const Icon(
                                Icons.cancel_rounded,
                                color: AppColors.textMuted,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick Suggestion Chips (Pas, 20.000, 50.000, 100.000)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildQuickChip('Pas', widget.totalAmount),
                        _buildQuickChip('20.000', 20000),
                        _buildQuickChip('50.000', 50000),
                        _buildQuickChip('100.000', 100000),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Kembalian Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius:
                            BorderRadius.circular(AppStyles.radiusMedium),
                        border: Border.all(
                          color: AppColors.primaryTint,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Kembalian',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            _formatCurrency(_changeAmount),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // QRIS / Transfer instruction placeholder card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: AppStyles.cardDecoration(),
                      child: Column(
                        children: [
                          Icon(
                            _selectedMethod == 1
                                ? Icons.qr_code_scanner_rounded
                                : Icons.account_balance_rounded,
                            size: 48,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedMethod == 1
                                ? 'Scan QRIS Kasir untuk Membayar'
                                : 'Transfer ke Rekening Toko',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _selectedMethod == 1
                                ? 'Pelanggan memindai QR dinamis sebesar ${_formatCurrency(widget.totalAmount)}'
                                : 'BCA: 8820-1928-11 a/n TitipKasir',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom Selesaikan Transaksi Button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: const Border(
                top: BorderSide(
                  color: AppColors.divider,
                  width: 1.2,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: AppStyles.primaryButtonStyle(
                  radius: AppStyles.radiusMedium,
                ),
                onPressed: _completeTransaction,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Selesaikan Transaksi',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard({
    required int index,
    required String title,
    required IconData icon,
  }) {
    final isSelected = _selectedMethod == index;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedMethod = index),
        borderRadius: BorderRadius.circular(AppStyles.radiusCard),
        child: Container(
          height: 100,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : AppColors.surface,
            borderRadius: BorderRadius.circular(AppStyles.radiusCard),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.6 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 26,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
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

  Widget _buildQuickChip(String label, int value) {
    final isSelected = _cashReceived == value;

    return InkWell(
      onTap: () => _onSelectQuickCash(value),
      borderRadius: BorderRadius.circular(AppStyles.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(AppStyles.radiusPill),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
