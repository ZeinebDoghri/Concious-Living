import 'package:flutter/material.dart';
import '../../theme/role_colors.dart';

/// Primary action button (burgundy background)
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isEnabled;
  final double? height;
  final double? width;
  final EdgeInsets? padding;
  final TextStyle? textStyle;
  final IconData? icon;
  final MainAxisAlignment? iconAlignment;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.height = 52,
    this.width,
    this.padding,
    this.textStyle,
    this.icon,
    this.iconAlignment,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: ElevatedButton(
        onPressed: isLoading || !isEnabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.textSecondary.withValues(
            alpha: 0.5,
          ),
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: iconAlignment ?? MainAxisAlignment.center,
                children: [
                  if (icon != null) Icon(icon, size: 20),
                  if (icon != null) const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      style:
                          textStyle ??
                          const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Secondary action button (outlined burgundy)
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isEnabled;
  final double? height;
  final double? width;
  final Color borderColor;
  final Color textColor;
  final TextStyle? textStyle;
  final IconData? icon;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.height = 52,
    this.width,
    this.borderColor = AppColors.primary,
    this.textColor = AppColors.primary,
    this.textStyle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: OutlinedButton(
        onPressed: isLoading || !isEnabled ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isEnabled
                ? borderColor
                : AppColors.textSecondary.withValues(alpha: 0.3),
            width: 1.5,
          ),
          foregroundColor: textColor,
          disabledForegroundColor: AppColors.textSecondary.withValues(
            alpha: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) Icon(icon, size: 20),
                  if (icon != null) const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      style:
                          textStyle ??
                          const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Text button (no background or border)
class TextActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color textColor;
  final TextStyle? textStyle;
  final IconData? icon;

  const TextActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.textColor = AppColors.primary,
    this.textStyle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: textColor),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 18),
          if (icon != null) const SizedBox(width: 6),
          Text(
            label,
            style:
                textStyle ??
                TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
          ),
        ],
      ),
    );
  }
}

/// Icon button with background
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color iconColor;
  final double size;
  final double iconSize;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor = AppColors.primary,
    this.iconColor = Colors.white,
    this.size = 52,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: backgroundColor,
        shape: const CircleBorder(),
        child: Icon(icon, color: iconColor, size: iconSize),
      ),
    );
  }
}

/// Floating action button for center scan button
class FloatingCenterScanButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final bool isElevated;

  const FloatingCenterScanButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.isElevated = true,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: AppColors.primary,
      elevation: isElevated ? 4 : 0,
      shape: const CircleBorder(),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }
}

/// Compact action button (smaller, for inline use)
class CompactButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final double? height;
  final IconData? icon;

  const CompactButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor = AppColors.secondary,
    this.textColor = Colors.white,
    this.height = 32,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        label: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        icon: icon != null ? Icon(icon, size: 14) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
