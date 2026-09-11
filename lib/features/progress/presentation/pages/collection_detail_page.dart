import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/error/app_error_presenter.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/app_routes.dart';
import '../../../explore/domain/entities/explore_content.dart';
import '../../../explore/domain/repositories/explore_repository.dart';
import '../../domain/entities/trip_collection.dart';
import '../providers/progress_provider.dart';
import 'collections_page.dart';

class CollectionDetailPage extends StatefulWidget {
  const CollectionDetailPage({
    required this.collectionId,
    super.key,
  });

  final String collectionId;

  @override
  State<CollectionDetailPage> createState() => _CollectionDetailPageState();
}

class _CollectionDetailPageState extends State<CollectionDetailPage> {
  List<ExploreContent>? _contents;
  String? _languageCode;
  String? _loadError;
  int _requestId = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languageCode = Localizations.localeOf(context).languageCode;
    if (_languageCode == languageCode) return;
    _languageCode = languageCode;
    _loadContents(languageCode);
  }

  Future<void> _loadContents(String languageCode) async {
    final requestId = ++_requestId;
    setState(() {
      _loadError = null;
      _contents = null;
    });

    try {
      final all = await context.read<ExploreRepository>().getContents(
            languageCode: languageCode,
          );
      if (!mounted || requestId != _requestId) return;
      setState(() => _contents = all);
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() => _loadError = AppErrorPresenter.message(context, error));
    }
  }

  @override
  void dispose() {
    _requestId++;
    super.dispose();
  }

  Future<void> _edit(TripCollection collection) async {
    final draft = await showCollectionEditor(
      context,
      collection: collection,
    );
    if (draft == null || !mounted) return;

    final ok = await context.read<ProgressProvider>().updateCollection(
          collectionId: collection.id,
          name: draft.name,
          description: draft.description,
        );

    if (!mounted || ok) return;
    _showProviderError();
  }

  Future<void> _delete(TripCollection collection) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(context.l10n.text('deleteCollection')),
            content: Text(context.l10n.text('deleteCollectionConfirmation')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(context.l10n.text('cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(context.l10n.text('delete')),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) return;

    final ok = await context
        .read<ProgressProvider>()
        .deleteCollection(collection.id);

    if (!mounted) return;

    if (ok) {
      context.pop();
    } else {
      _showProviderError();
    }
  }

  void _showProviderError() {
    final error = context.read<ProgressProvider>().errorMessage;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppErrorPresenter.message(context, error),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final collection = progress.collectionById(widget.collectionId);

    if (collection == null) {
      return Scaffold(
        appBar: AppBar(),
        body: progress.isLoading
            ? const Center(child: CircularProgressIndicator())
            : progress.hasError
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppErrorPresenter.message(
                              context,
                              progress.errorMessage,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.tonalIcon(
                            onPressed: progress.refresh,
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(context.l10n.text('retry')),
                          ),
                        ],
                      ),
                    ),
                  )
                : Center(
                    child: Text(context.l10n.text('collectionNotFound')),
                  ),
      );
    }

    final pending = progress.isCollectionPending(collection.id);
    final allContents = _contents;
    final selectedContents = allContents == null
        ? const <ExploreContent>[]
        : allContents
            .where((item) => collection.contentIds.contains(item.id))
            .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(collection.name),
        actions: [
          IconButton(
            tooltip: context.l10n.text('editCollection'),
            onPressed: pending ? null : () => _edit(collection),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: context.l10n.text('deleteCollection'),
            onPressed: pending ? null : () => _delete(collection),
            icon: pending
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadContents(
          _languageCode ?? Localizations.localeOf(context).languageCode,
        ),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _CollectionHeader(collection: collection),
            const SizedBox(height: 22),
            Text(
              context.l10n.text('savedDiscoveries'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 10),
            if (_loadError != null)
              _InlineError(
                onRetry: () => _loadContents(
                  _languageCode ??
                      Localizations.localeOf(context).languageCode,
                ),
              )
            else if (_contents == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (selectedContents.isEmpty)
              _CollectionEmpty(
                onExplore: () => context.go(AppRoutes.home),
              )
            else
              ...selectedContents.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ContentCard(
                    item: item,
                    onOpen: () => context.push(
                      AppRoutes.contentDetail(item.id),
                      extra: item,
                    ),
                    onRemove: () async {
                      final ok = await progress.toggleCollectionItem(
                        collectionId: collection.id,
                        contentId: item.id,
                      );
                      if (!context.mounted || ok) return;
                      _showProviderError();
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CollectionHeader extends StatelessWidget {
  const _CollectionHeader({required this.collection});
  final TripCollection collection;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bookmarks_rounded, size: 34),
          const SizedBox(height: 14),
          Text(
            collection.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          if ((collection.description ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(collection.description!.trim()),
          ],
          const SizedBox(height: 14),
          Text(
            '${collection.contentIds.length} ${context.l10n.text('items')}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({
    required this.item,
    required this.onOpen,
    required this.onRemove,
  });

  final ExploreContent item;
  final VoidCallback onOpen;
  final Future<void> Function() onRemove;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.allImageUrls.isEmpty ? null : item.allImageUrls.first;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Row(
          children: [
            SizedBox(
              width: 104,
              height: 104,
              child: imageUrl == null
                  ? const ColoredBox(
                      color: Colors.black12,
                      child: Icon(Icons.image_outlined),
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Colors.black12,
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.locationLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: context.l10n.text('removeFromCollection'),
              onPressed: onRemove,
              icon: const Icon(Icons.remove_circle_outline_rounded),
            ),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}

class _CollectionEmpty extends StatelessWidget {
  const _CollectionEmpty({required this.onExplore});
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.bookmark_add_outlined, size: 56),
          const SizedBox(height: 14),
          Text(
            context.l10n.text('collectionEmptyTitle'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.text('collectionEmptyMessage'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onExplore,
            icon: const Icon(Icons.explore_outlined),
            label: Text(context.l10n.text('discover')),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 44),
          const SizedBox(height: 10),
          Text(context.l10n.text('collectionsLoadFailedMessage')),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(context.l10n.text('retry')),
          ),
        ],
      ),
    );
  }
}
