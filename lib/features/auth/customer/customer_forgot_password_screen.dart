import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants.dart';
import '../../../core/firebase_service.dart';
import '../../../shared/widgets/animated_button.dart';
import '../../../shared/widgets/customer_flow_frame.dart';

class CustomerForgotPasswordScreen extends StatefulWidget {
  const CustomerForgotPasswordScreen({super.key});

  @override
  State<CustomerForgotPasswordScreen> createState() =>
      _CustomerForgotPasswordScreenState();
}

class _CustomerForgotPasswordScreenState
    extends State<CustomerForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();

  bool _isLoading = false;
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
      setState(() {
        _sent = true;
      });
      _successController.forward(from: 0);
    } catch (e) {
      _snack(_readableError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomerFlowFrame(
      title: AppStrings.resetPassword,
      subtitle: AppStrings.resetPasswordSubtitle,
      badgeIcon: Icons.lock_reset_rounded,
      badgeLabel: 'Account help',
      highlights: const ['Secure reset', 'Email link', 'Quick recovery'],
      onBack: () => context.go(AppRoutes.customerLogin),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: _sent
            ? _SuccessView(scale: _successScale)
            : _FormView(
                emailController: _emailController,
                isLoading: _isLoading,
                onSend: _send,
              ),
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  final TextEditingController emailController;
  final bool isLoading;
  final Future<void> Function() onSend;

  const _FormView({
    required this.emailController,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('form'),
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.cherryBlush,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.email_outlined,
              size: 32,
              color: AppColors.cherry,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.forgotYourPasswordTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.cherry,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.forgotYourPasswordBody,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.cocoa,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: AppStrings.emailAddress,
              prefixIcon: const Icon(
                Icons.email_outlined,
                color: AppColors.cocoa,
              ),
            ),
          ),
          const SizedBox(height: 20),
          AnimatedButton(
            label: AppStrings.sendResetLink,
            color: AppColors.cherry,
            textColor: AppColors.cherryHeaderText,
            onTap: onSend,
            isLoading: isLoading,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go(AppRoutes.customerLogin),
            child: Text(
              AppStrings.backToSignIn,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.cherry,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final Animation<double> scale;

  const _SuccessView({required this.scale});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('success'),
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 24),
      child: Column(
        children: [
          ScaleTransition(
            scale: scale,
            child: Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.oliveMist,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.check_circle,
                size: 40,
                color: AppColors.olive,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.resetSentTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.olive,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.resetSentBody,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.cocoa,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => context.go(AppRoutes.customerLogin),
            child: Text(
              AppStrings.backToSignIn,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.cherry,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
