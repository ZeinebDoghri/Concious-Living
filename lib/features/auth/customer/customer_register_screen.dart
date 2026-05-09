import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../providers/user_provider.dart';
import '../../../shared/widgets/animated_button.dart';

// ─── FreshGuard Customer Theme (same tokens as login) ────────────────────────
class _FG {
  static const primary       = Color(0xFF5B4E8A);
  static const primaryDark   = Color(0xFF2D2350);
  static const primaryLight  = Color(0xFFC4B8F0);
  static const heroCircle1   = Color(0xFF6E60A0);
  static const heroCircle2   = Color(0xFF4A3D78);
  static const surface       = Color(0xFFF4F2FA);
  static const surfaceTint   = Color(0xFFEDE9F7);
  static const fieldBorder   = Color(0xFFC8C0E8);
  static const textPrimary   = Color(0xFF2D2350);
  static const textSecondary = Color(0xFFA090C0);
  // Semantic (shared across all themes)
  static const freshGreen  = Color(0xFF2E8B69);
  static const warningAmber = Color(0xFFE8872A);
  static const dangerRed   = Color(0xFFE24B4A);
}

class CustomerRegisterScreen extends StatefulWidget {
  const CustomerRegisterScreen({super.key});

  @override
  State<CustomerRegisterScreen> createState() => _CustomerRegisterScreenState();
}

