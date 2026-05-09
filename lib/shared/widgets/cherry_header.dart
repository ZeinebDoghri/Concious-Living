import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';
import '../../theme/app_theme.dart';

class CherryHeader extends StatefulWidget {
  final String title;
  final String? subtitle;
  final bool showBack;
  final List<Widget>? actions;
  final double height;
  final Color? color;
  final String? emoji;
  final String role;

  const CherryHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = true,
    this.actions,
    this.height = 220,
    this.color,
    this.emoji,
    this.role = 'restaurant',
  });

  @override
  State<CherryHeader> createState() => _CherryHeaderState();
}

class _CherryHeaderState extends State<CherryHeader>
    with TickerProviderStateMixin {
  late final AnimationController _blobRotation;
  late final AnimationController _foodBounce;

  @override
  void initState() {
    super.initState();
    _blobRotation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _foodBounce = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blobRotation.dispose();
    _foodBounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.themeColors(widget.role);
    final bg = widget.color ?? colors.primary;

    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            height: widget.height,
            color: bg,
          ),

          // Blob 1 — large
          Positioned(
            top: -50,
            right: -60,
            child: AnimatedBuilder(
              animation: _blobRotation,
              builder: (context, _) {
                return Transform.rotate(
                  angle: _blobRotation.value * 2 * math.pi,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.heroBlob1.withValues(alpha: 0.25),
                    ),
                  ),
                );
              },
            ),
          ),

          // Blob 2 — medium
          Positioned(
            bottom: 20,
            left: -30,
            child: AnimatedBuilder(
              animation: _blobRotation,
              builder: (context, _) {
                return Transform.rotate(
                  angle: -_blobRotation.value * 2 * math.pi,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.heroBlob2.withValues(alpha: 0.20),
                    ),
                  ),
                );
              },
            ),
          ),

          // Blob 3 — accent
          Positioned(
            top: 40,
            left: 80,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),

          // Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Row(
                      children: [
                        if (widget.showBack)
                          IconButton(
                            onPressed: () => context.pop(),
                            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                            color: Colors.white.withValues(alpha: 0.9),
                          )
                        else
                          const SizedBox(width: 48),
                        const Spacer(),
                        if (widget.actions != null) ...widget.actions!,
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            widget.subtitle!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.7),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Food circle (if emoji provided)
          if (widget.emoji != null)
            Positioned(
              bottom: -20,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedBuilder(
                  animation: _foodBounce,
                  builder: (context, _) {
                    final offset = (_foodBounce.value - 0.5) * 16;
                    return Transform.translate(
                      offset: Offset(0, offset),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.deep.withValues(alpha: 0.3),
                          boxShadow: AppShadows.md(colors.primary),
                        ),
                        child: Center(
                          child: Text(
                            widget.emoji!,
                            style: const TextStyle(fontSize: 48),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
