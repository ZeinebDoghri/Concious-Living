import 'package:flutter/material.dart';

/// Mixin that provides a fade + slide page entrance animation.
/// Use with [TickerProviderStateMixin].
///
/// Usage:
/// ```dart
/// class _MyState extends State<MyWidget>
///     with TickerProviderStateMixin, PageEnterMixin<MyWidget> {
///   @override
///   void initState() {
///     super.initState();
///     initPageEnter();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return wrapWithEnter(/* your widget tree */);
///   }
/// }
/// ```
mixin PageEnterMixin<T extends StatefulWidget> on State<T>,
    TickerProviderStateMixin<T> {
  late AnimationController enterCtrl;
  late Animation<double> fadeAnim;
  late Animation<Offset> slideAnim;

  void initPageEnter({
    Duration duration = const Duration(milliseconds: 900),
  }) {
    enterCtrl = AnimationController(vsync: this, duration: duration)
      ..forward();
    fadeAnim = CurvedAnimation(parent: enterCtrl, curve: Curves.easeOutCubic);
    slideAnim = Tween(begin: const Offset(0, .04), end: Offset.zero).animate(
      fadeAnim,
    );
  }

  Widget wrapWithEnter(Widget child) => FadeTransition(
    opacity: fadeAnim,
    child: SlideTransition(position: slideAnim, child: child),
  );

  /// Returns a stagger animation for list items.
  Animation<double> staggerAnim(int i) => CurvedAnimation(
    parent: enterCtrl,
    curve: Interval(i * 0.08, 1.0, curve: Curves.easeOutCubic),
  );
}
