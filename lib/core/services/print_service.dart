import 'dart:typed_data';
import 'package:barcode/barcode.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../utils/currency_formatter.dart';

class PrintService {
  // ============================================================
  // HELPER
  // ============================================================
  static String _formatCurrency(int amount) {
    return CurrencyFormatter.format(amount);
  }

  // ============================================================
  // CETAK LABEL BARCODE 33x15mm
  // ============================================================
  static final PdfPageFormat _labelFormat = PdfPageFormat(
    33.0 * PdfPageFormat.mm,
    15.0 * PdfPageFormat.mm,
    marginAll: 0,
  );

  /// Cetak label barcode 33x15mm ke thermal printer via Android print dialog.
  static Future<void> printBarcodeLabels({
    required String productName,
    required String penitipName,
    required int price,
    required String barcodeCode,
    required String expiryDate,
    required int quantity,
  }) async {
    await Printing.layoutPdf(
      name: 'Barcode_$productName',
      format: _labelFormat,
      onLayout: (format) => _buildLabelPdf(
        productName: productName,
        penitipName: penitipName,
        price: price,
        barcodeCode: barcodeCode,
        expiryDate: expiryDate,
        quantity: quantity,
        format: format,
      ),
    );
  }

  static Future<Uint8List> _buildLabelPdf({
    required String productName,
    required String penitipName,
    required int price,
    required String barcodeCode,
    required String expiryDate,
    required int quantity,
    required PdfPageFormat format,
  }) async {
    final pdf = pw.Document();

    final barcodeSvg = Barcode.code128().toSvg(
      barcodeCode,
      width: 29.0 * PdfPageFormat.mm,
      height: 5.5 * PdfPageFormat.mm,
      drawText: false,
    );

    for (int i = 0; i < quantity; i++) {
      pdf.addPage(
        pw.Page(
          pageFormat: format,
          margin: pw.EdgeInsets.symmetric(
            horizontal: 1.5 * PdfPageFormat.mm,
            vertical: 1.0 * PdfPageFormat.mm,
          ),
          build: (ctx) => _buildLabelWidget(
            productName: productName,
            penitipName: penitipName,
            price: price,
            barcodeCode: barcodeCode,
            expiryDate: expiryDate,
            barcodeSvg: barcodeSvg,
          ),
        ),
      );
    }

    return pdf.save();
  }

