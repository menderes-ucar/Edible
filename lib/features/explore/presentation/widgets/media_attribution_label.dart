import 'package:flutter/material.dart';
import '../../data/datasources/verified_media_registry.dart';

class MediaAttributionLabel extends StatelessWidget {
  const MediaAttributionLabel({required this.contentTitle, super.key});
  final String contentTitle;

  @override
  Widget build(BuildContext context) {
    final media = verifiedMediaFor(contentTitle);
    if (media == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.photo_camera_outlined,
              size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              media.attribution,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
