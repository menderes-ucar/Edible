import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/error/app_error_presenter.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../explore/domain/entities/explore_content.dart';
import '../../../explore/domain/repositories/explore_repository.dart';
import '../../../travel_history/domain/entities/travel_visit.dart';
import '../../../travel_history/presentation/providers/travel_history_provider.dart';
import '../../../travel_share/presentation/services/travel_card_share_service.dart';
import '../../../travel_share/presentation/widgets/passport_share_card_widget.dart';
import '../../domain/entities/travel_badge.dart';
import '../../domain/usecases/calculate_discovery_progress.dart';
import '../providers/progress_provider.dart';

class PassportPage extends StatefulWidget {
  const PassportPage({super.key});

  @override
  State<PassportPage> createState() => _PassportPageState();
}

class _PassportPageState extends State<PassportPage> {
  final _passportShareKey = GlobalKey();
  List<ExploreContent>? _contents;
  String? _languageCode;
  String? _authIdentity;
  String? _loadError;
  int _loadGeneration = 0;
  bool _isSharing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final auth = context.watch<AuthProvider>();
    final languageCode = Localizations.localeOf(context).languageCode;
    final identity = auth.user?.id;

    if (auth.isGuest || identity == null) {
      if (_authIdentity != null) {
        _loadGeneration++;
        _contents = null;
        _loadError = null;
      }
      _authIdentity = null;
      _languageCode = languageCode;
      return;
    }

    if (_languageCode == languageCode && _authIdentity == identity) {
      return;
    }

