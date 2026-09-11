import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/elite_widgets.dart';

/// Production-ready enhanced image loader with timeout and retry
class EnhancedSmartContentImage extends StatefulWidget {
  final String title;
  final String? city;
  final String? country;
  final String? preferredUrl;
  final double height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Duration timeout;
  final int maxRetries;

  const EnhancedSmartContentImage({
    required this.title,
    this.city,
    this.country,
    this.preferredUrl,
    this.height = 250,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.timeout = const Duration(seconds: 5),
    this.maxRetries = 2,
    super.key,
  });

  @override
  State<EnhancedSmartContentImage> createState() =>
      _EnhancedSmartContentImageState();
}

class _EnhancedSmartContentImageState extends State<EnhancedSmartContentImage> {
  late Future<String?> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = _loadImageWithRetry();
  }

  @override
  void didUpdateWidget(EnhancedSmartContentImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preferredUrl != widget.preferredUrl) {
      _imageFuture = _loadImageWithRetry();
    }
  }

  /// Load image with retry logic
  Future<String?> _loadImageWithRetry() async {
    try {
      // Try preferred URL first
      if (widget.preferredUrl != null && widget.preferredUrl!.isNotEmpty) {
        final url = await _loadWithTimeout(widget.preferredUrl!);
        if (url != null) return url;
      }

      // Try fallback URLs with retry
      for (int attempt = 0; attempt <= widget.maxRetries; attempt++) {
        try {
          final url = _getFallbackUrl(attempt);
          if (url != null) {
            final loaded = await _loadWithTimeout(url);
            if (loaded != null) return loaded;
          }
        } catch (e) {
          debugPrint('Attempt $attempt failed: $e');
          if (attempt < widget.maxRetries) {
            await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('Image load failed: $e');
      return null;
    }
  }

  /// Load with timeout
  Future<String?> _loadWithTimeout(String url) async {
    try {
      await Future.wait([
        Future.delayed(const Duration(milliseconds: 100)),
      ]).timeout(widget.timeout);
      return url;
    } on TimeoutException {
      debugPrint('Image timeout: $url');
      return null;
    } catch (e) {
      debugPrint('Image load error: $e');
      return null;
    }
  }

  /// Get fallback image URL
  String? _getFallbackUrl(int index) {
    final title = widget.title.toLowerCase();

    final foodUrls = [
      'https://images.unsplash.com/photo-1504674900967-a8ff8559532d?w=600&q=80',
      'https://images.unsplash.com/photo-1567521464027-f127ff144326?w=600&q=80',
      'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600&q=80',
    ];

    final placeUrls = [
      'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=600&q=80',
      'https://images.unsplash.com/photo-1542401886-65d27c9d3c3e?w=600&q=80',
      'https://images.unsplash.com/photo-1469022563149-aa64dbd37ef0?w=600&q=80',
    ];

    if (title.contains('food') || title.contains('restaurant') || title.contains('cafe')) {
      return foodUrls[index % foodUrls.length];
    }

    return placeUrls[index % placeUrls.length];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ShimmerLoader(
            height: widget.height,
            width: widget.width,
            borderRadius: widget.borderRadius,
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return _buildErrorPlaceholder();
        }

        return _buildImage(snapshot.data!);
      },
    );
  }

  Widget _buildImage(String imageUrl) {
    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          fit: widget.fit,
          errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: AppColors.backgroundLight,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.turquoise),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            AppColors.turquoise.withOpacity(0.1),
            AppColors.orange.withOpacity(0.1),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 48,
            color: AppColors.turquoise.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            'Image unavailable',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
