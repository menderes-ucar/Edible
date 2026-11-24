import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/support_config.dart';
import '../localization/app_localizations.dart';

/// Opens the mail app addressed to the configured support address.
/// Does nothing visible if no address is configured.
Future<void> openSupportEmail(BuildContext context, {String? subject}) async {
  final uri = SupportConfig.mailto(subject: subject);
  if (uri == null) return;
  var opened = false;
  try {
    opened = await launchUrl(uri);
  } catch (_) {
    opened = false;
  }
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.text('legalLinkFailed'))),
    );
  }
}
