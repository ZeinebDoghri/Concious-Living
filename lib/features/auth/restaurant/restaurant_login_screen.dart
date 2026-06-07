import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../providers/user_provider.dart';
import '../../../services/google_sign_in_service.dart';

// ── Restaurant — Spring Meadows (olive green) ─────────────────────────────────
const _kBg = Color(0xFFF5F8EE); // lightest tint of restaurant green
const _kPrimary = Color(0xFF8FA84A);
const _kDeep = Color(0xFF5A7030);
const _kSoftBg = Color(0xFFE3E8D1);
const _kBorder = Color(0xFFC0D089);
const _kTitle = Color(0xFF26201B);
const _kMuted = Color(0xFF8C7E78);

const _kCustAccent = Color(0xFFD9899F);
const _kHotelAccent = Color(0xFF5A9FC9);

class RestaurantLoginScreen extends StatefulWidget {
  const RestaurantLoginScreen({super.key});

  @override
  State<RestaurantLoginScreen> createState() => _RestaurantLoginScreenState();
}

class _RestaurantLoginScreenState extends State<RestaurantLoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscure = true;
  bool _isLoading = false;
  bool _pressed = false;

  late final AnimationController _blobCtrl;

  @override
  void initState() {
    super.initState();
    _blobCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _blobCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  String _readable(Object e) {
    final s = e.toString();
    if (s.startsWith('Exception: ')) return s.substring(11);
    if (s.startsWith('StateError: ')) return s.substring(12);
    return s;
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  Future<void> _signIn() async {
    if (_isLoading) return;
    HapticFeedback.selectionClick();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
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
        role: 'restaurant',
      );
      if (!mounted) return;
      context.go(AppRoutes.restaurantDashboard);
    } catch (e) {
      _snack(_readable(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final cred = await GoogleSignInService.signIn();
      if (cred == null || !mounted) return;
      final uid = cred.user!.uid;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final role = doc.data()?['role']?.toString();
      if (!mounted) return;
      if (role == null || role.isEmpty) {
        context.go(AppRoutes.selectRole);
        return;
      }
      if (role == 'customer') {
        context.go(AppRoutes.customerHome);
      } else if (role == 'restaurant') {
        context.go(AppRoutes.restaurantDashboard);
      } else if (role == 'hotel') {
        context.go(AppRoutes.hotelDashboard);
      } else {
        context.go(AppRoutes.selectRole);
      }
    } catch (e) {
      _snack(_readable(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final heroH = screenH * 0.44;

    return Scaffold(
      backgroundColor: _kBg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background blobs
          AnimatedBuilder(
            animation: _blobCtrl,
            builder: (_, _) => CustomPaint(
              painter: _BlobBgPainter(_blobCtrl.value),
              size: Size(double.infinity, MediaQuery.of(context).size.height),
            ),
          ),

          // Hero
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroH,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_kPrimary.withOpacity(0.90), _kDeep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  AnimatedBuilder(
                    animation: _blobCtrl,
                    builder: (_, _) => CustomPaint(
                      painter: _HeroBlobPainter(_blobCtrl.value),
                      size: Size(double.infinity, heroH),
                    ),
                  ),

                  Positioned(
                    right: -heroH * 0.16,
                    bottom: -heroH * 0.12,
                    child: Container(
                      width: heroH * 0.65,
                      height: heroH * 0.65,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            onPressed: _goBack,
                            icon: const Icon(Icons.arrow_back),
                            color: Colors.white,
                          ),
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Restaurant',
                                        style: GoogleFonts.cormorantGaramond(
                                          fontSize: 36,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          height: 1.05,
                                        ),
                                      ),
                                      Text(
                                        'Portal',
                                        style: GoogleFonts.cormorantGaramond(
                                          fontSize: 36,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          height: 1.05,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'KITCHEN OPERATIONS',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white.withOpacity(0.70),
                                          letterSpacing: 2.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const _KitchenIllustration(size: 108),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating card
          Positioned(
            top: heroH - 26,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _kPrimary.withOpacity(0.16),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 30, 28, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sign in',
                                style: GoogleFonts.cormorantGaramond(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: _kTitle,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Manage your kitchen operations',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: _kMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _kSoftBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _kBorder, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: _kPrimary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Restaurant',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _kDeep,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 26),

                    _buildInput(
                      controller: _emailCtrl,
                      label: AppStrings.emailAddress,
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),

                    _buildInput(
                      controller: _passwordCtrl,
                      label: AppStrings.password,
                      icon: Icons.lock_outline,
                      obscure: _obscure,
                      onToggleObscure: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                    const SizedBox(height: 6),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.go(AppRoutes.restaurantForgot),
                        child: Text(
                          AppStrings.forgotPassword,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildCta(label: AppStrings.signIn, onTap: _signIn),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: _kMuted,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),

                    OutlinedButton.icon(
                      onPressed: _signInWithGoogle,
                      icon: const Icon(Icons.g_mobiledata_rounded, size: 24),
                      label: const Text('Continue with Google'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        side: BorderSide(color: _kBorder, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _pill(_kPrimary),
                          const SizedBox(width: 4),
                          _pill(_kCustAccent),
                          const SizedBox(width: 4),
                          _pill(_kHotelAccent),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Center(
                      child: GestureDetector(
                        onTap: () => context.go(AppRoutes.restaurantRegister),
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: _kMuted,
                            ),
                            children: [
                              const TextSpan(text: 'New restaurant?  '),
                              TextSpan(
                                text: 'Create account',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _kPrimary,
                                ),
                              ),
                            ],
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

  Widget _pill(Color c) => Container(
    width: 20,
    height: 4,
    decoration: BoxDecoration(
      color: c.withOpacity(0.50),
      borderRadius: BorderRadius.circular(2),
    ),
  );

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
      style: GoogleFonts.dmSans(fontSize: 14, color: _kTitle),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(fontSize: 14, color: _kMuted),
        filled: true,
        fillColor: _kSoftBg,
        prefixIcon: Icon(icon, color: _kMuted, size: 20),
        suffixIcon: onToggleObscure != null
            ? IconButton(
                onPressed: onToggleObscure,
                icon: Icon(
                  obscure! ? Icons.visibility : Icons.visibility_off,
                  color: _kMuted,
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
          borderSide: const BorderSide(color: _kPrimary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildCta({
    required String label,
    required Future<void> Function() onTap,
  }) {
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
              colors: [_kPrimary, _kDeep],
              begin: Alignment.centerLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withOpacity(0.30),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}

class _HeroBlobPainter extends CustomPainter {
  final double t;
  _HeroBlobPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final angle = t * 2 * math.pi;
    void blob(double cx, double cy, double r, double op) {
      final c = Offset(cx, cy);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [Colors.white.withOpacity(op), Colors.transparent],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }

    blob(
      size.width * 0.15 + math.cos(angle) * 20,
      size.height * 0.35 + math.sin(angle) * 15,
      size.width * 0.5,
      0.07,
    );
    blob(
      size.width * 0.85 + math.sin(angle * 0.7) * 18,
      size.height * 0.6 + math.cos(angle * 0.7) * 22,
      size.width * 0.4,
      0.05,
    );
    blob(
      size.width * 0.5 + math.cos(angle * 1.4) * 14,
      size.height * 0.2 + math.sin(angle * 1.4) * 10,
      size.width * 0.3,
      0.06,
    );
  }

  @override
  bool shouldRepaint(_HeroBlobPainter old) => old.t != t;
}

class _BlobBgPainter extends CustomPainter {
  final double t;
  _BlobBgPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final angle = t * 2 * math.pi;
    void blob(double cx, double cy, double r, Color c, double op) {
      final center = Offset(cx, cy);
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [c.withOpacity(op), Colors.transparent],
          ).createShader(Rect.fromCircle(center: center, radius: r)),
      );
    }

    blob(
      size.width * 0.85 + math.sin(angle * 0.6) * 20,
      size.height * 0.75 + math.cos(angle * 0.6) * 24,
      size.width * 0.40,
      _kPrimary,
      0.07,
    );
    blob(
      size.width * 0.10 + math.cos(angle * 0.8) * 16,
      size.height * 0.82 + math.sin(angle * 0.8) * 18,
      size.width * 0.30,
      const Color(0xFFD9899F),
      0.05,
    );
  }

  @override
  bool shouldRepaint(_BlobBgPainter old) => old.t != t;
}

// ── Kitchen illustration ───────────────────────────────────────────────────────
class _KitchenIllustration extends StatelessWidget {
  final double size;
  const _KitchenIllustration({required this.size});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _KitchenPainter()),
  );
}

class _KitchenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    // Pan body
    final panPath = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(w * 0.50, h * 0.58),
          width: w * 0.64,
          height: h * 0.28,
        ),
      );
    canvas.drawPath(panPath, Paint()..color = const Color(0xFF4A5528));
    // Pan rim highlight
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.54),
        width: w * 0.60,
        height: h * 0.12,
      ),
      Paint()..color = const Color(0xFF8FA84A),
    );
    // Pan handle
    final handle = Path()
      ..moveTo(w * 0.82, h * 0.56)
      ..lineTo(w * 0.96, h * 0.50)
      ..lineTo(w * 0.96, h * 0.56)
      ..lineTo(w * 0.82, h * 0.62)
      ..close();
    canvas.drawPath(handle, Paint()..color = const Color(0xFF4A5528));
    // Veggie items in pan
    canvas.drawCircle(
      Offset(w * 0.38, h * 0.56),
      w * 0.08,
      Paint()..color = const Color(0xFF66BB6A),
    );
    canvas.drawCircle(
      Offset(w * 0.55, h * 0.54),
      w * 0.07,
      Paint()..color = const Color(0xFFEF5350),
    );
    canvas.drawCircle(
      Offset(w * 0.44, h * 0.64),
      w * 0.065,
      Paint()..color = const Color(0xFFFDD835),
    );
    canvas.drawCircle(
      Offset(w * 0.62, h * 0.62),
      w * 0.06,
      Paint()..color = const Color(0xFFD9899F),
    );
    // Steam lines
    final steamPaint = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(w * 0.38, h * 0.44),
      Offset(w * 0.35, h * 0.28),
      steamPaint,
    );
    canvas.drawLine(
      Offset(w * 0.50, h * 0.42),
      Offset(w * 0.50, h * 0.26),
      steamPaint,
    );
    canvas.drawLine(
      Offset(w * 0.62, h * 0.44),
      Offset(w * 0.65, h * 0.28),
      steamPaint,
    );
    // Shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.88),
        width: w * 0.55,
        height: h * 0.07,
      ),
      Paint()..color = Colors.black.withOpacity(0.08),
    );
  }

  @override
  bool shouldRepaint(_KitchenPainter old) => false;
}
