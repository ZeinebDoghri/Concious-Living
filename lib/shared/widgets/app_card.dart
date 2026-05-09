import 'package:flutter/material.dart';
import '../../theme/role_colors.dart';

/// Reusable card component with consistent styling
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final Color backgroundColor;
  final BoxBorder? border;
  final double? elevation;
  final VoidCallback? onTap;
  final Gradient? gradient;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.backgroundColor = AppColors.cardBackground,
    this.border,
    this.elevation = 0,
    this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: gradient == null ? backgroundColor : null,
          gradient: gradient,
          borderRadius: border == null || border!.isUniform ? borderRadius : null,
          boxShadow: [
            if (elevation != null && elevation! > 0)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            if (elevation != null && elevation! > 1)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
          border: border,
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Elevated card with shadow
class ElevatedAppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color backgroundColor;
  final VoidCallback? onTap;

  const ElevatedAppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor = AppColors.cardBackground,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: padding,
      backgroundColor: backgroundColor,
      elevation: 1,
      onTap: onTap,
      child: child,
    );
  }
}

/// Card with left-side accent color
class AccentCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color accentColor;
  final double accentWidth;
  final VoidCallback? onTap;

  const AccentCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.accentColor = AppColors.secondary,
    this.accentWidth = 4,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: padding,
      border: Border(
        left: BorderSide(color: accentColor, width: accentWidth),
      ),
      elevation: 0.5,
      onTap: onTap,
      child: child,
    );
  }
}
