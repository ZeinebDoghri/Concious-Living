import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../providers/user_provider.dart';
import '../../../shared/widgets/animated_button.dart';
import '../../../shared/widgets/customer_flow_frame.dart';

class CustomerLoginScreen extends StatefulWidget {
  const CustomerLoginScreen({super.key});

  @override
  State<CustomerLoginScreen> createState() => _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends State<CustomerLoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscure = true;
  bool _isLoading = false;

  late final AnimationController _entryController;
  late final Animation<Offset> _entrySlide;
  late final Animation<double> _entryFade;

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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your password')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userProvider = context.read<UserProvider>();
      final user = await userProvider.login(
        email: email,
        password: password,
        role: 'customer',
      );

      if (!mounted) return;

      // Navigate to home with allergens loaded
      context.go(AppRoutes.customerHome);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomerFlowFrame(
      title: AppStrings.welcomeBack,
      subtitle: AppStrings.signInToContinue,
      badgeIcon: Icons.person_rounded,
      badgeLabel: 'Customer access',
      highlights: const [
        'Scan dishes',
        'Track nutrition',
        'Allergen alerts',
      ],
      onBack: () => context.go(AppRoutes.roleSelector),
      child: FadeTransition(
        opacity: _entryFade,
        child: SlideTransition(
          position: _entrySlide,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Welcome banner ──────────────────────────────────────
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
                      Icons.restaurant_rounded,
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
                          'Welcome back',
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
                          'Sign in to keep your meals, alerts, and preferences in sync.',
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

            // ── Email ────────────────────────────────────────────────
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: AppStrings.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.cocoa),
              ),
            ),

            const SizedBox(height: 16),

            // ── Password ─────────────────────────────────────────────
            TextField(
              controller: _passwordController,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: AppStrings.password,
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.cocoa),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure ? Icons.visibility : Icons.visibility_off,
                    color: AppColors.cocoa,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Forgot password ──────────────────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.go(AppRoutes.customerForgot),
                child: Text(
                  AppStrings.forgotPassword,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.olive,
                    height: 1.2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Sign-in button ───────────────────────────────────────
            AnimatedButton(
              label: AppStrings.signIn,
              color: AppColors.olive,
              textColor: AppColors.oliveHeaderText,
              onTap: _signIn,
              isLoading: _isLoading,
              height: 52,
            ),

            const SizedBox(height: 16),

            // ── Divider ──────────────────────────────────────────────
            Row(
              children: [
                const Expanded(
                  child: Divider(color: AppColors.sand, thickness: 0.5),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    AppStrings.orSignInWith,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.fog,
                      height: 1.2,
                    ),
                  ),
                ),
                const Expanded(
                  child: Divider(color: AppColors.sand, thickness: 0.5),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Create account ───────────────────────────────────────
            OutlinedButton.icon(
              onPressed: () => context.go(AppRoutes.customerRegister),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: Text(AppStrings.createAccount),
            ),

            const SizedBox(height: 10),

            // ── Not a customer ───────────────────────────────────────
            Center(
              child: TextButton(
                onPressed: () => context.go(AppRoutes.roleSelector),
                child: Text(
                  AppStrings.notACustomer,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.cocoa,
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