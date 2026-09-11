import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/error/app_error_presenter.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../explore/domain/entities/explore_content.dart';
import '../providers/favorites_provider.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  String? _languageCode;
  String? _authIdentity;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final auth = context.watch<AuthProvider>();
    final languageCode = Localizations.localeOf(context).languageCode;
    final identity = auth.user?.id;

    if (auth.isGuest || identity == null) {
      _languageCode = languageCode;
      _authIdentity = null;
      return;
    }

    if (_languageCode == languageCode && _authIdentity == identity) return;

    _languageCode = languageCode;
    _authIdentity = identity;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final currentAuth = context.read<AuthProvider>();
      if (!currentAuth.isAuthenticated ||
          currentAuth.user?.id != identity) {
        return;
      }

      context.read<FavoritesProvider>().ensureLoaded(
            languageCode: languageCode,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final favorites = context.watch<FavoritesProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.text('favorites'))),
      body: auth.isGuest
          ? _GuestState(
              onSignIn: () => context.push(
                AppRoutes.loginFor(AppRoutes.favorites),
              ),
            )
          : favorites.isLoading && favorites.items.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : favorites.errorMessage != null && favorites.items.isEmpty
                  ? _ErrorState(
                      onRetry: () => favorites.refresh(
                        languageCode: _languageCode ??
                            Localizations.localeOf(context).languageCode,
                      ),
                    )
                  : favorites.items.isEmpty
                      ? const _EmptyState()
                      : RefreshIndicator(
                          onRefresh: () => favorites.refresh(
                            languageCode: _languageCode ??
                                Localizations.localeOf(context).languageCode,
                          ),
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                            itemCount: favorites.items.length +
                                (favorites.errorMessage != null ? 1 : 0),
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              if (favorites.errorMessage != null &&
                                  index == 0) {
                                return _RefreshErrorCard(
                                  message: AppErrorPresenter.message(
                                    context,
                                    favorites.errorMessage,
                                  ),
                                  onRetry: () => favorites.refresh(
                                    languageCode: _languageCode ??
                                        Localizations.localeOf(context)
                                            .languageCode,
                                  ),
                                );
                              }

                              final itemIndex =
                                  index - (favorites.errorMessage != null ? 1 : 0);
                              final item = favorites.items[itemIndex];
                              return _FavoriteCard(
                                item: item,
                                pending: favorites.isPending(item.id),
                                onOpen: () => context.push(
                                  AppRoutes.contentDetail(item.id),
                                  extra: item,
                                ),
                                onRemove: () async {
                                  final ok = await favorites.toggle(item);
                                  if (!context.mounted || ok) return;

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppErrorPresenter.message(
                                          context,
                                          favorites.errorMessage ??
                                              'favorite_update_failed',
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
    );
  }
}

class _RefreshErrorCard extends StatelessWidget {
  const _RefreshErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Row(
          children: [
            Icon(
              Icons.sync_problem_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: Text(context.l10n.text('retry')),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.item,
    required this.pending,
    required this.onOpen,
    required this.onRemove,
  });

  final ExploreContent item;
  final bool pending;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.allImageUrls.isEmpty ? null : item.allImageUrls.first;

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: SizedBox(
          height: 118,
          child: Row(
            children: [
              SizedBox(
                width: 118,
                height: double.infinity,
                child: imageUrl == null
                    ? _ImageFallback(countryCode: item.countryCode)
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _ImageFallback(countryCode: item.countryCode),
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 17),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.locationLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton.filledTonal(
                  tooltip: context.l10n.text('removeFavorite'),
                  onPressed: pending ? null : onRemove,
                  icon: pending
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.favorite_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.countryCode});
  final String countryCode;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Text(
          countryCode,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
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
      icon: Icons.favorite_border_rounded,
      title: context.l10n.text('favorites'),
      message: context.l10n.text('favoritesLogin'),
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
      icon: Icons.favorite_border_rounded,
      title: context.l10n.text('favoritesEmptyTitle'),
      message: context.l10n.text('favoritesEmptyMessage'),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _CenteredState(
      icon: Icons.cloud_off_rounded,
      title: context.l10n.text('favoritesLoadFailed'),
      message: context.l10n.text('favoritesLoadFailedMessage'),
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
                style: Theme.of(context).textTheme.bodyLarge,
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
