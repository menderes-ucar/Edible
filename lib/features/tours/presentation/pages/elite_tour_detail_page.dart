import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/tour_package.dart';
import '../../data/services/content_visual_matcher.dart';
import '../../../explore/presentation/widgets/enhanced_smart_content_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/elite_widgets.dart';
class EliteTourDetailPage extends StatefulWidget {
  final TourPackage tour;

  const EliteTourDetailPage({
    required this.tour,
    super.key,
  });

  @override
  State<EliteTourDetailPage> createState() => _EliteTourDetailPageState();
}

class _EliteTourDetailPageState extends State<EliteTourDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isFavorited = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.backgroundWhite,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundWhite,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () => setState(() => _isFavorited = !_isFavorited),
                child: Container(
                  margin: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundWhite,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      _isFavorited ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorited ? AppColors.error : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Cover Image
                  EnhancedSmartContentImage(
                    title: widget.tour.cityName,
                    locale: 'en',
                    city: widget.tour.cityName,
                    country: widget.tour.countryName,
                    preferredUrl: widget.tour.coverImageUrl,
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Duration & Location Badges
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.turquoiseLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: AppColors.turquoise,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    widget.tour.days.toString() + ' ' + context.l10n.text('days'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.turquoise,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 12),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.orangeLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: AppColors.orange,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    '${widget.tour.cityName}, ${widget.tour.countryName}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        // Title
                        Text(
                          widget.tour.title,
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        SizedBox(height: 12),
                        // Summary
                        Text(
                          widget.tour.summary,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textMuted,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  // Rating Card
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: EliteCard(
                      backgroundColor: AppColors.backgroundWhite,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RatingDisplay(
                            rating: widget.tour.ratingAverage,
                            reviewCount: widget.tour.ratingCount,
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.gradientTurquoiseToGreen,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '👍 ${widget.tour.favoriteCount}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  // Itinerary Section
                  if (widget.tour.stops.isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Daily Itinerary',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: _buildItinerary(),
                    ),
                    SizedBox(height: 24),
                  ],
                  // CTA Button
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: GradientButton(
                      label: context.l10n.text('bookThisTour'),
                      gradient: AppColors.gradientOrangeToTurquoise,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.l10n.text('bookingComingSoon')),
                            backgroundColor: AppColors.turquoise,
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItinerary() {
    // Group stops by day
    final stopsByDay = <int, List<TourStop>>{};
    for (final stop in widget.tour.stops) {
      stopsByDay.putIfAbsent(stop.dayIndex, () => []).add(stop);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: stopsByDay.length,
      itemBuilder: (context, index) {
        final dayIndex = stopsByDay.keys.toList()[index];
        final stops = stopsByDay[dayIndex]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.turquoise.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Day ${dayIndex + 1}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.turquoise,
                ),
              ),
            ),
            SizedBox(height: 12),
            // Stops
            ...stops.map((stop) {
              final (icon, color) = ContentVisualMatcher.getCategoryIconAndColor(stop.kind);
              return Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: EliteCard(
                  padding: EdgeInsets.all(12),
                  backgroundColor: AppColors.backgroundWhite,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stop.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              stop.subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            SizedBox(height: 24),
          ],
        );
      },
    );
  }
}
