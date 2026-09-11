import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/tour_package.dart';
import '../../data/datasources/hardcoded_world_tours_dataset.dart';
import '../../domain/services/tour_recommendation_engine.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/elite_widgets.dart';
import '../widgets/elite_tour_filter_sheet.dart';
import 'elite_tour_detail_page.dart';
import '../../../explore/presentation/widgets/enhanced_smart_content_image.dart';

class EliteToursListPage extends StatefulWidget {
  const EliteToursListPage({super.key});

  @override
  State<EliteToursListPage> createState() => _EliteToursListPageState();
}

class _EliteToursListPageState extends State<EliteToursListPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<TourPackage> _allTours;
  late List<TourPackage> _filteredTours;

  String? _selectedCountry;
  int? _selectedDuration;
  String? _selectedStyle;
  bool _sortByPopularity = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _allTours = HardcodedWorldToursDataset.allTours;
    _filteredTours = _allTours;
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      _filteredTours = TourRecommendationEngine.getRecommendations(
        preferredCountry: _selectedCountry,
        preferredDuration: _selectedDuration,
        travelStyle: _selectedStyle,
        minRating: 0.0,
        sortByPopularity: _sortByPopularity,
      );

      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        _filteredTours = TourRecommendationEngine.search(_searchQuery)
            .where((tour) {
              if (_selectedCountry != null) {
                return tour.countryName.toLowerCase() ==
                    _selectedCountry!.toLowerCase();
              }
              return true;
            })
            .toList();
      }
    });

    _animationController.forward(from: 0.0);
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => EliteTourFilterSheet(
        selectedCountry: _selectedCountry,
        selectedDuration: _selectedDuration,
        selectedStyle: _selectedStyle,
        sortByPopularity: _sortByPopularity,
        onCountryChanged: (country) {
          setState(() => _selectedCountry = country);
          _applyFilters();
          Navigator.pop(context);
        },
        onDurationChanged: (duration) {
          setState(() => _selectedDuration = duration);
          _applyFilters();
          Navigator.pop(context);
        },
        onStyleChanged: (style) {
          setState(() => _selectedStyle = style);
          _applyFilters();
          Navigator.pop(context);
        },
        onSortChanged: (sortByPop) {
          setState(() => _sortByPopularity = sortByPop);
          _applyFilters();
          Navigator.pop(context);
        },
        onReset: () {
          setState(() {
            _selectedCountry = null;
            _selectedDuration = null;
            _selectedStyle = null;
            _sortByPopularity = false;
            _searchQuery = '';
            _filteredTours = _allTours;
          });
          Navigator.pop(context);
        },
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(context.l10n.text('exploreTours'), style: TextStyle(color: AppColors.textDark)),
        elevation: 0,
        backgroundColor: AppColors.backgroundWhite,
        actions: [
          Container(
            margin: EdgeInsets.all(8),
            child: GestureDetector(
              onTap: _showFilterSheet,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.turquoise.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.tune, color: AppColors.turquoise, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Filter',
                      style: TextStyle(
                        color: AppColors.turquoise,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: TextField(
                onChanged: (query) {
                  setState(() => _searchQuery = query);
                  _applyFilters();
                },
                decoration: InputDecoration(
                  hintText: context.l10n.text('searchTours'),
                  prefixIcon: Icon(Icons.search, color: AppColors.turquoise),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            setState(() {
                              _searchQuery = '';
                              _applyFilters();
                            });
                          },
                          child: Icon(Icons.clear, color: AppColors.textMuted),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.mediumGray),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          // Active Filters
          if (_selectedCountry != null ||
              _selectedDuration != null ||
              _selectedStyle != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (_selectedCountry != null)
                        Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: ColorChip(
                            label: _selectedCountry!,
                            isSelected: true,
                            onTap: () {
                              setState(() => _selectedCountry = null);
                              _applyFilters();
                            },
                            selectedColor: AppColors.turquoise,
                          ),
                        ),
                      if (_selectedDuration != null)
                        Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: ColorChip(
                            label: '${_selectedDuration} ${context.l10n.text('days')}',
                            isSelected: true,
                            onTap: () {
                              setState(() => _selectedDuration = null);
                              _applyFilters();
                            },
                            selectedColor: AppColors.orange,
                          ),
                        ),
                      if (_selectedStyle != null)
                        Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: ColorChip(
                            label: _selectedStyle!,
                            isSelected: true,
                            onTap: () {
                              setState(() => _selectedStyle = null);
                              _applyFilters();
                            },
                            selectedColor: AppColors.freshGreen,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          SliverPadding(padding: EdgeInsets.only(top: 16)),
          // Tours Grid
          if (_filteredTours.isNotEmpty)
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final tour = _filteredTours[index];
                    return FadeTransition(
                      opacity: Tween<double>(begin: 0, end: 1).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(
                            (index * 0.05).clamp(0.0, 1.0),
                            ((index + 1) * 0.05).clamp(0.0, 1.0),
                          ),
                        ),
                      ),
                      child: _buildTourCard(tour),
                    );
                  },
                  childCount: _filteredTours.length,
                ),
              ),
            )
          else
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.travel_explore,
                      size: 64,
                      color: AppColors.turquoise.withOpacity(0.3),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No tours found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Try adjusting your filters',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textLight,
                      ),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => setState(() {
                        _selectedCountry = null;
                        _selectedDuration = null;
                        _selectedStyle = null;
                        _searchQuery = '';
                        _filteredTours = _allTours;
                      }),
                      child: Text(context.l10n.text('clearFilters')),
                    ),
                  ],
                ),
              ),
            ),
          SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  Widget _buildTourCard(TourPackage tour) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EliteTourDetailPage(tour: tour),
          ),
        );
      },
      child: EliteCard(
        padding: EdgeInsets.zero,
        borderRadius: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  EnhancedSmartContentImage(
                    title: tour.cityName,
                    locale: 'en',
                    city: tour.cityName,
                    country: tour.countryName,
                    preferredUrl: tour.coverImageUrl,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                  // Rating Badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundWhite,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 14, color: AppColors.orange),
                          SizedBox(width: 4),
                          Text(
                            tour.ratingAverage.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Duration
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.turquoiseLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tour.days.toString() + ' ' + context.l10n.text('days'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.turquoise,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  // Title
                  Text(
                    tour.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6),
                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: AppColors.textMuted,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${tour.cityName}, ${tour.countryName}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
