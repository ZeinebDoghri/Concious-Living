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

const _kPrimary = Color(0xFF7DC5A0);
const _kDeep    = Color(0xFF4A8A6A);
const _kSurface = Color(0xFFF4FAF7);
const _kSoftBg  = Color(0xFFDFF2E9);
const _kTitle   = Color(0xFF0D2E1E);
const _kBody    = Color(0xFF3A6A52);
const _kMuted   = Color(0xFF7AAA90);

class EditHotelProfileScreen extends StatefulWidget {
  const EditHotelProfileScreen({super.key});

  @override
  State<EditHotelProfileScreen> createState() => _EditHotelProfileScreenState();
}

class _EditHotelProfileScreenState extends State<EditHotelProfileScreen>
    with TickerProviderStateMixin {
  int _step     = 0;
  int _prevStep = 0;

  final _hotelNameController = TextEditingController();

  Uint8List? _newLogoBytes;

  String _hotelType    = 'Boutique';
  double _rooms        = 80;
  int    _staffCount   = 12;
  final Set<String> _roles = <String>{'Manager'};
  bool   _allergyHandling  = true;

  bool   _notifySpoilage     = true;
  bool   _notifyLowInventory = true;
  bool   _notifyWasteTips    = true;
  double _wasteThreshold     = 20;

  bool _saving              = false;
  bool _didHandleInitialStep = false;

  static const _typeOptions = <String>['Boutique', 'Business', 'Resort', 'Budget', 'Other'];
  static const _roleOptions = <String>['Housekeeping', 'Kitchen', 'Front Desk', 'Manager'];

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().currentUser;
    _hotelNameController.text = user?.hotelName ?? '';

    final type = (user?.hotelType ?? '').trim();
    if (type.isNotEmpty) _hotelType = _typeOptions.contains(type) ? type : 'Other';

    final rooms = user?.rooms;
    if (rooms != null) _rooms = rooms.toDouble().clamp(10, 500);

    final teamSize = user?.teamSize;
    if (teamSize != null && teamSize > 0) _staffCount = teamSize.clamp(1, 80);

    final staffRoles = user?.staffRoles ?? const <String>[];
    if (staffRoles.isNotEmpty) {
      _roles..clear()..addAll(staffRoles.map((e) => e.trim()).where((e) => e.isNotEmpty));
      if (_roles.isEmpty) _roles.add('Manager');
    }

    _allergyHandling   = user?.allergyHandling    ?? true;
    _notifySpoilage    = user?.notifyAllergens     ?? true;
    _notifyLowInventory = user?.notifyWeeklyReport ?? true;
    _notifyWasteTips   = user?.notifyDailyIntake   ?? true;
    _wasteThreshold    = (user?.wasteThreshold ?? 20).clamp(0, 100).toDouble();

    WidgetsBinding.instance.addPostFrameCallback((_) => _handleInitialStep());
  }

  @override
  void dispose() {
    _hotelNameController.dispose();
    super.dispose();
  }

  void _handleInitialStep() {
    if (!mounted || _didHandleInitialStep) return;
    _didHandleInitialStep = true;
    final stepParam = GoRouterState.of(context).uri.queryParameters['step'];
    if (stepParam == null) return;
    final idx = ((int.tryParse(stepParam) ?? 1) - 1).clamp(0, 2);
    setState(() { _step = idx; _prevStep = idx; });
  }

  void _next() {
    if (_step >= 2) return;
    setState(() { _prevStep = _step; _step++; });
  }

  void _back() {
    if (_step <= 0) return;
    setState(() { _prevStep = _step; _step--; });
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  String _readableError(Object e) {
    final s = e.toString();
    if (s.startsWith('Exception: '))  return s.substring(11);
    if (s.startsWith('StateError: ')) return s.substring(12);
    return s;
  }

  Future<void> _pickLogo() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1400);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _newLogoBytes = bytes);
  }

  void _toggleRole(String role) {
    setState(() {
      if (_roles.contains(role)) { _roles.remove(role); } else { _roles.add(role); }
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final hotelName = _hotelNameController.text.trim();
    if (hotelName.isEmpty) { _snack(AppStrings.validationRequiredField); return; }
    setState(() => _saving = true);
    try {
      final userProvider = context.read<UserProvider>();
      final current = userProvider.currentUser;
      if (current == null) { _snack('Please sign in again.'); return; }

      String? uploadedLogoUrl;
      if (_newLogoBytes != null) {
        try {
          uploadedLogoUrl = await FirebaseService.uploadProfilePhoto(userId: current.id, bytes: _newLogoBytes!);
        } catch (_) {}
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
      context.pop();
    } catch (e) {
      _snack(_readableError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user    = context.watch<UserProvider>().currentUser;
    final forward = _step >= _prevStep;

    return Scaffold(
      backgroundColor: _kSurface,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_kPrimary, _kDeep],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => _step > 0 ? _back() : context.pop(),
                      icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit hotel profile',
                            style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Update hotel details and preferences',
                            style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.75)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Floating card ────────────────────────────────────────────────
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _StepIndicator(step: _step),
                  const SizedBox(height: 16),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeInOut,
                      switchOutCurve: Curves.easeInOut,
                      transitionBuilder: (child, animation) {
                        final isIncoming = child.key == ValueKey(_step);
                        final inTween  = Tween<Offset>(begin: forward ? const Offset(1, 0) : const Offset(-1, 0), end: Offset.zero);
                        final outTween = Tween<Offset>(begin: Offset.zero, end: forward ? const Offset(-1, 0) : const Offset(1, 0));
                        return SlideTransition(position: (isIncoming ? inTween : outTween).animate(animation), child: child);
                      },
                      child: SingleChildScrollView(
                        key: ValueKey(_step),
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        child: _stepContent((user?.avatarPath ?? '').trim()),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: AnimatedButton(
                      label: _step == 2 ? 'Save changes' : AppStrings.continueCta,
                      color: _kPrimary,
                      textColor: Colors.white,
                      onTap: _step == 2
                          ? _save
                          : () async {
                              if (_step == 0 && _hotelNameController.text.trim().isEmpty) {
                                _snack(AppStrings.validationRequiredField);
                                return;
                              }
                              _next();
                            },
                      isLoading: _saving,
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

  Widget _stepContent(String existingLogoUrl) {
    switch (_step) {
      case 0:
        return _HotelDetailsStep(
          newLogoBytes: _newLogoBytes,
          existingLogoUrl: existingLogoUrl,
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
}

// ── Step indicator ─────────────────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int step;
  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          _Dot(active: step == 0, complete: step > 0),
          Expanded(child: Container(height: 2, color: step > 0 ? _kPrimary : _kSoftBg)),
          _Dot(active: step == 1, complete: step > 1),
          Expanded(child: Container(height: 2, color: step > 1 ? _kPrimary : _kSoftBg)),
          _Dot(active: step == 2, complete: false),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;
  final bool complete;
  const _Dot({required this.active, required this.complete});

  @override
  Widget build(BuildContext context) {
    final size  = active ? 24.0 : 14.0;
    final color = (active || complete) ? _kPrimary : _kSoftBg;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size, height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: (active || complete) ? _kPrimary : _kMuted, width: 1.5),
      ),
      child: complete ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
    );
  }
}

// ── Step 0: Hotel details ──────────────────────────────────────────────────────
class _HotelDetailsStep extends StatelessWidget {
  final Uint8List? newLogoBytes;
  final String?   existingLogoUrl;
  final Future<void> Function() onPickLogo;
  final TextEditingController hotelNameController;
  final String hotelType;
  final List<String> typeOptions;
  final ValueChanged<String> onHotelType;
  final double rooms;
  final ValueChanged<double> onRooms;

  const _HotelDetailsStep({
    required this.newLogoBytes, required this.existingLogoUrl,
    required this.onPickLogo, required this.hotelNameController,
    required this.hotelType, required this.typeOptions,
    required this.onHotelType, required this.rooms, required this.onRooms,
  });

  @override
  Widget build(BuildContext context) {
    final url = (existingLogoUrl ?? '').trim();
    final Widget avatar = newLogoBytes != null
        ? CircleAvatar(radius: 45, backgroundImage: MemoryImage(newLogoBytes!))
        : (url.isNotEmpty
            ? CircleAvatar(radius: 45, backgroundImage: NetworkImage(url))
            : const CircleAvatar(radius: 45, backgroundColor: _kSoftBg,
                child: Icon(Icons.hotel, size: 42, color: _kDeep)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Stack(
            children: [
              avatar,
              Positioned(
                right: 0, bottom: 0,
                child: GestureDetector(
                  onTap: onPickLogo,
                  child: Container(
                    width: 28, height: 28,
                    decoration: const BoxDecoration(color: _kPrimary, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: hotelNameController,
          decoration: InputDecoration(
            labelText: 'Hotel name',
            prefixIcon: const Icon(Icons.hotel, color: _kMuted),
            filled: true,
            fillColor: _kSoftBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.input), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.input), borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: hotelType,
          decoration: InputDecoration(
            labelText: 'Hotel type',
            prefixIcon: const Icon(Icons.apartment_outlined, color: _kMuted),
            filled: true,
            fillColor: _kSoftBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.input), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.input), borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
          ),
          items: typeOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(growable: false),
          onChanged: (v) { if (v != null) onHotelType(v); },
        ),
        const SizedBox(height: 20),
        Text('Rooms: ${rooms.round()}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _kTitle)),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _kPrimary,
            inactiveTrackColor: _kSoftBg,
            thumbColor: _kPrimary,
            overlayColor: _kPrimary.withValues(alpha: 0.12),
            trackHeight: 4,
          ),
          child: Slider(value: rooms, min: 10, max: 500, divisions: 49, onChanged: onRooms),
        ),
      ],
    );
  }
}

// ── Step 1: Team setup ─────────────────────────────────────────────────────────
class _TeamSetupStep extends StatelessWidget {
  final int staffCount;
  final ValueChanged<int> onStaffCount;
  final Set<String> roles;
  final List<String> roleOptions;
  final ValueChanged<String> onToggleRole;
  final bool allergyHandling;
  final ValueChanged<bool> onAllergyHandling;

  const _TeamSetupStep({
    required this.staffCount, required this.onStaffCount,
    required this.roles, required this.roleOptions, required this.onToggleRole,
    required this.allergyHandling, required this.onAllergyHandling,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Team setup', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: _kTitle)),
        const SizedBox(height: 16),
        Text('Staff count', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _kTitle)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: _kPrimary, inactiveTrackColor: _kSoftBg,
                  thumbColor: _kPrimary, overlayColor: _kPrimary.withValues(alpha: 0.12),
                ),
                child: Slider(value: staffCount.toDouble(), min: 1, max: 80, divisions: 79, onChanged: (v) => onStaffCount(v.round())),
              ),
            ),
            SizedBox(
              width: 48,
              child: Text('$staffCount', textAlign: TextAlign.right,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Roles in your team', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _kTitle)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: roleOptions.map((r) {
            final selected = roles.contains(r);
            return GestureDetector(
              onTap: () => onToggleRole(r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? _kSoftBg : Colors.white,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  border: Border.all(color: selected ? _kPrimary : _kSoftBg, width: 1.5),
                ),
                child: Text(r, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                    color: selected ? _kDeep : _kMuted)),
              ),
            );
          }).toList(growable: false),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(color: _kSoftBg, borderRadius: BorderRadius.circular(AppRadii.md)),
          child: SwitchListTile(
            value: allergyHandling,
            onChanged: onAllergyHandling,
            activeColor: _kPrimary,
            title: Text('Allergy handling', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _kTitle)),
          ),
        ),
      ],
    );
  }
}

