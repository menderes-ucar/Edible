import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/error/app_error_presenter.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../travel_share/presentation/services/travel_card_share_service.dart';
import '../../domain/entities/country_visit_badge.dart';
import '../../domain/entities/travel_dna.dart';
import '../../domain/entities/passport_milestone.dart';
import '../../domain/entities/travel_year_summary.dart';
import '../providers/visits_provider.dart';
import '../widgets/travel_dna_share_card.dart';
import '../widgets/year_in_travel_share_card.dart';

class VisitsPage extends StatefulWidget {
  const VisitsPage({super.key});

  @override
  State<VisitsPage> createState() => _VisitsPageState();
}

class _VisitsPageState extends State<VisitsPage> {
  final GlobalKey _yearShareKey = GlobalKey();
  final GlobalKey _dnaShareKey = GlobalKey();
  String? _authIdentity;
  bool _openingMemory = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final auth = context.watch<AuthProvider>();
    final identity = auth.user?.id;

    if (auth.isGuest || identity == null) {
      _authIdentity = null;
      return;
    }

    if (_authIdentity == identity) {
      return;
    }

    _authIdentity = identity;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final currentAuth = context.read<AuthProvider>();
      if (!currentAuth.isAuthenticated ||
          currentAuth.user?.id != identity) {
        return;
      }

