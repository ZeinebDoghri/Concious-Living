import 'dart:math' as math;

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants.dart';
import '../../../core/firebase_service.dart';

// Customer (violet/lavender) role colors
const _primary   = Color(0xFFA78BFA);
const _deep      = Color(0xFF7C3AED);
const _softBg    = Color(0xFFEDE9FE);
const _textTitle = Color(0xFF2D1B69);
const _textMuted = Color(0xFF8B7BC0);

class CustomerForgotPasswordScreen extends StatefulWidget {
  const CustomerForgotPasswordScreen({super.key});

  @override
  State<CustomerForgotPasswordScreen> createState() =>
      _CustomerForgotPasswordScreenState();
}

class _CustomerForgotPasswordScreenState
    extends State<CustomerForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _sent      = false;
  bool _pressed   = false;

  late final AnimationController _blobController;
  late final Animation<double>   _successScale;

  @override
  void initState() {
    super.initState();
    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _successScale = CurvedAnimation(parent: _blobController, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _blobController.dispose();
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
    if (_isLoading) return;

    final email = _emailController.text.trim();
    if (!EmailValidator.validate(email)) {
      _snack(AppStrings.validationInvalidEmail);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseService.sendPasswordReset(email);
      if (!mounted) return;
      setState(() => _sent = true);
      _blobController.reset();
      _blobController.forward();
    } catch (e) {
      _snack(_readableError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                          onPressed: () => context.go(AppRoutes.customerLogin),
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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: _sent
                    ? _SuccessView(key: const ValueKey('success'))
                    : _FormView(
                        key: const ValueKey('form'),
                        emailController: _emailController,
                        isLoading: _isLoading,
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
        ],
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  final TextEditingController emailController;
  final bool isLoading;
  final bool pressed;
  final VoidCallback onPressDown;
  final VoidCallback onPressUp;
  final VoidCallback onPressCancel;

  const _FormView({
    super.key,
    required this.emailController,
    required this.isLoading,
    required this.pressed,
    required this.onPressDown,
    required this.onPressUp,
    required this.onPressCancel,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _softBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.email_outlined, size: 32, color: _primary),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.forgotYourPasswordTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _textTitle,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.forgotYourPasswordBody,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _textMuted,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
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
          const SizedBox(height: 24),
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
                child: isLoading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        AppStrings.sendResetLink,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go(AppRoutes.customerLogin),
            child: Text(
              AppStrings.backToSignIn,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 48, 28, 24),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFDFF2E9),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.check_circle, size: 40, color: Color(0xFF4A8A6A)),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.resetSentTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _textTitle,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.resetSentBody,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: _textMuted, height: 1.6),
          ),
          const SizedBox(height: 28),
          OutlinedButton(
            onPressed: () => context.go(AppRoutes.customerLogin),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primary,
              side: const BorderSide(color: _primary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: Text(
              AppStrings.backToSignIn,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: _primary),
            ),
          ),
        ],
      ),
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
