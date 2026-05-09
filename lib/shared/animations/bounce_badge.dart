import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/brand_palette.dart';

/// A notification badge that bounces to attract attention.
class BounceBadge extends StatefulWidget {
  final int count;
  final Color color;

  const BounceBadge({super.key, required this.count, this.color = kDanger});

  @override
  State<BounceBadge> createState() => _BounceBadgeState();
}

class _BounceBadgeState extends State<BounceBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.35).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
      ),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Text(
          '${widget.count}',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}
