import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/error/app_error_presenter.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/app_routes.dart';
import '../../domain/entities/explore_content.dart';
import '../../domain/entities/explore_category.dart';
import '../../domain/services/country_discovery_overview.dart';
import '../../domain/repositories/explore_repository.dart';
import '../../../progress/domain/usecases/calculate_discovery_progress.dart';
import '../../../progress/presentation/providers/progress_provider.dart';
import '../../../progress/presentation/widgets/discovery_score_card.dart';
import '../widgets/explore_content_card.dart';

class CountryDetailPage extends StatefulWidget {
  const CountryDetailPage({
    required this.countryCode,
    super.key,
  });

  final String countryCode;

  @override
  State<CountryDetailPage> createState() => _CountryDetailPageState();
}

class _CountryDetailPageState extends State<CountryDetailPage> {
  List<ExploreContent>? _items;
  String? _error;
  String? _languageCode;
  int _requestId = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final language = Localizations.localeOf(context).languageCode;
    if (_languageCode != language) {
      _languageCode = language;
      _load(language);
    }
  }

  @override
  void didUpdateWidget(covariant CountryDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.countryCode == widget.countryCode) return;

    _requestId++;
    _items = null;
    _error = null;

    final languageCode =
        _languageCode ?? Localizations.localeOf(context).languageCode;
    _load(languageCode);
  }

  Future<void> _load(String languageCode) async {
    final requestId = ++_requestId;
    final countryCode = widget.countryCode.toLowerCase();

    setState(() {
      _items = null;
      _error = null;
    });

    try {
      final all = await context.read<ExploreRepository>().getContents(
            languageCode: languageCode,
          );

      if (!mounted || requestId != _requestId) return;

      setState(() {
        _items = all
            .where(
              (item) => item.countryCode.toLowerCase() == countryCode,
            )
            .toList(growable: false);
        _error = null;
      });
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(
        () => _error = AppErrorPresenter.message(context, error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _load(
                    _languageCode ??
                        Localizations.localeOf(context).languageCode,
                  ),
                  icon: const Icon(Icons.refresh_rounded),
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
        appBar: AppBar(),
        body: Center(child: Text(context.l10n.text('noResults'))),
      );
    }

    final countryName = items.first.countryName;
    final cities = <String, List<ExploreContent>>{};
    for (final item in items) {
      cities.putIfAbsent(item.cityName, () => []).add(item);
    }

    final progress = context.watch<ProgressProvider>();
    const calculator = CalculateDiscoveryProgress();
    final discoveryStats = calculator.forContents(
      contents: items,
      visitedIds: progress.visitedIds,
      triedIds: progress.triedIds,
    );

    final overview = CountryDiscoveryOverviewBuilder.build(items);

    final featured =
        items.where((item) => item.isFeatured).toList(growable: false);
    final mustTry = items.where(_isMustTry).toList(growable: false);
    final culture = items
        .where((item) => item.category.name == 'culture')
        .toList(growable: false);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            pinned: true,
            expandedHeight: 310,
            flexibleSpace: FlexibleSpaceBar(
              background: _CountryHero(
                imageUrl: items
                    .expand((item) => item.allImageUrls)
                    .cast<String?>()
                    .firstWhere(
                      (url) => url != null && url.isNotEmpty,
                      orElse: () => null,
                    ),
                code: widget.countryCode,
                countryName: countryName,
                cityCount: overview.cityCount,
                discoveryCount: overview.totalCount,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 36),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                DiscoveryScoreCard(stats: discoveryStats),
                const SizedBox(height: 16),
                _CountryStatsPanel(overview: overview),
                const SizedBox(height: 28),
                _SectionTitle(
                  title: context.l10n.text('exploreCities'),
                  trailing: context.l10n
                      .text('countryCityCount')
                      .replaceAll('{count}', '${overview.cityCount}'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 176,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: overview.cities.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final city = overview.cities[index];
                      return _CountryCityCard(
                        city: city,
                        onTap: () => context.push(
                          AppRoutes.cityDetail(
                            countryCode: widget.countryCode,
                            cityName: city.cityName,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (featured.isNotEmpty) ...[
                  const SizedBox(height: 30),
                  _HorizontalSection(
                    title: context.l10n.text('featured'),
                    items: featured,
                  ),
                ],
                if (mustTry.isNotEmpty) ...[
                  const SizedBox(height: 30),
                  _HorizontalSection(
                    title: context.l10n.text('mustTry'),
                    items: mustTry,
                  ),
                ],
                if (culture.isNotEmpty) ...[
                  const SizedBox(height: 30),
                  _HorizontalSection(
                    title: context.l10n.text('cultureGuide'),
                    items: culture,
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  bool _isMustTry(ExploreContent item) {
    final category = item.category.name;
    return category == 'food' ||
        category == 'snack' ||
        category == 'fruit' ||
        category == 'drink';
  }
}

class _HorizontalSection extends StatelessWidget {
  const _HorizontalSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<ExploreContent> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: title),
        const SizedBox(height: 12),
        SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return ExploreContentCard(
                content: item,
                onTap: () => context.push(
                  AppRoutes.contentDetail(item.id),
                  extra: item,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.trailing,
  });

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
          ),
      ],
    );
  }
}

class _CountryHero extends StatelessWidget {
  const _CountryHero({
    required this.imageUrl,
    required this.code,
    required this.countryName,
    required this.cityCount,
    required this.discoveryCount,
  });

  final String? imageUrl;
  final String code;
  final String countryName;
  final int cityCount;
  final int discoveryCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageUrl != null && imageUrl!.trim().isNotEmpty)
          Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _CountryHeroFallback(code: code),
          )
        else
          _CountryHeroFallback(code: code),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x22000000),
                Color(0x33000000),
                Color(0xE8000000),
              ],
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 22,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                code.toUpperCase(),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                countryName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _CountryHeroStat(
                    icon: Icons.location_city_rounded,
                    text: context.l10n
                        .text('countryCityCount')
                        .replaceAll('{count}', '$cityCount'),
                  ),
                  _CountryHeroStat(
                    icon: Icons.explore_rounded,
                    text: context.l10n
                        .text('cityDiscoveryCount')
                        .replaceAll('{count}', '$discoveryCount'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CountryHeroFallback extends StatelessWidget {
  const _CountryHeroFallback({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.tertiary],
        ),
      ),
      child: Center(
        child: Text(
          code.toUpperCase(),
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: scheme.onPrimary,
                fontWeight: FontWeight.w900,
              ),
        ),
      ),
    );
  }
}

class _CountryHeroStat extends StatelessWidget {
  const _CountryHeroStat({
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
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountryStatsPanel extends StatelessWidget {
  const _CountryStatsPanel({required this.overview});

  final CountryDiscoveryOverview overview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ExploreCategory.values
        .where((category) => overview.countFor(category) > 0)
        .toList(growable: false);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final category in categories)
              Chip(
                avatar: CircleAvatar(
                  child: Text(
                    '${overview.countFor(category)}',
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
                label: Text(context.l10n.text(category.localizationKey)),
              ),
          ],
        ),
      ),
    );
  }
}

class _CountryCityCard extends StatelessWidget {
  const _CountryCityCard({
    required this.city,
    required this.onTap,
  });

  final CountryCityOverview city;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 190,
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (city.imageUrl != null)
                Image.network(
                  city.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xE5000000)],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      city.cityName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      context.l10n
                          .text('cityDiscoveryCount')
                          .replaceAll('{count}', '${city.discoveryCount}'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
