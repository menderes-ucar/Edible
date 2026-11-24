enum PurchasePeriod { weekly, monthly, annual, other }

class PurchaseOption {
  const PurchaseOption({
    required this.id,
    required this.title,
    required this.description,
    required this.priceText,
    required this.packageIdentifier,
    this.period = PurchasePeriod.other,
    this.price = 0,
    this.currencyCode,
    this.trialDays,
    this.trialMonths,
    this.savingsPercent,
  });

  final String id;
  final String title;
  final String description;
  final String priceText;
  final String packageIdentifier;

  /// Billing period, taken from the store package type.
  final PurchasePeriod period;

  /// Numeric price in [currencyCode] (0 when unknown).
  final double price;
  final String? currencyCode;

  /// Free introductory period configured in the store (new subscribers only).
  /// Exactly one of these is set, or neither when there is no free trial.
  final int? trialDays;
  final int? trialMonths;

  /// Saving of this plan versus paying monthly for a year (annual plans only).
  final int? savingsPercent;

  bool get hasFreeTrial => trialDays != null || trialMonths != null;

  /// Monthly-equivalent price of an annual plan (null for other plans).
  double? get monthlyEquivalent =>
      period == PurchasePeriod.annual && price > 0 ? price / 12 : null;

  PurchaseOption copyWith({int? savingsPercent}) {
    return PurchaseOption(
      id: id,
      title: title,
      description: description,
      priceText: priceText,
      packageIdentifier: packageIdentifier,
      period: period,
      price: price,
      currencyCode: currencyCode,
      trialDays: trialDays,
      trialMonths: trialMonths,
      savingsPercent: savingsPercent ?? this.savingsPercent,
    );
  }
}
