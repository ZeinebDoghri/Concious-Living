import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants.dart';
import '../../../shared/widgets/animated_button.dart';
import '../../../shared/widgets/customer_flow_frame.dart';

class CustomerRegisterScreen extends StatefulWidget {
  const CustomerRegisterScreen({super.key});

  @override
  State<CustomerRegisterScreen> createState() => _CustomerRegisterScreenState();
}

class _CustomerRegisterScreenState extends State<CustomerRegisterScreen>
    with TickerProviderStateMixin {
  // ── Controllers ─────────────────────────────────────────────────────────────
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  // ── Focus nodes ──────────────────────────────────────────────────────────────
  final _passwordFocus = FocusNode();

  // ── UI state ─────────────────────────────────────────────────────────────────
  bool _obscure = true;
  bool _obscure2 = true;
  bool _isLoading = false;
  String? _emailError;

  // ── Animation ────────────────────────────────────────────────────────────────
  late final AnimationController _entryController;
  late final Animation<Offset> _entrySlide;
  late final Animation<double> _entryFade;

  // ── Password-strength helpers ────────────────────────────────────────────────
  int get strength {
    final p = _passwordController.text;
    int score = 0;
    if (p.length >= 8) score++;
    if (p.contains(RegExp(r'[A-Z]'))) score++;
    if (p.contains(RegExp(r'[0-9]'))) score++;
    if (p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) score++;
    return score;
  }

  bool get showStrength => _passwordController.text.isNotEmpty;
  bool get mismatch =>
      _confirmController.text.isNotEmpty &&
      _passwordController.text != _confirmController.text;

  // ── Lifecycle ────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );
    _entryFade = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _entryController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────────────────────
  Future<void> _createAccount() async {
    // Validate email
    final email = _emailController.text.trim();
    if (!EmailValidator.validate(email)) {
      setState(() => _emailError = AppStrings.validationInvalidEmail);
      return;
    }
    setState(() => _emailError = null);

    // Validate password match
    if (mismatch || _passwordController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      // TODO: implement registration logic via UserProvider
      // await context.read<UserProvider>().register(...);
      if (mounted) context.go(AppRoutes.customerHome);
    } catch (e) {
      // TODO: show error snackbar
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return CustomerFlowFrame(
      title: AppStrings.createYourAccount,
      subtitle: AppStrings.joinToday,
      badgeIcon: Icons.badge_rounded,
      badgeLabel: 'Create profile',
      highlights: const [
        'Set goals',
        'Save allergens',
        'Custom alerts',
      ],
      onBack: () => context.go(AppRoutes.customerLogin),
      child: FadeTransition(
        opacity: _entryFade,
        child: SlideTransition(
          position: _entrySlide,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Welcome banner ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.sand, width: 0.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F2C1A1B),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.oliveMist,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_add_alt_rounded,
                      color: AppColors.oliveDark,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Join in a few steps',
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                            color: AppColors.espresso,
                            letterSpacing: 0.2,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Create your account once and personalize nutrition tracking, meal alerts, and your dietary profile.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: AppColors.cocoa,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ── Full name ────────────────────────────────────────────────────
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: AppStrings.fullName,
                prefixIcon: const Icon(
                  Icons.person_outline,
                  color: AppColors.cocoa,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Email ────────────────────────────────────────────────────────
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: AppStrings.emailAddress,
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  color: AppColors.cocoa,
                ),
                errorText: _emailError,
              ),
            ),

            const SizedBox(height: 16),

            // ── Password ─────────────────────────────────────────────────────
            TextField(
              focusNode: _passwordFocus,
              controller: _passwordController,
              obscureText: _obscure,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: AppStrings.password,
                prefixIcon: const Icon(
                  Icons.lock_outline,
                  color: AppColors.cocoa,
                ),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure ? Icons.visibility : Icons.visibility_off,
                    color: AppColors.cocoa,
                  ),
                ),
              ),
            ),

            // ── Password strength bar ────────────────────────────────────────
            if (showStrength) ...[
              const SizedBox(height: 10),
              Row(
                children: List.generate(4, (i) {
                  final filled = strength >= (i + 1);
                  final Color color;
                  if (!filled) {
                    color = AppColors.sand;
                  } else if (i == 0) {
                    color = AppColors.cherryBlush;
                  } else if (i == 1) {
                    color = AppColors.butter;
                  } else if (i == 2) {
                    color = AppColors.oliveMist;
                  } else {
                    color = AppColors.olive;
                  }
                  return Expanded(
                    child: Container(
                      height: 8,
                      margin: EdgeInsets.only(right: i == 3 ? 0 : 8),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.sand,
                          width: 0.5,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],

            const SizedBox(height: 16),

            // ── Confirm password ─────────────────────────────────────────────
            TextField(
              controller: _confirmController,
              obscureText: _obscure2,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: AppStrings.confirmPassword,
                prefixIcon: const Icon(
                  Icons.lock_outline,
                  color: AppColors.cocoa,
                ),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure2 = !_obscure2),
                  icon: Icon(
                    _obscure2 ? Icons.visibility : Icons.visibility_off,
                    color: AppColors.cocoa,
                  ),
                ),
              ),
            ),

            // ── Mismatch error ───────────────────────────────────────────────
            if (mismatch) ...[
              const SizedBox(height: 8),
              Text(
                AppStrings.validationPasswordsMismatch,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.cherry,
                  height: 1.2,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ── Terms ────────────────────────────────────────────────────────
            Wrap(
              children: [
                Text(
                  AppStrings.termsPrefix,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.cocoa,
                    height: 1.4,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    AppStrings.termsOfService,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.olive,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Submit button ────────────────────────────────────────────────
            AnimatedButton(
              label: AppStrings.createAccountCta,
              color: AppColors.olive,
              textColor: AppColors.oliveHeaderText,
              onTap: _createAccount,
              isLoading: _isLoading,
              height: 52,
            ),

            const SizedBox(height: 12),

            // ── Already have account ─────────────────────────────────────────
            Center(
              child: TextButton(
                onPressed: () => context.go(AppRoutes.customerLogin),
                child: Text(
                  AppStrings.alreadyHaveAccount,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.olive,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}