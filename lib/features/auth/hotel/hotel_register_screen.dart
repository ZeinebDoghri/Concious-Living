import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../providers/user_provider.dart';
import '../../../shared/widgets/animated_button.dart';

class HotelRegisterScreen extends StatefulWidget {
  const HotelRegisterScreen({super.key});

  @override
  State<HotelRegisterScreen> createState() => _HotelRegisterScreenState();
}

class _HotelRegisterScreenState extends State<HotelRegisterScreen>
    with SingleTickerProviderStateMixin {
  final _hotelController = TextEditingController();
  final _managerController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  final _passwordFocus = FocusNode();

  bool _obscure = true;
  bool _obscure2 = true;
  bool _isLoading = false;

  String? _emailError;

  double _rooms = 80;
  String _hotelType = 'Boutique';

  late final AnimationController _cardController;
  late final Animation<Offset> _cardSlide;

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

    _emailController.addListener(_validateEmailRealtime);
  }

  @override
  void dispose() {
    _hotelController.dispose();
    _managerController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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

  Future<void> _createHotelAccount() async {
    if (_isLoading) return;

    final hotel = _hotelController.text.trim();
    final manager = _managerController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (hotel.isEmpty || manager.isEmpty || phone.isEmpty) {
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
      _snack(_readableError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final password = _passwordController.text;
    final strength = _passwordStrength(password);
    final showStrength = _passwordFocus.hasFocus && password.isNotEmpty;

    final mismatch = _confirmController.text.isNotEmpty &&
        _passwordController.text != _confirmController.text;

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
                            onPressed: () => context.go(AppRoutes.hotelLogin),
                            icon: const Icon(Icons.arrow_back_ios_new),
                            color: AppColors.cherry,
                            splashColor: AppColors.cherry.withValues(alpha: 0.12),
                          ),
                          const Spacer(),
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  'Register your hotel',
                                  style: GoogleFonts.dmSerifDisplay(
                                    fontSize: 24,
                                    color: AppColors.cherry,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Create your team account in minutes',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.espresso,
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
                        TextField(
                          controller: _hotelController,
                          decoration: const InputDecoration(
                            labelText: 'Hotel name',
                            prefixIcon: Icon(Icons.hotel, color: AppColors.cocoa),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _managerController,
                          decoration: const InputDecoration(
                            labelText: 'Manager full name',
                            prefixIcon: Icon(Icons.person_outline, color: AppColors.cocoa),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Professional email',
                            prefixIcon:
                                const Icon(Icons.email_outlined, color: AppColors.cocoa),
                            errorText: _emailError,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone number',
                            prefixIcon: Icon(Icons.phone_outlined, color: AppColors.cocoa),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Number of rooms: ${_rooms.round()}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.espresso,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.cherry,
                            inactiveTrackColor: AppColors.sand,
                            thumbColor: AppColors.cherry,
                            overlayColor: AppColors.cherry.withValues(alpha: 0.12),
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
                          decoration: const InputDecoration(
                            labelText: 'Hotel type',
                            prefixIcon: Icon(Icons.apartment, color: AppColors.cocoa),
                          ),
                          items: _typeOptions
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _hotelType = v);
                          },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          focusNode: _passwordFocus,
                          controller: _passwordController,
                          obscureText: _obscure,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: AppStrings.password,
                            prefixIcon:
                                const Icon(Icons.lock_outline, color: AppColors.cocoa),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure ? Icons.visibility : Icons.visibility_off,
                                color: AppColors.cocoa,
                              ),
                            ),
                          ),
                        ),
                        if (showStrength) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: List.generate(4, (i) {
                              final filled = strength >= (i + 1);
                              final Color color;
                              if (!filled) {
                                color = AppColors.sand;
                              } else {
                                if (i == 0) {
                                  color = AppColors.cherryBlush;
                                } else if (i == 1) {
                                  color = AppColors.butter;
                                } else if (i == 2) {
                                  color = AppColors.cherryLight;
                                } else {
                                  color = AppColors.cherry;
                                }
                              }
                              return Expanded(
                                child: Container(
                                  height: 8,
                                  margin: EdgeInsets.only(right: i == 3 ? 0 : 8),
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.sand, width: 0.5),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextField(
                          controller: _confirmController,
                          obscureText: _obscure2,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: AppStrings.confirmPassword,
                            prefixIcon:
                                const Icon(Icons.lock_outline, color: AppColors.cocoa),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscure2 = !_obscure2),
                              icon: Icon(
                                _obscure2 ? Icons.visibility : Icons.visibility_off,
                                color: AppColors.cocoa,
                              ),
                            ),
                          ),
                        ),
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
                        const SizedBox(height: 20),
                        AnimatedButton(
                          label: 'Create hotel account',
                          color: AppColors.butter,
                          textColor: AppColors.cherry,
                          onTap: _createHotelAccount,
                          isLoading: _isLoading,
                          height: 52,
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