      context.read<VisitsProvider>().refresh();
    });
  }


  Future<void> _shareTravelDna() async {
    final dna = context.read<VisitsProvider>().travelDna;
    if (dna == null || !dna.hasData) return;

    final boundary = _dnaShareKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return;

    try {
      await const TravelCardShareService().shareBoundary(
        boundary: boundary,
        fileName: 'edible_travel_dna_${dna.profileKey}',
        shareText:
            '${context.l10n.text('myTravelDna')} • '
            '${context.l10n.text(dna.profileTitleKey)}',
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrorPresenter.message(context, error))),
      );
    }
  }

  Future<void> _shareYearSummary() async {
    final summary = context.read<VisitsProvider>().yearSummary;
    if (summary == null || !summary.hasTravel) return;

    final boundary = _yearShareKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return;

    try {
      await const TravelCardShareService().shareBoundary(
        boundary: boundary,
        fileName: 'edible_year_in_travel_${summary.year}',
        shareText:
            '${summary.year} • ${summary.countryCount} countries • '
            '${summary.cityCount} cities • ${summary.travelDayCount} travel days',
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrorPresenter.message(context, error))),
      );
    }
  }

  Future<void> _openMemory(CountryVisitBadge badge) async {
    if (_openingMemory || badge.latestVisitId.trim().isEmpty) return;

    _openingMemory = true;
    try {
      await context.push(
        AppRoutes.travelMemoryFor(badge.latestVisitId),
      );

      if (!mounted) return;

      final visits = context.read<VisitsProvider>();
      await visits.refresh();

      if (!mounted || !visits.hasError) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppErrorPresenter.message(context, visits.errorMessage),
          ),
        ),
      );
    } finally {
      _openingMemory = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final visits = context.watch<VisitsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.text('visits')),
      ),
      body: auth.isGuest
          ? _GuestState(
              onSignIn: () => context.push(
                AppRoutes.loginFor(AppRoutes.visits),
              ),
            )
          : visits.isLoading && visits.badges.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : visits.hasError && visits.badges.isEmpty
                  ? _ErrorState(onRetry: visits.refresh)
                  : RefreshIndicator(
                      onRefresh: visits.refresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                        children: [
                          _PassportHero(provider: visits),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.tonalIcon(
                                  onPressed: visits.mappableBadges.isEmpty
                                      ? null
                                      : () => context.push(
                                            AppRoutes.visitedWorldMap,
                                          ),
                                  icon: const Icon(Icons.map_outlined),
                                  label: Text(
                                    context.l10n.text('openVisitedWorldMap'),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton.tonalIcon(
                                  onPressed: visits.mappableBadges.isEmpty
                                      ? null
                                      : () => context.push(
                                            AppRoutes.journeyReplay,
                                          ),
                                  icon: const Icon(Icons.play_circle_outline),
                                  label: Text(
                                    context.l10n.text('openJourneyReplay'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: visits.badges.isEmpty
                                  ? null
                                  : () => context.push(
                                        AppRoutes.countryMastery,
                                      ),
                              icon: const Icon(
                                Icons.workspace_premium_outlined,
                              ),
                              label: Text(
                                context.l10n.text('openCountryMastery'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: visits.badges.isEmpty
                                  ? null
                                  : () => context.push(
                                        AppRoutes.countryQuests,
                                      ),
                              icon: const Icon(Icons.explore_outlined),
                              label: Text(
                                context.l10n.text('openCountryQuests'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: visits.badges.isEmpty
                                  ? null
                                  : () => context.push(
                                        AppRoutes.passportTimeline,
                                      ),
                              icon: const Icon(Icons.auto_stories_outlined),
                              label: Text(
                                context.l10n.text('openPassportTimeline'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: visits.badges.isEmpty
                                  ? null
                                  : () => context.push(
                                        AppRoutes.travelCalendar,
                                      ),
                              icon: const Icon(Icons.calendar_month_outlined),
                              label: Text(
                                context.l10n.text('openTravelCalendar'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonalIcon(
                              onPressed: visits.badges.isEmpty
                                  ? null
                                  : () => context.push(
                                        AppRoutes.onThisDay,
                                      ),
                              icon: const Icon(Icons.history_toggle_off_outlined),
                              label: Text(
                                context.l10n.text('openOnThisDay'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: visits.badges.isEmpty
                                  ? null
                                  : () => context.push(
                                        AppRoutes.travelStats,
                                      ),
                              icon: const Icon(Icons.insights_outlined),
                              label: Text(
                                context.l10n.text('openTravelStats'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonalIcon(
                              onPressed: visits.badges.isEmpty
                                  ? null
                                  : () => context.push(
                                        AppRoutes.travelAchievements,
                                      ),
                              icon: const Icon(Icons.workspace_premium_outlined),
                              label: Text(
                                context.l10n.text('openTravelAchievements'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          if (visits.yearSummary != null)
                            _YearInTravelCard(
                              summary: visits.yearSummary!,
                              shareKey: _yearShareKey,
                              onShare: _shareYearSummary,
                            ),
                          if (visits.yearSummary != null)
                            const SizedBox(height: 22),
                          if (visits.travelDna != null)
                            _TravelDnaCard(
                              dna: visits.travelDna!,
                              shareKey: _dnaShareKey,
                              onShare: _shareTravelDna,
                            ),
                          if (visits.travelDna != null)
                            const SizedBox(height: 22),
                          _MilestoneProgressCard(provider: visits),
                          const SizedBox(height: 22),
                          Text(
                            context.l10n.text('passportMilestones'),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.l10n.text('passportMilestonesSubtitle'),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 158,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: VisitsProvider.milestones.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, index) {
                                final milestone =
                                    VisitsProvider.milestones[index];
                                return _MilestoneCard(
                                  milestone: milestone,
                                  countryCount: visits.countryCount,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  context.l10n.text('countryBadges'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                              ),
                              Text(
                                '${visits.unlockedCount}/${visits.countryCount}',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.l10n.text('countryBadgesSubtitle'),
                          ),
                          const SizedBox(height: 14),
                          if (visits.badges.isEmpty)
                            const _EmptyState()
                          else
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final width = constraints.maxWidth;
                                final columns = width >= 850
                                    ? 4
                                    : width >= 560
                                        ? 3
                                        : 2;

                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  itemCount: visits.badges.length,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 0.86,
                                  ),
                                  itemBuilder: (context, index) {
                                    final badge = visits.badges[index];
                                    return _CountryBadgeCard(
                                      badge: badge,
                                      onTap: () => _openMemory(badge),
                                    );
                                  },
                                );
                              },
                            ),
                        ],
                      ),
                    ),
    );
  }
}

class _PassportHero extends StatelessWidget {
  const _PassportHero({required this.provider});

  final VisitsProvider provider;

  @override
  Widget build(BuildContext context) {
    final progress = (provider.completionPercent * 100).round();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.public_rounded, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.text('myWorldPassport'),
                      style:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(context.l10n.text('myWorldPassportSubtitle')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: provider.completionPercent,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$progress% ${context.l10n.text('badgeCollectionComplete')}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _HeroStat(
                value: provider.countryCount,
                label: context.l10n.text('countries'),
              ),
              _HeroStat(
                value: provider.unlockedCount,
                label: context.l10n.text('shiningBadges'),
              ),
              _HeroStat(
                value: provider.totalPhotoCount,
                label: context.l10n.text('travelPhotos'),
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
          const SizedBox(height: 2),
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

class _CountryBadgeCard extends StatelessWidget {
  const _CountryBadgeCard({
    required this.badge,
    required this.onTap,
  });

  final CountryVisitBadge badge;
  final VoidCallback onTap;

  String _flag(String countryCode) {
    final code = countryCode.trim().toUpperCase();
    if (code.length != 2) return '🌍';

    return String.fromCharCodes(
      code.codeUnits.map((unit) => unit + 127397),
    );
  }

  String _date(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = badge.isUnlocked;
    final scheme = Theme.of(context).colorScheme;
    final coverUrl = badge.coverPhotoUrl;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: unlocked
              ? scheme.primary.withValues(alpha: 0.78)
              : scheme.outlineVariant,
          width: unlocked ? 1.8 : 1,
        ),
        boxShadow: unlocked
            ? [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.24),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ]
            : const [],
      ),
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (coverUrl != null && coverUrl.trim().isNotEmpty)
                Image.network(
                  coverUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _BadgeFallback(unlocked: unlocked),
                )
              else
                _BadgeFallback(unlocked: unlocked),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: coverUrl != null && coverUrl.trim().isNotEmpty
                        ? [
                            Colors.black.withValues(alpha: 0.08),
                            Colors.black.withValues(alpha: 0.76),
                          ]
                        : [
                            Colors.transparent,
                            scheme.surface.withValues(alpha: 0.92),
                          ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 43,
                          height: 43,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: scheme.surface.withValues(alpha: 0.88),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: unlocked
                                  ? scheme.primary
                                  : scheme.outlineVariant,
                            ),
                          ),
                          child: Text(
                            _flag(badge.countryCode),
                            style: const TextStyle(fontSize: 25),
                          ),
                        ),
                        const Spacer(),
                        if (unlocked)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 14,
                                  color: scheme.onPrimary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  context.l10n.text('badgeShining'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: scheme.onPrimary,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      badge.countryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: coverUrl != null
                                ? Colors.white
                                : scheme.onSurface,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${badge.cityCount} ${context.l10n.text('cities')} • '
                      '${badge.visitCount} ${context.l10n.text('travelDays')}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: coverUrl != null
                                ? Colors.white.withValues(alpha: 0.88)
                                : scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          unlocked
                              ? Icons.photo_library_outlined
                              : Icons.add_photo_alternate_outlined,
                          size: 16,
                          color: coverUrl != null
                              ? Colors.white
                              : scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            unlocked
                                ? '${badge.photoCount} '
                                    '${context.l10n.text('travelPhotos')}'
                                : context.l10n.text('addPhotoToShine'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: coverUrl != null
                                          ? Colors.white
                                          : scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w800,
                                    ),
                          ),
                        ),
                        Text(
                          _date(badge.lastVisitDay),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: coverUrl != null
                                        ? Colors.white.withValues(alpha: 0.84)
                                        : scheme.onSurfaceVariant,
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
      ),
    );
  }
}

class _BadgeFallback extends StatelessWidget {
  const _BadgeFallback({required this.unlocked});

  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: unlocked
              ? [
                  scheme.primaryContainer,
                  scheme.secondaryContainer,
                ]
              : [
                  scheme.surfaceContainerLow,
                  scheme.surfaceContainerHighest,
                ],
        ),
      ),
      child: Center(
        child: Icon(
          unlocked ? Icons.public_rounded : Icons.lock_outline_rounded,
          size: 56,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.22),
        ),
      ),
    );
  }
}



class _TravelDnaCard extends StatelessWidget {
  const _TravelDnaCard({
    required this.dna,
    required this.shareKey,
    required this.onShare,
  });

  final TravelDna dna;
  final GlobalKey shareKey;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = dna.foodScore + dna.cultureScore + dna.placeScore;
    final safeTotal = total <= 0 ? 1 : total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.text('myTravelDna'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            IconButton.filledTonal(
              tooltip: context.l10n.text('shareTravelDna'),
              onPressed: dna.hasData ? onShare : null,
              icon: const Icon(Icons.ios_share_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                scheme.tertiaryContainer,
                scheme.surfaceContainerLow,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: dna.hasData
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.auto_awesome_rounded),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.text(dna.profileTitleKey),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                context.l10n.text(dna.profileSubtitleKey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _DnaMetric(
                      label: context.l10n.text('travelDnaTaste'),
                      value: dna.foodScore,
                      ratio: dna.foodScore / safeTotal,
                    ),
                    const SizedBox(height: 10),
                    _DnaMetric(
                      label: context.l10n.text('travelDnaCulture'),
                      value: dna.cultureScore,
                      ratio: dna.cultureScore / safeTotal,
                    ),
                    const SizedBox(height: 10),
                    _DnaMetric(
                      label: context.l10n.text('travelDnaPlaces'),
                      value: dna.placeScore,
                      ratio: dna.placeScore / safeTotal,
                    ),
                  ],
                )
              : Text(context.l10n.text('travelDnaEmpty')),
        ),
        Offstage(
          offstage: true,
          child: RepaintBoundary(
            key: shareKey,
            child: SizedBox(
              width: 360,
              child: TravelDnaShareCard(dna: dna),
            ),
          ),
        ),
      ],
    );
  }
}

class _DnaMetric extends StatelessWidget {
  const _DnaMetric({
    required this.label,
    required this.value,
    required this.ratio,
  });

  final String label;
  final int value;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 26,
          child: Text(
            '$value',
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _YearInTravelCard extends StatelessWidget {
  const _YearInTravelCard({
    required this.summary,
    required this.shareKey,
    required this.onShare,
  });

  final TravelYearSummary summary;
  final GlobalKey shareKey;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.text('yearInTravel'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            IconButton.filledTonal(
              tooltip: context.l10n.text('shareYearInTravel'),
              onPressed: summary.hasTravel ? onShare : null,
              icon: const Icon(Icons.ios_share_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: summary.hasTravel
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${summary.year}',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _YearStat(
                          value: summary.countryCount,
                          label: context.l10n.text('countries'),
                        ),
                        _YearStat(
                          value: summary.cityCount,
                          label: context.l10n.text('cities'),
                        ),
                        _YearStat(
                          value: summary.travelDayCount,
                          label: context.l10n.text('travelDays'),
                        ),
                        _YearStat(
                          value: summary.photoCount,
                          label: context.l10n.text('travelPhotos'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${summary.travelStreakYears} '
                            '${context.l10n.text('yearTravelStreak')}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Text(context.l10n.text('yearInTravelEmpty')),
        ),
        Offstage(
          offstage: true,
          child: RepaintBoundary(
            key: shareKey,
            child: SizedBox(
              width: 1080 / 3,
              child: YearInTravelShareCard(summary: summary),
            ),
          ),
        ),
      ],
    );
  }
}

class _YearStat extends StatelessWidget {
  const _YearStat({
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
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _MilestoneProgressCard extends StatelessWidget {
  const _MilestoneProgressCard({
    required this.provider,
  });

  final VisitsProvider provider;

  @override
  Widget build(BuildContext context) {
    final next = provider.nextMilestone;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: next == null
          ? Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.workspace_premium_rounded),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.text('allMilestonesUnlocked'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(context.l10n.text('allMilestonesUnlockedSubtitle')),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flag_circle_rounded),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.l10n.text('nextPassportMilestone'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    Text(
                      '${provider.countryCount}/${next.requiredCountries}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  context.l10n.text(next.titleKey),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: next.progressFor(provider.countryCount),
                    minHeight: 9,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${provider.countriesToNextMilestone} '
                  '${context.l10n.text('countriesToNextMilestone')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({
    required this.milestone,
    required this.countryCount,
  });

  final PassportMilestone milestone;
  final int countryCount;

  @override
  Widget build(BuildContext context) {
    final unlocked = milestone.isUnlockedBy(countryCount);
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 190,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unlocked
            ? scheme.secondaryContainer
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: unlocked
              ? scheme.secondary
              : scheme.outlineVariant,
        ),
        boxShadow: unlocked
            ? [
                BoxShadow(
                  color: scheme.secondary.withValues(alpha: 0.16),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ]
            : const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: unlocked
                      ? scheme.secondary.withValues(alpha: 0.16)
                      : scheme.surfaceContainerHighest,
                ),
                child: Icon(
                  unlocked
                      ? Icons.workspace_premium_rounded
                      : Icons.lock_outline_rounded,
                ),
              ),
              const Spacer(),
              Text(
                '${milestone.requiredCountries}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            context.l10n.text(milestone.titleKey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.text(milestone.subtitleKey),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _GuestState extends StatelessWidget {
  const _GuestState({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return _CenteredState(
      icon: Icons.public_rounded,
      title: context.l10n.text('visits'),
      message: context.l10n.text('visitsLogin'),
      action: FilledButton.icon(
        onPressed: onSignIn,
        icon: const Icon(Icons.login_rounded),
        label: Text(context.l10n.text('signIn')),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return _CenteredState(
      icon: Icons.flight_takeoff_rounded,
      title: context.l10n.text('visitsEmptyTitle'),
      message: context.l10n.text('visitsEmptyMessage'),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return _CenteredState(
      icon: Icons.cloud_off_rounded,
      title: context.l10n.text('visitsLoadFailed'),
      message: context.l10n.text('visitsLoadFailedMessage'),
      action: FilledButton.tonalIcon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: Text(context.l10n.text('retry')),
      ),
    );
  }
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 64),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
              if (action != null) ...[
                const SizedBox(height: 22),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
