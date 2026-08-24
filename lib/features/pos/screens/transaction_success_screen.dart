import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/services/bluetooth_printer_service.dart';
import '../../../core/services/print_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/cart_item.dart';
import '../../../shared/widgets/bluetooth_printer_modal.dart';

class TransactionSuccessScreen extends StatelessWidget {
  final String transactionId;
  final int totalAmount;
  final int cashReceived;
  final int changeAmount;
  final String paymentMethod;
  final List<CartItem> cartItems;

  const TransactionSuccessScreen({
    super.key,
    required this.transactionId,
    required this.totalAmount,
    required this.cashReceived,
    required this.changeAmount,
    required this.paymentMethod,
    required this.cartItems,
  });

  String _formatCurrency(int amount) {
    return CurrencyFormatter.format(amount);
  }

  /// Eksekusi Cetak Struk Langsung ke Bluetooth Thermal Printer
  Future<void> _directPrintReceipt(BuildContext context) async {
    final isConnected = await BluetoothPrinterService.checkConnection();

    if (!isConnected) {
      if (!context.mounted) return;
      // Belum terhubung -> Buka Modal Pilih & Sambungkan Bluetooth
      final connected = await BluetoothPrinterModal.show(
        context,
        onConnected: () {
          // Begitu terhubung, langsung otomatis cetak
          _executeDirectPrint(context);
        },
      );
      if (connected == true && context.mounted) {
        await _executeDirectPrint(context);
      }
      return;
    }

    if (context.mounted) {
      await _executeDirectPrint(context);
    }
  }

  Future<void> _executeDirectPrint(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.primary,
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Mengirim struk ke printer thermal...'),
          ],
        ),
      ),
    );

    final success = await BluetoothPrinterService.printReceipt(
      receiptNumber: transactionId,
      dateTime: DateFormatter.formatFullDate(DateTime.now()),
      paymentMethod: paymentMethod,
      items: cartItems
          .map((e) => {
                'name': e.name,
                'qty': e.quantity,
                'price': e.price,
              })
          .toList(),
      totalAmount: totalAmount,
      cashReceived: cashReceived,
      changeAmount: changeAmount,
    );

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Struk berhasil dicetak ke printer thermal!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: const Text(
            'Gagal mencetak struk. Pastikan printer Bluetooth menyala dan tersambung.',
          ),
          action: SnackBarAction(
            label: 'Sambungkan',
            textColor: Colors.white,
            onPressed: () => BluetoothPrinterModal.show(context),
          ),
        ),
      );
    }
  }

  /// Cetak via Print Spooler / PDF Sistem (Fallback)
  Future<void> _systemPdfPrint() async {
    await PrintService.printReceipt(
      receiptNumber: transactionId,
      dateTime: DateFormatter.formatFullDate(DateTime.now()),
      paymentMethod: paymentMethod,
      items: cartItems
          .map((e) => {
                'name': e.name,
                'qty': e.quantity,
                'price': e.price,
              })
          .toList(),
      totalAmount: totalAmount,
      cashReceived: cashReceived,
      changeAmount: changeAmount,
    );
  }

  void _showPrintReceiptModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Pratinjau Struk Kasir',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Simulated Paper Struk
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Text(
                    'TITIPKASIR',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 1.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Kasir & Konsinyasi Makanan Titipan',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(thickness: 1, height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        transactionId,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(thickness: 1, height: 1),
                  const SizedBox(height: 8),

                  // Cart Items
                  ...cartItems.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.penitipName != null &&
                                        item.penitipName!.isNotEmpty
                                    ? '${item.name} (${item.penitipName}) x${item.quantity}'
                                    : '${item.name} (${item.quantity}x)',
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatCurrency(item.totalPrice),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )),

                  const SizedBox(height: 8),
                  const Divider(thickness: 1, height: 1),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        _formatCurrency(totalAmount),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bayar ($paymentMethod)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        _formatCurrency(cashReceived),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  if (changeAmount > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Kembalian',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          _formatCurrency(changeAmount),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Text(
                    'Terima Kasih Atas Kunjungan Anda!',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Direct Bluetooth Print Action
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: AppStyles.primaryButtonStyle(),
                onPressed: () {
                  Navigator.pop(ctx);
                  _directPrintReceipt(context);
                },
                icon: const Icon(Icons.print_rounded, size: 20),
                label: const Text('Cetak Langsung (Bluetooth Thermal)'),
              ),
            ),
            const SizedBox(height: 10),

            // System PDF Print Fallback
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                style: AppStyles.outlinedButtonStyle(),
                onPressed: () {
                  Navigator.pop(ctx);
                  _systemPdfPrint();
                },
                icon: const Icon(Icons.picture_as_pdf_rounded,
                    size: 18, color: AppColors.primary),
                label: const Text('Cetak via Dialog Sistem (PDF)'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nowFormatted = DateFormatter.formatFullDate(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(height: 12),

              // Success Circle Icon
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title & Date
              const Text(
                'Transaksi Berhasil',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                nowFormatted,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),

              // Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: AppStyles.cardDecoration(),
                child: Column(
                  children: [
                    // ID Transaksi
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ID Transaksi',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          transactionId,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(
                        height: 1,
                        color: AppColors.divider,
                      ),
                    ),

                    // Total Tagihan
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Tagihan',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _formatCurrency(totalAmount),
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Uang Diterima
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Uang Diterima',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _formatCurrency(cashReceived),
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Kembalian Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius:
                            BorderRadius.circular(AppStyles.radiusMedium),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Kembalian',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            _formatCurrency(changeAmount),
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Bluetooth Printer Status & Quick Connect Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      BluetoothPrinterService.isConnected
                          ? Icons.bluetooth_connected_rounded
                          : Icons.bluetooth_rounded,
                      color: BluetoothPrinterService.isConnected
                          ? AppColors.success
                          : AppColors.textSecondary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            BluetoothPrinterService.isConnected
                                ? 'Printer: ${BluetoothPrinterService.selectedDevice?.name ?? "Terhubung"}'
                                : 'Printer Bluetooth belum tersambung',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: BluetoothPrinterService.isConnected
                                  ? AppColors.success
                                  : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            BluetoothPrinterService.isConnected
                                ? 'Siap mencetak struk langsung (ESC/POS)'
                                : 'Ketuk untuk pilih & hubungkan printer',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => BluetoothPrinterModal.show(context),
                      child: Text(
                        BluetoothPrinterService.isConnected
                            ? 'Ganti'
                            : 'Pilih Printer',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Cetak Struk Langsung (Bluetooth Thermal)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: AppStyles.primaryButtonStyle(),
                  onPressed: () => _directPrintReceipt(context),
                  icon: const Icon(
                    Icons.print_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: const Text('Cetak Struk Thermal (Bluetooth)'),
                ),
              ),
              const SizedBox(height: 10),

              // Pratinjau & Pilihan Print
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  style: AppStyles.outlinedButtonStyle(),
                  onPressed: () => _showPrintReceiptModal(context),
                  icon: const Icon(
                    Icons.receipt_long_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  label: const Text('Pratinjau / Opsi Lain'),
                ),
              ),
              const SizedBox(height: 10),

              // Transaksi Baru Button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                  ),
                  label: const Text('Kembali ke Kasir (Transaksi Baru)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
