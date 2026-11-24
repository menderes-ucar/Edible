import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../data/pronunciation_service.dart';
import '../../domain/speech_locale.dart';

/// "Listen" button for a phrase written in the destination's language.
/// Renders nothing when the country's voice language is unknown.
class SpeakButton extends StatelessWidget {
  const SpeakButton({
    required this.text,
    required this.countryCode,
    super.key,
  });

  final String text;
  final String? countryCode;

  @override
  Widget build(BuildContext context) {
    final locale = speechLocaleForCountry(countryCode);
    if (locale == null || text.trim().isEmpty) return const SizedBox.shrink();

    return IconButton(
      tooltip: context.l10n.text('pronunciationListen'),
      icon: const Icon(Icons.volume_up_rounded),
      onPressed: () async {
        final result = await PronunciationService.instance.speak(text, locale);
        if (!context.mounted) return;

        final message = switch (result) {
          SpeakResult.spoken => null,
          SpeakResult.languageUnavailable =>
            context.l10n.text('pronunciationUnavailable'),
          SpeakResult.failed => context.l10n.text('pronunciationFailed'),
        };
        if (message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      },
    );
  }
}
