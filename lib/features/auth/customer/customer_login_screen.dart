import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../providers/user_provider.dart';
import '../../../shared/widgets/animated_button.dart';

// ─── FreshGuard Customer Theme tokens ────────────────────────────────────────
// primary        #5B4E8A   hero bg, CTA, active nav
// primaryDark    #2D2350   hero plate circle, AI pill bg
// primaryLight   #C4B8F0   light accent text
// heroCircle1    #6E60A0   large decorative circle (opacity 0.25)
// heroCircle2    #4A3D78   small decorative circle (opacity 0.20)
// surface        #F4F2FA   floating card panel bg
// surfaceTint    #EDE9F7   field bg, stat card bg
// fieldBorder    #C8C0E8   input borders
// textPrimary    #2D2350
// textSecondary  #A090C0
// freshGreen     #2E8B69
// warningAmber   #E8872A
// dangerRed      #E24B4A
// ─────────────────────────────────────────────────────────────────────────────

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
}

class CustomerLoginScreen extends StatefulWidget {
  const CustomerLoginScreen({super.key});

  @override
  State<CustomerLoginScreen> createState() => _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends State<CustomerLoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscure   = true;
  bool _isLoading = false;

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
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _cardController.dispose();
    super.dispose();
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
        email:    email,
        password: password,
        role:     'customer',
      );
      if (!mounted) return;
      context.go(AppRoutes.customerHome);
    } catch (e) {
      _snack(_readableError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Playfair Display text style
  TextStyle _playfair({
    double fontSize = 16,
    FontWeight weight = FontWeight.w600,
    Color color = _FG.textPrimary,
    double height = 1.2,
  }) =>
      GoogleFonts.playfairDisplay(
        fontSize: fontSize,
        fontWeight: weight,
        color: color,
        height: height,
      );

  /// Inter text style
  TextStyle _inter({
    double fontSize = 13,
    FontWeight weight = FontWeight.w400,
    Color color = _FG.textSecondary,
    double height = 1.5,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  InputDecoration _fieldDecor({
    required String label,
    required IconData prefixIcon,
    Widget? suffix,
  }) =>
      InputDecoration(
        labelText: label,
        labelStyle: _inter(fontSize: 12, weight: FontWeight.w500, color: _FG.textSecondary, letterSpacing: 0.06),
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
          borderSide: const BorderSide(color: Color(0xFFE24B4A), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE24B4A), width: 1.2),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      );

  @override
  Widget build(BuildContext context) {
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
                  // Solid primary background
                  Positioned.fill(
                    child: Container(color: _FG.primary),
                  ),

                  // Decorative circle 1 — large, top-right
                  Positioned(
                    top: -50,
                    right: -60,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _FG.heroCircle1,
                      ),
                      // opacity applied via ColorFiltered to stay const-compatible
                    ),
                  ),

                  // Decorative circle 2 — small, bottom-left
                  Positioned(
                    bottom: 30,
                    left: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _FG.heroCircle2,
                      ),
                    ),
                  ),

                  // Food plate circle — bleeds off bottom-right
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
                        child: Text('🥗', style: TextStyle(fontSize: 60)),
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
                        onPressed: () => context.go(AppRoutes.roleSelector),
                        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                        color: Colors.white,
                        splashColor: Colors.white24,
                      ),
                    ),
                  ),

                  // Greeting text
                  Positioned(
                    left: 20,
                    bottom: 32,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'AI FOOD SAFETY',
                          style: _inter(
                            fontSize: 9,
                            color: Colors.white70,
                            letterSpacing: 0.08,
                          ).copyWith(letterSpacing: 1.0),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.welcomeBack,
                          style: _playfair(fontSize: 22, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.signInToContinue,
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
                        // Section tag
                        Text(
                          'WELCOME BACK',
                          style: _inter(
                            fontSize: 9,
                            weight: FontWeight.w500,
                            color: _FG.primary,
                            letterSpacing: 0.12,
                          ).copyWith(letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.customerSignInTitle,
                          style: _playfair(fontSize: 20, color: _FG.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.customerSignInSubtitle,
                          style: _inter(fontSize: 12, color: _FG.textSecondary, height: 1.5),
                        ),
                        const SizedBox(height: 20),

                        // Role pills
                        Container(
                          decoration: BoxDecoration(
                            color: _FG.surfaceTint,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: _FG.fieldBorder, width: 0.5),
                          ),
                          padding: const EdgeInsets.all(3),
                          child: Row(
                            children: [
                              _rolePill('Restaurant', active: false),
                              _rolePill('Hotel', active: false),
                              _rolePill('Guest', active: true),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Email field
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: _inter(fontSize: 13, color: _FG.textPrimary),
                          decoration: _fieldDecor(
                            label: AppStrings.emailAddress,
                            prefixIcon: Icons.email_outlined,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Password field
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscure,
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
                        const SizedBox(height: 6),

                        // Forgot password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.go(AppRoutes.customerForgot),
                            style: TextButton.styleFrom(
                              foregroundColor: _FG.primary,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              AppStrings.forgotPassword,
                              style: _inter(fontSize: 11, weight: FontWeight.w500, color: _FG.primary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // CTA button
                        AnimatedButton(
                          label: '${AppStrings.signIn} →',
                          color: _FG.primary,
                          textColor: Colors.white,
                          onTap: _signIn,
                          isLoading: _isLoading,
                          height: 52,
                        ),
                        const SizedBox(height: 16),

                        // Divider
                        Row(
                          children: [
                            const Expanded(child: Divider(color: _FG.fieldBorder, thickness: 0.5)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                AppStrings.orSignInWith,
                                style: _inter(fontSize: 11, color: _FG.textSecondary),
                              ),
                            ),
                            const Expanded(child: Divider(color: _FG.fieldBorder, thickness: 0.5)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Google / create account button
                        OutlinedButton(
                          onPressed: () => context.go(AppRoutes.customerRegister),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            foregroundColor: _FG.textPrimary,
                            side: const BorderSide(color: _FG.fieldBorder, width: 0.8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            textStyle: _inter(fontSize: 13, weight: FontWeight.w500, color: _FG.textPrimary),
                          ),
                          child: Text(
                            AppStrings.createAccount,
                            style: _inter(fontSize: 13, weight: FontWeight.w500, color: _FG.textPrimary),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Not a customer link
                        Center(
                          child: TextButton(
                            onPressed: () => context.go(AppRoutes.roleSelector),
                            style: TextButton.styleFrom(
                              foregroundColor: _FG.textSecondary,
                            ),
                            child: Text(
                              AppStrings.notACustomer,
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

  Widget _rolePill(String label, {required bool active}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: active ? _FG.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: _inter(
            fontSize: 9,
            weight: FontWeight.w500,
            color: active ? Colors.white : _FG.textSecondary,
          ),
        ),
      ),
    );
  }
}