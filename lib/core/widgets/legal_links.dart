import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/legal_config.dart';
import '../localization/app_localizations.dart';

/// Privacy Policy / Terms of Use links. Renders nothing when no URL is
/// configured, so it never shows a dead link.
class LegalLinks extends StatelessWidget {
  const LegalLinks({super.key, this.alignment = WrapAlignment.center});

  final WrapAlignment alignment;

  static Future<void> open(BuildContext context, String url) async {
    final uri = Uri.tryParse(url.trim());
    var opened = false;
    if (uri != null && uri.scheme == 'https') {
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        opened = false;
      }
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.text('legalLinkFailed'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!LegalConfig.hasAny) return const SizedBox.shrink();
    return Wrap(
      alignment: alignment,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (LegalConfig.hasPrivacyPolicy)
          TextButton(
            onPressed: () => open(context, LegalConfig.privacyPolicyUrl),
            child: Text(context.l10n.text('privacyPolicy')),
          ),
        if (LegalConfig.hasTermsOfUse)
          TextButton(
            onPressed: () => open(context, LegalConfig.termsOfUseUrl),
            child: Text(context.l10n.text('termsOfUse')),
          ),
      ],
    );
  }
}
