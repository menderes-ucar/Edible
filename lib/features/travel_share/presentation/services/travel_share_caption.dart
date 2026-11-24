import 'package:flutter/widgets.dart';

import '../../../../core/config/share_config.dart';
import '../../../../core/localization/app_localizations.dart';

abstract final class TravelShareCaption {
  /// Appends a localized "discover more" line with the download link when a
  /// valid `APP_SHARE_URL` is configured. Otherwise returns [caption] as is.
  static String withLink(BuildContext context, String caption) {
    final link = ShareConfig.appShareUrl;
    if (link == null) return caption;
    return '$caption\n\n${context.l10n.text('shareGetEdible')} $link';
  }
}
