import 'package:flutter/material.dart';

import '../../data/services/content_image_resolver.dart';

/// Remote image renderer.
///
/// There is intentionally NO bundled-image system here. The first successful
/// remote search is persisted by ContentImageResolver and the same URL is used
/// on every subsequent rebuild/scroll/session for this content key.
class SmartContentImage extends StatefulWidget {
  const SmartContentImage({
    required this.title,
    required this.locale,
    this.city,
    this.country,
    this.category,
    this.preferredUrl,
    this.fit = BoxFit.cover,
    this.showAttribution = false,
    super.key,
  });

  final String title;
  final String locale;
  final String? city;
  final String? country;
  final String? category;
  final String? preferredUrl;
  final BoxFit fit;
  final bool showAttribution;

  @override
  State<SmartContentImage> createState() => _SmartContentImageState();
}

class _SmartContentImageState extends State<SmartContentImage>
    with AutomaticKeepAliveClientMixin {
  ResolvedContentImage? _resolved;
  bool _loading = true;
  bool _failed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _resolveOnce();
  }

  @override
  void didUpdateWidget(covariant SmartContentImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title ||
        oldWidget.city != widget.city ||
        oldWidget.country != widget.country ||
        oldWidget.locale != widget.locale ||
        oldWidget.preferredUrl != widget.preferredUrl) {
      _resolved = null;
      _failed = false;
      _loading = true;
      _resolveOnce();
    }
  }

  Future<void> _resolveOnce() async {
    final result = await ContentImageResolver.instance.resolve(
      title: widget.title,
      locale: widget.locale,
      city: widget.city,
      country: widget.country,
      preferredUrl: widget.preferredUrl,
    );
    if (!mounted) return;
    setState(() {
      _resolved = result;
      _loading = false;
      _failed = result == null;
    });
  }

  Widget _placeholder(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.image_not_supported_outlined, size: 30),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final image = _resolved;
    if (image == null) return _placeholder(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          image.imageUrl,
          fit: widget.fit,
          cacheWidth: 900,
          filterQuality: FilterQuality.low,
          gaplessPlayback: true,
          errorBuilder: (context, error, stack) {
            // Do NOT search again or swap to another image while scrolling.
            // The selected URL is intentionally stable for this content key.
            if (!_failed && mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _failed = true);
              });
            }
            return _placeholder(context);
          },
        ),
        if (widget.showAttribution &&
            image.attribution != null &&
            image.attribution!.trim().isNotEmpty)
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: Text(
                  image.attribution!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