  static pw.Widget _buildLabelWidget({
    required String productName,
    required String penitipName,
    required int price,
    required String barcodeCode,
    required String expiryDate,
    required String barcodeSvg,
  }) {
    final titleStyle = pw.TextStyle(fontSize: 5.5, fontWeight: pw.FontWeight.bold);
    final subStyle = pw.TextStyle(fontSize: 4.2);
    final priceStyle = pw.TextStyle(fontSize: 7.0, fontWeight: pw.FontWeight.bold);
    final codeStyle = pw.TextStyle(fontSize: 3.8);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('TITIPKASIR',
                style: pw.TextStyle(
                    fontSize: 4.8,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.5)),
            pw.Text(penitipName, style: subStyle),
          ],
        ),
        pw.Center(
          child: pw.Text(productName,
              maxLines: 1, style: titleStyle, textAlign: pw.TextAlign.center),
        ),
        pw.SvgImage(svg: barcodeSvg, fit: pw.BoxFit.fitWidth),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(barcodeCode, style: codeStyle),
            pw.Text('Exp: $expiryDate', style: codeStyle),
          ],
        ),
        pw.Container(
          alignment: pw.Alignment.center,
          padding: pw.EdgeInsets.symmetric(vertical: 0.5),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            borderRadius: pw.BorderRadius.circular(1),
          ),
          child: pw.Text(_formatCurrency(price), style: priceStyle),
        ),
      ],
    );
  }

  // ============================================================
  // CETAK NOTA / STRUK (lebar 58mm — standar thermal printer)
  // ============================================================
  static final PdfPageFormat _receiptFormat = PdfPageFormat(
    58.0 * PdfPageFormat.mm,
    double.infinity, // tinggi dinamis sesuai isi struk
    marginAll: 0,
  );

  /// Cetak struk transaksi ke thermal printer via Android print dialog.
  /// Kompatibel semua merk printer China (PANDA, NIIMBOT, MUNBYN, HPRT, dll).
  static Future<void> printReceipt({
    required String receiptNumber,
    required String dateTime,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
    required int totalAmount,
    required int cashReceived,
    required int changeAmount,
  }) async {
    await Printing.layoutPdf(
      name: 'Struk_$receiptNumber',
      format: _receiptFormat,
      onLayout: (format) => _buildReceiptPdf(
        receiptNumber: receiptNumber,
        dateTime: dateTime,
        paymentMethod: paymentMethod,
        items: items,
        totalAmount: totalAmount,
        cashReceived: cashReceived,
        changeAmount: changeAmount,
        format: format,
      ),
    );
  }

  static Future<Uint8List> _buildReceiptPdf({
    required String receiptNumber,
    required String dateTime,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
    required int totalAmount,
    required int cashReceived,
    required int changeAmount,
    required PdfPageFormat format,
  }) async {
    final pdf = pw.Document();
    final boldStyle = pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold);
    final normalStyle = pw.TextStyle(fontSize: 7.5);
    final smallStyle = pw.TextStyle(fontSize: 7);
    final divider = pw.Divider(thickness: 0.5, color: PdfColors.grey500);

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.symmetric(
          horizontal: 3 * PdfPageFormat.mm,
          vertical: 4 * PdfPageFormat.mm,
        ),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Header
            pw.Center(
              child: pw.Text(
                'TITIPKASIR',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Center(
              child: pw.Text(
                'Kasir & Konsinyasi Makanan Titipan',
                style: smallStyle,
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 5),
            divider,
            pw.SizedBox(height: 3),

            // Info transaksi
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('No. Struk', style: normalStyle),
                pw.Text(
                  receiptNumber.length > 18
                      ? receiptNumber.substring(receiptNumber.length - 14)
                      : receiptNumber,
                  style: boldStyle,
                ),
              ],
            ),
            pw.SizedBox(height: 2),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Tanggal', style: normalStyle),
                pw.Text(dateTime, style: normalStyle),
              ],
            ),
            pw.SizedBox(height: 2),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Metode', style: normalStyle),
                pw.Text(paymentMethod.toUpperCase(), style: boldStyle),
              ],
            ),
            pw.SizedBox(height: 3),
            divider,
            pw.SizedBox(height: 3),

            // Items
            ...items.map((item) {
              final name = (item['name'] as String? ?? '').trim();
              final qty = item['qty'] as int? ?? 1;
              final price = item['price'] as int? ?? 0;
              final subtotal = qty * price;
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(name, style: boldStyle),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('  $qty x ${_formatCurrency(price)}',
                            style: normalStyle),
                        pw.Text(_formatCurrency(subtotal), style: normalStyle),
                      ],
                    ),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 3),
            divider,
            pw.SizedBox(height: 3),

            // Total
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL',
                    style: pw.TextStyle(
                        fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.Text(_formatCurrency(totalAmount),
                    style: pw.TextStyle(
                        fontSize: 9, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 2),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Bayar (${paymentMethod.toUpperCase()})',
                    style: normalStyle),
                pw.Text(_formatCurrency(cashReceived), style: normalStyle),
              ],
            ),
            pw.SizedBox(height: 2),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Kembali', style: boldStyle),
                pw.Text(_formatCurrency(changeAmount), style: boldStyle),
              ],
            ),
            pw.SizedBox(height: 3),
            divider,
            pw.SizedBox(height: 4),

            // Footer
            pw.Center(
              child: pw.Text(
                'Terima kasih atas kunjungan Anda!',
                style: smallStyle,
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Center(
              child: pw.Text(
                'Barang yang sudah dibeli tidak dapat ditukar.',
                style: smallStyle,
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }
}