// ── Step 2: Alert preferences ──────────────────────────────────────────────────
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
    required this.notifySpoilage, required this.notifyLowInventory, required this.notifyWasteTips,
    required this.onNotifySpoilage, required this.onNotifyLowInventory, required this.onNotifyWasteTips,
    required this.wasteThreshold, required this.onWasteThreshold,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Alert preferences', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: _kTitle)),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(color: _kSoftBg, borderRadius: BorderRadius.circular(AppRadii.md)),
          child: Column(
            children: [
              SwitchListTile(
                value: notifySpoilage, onChanged: onNotifySpoilage, activeColor: _kPrimary,
                title: Text('Spoilage alerts', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _kTitle)),
              ),
              Divider(color: _kPrimary.withValues(alpha: 0.1), height: 1),
              SwitchListTile(
                value: notifyLowInventory, onChanged: onNotifyLowInventory, activeColor: _kPrimary,
                title: Text('Low inventory alerts', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _kTitle)),
              ),
              Divider(color: _kPrimary.withValues(alpha: 0.1), height: 1),
              SwitchListTile(
                value: notifyWasteTips, onChanged: onNotifyWasteTips, activeColor: _kPrimary,
                title: Text('Waste reduction tips', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _kTitle)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Waste threshold: ${wasteThreshold.round()}%',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _kTitle)),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _kPrimary, inactiveTrackColor: _kSoftBg,
            thumbColor: _kPrimary, overlayColor: _kPrimary.withValues(alpha: 0.12),
            trackHeight: 4,
          ),
          child: Slider(value: wasteThreshold, min: 0, max: 100, divisions: 20, onChanged: onWasteThreshold),
        ),
      ],
    );
  }
}
