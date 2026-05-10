import 'package:flutter/material.dart';

class AnimatedChatFab extends StatefulWidget {
  final Color color;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const AnimatedChatFab({
    super.key,
    required this.color,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<AnimatedChatFab> createState() => _AnimatedChatFabState();
}

class _AnimatedChatFabState extends State<AnimatedChatFab>
    with TickerProviderStateMixin {
  late AnimationController _pulse, _bounce, _wiggle, _label;
  late Animation<double> _pulseScale,
      _pulseOpacity,
      _bounceScale,
      _wiggleAngle,
      _labelOpacity;
  late Animation<Offset> _labelOffset;
  bool _showLabel = true;

  @override
  void initState() {
    super.initState();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _pulseScale = Tween<double>(
      begin: 1.0,
      end: 1.8,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeOut));
    _pulseOpacity = Tween<double>(
      begin: 0.6,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeOut));

    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _bounceScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _bounce, curve: Curves.elasticOut));
    _bounce.forward();

    _wiggle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _wiggleAngle = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.15), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.15, end: -0.15), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.15, end: 0.1), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: -0.1), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _wiggle, curve: Curves.easeInOut));
    Future.delayed(const Duration(seconds: 3), _wiggleLoop);

    _label = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _labelOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _label, curve: Curves.easeOut));
    _labelOffset = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _label, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _label.forward();
    });
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _label.reverse();
        setState(() => _showLabel = false);
      }
    });
  }

  void _wiggleLoop() {
    if (!mounted) return;
    _wiggle
        .forward(from: 0)
        .then((_) => Future.delayed(const Duration(seconds: 4), _wiggleLoop));
  }

  @override
  void dispose() {
    _pulse.dispose();
    _bounce.dispose();
    _wiggle.dispose();
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_showLabel)
            FadeTransition(
              opacity: _labelOpacity,
              child: SlideTransition(
                position: _labelOffset,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 10),
          ScaleTransition(
            scale: _bounceScale,
            child: AnimatedBuilder(
              animation: Listenable.merge([_pulse, _wiggle]),
              builder: (context, _) => Stack(
                alignment: Alignment.center,
                children: [
                  Transform.scale(
                    scale: _pulseScale.value,
                    child: Opacity(
                      opacity: _pulseOpacity.value,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.color.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: (_pulseScale.value + 0.3).clamp(1.0, 2.2),
                    child: Opacity(
                      opacity: (_pulseOpacity.value - 0.3).clamp(0.0, 0.4),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.color.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                  Transform.rotate(
                    angle: _wiggleAngle.value,
                    child: GestureDetector(
                      onTap: widget.onTap,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              widget.color,
                              widget.color.withValues(alpha: 0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.color.withValues(alpha: 0.5),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(widget.icon, color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF6B6B),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
