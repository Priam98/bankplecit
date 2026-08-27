import 'package:flutter/services.dart';

/// Format angka ke string rupiah tanpa prefix "Rp " (contoh: 1500000 → "1.500.000").
String formatRupiah(num value, {bool withSymbol = false}) {
  final isNegative = value < 0;
  final absValue = value.abs();
  final text = absValue.toStringAsFixed(0);
  final buffer = StringBuffer();

  for (var i = 0; i < text.length; i++) {
    final positionFromEnd = text.length - i;
    buffer.write(text[i]);
    if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
      buffer.write('.');
    }
  }

  final formatted = buffer.toString();
  final withSign = isNegative ? '-$formatted' : formatted;
  return withSymbol ? 'Rp $withSign' : withSign;
}

/// Parse string input (bisa berisi titik pemisah ribuan) ke double.
double? parseRupiah(String input) {
  final cleaned = input.replaceAll(RegExp(r'[^0-9]'), '');
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}

/// TextInputFormatter yang memformat input nominal dengan titik ribuan.
class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Hindari leading zeros berlebih, kecuali nilai 0.
    final normalized = digitsOnly.replaceFirst(RegExp(r'^0+(?=.)'), '');
    final formatted = formatRupiah(int.parse(normalized));

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
