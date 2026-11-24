/// Public download link added to shared travel cards.
///
/// Provide it at build time, for example:
///   --dart-define=APP_SHARE_URL=https://example.com/get-edible
///
/// Without a valid https URL nothing is appended, so a card never carries a
/// dead or placeholder link.
class ShareConfig {
  const ShareConfig._();

  static const _appShareUrl = String.fromEnvironment('APP_SHARE_URL');

  static String? get appShareUrl {
    final uri = Uri.tryParse(_appShareUrl.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
    return uri.toString();
  }
}
