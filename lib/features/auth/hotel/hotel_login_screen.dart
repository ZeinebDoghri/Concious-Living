import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../providers/user_provider.dart';

// Hotel (green/sage) role colors
const _primary   = Color(0xFF7DC5A0);
const _deep      = Color(0xFF4A8A6A);
const _softBg    = Color(0xFFDFF2E9);
const _textTitle = Color(0xFF0D2E1E);
const _textMuted = Color(0xFF7AAA90);

class HotelLoginScreen extends StatefulWidget {
  const HotelLoginScreen({super.key});

  @override
  State<HotelLoginScreen> createState() => _HotelLoginScreenState();
}

class _HotelLoginScreenState extends State<HotelLoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscure   = true;
  bool _isLoading = false;
  bool _pressed   = false;

  late final AnimationController _blobController;

  @override
  void initState() {
    super.initState();
    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  Future<void> _signIn() async {
    if (_isLoading) return;

    final email    = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      _snack(AppStrings.validationInvalidEmail);
      return;
    }
    if (password.length < 6) {
      _snack(AppStrings.validationPasswordMin);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await context.read<UserProvider>().login(
            email: email,
            password: password,
            role: 'hotel',
          );
      if (!mounted) return;
      context.go(AppRoutes.hotelDashboard);
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
                          onPressed: () => context.go(AppRoutes.roleSelector),
                          icon: const Icon(Icons.arrow_back_ios_new),
                          color: Colors.white,
                        ),
                        const Spacer(),
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'Hotel sign in',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Manage your hotel operations',
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Email
                    _buildInput(
                      controller: _emailController,
                      label: AppStrings.emailAddress,
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    // Password
                    _buildInput(
                      controller: _passwordController,
                      label: AppStrings.password,
                      icon: Icons.lock_outline,
                      obscure: _obscure,
                      onToggleObscure: () => setState(() => _obscure = !_obscure),
                    ),
                    const SizedBox(height: 8),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.go(AppRoutes.hotelForgotPassword),
                        child: Text(
                          AppStrings.forgotPassword,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // CTA
                    _buildCta(label: AppStrings.signIn, onTap: _signIn),

                    const SizedBox(height: 20),

                    // Register link
                    Center(
                      child: TextButton(
                        onPressed: () => context.go(AppRoutes.hotelRegister),
                        child: Text(
                          'New hotel? Register here',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool? obscure,
    VoidCallback? onToggleObscure,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure ?? false,
      style: GoogleFonts.inter(fontSize: 14, color: _textTitle),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 14, color: _textMuted),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: _textMuted),
        filled: true,
        fillColor: _softBg,
        prefixIcon: Icon(icon, color: _textMuted, size: 20),
        suffixIcon: onToggleObscure != null
            ? IconButton(
                onPressed: onToggleObscure,
                icon: Icon(
                  obscure! ? Icons.visibility : Icons.visibility_off,
                  color: _textMuted,
                  size: 20,
                ),
              )
            : null,
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
    );
  }

  Widget _buildCta({required String label, required Future<void> Function() onTap}) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
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
          child: _isLoading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
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
