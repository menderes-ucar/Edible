import 'package:flutter/material.dart';
import 'smart_content_image.dart';

/// Deterministic image renderer for licensed/static content.
/// Runtime image discovery/search is intentionally disabled.
class LicensedContentImage extends StatelessWidget {
  const LicensedContentImage({
    required this.title,
    this.city,
    this.country,
    this.category,
    this.preferredUrl,
    super.key,
  });
  final String title;
  final String? city, country, category, preferredUrl;

  @override
  Widget build(BuildContext context) {
    return SmartContentImage(
      title: title,
      locale: 'en',
      city: city,
      country: country,
      category: category,
      preferredUrl: preferredUrl,
      fit: BoxFit.cover,
      showAttribution: true,
    );
  }
}
