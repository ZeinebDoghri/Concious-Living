import 'dart:math' as math;

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants.dart';
import '../../../core/firebase_service.dart';
import '../../../shared/widgets/animated_button.dart';

// Hotel (green/sage) role colors
const _primary   = Color(0xFF7DC5A0);
const _deep      = Color(0xFF4A8A6A);
const _softBg    = Color(0xFFDFF2E9);
const _textTitle = Color(0xFF0D2E1E);
const _textMuted = Color(0xFF7AAA90);

class HotelForgotPasswordScreen extends StatefulWidget {
  const HotelForgotPasswordScreen({super.key});

  @override
  State<HotelForgotPasswordScreen> createState() =>
      _HotelForgotPasswordScreenState();
}

class _HotelForgotPasswordScreenState extends State<HotelForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();

  bool _isSending = false;
  bool _sent      = false;
  bool _pressed   = false;

  late final AnimationController _blobController;
  late final AnimationController _successController;
  late final Animation<double>   _successScale;

  @override
  void initState() {
    super.initState();
    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScale = CurvedAnimation(parent: _successController, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _blobController.dispose();
    _successController.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _readableError(Object e) {
    final message = e.toString();
    if (message.startsWith('Exception: ')) return message.substring('Exception: '.length);
    if (message.startsWith('StateError: ')) return message.substring('StateError: '.length);
    return message;
  }

  Future<void> _send() async {
    if (_isSending) return;

    final email = _emailController.text.trim();
    if (!EmailValidator.validate(email)) {
      _snack(AppStrings.validationInvalidEmail);
      return;
    }

    setState(() => _isSending = true);

    try {
      await FirebaseService.sendPasswordReset(email);
      if (!mounted) return;
      setState(() => _sent = true);
      await _successController.forward(from: 0);
    } catch (e) {
      _snack(_readableError(e));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final heroH   = screenH * 0.42;

    return Scaffold(
      backgroundColor: _primary,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Hero zone ────────────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            height: heroH,
            child: Stack(
              children: [
                Container(color: _primary),
                AnimatedBuilder(
                  animation: _blobController,
                  builder: (_, __) => CustomPaint(
                    painter: _BlobPainter(_blobController.value, _primary),
                    size: Size(double.infinity, heroH),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          onPressed: () => context.go(AppRoutes.hotelLogin),
                          icon: const Icon(Icons.arrow_back_ios_new),
                          color: Colors.white,
                        ),
                        const Spacer(),
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'Forgot password?',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'We\'ll send you a reset link',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Floating card ────────────────────────────────────────────
          Positioned(
            top: heroH - 24,
            left: 0, right: 0, bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft:  Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: AppShadows.lg(_primary),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: _sent
                      ? _SuccessPanel(key: const ValueKey('success'), scale: _successScale)
                      : _FormPanel(
                          key: const ValueKey('form'),
                          emailController: _emailController,
                          isSending: _isSending,
                          pressed: _pressed,
                          onPressDown: () => setState(() => _pressed = true),
                          onPressUp: () {
                            setState(() => _pressed = false);
                            _send();
                          },
                          onPressCancel: () => setState(() => _pressed = false),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormPanel extends StatelessWidget {
  final TextEditingController emailController;
  final bool isSending;
  final bool pressed;
  final VoidCallback onPressDown;
  final VoidCallback onPressUp;
  final VoidCallback onPressCancel;

  const _FormPanel({
    super.key,
    required this.emailController,
    required this.isSending,
    required this.pressed,
    required this.onPressDown,
    required this.onPressUp,
    required this.onPressCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.enterYourEmail,
          style: GoogleFonts.inter(fontSize: 13, color: _textMuted, height: 1.6),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.inter(fontSize: 14, color: _textTitle),
          decoration: InputDecoration(
            labelText: AppStrings.emailAddress,
            labelStyle: GoogleFonts.inter(fontSize: 14, color: _textMuted),
            filled: true,
            fillColor: _softBg,
            prefixIcon: const Icon(Icons.email_outlined, color: _textMuted, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.input),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.input),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.input),
              borderSide: const BorderSide(color: _primary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 18),
        GestureDetector(
          onTapDown: (_) => onPressDown(),
          onTapUp: (_) => onPressUp(),
          onTapCancel: onPressCancel,
          child: AnimatedScale(
            scale: pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Container(
              height: 54,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.pill),
                gradient: const LinearGradient(
                  colors: [_primary, _deep],
                  begin: Alignment.centerLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: isSending
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      AppStrings.sendResetLink,
                      style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
        const Spacer(),
        Center(
          child: TextButton(
            onPressed: () => context.go(AppRoutes.hotelLogin),
            child: Text(
              AppStrings.backToSignIn,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _primary),
            ),
          ),
        ),
      ],
    );
  }
}

class _SuccessPanel extends StatelessWidget {
  final Animation<double> scale;

  const _SuccessPanel({super.key, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: scale,
          child: Container(
            width: 84, height: 84,
            decoration: const BoxDecoration(
              color: Color(0xFFDFF2E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: _deep, size: 42),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppStrings.checkYourEmail,
          style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w600, color: _textTitle),
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.resetEmailSent,
          style: GoogleFonts.inter(fontSize: 13, color: _textMuted, height: 1.6),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        AnimatedButton(
          label: AppStrings.backToSignIn,
          color: _primary,
          textColor: Colors.white,
          onTap: () async => context.go(AppRoutes.hotelLogin),
          height: 52,
        ),
      ],
    );
  }
}

class _BlobPainter extends CustomPainter {
  final double t;
  final Color primary;
  _BlobPainter(this.t, this.primary);

  @override
  void paint(Canvas canvas, Size size) {
    final angle = t * 2 * math.pi;
    final c1 = Offset(size.width * 0.15 + math.cos(angle) * 20, size.height * 0.35 + math.sin(angle) * 15);
    canvas.drawCircle(c1, size.width * 0.5, Paint()
      ..shader = RadialGradient(colors: [Colors.white.withValues(alpha: 0.10), Colors.transparent])
          .createShader(Rect.fromCircle(center: c1, radius: size.width * 0.5)));
    final c2 = Offset(size.width * 0.85 + math.sin(angle * 0.7) * 18, size.height * 0.6 + math.cos(angle * 0.7) * 22);
    canvas.drawCircle(c2, size.width * 0.4, Paint()
      ..shader = RadialGradient(colors: [Colors.white.withValues(alpha: 0.07), Colors.transparent])
          .createShader(Rect.fromCircle(center: c2, radius: size.width * 0.4)));
    final c3 = Offset(size.width * 0.5 + math.cos(angle * 1.4) * 14, size.height * 0.2 + math.sin(angle * 1.4) * 10);
    canvas.drawCircle(c3, size.width * 0.3, Paint()
      ..shader = RadialGradient(colors: [Colors.white.withValues(alpha: 0.08), Colors.transparent])
          .createShader(Rect.fromCircle(center: c3, radius: size.width * 0.3)));
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.t != t;
}
