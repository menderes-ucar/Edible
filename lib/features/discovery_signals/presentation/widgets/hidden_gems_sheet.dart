import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/hidden_gem_recommendation.dart';

class HiddenGemsSheet extends StatelessWidget {
  const HiddenGemsSheet({
    super.key,
    required this.items,
    required this.isLoading,
    required this.onRefresh,
    required this.onOpen,
  });

  final List<HiddenGemRecommendation> items;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final ValueChanged<HiddenGemRecommendation> onOpen;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.76,
        child: RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
            children: [
              Row(
                children: [
                  const Icon(Icons.diamond_outlined),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.l10n.text('hiddenGems'),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(context.l10n.text('hiddenGemsSubtitle')),
              if (isLoading) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
              ],
              const SizedBox(height: 16),
              if (items.isEmpty && !isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Text(
                    context.l10n.text('hiddenGemsEmpty'),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ...items.map(
                  (item) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(item.content.countryCode),
                      ),
                      title: Text(
                        item.content.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.content.locationLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _reason(context, item.reason),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => onOpen(item),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _reason(BuildContext context, HiddenGemReason reason) {
    return switch (reason) {
      HiddenGemReason.matchesInterest =>
        context.l10n.text('hiddenGemReasonInterest'),
      HiddenGemReason.lowExposure =>
        context.l10n.text('hiddenGemReasonLowExposure'),
      HiddenGemReason.localDiscovery =>
        context.l10n.text('hiddenGemReasonLocal'),
    };
  }
}
