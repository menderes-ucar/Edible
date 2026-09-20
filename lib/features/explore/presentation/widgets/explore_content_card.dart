import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/error/app_error_presenter.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/explore_content.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import 'smart_content_image.dart';

class ExploreContentCard extends StatelessWidget {
  const ExploreContentCard({required this.content, required this.onTap, super.key});

  final ExploreContent content;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = content.shortDescription.trim().isNotEmpty
        ? content.shortDescription.trim()
        : content.description.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.primary.withValues(alpha: .22)),
            boxShadow: [
              BoxShadow(
                color: AppColors.darkNavy.withValues(alpha: .11),
                blurRadius: 20,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 172,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      SmartContentImage(
                        title: content.title,
                        locale: Localizations.localeOf(context).languageCode,
                        city: content.cityName,
                        country: content.countryName,
                        category: content.category.value,
                        preferredUrl: content.coverImageUrl,
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, AppColors.darkNavy.withValues(alpha: .42)],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.orange,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: Text(
                              content.category.value,
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Builder(
                          builder: (context) {
                            final favorites = context.watch<FavoritesProvider>();
                            final selected = favorites.isFavorite(content.id);
                            return Material(
                              color: AppColors.darkNavy.withValues(alpha: .78),
                              shape: const CircleBorder(),
                              child: IconButton(
                                visualDensity: VisualDensity.compact,
                                color: Colors.white,
                                tooltip: selected ? context.l10n.text('favoriteRemove') : context.l10n.text('favoriteAdd'),
                                onPressed: favorites.isPending(content.id)
                                    ? null
                                    : () async {
                                        final ok = await favorites.toggle(content);
                                        if (!ok && context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                AppErrorPresenter.message(
                                                  context,
                                                  favorites.errorMessage,
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                icon: Icon(selected ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 19),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 10, 15, 11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(content.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, height: 1.08)),
                      const SizedBox(height: 7),
                      Row(children: [
                        const Icon(Icons.location_on_rounded, size: 15, color: AppColors.primaryDark),
                        const SizedBox(width: 4),
                        Expanded(child: Text(content.locationLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primaryDark))),
                      ]),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 7),
                        Text(description, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(height: 1.35, color: AppColors.textMuted)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
