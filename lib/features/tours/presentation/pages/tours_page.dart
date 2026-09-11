import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_routes.dart';
import '../../data/repositories/tour_repository.dart';
import '../../domain/entities/tour_package.dart';
import '../widgets/tour_filter_sheet.dart';
import '../../../explore/presentation/widgets/smart_content_image.dart';

class ToursPage extends StatefulWidget {
  const ToursPage({super.key});

  @override
  State<ToursPage> createState() => _ToursPageState();
}

class _ToursPageState extends State<ToursPage> {
  final _repository = TourRepository();
  List<TourPackage>? _packages;
  String? _country;
  String? _city;
  double? _minRating;
  TourSort _sort = TourSort.topRated;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _favorite(TourPackage package) async {
    try {
      await _repository.favorite(package.id, true);
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.text('authenticationRequired'))),
      );
    }
  }

  Future<void> _load() async {
    final packages = await _repository.getPackages();
    if (!mounted) return;
    setState(() => _packages = packages);
  }

  @override
  Widget build(BuildContext context) {
    final source = _packages;
    if (source == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF2D2D2D),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final countries = source.map((e) => e.countryCode).toSet().toList()..sort();
    final countryNames = <String, String>{
      for (final package in source) package.countryCode: package.countryName,
    };
    final citiesByCountry = <String, List<String>>{};
    for (final package in source) {
      citiesByCountry.putIfAbsent(package.countryCode, () => <String>[]).add(package.cityName);
    }
    for (final entry in citiesByCountry.entries) {
      final uniqueCities = entry.value.toSet().toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      citiesByCountry[entry.key] = uniqueCities;
    }

    final visible = source.where((p) {
      if (_country != null && p.countryCode != _country) return false;
      if (_city != null && p.cityName != _city) return false;
      if (_minRating != null && p.ratingAverage < _minRating!) return false;
      return true;
    }).toList();
    visible.sort((a, b) => _sort == TourSort.topRated
        ? b.ratingAverage.compareTo(a.ratingAverage)
        : b.favoriteCount.compareTo(a.favoriteCount));

    final activeFilterCount = (_country == null ? 0 : 1) +
        (_city == null ? 0 : 1) +
        (_minRating == null ? 0 : 1) +
        (_sort == TourSort.topRated ? 0 : 1);

    Future<void> showFilters() async {
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => TourFilterSheet(
          countryCodes: countries,
          countryNames: countryNames,
          citiesByCountry: citiesByCountry,
          initialCountry: _country,
          initialCity: _city,
          initialMinRating: _minRating,
          initialSort: _sort,
          onApply: (country, city, minRating, sort) {
            setState(() {
              _country = country;
              _city = city;
              _minRating = minRating;
              _sort = sort;
            });
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF2D2D2D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        foregroundColor: Colors.white,
        title: Text(context.l10n.text('tours')),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.primary.withValues(alpha: .16)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.darkNavy.withValues(alpha: .08),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => context.push(AppRoutes.vacationPlanner),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
                    child: Row(children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.orangeSoft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryDark),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          context.l10n.text('planVacation'),
                          style: const TextStyle(color: AppColors.primaryDark, fontSize: 17, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          context.l10n.text('planVacationSubtitle'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AppColors.primaryDark.withValues(alpha: .68)),
                        ),
                      ])),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, color: AppColors.primaryDark),
                    ]),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 2, 2, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${visible.length} ${context.l10n.text('tours')}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    _sort == TourSort.topRated ? context.l10n.text('featured') : context.l10n.text('favorites'),
                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Material(
                elevation: 3,
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: showFilters,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.tune_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(context.l10n.text('filters'), style: const TextStyle(fontWeight: FontWeight.w800)),
                        if (activeFilterCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$activeFilterCount',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            for (final package in visible) ...[
              _TourPackageCard(
                package: package,
                onTap: () => context.pushNamed(
                  'tour-detail',
                  pathParameters: {'packageId': package.id},
                  extra: package,
                ),
                onFavorite: () => _favorite(package),
              ),
              const SizedBox(height: 14),
            ],
            if (visible.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Center(child: Text(context.l10n.text('noResults'), style: const TextStyle(color: Colors.white70))),
              ),
          ],
        ),
      ),
    );
  }
}

class _TourPackageCard extends StatelessWidget {
  const _TourPackageCard({required this.package, required this.onTap, required this.onFavorite});
  final TourPackage package;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 8.5,
              child: SmartContentImage(
                title: package.cityName,
                locale: Localizations.localeOf(context).languageCode,
                city: package.cityName,
                country: package.countryName,
                preferredUrl: package.coverImageUrl,
                fit: BoxFit.cover,
                showAttribution: false,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${package.cityName} · ${package.days} ${context.l10n.text('days')}',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 5),
                  Text(package.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(package.summary),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: Wrap(spacing: 12, children: [
                      _Stat(icon: Icons.star_rounded, text: package.ratingCount == 0 ? '—' : package.ratingAverage.toStringAsFixed(1)),
                      _Stat(icon: Icons.favorite_rounded, text: '${package.favoriteCount}'),
                      _Stat(icon: Icons.route_rounded, text: '${package.stops.length} ${context.l10n.text('stops')}'),
                    ])),
                    IconButton(
                      tooltip: context.l10n.text('favorite'),
                      onPressed: onFavorite,
                      icon: const Icon(Icons.favorite_border_rounded),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Text(package.coverAttribution, style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.text});
  final IconData icon; final String text;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon,size:16), const SizedBox(width:4), Text(text,style:const TextStyle(fontWeight:FontWeight.w800)),
  ]);
}
