import 'dart:convert';
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants.dart';
import '../../../core/firebase_service.dart';
import '../../../core/models/alert_model.dart';
import '../../../providers/alerts_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../shared/widgets/empty_state.dart';

// ── Customer design tokens ─────────────────────────────────────────────────────
const _kPrimary = Color(0xFFD9899F);
const _kDeep = Color(0xFFB27589);
const _kSurface = Color(0xFFFEFAFC);
const _kSoftBg = Color(0xFFF9E9F2);
const _kTextTitle = Color(0xFF26201B);
const _kTextBody = Color(0xFF5C4F48);
const _kTextMuted = Color(0xFF8C7E78);
const _kDanger = Color(0xFFFF7070);

class AllergenScreen extends StatefulWidget {
  const AllergenScreen({super.key});

  @override
  State<AllergenScreen> createState() => _AllergenScreenState();
}

class _AllergenScreenState extends State<AllergenScreen>
    with SingleTickerProviderStateMixin {
  static const _prefsKey = 'customer_allergens_json';

  bool _loading = true;
  bool _saving = false;
  List<String> _allergens = <String>[];
  Timer? _autoSaveDebounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userProvider = context.read<UserProvider>();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);

    final cached = _decodeSaved(raw);
    if (mounted) {
      setState(() {
        _allergens = cached;
        _loading = false;
      });
    }

    try {
      final remote = _normalizeAllergens(await FirebaseService.getUserAllergens());
      await prefs.setString(_prefsKey, jsonEncode(remote));

      if (!mounted) return;
      setState(() {
        _allergens = remote;
        _loading = false;
      });

      userProvider.updateCurrentUserAllergens(remote);
    } catch (_) {}
  }

  List<String> _decodeSaved(String? raw) {
    if (raw == null || raw.trim().isEmpty) return <String>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return _normalizeAllergens(decoded.whereType<String>());
    } catch (_) {}
    return <String>[];
  }

  List<String> _normalizeAllergens(Iterable<String> values) {
    final cleaned = values
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList(growable: false)
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return cleaned;
  }

  @override
  void dispose() {
    _autoSaveDebounce?.cancel();
    super.dispose();
  }

  Future<void> _save(
    List<String> next, {
    bool showFeedback = false,
    bool fromAutoSave = false,
  }) async {
    final userProvider = context.read<UserProvider>();
    final normalized = _normalizeAllergens(next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(normalized));

    if (mounted) {
      setState(() {
        _allergens = normalized;
        if (!fromAutoSave) _saving = true;
      });
    }

    try {
      await FirebaseService.saveUserAllergens(normalized);
      userProvider.updateCurrentUserAllergens(normalized);

      if (!mounted) return;
      if (showFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Allergens saved to your account.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      if (showFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Saved on this device. Account sync will retry when online.',
            ),
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() => _saving = false);
  }

  void _scheduleAutoSave(Set<String> selected) {
    _autoSaveDebounce?.cancel();
    _autoSaveDebounce = Timer(const Duration(milliseconds: 450), () {
      _save(selected.toList(), fromAutoSave: true);
    });
  }

  Future<void> _edit() async {
    final initial = Set<String>.from(_allergens);
    final selected = await showModalBottomSheet<Set<String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _EditAllergensSheet(
          initial: initial,
          onSelectionChanged: _scheduleAutoSave,
        );
      },
    );

    if (selected == null) return;
    await _save(selected.toList(), showFeedback: true);
  }

  @override
  Widget build(BuildContext context) {
    final alertsProvider = context.watch<AlertsProvider>();
    final providerPendingAlerts = alertsProvider.filterByStatus('pending');
    final authUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: _kSurface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFB27589), Color(0xFFD9899F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.myAllergenProfile,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.allergenBanner,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _edit,
                    icon: const Icon(Icons.edit_outlined),
                    color: Colors.white,
                    splashColor: Colors.white.withValues(alpha: 0.2),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: _kPrimary))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_saving) ...[
                            LinearProgressIndicator(color: _kPrimary),
                            const SizedBox(height: 12),
                          ],
                          // ── Info banner ───────────────────────────────
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _kSoftBg,
                              borderRadius: BorderRadius.circular(
                                AppRadii.innerCard,
                              ),
                              border: Border.all(
                                color: _kPrimary.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: _kPrimary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    AppStrings.allergenInformation,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: _kTextBody,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // ── My allergens ──────────────────────────────
                          Text(
                            AppStrings.myAllergens,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _kTextTitle,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_allergens.isEmpty)
                            EmptyState(
                              icon: Icons.shield_outlined,
                              title: AppStrings.noAllergensTitle,
                              subtitle: AppStrings.noAllergensSubtitle,
                              actionLabel: AppStrings.editAllergenProfile,
                              onAction: _edit,
                            )
                          else
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: _allergens
                                  .map(
                                    (a) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _kDanger.withValues(alpha: 0.10),
                                        borderRadius: BorderRadius.circular(
                                          AppRadii.pill,
                                        ),
                                        border: Border.all(
                                          color: _kDanger.withValues(
                                            alpha: 0.35,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.warning_amber_rounded,
                                            size: 14,
                                            color: _kDanger,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            a,
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: _kDanger,
                                              height: 1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                          const SizedBox(height: 24),

                          // ── Recent allergen warnings ───────────────────
                          Text(
                            AppStrings.recentAllergenWarnings,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _kTextTitle,
                            ),
                          ),
                          const SizedBox(height: 10),
                          StreamBuilder<List<AlertModel>>(
                            stream: authUid.isEmpty
                                ? const Stream<List<AlertModel>>.empty()
                                : FirebaseService.watchAlertsByCustomer(authUid),
                            builder: (context, snapshot) {
                              final streamPending = (snapshot.data ?? const <AlertModel>[])
                                  .where((a) => a.status == 'pending')
                                  .toList(growable: false);
                              final pendingAlerts = streamPending.isNotEmpty
                                  ? streamPending
                                  : providerPendingAlerts;

                              if (pendingAlerts.isEmpty) {
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.innerCard,
                                    ),
                                    boxShadow: AppShadows.sm(_kPrimary),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: _kSoftBg,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.shield_outlined,
                                          color: _kPrimary,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'No recent warnings',
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: _kTextTitle,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              snapshot.hasError
                                                  ? 'Could not load warnings (${snapshot.error}).'
                                                  : 'Scan a dish to check for allergen risks.',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: _kTextMuted,
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return Column(
                                children: pendingAlerts
                                    .take(5)
                                    .map(
                                      (alert) => Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(bottom: 10),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: _kDanger.withValues(alpha: 0.10),
                                          borderRadius: BorderRadius.circular(
                                            AppRadii.innerCard,
                                          ),
                                          border: Border.all(
                                            color: _kDanger.withValues(alpha: 0.35),
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons.warning_amber_rounded,
                                              color: _kDanger,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'DANGEROUS ALLERGEN ALERT',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w800,
                                                      color: _kDanger,
                                                      letterSpacing: 0.2,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${alert.dishName} contains ${alert.allergen}',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: _kTextBody,
                                                      height: 1.35,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    alert.customerName,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      color: _kTextMuted,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                              );
                            },
                          ),
                          const SizedBox(height: 18),

                          // ── Scan CTA ──────────────────────────────────
                          GestureDetector(
                            onTap: () async =>
                                context.go(AppRoutes.customerScan),
                            child: Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFB27589),
                                    Color(0xFFD9899F),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppRadii.pill,
                                ),
                                boxShadow: AppShadows.md(_kPrimary),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.camera_alt_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppStrings.scanYourDish,
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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

class _EditAllergensSheet extends StatefulWidget {
  final Set<String> initial;
  final ValueChanged<Set<String>>? onSelectionChanged;

  const _EditAllergensSheet({
    required this.initial,
    this.onSelectionChanged,
  });

  @override
  State<_EditAllergensSheet> createState() => _EditAllergensSheetState();
}

class _EditAllergensSheetState extends State<_EditAllergensSheet> {
  late Set<String> _selected;
  final _customController = TextEditingController();

  static const _options = AppData.commonAllergens;

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.initial);
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppStrings.editAllergenProfile,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _kTextTitle,
                          height: 1.2,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: _kTextMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _options
                      .map((a) {
                        final selected = _selected.contains(a);
                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (selected) {
                                _selected.remove(a);
                              } else {
                                _selected.add(a);
                              }
                            });
                            widget.onSelectionChanged?.call(
                              Set<String>.from(_selected),
                            );
                          },
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                          splashColor: _kPrimary.withValues(alpha: 0.12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: selected ? _kSoftBg : Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                AppRadii.pill,
                              ),
                              border: Border.all(
                                color: selected
                                    ? _kPrimary
                                    : const Color(0xFFF9E9F2),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              a,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected ? _kDeep : _kTextMuted,
                                height: 1.2,
                              ),
                            ),
                          ),
                        );
                      })
                      .toList(growable: false),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _customController,
                  style: GoogleFonts.inter(fontSize: 14, color: _kTextTitle),
                  decoration: InputDecoration(
                    labelText: 'Add custom allergen',
                    labelStyle: GoogleFonts.inter(color: _kTextMuted),
                    prefixIcon: Icon(Icons.add, color: _kPrimary),
                    filled: true,
                    fillColor: _kSoftBg,
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
                      borderSide: BorderSide(color: _kPrimary, width: 1.5),
                    ),
                  ),
                  onSubmitted: (v) {
                    final t = v.trim();
                    if (t.isEmpty) return;
                    setState(() {
                      _selected.add(t);
                      _customController.clear();
                    });
                    widget.onSelectionChanged?.call(Set<String>.from(_selected));
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: _kSoftBg,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: Center(
                            child: Text(
                              AppStrings.cancel,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _kTextBody,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(_selected),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFB27589), Color(0xFFD9899F)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: Center(
                            child: Text(
                              AppStrings.saveGoals,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
