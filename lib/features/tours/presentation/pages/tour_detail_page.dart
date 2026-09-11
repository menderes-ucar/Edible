import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../explore/presentation/widgets/smart_content_image.dart';
import '../../data/datasources/tour_local_data_source.dart';
import '../../data/datasources/tour_remote_data_source.dart';
import '../../data/repositories/tour_repository.dart';
import '../../domain/entities/tour_package.dart';

class TourDetailPage extends StatefulWidget {
  const TourDetailPage({required this.packageId, this.initialPackage, super.key});
  final String packageId;
  final TourPackage? initialPackage;

  @override
  State<TourDetailPage> createState() => _TourDetailPageState();
}

class _TourDetailPageState extends State<TourDetailPage> {
  final _repository = TourRepository();
  TourPackage? _package;
  TourUserState _userState = const TourUserState();
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _package = widget.initialPackage;
    _load();
  }

  Future<void> _load() async {
    try {
      TourPackage? package = _package;

      // The list already passes the selected package through `extra`.
      // Resolve locally first so the detail page never waits on Supabase
      // before it can render the actual tour.
      if (package == null || package.id != widget.packageId) {
        for (final candidate in const TourLocalDataSource().getPackages()) {
          if (candidate.id == widget.packageId) {
            package = candidate;
            break;
          }
        }
      }

      if (package == null) {
        final all = await _repository.getPackages();
        for (final candidate in all) {
          if (candidate.id == widget.packageId) {
            package = candidate;
            break;
          }
        }
      }

      if (package == null) {
        throw StateError('Tour not found: ${widget.packageId}');
      }

      // Render the tour immediately. User progress/favorite state is
      // secondary and must never make a valid tour appear blank/loading.
      _package = package;
      if (mounted) setState(() => _loading = false);

      try {
        final state = await _repository.userState(widget.packageId);
        if (mounted) setState(() => _userState = state);
      } catch (_) {
        // Guest/offline state is valid; the tour itself remains visible.
        if (mounted) setState(() => _userState = const TourUserState());
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '$e';
        });
      }
    }
  }

  Future<bool> _requireAuth() async {
    if (!context.read<AuthProvider>().isGuest) return true;
    context.push(AppRoutes.loginFor(AppRoutes.tourDetailFor(widget.packageId)));
    return false;
  }

  Future<void> _toggleFavorite() async {
    if (!await _requireAuth()) return;
    setState(() => _busy = true);
    try {
      await _repository.favorite(widget.packageId, !_userState.isFavorite);
      _userState = await _repository.userState(widget.packageId);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _start() async {
    if (!await _requireAuth()) return;
    setState(() => _busy = true);
    try {
      await _repository.start(widget.packageId);
      _userState = await _repository.userState(widget.packageId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.text('tourStarted'))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _ratePackage() async {
    if (!await _requireAuth()) return;
    final rating = await _ratingDialog(context, context.l10n.text('ratePackage'));
    if (rating == null) return;
    await _repository.ratePackage(widget.packageId, rating);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.text('ratingSaved'))));
  }

  Future<void> _completeStop(TourStop stop) async {
    if (!await _requireAuth()) return;
    final rating = await _ratingDialog(context, context.l10n.text('rateStop'));
    if (rating == null) return;
    if (_userState.status == null) await _repository.start(widget.packageId);
    await _repository.rateStop(widget.packageId, stop.id, rating, completed: true);
    _userState = await _repository.userState(widget.packageId);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.text('stopCompleted'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF2D2D2D),
        body: Center(child: CircularProgressIndicator(color: AppColors.orangeSoft)),
      );
    }
    final package = _package;
    if (package == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF2D2D2D),
        appBar: AppBar(backgroundColor: const Color(0xFF2D2D2D), foregroundColor: Colors.white),
        body: _ErrorState(message: _error ?? context.l10n.text('noResults'), onRetry: _load),
      );
    }

    final byDay = <int, List<TourStop>>{};
    for (final stop in package.stops) {
      byDay.putIfAbsent(stop.dayIndex, () => <TourStop>[]).add(stop);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF2D2D2D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        foregroundColor: Colors.white,
        title: Text(package.cityName, style: const TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            tooltip: context.l10n.text('favorite'),
            onPressed: _busy ? null : _toggleFavorite,
            icon: Icon(_userState.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.orange,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 36),
          children: [
            _TourHero(package: package),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(package.title, style: const TextStyle(color: Colors.white, fontSize: 25, height: 1.1, fontWeight: FontWeight.w900)),
                const SizedBox(height: 9),
                Text(package.summary, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.45)),
                const SizedBox(height: 16),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _MetaChip(icon: Icons.calendar_month_rounded, label: '${package.days} ${context.l10n.text('days')}'),
                  _MetaChip(icon: Icons.route_rounded, label: '${package.stops.length} ${context.l10n.text('stops')}'),
                  _MetaChip(icon: Icons.star_rounded, label: package.ratingCount == 0 ? '—' : package.ratingAverage.toStringAsFixed(1)),
                ]),
                const SizedBox(height: 18),
                _ProgressCard(package: package, state: _userState),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _start,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(context.l10n.text('startTour')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _ratePackage,
                      icon: const Icon(Icons.star_outline_rounded),
                      label: Text(context.l10n.text('rate')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white30),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 28),
                Row(children: [
                  const Icon(Icons.route_rounded, color: AppColors.orangeSoft, size: 22),
                  const SizedBox(width: 8),
                  Text(context.l10n.text('dayByDayItinerary'), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                ]),
                const SizedBox(height: 14),
                for (final entry in byDay.entries) ...[
                  _DayHeader(day: entry.key + 1, count: entry.value.length),
                  const SizedBox(height: 10),
                  for (final stop in entry.value) ...[
                    _StopCard(package: package, stop: stop, completed: _userState.completedStopIds.contains(stop.id), rating: _userState.stopRatings[stop.id], onCompleted: () => _completeStop(stop)),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 6),
                ],
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _TourHero extends StatelessWidget {
  const _TourHero({required this.package});
  final TourPackage package;
  @override
  Widget build(BuildContext context) => Stack(children: [
    AspectRatio(aspectRatio: 16 / 8.8, child: SmartContentImage(title: package.cityName, locale: Localizations.localeOf(context).languageCode, city: package.cityName, country: package.countryName, preferredUrl: package.coverImageUrl, fit: BoxFit.cover, showAttribution: false)),
    Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: .72)])))),
    Positioned(left: 16, right: 16, bottom: 16, child: Row(children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: AppColors.orangeSoft, borderRadius: BorderRadius.circular(999)), child: Text(package.countryName, style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w900))),
      const Spacer(),
      Text(package.cityName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
    ])),
  ]);
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon; final String label;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8), decoration: BoxDecoration(color: const Color(0xFF3A3A3A), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white12)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: AppColors.orangeSoft), const SizedBox(width: 6), Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12))]));
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.package, required this.state});
  final TourPackage package; final TourUserState state;
  @override
  Widget build(BuildContext context) {
    final progress = package.stops.isEmpty ? 0.0 : (state.completedStopIds.length / package.stops.length).clamp(0.0, 1.0);
    return Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: const Color(0xFF383838), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Icon(Icons.flag_rounded, color: AppColors.orangeSoft, size: 19), const SizedBox(width: 7), Expanded(child: Text(context.l10n.text('travelDays'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))), Text('${state.completedStopIds.length}/${package.stops.length}', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w800))]),
      const SizedBox(height: 10),
      ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: Colors.white12, valueColor: const AlwaysStoppedAnimation(AppColors.orangeSoft))),
    ]));
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.count});
  final int day; final int count;
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 38, height: 38, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.orangeSoft, borderRadius: BorderRadius.circular(13)), child: Text('$day', style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w900))),
    const SizedBox(width: 10),
    Text(context.l10n.text('tourDay').replaceAll('{day}', '$day'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
    const Spacer(), Text('$count', style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w800)),
  ]);
}

