import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/brand_palette.dart';
import '../animations/fab_pulse.dart';
import '../animations/pressable.dart';

enum ScanExperienceRole { customer, restaurant, hotel }

class RoleScanExperience extends StatelessWidget {
  final ScanExperienceRole role;
  final String title;
  final String subtitle;
  final String hint;
  final String? liveTitle;
  final String? liveSubtitle;
  final String? imagePath;
  final Uint8List? imageBytes;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;
  final VoidCallback? onInfoTap;

  const RoleScanExperience({
    super.key,
    required this.role,
    required this.title,
    required this.subtitle,
    required this.hint,
    required this.isLoading,
    required this.onBack,
    required this.onCameraTap,
    required this.onGalleryTap,
    this.liveTitle,
    this.liveSubtitle,
    this.imagePath,
    this.imageBytes,
    this.onInfoTap,
  });

  _ScanStyle get _style {
    switch (role) {
      case ScanExperienceRole.restaurant:
        return const _ScanStyle(
          background: kRest3,
          primary: kRest1,
          deep: kRest2,
          soft: kRest4,
          surface: kRest3,
          icon: Icons.qr_code_scanner_rounded,
          scanDuration: Duration(milliseconds: 2000),
        );
      case ScanExperienceRole.hotel:
        return const _ScanStyle(
          background: kHotel3,
          primary: kHotel1,
          deep: kHotel2,
          soft: kHotel4,
          surface: kHotel3,
          icon: Icons.camera_alt_rounded,
          scanDuration: Duration(milliseconds: 3000),
        );
      case ScanExperienceRole.customer:
        return const _ScanStyle(
          background: kCust3,
          primary: kCust1,
          deep: kCust2,
          soft: kCust4,
          surface: kCust3,
          icon: Icons.camera_alt_rounded,
          scanDuration: Duration(milliseconds: 2500),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;
    return Scaffold(
      backgroundColor: style.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: _RoleGrid(role: role, color: style.primary),
          ),
          SafeArea(
            child: Column(
              children: [
                _Header(
                  title: title,
                  subtitle: subtitle,
                  color: style.primary,
                  onBack: onBack,
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
                          child: _Viewfinder(
                            role: role,
                            style: style,
                            hint: hint,
                            imagePath: imagePath,
                            imageBytes: imageBytes,
                          ),
                        ),
                      ),
                      if (role == ScanExperienceRole.hotel)
                        Positioned(
                          top: 10,
                          left: 20,
                          right: 20,
                          child: _HotelLiveOverlay(
                            title: liveTitle ?? 'Hotel Food Scan',
                            subtitle: liveSubtitle ?? 'Product category ready',
                            style: style,
                          ),
                        ),
                    ],
                  ),
                ),
                if (role == ScanExperienceRole.restaurant)
                  _RestaurantLiveOverlay(
                    title: liveTitle ?? 'Dish detection standby',
                    subtitle: liveSubtitle ?? 'Food category will appear here',
                    style: style,
                  ),
                _CaptureDock(
                  role: role,
                  style: style,
                  onCameraTap: onCameraTap,
                  onGalleryTap: onGalleryTap,
                  onInfoTap: onInfoTap,
                ),
              ],
            ),
          ),
          if (isLoading) _LoadingOverlay(role: role, style: style),
        ],
      ),
    );
  }
}

class _ScanStyle {
  final Color background;
  final Color primary;
  final Color deep;
  final Color soft;
  final Color surface;
  final IconData icon;
  final Duration scanDuration;

  const _ScanStyle({
    required this.background,
    required this.primary,
    required this.deep,
    required this.soft,
    required this.surface,
    required this.icon,
    required this.scanDuration,
  });
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onBack;

