
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../../progress/domain/entities/content_progress.dart';
import '../../../progress/presentation/providers/progress_provider.dart';
import '../../../location/presentation/providers/location_provider.dart';
import '../../../location/presentation/widgets/location_failure_snackbar.dart';
import '../../../location/domain/usecases/verify_check_in.dart';
import '../../../../core/services/location_service.dart';
import '../../../food/domain/entities/food_details.dart';
import '../../../food/domain/repositories/food_repository.dart';
import '../../../food/presentation/widgets/food_intelligence_section.dart';
import '../../domain/entities/explore_content.dart';
import '../../domain/entities/explore_metadata.dart';
import '../../domain/repositories/explore_repository.dart';
import '../../data/services/content_description_resolver.dart';

import '../widgets/smart_content_image.dart';
import '../widgets/content_rating_card.dart';
class ContentDetailPage extends StatefulWidget {
  const ContentDetailPage({
    required this.contentId,
    this.initialContent,
    super.key,
  });

  final String contentId;
  final ExploreContent? initialContent;

  @override
  State<ContentDetailPage> createState() => _ContentDetailPageState();
}

class _ContentDetailPageState extends State<ContentDetailPage> {
  ExploreContent? _content;
  bool _loading = false;
  FoodDetails? _foodDetails;
  String? _foodLanguageCode;
  String? _favoritesLanguageCode;
  String? _descriptionLanguageCode;
  String? _resolvedShortDescription;
  String? _resolvedDescription;
  String? _descriptionSource;
  String? _descriptionSourceUrl;

  @override
  void initState() {
    super.initState();
    _content = widget.initialContent;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_content == null && !_loading) _load();

    final languageCode = Localizations.localeOf(context).languageCode;