    _languageCode = languageCode;
    _authIdentity = identity;
    _contents = null;
    _loadError = null;

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _load(
        languageCode: languageCode,
        identity: identity,
      ),
    );
  }

  Future<void> _sharePassport() async {
    if (_isSharing) {
      return;
    }

    final boundary = _passportShareKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) {
      return;
    }

    setState(() => _isSharing = true);

    try {
      await const TravelCardShareService().shareBoundary(
        boundary: boundary,
        fileName: 'edible_passport',
        shareText: 'My Edible Passport',
      );
    } catch (error) {
      if (!mounted) {
      return;
    }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppErrorPresenter.message(context, error),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<void> _load({
    required String languageCode,
    required String identity,
  }) async {
    final generation = ++_loadGeneration;

    if (mounted) {
      setState(() => _loadError = null);
    }

    try {
      await context.read<TravelHistoryProvider>().refresh();

      final all = await context.read<ExploreRepository>().getContents(
            languageCode: languageCode,
          );

      if (!mounted ||
          generation != _loadGeneration ||
          _languageCode != languageCode ||
          _authIdentity != identity ||
          context.read<AuthProvider>().user?.id != identity) {
        return;
      }

      setState(() {
        _contents = all;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted ||
          generation != _loadGeneration ||
          _languageCode != languageCode ||
          _authIdentity != identity ||
          context.read<AuthProvider>().user?.id != identity) {
        return;
      }

      setState(() {
        _loadError = AppErrorPresenter.message(context, error);
      });
    }
  }

  @override
  void dispose() {
    _loadGeneration++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final progress = context.watch<ProgressProvider>();
    final travelHistory = context.watch<TravelHistoryProvider>();

    if (auth.isGuest) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.text('passport'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.text('passportLogin'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => context.push(
                    AppRoutes.loginFor(AppRoutes.passport),
                  ),
                  icon: const Icon(Icons.login_rounded),
                  label: Text(context.l10n.text('signIn')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final contents = _contents;
    if (contents == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.text('passport'))),
        body: _loadError == null
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: 42),
                      const SizedBox(height: 12),
                      Text(
                        _loadError!,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.tonalIcon(
                        onPressed: () {
                          final identity =
                              context.read<AuthProvider>().user?.id;
                          if (identity == null) {
                            return;
                          }

                          _load(
                            languageCode:
                                Localizations.localeOf(context).languageCode,
                            identity: identity,
                          );
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(context.l10n.text('retry')),
                      ),
                    ],
                  ),
                ),
              ),
      );
    }

    final visitedContents = contents
        .where((item) => progress.isVisited(item.id))
        .toList(growable: false);

    final countries = <String>{
      ...visitedContents.map((item) => item.countryName),
      ...travelHistory.visits.map((visit) => visit.countryName),
    }.toList(growable: false)
      ..sort();

    final cities = <String>{
      ...visitedContents.map((item) => item.cityName),
      ...travelHistory.visits.map((visit) => visit.cityName),
    }.toList(growable: false)
      ..sort();

    const calculator = CalculateDiscoveryProgress();
    final worldStats = calculator.forContents(
      contents: contents,
      visitedIds: progress.visitedIds,
      triedIds: progress.triedIds,
    );
    final badges = calculator.badges(
      allContents: contents,
      visitedIds: progress.visitedIds,
      triedIds: progress.triedIds,
    );
    final unlockedCount = badges.where((badge) => badge.unlocked).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.text('passport')),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await progress.refresh();
          await travelHistory.refresh();
          final identity = context.read<AuthProvider>().user?.id;
          if (identity == null) {
            return;
          }

          await _load(
            languageCode: Localizations.localeOf(context).languageCode,
            identity: identity,
          );
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
          children: [
            _PassportHeader(
              countryCount: countries.length,
              cityCount: cities.length,
              visitedCount: progress.visitedCount,
              triedCount: progress.triedCount,
              progressPercent: worldStats.percent,
            ),
            const SizedBox(height: 20),
            _DiscoveryProgressCard(
              title: context.l10n.text('worldDiscovery'),
              completed: worldStats.completed,
              total: worldStats.total,
              percent: worldStats.percent,
            ),
            const SizedBox(height: 26),
            _SectionTitle(
              title: context.l10n.text('badges'),
              trailing: '$unlockedCount/${badges.length}',
            ),
            const SizedBox(height: 12),
            ...badges.map((badge) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _BadgeCard(badge: badge),
                )),
            const SizedBox(height: 20),
            _TravelHistorySummaryCard(
              visits: travelHistory.visits,
            ),
            const SizedBox(height: 14),
            RepaintBoundary(
              key: _passportShareKey,
              child: PassportShareCardWidget(
                travelDays: travelHistory.travelDayCount,
                countries: travelHistory.countryCount,
                cities: travelHistory.cityCount,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: travelHistory.visits.isEmpty || _isSharing
                  ? null
                  : _sharePassport,
              icon: _isSharing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.ios_share_outlined),
              label: Text(context.l10n.text('sharePassport')),
            ),
            const SizedBox(height: 24),
            _SectionTitle(
              title: context.l10n.text('travelTimeline'),
              trailing: '${travelHistory.travelDayCount}',
            ),
            const SizedBox(height: 10),
            if (travelHistory.isLoading && travelHistory.visits.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (travelHistory.visits.isEmpty)
              Text(context.l10n.text('travelHistoryEmpty'))
            else
              ...travelHistory.visits.take(20).map(
                    (visit) => _TravelVisitTile(visit: visit),
                  ),
            const SizedBox(height: 20),
            _SectionTitle(title: context.l10n.text('visitedCountries')),
            const SizedBox(height: 10),
            if (countries.isEmpty)
              Text(context.l10n.text('passportEmpty'))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: countries
                    .map(
                      (country) => Chip(
                        avatar: const Icon(Icons.public, size: 17),
                        label: Text(country),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 24),
            _SectionTitle(title: context.l10n.text('visitedCities')),
            const SizedBox(height: 10),
            if (cities.isEmpty)
              Text(context.l10n.text('passportEmpty'))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: cities
                    .map(
                      (city) => Chip(
                        avatar: const Icon(Icons.location_city, size: 17),
                        label: Text(city),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _PassportHeader extends StatelessWidget {
  const _PassportHeader({
    required this.countryCount,
    required this.cityCount,
    required this.visitedCount,
    required this.triedCount,
    required this.progressPercent,
  });

  final int countryCount;
  final int cityCount;
  final int visitedCount;
  final int triedCount;
  final int progressPercent;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  child: Text(
                    '$progressPercent%',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.text('travelPassport'),
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(context.l10n.text('passportSubtitle')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                _Stat(
                  value: countryCount,
                  label: context.l10n.text('countries'),
                ),
                _Stat(
                  value: cityCount,
                  label: context.l10n.text('cities'),
                ),
                _Stat(
                  value: visitedCount,
                  label: context.l10n.text('visited'),
                ),
                _Stat(
                  value: triedCount,
                  label: context.l10n.text('tried'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class _TravelHistorySummaryCard extends StatelessWidget {
  const _TravelHistorySummaryCard({
    required this.visits,
  });

  final List<TravelVisit> visits;

  @override
  Widget build(BuildContext context) {
    final countries = visits
        .map((visit) => visit.countryCode.toUpperCase())
        .toSet()
        .length;

    final cities = visits
        .map(
          (visit) =>
              '${visit.countryCode.toUpperCase()}|${visit.cityName.toLowerCase()}',
        )
        .toSet()
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.l10n.text('automaticPassport'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(context.l10n.text('automaticPassportSubtitle')),
            const SizedBox(height: 16),
            Row(
              children: [
                _HistoryStat(
                  value: visits.length,
                  label: context.l10n.text('travelDays'),
                ),
                _HistoryStat(
                  value: countries,
                  label: context.l10n.text('countries'),
                ),
                _HistoryStat(
                  value: cities,
                  label: context.l10n.text('cities'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryStat extends StatelessWidget {
  const _HistoryStat({
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
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

class _TravelVisitTile extends StatelessWidget {
  const _TravelVisitTile({
    required this.visit,
  });

  final TravelVisit visit;

  String _date(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String _flag(String countryCode) {
    final code = countryCode.trim().toUpperCase();
    if (code.length != 2) return '🌍';

    return String.fromCharCodes(
      code.codeUnits.map((unit) => unit + 127397),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(_flag(visit.countryCode)),
        ),
        title: Text(
          visit.cityName,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${visit.countryName} • ${_date(visit.visitDay)}\n'
          '${context.l10n.text('openTripMemory')}',
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (visit.detectionCount > 1)
              Tooltip(
                message: context.l10n.text('arrivalDetections'),
                child: Chip(
                  label: Text('×${visit.detectionCount}'),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => context.push(
          AppRoutes.travelMemoryFor(visit.id),
        ),
      ),
    );
  }
}

class _DiscoveryProgressCard extends StatelessWidget {
  const _DiscoveryProgressCard({
    required this.title,
    required this.completed,
    required this.total,
    required this.percent,
  });

  final String title;
  final int completed;
  final int total;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                Text(
                  '$percent%',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: total == 0 ? 0 : completed / total,
              minHeight: 10,
              borderRadius: BorderRadius.circular(99),
            ),
            const SizedBox(height: 8),
            Text(
              '$completed / $total ${context.l10n.text('discoveriesCompleted')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.badge});

  final TravelBadge badge;

  @override
  Widget build(BuildContext context) {
    final icon = switch (badge.iconName) {
      'city' => Icons.location_city,
      'world' => Icons.public,
      'food' => Icons.ramen_dining,
      'culture' => Icons.museum_outlined,
      'restaurant' => Icons.restaurant,
      _ => Icons.directions_walk,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              child: Icon(
                badge.unlocked ? icon : Icons.lock_outline,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.l10n.text(badge.titleKey),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      if (badge.unlocked)
                        const Icon(Icons.verified, size: 20),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    context.l10n.text(badge.descriptionKey),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 9),
                  LinearProgressIndicator(
                    value: badge.progress,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    badge.unlocked
                        ? context.l10n.text('unlocked')
                        : '${badge.current}/${badge.target}',
                    style: Theme.of(context).textTheme.labelSmall,
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
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: Theme.of(context).textTheme.titleMedium,
          ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
