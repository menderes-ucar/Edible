import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/app_routes.dart';
import '../../../explore/domain/entities/explore_category.dart';
import '../../../explore/domain/entities/explore_content.dart';
import '../../../explore/domain/repositories/explore_repository.dart';
import '../../../explore/presentation/providers/explore_provider.dart';
import '../../../explore/presentation/widgets/explore_content_card.dart';
import '../../../explore/presentation/widgets/explore_filter_sheet.dart';
import '../../../discovery_signals/data/datasources/discovery_signals_remote_datasource.dart';
import '../../../explore/presentation/widgets/smart_content_image.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../discovery_signals/data/repositories/discovery_signals_repository_impl.dart';
import '../../../discovery_signals/presentation/providers/discovery_signals_provider.dart';
import '../../../discovery_signals/presentation/providers/for_you_provider.dart';
import '../../../discovery_signals/presentation/providers/recommendation_feedback_provider.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../../discovery_signals/presentation/widgets/for_you_sheet.dart';
import '../../../../core/theme/app_colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ExploreProvider _exploreProvider;
  late final DiscoverySignalsProvider _signalsProvider;
  late final ForYouProvider _forYouProvider;
  late final RecommendationFeedbackProvider _feedbackProvider;
  String? _languageCode;

  @override
  void initState() {
    super.initState();
    _exploreProvider = ExploreProvider(repository: context.read<ExploreRepository>());
    final repository = DiscoverySignalsRepositoryImpl(
      DiscoverySignalsRemoteDataSource(SupabaseService.client),
    );
    // The discovery providers are kept compatible with the existing home architecture.
    // Their sheets/actions are still available from the redesigned home.
    _signalsProvider = DiscoverySignalsProvider(repository: repository);
    _forYouProvider = ForYouProvider(repository: repository);
    _feedbackProvider = RecommendationFeedbackProvider(repository: repository);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languageCode = Localizations.localeOf(context).languageCode;
    if (_languageCode != languageCode) {
      _languageCode = languageCode;
      _exploreProvider.load(languageCode: languageCode, force: true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<FavoritesProvider>().ensureLoaded(languageCode: languageCode);
        }
      });
    }
  }

  @override
  void dispose() {
    _feedbackProvider.dispose();
    _forYouProvider.dispose();
    _signalsProvider.dispose();
    _exploreProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _exploreProvider),
        ChangeNotifierProvider.value(value: _signalsProvider),
        ChangeNotifierProvider.value(value: _forYouProvider),
        ChangeNotifierProvider.value(value: _feedbackProvider),
      ],
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

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

  void _openContent(BuildContext context, ExploreContent item) {
    context.push(AppRoutes.contentDetail(item.id), extra: item);
  }

  void _openCity(BuildContext context, ExploreContent item) {
    context.push(AppRoutes.cityDetail(
      countryCode: item.countryCode,
      cityName: item.cityName,
    ));
  }

  void _openCityMap(BuildContext context, ExploreContent item) {
    context.push(AppRoutes.cityMapFor(
      countryCode: item.countryCode,
      cityName: item.cityName,
    ));
  }

  Future<void> _showForYou(BuildContext context) async {
    final catalog = context.read<ExploreProvider>().items;
    final provider = context.read<ForYouProvider>();
    await provider.refresh(contents: catalog);
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => ChangeNotifierProvider.value(
        value: provider,
        child: Consumer<ForYouProvider>(
          builder: (context, state, _) => ForYouSheet(
            items: state.recommendations,
            isPersonalized: state.hasPersonalSignals,
            isLoading: state.isLoading,
            onRefresh: () => state.refresh(contents: catalog),
            isSuppressed: context.watch<RecommendationFeedbackProvider>().isSuppressed,
            isUseful: context.watch<RecommendationFeedbackProvider>().isUseful,
            isFeedbackPending: context.watch<RecommendationFeedbackProvider>().isPending,
            onUseful: (r) => context.read<RecommendationFeedbackProvider>().useful(
              contentId: r.content.id,
              category: r.content.category.name,
              countryCode: r.content.countryCode,
              cityName: r.content.cityName,
            ),
            onNotForMe: (r) => context.read<RecommendationFeedbackProvider>().notForMe(
              contentId: r.content.id,
              category: r.content.category.name,
              countryCode: r.content.countryCode,
              cityName: r.content.cityName,
            ),
            onOpen: (r) {
              Navigator.pop(sheetContext);
              _openContent(context, r.content);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ExploreProvider>();
    final items = state.visibleItems;
    final cities = <String, List<ExploreContent>>{};
    for (final item in items) {
      final key = '${item.countryCode.trim().toUpperCase()}|${_normalizeCity(item.cityName)}';
      (cities[key] ??= []).add(item);
    }
    final cityGroups = cities.values.toList()
      ..sort((a, b) {
        final countryCompare = a.first.countryName.toLowerCase().compareTo(b.first.countryName.toLowerCase());
        if (countryCompare != 0) return countryCompare;
        return a.first.cityName.toLowerCase().compareTo(b.first.cityName.toLowerCase());
      });
    final featured = items.where((e) => e.isFeatured).take(8).toList();
    final popular = (featured.isEmpty ? items : featured).take(10).toList();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => state.load(
          languageCode: Localizations.localeOf(context).languageCode,
          force: true,
        ),
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _HomeHeader()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: _SearchBar(
                  initialValue: state.query,
                  onChanged: state.updateQuery,
                  onFilter: () => _showFilters(context),
                ),
              ),
            ),
            if (state.isLoading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (items.isEmpty)
              SliverFillRemaining(child: _EmptyState(onReset: state.clearFilters))
            else ...[
              SliverToBoxAdapter(
                child: _FavoritesSection(items: context.watch<FavoritesProvider>().items),
              ),
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: context.l10n.text('discover'),
                  subtitle: context.l10n.text('discoverCity'),
                ),
              ),
              if (popular.isNotEmpty)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 300,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      scrollDirection: Axis.horizontal,
                      itemCount: popular.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => SizedBox(
                        width: 300,
                        child: ExploreContentCard(
                          content: popular[i],
                          onTap: () => _openContent(context, popular[i]),
                        ),
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: context.l10n.text('cities'),
                  subtitle: '${cityGroups.length} · ${items.length} ${context.l10n.text('places')}',
                ),
              ),
              SliverList.builder(
                itemCount: cityGroups.length,
                itemBuilder: (context, index) {
                  final cityItems = cityGroups[index];
                  final city = cityItems.first;
                  return _CityCard(
                    city: city,
                    items: cityItems,
                    onTap: () => _openCity(context, city),
                    onMapTap: () => _openCityMap(context, city),
                    onContentTap: (item) => _openContent(context, item),
                  );
                },
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Future<void> _showFilters(BuildContext context) async {
    // Keep the existing filter workflow accessible from the new home.
    final state = context.read<ExploreProvider>();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => ExploreFilterSheet(
        initial: state.filters,
        initialCategory: state.selectedCategory,
        countryCodes: state.availableCountryCodes,
        countryNames: state.availableCountryNames,
        citiesByCountry: state.availableCitiesByCountry,
        onApply: (filters, category) {
          state.updateFilters(filters);
          if (category == null) {
            state.clearCategory();
          } else {
            state.selectCategory(category);
          }
        },
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 136,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: AppColors.orangeSoft,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Stack(
        children: [
          Positioned(right: -62, top: -100, child: _HomeCircle(size: 145)),
          Positioned(left: -70, bottom: -112, child: _HomeCircle(size: 145)),
          Positioned(right: 22, top: 25, child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withValues(alpha: .08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.travel_explore_rounded, color: AppColors.primaryDark, size: 25),
          )),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 82, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'EDIBLE',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2.4),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Yeni yerler.\nYeni tatlar.',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w900,
                      height: .98,
                      fontSize: 21,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Bugün ne keşfedeceksin?',
                    style: TextStyle(color: AppColors.primaryDark.withValues(alpha: .72), fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeCircle extends StatelessWidget {
  const _HomeCircle({required this.size});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.primaryDark.withValues(alpha: .08), width: 2),
      color: AppColors.primaryDark.withValues(alpha: .035),
    ),
  );
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.initialValue, required this.onChanged, required this.onFilter});
  final String initialValue;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surfaceMint,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: .55)),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withValues(alpha: .13),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: context.l10n.text('searchHint'),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryDark),
          suffixIcon: Padding(
            padding: const EdgeInsets.all(4),
            child: IconButton(
              onPressed: onFilter,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.tune_rounded, size: 19),
            ),
          ),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _CategoryRail extends StatelessWidget {
  const _CategoryRail({required this.selected, required this.onSelected, required this.onClear});
  final ExploreCategory? selected;
  final ValueChanged<ExploreCategory> onSelected;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final values = ExploreCategory.values;
    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        scrollDirection: Axis.horizontal,
        itemCount: values.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i == 0) return FilterChip(label: Text(context.l10n.text('all')), selected: selected == null, onSelected: (_) => onClear());
          final category = values[i - 1];
          return FilterChip(label: Text(_categoryName(category)), selected: selected == category, onSelected: (_) => onSelected(category));
        },
      ),
    );
  }

  String _categoryName(ExploreCategory c) => switch (c) {
    ExploreCategory.place => 'Mekân',
    ExploreCategory.food => 'Yemek',
    ExploreCategory.snack => 'Atıştırmalık',
    ExploreCategory.culture => 'Kültür',
    ExploreCategory.fruit => 'Meyve',
    ExploreCategory.drink => 'İçecek',
  };
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: AppColors.primary.withValues(alpha: .16)),
          ),
          child: Icon(
            title == 'Şehirler' ? Icons.location_city_rounded : Icons.explore_rounded,
            color: AppColors.primaryDark,
            size: 21,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CityCard extends StatelessWidget {
  const _CityCard({required this.city, required this.items, required this.onTap, required this.onMapTap, required this.onContentTap});
  final ExploreContent city;
  final List<ExploreContent> items;
  final VoidCallback onTap;
  final VoidCallback onMapTap;
  final ValueChanged<ExploreContent> onContentTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.surfaceStrong, AppColors.surface], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.primary.withValues(alpha: .20)),
        boxShadow: [BoxShadow(color: AppColors.darkNavy.withValues(alpha: .07), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: InkWell(
                onTap: onTap,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(city.cityName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text('${city.countryName} · ${items.length} keşif', style: theme.textTheme.bodySmall),
                ]),
              )),
              IconButton(
                tooltip: context.l10n.text('showOnMap'),
                onPressed: onMapTap,
                icon: const Icon(Icons.map_outlined),
              ),
              Builder(
                builder: (context) {
                  final favorites = context.watch<FavoritesProvider>();
                  final representative = items.first;
                  final selected = favorites.isFavorite(representative.id);
                  return IconButton(
                    tooltip: selected ? context.l10n.text('favoriteRemove') : context.l10n.text('favoriteAdd'),
                    onPressed: favorites.isPending(representative.id)
                        ? null
                        : () => favorites.toggle(representative),
                    icon: Icon(
                      selected ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    ),
                  );
                },
              ),
            ]),
            const SizedBox(height: 10),
            SizedBox(
              height: 148,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.take(5).length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => SizedBox(
                  width: 190,
                  child: _MiniContentCard(content: items[i], onTap: () => onContentTap(items[i])),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _MiniContentCard extends StatelessWidget {
  const _MiniContentCard({required this.content, required this.onTap});
  final ExploreContent content;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();
    final isFavorite = favorites.isFavorite(content.id);

    return Container(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: AppColors.surfaceMint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: .18)),
        boxShadow: [BoxShadow(color: AppColors.darkNavy.withValues(alpha: .06), blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            height: 82,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                SmartContentImage(
              title: content.title,
              locale: Localizations.localeOf(context).languageCode,
              city: content.cityName,
              country: content.countryName,
              preferredUrl: content.coverImageUrl,
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: isFavorite ? context.l10n.text('favoriteRemove') : context.l10n.text('favoriteAdd'),
                      color: Colors.white,
                      onPressed: favorites.isPending(content.id)
                          ? null
                          : () => favorites.toggle(content),
                      icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(9, 7, 9, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(content.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              const SizedBox(height: 2),
              Text(
                (content.shortDescription.trim().isNotEmpty ? content.shortDescription : content.description),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10.5),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _FavoritesSection extends StatelessWidget {
  const _FavoritesSection({required this.items});

  final List<ExploreContent> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Favorilerin',
          subtitle: 'Kaydettiğin keşiflere hızlıca dön.',
        ),
        SizedBox(
          height: 286,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            scrollDirection: Axis.horizontal,
            itemCount: items.take(8).length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return SizedBox(
                width: 220,
                child: ExploreContentCard(
                  content: item,
                  onTap: () => context.push(
                    AppRoutes.contentDetail(item.id),
                    extra: item,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onReset});
  final VoidCallback onReset;
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.travel_explore_rounded, size: 54),
      const SizedBox(height: 12),
      Text(context.l10n.text('noResults'), textAlign: TextAlign.center),
      const SizedBox(height: 12),
      FilledButton(onPressed: onReset, child: Text(context.l10n.text('tryAnotherSearch'))),
    ]),
  ));
}
