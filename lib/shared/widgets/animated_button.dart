import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';

class AnimatedButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final Color textColor;
  final Future<void> Function()? onTap;
  final bool isLoading;
  final double height;

  const AnimatedButton({
    super.key,
    required this.label,
    this.icon,
    required this.color,
    this.textColor = Colors.white,
    required this.onTap,
    this.isLoading = false,
    this.height = 52,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
  bool _pressed = false;

  Future<void> _handleTap() async {
    if (widget.isLoading || widget.onTap == null) return;
    await widget.onTap!.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onTap == null || widget.isLoading) return;
        setState(() => _pressed = true);
      },
      onTapUp: (_) {
        if (widget.onTap == null || widget.isLoading) return;
        setState(() => _pressed = false);
      },
      onTapCancel: () => setState(() => _pressed = false),
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: _pressed ? AppDurations.xs : const Duration(milliseconds: 300),
        curve: _pressed ? Curves.easeIn : Curves.elasticOut,
        child: Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.isLoading
                ? widget.color.withValues(alpha: 0.7)
                : widget.color,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            boxShadow: AppShadows.md(widget.color),
          ),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: AppDurations.sm,
            child: widget.isLoading
                ? SizedBox(
                    key: const ValueKey('loading'),
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(widget.textColor),
                    ),
                  )
                : Row(
                    key: const ValueKey('label'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: widget.textColor, size: 18),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        widget.label,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: widget.textColor,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded,
                          color: widget.textColor.withValues(alpha: 0.7), size: 16),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
