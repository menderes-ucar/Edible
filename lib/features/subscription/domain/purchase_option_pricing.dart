import 'entities/purchase_option.dart';

/// A free trial length derived from an ISO-8601 duration such as "P7D" or "P1M".
class TrialLength {
  const TrialLength({this.days, this.months});

  final int? days;
  final int? months;
}

/// Parses the subset of ISO-8601 durations stores use for introductory offers.
/// Returns null for anything that is not a clean number of days or months, so
/// the paywall simply shows no trial badge instead of a wrong one.
TrialLength? parseTrialPeriod(String? iso, {int cycles = 1}) {
  if (iso == null) return null;
  final match = RegExp(r'^P(?:(\d+)Y)?(?:(\d+)M)?(?:(\d+)W)?(?:(\d+)D)?$')
      .firstMatch(iso.trim().toUpperCase());
  if (match == null) return null;

  int part(int group) => int.tryParse(match.group(group) ?? '') ?? 0;

  final repeat = cycles < 1 ? 1 : cycles;
  final days = (part(3) * 7 + part(4)) * repeat;
  final months = (part(1) * 12 + part(2)) * repeat;

  if (days > 0 && months == 0) return TrialLength(days: days);
  if (months > 0 && days == 0) return TrialLength(months: months);
  return null;
}

/// Adds `savingsPercent` to the annual plan when a monthly plan in the same
/// currency exists. Savings below 5% are not advertised.
List<PurchaseOption> withAnnualSavings(List<PurchaseOption> options) {
  PurchaseOption? monthly;
  for (final option in options) {
    if (option.period == PurchasePeriod.monthly && option.price > 0) {
      monthly = option;
      break;
    }
  }
  if (monthly == null) return options;
  final monthlyOption = monthly;

  return [
    for (final option in options)
      if (option.period == PurchasePeriod.annual &&
          option.price > 0 &&
          option.currencyCode == monthlyOption.currencyCode &&
          _savingsPercent(option.price, monthlyOption.price) >= 5)
        option.copyWith(
          savingsPercent: _savingsPercent(option.price, monthlyOption.price),
        )
      else
        option,
  ];
}

int _savingsPercent(double annualPrice, double monthlyPrice) {
  final yearAtMonthlyRate = monthlyPrice * 12;
  if (yearAtMonthlyRate <= 0) return 0;
  return ((1 - annualPrice / yearAtMonthlyRate) * 100).round();
}
