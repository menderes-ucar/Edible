import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/country_mastery.dart';
import '../providers/visits_provider.dart';

class CountryMasteryPage extends StatefulWidget {
  const CountryMasteryPage({super.key});

  @override
  State<CountryMasteryPage> createState() => _CountryMasteryPageState();
}

class _CountryMasteryPageState extends State<CountryMasteryPage> {
  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didLoad) return;
    _didLoad = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<VisitsProvider>().loadCountryMastery();
    });
  }

  @override
  Widget build(BuildContext context) {
    final visits = context.watch<VisitsProvider>();
    final mastery = visits.countryMastery;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.text('countryMastery')),
      ),
      body: visits.isMasteryLoading && mastery.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : visits.masteryErrorMessage != null && mastery.isEmpty
              ? _MasteryState(
                  icon: Icons.cloud_off_rounded,
                  title: context.l10n.text('countryMasteryLoadFailed'),
                  message: context.l10n.text('countryMasteryLoadFailedMessage'),
                  action: FilledButton.tonalIcon(
                    onPressed: visits.loadCountryMastery,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(context.l10n.text('retry')),
                  ),
                )
              : mastery.isEmpty
                  ? _MasteryState(
                      icon: Icons.workspace_premium_outlined,
                      title: context.l10n.text('countryMasteryEmptyTitle'),
                      message: context.l10n.text('countryMasteryEmptyMessage'),
                    )
                  : RefreshIndicator(
                      onRefresh: visits.loadCountryMastery,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                        children: [
                          _MasteryHero(items: mastery),
                          const SizedBox(height: 22),
                          Text(
                            context.l10n.text('countryMasteryCountries'),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(context.l10n.text('countryMasterySubtitle')),
                          const SizedBox(height: 14),
                          ...mastery.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _CountryMasteryCard(item: item),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _MasteryHero extends StatelessWidget {
  const _MasteryHero({required this.items});

  final List<CountryMastery> items;

  @override
  Widget build(BuildContext context) {
    final completed = items.where((item) => item.isComplete).length;
    final totalCompleted = items.fold<int>(
      0,
      (sum, item) => sum + item.completedCount,
    );
    final totalAvailable = items.fold<int>(
      0,
      (sum, item) => sum + item.totalCount,
    );
    final percent = totalAvailable == 0
        ? 0
        : ((totalCompleted / totalAvailable) * 100).round();

    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primaryContainer,
            scheme.tertiaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium_rounded, size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.text('countryMasteryHeroTitle'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: totalAvailable == 0
                  ? 0
                  : totalCompleted / totalAvailable,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$percent% ${context.l10n.text('countryMasteryOverall')}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _HeroStat(
                value: items.length,
                label: context.l10n.text('countries'),
              ),
              _HeroStat(
                value: completed,
                label: context.l10n.text('countryMasteryCompletedCountries'),
              ),
              _HeroStat(
                value: totalCompleted,
                label: context.l10n.text('countryMasteryDiscoveries'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.value,
    required this.label,
  });

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _CountryMasteryCard extends StatelessWidget {
  const _CountryMasteryCard({required this.item});

  final CountryMastery item;

  String _flag(String code) {
    final normalized = code.trim().toUpperCase();
    if (normalized.length != 2) return '🌍';

    return String.fromCharCodes(
      normalized.codeUnits.map((unit) => unit + 127397),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _flag(item.countryCode),
                  style: const TextStyle(fontSize: 34),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.countryName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        context.l10n.text(item.rankKey),
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: item.isComplete
                        ? scheme.primaryContainer
                        : scheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${item.percent}%',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: item.completion,
                minHeight: 9,
              ),
            ),
            const SizedBox(height: 14),
            _MasteryMetric(
              icon: Icons.location_city_outlined,
              label: context.l10n.text('travelDnaPlaces'),
              completed: item.placeCompleted,
              total: item.placeTotal,
            ),
            const SizedBox(height: 9),
            _MasteryMetric(
              icon: Icons.restaurant_outlined,
              label: context.l10n.text('travelDnaTaste'),
              completed: item.tasteCompleted,
              total: item.tasteTotal,
            ),
            const SizedBox(height: 9),
            _MasteryMetric(
              icon: Icons.museum_outlined,
              label: context.l10n.text('travelDnaCulture'),
              completed: item.cultureCompleted,
              total: item.cultureTotal,
            ),
          ],
        ),
      ),
    );
  }
}

class _MasteryMetric extends StatelessWidget {
  const _MasteryMetric({
    required this.icon,
    required this.label,
    required this.completed,
    required this.total,
  });

  final IconData icon;
  final String label;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final safeCompleted = completed.clamp(0, total < 0 ? 0 : total);

    return Row(
      children: [
        Icon(icon, size: 19),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          '$safeCompleted/$total',
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ],
    );
  }
}

class _MasteryState extends StatelessWidget {
  const _MasteryState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 62),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: 18),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
