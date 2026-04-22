import 'dart:io';
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
import '../../../shared/widgets/cherry_header.dart';

class CustomerProfileSetupScreen extends StatefulWidget {
  final Map<String, dynamic> args;

  const CustomerProfileSetupScreen({super.key, this.args = const <String, dynamic>{}});

  @override
  State<CustomerProfileSetupScreen> createState() =>
      _CustomerProfileSetupScreenState();
}

class _CustomerProfileSetupScreenState extends State<CustomerProfileSetupScreen>
    with TickerProviderStateMixin {
  int _step = 0;
  int _prevStep = 0;

  final _displayNameController = TextEditingController();

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

  late final AnimationController _screenExitController;
  late final Animation<double> _screenFade;
  late final Animation<double> _screenScale;

  @override
  void initState() {
    super.initState();
    final fromProvider = context.read<UserProvider>().currentUser?.name;
    _displayNameController.text =
      (fromProvider?.trim().isNotEmpty ?? false)
        ? fromProvider!.trim()
        : (widget.args['name'] as String?)?.trim() ?? '';

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
      CurvedAnimation(parent: _screenExitController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _screenExitController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.cherry,
              onPrimary: AppColors.cherryHeaderText,
                  surface: AppColors.parchment,
                  onSurface: AppColors.espresso,
                ),
          ),
          child: child!,
        );
      },
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
        // Keep local avatarPath if upload fails.
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

    return Scaffold(
      backgroundColor: AppColors.oat,
      body: SafeArea(
        child: FadeTransition(
          opacity: _screenFade,
          child: ScaleTransition(
            scale: _screenScale,
            child: Column(
              children: [
                CherryHeader(
                  title: AppStrings.setupYourProfile,
                  showBack: true,
                  height: 180,
                  actions: [
                    if (_step > 0)
                      IconButton(
                        onPressed: _back,
                        icon: const Icon(Icons.chevron_left),
                        color: AppColors.cherryHeaderText,
                        splashColor: AppColors.cherryHeaderText.withValues(alpha: 0.15),
                      ),
                  ],
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
                                begin: forward ? const Offset(1, 0) : const Offset(-1, 0),
                                end: Offset.zero,
                              );
                              final outTween = Tween<Offset>(
                                begin: Offset.zero,
                                end: forward ? const Offset(-1, 0) : const Offset(1, 0),
                              );

                              final isIncoming = child.key == ValueKey(_step);
                              final offsetAnim = isIncoming
                                  ? inTween.animate(animation)
                                  : outTween.animate(animation);

                              return SlideTransition(position: offsetAnim, child: child);
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
                            label: _step == 2 ? AppStrings.completeSetup : AppStrings.continueCta,
                            color: _step == 2 ? AppColors.olive : AppColors.cherry,
                            textColor: _step == 2 ? AppColors.oliveHeaderText : AppColors.cherryHeaderText,
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
      ),
    );
  }
}

class _StepProgressHeader extends StatelessWidget {
  final int step;

  const _StepProgressHeader({required this.step});

  @override
  Widget build(BuildContext context) {
    Widget dot(int index) {
      if (index < step) {
        return const _FilledDot(size: 16, color: AppColors.olive);
      }
      if (index == step) {
        return const _FilledDot(size: 24, color: AppColors.cherry);
      }
      return const _OutlinedDot(size: 16, color: AppColors.sand);
    }

    Color lineColor(int leftIndex) {
      return leftIndex < step ? AppColors.cherry : AppColors.sand;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          dot(0),
          Expanded(
            child: Container(height: 2, color: lineColor(0)),
          ),
          dot(1),
          Expanded(
            child: Container(height: 2, color: lineColor(1)),
          ),
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
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _OutlinedDot extends StatelessWidget {
  final double size;
  final Color color;

  const _OutlinedDot({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
    );
  }
}

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
            ? CircleAvatar(radius: 45, backgroundImage: FileImage(File(avatarPath!)))
            : const CircleAvatar(
                radius: 45,
                backgroundColor: AppColors.cherry,
                child: Icon(Icons.person, size: 42, color: AppColors.parchment),
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
                      color: AppColors.olive,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.camera_alt, size: 14, color: AppColors.parchment),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: displayNameController,
          decoration: InputDecoration(
            labelText: 'Display name',
            prefixIcon: const Icon(Icons.person_outline, color: AppColors.cocoa),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onPickDob,
          child: AbsorbPointer(
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Date of birth',
                prefixIcon: const Icon(Icons.cake_outlined, color: AppColors.cocoa),
                hintText: _dobLabel(),
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
            color: AppColors.espresso,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _GenderChip(
              label: 'Male',
              selected: gender == 'Male',
              onTap: () => onGender('Male'),
            ),
            _GenderChip(
              label: 'Female',
              selected: gender == 'Female',
              onTap: () => onGender('Female'),
            ),
            _GenderChip(
              label: 'Prefer not to say',
              selected: gender == 'Prefer not to say',
              onTap: () => onGender('Prefer not to say'),
            ),
          ],
        ),
      ],
    );
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenderChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.chip),
      splashColor: AppColors.cherry.withValues(alpha: 0.15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.cherry : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.chip),
          border: Border.all(color: AppColors.sand, width: 1),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.butter : AppColors.cocoa,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

class _StepHealthProfile extends StatelessWidget {
  final Set<String> conditions;
  final ValueChanged<String> onToggleCondition;
  final double calorieGoal;
  final ValueChanged<double> onCalorie;

  const _StepHealthProfile({
    required this.conditions,
    required this.onToggleCondition,
    required this.calorieGoal,
    required this.onCalorie,
  });

  @override
  Widget build(BuildContext context) {
    final options = const [
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
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.cherry,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          AppStrings.personaliseAlerts,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.cocoa,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppStrings.chronicConditionsQ,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.espresso,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((c) {
            final selected = conditions.contains(c);
            return InkWell(
              onTap: () => onToggleCondition(c),
              borderRadius: BorderRadius.circular(AppRadii.chip),
              splashColor: AppColors.cherry.withValues(alpha: 0.15),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.cherry : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                  border: Border.all(color: AppColors.sand, width: 1),
                ),
                child: Text(
                  c,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.butter : AppColors.cocoa,
                    height: 1.2,
                  ),
                ),
              ),
            );
          }).toList(growable: false),
        ),
        const SizedBox(height: 20),
        Text(
          AppStrings.dailyCalorieGoal,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.espresso,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          AppStrings.kcal(calorieGoal.toInt()),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.cherry,
            height: 1.2,
          ),
        ),
        Slider(
          value: calorieGoal,
          min: 1200,
          max: 4000,
          divisions: 28,
          activeColor: AppColors.cherry,
          onChanged: onCalorie,
        ),
      ],
    );
  }
}

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
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.cherry,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.parchment,
            borderRadius: BorderRadius.circular(AppRadii.innerCard),
            border: Border.all(color: AppColors.sand, width: 0.5),
          ),
          child: Column(
            children: [
              SwitchListTile(
                value: notifyDaily,
                onChanged: onNotifyDaily,
                activeThumbColor: AppColors.cherry,
                title: Text(
                  AppStrings.dailyIntakeSummary,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.espresso,
                  ),
                ),
              ),
              const Divider(color: AppColors.sand, thickness: 0.5, height: 0.5),
              SwitchListTile(
                value: notifyAllergens,
                onChanged: onNotifyAllergens,
                activeThumbColor: AppColors.cherry,
                title: Text(
                  AppStrings.allergenAlerts,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.espresso,
                  ),
                ),
              ),
              const Divider(color: AppColors.sand, thickness: 0.5, height: 0.5),
              SwitchListTile(
                value: notifyWeekly,
                onChanged: onNotifyWeekly,
                activeThumbColor: AppColors.cherry,
                title: Text(
                  AppStrings.weeklyHealthReport,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.espresso,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          initialValue: language,
          decoration: InputDecoration(labelText: AppStrings.preferredLanguage),
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
