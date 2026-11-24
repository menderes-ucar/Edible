import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/travel_share_format.dart';

/// Asks whether to share the card as a feed post (4:5) or a Story (9:16).
/// Returns null if the sheet is dismissed.
Future<TravelShareFormat?> showTravelShareFormatSheet(BuildContext context) {
  return showModalBottomSheet<TravelShareFormat>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final l10n = sheetContext.l10n;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                l10n.text('shareFormatTitle'),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.crop_portrait_rounded),
              title: Text(l10n.text('shareFormatPost')),
              onTap: () => Navigator.of(sheetContext).pop(TravelShareFormat.post),
            ),
            ListTile(
              leading: const Icon(Icons.stay_current_portrait_rounded),
              title: Text(l10n.text('shareFormatStory')),
              onTap: () => Navigator.of(sheetContext).pop(TravelShareFormat.story),
            ),
          ],
        ),
      );
    },
  );
}
