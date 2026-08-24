import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../utils/currency_formatter.dart';

class BluetoothPrinterService {
  static BluetoothInfo? selectedDevice;
  static bool _isConnected = false;

  static bool get isConnected => _isConnected;

  /// Lebar karakter standar thermal printer 58mm (Font A)
  static const int _lineWidth = 32;

  /// Helper: Buat baris dengan teks kiri dan kanan yang rapi pas 32 karakter
  static String _padBetween(String left, String right, {int width = _lineWidth}) {
    final totalLen = left.length + right.length;
    if (totalLen >= width) {
      // Jika kepanjangan, potong teks kiri sedikit
      final maxLeft = width - right.length - 1;
      if (maxLeft > 0 && left.length > maxLeft) {
        left = '${left.substring(0, maxLeft - 1)}.';
      }
    }
    final spaces = width - left.length - right.length;
    return '$left${' ' * (spaces > 0 ? spaces : 1)}$right';
  }

  /// Cek apakah Bluetooth di HP menyala
  static Future<bool> isBluetoothEnabled() async {
    try {
      return await PrintBluetoothThermal.bluetoothEnabled;
    } catch (_) {
      return false;
    }
  }

  /// Cek apakah permission Bluetooth sudah diizinkan
  static Future<bool> checkPermission() async {
    try {
      return await PrintBluetoothThermal.isPermissionBluetoothGranted;
    } catch (_) {
      return false;
    }
  }

  /// Mendapatkan daftar printer yang sudah di-pairing di HP
  static Future<List<BluetoothInfo>> getPairedDevices() async {
    try {
      final List<BluetoothInfo> list =
          await PrintBluetoothThermal.pairedBluetooths;
      return list;
    } catch (e) {
      return [];
    }
  }

  /// Cek status koneksi real-time ke printer
  static Future<bool> checkConnection() async {
    try {
      _isConnected = await PrintBluetoothThermal.connectionStatus;
      return _isConnected;
    } catch (_) {
      _isConnected = false;
      return false;
    }
  }

