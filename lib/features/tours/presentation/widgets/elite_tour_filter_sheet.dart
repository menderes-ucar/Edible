import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/elite_widgets.dart';
import '../../data/datasources/hardcoded_world_tours_dataset.dart';


class EliteTourFilterSheet extends StatefulWidget {
  final String? selectedCountry;
  final int? selectedDuration;
  final String? selectedStyle;
  final bool sortByPopularity;
  final Function(String?) onCountryChanged;
  final Function(int?) onDurationChanged;
  final Function(String?) onStyleChanged;
  final Function(bool) onSortChanged;
  final VoidCallback onReset;

  const EliteTourFilterSheet({
    required this.selectedCountry,
    required this.selectedDuration,
    required this.selectedStyle,
    required this.sortByPopularity,
    required this.onCountryChanged,
    required this.onDurationChanged,
    required this.onStyleChanged,
    required this.onSortChanged,
    required this.onReset,
    super.key,
  });

  @override
  State<EliteTourFilterSheet> createState() => _EliteTourFilterSheetState();
}

class _EliteTourFilterSheetState extends State<EliteTourFilterSheet> {
  late String? _selectedCountry;
  late int? _selectedDuration;
  late String? _selectedStyle;
  late bool _sortByPopularity;

  final List<int> _durations = [1, 2, 3, 5, 7];
  final List<String> _styles = ['luxury', 'budget', 'adventure', 'culture', 'food'];

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.selectedCountry;
    _selectedDuration = widget.selectedDuration;
    _selectedStyle = widget.selectedStyle;
    _sortByPopularity = widget.sortByPopularity;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle
              Container(
                margin: EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.mediumGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.l10n.text('filterTours'),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.mediumGray,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: 20,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),

                        // Countries Filter
                        _buildSectionHeader(context.l10n.text('destination')),
                        SizedBox(height: 12),
                        _buildCountryFilter(),
                        SizedBox(height: 24),

                        // Duration Filter
                        _buildSectionHeader(context.l10n.text('duration')),
                        SizedBox(height: 12),
                        _buildDurationFilter(),
                        SizedBox(height: 24),

                        // Travel Style Filter
                        _buildSectionHeader(context.l10n.text('travelStyle')),
                        SizedBox(height: 12),
                        _buildStyleFilter(),
                        SizedBox(height: 24),

                        // Sort Options
                        _buildSectionHeader(context.l10n.text('sortBy')),
                        SizedBox(height: 12),
                        _buildSortOptions(),
                        SizedBox(height: 40),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedCountry = null;
                                    _selectedDuration = null;
                                    _selectedStyle = null;
                                    _sortByPopularity = false;
                                  });
                                  widget.onReset();
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(
                                    color: AppColors.mediumGray,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  context.l10n.text('reset'),
                                  style: TextStyle(
                                    color: AppColors.textDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: GradientButton(
                                label: context.l10n.text('applyFilters'),
                                gradient: AppColors.gradientTurquoiseToGreen,
                                onPressed: () {
                                  widget.onCountryChanged(_selectedCountry);
                                  widget.onDurationChanged(_selectedDuration);
                                  widget.onStyleChanged(_selectedStyle);
                                  widget.onSortChanged(_sortByPopularity);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildCountryFilter() {
    final countries = HardcodedWorldToursDataset.getAllCountries();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: countries
          .map((country) => ColorChip(
                label: country,
                isSelected: _selectedCountry == country,
                onTap: () {
                  setState(() {
                    _selectedCountry = _selectedCountry == country ? null : country;
                  });
                },
                selectedColor: AppColors.turquoise,
                unselectedColor: AppColors.lightGray,
              ))
          .toList(),
    );
  }

  Widget _buildDurationFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _durations
          .map((duration) => ColorChip(
                label: '$duration ${context.l10n.text('days')}',
                isSelected: _selectedDuration == duration,
                onTap: () {
                  setState(() {
                    _selectedDuration =
                        _selectedDuration == duration ? null : duration;
                  });
                },
                selectedColor: AppColors.orange,
                unselectedColor: AppColors.lightGray,
              ))
          .toList(),
    );
  }

  Widget _buildStyleFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _styles
          .map((style) => ColorChip(
                label: style.replaceFirst(
                  style[0],
                  style[0].toUpperCase(),
                ),
                isSelected: _selectedStyle == style,
                onTap: () {
                  setState(() {
                    _selectedStyle = _selectedStyle == style ? null : style;
                  });
                },
                selectedColor: AppColors.freshGreen,
                unselectedColor: AppColors.lightGray,
              ))
          .toList(),
    );
  }

  Widget _buildSortOptions() {
    return Column(
      children: [
        _buildSortOption(
          label: context.l10n.text('highestRated'),
          isSelected: !_sortByPopularity,
          onTap: () {
            setState(() => _sortByPopularity = false);
          },
        ),
        SizedBox(height: 12),
        _buildSortOption(
          label: context.l10n.text('mostPopular'),
          isSelected: _sortByPopularity,
          onTap: () {
            setState(() => _sortByPopularity = true);
          },
        ),
      ],
    );
  }

  Widget _buildSortOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.turquoise.withOpacity(0.1)
              : AppColors.backgroundWhite,
          border: Border.all(
            color: isSelected ? AppColors.turquoise : AppColors.mediumGray,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.turquoise : AppColors.gray,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.turquoise,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
