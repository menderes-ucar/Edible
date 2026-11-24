/// Converts using rates quoted as "units of currency per 1 USD".
/// Returns null when either currency has no rate.
double? convertAmount({
  required double amount,
  required String from,
  required String to,
  required Map<String, double> usdRates,
}) {
  final fromRate = usdRates[from];
  final toRate = usdRates[to];
  if (fromRate == null || toRate == null || fromRate <= 0 || toRate <= 0) {
    return null;
  }
  return amount / fromRate * toRate;
}

/// Parses what people type into a price field: "12,5", "1.234,56", "1,234.56",
/// "1 000". Returns null for anything that is not a non-negative number.
double? parseAmount(String input) {
  var text = input.trim().replaceAll(RegExp(r'[\s\u00A0\u202F]'), '');
  if (text.isEmpty) return null;

  final hasComma = text.contains(',');
  final hasDot = text.contains('.');

  if (hasComma && hasDot) {
    // The separator that appears last is the decimal one.
    final decimalIsComma = text.lastIndexOf(',') > text.lastIndexOf('.');
    text = decimalIsComma
        ? text.replaceAll('.', '').replaceAll(',', '.')
        : text.replaceAll(',', '');
  } else if (hasComma) {
    final thousands = RegExp(r'^\d{1,3}(,\d{3})+$').hasMatch(text);
    text = thousands ? text.replaceAll(',', '') : text.replaceAll(',', '.');
  } else if (hasDot) {
    final multipleDots = '.'.allMatches(text).length > 1;
    if (multipleDots) text = text.replaceAll('.', '');
  }

  final value = double.tryParse(text);
  if (value == null || value.isNaN || value.isInfinite || value < 0) return null;
  return value;
}

String formatMoney(double value, int decimals) {
  final fixed = value.toStringAsFixed(decimals);
  final parts = fixed.split('.');
  final digits = parts.first;
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return parts.length > 1 ? '$buffer.${parts[1]}' : buffer.toString();
}
