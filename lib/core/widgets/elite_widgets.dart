import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Elite card widget with subtle shadow and hover effect
class EliteCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final double borderRadius;
  final Color? backgroundColor;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;

  const EliteCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
    this.backgroundColor,
    this.border,
    this.boxShadow,
  });

  @override
  State<EliteCard> createState() => _EliteCardState();
}

class _EliteCardState extends State<EliteCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 200),
          offset: Offset(0, _isHovered ? -0.02 : 0),
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
            color: widget.backgroundColor ?? AppColors.backgroundWhite,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: widget.border,
            boxShadow: widget.boxShadow ??
                [
                  BoxShadow(
                    color: Colors.black.withOpacity(_isHovered ? 0.12 : 0.06),
                    blurRadius: _isHovered ? 16 : 8,
                    offset: Offset(0, _isHovered ? 8 : 4),
                  ),
                ],
          ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Gradient button with smooth animation
class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final LinearGradient gradient;
  final double height;
  final double borderRadius;
  final TextStyle? textStyle;
  final bool isLoading;

  const GradientButton({
    required this.label,
    required this.onPressed,
    this.gradient = AppColors.gradientTurquoiseToGreen,
    this.height = 56,
    this.borderRadius = 12,
    this.textStyle,
    this.isLoading = false,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        if (!widget.isLoading) widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.colors[0].withOpacity(0.4),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.isLoading ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        widget.label,
                        style: widget.textStyle ??
                            TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Elite color chip for filtering
class ColorChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? selectedColor;
  final Color? unselectedColor;
  final IconData? icon;

  const ColorChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.selectedColor = AppColors.turquoise,
    this.unselectedColor = AppColors.lightGray,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : unselectedColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color:
                isSelected ? selectedColor! : AppColors.mediumGray,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedColor!.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.textMuted,
              ),
              SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textDark,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Elite rating display widget
class RatingDisplay extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final double size;

  const RatingDisplay({
    required this.rating,
    required this.reviewCount,
    this.size = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star,
          color: AppColors.orange,
          size: 16 * size,
        ),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${rating.toStringAsFixed(1)} ⭐',
              style: TextStyle(
                fontSize: 14 * size,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            Text(
              '$reviewCount reviews',
              style: TextStyle(
                fontSize: 12 * size,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Elite image placeholder
class ImagePlaceholder extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const ImagePlaceholder({
    this.height = 200,
    this.width,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.gradientTurquoiseToGreen.scale(0.3),
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image,
              size: 48,
              color: AppColors.turquoise.withOpacity(0.5),
            ),
            SizedBox(height: 12),
            Text(
              'Loading Image...',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Elite shimmer loader for cards
class ShimmerLoader extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const ShimmerLoader({
    this.height = 200,
    this.width,
    this.borderRadius,
  });

  @override
  State<ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<ShimmerLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width ?? double.infinity,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.mediumGray,
                AppColors.lightGray,
                AppColors.mediumGray,
              ],
              stops: [
                0.0,
                _controller.value,
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }
}
