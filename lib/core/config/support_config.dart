/// Contact address for corrections / removal requests, set at build time:
///   --dart-define=SUPPORT_EMAIL=support@example.com
/// Without a valid address nothing mail-related is shown.
class SupportConfig {
  const SupportConfig._();

  static const _email = String.fromEnvironment('SUPPORT_EMAIL');

  static String? get email {
    final value = _email.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value) ? value : null;
  }

  /// mailto: link; the subject is percent-encoded (spaces as %20, which every
  /// mail client reads correctly).
  static Uri? mailto({String? subject}) {
    final address = email;
    if (address == null) return null;
    return Uri(
      scheme: 'mailto',
      path: address,
      query: subject == null ? null : 'subject=${Uri.encodeComponent(subject)}',
    );
  }
}
