import 'dart:io';

class RevenueCatConfig {
  const RevenueCatConfig._();

  static const androidApiKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
  );

  static const iosApiKey = String.fromEnvironment(
    'REVENUECAT_IOS_API_KEY',
  );

  static const entitlementId = String.fromEnvironment(
    'REVENUECAT_ENTITLEMENT_ID',
    defaultValue: 'premium',
  );

  static String get apiKey {
    if (Platform.isAndroid) return androidApiKey;
    if (Platform.isIOS) return iosApiKey;
    return '';
  }

  static bool get isConfigured => apiKey.trim().isNotEmpty;
}
