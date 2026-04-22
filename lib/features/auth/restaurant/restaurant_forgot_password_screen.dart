import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants.dart';
import '../../../core/firebase_service.dart';
import '../../../shared/widgets/animated_button.dart';

class RestaurantForgotPasswordScreen extends StatefulWidget {
  const RestaurantForgotPasswordScreen({super.key});

  @override
  State<RestaurantForgotPasswordScreen> createState() =>
      _RestaurantForgotPasswordScreenState();
}

class _RestaurantForgotPasswordScreenState
    extends State<RestaurantForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();

  bool _isSending = false;
  bool _sent = false;

  late final AnimationController _successController;
  late final Animation<double> _successScale;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScale = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _successController.dispose();
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
      setState(() {
        _sent = true;
      });
      await _successController.forward(from: 0);
    } catch (e) {
        _snack(_readableError(e));
    } finally {
      if (mounted) setState(() => _isSending = false);
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
              decoration: const BoxDecoration(color: AppColors.olive),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 56,
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.06),
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
                            onPressed: () => context.go(AppRoutes.restaurantLogin),
                            icon: const Icon(Icons.arrow_back_ios_new),
                            color: AppColors.oliveHeaderText,
                            splashColor: AppColors.oliveHeaderText.withValues(alpha: 0.15),
                          ),
                          const Spacer(),
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  AppStrings.resetYourPassword,
                                  style: GoogleFonts.dmSerifDisplay(
                                    fontSize: 24,
                                    color: AppColors.oliveHeaderText,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppStrings.resetPasswordSubtitle,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.oliveMist,
                                    height: 1.3,
                                  ),
                                  textAlign: TextAlign.center,
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
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.parchment,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, anim) {
                      return FadeTransition(opacity: anim, child: child);
                    },
                    child: _sent
                        ? _SuccessPanel(scale: _successScale)
                        : _FormPanel(
                            emailController: _emailController,
                            isSending: _isSending,
                            onSend: _send,
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

class _FormPanel extends StatelessWidget {
  final TextEditingController emailController;
  final bool isSending;
  final Future<void> Function() onSend;

  const _FormPanel({
    required this.emailController,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.enterYourEmail,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.cocoa,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: AppStrings.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined, color: AppColors.cocoa),
          ),
        ),
        const SizedBox(height: 18),
        AnimatedButton(
          label: AppStrings.sendResetLink,
          color: AppColors.olive,
          textColor: AppColors.oliveHeaderText,
          onTap: onSend,
          isLoading: isSending,
          height: 52,
        ),
        const Spacer(),
        Center(
          child: TextButton(
            onPressed: () => context.go(AppRoutes.restaurantLogin),
            child: Text(
              AppStrings.backToSignIn,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.olive,
                height: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SuccessPanel extends StatelessWidget {
  final Animation<double> scale;

  const _SuccessPanel({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('success'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: scale,
          child: Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              color: AppColors.oliveMist,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: AppColors.olive, size: 42),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppStrings.checkYourEmail,
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.olive,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.resetEmailSent,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.cocoa,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        AnimatedButton(
          label: AppStrings.backToSignIn,
          color: AppColors.olive,
          textColor: AppColors.oliveHeaderText,
          onTap: () async => context.go(AppRoutes.restaurantLogin),
          height: 52,
        ),
      ],
    );
  }
}
