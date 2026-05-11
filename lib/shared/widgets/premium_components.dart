import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PREMIUM CARD COMPONENTS — Flat design with subtle depth
// ═══════════════════════════════════════════════════════════════════════════════

/// Premium elevated card with subtle shadow and border
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final bool animate;

  const PremiumCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 20,
    this.onTap,
    this.backgroundColor,
    this.animate = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ??
        (isDark ? AppColorsPremium.darkBgCard : AppColorsPremium.bgPrimary);
    final border =
        isDark ? AppColorsPremium.darkBorder : AppColorsPremium.borderLight;

    final card = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: border, width: 0.8),
            boxShadow: PremiumShadows.elevation2,
          ),
          child: child,
        ),
      ),
    );

    if (animate) {
      return card
          .animate(onPlay: (controller) => controller.forward())
          .fadeIn(duration: 300.ms)
          .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut);
    }

    return card;
  }
}

/// Premium stat tile for KPI dashboards
class PremiumStatTile extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? accentColor;
  final VoidCallback? onTap;
  final int animationDelay;

  const PremiumStatTile({
    Key? key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.accentColor,
    this.onTap,
    this.animationDelay = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColorsPremium.darkTextPrimary
        : AppColorsPremium.textPrimary;
    final textSecondary = isDark
        ? AppColorsPremium.darkTextSecondary
        : AppColorsPremium.textSecondary;
    final accent = accentColor ?? AppColorsPremium.emeraldPrimary;

    return PremiumCard(
      onTap: onTap,
      animate: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 24),
            )
          else
            const SizedBox.shrink(),
          if (icon != null) const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.sora(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
          ],
        ],
      ),
    )
        .animate(onPlay: (controller) => controller.forward())
        .fadeIn(delay: Duration(milliseconds: animationDelay), duration: 300.ms)
        .slideY(
          begin: 0.15,
          end: 0,
          delay: Duration(milliseconds: animationDelay),
          duration: 400.ms,
          curve: Curves.easeOut,
        );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PREMIUM SECTION HEADER — Clean, elegant typography
// ═══════════════════════════════════════════════════════════════════════════════

class PremiumSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const PremiumSectionHeader({
    Key? key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColorsPremium.darkTextPrimary
        : AppColorsPremium.textPrimary;
    final textSecondary = isDark
        ? AppColorsPremium.darkTextSecondary
        : AppColorsPremium.textSecondary;

    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.sora(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PREMIUM BUTTONS — Modern, responsive, smooth interactions
// ═══════════════════════════════════════════════════════════════════════════════

class PremiumButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;

  const PremiumButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.backgroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  }) : super(key: key);

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.backgroundColor ?? AppColorsPremium.emeraldPrimary;

    return SizedBox(
      width: widget.isFullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: widget.isLoading ? null : widget.onPressed,
        icon: widget.isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withValues(alpha: 0.9),
                  ),
                  strokeWidth: 2,
                ),
              )
            : (widget.icon != null ? Icon(widget.icon) : const SizedBox.shrink()),
        label: Text(
          widget.label,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: Colors.white,
          padding: widget.padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PREMIUM ALERT CARD — Beautiful alert/notification design
// ═══════════════════════════════════════════════════════════════════════════════

class PremiumAlertCard extends StatelessWidget {
  final String title;
  final String message;
  final AlertLevel level;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;
  final String? actionLabel;
  final int animationDelay;

  const PremiumAlertCard({
    Key? key,
    required this.title,
    required this.message,
    this.level = AlertLevel.info,
    this.onDismiss,
    this.onAction,
    this.actionLabel = 'View',
    this.animationDelay = 0,
  }) : super(key: key);

  Color _getColorForLevel() {
    switch (level) {
      case AlertLevel.success:
        return AppColorsPremium.success;
      case AlertLevel.warning:
        return AppColorsPremium.warning;
      case AlertLevel.alert:
        return AppColorsPremium.alert;
      case AlertLevel.info:
        return AppColorsPremium.info;
    }
  }

  IconData _getIconForLevel() {
    switch (level) {
      case AlertLevel.success:
        return Icons.check_circle_outline;
      case AlertLevel.warning:
        return Icons.warning_outline;
      case AlertLevel.alert:
        return Icons.error_outline;
      case AlertLevel.info:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColorsPremium.darkBgHover
        : AppColorsPremium.cloud.withValues(alpha: 0.5);
    final accentColor = _getColorForLevel();

    return PremiumCard(
      backgroundColor: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_getIconForLevel(), color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColorsPremium.darkTextPrimary
                        : AppColorsPremium.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: isDark
                        ? AppColorsPremium.darkTextSecondary
                        : AppColorsPremium.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      ),
    )
        .animate(onPlay: (controller) => controller.forward())
        .fadeIn(
          delay: Duration(milliseconds: animationDelay),
          duration: 300.ms,
        )
        .slideX(
          begin: 0.1,
          end: 0,
          delay: Duration(milliseconds: animationDelay),
          duration: 400.ms,
          curve: Curves.easeOut,
        );
  }
}

enum AlertLevel { success, warning, alert, info }

// ═══════════════════════════════════════════════════════════════════════════════
// PREMIUM EMPTY STATE — Beautiful, engaging empty screen
// ═══════════════════════════════════════════════════════════════════════════════

class PremiumEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const PremiumEmptyState({
    Key? key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColorsPremium.darkTextPrimary
        : AppColorsPremium.textPrimary;
    final textSecondary = isDark
        ? AppColorsPremium.darkTextSecondary
        : AppColorsPremium.textSecondary;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColorsPremium.emeraldPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: AppColorsPremium.emeraldPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: textSecondary,
                  height: 1.6,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: 200,
                  child: PremiumButton(
                    label: actionLabel!,
                    onPressed: onAction!,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PREMIUM LOADING INDICATOR — Modern, smooth loading animation
// ═══════════════════════════════════════════════════════════════════════════════

class PremiumLoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;

  const PremiumLoadingIndicator({
    Key? key,
    this.size = 48,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final accentColor = color ?? AppColorsPremium.emeraldPrimary;

    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
        strokeWidth: 2.5,
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .fadeIn(duration: 300.ms)
        .scale(begin: 0.8, end: 1, duration: 400.ms, curve: Curves.elasticOut);
  }
}