  const _Header({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Pressable(
            onTap: onBack,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withValues(alpha: 0.22)),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: color,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lora(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: kText2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color.withValues(alpha: 0.45)),
            ),
            child: Text(
              'AI',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Viewfinder extends StatefulWidget {
  final ScanExperienceRole role;
  final _ScanStyle style;
  final String hint;
  final String? imagePath;
  final Uint8List? imageBytes;

  const _Viewfinder({
    required this.role,
    required this.style,
    required this.hint,
    this.imagePath,
    this.imageBytes,
  });

  @override
  State<_Viewfinder> createState() => _ViewfinderState();
}

class _ViewfinderState extends State<_Viewfinder>
    with TickerProviderStateMixin {
  late final AnimationController _scanCtrl;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
      vsync: this,
      duration: widget.style.scanDuration,
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: widget.role == ScanExperienceRole.hotel
          ? const Duration(milliseconds: 2500)
          : const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: widget.style.primary.withValues(
                    alpha: 0.18 + _pulseCtrl.value * 0.18,
                  ),
                  blurRadius: 22 + _pulseCtrl.value * 18,
                ),
              ],
            ),
            child: child,
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _Preview(
                role: widget.role,
                style: widget.style,
                imagePath: widget.imagePath,
                imageBytes: widget.imageBytes,
              ),
              _ScanLine(
                controller: _scanCtrl,
                role: widget.role,
                style: widget.style,
              ),
              _DetectionDots(role: widget.role, style: widget.style),
              CustomPaint(
                painter: _FramePainter(
                  role: widget.role,
                  color: Color.lerp(
                    widget.style.primary,
                    widget.style.soft,
                    _pulseCtrl.value,
                  )!,
                  pulse: _pulseCtrl.value,
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: _HintPill(
                  role: widget.role,
                  style: widget.style,
                  text: widget.hint,
                  pulse: _pulseCtrl,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  final ScanExperienceRole role;
  final _ScanStyle style;
  final String? imagePath;
  final Uint8List? imageBytes;

  const _Preview({
    required this.role,
    required this.style,
    this.imagePath,
    this.imageBytes,
  });

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    if (imageBytes != null && imageBytes!.isNotEmpty) {
      return Image.memory(imageBytes!, fit: BoxFit.cover);
    }
    if (!kIsWeb && path != null && path.isNotEmpty) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _Placeholder(role: role, style: style),
      );
    }
    return _Placeholder(role: role, style: style);
  }
}

class _Placeholder extends StatelessWidget {
  final ScanExperienceRole role;
  final _ScanStyle style;

  const _Placeholder({required this.role, required this.style});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [style.primary.withValues(alpha: 0.22), style.surface],
          center: const Alignment(-0.2, -0.35),
          radius: 1.1,
        ),
      ),
      child: Center(
        child: Icon(
          role == ScanExperienceRole.restaurant
              ? Icons.restaurant_menu_rounded
              : role == ScanExperienceRole.hotel
              ? Icons.room_service_rounded
              : Icons.document_scanner_rounded,
          color: style.primary.withValues(alpha: 0.38),
          size: 76,
        ),
      ),
    );
  }
}

class _ScanLine extends StatelessWidget {
  final AnimationController controller;
  final ScanExperienceRole role;
  final _ScanStyle style;

