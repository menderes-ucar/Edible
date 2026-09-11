import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/for_you_recommendation.dart';

class ForYouSheet extends StatelessWidget {
  const ForYouSheet({
    super.key,
    required this.items,
    required this.isPersonalized,
    required this.isLoading,
    required this.onRefresh,
    required this.onOpen,
    required this.isSuppressed,
    required this.isUseful,
    required this.isFeedbackPending,
    required this.onUseful,
    required this.onNotForMe,
  });

  final List<ForYouRecommendation> items;
  final bool isPersonalized;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final ValueChanged<ForYouRecommendation> onOpen;
  final bool Function(String) isSuppressed;
  final bool Function(String) isUseful;
  final bool Function(String) isFeedbackPending;
  final ValueChanged<ForYouRecommendation> onUseful;
  final ValueChanged<ForYouRecommendation> onNotForMe;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.72,
        child: RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
            children: [
              Text(
                context.l10n.text('forYou'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 5),
              Text(
                context.l10n.text(
                  isPersonalized
                      ? 'forYouPersonalizedSubtitle'
                      : 'forYouLearningSubtitle',
                ),
              ),
              if (isLoading) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
              ],
              const SizedBox(height: 16),
              if (items.isEmpty && !isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Column(
                    children: [
                      const Icon(Icons.auto_awesome_outlined, size: 52),
                      const SizedBox(height: 12),
                      Text(
                        context.l10n.text('forYouEmpty'),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ...items.where((item) => !isSuppressed(item.content.id)).map(
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
                      trailing: isFeedbackPending(item.content.id)
                          ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : PopupMenuButton<String>(
                              onSelected: (value) => value == 'useful' ? onUseful(item) : onNotForMe(item),
                              itemBuilder: (_) => [
                                PopupMenuItem(value: 'useful', child: Text(context.l10n.text('recommendationUseful'))),
                                PopupMenuItem(value: 'not_for_me', child: Text(context.l10n.text('recommendationNotForMe'))),
                              ],
                            ),
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

  String _reason(BuildContext context, ForYouReason reason) {
    return switch (reason) {
      ForYouReason.categoryAffinity =>
        context.l10n.text('forYouReasonInterest'),
      ForYouReason.featuredFallback =>
        context.l10n.text('forYouReasonFeatured'),
      ForYouReason.freshFallback =>
        context.l10n.text('forYouReasonExplore'),
    };
  }
}
