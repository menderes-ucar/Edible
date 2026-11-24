import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/app_routes.dart';
import '../../domain/entities/dietary_profile.dart';
import '../../domain/entities/food_details.dart';
import '../../domain/waiter_phrases.dart';
import '../providers/dietary_profile_provider.dart';

/// Shown on food detail pages. It never says a dish is safe: it shows a red
/// banner for known conflicts and an amber one when the user must still check
/// with the restaurant. Designed for the dark detail page background.
class DietaryAlertBanner extends StatelessWidget {
  const DietaryAlertBanner({
    required this.details,
    required this.countryCode,
    super.key,
  });

  final FoodDetails? details;
  final String countryCode;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DietaryProfileProvider>();
    if (!provider.isRestored) return const SizedBox.shrink();

    final l10n = context.l10n;
    final profile = provider.profile;

    if (profile.isEmpty) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white38),
          ),
          onPressed: () => context.push(AppRoutes.dietaryProfile),
          icon: const Icon(Icons.no_food_rounded, size: 18),
          label: Text(l10n.text('dietarySetupPrompt')),
        ),
      );
    }

    final assessment = DietaryMatcher.assess(profile: profile, details: details);
    if (!assessment.isRelevant) return const SizedBox.shrink();

    final languageCode = Localizations.localeOf(context).languageCode;
    final separator = waiterListSeparator(languageCode);
    final conflict = assessment.hasConflict;
    final accent = conflict ? const Color(0xFFEF5350) : const Color(0xFFFFB300);
    final background = conflict ? const Color(0xFF3B1214) : const Color(0xFF3A2D0B);

    final lines = <String>[
      if (assessment.allergenConflicts.isNotEmpty)
        l10n.text('dietaryConflictAllergens').replaceAll(
              '{items}',
              assessment.allergenConflicts
                  .map((allergen) => l10n.text(allergen.localizationKey))
                  .join(separator),
            ),
      if (assessment.dietConflicts.isNotEmpty)
        l10n.text('dietaryConflictDiets').replaceAll(
              '{items}',
              assessment.dietConflicts
                  .map((rule) => l10n.text(rule.localizationKey))
                  .join(separator),
            ),
      l10n.text('dietaryUnverifiedBody'),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                conflict ? Icons.warning_amber_rounded : Icons.help_outline_rounded,
                color: accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  conflict
                      ? l10n.text('dietaryConflictTitle')
                      : l10n.text('dietaryUnverifiedTitle'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                line,
                style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.4),
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.black,
                ),
                onPressed: () => context.push(
                  AppRoutes.waiterCardFor(languageCode: waiterLanguageForCountry(countryCode)),
                ),
                icon: const Icon(Icons.restaurant_menu_rounded, size: 18),
                label: Text(l10n.text('dietaryShowWaiter')),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                onPressed: () => context.push(AppRoutes.dietaryProfile),
                child: Text(l10n.text('dietaryProfile')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