  const _ScanLine({
    required this.controller,
    required this.role,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (_, constraints) => AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final opacity = role == ScanExperienceRole.hotel
                ? 0.7 + sin(controller.value * pi * 2) * 0.15
                : 1.0;
            return Transform.translate(
              offset: Offset(0, controller.value * constraints.maxHeight),
              child: Align(
                alignment: Alignment.topCenter,
                child: Opacity(
                  opacity: opacity.clamp(0.55, 1.0),
                  child: Container(
                    height: role == ScanExperienceRole.hotel ? 4 : 3,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: role == ScanExperienceRole.hotel
                            ? [
                                Colors.transparent,
                                style.soft,
                                style.primary,
                                style.soft,
                                Colors.transparent,
                              ]
                            : [
                                Colors.transparent,
                                style.primary,
                                style.soft,
                                Colors.transparent,
                              ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: style.primary.withValues(alpha: 0.65),
                          blurRadius: role == ScanExperienceRole.hotel
                              ? 20
                              : 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DetectionDots extends StatelessWidget {
  final ScanExperienceRole role;
  final _ScanStyle style;

  const _DetectionDots({required this.role, required this.style});

  @override
  Widget build(BuildContext context) {
    const positions = [
      Alignment(-0.48, -0.22),
      Alignment(0.46, -0.36),
      Alignment(-0.16, 0.24),
      Alignment(0.38, 0.34),
    ];
    return Stack(
      children: positions
          .asMap()
          .entries
          .map((entry) {
            return Align(
              alignment: entry.value,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.elasticOut,
                builder: (_, value, child) =>
                    Transform.scale(scale: value, child: child),
                child: _Dot(role: role, style: style),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _Dot extends StatelessWidget {
  final ScanExperienceRole role;
  final _ScanStyle style;

  const _Dot({required this.role, required this.style});

  @override
  Widget build(BuildContext context) {
    if (role == ScanExperienceRole.restaurant) {
      return Transform.rotate(
        angle: pi / 4,
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: style.primary,
            boxShadow: [
              BoxShadow(
                color: style.primary.withValues(alpha: 0.9),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      );
    }
    if (role == ScanExperienceRole.hotel) {
      return Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: style.primary,
          boxShadow: [
            BoxShadow(
              color: style.primary.withValues(alpha: 0.8),
              blurRadius: 10,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: style.soft,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: style.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: style.primary.withValues(alpha: 0.7), blurRadius: 8),
        ],
      ),
    );
  }
}

class _HintPill extends StatelessWidget {
  final ScanExperienceRole role;
  final _ScanStyle style;
  final String text;
  final Animation<double> pulse;

  const _HintPill({
    required this.role,
    required this.style,
    required this.text,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: role == ScanExperienceRole.hotel ? 12 : 8,
          sigmaY: role == ScanExperienceRole.hotel ? 12 : 8,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: style.soft.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: pulse,
                builder: (context, child) => Transform.scale(
                  scale: 0.75 + pulse.value * 0.45,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: style.primary,
                      shape: role == ScanExperienceRole.restaurant
                          ? BoxShape.rectangle
                          : BoxShape.circle,
                      borderRadius: role == ScanExperienceRole.restaurant
                          ? BorderRadius.circular(2)
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: role == ScanExperienceRole.hotel
                    ? GoogleFonts.lora(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: style.deep,
                      )
                    : GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: style.deep,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaptureDock extends StatelessWidget {
  final ScanExperienceRole role;
  final _ScanStyle style;
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;
  final VoidCallback? onInfoTap;

  const _CaptureDock({
    required this.role,
    required this.style,
    required this.onCameraTap,
    required this.onGalleryTap,
    this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _SideAction(
            icon: Icons.photo_library_outlined,
            label: 'Gallery',
            color: style.primary,
            onTap: onGalleryTap,
          ),
          FabWithPulse(
            ringColor: style.primary,
            fab: Pressable(
              onTap: onCameraTap,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: role == ScanExperienceRole.restaurant
                      ? BoxShape.rectangle
                      : BoxShape.circle,
                  borderRadius: role == ScanExperienceRole.restaurant
                      ? BorderRadius.circular(20)
                      : null,
                  gradient: role == ScanExperienceRole.hotel
                      ? RadialGradient(
                          colors: [style.primary, style.deep],
                          center: const Alignment(-0.3, -0.3),
                        )
                      : LinearGradient(colors: [style.deep, style.primary]),
                  boxShadow: [
                    BoxShadow(
                      color: style.primary.withValues(alpha: 0.45),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Icon(style.icon, color: Colors.white, size: 30),
              ),
            ),
          ),
          _SideAction(
            icon: Icons.info_outline_rounded,
            label: 'Info',
            color: style.primary,
            onTap: onInfoTap,
          ),
        ],
      ),
    );
  }
}

class _SideAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _SideAction({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: kText2,
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantLiveOverlay extends StatelessWidget {
  final String title;
  final String subtitle;
  final _ScanStyle style;

  const _RestaurantLiveOverlay({
    required this.title,
    required this.subtitle,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(title),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: style.primary.withValues(alpha: 0.24)),
        ),
        child: Row(
          children: [
            Icon(Icons.restaurant_rounded, color: style.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.lora(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: style.deep,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 11, color: kText2),
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

class _HotelLiveOverlay extends StatelessWidget {
  final String title;
  final String subtitle;
  final _ScanStyle style;

  const _HotelLiveOverlay({
    required this.title,
    required this.subtitle,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      offset: Offset.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: kCard.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: style.soft.withValues(alpha: 0.65)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: style.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.hotel_rounded, color: style.deep, size: 19),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.lora(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: style.deep,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(fontSize: 11, color: kText2),
                      ),
                    ],
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

class _LoadingOverlay extends StatelessWidget {
  final ScanExperienceRole role;
  final _ScanStyle style;

  const _LoadingOverlay({required this.role, required this.style});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: style.soft.withValues(alpha: 0.82),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: style.primary.withValues(alpha: 0.26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: style.primary, strokeWidth: 3),
              const SizedBox(height: 18),
              Text(
                'Analyzing...',
                style: GoogleFonts.lora(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: style.deep,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                role == ScanExperienceRole.customer
                    ? 'Reading nutrition and allergens'
                    : 'Scanning for contamination and food safety signals',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: kText2,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleGrid extends StatelessWidget {
  final ScanExperienceRole role;
  final Color color;

  const _RoleGrid({required this.role, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: switch (role) {
        ScanExperienceRole.restaurant => _HexGridPainter(color),
        ScanExperienceRole.hotel => _DiagonalGridPainter(color),
        ScanExperienceRole.customer => _SquareGridPainter(color),
      },
    );
  }
}

class _SquareGridPainter extends CustomPainter {
  final Color color;
  const _SquareGridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.04)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_SquareGridPainter oldDelegate) => false;
}

class _HexGridPainter extends CustomPainter {
  final Color color;
  const _HexGridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    const r = 32.0;
    final h = sqrt(3) * r;
    for (double y = -h; y < size.height + h; y += h) {
      for (double x = -r; x < size.width + r; x += r * 1.5) {
        final cy = y + ((x / (r * 1.5)).round().isOdd ? h / 2 : 0);
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final angle = pi / 6 + i * pi / 3;
          final p = Offset(x + cos(angle) * r, cy + sin(angle) * r);
          if (i == 0) {
            path.moveTo(p.dx, p.dy);
          } else {
            path.lineTo(p.dx, p.dy);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_HexGridPainter oldDelegate) => false;
}

class _DiagonalGridPainter extends CustomPainter {
  final Color color;
  const _DiagonalGridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.05)
      ..strokeWidth = 0.5;
    for (double x = -size.height; x < size.width + size.height; x += 24) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DiagonalGridPainter oldDelegate) => false;
}

class _FramePainter extends CustomPainter {
  final ScanExperienceRole role;
  final Color color;
  final double pulse;

  const _FramePainter({
    required this.role,
    required this.color,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(18, 18, size.width - 36, size.height - 36);
    final paint = Paint()
      ..color = color
      ..strokeWidth = role == ScanExperienceRole.hotel ? 2 : 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 + pulse * 10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    if (role == ScanExperienceRole.hotel) {
      final outer = RRect.fromRectAndRadius(rect, const Radius.circular(14));
      final inner = RRect.fromRectAndRadius(
        rect.deflate(8),
        const Radius.circular(10),
      );
      canvas.drawRRect(outer, glowPaint);
      _drawLuxuryCorners(canvas, rect, paint, 28);
      final innerPaint = Paint()
        ..color = kHotel4
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      _drawLuxuryCorners(canvas, inner.outerRect, innerPaint, 20);
      return;
    }

    final len = role == ScanExperienceRole.restaurant ? 24.0 : 20.0;
    canvas.drawRect(rect, glowPaint);
    _drawLCorners(canvas, rect, paint, len);
    if (role == ScanExperienceRole.restaurant) {
      final diamondPaint = Paint()..color = color;
      for (final p in [
        rect.topLeft,
        rect.topRight,
        rect.bottomLeft,
        rect.bottomRight,
      ]) {
        final path = Path()
          ..moveTo(p.dx, p.dy - 5)
          ..lineTo(p.dx + 5, p.dy)
          ..lineTo(p.dx, p.dy + 5)
          ..lineTo(p.dx - 5, p.dy)
          ..close();
        canvas.drawPath(path, diamondPaint);
      }
    }
  }

  void _drawLCorners(Canvas canvas, Rect r, Paint p, double len) {
    canvas.drawLine(r.topLeft, r.topLeft + Offset(len, 0), p);
    canvas.drawLine(r.topLeft, r.topLeft + Offset(0, len), p);
    canvas.drawLine(r.topRight, r.topRight + Offset(-len, 0), p);
    canvas.drawLine(r.topRight, r.topRight + Offset(0, len), p);
    canvas.drawLine(r.bottomLeft, r.bottomLeft + Offset(len, 0), p);
    canvas.drawLine(r.bottomLeft, r.bottomLeft + Offset(0, -len), p);
    canvas.drawLine(r.bottomRight, r.bottomRight + Offset(-len, 0), p);
    canvas.drawLine(r.bottomRight, r.bottomRight + Offset(0, -len), p);
  }

  void _drawLuxuryCorners(Canvas canvas, Rect r, Paint p, double len) {
    _drawLCorners(canvas, r, p, len);
  }

  @override
  bool shouldRepaint(_FramePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.pulse != pulse;
}
