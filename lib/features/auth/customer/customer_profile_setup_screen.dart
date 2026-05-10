import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../core/firebase_service.dart';
import '../../../providers/user_provider.dart';
import '../../../shared/widgets/animated_button.dart';

// Customer role colors
const _primary = Color(0xFFD9899F);
const _deep = Color(0xFFB27589);
const _surface = Color(0xFFFEFAFC);
const _softBg = Color(0xFFF9E9F2);
const _textTitle = Color(0xFF26201B);
const _textBody = Color(0xFF5C4F48);
const _textMuted = Color(0xFF8C7E78);

class CustomerProfileSetupScreen extends StatefulWidget {
  final Map<String, dynamic> args;

  const CustomerProfileSetupScreen({
    super.key,
    this.args = const <String, dynamic>{},
  });

  @override
  State<CustomerProfileSetupScreen> createState() =>
      _CustomerProfileSetupScreenState();
}

class _CustomerProfileSetupScreenState extends State<CustomerProfileSetupScreen>
    with TickerProviderStateMixin {
  int _step = 0;
  int _prevStep = 0;

  final _displayNameController = TextEditingController();
  final _cholesterolController = TextEditingController(text: '300');
  final _saturatedFatController = TextEditingController(text: '20');
  final _sodiumController = TextEditingController(text: '2300');
  final _sugarController = TextEditingController(text: '50');

  DateTime? _dob;
  String? _gender;

  Uint8List? _avatarBytes;
  String? _avatarPath;

  final Set<String> _conditions = <String>{};
  double _calorieGoal = 2200;

  bool _notifyDaily = true;
  bool _notifyAllergens = true;
  bool _notifyWeekly = true;
  String _language = 'English';

  bool _completing = false;

  late final AnimationController _blobController;
  late final AnimationController _screenExitController;
  late final Animation<double> _screenFade;
  late final Animation<double> _screenScale;

  @override
  void initState() {
    super.initState();

    final fromProvider = context.read<UserProvider>().currentUser?.name;
    _displayNameController.text = (fromProvider?.trim().isNotEmpty ?? false)
        ? fromProvider!.trim()
        : (widget.args['name'] as String?)?.trim() ?? '';

    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _screenExitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 1.0,
    );
    _screenFade = CurvedAnimation(
      parent: _screenExitController,
      curve: Curves.easeOutCubic,
    );
    _screenScale = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _screenExitController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _cholesterolController.dispose();
    _saturatedFatController.dispose();
    _sodiumController.dispose();
    _sugarController.dispose();
    _blobController.dispose();
    _screenExitController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _avatarBytes = bytes;
      _avatarPath = file.path;
    });
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial = _dob ?? DateTime(now.year - 22, now.month, now.day);
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 10, now.month, now.day),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: _primary,
            onPrimary: Colors.white,
            surface: _surface,
            onSurface: _textTitle,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null) return;
    if (!mounted) return;
    setState(() => _dob = date);
  }

  void _next() {
    if (_step >= 2) return;
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

  Future<void> _complete() async {
    if (_completing) return;

    final userProvider = context.read<UserProvider>();
    final existing = userProvider.currentUser;
    final email = (existing?.email ?? '').trim();
    final name = _displayNameController.text.trim();

    if (existing == null || name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.validationRequiredField)),
      );
      return;
    }

    setState(() => _completing = true);

    String? avatarUrl = existing.avatarPath;
    if (_avatarPath != null && _avatarPath!.trim().isNotEmpty) {
      try {
        avatarUrl = await FirebaseService.uploadProfilePhoto(
          userId: existing.id,
          file: File(_avatarPath!),
        );
      } catch (_) {
        avatarUrl = existing.avatarPath;
      }
    }

    final user = existing.copyWith(
      name: name,
      dateOfBirth: _dob,
      gender: _gender,
      conditions: _conditions.toList(growable: false),
      calorieGoal: _calorieGoal.toInt(),
      notifyDailyIntake: _notifyDaily,
      notifyAllergens: _notifyAllergens,
      notifyWeeklyReport: _notifyWeekly,
      avatarPath: avatarUrl,
    );

    await userProvider.saveProfile(user);

    await FirebaseService.saveNutrientLimits(
      uid: user.id,
      cholesterol_mg: double.tryParse(_cholesterolController.text.trim()) ?? 300.0,
      saturated_fat_g: double.tryParse(_saturatedFatController.text.trim()) ?? 20.0,
      sodium_mg: double.tryParse(_sodiumController.text.trim()) ?? 2300.0,
      sugar_g: double.tryParse(_sugarController.text.trim()) ?? 50.0,
    );

    await _screenExitController.forward(from: 0.0);
    if (!mounted) return;
    context.go(AppRoutes.customerHome);
  }

  Widget _stepContent() {
    switch (_step) {
      case 0:
        return _StepPersonalInfo(
          displayNameController: _displayNameController,
          dob: _dob,
          onPickDob: _pickDob,
          gender: _gender,
          onGender: (g) => setState(() => _gender = g),
          avatarBytes: _avatarBytes,
          avatarPath: _avatarPath,
          onPickAvatar: _pickAvatar,
        );
      case 1:
        return _StepHealthProfile(
          conditions: _conditions,
          onToggleCondition: (c) {
            setState(() {
              if (_conditions.contains(c)) {
                _conditions.remove(c);
              } else {
                if (c == 'None') {
                  _conditions
                    ..clear()
                    ..add('None');
                } else {
                  _conditions.remove('None');
                  _conditions.add(c);
                }
              }
            });
          },
          calorieGoal: _calorieGoal,
          onCalorie: (v) => setState(() => _calorieGoal = v),
          cholesterolCtrl: _cholesterolController,
          saturatedFatCtrl: _saturatedFatController,
          sodiumCtrl: _sodiumController,
          sugarCtrl: _sugarController,
        );
      case 2:
      default:
        return _StepPreferences(
          notifyDaily: _notifyDaily,
          notifyAllergens: _notifyAllergens,
          notifyWeekly: _notifyWeekly,
          onNotifyDaily: (v) => setState(() => _notifyDaily = v),
          onNotifyAllergens: (v) => setState(() => _notifyAllergens = v),
          onNotifyWeekly: (v) => setState(() => _notifyWeekly = v),
          language: _language,
          onLanguage: (v) => setState(() => _language = v),
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
      body: FadeTransition(
        opacity: _screenFade,
        child: ScaleTransition(
          scale: _screenScale,
          child: Stack(
            children: [
              // ── Hero zone ──────────────────────────────────────────
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
                      builder: (_, _) => CustomPaint(
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (_step > 0)
                                  IconButton(
                                    onPressed: _back,
                                    icon: const Icon(Icons.arrow_back_ios_new),
                                    color: Colors.white,
                                  )
                                else
                                  const SizedBox(width: 48),
                              ],
                            ),
                            const Spacer(),
                            Center(
                              child: Text(
                                AppStrings.setupYourProfile,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
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

              // ── Floating card ──────────────────────────────────────
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
                      _StepProgressHeader(step: _step),
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
                              ? AppStrings.completeSetup
                              : AppStrings.continueCta,
                          color: _step == 2 ? _deep : _primary,
                          textColor: Colors.white,
                          onTap: _step == 2 ? _complete : () async => _next(),
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
        ),
      ),
    );
  }
}

// ── Step progress indicator ─────────────────────────────────────────────────

class _StepProgressHeader extends StatelessWidget {
  final int step;
  const _StepProgressHeader({required this.step});

  @override
  Widget build(BuildContext context) {
    Widget dot(int index) {
      if (index < step) return const _FilledDot(size: 16, color: _deep);
      if (index == step) return const _FilledDot(size: 24, color: _primary);
      return const _OutlinedDot(size: 16, color: Color(0xFFE2E8F0));
    }

    Color lineColor(int leftIndex) =>
        leftIndex < step ? _primary : const Color(0xFFE2E8F0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          dot(0),
          Expanded(child: Container(height: 2, color: lineColor(0))),
          dot(1),
          Expanded(child: Container(height: 2, color: lineColor(1))),
          dot(2),
        ],
      ),
    );
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

// ── Step 0: Personal info ────────────────────────────────────────────────────

class _StepPersonalInfo extends StatelessWidget {
  final TextEditingController displayNameController;
  final DateTime? dob;
  final VoidCallback onPickDob;
  final String? gender;
  final ValueChanged<String?> onGender;
  final Uint8List? avatarBytes;
  final String? avatarPath;
  final Future<void> Function() onPickAvatar;

  const _StepPersonalInfo({
    required this.displayNameController,
    required this.dob,
    required this.onPickDob,
    required this.gender,
    required this.onGender,
    required this.avatarBytes,
    required this.avatarPath,
    required this.onPickAvatar,
  });

  String _dobLabel() {
    if (dob == null) return 'DD / MM / YYYY';
    return DateFormat('dd / MM / yyyy').format(dob!);
  }

  @override
  Widget build(BuildContext context) {
    final avatar = avatarBytes != null
        ? CircleAvatar(radius: 45, backgroundImage: MemoryImage(avatarBytes!))
        : (avatarPath != null && File(avatarPath!).existsSync())
        ? CircleAvatar(
            radius: 45,
            backgroundImage: FileImage(File(avatarPath!)),
          )
        : const CircleAvatar(
            radius: 45,
            backgroundColor: _softBg,
            child: Icon(Icons.person, size: 42, color: _primary),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.center,
          child: Stack(
            children: [
              avatar,
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: onPickAvatar,
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
        _field(
          controller: displayNameController,
          label: 'Display name',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onPickDob,
          child: AbsorbPointer(
            child: TextField(
              style: GoogleFonts.inter(fontSize: 14, color: _textTitle),
              decoration: InputDecoration(
                labelText: 'Date of birth',
                hintText: _dobLabel(),
                labelStyle: GoogleFonts.inter(fontSize: 14, color: _textMuted),
                hintStyle: GoogleFonts.inter(fontSize: 14, color: _textMuted),
                prefixIcon: const Icon(
                  Icons.cake_outlined,
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
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Gender',
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
          children: ['Male', 'Female', 'Prefer not to say'].map((g) {
            final sel = gender == g;
            return InkWell(
              onTap: () => onGender(g),
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: sel ? _primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  border: Border.all(
                    color: sel ? _primary : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  g,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: sel ? Colors.white : _textMuted,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: GoogleFonts.inter(fontSize: 14, color: _textTitle),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 14, color: _textMuted),
        prefixIcon: Icon(icon, color: _textMuted, size: 20),
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
    );
  }
}

// ── Step 1: Health profile ───────────────────────────────────────────────────

class _StepHealthProfile extends StatelessWidget {
  final Set<String> conditions;
  final ValueChanged<String> onToggleCondition;
  final double calorieGoal;
  final ValueChanged<double> onCalorie;
  final TextEditingController cholesterolCtrl;
  final TextEditingController saturatedFatCtrl;
  final TextEditingController sodiumCtrl;
  final TextEditingController sugarCtrl;

  const _StepHealthProfile({
    required this.conditions,
    required this.onToggleCondition,
    required this.calorieGoal,
    required this.onCalorie,
    required this.cholesterolCtrl,
    required this.saturatedFatCtrl,
    required this.sodiumCtrl,
    required this.sugarCtrl,
  });

  @override
  Widget build(BuildContext context) {
    const options = [
      'Diabetes',
      'Hypertension',
      'High cholesterol',
      'Heart disease',
      'Kidney disease',
      'None',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.yourHealthProfile,
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _textTitle,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          AppStrings.personaliseAlerts,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: _textMuted,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppStrings.chronicConditionsQ,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textBody,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((c) {
            final sel = conditions.contains(c);
            return InkWell(
              onTap: () => onToggleCondition(c),
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: sel ? _primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  border: Border.all(
                    color: sel ? _primary : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  c,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: sel ? Colors.white : _textMuted,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Text(
          AppStrings.dailyCalorieGoal,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textBody,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          AppStrings.kcal(calorieGoal.toInt()),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _primary,
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _primary,
            inactiveTrackColor: _softBg,
            thumbColor: _deep,
            overlayColor: _primary.withValues(alpha: 0.12),
            trackHeight: 4,
          ),
          child: Slider(
            value: calorieGoal,
            min: 1200,
            max: 4000,
            divisions: 28,
            onChanged: onCalorie,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Daily Nutrient Limits (for alerts)',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textBody,
          ),
        ),
        const SizedBox(height: 12),
        _limitField(
          controller: cholesterolCtrl,
          label: 'Cholesterol (mg)',
          icon: Icons.monitor_heart_outlined,
        ),
        const SizedBox(height: 12),
        _limitField(
          controller: saturatedFatCtrl,
          label: 'Saturated Fat (g)',
          icon: Icons.fastfood_outlined,
        ),
        const SizedBox(height: 12),
        _limitField(
          controller: sodiumCtrl,
          label: 'Sodium (mg)',
          icon: Icons.water_drop_outlined,
        ),
        const SizedBox(height: 12),
        _limitField(
          controller: sugarCtrl,
          label: 'Sugar (g)',
          icon: Icons.cake_outlined,
        ),
      ],
    );
  }

  Widget _limitField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: GoogleFonts.inter(fontSize: 14, color: _textTitle),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 14, color: _textMuted),
        prefixIcon: Icon(icon, color: _primary, size: 20),
        filled: true,
        fillColor: _softBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// ── Step 2: Preferences ──────────────────────────────────────────────────────

class _StepPreferences extends StatelessWidget {
  final bool notifyDaily;
  final bool notifyAllergens;
  final bool notifyWeekly;
  final ValueChanged<bool> onNotifyDaily;
  final ValueChanged<bool> onNotifyAllergens;
  final ValueChanged<bool> onNotifyWeekly;
  final String language;
  final ValueChanged<String> onLanguage;

  const _StepPreferences({
    required this.notifyDaily,
    required this.notifyAllergens,
    required this.notifyWeekly,
    required this.onNotifyDaily,
    required this.onNotifyAllergens,
    required this.onNotifyWeekly,
    required this.language,
    required this.onLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.notificationPreferences,
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _textTitle,
          ),
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
                value: notifyDaily,
                onChanged: onNotifyDaily,
                activeThumbColor: _primary,
                activeTrackColor: _softBg,
                title: Text(
                  AppStrings.dailyIntakeSummary,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textTitle,
                  ),
                ),
              ),
              Divider(color: _softBg, thickness: 0.5, height: 0.5),
              SwitchListTile(
                value: notifyAllergens,
                onChanged: onNotifyAllergens,
                activeThumbColor: _primary,
                activeTrackColor: _softBg,
                title: Text(
                  AppStrings.allergenAlerts,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textTitle,
                  ),
                ),
              ),
              Divider(color: _softBg, thickness: 0.5, height: 0.5),
              SwitchListTile(
                value: notifyWeekly,
                onChanged: onNotifyWeekly,
                activeThumbColor: _primary,
                activeTrackColor: _softBg,
                title: Text(
                  AppStrings.weeklyHealthReport,
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
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          initialValue: language,
          decoration: InputDecoration(
            labelText: AppStrings.preferredLanguage,
            labelStyle: GoogleFonts.inter(fontSize: 14, color: _textMuted),
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
          items: const ['Arabic', 'French', 'English']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(growable: false),
          onChanged: (v) {
            if (v != null) onLanguage(v);
          },
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
