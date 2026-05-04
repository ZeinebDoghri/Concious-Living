import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants.dart';
import '../../../providers/user_provider.dart';
import '../../../shared/widgets/animated_button.dart';
import '../../../shared/widgets/cherry_header.dart';
import '../../../shared/widgets/empty_state.dart';

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
    final userAllergens = context.read<UserProvider>().currentUser?.allergens;
    if (userAllergens != null && userAllergens.isNotEmpty) {
      final next = userAllergens.toList(growable: false)..sort();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(next));

      if (!mounted) return;
      setState(() {
        _allergens = next;
        _loading = false;
      });
      return;
    }

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

    final userProvider = context.read<UserProvider>();
    final user = userProvider.currentUser;
    if (user != null) {
      await userProvider.saveProfile(user.copyWith(allergens: next));
    }

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
      backgroundColor: AppColors.oat,
      body: SafeArea(
        child: Column(
          children: [
            CherryHeader(
              title: AppStrings.myAllergenProfile,
              subtitle: AppStrings.allergenBanner,
              showBack: false,
              actions: [
                IconButton(
                  onPressed: _edit,
                  icon: const Icon(Icons.edit_outlined),
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
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.cherry,
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.myAllergens,
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.espresso,
                                height: 1.2,
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
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.butter,
                                          borderRadius: BorderRadius.circular(
                                            AppRadii.chip,
                                          ),
                                          border: Border.all(
                                            color: AppColors.sand,
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Text(
                                          a,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.espresso,
                                            height: 1.2,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                            const SizedBox(height: 18),
                            Text(
                              AppStrings.recentAllergenWarnings,
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.espresso,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.infoBg,
                                borderRadius: BorderRadius.circular(
                                  AppRadii.innerCard,
                                ),
                                border: Border.all(
                                  color: AppColors.sand,
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: AppColors.infoText,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      AppStrings.allergenInformation,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.infoText,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            AnimatedButton(
                              label: AppStrings.scanYourDish,
                              color: AppColors.cherry,
                              textColor: AppColors.butter,
                              onTap: () async =>
                                  context.go(AppRoutes.customerScan),
                              height: 52,
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
          color: AppColors.parchment,
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
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.espresso,
                          height: 1.2,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
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
                          borderRadius: BorderRadius.circular(AppRadii.chip),
                          splashColor: AppColors.cherry.withValues(alpha: 0.12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.cherry
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                AppRadii.chip,
                              ),
                              border: Border.all(
                                color: AppColors.sand,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              a,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? AppColors.butter
                                    : AppColors.cocoa,
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
                  decoration: const InputDecoration(
                    labelText: 'Add custom allergen',
                    prefixIcon: Icon(Icons.add, color: AppColors.cocoa),
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
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(AppStrings.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(_selected),
                        child: Text(AppStrings.saveGoals),
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
