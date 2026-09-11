import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/community_service.dart';
import '../../../profile/presentation/pages/public_profile_page.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final _service = CommunityService();
  late Future<List<CommunityPost>> _future;
  final Set<String> _likeIds = {};
  bool _loadingReaction = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _service.feed();
  }

  Future<void> _openComposer() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      context.push('/login?from=%2Fcommunity');
      return;
    }

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreatePostSheet(),
    );

    if (created == true && mounted) {
      setState(_reload);
    }
  }

  Future<void> _react(CommunityPost post, String reaction) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated || _loadingReaction) {
      if (!auth.isAuthenticated) {
        context.push('/login?from=%2Fcommunity');
      }
      return;
    }
    setState(() => _loadingReaction = true);
    try {
      await _service.react(
        postId: post.id,
        userId: auth.user!.id,
        reaction: reaction,
      );
      if (mounted) setState(_reload);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.text('operationFailedWithError').replaceAll('{error}', '$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingReaction = false);
    }
  }

  Future<void> _delete(CommunityPost post) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.text('deleteShareTitle')),
        content: Text(context.l10n.text('deleteShareMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.text('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.text('delete')),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _service.deletePost(post);
      if (mounted) setState(_reload);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.text('shareDeleteFailed').replaceAll('{error}', '$e'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF2D2D2D),
      appBar: AppBar(
        title: Text(context.l10n.text('share'), style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: context.l10n.text('refresh'),
            onPressed: () => setState(_reload),
            icon: const Icon(Icons.refresh_rounded),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 112,
              height: 44,
              child: FilledButton.icon(
                onPressed: _openComposer,
                icon: const Icon(Icons.add_a_photo_outlined, size: 19),
                label: Text(context.l10n.text('share')),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<CommunityPost>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _EmptyState(
              icon: Icons.cloud_off_rounded,
              title: context.l10n.text('communityLoadFailed'),
              subtitle: context.l10n.text('communityLoadFailedHint'),
              action: TextButton(
                onPressed: () => setState(_reload),
                child: Text(context.l10n.text('retry')),
              ),
            );
          }

          final posts = snapshot.data ?? const [];
          if (posts.isEmpty) {
            return _EmptyState(
              icon: Icons.photo_camera_back_outlined,
              title: context.l10n.text('firstShare'),
              subtitle: context.l10n.text('firstShareHint'),
              action: FilledButton.icon(
                onPressed: _openComposer,
                icon: const Icon(Icons.add),
                label: Text(context.l10n.text('createShare')),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => setState(_reload),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 32),
              itemCount: posts.length,
              itemBuilder: (_, index) {
                final post = posts[index];
                final isMine = auth.user?.id == post.userId;
                return _PostCard(
                  post: post,
                  isMine: isMine,
                  onProfile: () => context.push(
                    '${PublicProfilePage.routePrefix}/${post.userId}',
                  ),
                  onLike: () => _react(post, 'like'),
                  onDislike: () => _react(post, 'dislike'),
                  onDelete: isMine ? () => _delete(post) : null,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.isMine,
    required this.onProfile,
    required this.onLike,
    required this.onDislike,
    this.onDelete,
  });

  final CommunityPost post;
  final bool isMine;
  final VoidCallback onProfile;
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final images = post.imageUrls;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      elevation: 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            onTap: onProfile,
            leading: _Avatar(url: post.avatarUrl),
            title: Text(
              post.displayName,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(_relative(post.createdAt)),
            trailing: isMine
                ? PopupMenuButton<String>(
                    onSelected: (_) => onDelete?.call(),
                    itemBuilder: (_) =>  [
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline),
                          title: Text(context.l10n.text('deletePost')),
                        ),
                      ),
                    ],
                  )
                : null,
          ),
          if (images.isNotEmpty) _ImageStrip(urls: images),
          if (post.caption.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Text(post.caption, style: const TextStyle(fontSize: 15, height: 1.4)),
            ),
          if (post.locationName?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      post.locationName!,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
            child: Row(
              children: [
                _ReactionButton(
                  icon: Icons.thumb_up_alt_outlined,
                  label: '${post.likeCount}',
                  onTap: onLike,
                ),
                _ReactionButton(
                  icon: Icons.thumb_down_alt_outlined,
                  label: '${post.dislikeCount}',
                  onTap: onDislike,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onProfile,
                  icon: const Icon(Icons.person_outline, size: 18),
                  label: Text(context.l10n.text('viewProfile')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _relative(DateTime value) {
    final d = DateTime.now().difference(value.toLocal());
    if (d.inMinutes < 1) return 'Şimdi';
    if (d.inHours < 1) return '${d.inMinutes} dk önce';
    if (d.inDays < 1) return '${d.inHours} sa önce';
    if (d.inDays < 7) return '${d.inDays} gün önce';
    return '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
  }
}

class _ImageStrip extends StatelessWidget {
  const _ImageStrip({required this.urls});
  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    if (urls.length == 1) {
      return AspectRatio(
        aspectRatio: 1.25,
        child: Image.network(
          urls.first,
          fit: BoxFit.cover,
          cacheWidth: 1100,
          errorBuilder: (_, __, ___) => const ColoredBox(
            color: Color(0xFFE9E9E6),
            child: Icon(Icons.broken_image_outlined, size: 42),
          ),
        ),
      );
    }
    return SizedBox(
      height: 285,
      child: PageView.builder(
        itemCount: urls.length,
        itemBuilder: (_, i) => Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              urls[i],
              fit: BoxFit.cover,
              cacheWidth: 1100,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: Color(0xFFE9E9E6),
                child: Icon(Icons.broken_image_outlined, size: 42),
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .65),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    '${i + 1}/${urls.length}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 19),
              const SizedBox(width: 5),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.url});
  final String? url;
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 22,
      backgroundImage: url?.trim().isNotEmpty == true ? NetworkImage(url!) : null,
      child: url?.trim().isNotEmpty == true ? null : const Icon(Icons.person_outline),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.subtitle, required this.action});
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget action;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 64, color: Colors.grey.shade500),
              const SizedBox(height: 18),
              Text(title, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(subtitle, textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
              const SizedBox(height: 18),
              action,
            ],
          ),
        ),
      );
}

