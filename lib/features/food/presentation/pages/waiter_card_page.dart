import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/dietary_profile.dart';
import '../../domain/waiter_phrases.dart';
import '../providers/dietary_profile_provider.dart';

/// Full-screen card the traveller can show to restaurant staff. Works offline:
/// all phrases are bundled with the app.
class WaiterCardPage extends StatefulWidget {
  const WaiterCardPage({this.initialLanguageCode, super.key});

  final String? initialLanguageCode;

  @override
  State<WaiterCardPage> createState() => _WaiterCardPageState();
}

class _WaiterCardPageState extends State<WaiterCardPage> {
  late String _languageCode = _normalize(widget.initialLanguageCode);

  static String _normalize(String? value) =>
      AppLanguage.fromCode(value ?? '')?.code ?? 'en';

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<DietaryProfileProvider>().profile;
    final l10n = context.l10n;
    final appLanguage = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.text('waiterCardTitle'))),
      body: SafeArea(
        child: profile.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.text('waiterCardNeedProfile'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => context.push(AppRoutes.dietaryProfile),
                        child: Text(l10n.text('dietaryProfile')),
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  Text(
                    l10n.text('waiterCardLanguage'),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final language in AppLanguage.all)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 8),
                            child: ChoiceChip(
                              selected: _languageCode == language.code,
                              label: Text(language.nativeName),
                              onSelected: (_) => setState(() => _languageCode = language.code),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _CardSurface(
                    child: _CardBody(
                      profile: profile,
                      languageCode: _languageCode,
                      large: true,
                    ),
                  ),
                  if (appLanguage != _languageCode) ...[
                    const SizedBox(height: 18),
                    Text(
                      l10n.text('waiterCardInYourLanguage'),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    _CardSurface(
                      child: _CardBody(
                        profile: profile,
                        languageCode: appLanguage,
                        large: false,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${l10n.text('waiterCardShowHint')} ${l10n.text('dietaryDisclaimer')}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textMuted,
                                height: 1.4,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

class _CardSurface extends StatelessWidget {
  const _CardSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: .35), width: 1.5),
      ),
      child: child,
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.profile,
    required this.languageCode,
    required this.large,
  });

  final DietaryProfile profile;
  final String languageCode;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final phrases = waiterPhrasesFor(languageCode);
    final allergens = [
      for (final allergen in Allergen.values)
        if (profile.allergens.contains(allergen)) allergen,
    ];
    final diets = [
      for (final rule in supportedDietaryRules)
        if (profile.diets.contains(rule)) rule,
    ];

    final titleSize = large ? 20.0 : 16.0;
    final bodySize = large ? 19.0 : 15.0;
    const ink = Color(0xFF111111);

    TextStyle body({FontWeight weight = FontWeight.w600}) =>
        TextStyle(color: ink, fontSize: bodySize, height: 1.35, fontWeight: weight);

    return Directionality(
      textDirection: languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            phrases.title,
            style: TextStyle(color: ink, fontSize: titleSize, height: 1.25, fontWeight: FontWeight.w900),
          ),
          if (allergens.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(phrases.allergyIntro, style: body()),
            const SizedBox(height: 6),
            for (final allergen in allergens)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                  '• ${phrases.allergens[allergen] ?? ''}',
                  style: TextStyle(
                    color: const Color(0xFFB71C1C),
                    fontSize: bodySize + 1,
                    height: 1.3,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            const SizedBox(height: 6),
            Text(phrases.allergyOutro, style: body()),
          ],
          if (diets.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(phrases.dietIntro, style: body()),
            const SizedBox(height: 6),
            for (final rule in diets)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text('• ${phrases.diets[rule] ?? ''}', style: body(weight: FontWeight.w700)),
              ),
          ],
          const SizedBox(height: 14),
          Text(phrases.thanks, style: body(weight: FontWeight.w800)),
        ],
      ),
    );
  }
}