  /// Sambungkan ke printer dengan MAC address
  static Future<bool> connect(BluetoothInfo device) async {
    try {
      final bool result = await PrintBluetoothThermal.connect(
        macPrinterAddress: device.macAdress,
      );
      _isConnected = result;
      if (result) {
        selectedDevice = device;
      }
      return result;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  /// Putuskan koneksi dari printer
  static Future<bool> disconnect() async {
    try {
      final bool result = await PrintBluetoothThermal.disconnect;
      _isConnected = !result ? _isConnected : false;
      return result;
    } catch (e) {
      return false;
    }
  }

  /// Tes Print Singkat yang Rapi
  static Future<bool> testPrint() async {
    final connected = await checkConnection();
    if (!connected) return false;

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      // Header
      bytes += generator.text(
        'TITIPKASIR',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
        ),
      );
      bytes += generator.text(
        'Kasir & Konsinyasi Makanan',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.text('================================');

      // Body Info
      bytes += generator.text(
        _padBetween('Status', 'TERHUBUNG'),
        styles: const PosStyles(bold: true),
      );
      bytes += generator.text(
        _padBetween('Printer', selectedDevice?.name ?? 'Thermal 58mm'),
      );
      bytes += generator.text('--------------------------------');
      bytes += generator.text(
        'Tes cetak printer berhasil!',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.text(
        'Format teks & margin siap dipakai',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.text('================================');

      bytes += generator.feed(2);
      bytes += generator.cut();

      final result = await PrintBluetoothThermal.writeBytes(bytes);
      return result;
    } catch (e) {
      return false;
    }
  }

  /// Cetak Struk Transaksi Kasir via ESC/POS 58mm (Format Rapi Standar Kasir)
  static Future<bool> printReceipt({
    required String receiptNumber,
    required String dateTime,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
    required int totalAmount,
    required int cashReceived,
    required int changeAmount,
  }) async {
    final connected = await checkConnection();
    if (!connected) return false;

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      // 1. Header Toko (Bersih & Elegan)
      bytes += generator.text(
        'TITIPKASIR',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
        ),
      );
      bytes += generator.text(
        'Kasir & Konsinyasi Makanan',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.text(
        'Titipan Terpercaya',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.text('================================');

      // 2. Info Transaksi (Format Rapi 32 Karakter)
      final cleanReceiptNo = receiptNumber.length > 18
          ? receiptNumber.substring(receiptNumber.length - 14)
          : receiptNumber;
      bytes += generator.text(_padBetween('No. Struk', cleanReceiptNo));
      bytes += generator.text(_padBetween('Tanggal', dateTime));
      bytes += generator.text(
        _padBetween('Metode', paymentMethod.toUpperCase()),
        styles: const PosStyles(bold: true),
      );
      bytes += generator.text('--------------------------------');

      // 3. Rincian Item Barang
      int totalQtyCount = 0;
      for (final item in items) {
        final name = (item['name'] as String? ?? '').trim();
        final qty = item['qty'] as int? ?? 1;
        final price = item['price'] as int? ?? 0;
        final subtotal = qty * price;
        totalQtyCount += qty;

        // Nama Barang (Baris 1)
        bytes += generator.text(
          name,
          styles: const PosStyles(bold: true),
        );

        // Qty x Harga ....... Subtotal (Baris 2, Rata Kanan-Kiri Sempurna)
        final qtyPriceText = '  $qty x ${CurrencyFormatter.format(price)}';
        final subtotalText = CurrencyFormatter.format(subtotal);
        bytes += generator.text(_padBetween(qtyPriceText, subtotalText));
      }

      bytes += generator.text('--------------------------------');

      // 4. Ringkasan Total & Pembayaran
      bytes += generator.text(
        _padBetween('Total Item', '$totalQtyCount pcs'),
      );
      bytes += generator.text(
        _padBetween('TOTAL', CurrencyFormatter.format(totalAmount)),
        styles: const PosStyles(
          bold: true,
          height: PosTextSize.size1,
        ),
      );
      bytes += generator.text(
        _padBetween('Bayar (${paymentMethod.toUpperCase()})',
            CurrencyFormatter.format(cashReceived)),
      );
      bytes += generator.text(
        _padBetween('Kembalian', CurrencyFormatter.format(changeAmount)),
        styles: const PosStyles(bold: true),
      );

      bytes += generator.text('================================');

      // 5. Footer Ucapan
      bytes += generator.text(
        'Terima Kasih Atas Kunjungan Anda!',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.text(
        'Barang yang sudah dibeli',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.text(
        'tidak dapat ditukar/dikembalikan.',
        styles: const PosStyles(align: PosAlign.center),
      );

      // Jarak kertas & potong
      bytes += generator.feed(2);
      bytes += generator.cut();

      final result = await PrintBluetoothThermal.writeBytes(bytes);
      return result;
    } catch (e) {
      return false;
    }
  }

  /// Cetak Label Barcode Produk langsung ke Bluetooth Thermal Printer
  static Future<bool> printBarcodeLabels({
    required String productName,
    required String penitipName,
    required int price,
    required String barcodeCode,
    required String expiryDate,
    required int quantity,
  }) async {
    final connected = await checkConnection();
    if (!connected) return false;

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      for (int i = 0; i < quantity; i++) {
        bytes += generator.text(
          'TITIPKASIR',
          styles: const PosStyles(align: PosAlign.center, bold: true),
        );
        bytes += generator.text(
          productName,
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
          ),
        );
        // Hanya tampilkan nama penitip jika ada (produk sendiri = tidak perlu dicetak)
        if (penitipName.isNotEmpty) {
          bytes += generator.text(
            penitipName,
            styles: const PosStyles(align: PosAlign.center),
          );
        }

        // Barcode Hardware ESC/POS
        try {
          bytes += generator.barcode(
            Barcode.code128(barcodeCode.codeUnits),
            width: 2,
            height: 50,
            font: BarcodeFont.fontA,
            textPos: BarcodeText.below,
            align: PosAlign.center,
          );
        } catch (_) {
          bytes += generator.text(
            '* $barcodeCode *',
            styles: const PosStyles(align: PosAlign.center, bold: true),
          );
        }

        bytes += generator.text(
          _padBetween(
            expiryDate.isNotEmpty ? 'Exp: $expiryDate' : '',
            CurrencyFormatter.format(price),
          ),
          styles: const PosStyles(bold: true),
        );
        bytes += generator.text('--------------------------------');

        if (i < quantity - 1) {
          bytes += generator.feed(1);
        }
      }

      bytes += generator.feed(2);
      bytes += generator.cut();

      final result = await PrintBluetoothThermal.writeBytes(bytes);
      return result;
    } catch (e) {
      return false;
    }
  }
}
