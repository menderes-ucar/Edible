import 'package:flutter/material.dart';

import 'smart_content_image.dart';

/// Backward-compatible image widget.
///
/// The old implementation used generic Unsplash fallbacks and a validation
/// race that could return before the image finished loading. It now delegates
/// to the single release-safe resolver so every caller gets the same verified
/// image pipeline.
class EnhancedSmartContentImage extends StatelessWidget {
  const EnhancedSmartContentImage({
    required this.title,
    required this.locale,
    this.city,
    this.country,
    this.preferredUrl,
    this.fit = BoxFit.cover,
    this.showAttribution = false,
    this.timeout = const Duration(seconds: 5),
    this.maxRetries = 2,
    this.height = 250,
    this.width,
    this.borderRadius,
    super.key,
  });

  final String title;
  final String locale;
  final String? city;
  final String? country;
  final String? preferredUrl;
  final BoxFit fit;
  final bool showAttribution;
  final Duration timeout;
  final int maxRetries;
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    Widget image = SizedBox(
      height: height,
      width: width,
      child: SmartContentImage(
        title: title,
        locale: locale,
        city: city,
        country: country,
        preferredUrl: preferredUrl,
        fit: fit,
        showAttribution: showAttribution,
      ),
    );

    final radius = borderRadius;
    if (radius != null) {
      image = ClipRRect(borderRadius: radius, child: image);
    }
    return image;
  }
}