    if (_favoritesLanguageCode != languageCode) {
      _favoritesLanguageCode = languageCode;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<FavoritesProvider>().refresh(
              languageCode: languageCode,
            );
      });
    }

    final content = _content;
    if (content != null &&
        _descriptionLanguageCode != languageCode &&
        _needsResolvedDescription(content)) {
      _descriptionLanguageCode = languageCode;
      _loadDescription(content, languageCode);
    }

    if (content != null &&
        _isFoodContent(content) &&
        _foodLanguageCode != languageCode) {
      _foodLanguageCode = languageCode;
      _loadFoodDetails(content, languageCode);
    }
  }

  bool _needsResolvedDescription(ExploreContent content) {
    final text = content.description.trim().toLowerCase();
    if (text.isEmpty) return true;
    const genericFragments = [
      'kategori bazlı yerel keşif noktası',
      'yerel deneyim kataloğu',
      'öne çıkan ziyaret noktalarındandır',
      'seyahatinde öne çıkan ziyaret noktalarındandır',
      'local discovery point',
      'local experience catalog',
      'featured travel stop',
      'travel destination',
    ];
    return genericFragments.any(text.contains) || text.length < 140;
  }

  bool _isFoodContent(ExploreContent content) {
    final category = content.category.name;
    return category == 'food' ||
        category == 'snack' ||
        category == 'fruit' ||
        category == 'drink';
  }

  Future<void> _loadDescription(
    ExploreContent content,
    String languageCode,
  ) async {
    final result = await ContentDescriptionResolver.instance.resolve(
      title: content.title,
      locale: languageCode,
      city: content.cityName,
      country: content.countryName,
      category: content.category.value,
    );

    if (!mounted || result == null) return;
    setState(() {
      _resolvedShortDescription = result.shortDescription.isNotEmpty
          ? result.shortDescription
          : result.description;
      _resolvedDescription = result.description;
      _descriptionSource = result.source;
      _descriptionSourceUrl = result.sourceUrl;
    });
  }

  Future<void> _loadFoodDetails(
    ExploreContent content,
    String languageCode,
  ) async {
    final details = await context.read<FoodRepository>().getByContentId(
          contentId: content.id,
          languageCode: languageCode,
        );

    if (!mounted) return;
    setState(() => _foodDetails = details);
  }

  Future<void> _load() async {
    _loading = true;

    final content = await context.read<ExploreRepository>().getById(
          id: widget.contentId,
          languageCode: Localizations.localeOf(context).languageCode,
        );

    if (!mounted) return;

    setState(() {
      _content = content;
      _loading = false;
    });

    if (content != null && _needsResolvedDescription(content)) {
      final languageCode = Localizations.localeOf(context).languageCode;
      _descriptionLanguageCode = languageCode;
      await _loadDescription(content, languageCode);
    }

    if (content != null && _isFoodContent(content)) {
      final languageCode = Localizations.localeOf(context).languageCode;
      _foodLanguageCode = languageCode;
      await _loadFoodDetails(content, languageCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _content;

    if (content == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: _loading
              ? const CircularProgressIndicator()
              : Text(context.l10n.text('loadError')),
        ),
      );
    }

    final favorites = context.watch<FavoritesProvider>();
    final progress = context.watch<ProgressProvider>();
    final isFavorite = favorites.isFavorite(content.id);
    final isVisited = progress.isVisited(content.id);
    final isTried = progress.isTried(content.id);
    final images = content.allImageUrls;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            expandedHeight: 310,
            pinned: true,
            actions: [
              IconButton.filledTonal(
                tooltip: isFavorite
                    ? context.l10n.text('saved')
                    : context.l10n.text('save'),
                onPressed: favorites.isPending(content.id)
                    ? null
                    : () async {
                  final auth = context.read<AuthProvider>();
                  if (auth.isGuest) {
                    context.push(AppRoutes.login);
                    return;
                  }

                  final ok = await favorites.toggle(content);
                  if (!context.mounted || ok) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.l10n.text('favoriteUpdateFailed'),
                      ),
                    ),
                  );
                },
                icon: favorites.isPending(content.id)
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                      ),
              ),
              const SizedBox(width: 10),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: SmartContentImage(
                title: content.title,
                locale: Localizations.localeOf(context).languageCode,
                city: content.cityName,
                country: content.countryName,
                category: content.category.value,
                preferredUrl: images.isEmpty ? null : images.first,
                showAttribution: true,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  Text(
                    content.title,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.location_city, size: 17),
                        label: Text(content.cityName),
                        onPressed: () => context.push(
                          AppRoutes.cityDetail(
                            countryCode: content.countryCode,
                            cityName: content.cityName,
                          ),
                        ),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.public, size: 17),
                        label: Text(content.countryName),
                        onPressed: () => context.push(
                          AppRoutes.countryDetail(content.countryCode),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (!content.metadata.hasExactCoordinates) ...[
                    _CoordinateTruthNotice(
                      message: context.l10n.text('approximateLocationNotice'),
                    ),
                    const SizedBox(height: 14),
                  ],
                  _PrimaryActionPanel(
                    isFavorite: isFavorite,
                    favoritePending: favorites.isPending(content.id),
                    isVisited: isVisited,
                    isTried: isTried,
                    visitedPending: progress.isProgressPending(
                      contentId: content.id,
                      type: ContentProgressType.visited,
                    ),
                    triedPending: progress.isProgressPending(
                      contentId: content.id,
                      type: ContentProgressType.tried,
                    ),
                    onFavorite: () async {
                      final auth = context.read<AuthProvider>();
                      if (auth.isGuest) {
                        context.push(AppRoutes.login);
                        return;
                      }
                      final ok = await favorites.toggle(content);
                      if (!context.mounted || ok) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            context.l10n.text('favoriteUpdateFailed'),
                          ),
                        ),
                      );
                    },
                    onVisited: () async {
                      if (context.read<AuthProvider>().isGuest) {
                        context.push(AppRoutes.login);
                        return;
                      }
                      final ok = await progress.toggleVisited(content.id);
                      if (!context.mounted || ok) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            context.l10n.text('progressUpdateFailed'),
                          ),
                        ),
                      );
                    },
                    onTried: () async {
                      if (context.read<AuthProvider>().isGuest) {
                        context.push(AppRoutes.login);
                        return;
                      }
                      final ok = await progress.toggleTried(content.id);
                      if (!context.mounted || ok) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            context.l10n.text('progressUpdateFailed'),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.my_location, size: 18),
                        label: Text(context.l10n.text('checkIn')),
                        onPressed: () async {
                          final auth = context.read<AuthProvider>();
                          if (auth.isGuest) {
                            context.push(AppRoutes.login);
                            return;
                          }

                          final location = context.read<LocationProvider>();
                          if (!location.hasLocation) {
                            final located = await location.locate();
                            if (!context.mounted) return;

                            if (!located || !location.hasLocation) {
                              await showLocationFailureSnackBar(
                                context,
                                location,
                              );
                              return;
                            }
                          }

                          if (!context.mounted ||
                              location.latitude == null ||
                              location.longitude == null) {
                            return;
                          }

                          final verifier = VerifyCheckIn(
                            distanceCalculator:
                                context.read<LocationService>().distanceMeters,
                          );

                          final result = verifier(
                            userLatitude: location.latitude!,
                            userLongitude: location.longitude!,
                            contentLatitude: content.latitude,
                            contentLongitude: content.longitude,
                          );

                          if (!context.mounted) return;

                          if (!result.allowed) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${context.l10n.text('checkInTooFar')} '
                                  '${result.distanceMeters.round()} m',
                                ),
                              ),
                            );
                            return;
                          }

                          if (!progress.isVisited(content.id)) {
                            final ok = await progress.toggleVisited(content.id);
                            if (!context.mounted) return;

                            if (!ok) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    context.l10n.text('progressUpdateFailed'),
                                  ),
                                ),
                              );
                              return;
                            }
                          }

                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.l10n.text('checkInSuccess')),
                            ),
                          );
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.playlist_add, size: 18),
                        label: Text(context.l10n.text('addToCollection')),
                        onPressed: () {
                          if (context.read<AuthProvider>().isGuest) {
                            context.push(AppRoutes.login);
                            return;
                          }
                          showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (sheetContext) {
                            final state = sheetContext.watch<ProgressProvider>();
                            return SafeArea(child: ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(16,4,16,24), children: [
                              Text(context.l10n.text('collections'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                              const SizedBox(height: 12),
                              if (state.collections.isEmpty) Padding(padding: const EdgeInsets.all(16), child: Text(context.l10n.text('collectionsEmpty'))),
                              ...state.collections.map((collection) => CheckboxListTile(value: collection.contentIds.contains(content.id), title: Text(collection.name), onChanged: (_) => sheetContext.read<ProgressProvider>().toggleCollectionItem(collectionId: collection.id, contentId: content.id))),
                              const SizedBox(height: 8),
                              FilledButton.icon(onPressed: () { Navigator.pop(sheetContext); context.push(AppRoutes.collections); }, icon: const Icon(Icons.add), label: Text(context.l10n.text('manageCollections'))),
                            ]));
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(
                        AppRoutes.cityMapFor(
                          countryCode: content.countryCode,
                          cityName: content.cityName,
                          contentId: content.id,
                        ),
                      ),
                      icon: const Icon(Icons.map_outlined),
                      label: Text(context.l10n.text('showOnMap')),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SummaryCard(
                    categoryLabel:
                        context.l10n.text(content.category.localizationKey),
                    description: (_resolvedShortDescription?.trim().isNotEmpty == true)
                        ? _resolvedShortDescription!
                        : content.shortDescription,
                  ),
                  const SizedBox(height: 14),
                  ContentRatingCard(
                    contentId: content.id,
                    isVisited: isVisited,
                  ),
                  if (images.length > 1) ...[
                    const SizedBox(height: 26),
                    _SectionHeader(
                      title: context.l10n.text('gallery'),
                      trailing: '${images.length}',
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 150,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.skip(1).length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final image = images.skip(1).elementAt(index);
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: SizedBox(
                              width: 210,
                              child: Image.network(
                                image,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  child: const Icon(
                                    Icons.travel_explore_rounded,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  _SectionHeader(
                    title: context.l10n.text('about'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (_resolvedDescription?.trim().isNotEmpty == true)
                        ? _resolvedDescription!
                        : content.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          height: 1.55,
                        ),
                  ),
                  if ((_descriptionSource?.trim().isNotEmpty == true) &&
                      (_descriptionSourceUrl?.trim().isNotEmpty == true)) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${_descriptionSource!} • Kaynak: ${_descriptionSourceUrl!}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                  if (_foodDetails != null && !_foodDetails!.isEmpty) ...[
                    const SizedBox(height: 30),
                    FoodIntelligenceSection(details: _foodDetails!),
                  ],
                  if (!content.metadata.isEmpty) ...[
                    const SizedBox(height: 30),
                    _MetadataSection(metadata: content.metadata),
                  ],
                  if (content.tags.isNotEmpty) ...[
                    const SizedBox(height: 30),
                    _SectionHeader(
                      title: context.l10n.text('tags'),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: content.tags
                          .map((tag) => Chip(label: Text(tag)))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({
    required this.imageUrl,
    required this.countryCode,
  });

  final String? imageUrl;
  final String countryCode;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();

    if (url == null || url.isEmpty) {
      return Container(
        color: Theme.of(context).colorScheme.primaryContainer,
        alignment: Alignment.center,
        child: Text(
          countryCode,
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Theme.of(context).colorScheme.primaryContainer,
            alignment: Alignment.center,
            child: Icon(
              Icons.travel_explore_rounded,
              size: 60,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black26, Colors.transparent, Colors.black38],
            ),
          ),
        ),
      ],
    );
  }
}

class _MetadataSection extends StatelessWidget {
  const _MetadataSection({required this.metadata});

  final ExploreMetadata metadata;

  @override
  Widget build(BuildContext context) {
    final items = <_MetadataItem>[];

    if (metadata.priceLevel != null) {
      items.add(
        _MetadataItem(
          icon: Icons.payments_outlined,
          label: context.l10n.text('priceLevel'),
          value: List.filled(metadata.priceLevel!, '\$').join(),
        ),
      );
    }

    if (metadata.bestTime != null) {
      items.add(_MetadataItem(
        icon: Icons.schedule,
        label: context.l10n.text('bestTime'),
        value: metadata.bestTime!,
      ));
    }

    if (metadata.openingInfo != null) {
      items.add(_MetadataItem(
        icon: Icons.access_time,
        label: context.l10n.text('openingInfo'),
        value: metadata.openingInfo!,
      ));
    }

    if (metadata.estimatedVisitMinutes != null) {
      items.add(_MetadataItem(
        icon: Icons.timelapse,
        label: context.l10n.text('visitDuration'),
        value:
            '${metadata.estimatedVisitMinutes} ${context.l10n.text('minutes')}',
      ));
    }

    if (metadata.vegetarian != null) {
      items.add(_yesNo(context, Icons.eco_outlined, 'vegetarian',
          metadata.vegetarian!));
    }
    if (metadata.vegan != null) {
      items.add(_yesNo(context, Icons.grass, 'vegan', metadata.vegan!));
    }
    if (metadata.halal != null) {
      items.add(_yesNo(context, Icons.verified_outlined, 'halal',
          metadata.halal!));
    }
    if (metadata.spicyLevel != null) {
      items.add(_MetadataItem(
        icon: Icons.local_fire_department_outlined,
        label: context.l10n.text('spicyLevel'),
        value: '${metadata.spicyLevel}/5',
      ));
    }
    if (metadata.localTip != null) {
      items.add(_MetadataItem(
        icon: Icons.lightbulb_outline,
        label: context.l10n.text('localTip'),
        value: metadata.localTip!,
      ));
    }
    if (metadata.etiquette != null) {
      items.add(_MetadataItem(
        icon: Icons.groups_outlined,
        label: context.l10n.text('etiquette'),
        value: metadata.etiquette!,
      ));
    }
    if (metadata.doText != null) {
      items.add(_MetadataItem(
        icon: Icons.check_circle_outline,
        label: context.l10n.text('do'),
        value: metadata.doText!,
      ));
    }
    if (metadata.dontText != null) {
      items.add(_MetadataItem(
        icon: Icons.block_outlined,
        label: context.l10n.text('dont'),
        value: metadata.dontText!,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: context.l10n.text('goodToKnow')),
        const SizedBox(height: 10),
        ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MetadataCard(item: item),
            ),
          ),
      ],
    );
  }

  _MetadataItem _yesNo(
    BuildContext context,
    IconData icon,
    String key,
    bool value,
  ) {
    return _MetadataItem(
      icon: icon,
      label: context.l10n.text(key),
      value: context.l10n.text(value ? 'yes' : 'no'),
    );
  }
}

class _MetadataItem {
  const _MetadataItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.item});

  final _MetadataItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(item.icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(item.value),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoordinateTruthNotice extends StatelessWidget {
  const _CoordinateTruthNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withValues(alpha: .7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.location_searching_rounded, color: scheme.onTertiaryContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: scheme.onTertiaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryActionPanel extends StatelessWidget {
  const _PrimaryActionPanel({
    required this.isFavorite,
    required this.favoritePending,
    required this.isVisited,
    required this.isTried,
    required this.visitedPending,
    required this.triedPending,
    required this.onFavorite,
    required this.onVisited,
    required this.onTried,
  });

  final bool isFavorite;
  final bool favoritePending;
  final bool isVisited;
  final bool isTried;
  final bool visitedPending;
  final bool triedPending;
  final VoidCallback onFavorite;
  final VoidCallback onVisited;
  final VoidCallback onTried;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PrimaryAction(
            icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            label: context.l10n.text(isFavorite ? 'saved' : 'save'),
            selected: isFavorite,
            pending: favoritePending,
            onTap: favoritePending ? null : onFavorite,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PrimaryAction(
            icon: Icons.check_circle_outline_rounded,
            label: context.l10n.text('visited'),
            selected: isVisited,
            pending: visitedPending,
            onTap: visitedPending ? null : onVisited,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PrimaryAction(
            icon: Icons.restaurant_menu_rounded,
            label: context.l10n.text('tried'),
            selected: isTried,
            pending: triedPending,
            onTap: triedPending ? null : onTried,
          ),
        ),
      ],
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.icon,
    required this.label,
    required this.selected,
    required this.pending,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool pending;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (pending)
                const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  icon,
                  size: 21,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.categoryLabel,
    required this.description,
  });

  final String categoryLabel;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: .42),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              categoryLabel.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              description,
              style: theme.textTheme.titleMedium?.copyWith(
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
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
                  color: Colors.white,
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

