import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

import '../../../core/utils/currency_formatter.dart';

class BarcodeLabelSticker extends StatelessWidget {
  final String productName;
  final String penitipName;
  final int price;
  final String barcodeCode;
  final String expiryDate;
  final double width;
  final double height;
  final bool showBorder;

  const BarcodeLabelSticker({
    super.key,
    required this.productName,
    required this.penitipName,
    required this.price,
    required this.barcodeCode,
    required this.expiryDate,
    this.width = 220,
    this.height = 135,
    this.showBorder = true,
  });

  String _formatCurrency(int amount) {
    return CurrencyFormatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: showBorder
            ? Border.all(color: const Color(0xFFD1D5DB), width: 1.2)
            : null,
        boxShadow: showBorder
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.center,
          child: SizedBox(
            width: width - 20, // account for horizontal padding
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header: Brand & Penitip
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TITIPKASIR',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        penitipName.isEmpty ? 'Dagangan Sendiri' : penitipName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Product Name
                Text(
                  productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),

                // Barcode Lines Graphic (Custom Vector Painter)
                SizedBox(
                  height: 38,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: BarcodeGraphicPainter(code: barcodeCode),
                  ),
                ),
                const SizedBox(height: 4),

                // Barcode String & Expiry Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        barcodeCode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                          letterSpacing: 1.2,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    Text(
                      'Exp: $expiryDate',
                      style: const TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Price Tag Pill
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _formatCurrency(price),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BarcodeGraphicPainter extends CustomPainter {
  final String code;

  BarcodeGraphicPainter({required this.code});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // Deterministic line pattern generator based on barcode string hash
    final seed = code.hashCode.abs();
    final barCount = 42;
    final totalSpacing = size.width;
    final unitWidth = totalSpacing / barCount;

    double currentX = 0;
    for (int i = 0; i < barCount; i++) {
      final isBlack = ((seed >> (i % 31)) ^ (i * 7)) % 3 != 0;
      final isThick = ((seed >> ((i + 3) % 31)) + i) % 4 == 0;

      if (isBlack) {
        final barW = isThick ? unitWidth * 1.5 : unitWidth * 0.75;
        canvas.drawRect(
          Rect.fromLTWH(currentX, 0, barW, size.height),
          paint,
        );
      }
      currentX += unitWidth;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
