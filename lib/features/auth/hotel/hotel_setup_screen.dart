import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../core/firebase_service.dart';
import '../../../providers/user_provider.dart';
import '../../../shared/widgets/animated_button.dart';

class HotelSetupScreen extends StatefulWidget {
  final Map<String, dynamic>? args;

  const HotelSetupScreen({super.key, this.args});

  @override
  State<HotelSetupScreen> createState() => _HotelSetupScreenState();
}

class _HotelSetupScreenState extends State<HotelSetupScreen>
    with TickerProviderStateMixin {
  int _step = 0;
  int _prevStep = 0;

  final _hotelNameController = TextEditingController();

  Uint8List? _logoBytes;

  String _hotelType = 'Boutique';
  double _rooms = 80;

  int _staffCount = 12;
  final Set<String> _roles = <String>{'Manager'};
  bool _allergyHandling = true;

  bool _notifySpoilage = true;
  bool _notifyLowInventory = true;
  bool _notifyWasteTips = true;
  double _wasteThreshold = 20;

  bool _completing = false;

  static const _typeOptions = <String>[
    'Boutique',
    'Business',
    'Resort',
    'Budget',
    'Other',
  ];

  static const _roleOptions = <String>[
    'Housekeeping',
    'Kitchen',
    'Front Desk',
    'Manager',
  ];

  @override
  void initState() {
    super.initState();
    final args = widget.args ?? const <String, dynamic>{};
    final hotelName = (args['hotelName'] as String?)?.trim();
    final type = (args['hotelType'] as String?)?.trim();
    final rooms = args['rooms'];

    if (hotelName != null && hotelName.isNotEmpty) {
      _hotelNameController.text = hotelName;
    }
    if (type != null && type.isNotEmpty) {
      _hotelType = type;
    }
    if (rooms is int) {
      _rooms = rooms.toDouble().clamp(10, 500);
    } else if (rooms is double) {
      _rooms = rooms.clamp(10, 500);
    }
  }

  @override
  void dispose() {
    _hotelNameController.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;

    setState(() {
      _logoBytes = bytes;
    });
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

  Future<void> _complete() async {
    if (_completing) return;

    final hotelName = _hotelNameController.text.trim();
    if (hotelName.isEmpty) {
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
        role: 'hotel',
        avatarPath: uploadedLogoUrl ?? current.avatarPath,
        hotelName: hotelName,
        hotelType: _hotelType,
        rooms: _rooms.round(),
        teamSize: _staffCount,
        staffRoles: _roles.toList(growable: false),
        allergyHandling: _allergyHandling,
        notifyAllergens: _notifySpoilage,
        notifyWeeklyReport: _notifyLowInventory,
        notifyDailyIntake: _notifyWasteTips,
        wasteThreshold: _wasteThreshold,
      );

      await userProvider.saveProfile(updated);
      if (!mounted) return;
      context.go(AppRoutes.hotelDashboard);
    } catch (e) {
      _snack(_readableError(e));
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  Widget _stepContent() {
    switch (_step) {
      case 0:
        return _HotelDetailsStep(
          logoBytes: _logoBytes,
          onPickLogo: _pickLogo,
          hotelNameController: _hotelNameController,
          hotelType: _hotelType,
          typeOptions: _typeOptions,
          onHotelType: (v) => setState(() => _hotelType = v),
          rooms: _rooms,
          onRooms: (v) => setState(() => _rooms = v),
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

    return Scaffold(
      backgroundColor: AppColors.oat,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 180,
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
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  if (_step > 0) {
                                    _back();
                                  } else {
                                    context.go(AppRoutes.hotelRegister);
                                  }
                                },
                                icon: const Icon(Icons.arrow_back_ios_new),
                                color: AppColors.cherry,
                                splashColor: AppColors.cherry.withValues(alpha: 0.12),
                              ),
                              const Spacer(),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            'Hotel setup',
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 24,
                              color: AppColors.cherry,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'A few details to get started',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: AppColors.espresso,
                              height: 1.3,
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
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _ThreeStepHeader(step: _step),
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
                        label: _step == 2 ? 'Start managing' : AppStrings.continueCta,
                        color: AppColors.butter,
                        textColor: AppColors.cherry,
                        onTap: _step == 2
                            ? _complete
                            : () async {
                                if (_step == 0 &&
                                    _hotelNameController.text.trim().isEmpty) {
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
      ),
    );
  }
}

class _ThreeStepHeader extends StatelessWidget {
  final int step;

  const _ThreeStepHeader({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _dot(active: step == 0, complete: step > 0),
          Expanded(
            child: Container(height: 2, color: step > 0 ? AppColors.cherry : AppColors.sand),
          ),
          _dot(active: step == 1, complete: step > 1),
          Expanded(
            child: Container(height: 2, color: step > 1 ? AppColors.cherry : AppColors.sand),
          ),
          _dot(active: step == 2, complete: false),
        ],
      ),
    );
  }

  Widget _dot({required bool active, required bool complete}) {
    if (complete) {
      return const _FilledDot(size: 16, color: AppColors.cherry);
    }
    if (active) {
      return const _FilledDot(size: 24, color: AppColors.cherry);
    }
    return const _OutlinedDot(size: 16, color: AppColors.sand);
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

class _HotelDetailsStep extends StatelessWidget {
  final Uint8List? logoBytes;
  final Future<void> Function() onPickLogo;

  final TextEditingController hotelNameController;

  final String hotelType;
  final List<String> typeOptions;
  final ValueChanged<String> onHotelType;

  final double rooms;
  final ValueChanged<double> onRooms;

  const _HotelDetailsStep({
    required this.logoBytes,
    required this.onPickLogo,
    required this.hotelNameController,
    required this.hotelType,
    required this.typeOptions,
    required this.onHotelType,
    required this.rooms,
    required this.onRooms,
  });

  @override
  Widget build(BuildContext context) {
    final logo = logoBytes != null
        ? CircleAvatar(radius: 45, backgroundImage: MemoryImage(logoBytes!))
        : const CircleAvatar(
            radius: 45,
            backgroundColor: AppColors.cherry,
            child: Icon(Icons.hotel, size: 42, color: AppColors.parchment),
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
                      color: AppColors.cherry,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.camera_alt,
                        size: 14, color: AppColors.parchment),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: hotelNameController,
          decoration: const InputDecoration(
            labelText: 'Hotel name',
            prefixIcon: Icon(Icons.hotel, color: AppColors.cocoa),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: hotelType,
          decoration: const InputDecoration(
            labelText: 'Hotel type',
            prefixIcon: Icon(Icons.apartment, color: AppColors.cocoa),
          ),
          items: typeOptions
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(growable: false),
          onChanged: (v) {
            if (v != null) onHotelType(v);
          },
        ),
        const SizedBox(height: 18),
        Text(
          'Number of rooms: ${rooms.round()}',
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
            value: rooms,
            min: 10,
            max: 500,
            divisions: 49,
            onChanged: onRooms,
          ),
        ),
      ],
    );
  }
}

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
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 18,
            color: AppColors.cherry,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Staff count',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.espresso,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.cherry,
                  inactiveTrackColor: AppColors.sand,
                  thumbColor: AppColors.cherry,
                  overlayColor: AppColors.cherry.withValues(alpha: 0.12),
                ),
                child: Slider(
                  value: staffCount.toDouble(),
                  min: 1,
                  max: 120,
                  divisions: 119,
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
                  color: AppColors.cherry,
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
            color: AppColors.espresso,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: roleOptions.map((r) {
            final selected = roles.contains(r);
            return ChoiceChip(
              label: Text(r),
              selected: selected,
              onSelected: (_) => onToggleRole(r),
              selectedColor: AppColors.cherryBlush,
              backgroundColor: AppColors.parchment,
              side: const BorderSide(color: AppColors.sand, width: 0.7),
              labelStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.cherry : AppColors.espresso,
              ),
            );
          }).toList(growable: false),
        ),
        const SizedBox(height: 18),
        Container(
          decoration: BoxDecoration(
            color: AppColors.parchment,
            borderRadius: BorderRadius.circular(AppRadii.innerCard),
            border: Border.all(color: AppColors.sand, width: 0.5),
          ),
          child: SwitchListTile(
            value: allergyHandling,
            onChanged: onAllergyHandling,
            activeThumbColor: AppColors.cherry,
            title: Text(
              'Allergy handling',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.espresso,
              ),
            ),
          ),
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
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 18,
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
                value: notifySpoilage,
                onChanged: onNotifySpoilage,
                activeThumbColor: AppColors.cherry,
                title: Text(
                  'Spoilage alerts',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.espresso,
                  ),
                ),
              ),
              const Divider(color: AppColors.sand, thickness: 0.5, height: 0.5),
              SwitchListTile(
                value: notifyLowInventory,
                onChanged: onNotifyLowInventory,
                activeThumbColor: AppColors.cherry,
                title: Text(
                  'Low inventory alerts',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.espresso,
                  ),
                ),
              ),
              const Divider(color: AppColors.sand, thickness: 0.5, height: 0.5),
              SwitchListTile(
                value: notifyWasteTips,
                onChanged: onNotifyWasteTips,
                activeThumbColor: AppColors.cherry,
                title: Text(
                  'Waste reduction tips',
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
        const SizedBox(height: 18),
        Text(
          'Waste threshold: ${wasteThreshold.round()}%',
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
