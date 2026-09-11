import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/error/app_error_presenter.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/trip_collection.dart';
import '../providers/progress_provider.dart';

class CollectionsPage extends StatefulWidget {
  const CollectionsPage({super.key});

  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage> {
  Future<void> _create() async {
    final draft = await _showCollectionEditor(context);
    if (draft == null || !mounted) return;

    final collection = await context.read<ProgressProvider>().createCollection(
          name: draft.name,
          description: draft.description,
        );

    if (!mounted) return;

    if (collection == null) {
      _showError();
      return;
    }

    context.push(AppRoutes.collectionDetail(collection.id));
  }

  void _showError() {
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
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<ProgressProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.text('collections')),
      ),
      floatingActionButton: auth.isAuthenticated
          ? FloatingActionButton.extended(
              onPressed: provider.isCollectionPending('__create__')
                  ? null
                  : _create,
              icon: provider.isCollectionPending('__create__')
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_rounded),
              label: Text(context.l10n.text('newCollection')),
            )
          : null,
      body: auth.isGuest
          ? _GuestState(
              onSignIn: () => context.push(
                AppRoutes.loginFor(AppRoutes.collections),
              ),
            )
          : provider.isLoading && provider.collections.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : provider.hasError && provider.collections.isEmpty
                  ? _ErrorState(onRetry: provider.refresh)
                  : RefreshIndicator(
                      onRefresh: provider.refresh,
                      child: provider.collections.isEmpty
                          ? const _EmptyState()
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding:
                                  const EdgeInsets.fromLTRB(16, 12, 16, 100),
                              itemCount: provider.collections.length +
                                  (provider.hasError ? 1 : 0),
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                if (provider.hasError && index == 0) {
                                  return _RefreshErrorCard(
                                    message: AppErrorPresenter.message(
                                      context,
                                      provider.errorMessage,
                                    ),
                                    onRetry: provider.refresh,
                                  );
                                }

                                final collectionIndex =
                                    index - (provider.hasError ? 1 : 0);
                                final collection =
                                    provider.collections[collectionIndex];
                                return _CollectionCard(
                                  collection: collection,
                                  pending: provider.isCollectionPending(
                                    collection.id,
                                  ),
                                  onTap: () => context.push(
                                    AppRoutes.collectionDetail(collection.id),
                                  ),
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
  final Future<void> Function() onRetry;

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

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({
    required this.collection,
    required this.pending,
    required this.onTap,
  });

  final TripCollection collection;
  final bool pending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: pending ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                child: const Icon(Icons.bookmarks_rounded),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collection.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    if ((collection.description ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        collection.description!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '${collection.contentIds.length} '
                      '${context.l10n.text('items')}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              pending
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right_rounded),
            ],
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
      icon: Icons.bookmarks_outlined,
      title: context.l10n.text('collections'),
      message: context.l10n.text('collectionsLogin'),
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
      icon: Icons.bookmarks_outlined,
      title: context.l10n.text('collectionsEmptyTitle'),
      message: context.l10n.text('collectionsEmptyMessage'),
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
      title: context.l10n.text('collectionsLoadFailed'),
      message: context.l10n.text('collectionsLoadFailedMessage'),
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

class CollectionEditorDraft {
  const CollectionEditorDraft({
    required this.name,
    required this.description,
  });

  final String name;
  final String? description;
}

Future<CollectionEditorDraft?> showCollectionEditor(
  BuildContext context, {
  TripCollection? collection,
}) {
  return _showCollectionEditor(context, collection: collection);
}

Future<CollectionEditorDraft?> _showCollectionEditor(
  BuildContext context, {
  TripCollection? collection,
}) async {
  final nameController = TextEditingController(text: collection?.name ?? '');
  final descriptionController = TextEditingController(
    text: collection?.description ?? '',
  );

  try {
    return await showDialog<CollectionEditorDraft>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          context.l10n.text(
            collection == null ? 'newCollection' : 'editCollection',
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                maxLength: 100,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: context.l10n.text('collectionName'),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                minLines: 2,
                maxLines: 4,
                maxLength: 300,
                decoration: InputDecoration(
                  labelText: context.l10n.text('collectionDescription'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.text('cancel')),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final description = descriptionController.text.trim();

              Navigator.pop(
                dialogContext,
                CollectionEditorDraft(
                  name: name,
                  description: description.isEmpty ? null : description,
                ),
              );
            },
            child: Text(
              context.l10n.text(collection == null ? 'create' : 'save'),
            ),
          ),
        ],
      ),
    );
  } finally {
    nameController.dispose();
    descriptionController.dispose();
  }
}
