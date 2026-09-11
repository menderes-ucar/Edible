import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:edible/core/error/app_error_presenter.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/app_routes.dart';
import '../../domain/entities/explore_category.dart';
import '../../domain/entities/explore_content.dart';
import '../../domain/services/city_discovery_overview.dart';
import '../../domain/repositories/explore_repository.dart';
import '../../../progress/domain/usecases/calculate_discovery_progress.dart';
import '../../../offline/presentation/providers/offline_city_pack_provider.dart';
import '../../../subscription/domain/entities/subscription_entitlement.dart';
import '../../../subscription/presentation/widgets/premium_gate.dart';
import '../../../progress/presentation/providers/progress_provider.dart';
import '../../../progress/presentation/widgets/discovery_score_card.dart';
import '../widgets/explore_content_card.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';

class CityDetailPage extends StatefulWidget {
  const CityDetailPage({
    required this.countryCode,
    required this.cityName,
    super.key,
  });

  final String countryCode;
  final String cityName;

  @override
  State<CityDetailPage> createState() => _CityDetailPageState();
}

class _CityDetailPageState extends State<CityDetailPage> {
  List<ExploreContent>? _items;
  ExploreCategory? _filter;
  String? _languageCode;
  String? _error;
  int _loadGeneration = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final language = Localizations.localeOf(context).languageCode;
    if (_languageCode != language) {
      _languageCode = language;
      _load(language);
    }
  }

  Future<void> _load(String languageCode) async {
    final generation = ++_loadGeneration;
    if (mounted) {
      setState(() => _error = null);
    }

    try {
      final all = await context.read<ExploreRepository>().getContents(
            languageCode: languageCode,
          );

      if (!mounted || generation != _loadGeneration) return;

      setState(() {
        _items = all.where((item) {
          return item.countryCode.toLowerCase() ==
                  widget.countryCode.toLowerCase() &&
              item.cityName.toLowerCase() == widget.cityName.toLowerCase();
        }).toList(growable: false);
        _error = null;
      });
    } catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() => _error = AppErrorPresenter.message(context, error));
    }
  }

  String _normalizeCity(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('İ', 'i')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c');

  @override
  Widget build(BuildContext context) {
    final items = _items;

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.cityName)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _load(
                    _languageCode ??
                        Localizations.localeOf(context).languageCode,
                  ),
                  icon: const Icon(Icons.refresh),
                  label: Text(context.l10n.text('retry')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (items == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.cityName)),
        body: Center(child: Text(context.l10n.text('noResults'))),
      );
    }

    final progress = context.watch<ProgressProvider>();
    final offline = context.watch<OfflineCityPackProvider>();
    final languageCode = Localizations.localeOf(context).languageCode;
    final isDownloaded = offline.contains(
      countryCode: widget.countryCode,
      cityName: widget.cityName,
      languageCode: languageCode,
    );

    const calculator = CalculateDiscoveryProgress();
    final discoveryStats = calculator.forContents(
      contents: items,
      visitedIds: progress.visitedIds,
      triedIds: progress.triedIds,
    );

    final visible = _filter == null
        ? items
        : items
            .where((item) => item.category == _filter)
            .toList(growable: false);
    final overview = CityDiscoveryOverviewBuilder.build(items);
    String? heroImage;
    for (final item in items) {
      final candidate = item.coverImageUrl?.trim();
      if (candidate != null && candidate.isNotEmpty) {
        heroImage = candidate;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cityName),
        actions: [
          TextButton(
            onPressed: () => context.push(
              AppRoutes.countryDetail(widget.countryCode),
            ),
            child: Text(items.first.countryName),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _CityHeroCard(
            cityName: widget.cityName,
            countryName: items.first.countryName,
            imageUrl: heroImage,
            overview: overview,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: () => context.push(
                AppRoutes.cityMapFor(
                  countryCode: widget.countryCode,
                  cityName: widget.cityName,
                ),
              ),
              icon: const Icon(Icons.map_rounded),
              label: Text(context.l10n.text('showOnMap')),
            ),
          ),
          const SizedBox(height: 14),
          DiscoveryScoreCard(stats: discoveryStats),
          const SizedBox(height: 18),
          Text(
            context.l10n.text('cityQuickActions'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 10),
          _CityActionGrid(
            actions: [
              _CityActionData(
                icon: Icons.luggage_outlined,
                title: context.l10n.text('createTripWorkspace'),
                subtitle: context.l10n.text('tripWorkspaceSubtitle'),
                onTap: () => context.push(
                  AppRoutes.savedTripsForCity(
                    countryCode: widget.countryCode,
                    countryName: items.first.countryName,
                    cityName: widget.cityName,
                  ),
                ),
              ),
              _CityActionData(
                icon: Icons.flight_land_rounded,
                title: context.l10n.text('first24Hours'),
                subtitle: context.l10n.text('arrivalGuideSubtitle'),
                onTap: () => context.push(
                  AppRoutes.arrivalGuideFor(
                    countryCode: widget.countryCode,
                    cityName: widget.cityName,
                  ),
                ),
              ),
              _CityActionData(
                icon: Icons.public_rounded,
                title: context.l10n.text('cultureGuide'),
                subtitle: context.l10n.text('cultureGuideSubtitle'),
                onTap: () => context.push(
                  AppRoutes.cultureGuideFor(
                    countryCode: widget.countryCode,
                    cityName: widget.cityName,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            context.l10n.text('cityTravelTools'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 10),
          _CityToolCard(
            icon: isDownloaded
                ? Icons.offline_pin_rounded
                : Icons.download_for_offline_outlined,
            title: isDownloaded
                ? context.l10n.text('offlinePackDownloaded')
                : context.l10n.text('downloadCity'),
            subtitle: context.l10n.text('offlinePackSubtitle'),
            trailing: offline.isLoading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(isDownloaded ? Icons.refresh_rounded : Icons.download_rounded),
            onTap: offline.isLoading
                ? null
                : () async {
                    if (!PremiumGate.allowOrOpenPaywall(
                      context,
                      PremiumFeature.offlineCityPacks,
                    )) {
                      return;
                    }

                    try {
                      await context.read<OfflineCityPackProvider>().download(
                            countryCode: widget.countryCode,
                            cityName: widget.cityName,
                            languageCode: languageCode,
                          );

                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.l10n.text('offlinePackReady')),
                        ),
                      );
                    } catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppErrorPresenter.message(context, error),
                          ),
                        ),
                      );
                    }
                  },
          ),
          const SizedBox(height: 8),
          _CityToolCard(
            icon: Icons.route_rounded,
            title: context.l10n.text('tripPlanner'),
            subtitle: context.l10n.text('tripPlannerSubtitle'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              if (!PremiumGate.allowOrOpenPaywall(
                context,
                PremiumFeature.advancedTripPlanner,
              )) {
                return;
              }
              context.push(AppRoutes.tripPlanner);
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.text('discoverCity'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              _CountBadge(
                label: context.l10n
                    .text('cityDiscoveryCount')
                    .replaceAll('{count}', '${overview.totalCount}'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: _filter == null,
                    label: Text(context.l10n.text('all')),
                    onSelected: (_) => setState(() => _filter = null),
                  ),
                ),
                ...ExploreCategory.values
                    .where((category) => overview.countFor(category) > 0)
                    .map(
                  (category) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: _filter == category,
                      avatar: CircleAvatar(
                        radius: 10,
                        child: Text(
                          '${overview.countFor(category)}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                      label: Text(
                        context.l10n.text(category.localizationKey),
                      ),
                      onSelected: (_) => setState(() => _filter = category),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.all(30),
              child: Text(
                context.l10n.text('noResults'),
                textAlign: TextAlign.center,
              ),
            )
          else
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: visible.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 320,
                mainAxisExtent: 278,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final item = visible[index];

                return ExploreContentCard(
                  content: item,
                  onTap: () => context.push(
                    AppRoutes.contentDetail(item.id),
                    extra: item,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _CityHeroCard extends StatelessWidget {
  const _CityHeroCard({
    required this.cityName,
    required this.countryName,
    required this.imageUrl,
    required this.overview,
  });

  final String cityName;
  final String countryName;
  final String? imageUrl;
  final CityDiscoveryOverview overview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 230,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null)
              Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _CityHeroFallback(
                  cityName: cityName,
                ),
              )
            else
              _CityHeroFallback(cityName: cityName),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x12000000),
                    Color(0xD9000000),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CountBadge(
                    dark: true,
                    label: countryName,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cityName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _HeroStat(
                        icon: Icons.explore_outlined,
                        text: context.l10n
                            .text('cityDiscoveryCount')
                            .replaceAll('{count}', '${overview.totalCount}'),
                      ),
                      if (overview.featuredCount > 0)
                        _HeroStat(
                          icon: Icons.star_rounded,
                          text: context.l10n
                              .text('cityFeaturedCount')
                              .replaceAll(
                                '{count}',
                                '${overview.featuredCount}',
                              ),
                        ),
                    ],
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

class _CityHeroFallback extends StatelessWidget {
  const _CityHeroFallback({required this.cityName});

  final String cityName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            scheme.tertiary,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.location_city_rounded,
          size: 72,
          color: scheme.onPrimary.withValues(alpha: .8),
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .35),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.label,
    this.dark = false,
  });

  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark
            ? Colors.black.withValues(alpha: .38)
            : theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: dark ? Colors.white : theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _CityActionData {
  const _CityActionData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _CityActionGrid extends StatelessWidget {
  const _CityActionGrid({required this.actions});

  final List<_CityActionData> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 3 : 1;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - (columns - 1) * 10) / columns;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final action in actions)
              SizedBox(
                width: width,
                child: Material(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: .5),
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: action.onTap,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            child: Icon(action.icon),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  action.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  action.subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CityToolCard extends StatelessWidget {
  const _CityToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 4,
        ),
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(subtitle),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}