class _StopCard extends StatelessWidget {
  const _StopCard({required this.package, required this.stop, required this.completed, required this.rating, required this.onCompleted});
  final TourPackage package; final TourStop stop; final bool completed; final int? rating; final VoidCallback onCompleted;
  @override
  Widget build(BuildContext context) => Card(clipBehavior: Clip.antiAlias, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    AspectRatio(aspectRatio: 16 / 8, child: SmartContentImage(title: stop.title, locale: Localizations.localeOf(context).languageCode, city: package.cityName, country: package.countryName, preferredUrl: stop.imageUrl, fit: BoxFit.cover, showAttribution: false)),
    Padding(padding: const EdgeInsets.fromLTRB(13, 12, 13, 13), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text(stop.title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 17))), if (completed) const Icon(Icons.check_circle_rounded, color: AppColors.success)]),
      const SizedBox(height: 5), Text(stop.subtitle, style: const TextStyle(color: AppColors.textMuted, height: 1.35)),
      const SizedBox(height: 11),
      Align(alignment: Alignment.centerRight, child: FilledButton.tonalIcon(onPressed: onCompleted, icon: Icon(completed ? Icons.star_rounded : Icons.check_rounded), label: Text(completed && rating != null ? '$rating/5' : context.l10n.text('visitedAndRate')))),
    ])),
  ]));
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message; final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.map_outlined, color: AppColors.orangeSoft, size: 48), const SizedBox(height: 12), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)), const SizedBox(height: 16), OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: Text(context.l10n.text('retry')), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white30)))])));
}

Future<int?> _ratingDialog(BuildContext context, String title) => showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(title),
        children: [
          for (var i = 5; i >= 1; i--)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, i),
              child: Row(
                children: [
                  for (var s = 0; s < i; s++) const Icon(Icons.star_rounded),
                  const SizedBox(width: 8),
                  Text('$i/5'),
                ],
              ),
            ),
        ],
      ),
    );

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
