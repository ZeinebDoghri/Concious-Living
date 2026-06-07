import 'dart:math' as math;

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../providers/user_provider.dart';

// ── Hotel — Granite Ridge (slate blue-grey) ───────────────────────────────────
const _kBg = Color(0xFFF0F5F8); // lightest tint of hotel slate
const _kPrimary = Color(0xFF5A9FC9);
const _kDeep = Color(0xFF35658F);
const _kSoftBg = Color(0xFFD9E9F5);
const _kBorder = Color(0xFFB6CAD6);
const _kTitle = Color(0xFF26201B);
const _kMuted = Color(0xFF8C7E78);
const _kBody = Color(0xFF5C4F48);

const _kCustAccent = Color(0xFFD9899F);
const _kRestAccent = Color(0xFF8FA84A);

class HotelRegisterScreen extends StatefulWidget {
  const HotelRegisterScreen({super.key});

  @override
  State<HotelRegisterScreen> createState() => _HotelRegisterScreenState();
}

class _HotelRegisterScreenState extends State<HotelRegisterScreen>
    with SingleTickerProviderStateMixin {
  final _hotelCtrl = TextEditingController();
  final _managerCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _passwordFocus = FocusNode();

  bool _obscure = true;
  bool _obscure2 = true;
  bool _isLoading = false;
  bool _pressed = false;

  String? _emailError;

  double _rooms = 80;
  String _hotelType = 'Boutique';

  late final AnimationController _blobCtrl;

  static const _typeOptions = <String>[
    'Boutique',
    'Business',
    'Resort',
    'Budget',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _blobCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _emailCtrl.addListener(_validateEmailRealtime);
  }

  @override
  void dispose() {
    _hotelCtrl.dispose();
    _managerCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _passwordFocus.dispose();
    _blobCtrl.dispose();
    super.dispose();
  }

  void _validateEmailRealtime() {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      if (_emailError != null) setState(() => _emailError = null);
      return;
    }
    final ok = EmailValidator.validate(email);
    final nextError = ok ? null : AppStrings.validationInvalidEmail;
    if (nextError != _emailError) setState(() => _emailError = nextError);
  }

  int _passwordStrength(String v) {
    if (v.isEmpty) return 0;
    int score = 0;
    if (v.length >= 6) score++;
    if (v.length >= 10) score++;
    if (RegExp(r'[A-Z]').hasMatch(v)) score++;
    if (RegExp(r'[0-9]').hasMatch(v) || RegExp(r'[!@#\$%\^&\*]').hasMatch(v)) {
      score++;
    }
    return score.clamp(0, 4);
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _showRegisterError(Object error) {
    final message = _readable(error);
    String snackMessage = message;
    String? actionLabel;
    String? actionRoute;

    if (message.toLowerCase().contains('already in use')) {
      snackMessage = 'This email is already registered.';
      actionLabel = 'Sign In';
      actionRoute = AppRoutes.hotelLogin;
    } else if (message.toLowerCase().contains('weak')) {
      snackMessage = 'Password too weak (minimum 6 characters).';
    } else if (message.toLowerCase().contains('valid email')) {
      snackMessage = 'Invalid email address.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(snackMessage),
        action: actionLabel == null
            ? null
            : SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: () => context.go(actionRoute!),
              ),
        duration: const Duration(seconds: 5),
        backgroundColor: const Color(0xFFFF6B8A),
      ),
    );
  }

  String _readable(Object e) {
    final s = e.toString();
    if (s.startsWith('Exception: ')) return s.substring(11);
    if (s.startsWith('StateError: ')) return s.substring(12);
    return s;
  }

  Future<void> _createHotelAccount() async {
    if (_isLoading) return;
    HapticFeedback.selectionClick();

    final hotel = _hotelCtrl.text.trim();
    final manager = _managerCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    if (hotel.isEmpty || manager.isEmpty || phone.isEmpty) {
      _snack(AppStrings.validationRequiredField);
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      _snack(AppStrings.validationInvalidEmail);
      return;
    }
    if (password.length < 6) {
      _snack(AppStrings.validationPasswordMin);
      return;
    }
    if (password != confirm) {
      _snack(AppStrings.validationPasswordsMismatch);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await context.read<UserProvider>().registerHotel(
        hotelName: hotel,
        managerName: manager,
        email: email,
        phone: phone,
        password: password,
      );
      if (!mounted) return;
      context.go(
        AppRoutes.hotelSetup,
        extra: <String, dynamic>{
          'hotelName': hotel,
          'hotelType': _hotelType,
          'rooms': _rooms.round(),
        },
      );
    } catch (e) {
      _showRegisterError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final heroH = screenH * 0.44;

    final password = _passwordCtrl.text;
    final strength = _passwordStrength(password);
    final showStrength = _passwordFocus.hasFocus && password.isNotEmpty;
    final mismatch =
        _confirmCtrl.text.isNotEmpty && _passwordCtrl.text != _confirmCtrl.text;

    return Scaffold(
      backgroundColor: _kBg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Full background blobs ────────────────────────────────────
          AnimatedBuilder(
            animation: _blobCtrl,
            builder: (_, _) => CustomPaint(
              painter: _BlobBgPainter(_blobCtrl.value),
              size: Size(double.infinity, MediaQuery.of(context).size.height),
            ),
          ),

          // ── Hero zone ────────────────────────────────────────────────
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
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              context.go(AppRoutes.hotelLogin);
                            },
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              size: 20,
                            ),
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
                                        'Hotel',
                                        style: GoogleFonts.cormorantGaramond(
                                          fontSize: 40,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          height: 1.05,
                                        ),
                                      ),
                                      Text(
                                        'Portal',
                                        style: GoogleFonts.cormorantGaramond(
                                          fontSize: 40,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          height: 1.05,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'GUEST OPERATIONS',
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
                                const _HotelIllustration(size: 108),
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

          // ── Floating card ────────────────────────────────────────────
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
                    // Card header row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start with us',
                                style: GoogleFonts.cormorantGaramond(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: _kTitle,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Streamline guest management',
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
                                'Hotel',
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
                      controller: _hotelCtrl,
                      label: 'Hotel name',
                      icon: Icons.hotel,
                    ),
                    const SizedBox(height: 14),
                    _buildInput(
                      controller: _managerCtrl,
                      label: 'Manager full name',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 14),
                    _buildInput(
                      controller: _emailCtrl,
                      label: 'Professional email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      errorText: _emailError,
                    ),
                    const SizedBox(height: 14),
                    _buildInput(
                      controller: _phoneCtrl,
                      label: 'Phone number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Number of rooms: ${_rooms.round()}',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kBody,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _kPrimary,
                        inactiveTrackColor: _kSoftBg,
                        thumbColor: _kDeep,
                        overlayColor: _kPrimary.withOpacity(0.12),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _rooms,
                        min: 10,
                        max: 500,
                        divisions: 49,
                        onChanged: (v) => setState(() => _rooms = v),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _hotelType,
                      decoration: InputDecoration(
                        labelText: 'Hotel type',
                        labelStyle: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: _kMuted,
                        ),
                        prefixIcon: const Icon(
                          Icons.apartment,
                          color: _kMuted,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: _kSoftBg,
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
                          borderSide: const BorderSide(
                            color: _kPrimary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      items: _typeOptions
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(growable: false),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _hotelType = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildInput(
                      controller: _passwordCtrl,
                      label: AppStrings.password,
                      icon: Icons.lock_outline,
                      obscure: _obscure,
                      focusNode: _passwordFocus,
                      onChanged: (_) => setState(() {}),
                      onToggleObscure: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                    if (showStrength) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: List.generate(4, (i) {
                          final filled = strength >= (i + 1);
                          final Color color;
                          if (!filled) {
                            color = const Color(0xFFE2E8F0);
                          } else {
                            if (i == 0) {
                              color = const Color(0xFFF87171);
                            } else if (i == 1)
                              color = const Color(0xFFFBBF24);
                            else if (i == 2)
                              color = const Color(0xFF34D399);
                            else
                              color = _kDeep;
                          }
                          return Expanded(
                            child: Container(
                              height: 6,
                              margin: EdgeInsets.only(right: i == 3 ? 0 : 6),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildInput(
                      controller: _confirmCtrl,
                      label: AppStrings.confirmPassword,
                      icon: Icons.lock_outline,
                      obscure: _obscure2,
                      onChanged: (_) => setState(() {}),
                      onToggleObscure: () =>
                          setState(() => _obscure2 = !_obscure2),
                    ),
                    if (mismatch) ...[
                      const SizedBox(height: 6),
                      Text(
                        AppStrings.validationPasswordsMismatch,
                        style: GoogleFonts.dmSans(fontSize: 11, color: _kDeep),
                      ),
                    ],
                    const SizedBox(height: 20),

                    _buildCta(
                      label: 'Create hotel account',
                      onTap: _createHotelAccount,
                    ),

                    const SizedBox(height: 20),

                    // Mixed-color accent strip
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _pill(_kPrimary),
                          const SizedBox(width: 4),
                          _pill(_kCustAccent),
                          const SizedBox(width: 4),
                          _pill(_kRestAccent),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Already have account
                    Center(
                      child: GestureDetector(
                        onTap: () => context.go(AppRoutes.hotelLogin),
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: _kMuted,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Already have an account?  ',
                              ),
                              TextSpan(
                                text: 'Sign in',
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
    FocusNode? focusNode,
    String? errorText,
    ValueChanged<String>? onChanged,
    VoidCallback? onToggleObscure,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure ?? false,
      focusNode: focusNode,
      onChanged: onChanged,
      style: GoogleFonts.dmSans(fontSize: 14, color: _kTitle),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(fontSize: 14, color: _kMuted),
        errorText: errorText,
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

// ── Hero blobs (inside gradient header) ───────────────────────────────────────
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

// ── Full-page background blobs ─────────────────────────────────────────────────
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

// ── Hotel building illustration ────────────────────────────────────────────────
class _HotelIllustration extends StatelessWidget {
  final double size;
  const _HotelIllustration({required this.size});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _HotelPainter()),
  );
}

class _HotelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final buildingPaint = Paint()..color = Colors.white.withOpacity(0.90);
    final windowPaint = Paint()
      ..color = const Color(0xFF6A8494).withOpacity(0.55);
    final accentPaint = Paint()
      ..color = const Color(0xFFD9899F).withOpacity(0.80);

    // Main building body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.20, h * 0.28, w * 0.60, h * 0.62),
        const Radius.circular(6),
      ),
      buildingPaint,
    );

    // Roof / top accent bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.18, h * 0.24, w * 0.64, h * 0.08),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF3E5462).withOpacity(0.85),
    );

    // Windows — 3 rows × 3 cols
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        final wx = w * (0.30 + col * 0.18);
        final wy = h * (0.36 + row * 0.16);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(wx, wy, w * 0.10, h * 0.09),
            const Radius.circular(2),
          ),
          windowPaint,
        );
      }
    }

    // Door
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.42, h * 0.75, w * 0.16, h * 0.16),
        const Radius.circular(3),
      ),
      accentPaint,
    );

    // Door handle
    canvas.drawCircle(
      Offset(w * 0.56, h * 0.83),
      w * 0.025,
      Paint()..color = Colors.white.withOpacity(0.70),
    );
  }

  @override
  bool shouldRepaint(_HotelPainter old) => false;
}
