import 'package:flutter/material.dart';

import '../../domain/entities/travel_card_style.dart';
import '../../domain/entities/travel_share_card.dart';

class EditableTravelCard extends StatelessWidget {
  const EditableTravelCard({
    required this.card,
    required this.aspect,
    required this.template,
    this.backgroundImageUrl,
    super.key,
  });

  final TravelShareCard card;
  final TravelCardAspect aspect;
  final TravelCardTemplate template;
  final String? backgroundImageUrl;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspect.ratio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _Background(
              template: template,
              imageUrl: backgroundImageUrl,
            ),
            _Overlay(template: template),
            Padding(
              padding: EdgeInsets.all(
                aspect == TravelCardAspect.story ? 28 : 24,
              ),
              child: _CardContent(
                card: card,
                template: template,
                hasPhoto: backgroundImageUrl != null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Background extends StatelessWidget {
  const _Background({
    required this.template,
    required this.imageUrl,
  });

  final TravelCardTemplate template;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final image = imageUrl;

    if (image != null && image.trim().isNotEmpty) {
      return Image.network(
        image,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _Fallback(template: template),
      );
    }

    return _Fallback(template: template);
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({
    required this.template,
  });

  final TravelCardTemplate template;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: switch (template) {
          TravelCardTemplate.minimal => LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.surfaceContainerHighest,
                scheme.surface,
              ],
            ),
          TravelCardTemplate.postcard => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                scheme.primaryContainer,
                scheme.secondaryContainer,
              ],
            ),
          TravelCardTemplate.bold => LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                scheme.primary,
                scheme.tertiary,
              ],
            ),
        },
      ),
    );
  }
}

class _Overlay extends StatelessWidget {
  const _Overlay({
    required this.template,
  });

  final TravelCardTemplate template;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: switch (template) {
          TravelCardTemplate.minimal => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x12000000),
                Color(0x42000000),
              ],
            ),
          TravelCardTemplate.postcard => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x18000000),
                Color(0x65000000),
              ],
            ),
          TravelCardTemplate.bold => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x30000000),
                Color(0x88000000),
              ],
            ),
        },
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({
    required this.card,
    required this.template,
    required this.hasPhoto,
  });

  final TravelShareCard card;
  final TravelCardTemplate template;
  final bool hasPhoto;

  @override
  Widget build(BuildContext context) {
    final darkText =
        !hasPhoto && template == TravelCardTemplate.minimal;

    final textColor = darkText
        ? Theme.of(context).colorScheme.onSurface
        : Colors.white;

    return DefaultTextStyle.merge(
      style: TextStyle(color: textColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BrandLine(
            template: template,
            color: textColor,
          ),
          const Spacer(),
          if (template == TravelCardTemplate.postcard)
            Text(
              card.dateLabel,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            card.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            card.location,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                ),
          ),
          if (template != TravelCardTemplate.postcard)
            Text(
              card.dateLabel,
              style: TextStyle(color: textColor),
            ),
          if (card.rating != null) ...[
            const SizedBox(height: 16),
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  index < card.rating!
                      ? Icons.star
                      : Icons.star_border,
                  color: textColor,
                  size: 21,
                ),
              ),
            ),
          ],
          if (card.favoriteFood.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.restaurant_outlined,
                  color: textColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    card.favoriteFood,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (card.note.trim().isNotEmpty &&
              template != TravelCardTemplate.bold) ...[
            const SizedBox(height: 14),
            Text(
              '“${card.note.trim()}”',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Text(
            'Made with Edible',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandLine extends StatelessWidget {
  const _BrandLine({
    required this.template,
    required this.color,
  });

  final TravelCardTemplate template;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          template == TravelCardTemplate.postcard
              ? Icons.local_post_office_outlined
              : Icons.public,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          template == TravelCardTemplate.postcard
              ? 'EDIBLE POSTCARD'
              : 'EDIBLE',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.8,
          ),
        ),
      ],
    );
  }
}
