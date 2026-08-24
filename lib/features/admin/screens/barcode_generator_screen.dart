import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/services/bluetooth_printer_service.dart';
import '../../../core/services/print_service.dart';
import '../../../core/services/product_service.dart';
import '../../../models/product_item.dart';
import '../../../shared/widgets/bluetooth_printer_modal.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../widgets/barcode_label_sticker.dart';

class BarcodeGeneratorScreen extends StatefulWidget {
  const BarcodeGeneratorScreen({super.key});

  @override
  State<BarcodeGeneratorScreen> createState() => _BarcodeGeneratorScreenState();
}

class _BarcodeGeneratorScreenState extends State<BarcodeGeneratorScreen> {
  List<ProductItem> _productList = [];
  ProductItem? _selectedProduct;
  int _printQuantity = 10;
  String _selectedSize = '33 x 15 mm';
  String _expiryOption = 'Hari Ini';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final list = await ProductService.fetchAll();
      setState(() {
        _productList = list;
        if (list.isNotEmpty) _selectedProduct = list.first;
      });
    } catch (_) {
      // gagal load produk — tetap tampil kosong
    }
  }

  String get _computedExpiryDate {
    final now = DateTime.now();
    if (_expiryOption == 'Hari Ini') {
      return DateFormat('dd/MM/yyyy').format(now);
    } else if (_expiryOption == 'Besok') {
      return DateFormat('dd/MM/yyyy').format(now.add(const Duration(days: 1)));
    } else {
      return DateFormat('dd/MM/yyyy').format(now.add(const Duration(days: 3)));
    }
  }

  /// Eksekusi Cetak Barcode Langsung ke Bluetooth Thermal Printer
  Future<void> _directPrintBarcode(BuildContext context) async {
    if (_selectedProduct == null) return;

    final isConnected = await BluetoothPrinterService.checkConnection();

    if (!isConnected) {
      if (!context.mounted) return;
      final connected = await BluetoothPrinterModal.show(
        context,
        onConnected: () {
          _executeDirectPrintBarcode(context);
        },
      );
      if (connected == true && context.mounted) {
        await _executeDirectPrintBarcode(context);
      }
      return;
    }

    if (context.mounted) {
      await _executeDirectPrintBarcode(context);
    }
  }

  Future<void> _executeDirectPrintBarcode(BuildContext context) async {
    if (_selectedProduct == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primary,
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text('Mencetak $_printQuantity label barcode ke printer thermal...'),
          ],
        ),
      ),
    );

    final success = await BluetoothPrinterService.printBarcodeLabels(
      productName: _selectedProduct!.name,
      penitipName: _selectedProduct!.penitipName,
      price: _selectedProduct!.price,
      barcodeCode: _selectedProduct!.barcode ??
          _selectedProduct!.id.substring(0, 8).toUpperCase(),
      expiryDate: _computedExpiryDate,
      quantity: _printQuantity,
    );

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Berhasil mencetak $_printQuantity label barcode!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
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
            'Gagal mencetak barcode. Pastikan printer Bluetooth menyala & terhubung.',
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

  /// Cetak via Print Dialog Sistem / PDF
  Future<void> _systemPdfPrint() async {
    if (_selectedProduct == null) return;
    await PrintService.printBarcodeLabels(
      productName: _selectedProduct!.name,
      penitipName: _selectedProduct!.penitipName,
      price: _selectedProduct!.price,
      barcodeCode: _selectedProduct!.barcode ??
          _selectedProduct!.id.substring(0, 8).toUpperCase(),
      expiryDate: _computedExpiryDate,
      quantity: _printQuantity,
    );
  }

  void _showPrintSheetPreview() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pratinjau Lembar Sticker Barcode',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Siap cetak $_printQuantity pcs untuk ditempel ke produk',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sheet Grid Preview
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 33 / 15, // rasio 33x15mm
                  ),
                  itemCount: _printQuantity,
                  itemBuilder: (context, index) {
                    return FittedBox(
                      fit: BoxFit.contain,
                      child: BarcodeLabelSticker(
                        productName: _selectedProduct?.name ?? '',
                        penitipName: _selectedProduct?.penitipName ?? '',
                        price: _selectedProduct?.price ?? 0,
                        barcodeCode: _selectedProduct?.barcode ?? (_selectedProduct?.id.substring(0, 8).toUpperCase() ?? ''),
                        expiryDate: _computedExpiryDate,
                        showBorder: true,
                        width: 220,
                        height: 100, // proporsional 33x15
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Direct Bluetooth Print Action Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: AppStyles.primaryButtonStyle(),
                onPressed: _selectedProduct == null
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        _directPrintBarcode(context);
                      },
                icon: const Icon(Icons.print_rounded, color: Colors.white, size: 20),
                label: Text('Cetak Langsung ($_printQuantity Barcode Bluetooth)'),
              ),
            ),
            const SizedBox(height: 10),

            // Fallback System PDF Print Button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                style: AppStyles.outlinedButtonStyle(),
                onPressed: _selectedProduct == null
                    ? null
                    : () {
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Generate Barcode Produk',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: InkWell(
                onTap: () async {
                  await BluetoothPrinterModal.show(context);
                  setState(() {});
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: BluetoothPrinterService.isConnected
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.surfaceMuted,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: BluetoothPrinterService.isConnected
                          ? AppColors.success
                          : AppColors.border,
                      width: 1.2,
                    ),
                  ),
                  child: Icon(
                    BluetoothPrinterService.isConnected
                        ? Icons.print_rounded
                        : Icons.print_disabled_rounded,
                    color: BluetoothPrinterService.isConnected
                        ? AppColors.success
                        : AppColors.textSecondary,
                    size: 19,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: Colors.white,
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 500));
          if (!mounted) return;
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header Instruction Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                border: Border.all(color: AppColors.primaryTint, width: 1.2),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.qr_code_2_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cetak Sticker Barcode Makanan Titipan',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Tempelkan sticker barcode ini ke bungkusan makanan agar kasir bisa langsung memindainya saat transaksi.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF334155),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Live Sticker Preview Card
            const Text(
              'Pratinjau Sticker Barcode',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: BarcodeLabelSticker(
                productName: _selectedProduct?.name ?? '',
                penitipName: _selectedProduct?.penitipName ?? '',
                price: _selectedProduct?.price ?? 0,
                barcodeCode: _selectedProduct?.barcode ?? (_selectedProduct?.id.substring(0, 8).toUpperCase() ?? ''),
                expiryDate: _computedExpiryDate,
                width: 250,
                height: 115, // proporsional 33x15
              ),
            ),
            const SizedBox(height: 24),

            // Form Configuration Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: AppStyles.cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Pilih Produk
                  const Text(
                    'Pilih Produk Makanan',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius:
                          BorderRadius.circular(AppStyles.radiusMedium),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<ProductItem>(
                        value: _selectedProduct,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        items: _productList.map((prod) {
                          return DropdownMenuItem<ProductItem>(
                            value: prod,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          prod.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '(${prod.penitipName})',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Rp ${prod.price}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedProduct = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Tanggal Expired / Konsumsi
                  const Text(
                    'Batas Konsumsi / Expired',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ['Hari Ini', 'Besok', '+3 Hari'].map((opt) {
                      final isSelected = _expiryOption == opt;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: InkWell(
                            onTap: () => setState(() => _expiryOption = opt),
                            borderRadius:
                                BorderRadius.circular(AppStyles.radiusPill),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.background,
                                borderRadius:
                                    BorderRadius.circular(AppStyles.radiusPill),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.border,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                opt,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // 3. Jumlah Cetak Sticker
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jumlah Sticker Barcode',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Sesuaikan dengan jumlah fisik titipan',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius:
                              BorderRadius.circular(AppStyles.radiusMedium),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: const BorderRadius.horizontal(
                                    left: Radius.circular(8)),
                                onTap: () {
                                  if (_printQuantity > 1) {
                                    setState(() => _printQuantity -= 1);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _printQuantity > 1
                                        ? AppColors.primaryLight
                                        : Colors.grey.shade100,
                                    borderRadius: const BorderRadius.horizontal(
                                        left: Radius.circular(8)),
                                  ),
                                  child: Icon(
                                    Icons.remove_rounded,
                                    size: 18,
                                    color: _printQuantity > 1
                                        ? AppColors.primaryDark
                                        : Colors.grey.shade400,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              constraints: const BoxConstraints(minWidth: 38),
                              alignment: Alignment.center,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '$_printQuantity',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: const BorderRadius.horizontal(
                                    right: Radius.circular(8)),
                                onTap: () {
                                  setState(() => _printQuantity += 1);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.horizontal(
                                        right: Radius.circular(8)),
                                  ),
                                  child: const Icon(
                                    Icons.add_rounded,
                                    size: 18,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 4. Ukuran Kertas Sticker
                  const Text(
                    'Ukuran Kertas Label',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ['50 x 30 mm', '40 x 30 mm', 'A4 (Grid)'].map((sz) {
                      final isSelected = _selectedSize == sz;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: InkWell(
                            onTap: () => setState(() => _selectedSize = sz),
                            borderRadius:
                                BorderRadius.circular(AppStyles.radiusSmall),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryLight
                                    : AppColors.background,
                                borderRadius:
                                    BorderRadius.circular(AppStyles.radiusSmall),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.border,
                                  width: isSelected ? 1.4 : 1.0,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                sz,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

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
                              ? 'Siap mencetak barcode produk langsung'
                              : 'Ketuk untuk pilih & sambungkan printer',
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
                    onPressed: () async {
                      await BluetoothPrinterModal.show(context);
                      setState(() {});
                    },
                    child: Text(
                      BluetoothPrinterService.isConnected ? 'Ganti' : 'Pilih Printer',
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

            // Direct Bluetooth Print Barcode Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: AppStyles.primaryButtonStyle(),
                onPressed: _selectedProduct == null
                    ? null
                    : () => _directPrintBarcode(context),
                icon: const Icon(Icons.print_rounded,
                    color: Colors.white, size: 20),
                label: Text('Cetak $_printQuantity Barcode (Bluetooth Thermal)'),
              ),
            ),
            const SizedBox(height: 10),

            // Pratinjau Lembar Button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                style: AppStyles.outlinedButtonStyle(),
                onPressed: _showPrintSheetPreview,
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('Pratinjau Lembar / Opsi Cetak PDF'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      ),
    );
  }
}
