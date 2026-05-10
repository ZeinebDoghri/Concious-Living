import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants.dart';
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
  List<String> _allergens = <String>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);

    List<String> next = <String>[];
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) next = decoded.whereType<String>().toList();
      } catch (_) {
        next = <String>[];
      }
    }

    if (!mounted) return;
    setState(() {
      _allergens = next;
      _loading = false;
    });
  }

  Future<void> _save(List<String> next) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(next));

    if (!mounted) return;
    setState(() => _allergens = next);
  }

  Future<void> _edit() async {
    final initial = Set<String>.from(_allergens);
    final selected = await showModalBottomSheet<Set<String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _EditAllergensSheet(initial: initial);
      },
    );

    if (selected == null) return;
    await _save(selected.toList()..sort());
  }

  @override
  Widget build(BuildContext context) {
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
                          // Placeholder info card
                          Container(
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
                                        'Scan a dish to check for allergen risks.',
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

  const _EditAllergensSheet({required this.initial});

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