class _CreatePostSheet extends StatefulWidget {
  const _CreatePostSheet();
  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _caption = TextEditingController();
  final _location = TextEditingController();
  final _picker = ImagePicker();
  final _service = CommunityService();
  final List<Uint8List> _images = [];
  double? _lat;
  double? _lng;
  bool _saving = false;

  @override
  void dispose() {
    _caption.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_images.length >= 5) return;
    final picked = await _picker.pickMultiImage(
      imageQuality: 78,
      maxWidth: 1800,
      maxHeight: 1800,
    );
    final remaining = 5 - _images.length;
    for (final file in picked.take(remaining)) {
      final bytes = await file.readAsBytes();
      if (bytes.isNotEmpty) _images.add(bytes);
    }
    if (mounted) setState(() {});
  }

  Future<void> _useLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('Konum servisi kapalı.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError('Konum izni verilmedi.');
      }
      final position = await Geolocator.getCurrentPosition();
      _lat = position.latitude;
      _lng = position.longitude;
      if (_location.text.trim().isEmpty) {
        _location.text =
            '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      }
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _save() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.text('atLeastOneImage'))),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.createPost(
        userId: user.id,
        caption: _caption.text,
        images: _images,
        locationName: _location.text,
        latitude: _lat,
        longitude: _lng,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.text('shareFailed').replaceAll('{error}', '$e'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Padding(
        padding: EdgeInsets.only(
          left: 18, right: 18, top: 10,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44, height: 5,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                 Expanded(
                  child: Text(context.l10n.text('newPost'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                ),
                Text('${_images.length}/5', style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 106,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  InkWell(
                    onTap: _pickImages,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 106,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Icon(Icons.add_photo_alternate_outlined, size: 30),
                    ),
                  ),
                  ..._images.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.memory(entry.value, width: 106, height: 106, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 5, right: 5,
                            child: GestureDetector(
                              onTap: () => setState(() => _images.removeAt(entry.key)),
                              child: const CircleAvatar(
                                radius: 14,
                                child: Icon(Icons.close, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _caption,
              maxLines: 4,
              maxLength: 2000,
              decoration:  InputDecoration(
                labelText: 'Açıklama',
                hintText: context.l10n.text('communityCaptionHint'),
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _location,
              decoration: InputDecoration(
                labelText: 'Konum (isteğe bağlı)',
                hintText: context.l10n.text('communityLocationHint'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_on_outlined),
                suffixIcon: IconButton(
                  tooltip: context.l10n.text('useCurrentLocation'),
                  onPressed: _useLocation,
                  icon: const Icon(Icons.my_location_rounded),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send_rounded),
                label: Text(_saving ? context.l10n.text('publishing') : context.l10n.text('publishPost')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
