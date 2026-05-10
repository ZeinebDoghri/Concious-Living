import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../core/firebase_service.dart';
import '../../../providers/user_provider.dart';
import '../../../shared/widgets/animated_button.dart';

// Restaurant role colors
const _primary = Color(0xFF8FA84A);
const _deep = Color(0xFF5A7030);
const _surface = Color(0xFFF5F8EE);
const _softBg = Color(0xFFE3E8D1);
const _textTitle = Color(0xFF26201B);
const _textBody = Color(0xFF5C4F48);
const _textMuted = Color(0xFF8C7E78);

class RestaurantSetupScreen extends StatefulWidget {
  final Map<String, dynamic>? args;

  const RestaurantSetupScreen({super.key, this.args});

  @override
  State<RestaurantSetupScreen> createState() => _RestaurantSetupScreenState();
}

class _RestaurantSetupScreenState extends State<RestaurantSetupScreen>
    with TickerProviderStateMixin {
  int _step = 0;
  int _prevStep = 0;

  final _restaurantNameController = TextEditingController();

  Uint8List? _logoBytes;

  String _cuisine = 'Tunisian';
  double _covers = 80;

  int _staffCount = 12;
  final Set<String> _roles = <String>{'Chef'};
  bool _allergyHandling = true;

  bool _notifySpoilage = true;
  bool _notifyLowInventory = true;
  bool _notifyWasteTips = true;
  double _wasteThreshold = 20;
  double _weeklyCompostGoalKg = 40;
  double _weeklyWasteCapKg = 30;

  bool _completing = false;

  late final AnimationController _blobController;

  static const _cuisineOptions = <String>[
    'Tunisian',
    'Mediterranean',
    'Italian',
    'Fast food',
    'Buffet',
    'Fine dining',
    'Other',
  ];

  static const _roleOptions = <String>['Chef', 'Server', 'Cleaner', 'Manager'];

  @override
  void initState() {
    super.initState();

    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    final args = widget.args ?? const <String, dynamic>{};
    final restaurantName = (args['restaurantName'] as String?)?.trim();
    final cuisineType = (args['cuisineType'] as String?)?.trim();
    final covers = args['covers'];

    if (restaurantName != null && restaurantName.isNotEmpty) {
      _restaurantNameController.text = restaurantName;
    }
    if (cuisineType != null && cuisineType.isNotEmpty) {
      _cuisine = cuisineType;
    }
    if (covers is int) {
      _covers = covers.toDouble().clamp(10, 500);
    } else if (covers is double) {
      _covers = covers.clamp(10, 500);
    }
  }

  @override
  void dispose() {
    _restaurantNameController.dispose();
    _blobController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step >= 3) return;
    setState(() {
      _prevStep = _step;
      _step += 1;
    });
  }

  void _back() {
    if (_step <= 0) return;
    setState(() {
      _prevStep = _step;
      _step -= 1;
    });
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _logoBytes = bytes);
  }

  void _toggleRole(String role) {
    setState(() {
      if (_roles.contains(role)) {
        _roles.remove(role);
      } else {
        _roles.add(role);
      }
    });
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _readableError(Object e) {
    final message = e.toString();
    if (message.startsWith('Exception: '))
      return message.substring('Exception: '.length);
    if (message.startsWith('StateError: '))
      return message.substring('StateError: '.length);
    return message;
  }

  Future<void> _complete() async {
    if (_completing) return;

    final restaurantName = _restaurantNameController.text.trim();
    if (restaurantName.isEmpty) {
      _snack(AppStrings.validationRequiredField);
      return;
    }

    setState(() => _completing = true);

    try {
      final userProvider = context.read<UserProvider>();
      final current = userProvider.currentUser;
      if (current == null) {
        _snack('Please sign in again.');
        return;
      }

      String? uploadedLogoUrl;
      if (_logoBytes != null) {
        try {
          uploadedLogoUrl = await FirebaseService.uploadProfilePhoto(
            userId: current.id,
            bytes: _logoBytes!,
          );
        } catch (_) {
          uploadedLogoUrl = null;
        }
      }

      final updated = current.copyWith(
        role: 'restaurant',
        avatarPath: uploadedLogoUrl ?? current.avatarPath,
        restaurantName: restaurantName,
        cuisineType: _cuisine,
        teamSize: _staffCount,
        staffRoles: _roles.toList(growable: false),
        allergyHandling: _allergyHandling,
        covers: _covers.round(),
        notifyAllergens: _notifySpoilage,
        notifyWeeklyReport: _notifyLowInventory,
        notifyDailyIntake: _notifyWasteTips,
        wasteThreshold: _wasteThreshold,
      );

      await userProvider.saveProfile(updated);
      await FirebaseFirestore.instance.collection('users').doc(current.id).set({
        'entityId': current.id,
        'restaurantId': current.id,
      }, SetOptions(merge: true));
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(current.id)
          .set({
            'compostQuota': {
              'weeklyCompostGoalKg': _weeklyCompostGoalKg,
              'weeklyWasteCapKg': _weeklyWasteCapKg,
            },
          }, SetOptions(merge: true));
      if (!mounted) return;
      context.go(AppRoutes.restaurantDashboard);
    } catch (e) {
      _snack(_readableError(e));
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  Widget _stepContent() {
    switch (_step) {
      case 0:
        return _RestaurantDetailsStep(
          logoBytes: _logoBytes,
          onPickLogo: _pickLogo,
          restaurantNameController: _restaurantNameController,
          cuisine: _cuisine,
          cuisineOptions: _cuisineOptions,
          onCuisine: (v) => setState(() => _cuisine = v),
          covers: _covers,
          onCovers: (v) => setState(() => _covers = v),
        );
      case 1:
        return _TeamSetupStep(
          staffCount: _staffCount,
          onStaffCount: (v) => setState(() => _staffCount = v),
          roles: _roles,
          roleOptions: _roleOptions,
          onToggleRole: _toggleRole,
          allergyHandling: _allergyHandling,
          onAllergyHandling: (v) => setState(() => _allergyHandling = v),
        );
      case 2:
        return _CompostQuotaStep(
          weeklyCompostGoalKg: _weeklyCompostGoalKg,
          weeklyWasteCapKg: _weeklyWasteCapKg,
          onWeeklyCompostGoal: (v) => setState(() => _weeklyCompostGoalKg = v),
          onWeeklyWasteCap: (v) => setState(() => _weeklyWasteCapKg = v),
        );
      case 3:
      default:
        return _AlertPreferencesStep(
          notifySpoilage: _notifySpoilage,
          notifyLowInventory: _notifyLowInventory,
          notifyWasteTips: _notifyWasteTips,
          onNotifySpoilage: (v) => setState(() => _notifySpoilage = v),
          onNotifyLowInventory: (v) => setState(() => _notifyLowInventory = v),
          onNotifyWasteTips: (v) => setState(() => _notifyWasteTips = v),
          wasteThreshold: _wasteThreshold,
          onWasteThreshold: (v) => setState(() => _wasteThreshold = v),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final forward = _step >= _prevStep;
    final screenH = MediaQuery.of(context).size.height;
    final heroH = screenH * 0.32;

    return Scaffold(
      backgroundColor: _primary,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Hero zone ────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroH,
            child: Stack(
              children: [
                Container(color: _primary),
                AnimatedBuilder(
                  animation: _blobController,
                  builder: (_, __) => CustomPaint(
                    painter: _BlobPainter(_blobController.value, _primary),
                    size: Size(double.infinity, heroH),
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
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (_step > 0) {
                                  _back();
                                } else {
                                  context.go(AppRoutes.restaurantRegister);
                                }
                              },
                              icon: const Icon(Icons.arrow_back_ios_new),
                              color: Colors.white,
                            ),
                            const Spacer(),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          'Restaurant setup',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'A few details to get started',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Floating card ────────────────────────────────────────────
          Positioned(
            top: heroH - 24,
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
                boxShadow: AppShadows.lg(_primary),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _SetupStepHeader(step: _step),
                  const SizedBox(height: 16),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeInOut,
                      switchOutCurve: Curves.easeInOut,
                      transitionBuilder: (child, animation) {
                        final inTween = Tween<Offset>(
                          begin: forward
                              ? const Offset(1, 0)
                              : const Offset(-1, 0),
                          end: Offset.zero,
                        );
                        final outTween = Tween<Offset>(
                          begin: Offset.zero,
                          end: forward
                              ? const Offset(-1, 0)
                              : const Offset(1, 0),
                        );
                        final isIncoming = child.key == ValueKey(_step);
                        final offsetAnim = isIncoming
                            ? inTween.animate(animation)
                            : outTween.animate(animation);
                        return SlideTransition(
                          position: offsetAnim,
                          child: child,
                        );
                      },
                      child: SingleChildScrollView(
                        key: ValueKey(_step),
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        child: _stepContent(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: AnimatedButton(
                      label: _step == 2
                          ? AppStrings.continueCta
                          : _step == 3
                          ? 'Start managing'
                          : AppStrings.continueCta,
                      color: _primary,
                      textColor: Colors.white,
                      onTap: _step == 3
                          ? _complete
                          : () async {
                              if (_step == 0 &&
                                  _restaurantNameController.text
                                      .trim()
                                      .isEmpty) {
                                _snack(AppStrings.validationRequiredField);
                                return;
                              }
                              _next();
                            },
                      isLoading: _completing,
                      height: 52,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step progress ────────────────────────────────────────────────────────────

class _SetupStepHeader extends StatelessWidget {
  final int step;
  const _SetupStepHeader({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _dot(active: step == 0, complete: step > 0),
          Expanded(
            child: Container(
              height: 2,
              color: step > 0 ? _primary : const Color(0xFFE2E8F0),
            ),
          ),
          _dot(active: step == 1, complete: step > 1),
          Expanded(
            child: Container(
              height: 2,
              color: step > 1 ? _primary : const Color(0xFFE2E8F0),
            ),
          ),
          _dot(active: step == 2, complete: step > 2),
          Expanded(
            child: Container(
              height: 2,
              color: step > 2 ? _primary : const Color(0xFFE2E8F0),
            ),
          ),
          _dot(active: step == 3, complete: false),
        ],
      ),
    );
  }

  Widget _dot({required bool active, required bool complete}) {
    if (complete) return const _FilledDot(size: 16, color: _deep);
    if (active) return const _FilledDot(size: 24, color: _primary);
    return const _OutlinedDot(size: 16, color: Color(0xFFE2E8F0));
  }
}

class _FilledDot extends StatelessWidget {
  final double size;
  final Color color;
  const _FilledDot({required this.size, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _OutlinedDot extends StatelessWidget {
  final double size;
  final Color color;
  const _OutlinedDot({required this.size, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.transparent,
      shape: BoxShape.circle,
      border: Border.all(color: color, width: 2),
    ),
  );
}

// ── Step 0: Restaurant details ───────────────────────────────────────────────

class _RestaurantDetailsStep extends StatelessWidget {
  final Uint8List? logoBytes;
  final Future<void> Function() onPickLogo;
  final TextEditingController restaurantNameController;
  final String cuisine;
  final List<String> cuisineOptions;
  final ValueChanged<String> onCuisine;
  final double covers;
  final ValueChanged<double> onCovers;

  const _RestaurantDetailsStep({
    required this.logoBytes,
    required this.onPickLogo,
    required this.restaurantNameController,
    required this.cuisine,
    required this.cuisineOptions,
    required this.onCuisine,
    required this.covers,
    required this.onCovers,
  });

  @override
  Widget build(BuildContext context) {
    final logo = logoBytes != null
        ? CircleAvatar(radius: 45, backgroundImage: MemoryImage(logoBytes!))
        : const CircleAvatar(
            radius: 45,
            backgroundColor: _softBg,
            child: Icon(Icons.restaurant, size: 42, color: _primary),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.center,
          child: Stack(
            children: [
              logo,
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: onPickLogo,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: _primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.camera_alt,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: restaurantNameController,
          style: GoogleFonts.inter(fontSize: 14, color: _textTitle),
          decoration: InputDecoration(
            labelText: 'Restaurant name',
            labelStyle: GoogleFonts.inter(fontSize: 14, color: _textMuted),
            prefixIcon: const Icon(
              Icons.restaurant,
              color: _textMuted,
              size: 20,
            ),
            filled: true,
            fillColor: _softBg,
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
              borderSide: const BorderSide(color: _primary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: cuisine,
          decoration: InputDecoration(
            labelText: 'Cuisine type',
            labelStyle: GoogleFonts.inter(fontSize: 14, color: _textMuted),
            prefixIcon: const Icon(
              Icons.local_dining,
              color: _textMuted,
              size: 20,
            ),
            filled: true,
            fillColor: _softBg,
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
              borderSide: const BorderSide(color: _primary, width: 1.5),
            ),
          ),
          items: cuisineOptions
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(growable: false),
          onChanged: (v) {
            if (v != null) onCuisine(v);
          },
        ),
        const SizedBox(height: 18),
        Text(
          'Number of covers: ${covers.round()}',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _textBody,
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _primary,
            inactiveTrackColor: _softBg,
            thumbColor: _deep,
            overlayColor: _primary.withValues(alpha: 0.12),
            trackHeight: 4,
          ),
          child: Slider(
            value: covers,
            min: 10,
            max: 500,
            divisions: 49,
            onChanged: onCovers,
          ),
        ),
      ],
    );
  }
}

// ── Step 1: Team setup ───────────────────────────────────────────────────────

class _TeamSetupStep extends StatelessWidget {
  final int staffCount;
  final ValueChanged<int> onStaffCount;
  final Set<String> roles;
  final List<String> roleOptions;
  final ValueChanged<String> onToggleRole;
  final bool allergyHandling;
  final ValueChanged<bool> onAllergyHandling;

  const _TeamSetupStep({
    required this.staffCount,
    required this.onStaffCount,
    required this.roles,
    required this.roleOptions,
    required this.onToggleRole,
    required this.allergyHandling,
    required this.onAllergyHandling,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Team setup',
          style: GoogleFonts.playfairDisplay(fontSize: 18, color: _textTitle),
        ),
        const SizedBox(height: 12),
        Text(
          'Staff count',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _textBody,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: _primary,
                  inactiveTrackColor: _softBg,
                  thumbColor: _deep,
                  overlayColor: _primary.withValues(alpha: 0.12),
                ),
                child: Slider(
                  value: staffCount.toDouble(),
                  min: 1,
                  max: 80,
                  divisions: 79,
                  onChanged: (v) => onStaffCount(v.round()),
                ),
              ),
            ),
            SizedBox(
              width: 56,
              child: Text(
                '$staffCount',
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Roles in your team',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _textBody,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: roleOptions
              .map((r) {
                final selected = roles.contains(r);
                return ChoiceChip(
                  label: Text(r),
                  selected: selected,
                  onSelected: (_) => onToggleRole(r),
                  selectedColor: _softBg,
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: selected ? _primary : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                  labelStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? _deep : _textMuted,
                  ),
                );
              })
              .toList(growable: false),
        ),
        const SizedBox(height: 18),
        Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(AppRadii.innerCard),
            border: Border.all(color: _softBg, width: 1),
          ),
          child: SwitchListTile(
            value: allergyHandling,
            onChanged: onAllergyHandling,
            activeColor: _primary,
            activeTrackColor: _softBg,
            title: Text(
              'Allergy handling',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textTitle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Step 2: Alert preferences ────────────────────────────────────────────────

class _CompostQuotaStep extends StatelessWidget {
  final double weeklyCompostGoalKg;
  final double weeklyWasteCapKg;
  final ValueChanged<double> onWeeklyCompostGoal;
  final ValueChanged<double> onWeeklyWasteCap;

  const _CompostQuotaStep({
    required this.weeklyCompostGoalKg,
    required this.weeklyWasteCapKg,
    required this.onWeeklyCompostGoal,
    required this.onWeeklyWasteCap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Compost goals',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _textTitle,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Weekly compost goal: ${weeklyCompostGoalKg.round()} kg',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _textBody,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '~ ${(weeklyCompostGoalKg * 0.5).toStringAsFixed(1)} kg CO2 avoided',
          style: GoogleFonts.inter(fontSize: 12, color: _textMuted),
        ),
        Slider(
          min: 5,
          max: 200,
          divisions: 195,
          value: weeklyCompostGoalKg.clamp(5, 200),
          activeColor: _primary,
          inactiveColor: _softBg,
          onChanged: onWeeklyCompostGoal,
        ),
        const SizedBox(height: 18),
        Text(
          'Weekly waste cap: ${weeklyWasteCapKg.round()} kg',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _textBody,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Above this cap -> automatic alerts',
          style: GoogleFonts.inter(fontSize: 12, color: _textMuted),
        ),
        Slider(
          min: 5,
          max: 200,
          divisions: 195,
          value: weeklyWasteCapKg.clamp(5, 200),
          activeColor: _primary,
          inactiveColor: _softBg,
          onChanged: onWeeklyWasteCap,
        ),
      ],
    );
  }
}

class _AlertPreferencesStep extends StatelessWidget {
  final bool notifySpoilage;
  final bool notifyLowInventory;
  final bool notifyWasteTips;
  final ValueChanged<bool> onNotifySpoilage;
  final ValueChanged<bool> onNotifyLowInventory;
  final ValueChanged<bool> onNotifyWasteTips;
  final double wasteThreshold;
  final ValueChanged<double> onWasteThreshold;

  const _AlertPreferencesStep({
    required this.notifySpoilage,
    required this.notifyLowInventory,
    required this.notifyWasteTips,
    required this.onNotifySpoilage,
    required this.onNotifyLowInventory,
    required this.onNotifyWasteTips,
    required this.wasteThreshold,
    required this.onWasteThreshold,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alert preferences',
          style: GoogleFonts.playfairDisplay(fontSize: 18, color: _textTitle),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(AppRadii.innerCard),
            border: Border.all(color: _softBg, width: 1),
          ),
          child: Column(
            children: [
              SwitchListTile(
                value: notifySpoilage,
                onChanged: onNotifySpoilage,
                activeColor: _primary,
                activeTrackColor: _softBg,
                title: Text(
                  'Spoilage alerts',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textTitle,
                  ),
                ),
              ),
              Divider(color: _softBg, thickness: 0.5, height: 0.5),
              SwitchListTile(
                value: notifyLowInventory,
                onChanged: onNotifyLowInventory,
                activeColor: _primary,
                activeTrackColor: _softBg,
                title: Text(
                  'Low inventory alerts',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textTitle,
                  ),
                ),
              ),
              Divider(color: _softBg, thickness: 0.5, height: 0.5),
              SwitchListTile(
                value: notifyWasteTips,
                onChanged: onNotifyWasteTips,
                activeColor: _primary,
                activeTrackColor: _softBg,
                title: Text(
                  'Waste reduction tips',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textTitle,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Waste threshold: ${wasteThreshold.round()}%',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _textBody,
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _primary,
            inactiveTrackColor: _softBg,
            thumbColor: _deep,
            overlayColor: _primary.withValues(alpha: 0.12),
            trackHeight: 4,
          ),
          child: Slider(
            value: wasteThreshold,
            min: 0,
            max: 100,
            divisions: 20,
            onChanged: onWasteThreshold,
          ),
        ),
      ],
    );
  }
}

// ── Blob painter ─────────────────────────────────────────────────────────────

class _BlobPainter extends CustomPainter {
  final double t;
  final Color primary;
  _BlobPainter(this.t, this.primary);

  @override
  void paint(Canvas canvas, Size size) {
    final angle = t * 2 * math.pi;
    final c1 = Offset(
      size.width * 0.15 + math.cos(angle) * 20,
      size.height * 0.35 + math.sin(angle) * 15,
    );
    canvas.drawCircle(
      c1,
      size.width * 0.5,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withValues(alpha: 0.10), Colors.transparent],
        ).createShader(Rect.fromCircle(center: c1, radius: size.width * 0.5)),
    );
    final c2 = Offset(
      size.width * 0.85 + math.sin(angle * 0.7) * 18,
      size.height * 0.6 + math.cos(angle * 0.7) * 22,
    );
    canvas.drawCircle(
      c2,
      size.width * 0.4,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withValues(alpha: 0.07), Colors.transparent],
        ).createShader(Rect.fromCircle(center: c2, radius: size.width * 0.4)),
    );
    final c3 = Offset(
      size.width * 0.5 + math.cos(angle * 1.4) * 14,
      size.height * 0.2 + math.sin(angle * 1.4) * 10,
    );
    canvas.drawCircle(
      c3,
      size.width * 0.3,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withValues(alpha: 0.08), Colors.transparent],
        ).createShader(Rect.fromCircle(center: c3, radius: size.width * 0.3)),
    );
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.t != t;
}
