import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/dietary_profile.dart';
import '../providers/dietary_profile_provider.dart';

/// Lets the traveller register allergies and diet rules. Works for guests too:
/// everything is stored on the device only.
class DietaryProfilePage extends StatelessWidget {
  const DietaryProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DietaryProfileProvider>();
    final profile = provider.profile;
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.text('dietaryProfile'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Text(
              l10n.text('dietaryIntro'),
              style: textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.text('dietaryPrivacyNote'),
                    style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              l10n.text('dietaryAllergiesTitle'),
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final allergen in Allergen.values)
                  FilterChip(
                    selected: profile.allergens.contains(allergen),
                    label: Text(l10n.text(allergen.localizationKey)),
                    onSelected: (_) => provider.toggleAllergen(allergen),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              l10n.text('dietaryDietsTitle'),
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final rule in supportedDietaryRules)
                  FilterChip(
                    selected: profile.diets.contains(rule),
                    label: Text(l10n.text(rule.localizationKey)),
                    onSelected: (_) => provider.toggleDiet(rule),
                  ),
              ],
            ),
            const SizedBox(height: 26),
            FilledButton.icon(
              onPressed: profile.isEmpty ? null : () => context.push(AppRoutes.waiterCard),
              icon: const Icon(Icons.restaurant_menu_rounded),
              label: Text(l10n.text('dietaryShowWaiter')),
            ),
            if (!profile.isEmpty) ...[
              const SizedBox(height: 6),
              TextButton(
                onPressed: provider.clear,
                child: Text(l10n.text('clearAll')),
              ),
            ],
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.orangeSoft.withValues(alpha: .35),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: Colors.black87),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.text('dietaryDisclaimer'),
                      style: textTheme.bodySmall?.copyWith(color: Colors.black87, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
