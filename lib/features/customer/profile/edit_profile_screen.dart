import 'dart:typed_data';

import 'package:email_validator/email_validator.dart';
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

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _scrollController = ScrollController();

  final _healthSectionKey = GlobalKey();
  bool _didHandleInitialStep = false;

  DateTime? _dob;
  String? _gender;

  Uint8List? _newAvatarBytes;

  final Set<String> _conditions = <String>{};

  bool _saving = false;

  static const _genderOptions = <String>[
    'Male',
    'Female',
    'Prefer not to say',
  ];

  static const _conditionOptions = <String>[
    'Diabetes',
    'Hypertension',
    'High cholesterol',
    'Heart disease',
    'None',
  ];

  @override
  void initState() {
    super.initState();

    final user = context.read<UserProvider>().currentUser;
    _nameController.text = user?.name ?? '';
    _emailController.text = user?.email ?? '';
    _phoneController.text = user?.phone ?? '';

    _dob = user?.dateOfBirth;
    _gender = user?.gender;

    final existingConditions = user?.conditions ?? const <String>[];
    _conditions.addAll(existingConditions);

    _syncDobText();

    WidgetsBinding.instance.addPostFrameCallback((_) => _handleInitialStep());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleInitialStep() {
    if (!mounted) return;
    if (_didHandleInitialStep) return;
    _didHandleInitialStep = true;

    final step = GoRouterState.of(context).uri.queryParameters['step'] ?? '';
    if (step != '2') return;

    final ctx = _healthSectionKey.currentContext;
    if (ctx == null) return;

    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  void _syncDobText() {
    if (_dob == null) {
      _dobController.text = '';
      return;
    }
    _dobController.text = DateFormat('MMM d, yyyy').format(_dob!);
  }

  InputDecoration _decoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.cocoa),
      filled: true,
      fillColor: AppColors.cream,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.input),
        borderSide: const BorderSide(color: AppColors.sand, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.input),
        borderSide: const BorderSide(color: AppColors.cherry, width: 1.2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.input),
        borderSide: const BorderSide(color: AppColors.sand, width: 1),
      ),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;

    setState(() => _newAvatarBytes = bytes);
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial = _dob ?? DateTime(now.year - 22, now.month, now.day);

    final picked = await showDatePicker(
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

    if (picked == null) return;
    if (!mounted) return;

    setState(() {
      _dob = picked;
      _syncDobText();
    });
  }

  void _toggleCondition(String c) {
    setState(() {
      if (_conditions.contains(c)) {
        _conditions.remove(c);
        return;
      }

      if (c == 'None') {
        _conditions
          ..clear()
          ..add('None');
      } else {
        _conditions.remove('None');
        _conditions.add(c);
      }
    });
  }

  List<String> _autoAdjustedNutrients(Set<String> conditions) {
    final selected = conditions.where((c) => c != 'None').toSet();
    final nutrients = <String>{};

    if (selected.contains('Diabetes')) nutrients.add('Sugar');
    if (selected.contains('Hypertension')) nutrients.add('Sodium');
    if (selected.contains('High cholesterol')) {
      nutrients.add('Cholesterol');
      nutrients.add('Saturated fat');
    }
    if (selected.contains('Heart disease')) {
      nutrients.add('Saturated fat');
      nutrients.add('Sodium');
    }

    final list = nutrients.toList()..sort();
    return list;
  }

  Future<void> _save() async {
    if (_saving) return;

    final userProvider = context.read<UserProvider>();
    final existing = userProvider.currentUser;
    if (existing == null) {
      _snack('No signed-in user.');
      return;
    }

    final name = _nameController.text.trim();
    final email = existing.email.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      _snack(AppStrings.validationRequiredField);
      return;
    }
    if (!EmailValidator.validate(email)) {
      _snack(AppStrings.validationInvalidEmail);
      return;
    }

    setState(() => _saving = true);

    String? avatarUrl = existing.avatarPath;
    if (_newAvatarBytes != null) {
      try {
        avatarUrl = await FirebaseService.uploadProfilePhoto(
          userId: existing.id,
          bytes: _newAvatarBytes,
        );
      } catch (_) {
        avatarUrl = existing.avatarPath;
      }
    }

    final updated = existing.copyWith(
      name: name,
      phone: phone.isEmpty ? null : phone,
      dateOfBirth: _dob,
      gender: _gender,
      conditions: _conditions.toList(growable: false),
      avatarPath: avatarUrl,
    );

    try {
      await userProvider.saveProfile(updated);
      if (!mounted) return;
      _snack('Profile updated');
      context.pop();
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.dmSerifDisplay(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.espresso,
        height: 1.2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;
    final adjusted = _autoAdjustedNutrients(_conditions);

    ImageProvider? avatarImage;
    if (_newAvatarBytes != null) {
      avatarImage = MemoryImage(_newAvatarBytes!);
    } else if (user?.avatarPath != null && user!.avatarPath!.trim().isNotEmpty) {
      avatarImage = NetworkImage(user.avatarPath!);
    }

    return Scaffold(
      backgroundColor: AppColors.oat,
      body: SafeArea(
        child: Column(
          children: [
            CherryHeader(
              title: 'Edit Profile',
              showBack: true,
              actions: [
                IconButton(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save),
                  color: AppColors.butter,
                  splashColor: AppColors.butter.withValues(alpha: 0.2),
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
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            SizedBox(
                              width: 90,
                              height: 90,
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 45,
                                    backgroundColor: AppColors.oatDeep,
                                    foregroundImage: avatarImage,
                                    child: avatarImage == null
                                        ? const Icon(Icons.person, color: AppColors.cocoa, size: 34)
                                        : null,
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: InkWell(
                                      onTap: _pickAvatar,
                                      borderRadius: BorderRadius.circular(18),
                                      child: Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: AppColors.parchment,
                                          borderRadius: BorderRadius.circular(18),
                                          border: Border.all(color: AppColors.sand, width: 0.8),
                                        ),
                                        child: const Icon(
                                          Icons.photo_camera_outlined,
                                          size: 18,
                                          color: AppColors.espresso,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Change photo',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.cherry,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _sectionTitle('Personal info'),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _nameController,
                        decoration: _decoration(label: AppStrings.fullName, icon: Icons.person_outline),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _emailController,
                        enabled: false,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.fog,
                        ),
                        decoration: _decoration(label: AppStrings.emailAddress, icon: Icons.email_outlined),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _dobController,
                        readOnly: true,
                        onTap: _pickDob,
                        decoration: _decoration(label: 'Date of birth', icon: Icons.cake_outlined),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _decoration(label: 'Phone number', icon: Icons.phone_outlined),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Gender',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.espresso,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _genderOptions.map((g) {
                          final selected = _gender == g;
                          return ChoiceChip(
                            label: Text(g),
                            selected: selected,
                            selectedColor: AppColors.cherryBlush,
                            backgroundColor: AppColors.cream,
                            side: const BorderSide(color: AppColors.sand, width: 0.8),
                            labelStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected ? AppColors.cherryDark : AppColors.espresso,
                            ),
                            onSelected: (v) => setState(() => _gender = v ? g : null),
                          );
                        }).toList(growable: false),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(key: _healthSectionKey),
                      _sectionTitle('Health conditions'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _conditionOptions.map((c) {
                          final selected = _conditions.contains(c);
                          return FilterChip(
                            label: Text(c),
                            selected: selected,
                            selectedColor: AppColors.cherryBlush,
                            backgroundColor: AppColors.cream,
                            side: const BorderSide(color: AppColors.sand, width: 0.8),
                            labelStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected ? AppColors.cherryDark : AppColors.espresso,
                            ),
                            onSelected: (_) => _toggleCondition(c),
                          );
                        }).toList(growable: false),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.parchment,
                          borderRadius: BorderRadius.circular(AppRadii.innerCard),
                          border: Border.all(color: AppColors.sand, width: 0.6),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.cherryBlush,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.info_outline, color: AppColors.cherryDark),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Chronic conditions',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.espresso,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    adjusted.isEmpty
                                        ? 'We automatically adjust nutrient alerts based on your health profile.'
                                        : 'We automatically adjust nutrient alerts for: ${adjusted.join(', ')}.',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.cocoa,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      AnimatedButton(
                        label: 'Save',
                        color: AppColors.cherry,
                        textColor: AppColors.butter,
                        isLoading: _saving,
                        onTap: _save,
                      ),
                    ],
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