class _CustomerRegisterScreenState extends State<CustomerRegisterScreen>
    with SingleTickerProviderStateMixin {
  final _nameController     = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController  = TextEditingController();

  final _passwordFocus = FocusNode();

  bool _obscure   = true;
  bool _obscure2  = true;
  bool _isLoading = false;

  String? _emailError;

  late final AnimationController _cardController;
  late final Animation<Offset>   _cardSlide;

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();

    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end:   Offset.zero,
    ).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
    );

    _emailController.addListener(_validateEmailRealtime);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _passwordFocus.dispose();
    _cardController.dispose();
    super.dispose();
  }

  void _validateEmailRealtime() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      if (_emailError != null) setState(() => _emailError = null);
      return;
    }
    final ok        = EmailValidator.validate(email);
    final nextError = ok ? null : AppStrings.validationInvalidEmail;
    if (nextError != _emailError) setState(() => _emailError = nextError);
  }

  int _passwordStrength(String v) {
    if (v.isEmpty) return 0;
    int score = 0;
    if (v.length >= 6)  score++;
    if (v.length >= 10) score++;
    if (RegExp(r'[A-Z]').hasMatch(v)) score++;
    if (RegExp(r'[0-9]').hasMatch(v) || RegExp(r'[!@#\$%\^&\*]').hasMatch(v)) score++;
    return score.clamp(0, 4);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _readableError(Object e) {
    final message = e.toString();
    if (message.startsWith('Exception: '))  return message.substring('Exception: '.length);
    if (message.startsWith('StateError: ')) return message.substring('StateError: '.length);
    return message;
  }

  Future<void> _createAccount() async {
    if (_isLoading) return;

    final name     = _nameController.text.trim();
    final email    = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm  = _confirmController.text;

    if (name.isEmpty) {
      _snack(AppStrings.validationRequiredField);
      return;
    }
    if (!EmailValidator.validate(email)) {
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
      await context.read<UserProvider>().registerCustomer(
        name:     name,
        email:    email,
        password: password,
      );
      if (!mounted) return;
      context.go(AppRoutes.customerProfileSetup);
    } catch (e) {
      _snack(_readableError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  TextStyle _playfair({
    double fontSize = 16,
    FontWeight weight = FontWeight.w600,
    Color color = _FG.textPrimary,
    double height = 1.2,
  }) =>
      GoogleFonts.playfairDisplay(fontSize: fontSize, fontWeight: weight, color: color, height: height);

  TextStyle _inter({
    double fontSize = 13,
    FontWeight weight = FontWeight.w400,
    Color color = _FG.textSecondary,
    double height = 1.5,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.inter(fontSize: fontSize, fontWeight: weight, color: color, height: height, letterSpacing: letterSpacing);

  InputDecoration _fieldDecor({
    required String label,
    required IconData prefixIcon,
    Widget? suffix,
    String? errorText,
  }) =>
      InputDecoration(
        labelText: label,
        errorText: errorText,
        labelStyle: _inter(fontSize: 12, weight: FontWeight.w500, color: _FG.textSecondary),
        floatingLabelStyle: _inter(fontSize: 11, weight: FontWeight.w500, color: _FG.primary),
        filled: true,
        fillColor: _FG.surfaceTint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIcon: Icon(prefixIcon, color: _FG.textSecondary, size: 18),
        suffixIcon: suffix,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _FG.fieldBorder, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _FG.primary, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _FG.dangerRed, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _FG.dangerRed, width: 1.2),
        ),
        errorStyle: _inter(fontSize: 10, color: _FG.dangerRed),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      );

  /// Maps strength level 0-4 → FreshGuard semantic color
  Color _strengthColor(int i, int strength) {
    if (strength < i + 1) return _FG.fieldBorder;
    switch (i) {
      case 0: return _FG.dangerRed;
      case 1: return _FG.warningAmber;
      case 2: return _FG.warningAmber;
      default: return _FG.freshGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final password     = _passwordController.text;
    final strength     = _passwordStrength(password);
    final showStrength = _passwordFocus.hasFocus && password.isNotEmpty;
    final mismatch     = _confirmController.text.isNotEmpty &&
        _passwordController.text != _confirmController.text;

    return Scaffold(
      backgroundColor: _FG.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Hero ────────────────────────────────────────────────────────
            SizedBox(
              height: 220,
              width: double.infinity,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned.fill(child: Container(color: _FG.primary)),

                  // Circle 1 — large, top-right
                  Positioned(
                    top: -50,
                    right: -60,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _FG.heroCircle1.withOpacity(0.25),
                      ),
                    ),
                  ),

                  // Circle 2 — small, bottom-left
                  Positioned(
                    bottom: 30,
                    left: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _FG.heroCircle2.withOpacity(0.20),
                      ),
                    ),
                  ),

                  // Food plate circle
                  Positioned(
                    right: -12,
                    bottom: -20,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _FG.primaryDark,
                      ),
                      child: const Center(
                        child: Text('🌿', style: TextStyle(fontSize: 60)),
                      ),
                    ),
                  ),

                  // Back button
                  Positioned(
                    top: 4,
                    left: 4,
                    child: SafeArea(
                      bottom: false,
                      child: IconButton(
                        onPressed: () => context.go(AppRoutes.customerLogin),
                        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                        color: Colors.white,
                        splashColor: Colors.white24,
                      ),
                    ),
                  ),

                  // Greeting
                  Positioned(
                    left: 20,
                    bottom: 32,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'JOIN FRESHGUARD',
                          style: _inter(fontSize: 9, color: Colors.white70).copyWith(letterSpacing: 1.0),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.createYourAccount,
                          style: _playfair(fontSize: 22, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.joinToday,
                          style: _inter(fontSize: 11, color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Floating card panel ─────────────────────────────────────────
            Expanded(
              child: SlideTransition(
                position: _cardSlide,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: _FG.surface,
                    borderRadius: BorderRadius.only(
                      topLeft:  Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tag
                        Text(
                          'CREATE ACCOUNT',
                          style: _inter(fontSize: 9, weight: FontWeight.w500, color: _FG.primary)
                              .copyWith(letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Set up your profile',
                          style: _playfair(fontSize: 20, color: _FG.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Scan meals, track allergens & calories with AI',
                          style: _inter(fontSize: 12, color: _FG.textSecondary, height: 1.5),
                        ),
                        const SizedBox(height: 20),

                        // Full name
                        TextField(
                          controller: _nameController,
                          style: _inter(fontSize: 13, color: _FG.textPrimary),
                          decoration: _fieldDecor(
                            label: AppStrings.fullName,
                            prefixIcon: Icons.person_outline,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Email
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: _inter(fontSize: 13, color: _FG.textPrimary),
                          decoration: _fieldDecor(
                            label: AppStrings.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            errorText: _emailError,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Password
                        TextField(
                          focusNode: _passwordFocus,
                          controller: _passwordController,
                          obscureText: _obscure,
                          onChanged: (_) => setState(() {}),
                          style: _inter(fontSize: 13, color: _FG.textPrimary),
                          decoration: _fieldDecor(
                            label: AppStrings.password,
                            prefixIcon: Icons.lock_outline,
                            suffix: IconButton(
                              onPressed: () => setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: _FG.textSecondary,
                                size: 18,
                              ),
                            ),
                          ),
                        ),

                        // Password strength bar — FreshGuard semantic colors
                        if (showStrength) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: List.generate(4, (i) {
                              return Expanded(
                                child: Container(
                                  height: 4,
                                  margin: EdgeInsets.only(right: i == 3 ? 0 : 6),
                                  decoration: BoxDecoration(
                                    color: _strengthColor(i, strength),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            strength <= 1
                                ? 'Weak password'
                                : strength <= 2
                                    ? 'Fair — add uppercase or symbols'
                                    : strength == 3
                                        ? 'Good'
                                        : 'Strong',
                            style: _inter(
                              fontSize: 10,
                              color: _strengthColor(strength - 1, strength),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),

                        // Confirm password
                        TextField(
                          controller: _confirmController,
                          obscureText: _obscure2,
                          onChanged: (_) => setState(() {}),
                          style: _inter(fontSize: 13, color: _FG.textPrimary),
                          decoration: _fieldDecor(
                            label: AppStrings.confirmPassword,
                            prefixIcon: Icons.lock_outline,
                            suffix: IconButton(
                              onPressed: () => setState(() => _obscure2 = !_obscure2),
                              icon: Icon(
                                _obscure2 ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: _FG.textSecondary,
                                size: 18,
                              ),
                            ),
                          ),
                        ),

                        if (mismatch) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.info_outline, size: 13, color: _FG.dangerRed),
                              const SizedBox(width: 4),
                              Text(
                                AppStrings.validationPasswordsMismatch,
                                style: _inter(fontSize: 10, color: _FG.dangerRed),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Terms
                        Wrap(
                          children: [
                            Text(
                              AppStrings.termsPrefix,
                              style: _inter(fontSize: 11, color: _FG.textSecondary, height: 1.5),
                            ),
                            GestureDetector(
                              onTap: () => _snack(AppStrings.aboutProject),
                              child: Text(
                                AppStrings.termsOfService,
                                style: _inter(
                                  fontSize: 11,
                                  weight: FontWeight.w500,
                                  color: _FG.primary,
                                  height: 1.5,
                                ).copyWith(decoration: TextDecoration.underline),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // CTA
                        AnimatedButton(
                          label: '${AppStrings.createAccountCta} →',
                          color: _FG.primary,
                          textColor: Colors.white,
                          onTap: _createAccount,
                          isLoading: _isLoading,
                          height: 52,
                        ),
                        const SizedBox(height: 10),

                        // Already have account
                        Center(
                          child: TextButton(
                            onPressed: () => context.go(AppRoutes.customerLogin),
                            style: TextButton.styleFrom(foregroundColor: _FG.textSecondary),
                            child: Text(
                              AppStrings.alreadyHaveAccount,
                              style: _inter(fontSize: 11, color: _FG.textSecondary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}