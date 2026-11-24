import 'dart:io';

/// Public legal URLs shown in the paywall and profile.
///
/// Provide them at build time, for example:
///   --dart-define=PRIVACY_POLICY_URL=https://example.com/privacy
///   --dart-define=TERMS_OF_USE_URL=https://example.com/terms
///
/// A link that is not configured is simply not shown (nothing broken is
/// rendered). On iOS, Terms of Use falls back to Apple's standard EULA, which
/// is valid for auto-renewing subscriptions when you have no custom EULA.
class LegalConfig {
  const LegalConfig._();

  static const privacyPolicyUrl = String.fromEnvironment('PRIVACY_POLICY_URL');
  static const _termsOfUseUrl = String.fromEnvironment('TERMS_OF_USE_URL');

  static const _appleStandardEula =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

  static String get termsOfUseUrl {
    final configured = _termsOfUseUrl.trim();
    if (configured.isNotEmpty) return configured;
    if (Platform.isIOS) return _appleStandardEula;
    return '';
  }

  static bool get hasPrivacyPolicy => _isHttps(privacyPolicyUrl);
  static bool get hasTermsOfUse => _isHttps(termsOfUseUrl);
  static bool get hasAny => hasPrivacyPolicy || hasTermsOfUse;

  static bool _isHttps(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
  }
}
