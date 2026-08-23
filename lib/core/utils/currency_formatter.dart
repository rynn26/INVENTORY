import 'package:flutter/services.dart';

/// Utility terpadu untuk pemformatan mata uang Rupiah dengan pemisah ribuan titik (.)
/// Contoh: 20000 -> "Rp 20.000" atau "20.000"
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Format angka integer/double menjadi string Rupiah bertitik
  /// [withSymbol] = true -> "Rp 20.000"
  /// [withSymbol] = false -> "20.000"
  /// [withSpace] = true -> "Rp 20.000" (ada spasi setelah Rp)
  static String format(
    num? amount, {
    bool withSymbol = true,
    bool withSpace = true,
  }) {
    if (amount == null) {
      if (!withSymbol) return '0';
      return withSpace ? 'Rp 0' : 'Rp0';
    }

    final int value = amount.round();
    final bool isNegative = value < 0;
    final String absoluteStr = value.abs().toString();

    // Tambahkan titik setiap 3 digit dari belakang
    final formatted = absoluteStr.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );

    final sign = isNegative ? '-' : '';

    if (!withSymbol) {
      return '$sign$formatted';
    }

    return withSpace ? '${sign}Rp $formatted' : '${sign}Rp$formatted';
  }

  /// Membaca string yang mungkin berisi format "Rp 20.000" atau "20.000" menjadi integer murni (20000)
  static int parse(dynamic input) {
    if (input == null) return 0;
    if (input is num) return input.round();
    final str = input.toString().trim();
    if (str.isEmpty) return 0;

    final isNegative = str.startsWith('-');
    // Hapus semua karakter non-angka
    final digitsOnly = str.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) return 0;

    final val = int.tryParse(digitsOnly) ?? 0;
    return isNegative ? -val : val;
  }
}

/// TextInputFormatter otomatis untuk TextFormField
/// Otomatis menambahkan titik pemisah ribuan saat pengguna mengetik nominal Rupiah
class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Hapus karakter non digit
    final cleanDigits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanDigits.isEmpty) {
      return newValue.copyWith(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    final numVal = int.tryParse(cleanDigits) ?? 0;
    final formatted = CurrencyFormatter.format(numVal, withSymbol: false);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
