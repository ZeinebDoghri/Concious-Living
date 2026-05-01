import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../providers/user_provider.dart';
import '../../../shared/widgets/animated_button.dart';

class HotelLoginScreen extends StatefulWidget {
  const HotelLoginScreen({super.key});

  @override
  State<HotelLoginScreen> createState() => _HotelLoginScreenState();
}

class _HotelLoginScreenState extends State<HotelLoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscure = true;
  bool _isLoading = false;

  late final AnimationController _cardController;
  late final Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();

    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
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
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    if (message.startsWith('StateError: ')) {
      return message.substring('StateError: '.length);
    }
    return message;
  }

  Future<void> _signIn() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
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
    return Scaffold(
      backgroundColor: AppColors.oat,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: const BoxDecoration(color: AppColors.butter),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 56,
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            onPressed: () => context.go(AppRoutes.roleSelector),
                            icon: const Icon(Icons.arrow_back_ios_new),
                            color: AppColors.cherry,
                            splashColor: AppColors.cherry.withValues(alpha: 0.12),
                          ),
                          const Spacer(),
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  'Hotel staff sign in',
                                  style: GoogleFonts.dmSerifDisplay(
                                    fontSize: 24,
                                    color: AppColors.cherry,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Manage buffet inventory & guest safety',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.espresso,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SlideTransition(
                position: _cardSlide,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.parchment,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: AppStrings.emailAddress,
                            prefixIcon:
                                const Icon(Icons.email_outlined, color: AppColors.cocoa),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadii.input),
                              borderSide:
                                  const BorderSide(color: AppColors.cherry, width: 1.4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: AppStrings.password,
                            prefixIcon:
                                const Icon(Icons.lock_outline, color: AppColors.cocoa),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadii.input),
                              borderSide:
                                  const BorderSide(color: AppColors.cherry, width: 1.4),
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
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.go(AppRoutes.hotelForgotPassword),
                            child: Text(
                              AppStrings.forgotPassword,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.cherry,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        AnimatedButton(
                          label: AppStrings.signIn,
                          color: AppColors.butter,
                          textColor: AppColors.cherry,
                          onTap: _signIn,
                          isLoading: _isLoading,
                          height: 52,
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed: () => context.go(AppRoutes.hotelRegister),
                            child: Text(
                              'New hotel? Register here',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.cherry,
                                height: 1.2,
                              ),
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
