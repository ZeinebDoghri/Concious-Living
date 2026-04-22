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
    required this.textColor,
    required this.onTap,
    this.isLoading = false,
    this.height = 52,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      value: 1.0,
      lowerBound: 0.96,
      upperBound: 1.0,
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (widget.isLoading || widget.onTap == null) return;
    await widget.onTap!.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onTap == null || widget.isLoading) return;
        _controller.animateTo(0.96);
      },
      onTapUp: (_) {
        if (widget.onTap == null || widget.isLoading) return;
        _controller.animateTo(1.0);
      },
      onTapCancel: () {
        if (widget.onTap == null || widget.isLoading) return;
        _controller.animateTo(1.0);
      },
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
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
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: widget.textColor,
                          letterSpacing: 0.3,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
