import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants.dart';
import '../../../core/models/user_model.dart';
import '../../../providers/scan_history_provider.dart';
import '../../../providers/user_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _cherryMutedText = Color(0xFFF5C0C2);
  static const _prefsAllergensKey = 'customer_allergens_json';

  String _fmtText(String? value, {String fallback = '—'}) {
    final v = (value ?? '').trim();
    return v.isEmpty ? fallback : v;
  }

  String _fmtDob(DateTime? value) {
    if (value == null) return '—';
    return DateFormat('MMM d, yyyy').format(value);
  }

  String _memberSinceText() {
    final dt = FirebaseAuth.instance.currentUser?.metadata.creationTime;
    if (dt == null) return 'Member since —';
    return 'Member since ${DateFormat('MMM yyyy').format(dt)}';
  }

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';

    final parts = trimmed
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';

    String firstChar(String s) {
      final t = s.trim();
      if (t.isEmpty) return '';
      return t.substring(0, 1).toUpperCase();
    }

    final first = firstChar(parts.first);
    final second = parts.length > 1 ? firstChar(parts[1]) : '';
    return (first + second).trim();
  }

  String _conditionTag(List<String>? conditions) {
    final list = (conditions ?? const <String>[])
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e != 'None')
        .toList(growable: false);
    if (list.isEmpty) return 'Healthy';
    return list.first;
  }

  Color _barColor(double pct) {
    if (pct > 100) return AppColors.cherry;
    if (pct >= 80) return AppColors.butterDeep;
    return AppColors.olive;
  }

  Future<List<String>> _loadAllergens(UserModel? user) async {
    final profileAllergens = user?.allergens ?? const <String>[];
    if (profileAllergens.isNotEmpty) {
      return profileAllergens;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsAllergensKey);

    if (raw == null || raw.trim().isEmpty) return <String>[];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.whereType<String>().toList();
    } catch (_) {}

    return <String>[];
  }

  Future<bool> _confirmDialog(
    BuildContext context, {
    required String title,
    required String body,
  }) async {
    return (await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(
                title,
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.espresso,
                ),
              ),
              content: Text(
                body,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.cocoa,
                  height: 1.5,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(AppStrings.cancel, style: GoogleFonts.inter()),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    AppStrings.ok,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: AppColors.cherry,
                    ),
                  ),
                ),
              ],
            );
          },
        )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.currentUser;
    final scans = context.watch<ScanHistoryProvider>().items;

    final scansTotal = scans.length;
    final scansThisWeek = scans
        .where((e) => DateTime.now().difference(e.scannedAt).inDays <= 7)
        .length;

    final intakePct = userProvider.mockDailyIntakePct;
    final goalsMet = intakePct.values.where((v) => v <= 100).length;

    String avgRiskLabel() {
      if (scans.isEmpty) return 'Low';

      int score(String r) {
        switch (r) {
          case 'high':
            return 3;
          case 'moderate':
            return 2;
          case 'low':
          default:
            return 1;
        }
      }

      final recent = scans.take(12).toList(growable: false);
      final avg =
          recent
              .map((e) => score(e.result.overallRisk))
              .reduce((a, b) => a + b) /
          recent.length;
      if (avg >= 2.4) return 'High';
      if (avg >= 1.7) return 'Moderate';
      return 'Low';
    }

    final avatarUrl = (user?.avatarPath ?? '').trim();
    final avatarImage = avatarUrl.isEmpty ? null : NetworkImage(avatarUrl);

    return Scaffold(
      backgroundColor: AppColors.oat,
      body: Column(
        children: [
          SizedBox(
            height: 220,
            width: double.infinity,
            child: Stack(
              children: [
                Container(color: AppColors.cherry),
                Positioned.fill(child: CustomPaint(painter: _ArcPainter())),
                SafeArea(
                  bottom: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 42,
                            backgroundColor: AppColors.cherryBlush,
                            foregroundImage: avatarImage,
                            child: avatarImage == null
                                ? Text(
                                    _initials(user?.name ?? ''),
                                    style: GoogleFonts.dmSerifDisplay(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.cherry,
                                      height: 1.0,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.oliveMist,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Customer',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.olive,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _fmtText(user?.name, fallback: AppStrings.appName),
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.butter,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _fmtText(user?.email, fallback: ''),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: _cherryMutedText,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _memberSinceText(),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: _cherryMutedText,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _StatPill(label: '$scansTotal Scans'),
                              const SizedBox(width: 10),
                              _StatPill(label: '$goalsMet Goals met'),
                              const SizedBox(width: 10),
                              _StatPill(label: _conditionTag(user?.conditions)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: _Card(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Health snapshot',
                                style: GoogleFonts.dmSerifDisplay(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.espresso,
                                ),
                              ),
                              const Spacer(),
                              InkWell(
                                onTap: () =>
                                    context.go('/customer/nutrition-goals'),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 6,
                                  ),
                                  child: Text(
                                    'Edit goals',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.cherry,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _MiniProgressRow(
                            icon: Icons.favorite_border,
                            name: 'Cholesterol',
                            pct: intakePct['cholesterol'] ?? 0,
                            barColor: _barColor(intakePct['cholesterol'] ?? 0),
                          ),
                          _MiniProgressRow(
                            icon: Icons.blur_circular,
                            name: 'Saturated fat',
                            pct: intakePct['saturatedFat'] ?? 0,
                            barColor: _barColor(intakePct['saturatedFat'] ?? 0),
                          ),
                          _MiniProgressRow(
                            icon: Icons.water_drop_outlined,
                            name: 'Sodium',
                            pct: intakePct['sodium'] ?? 0,
                            barColor: _barColor(intakePct['sodium'] ?? 0),
                          ),
                          _MiniProgressRow(
                            icon: Icons.cookie_outlined,
                            name: 'Sugar',
                            pct: intakePct['sugar'] ?? 0,
                            barColor: _barColor(intakePct['sugar'] ?? 0),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(color: AppColors.sand, height: 1),
                          ),
                          FutureBuilder<List<String>>(
                            future: _loadAllergens(user),
                            builder: (context, snap) {
                              final allergens = snap.data ?? const <String>[];
                              return Row(
                                children: [
                                  Text(
                                    'Dietary: None set',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.cocoa,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Allergens: ${allergens.length} flagged',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.cherry,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  _Card(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Personal information',
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.espresso,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () =>
                                  context.push(AppRoutes.customerEditProfile),
                              icon: const Icon(Icons.edit_outlined),
                              color: AppColors.cherry,
                              iconSize: 18,
                              splashRadius: 18,
                            ),
                          ],
                        ),
                        _InfoRow(
                          label: AppStrings.fullName,
                          value: _fmtText(user?.name),
                        ),
                        const Divider(color: AppColors.sand, height: 1),
                        _InfoRow(
                          label: 'Date of birth',
                          value: _fmtDob(user?.dateOfBirth),
                        ),
                        const Divider(color: AppColors.sand, height: 1),
                        _InfoRow(label: 'Phone', value: _fmtText(user?.phone)),
                        const Divider(color: AppColors.sand, height: 1),
                        _InfoRow(
                          label: 'Gender',
                          value: _fmtText(user?.gender),
                        ),
                      ],
                    ),
                  ),
                  _Card(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Health profile',
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.espresso,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => context.push(
                                '${AppRoutes.customerEditProfile}?step=2',
                              ),
                              icon: const Icon(Icons.edit_outlined),
                              color: AppColors.cherry,
                              iconSize: 18,
                              splashRadius: 18,
                            ),
                          ],
                        ),
                        Text(
                          'Conditions',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.fog,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _ChipsWrap(
                          chips: (user?.conditions ?? const <String>[])
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty && e != 'None')
                              .toList(growable: false),
                          emptyText: 'No conditions registered',
                          emptyStyle: GoogleFonts.inter(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppColors.fog,
                          ),
                          chipBuilder: (c) => _Chip(
                            text: c,
                            bg: AppColors.cherryBlush,
                            border: AppColors.cherry,
                            fg: AppColors.cherry,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Divider(color: AppColors.sand, height: 1),
                        const SizedBox(height: 10),
                        Text(
                          'Dietary preferences',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.fog,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _ChipsWrap(
                          chips: const <String>[],
                          emptyText: 'No preferences set',
                          emptyStyle: GoogleFonts.inter(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppColors.fog,
                          ),
                          chipBuilder: (c) => _Chip(
                            text: c,
                            bg: AppColors.oliveMist,
                            border: AppColors.olive,
                            fg: AppColors.olive,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Divider(color: AppColors.sand, height: 1),
                        const SizedBox(height: 10),
                        Text(
                          'Allergens',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.fog,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FutureBuilder<List<String>>(
                          future: _loadAllergens(user),
                          builder: (context, snap) {
                            final allergens =
                                (snap.data ?? const <String>[]).toList()
                                  ..sort();
                            if (allergens.isEmpty) {
                              return Text(
                                'No allergens flagged',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.fog,
                                ),
                              );
                            }

                            return Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: allergens
                                  .map(
                                    (a) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.butter,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.riskModerateText,
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.warning_amber_rounded,
                                            size: 10,
                                            color: AppColors.riskModerateText,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            a,
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.riskModerateText,
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
                      ],
                    ),
                  ),
                  _Card(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Activity',
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.espresso,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricTile(
                                number: '$scansTotal',
                                label: 'Total scans',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MetricTile(
                                number: '$scansThisWeek',
                                label: 'This week',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MetricTile(
                                number: avgRiskLabel(),
                                label: 'Avg risk',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _Card(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Settings',
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.espresso,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: AppColors.cherry,
                          activeTrackColor: AppColors.cherry.withValues(
                            alpha: 0.25,
                          ),
                          title: Text(
                            'Daily intake summary',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.espresso,
                            ),
                          ),
                          value: user?.notifyDailyIntake ?? true,
                          onChanged: (v) {
                            final existing = user;
                            if (existing == null) return;
                            userProvider.saveProfile(
                              existing.copyWith(notifyDailyIntake: v),
                            );
                          },
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: AppColors.cherry,
                          activeTrackColor: AppColors.cherry.withValues(
                            alpha: 0.25,
                          ),
                          title: Text(
                            'Allergen alerts',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.espresso,
                            ),
                          ),
                          value: user?.notifyAllergens ?? true,
                          onChanged: (v) {
                            final existing = user;
                            if (existing == null) return;
                            userProvider.saveProfile(
                              existing.copyWith(notifyAllergens: v),
                            );
                          },
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: AppColors.cherry,
                          activeTrackColor: AppColors.cherry.withValues(
                            alpha: 0.25,
                          ),
                          title: Text(
                            'Weekly health report',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.espresso,
                            ),
                          ),
                          value: user?.notifyWeeklyReport ?? true,
                          onChanged: (v) {
                            final existing = user;
                            if (existing == null) return;
                            userProvider.saveProfile(
                              existing.copyWith(notifyWeeklyReport: v),
                            );
                          },
                        ),
                        const Divider(color: AppColors.sand, height: 1),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.flag_outlined,
                            color: AppColors.cherry,
                          ),
                          title: Text(
                            'Nutrition goals',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.espresso,
                            ),
                          ),
                          onTap: () => context.go('/customer/nutrition-goals'),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.history,
                            color: AppColors.cherry,
                          ),
                          title: Text(
                            'Scan history',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.espresso,
                            ),
                          ),
                          onTap: () => context.go(AppRoutes.customerHistory),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.info_outline,
                            color: AppColors.fog,
                          ),
                          title: Text(
                            'About the project',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.espresso,
                            ),
                          ),
                          onTap: () {
                            showDialog<void>(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text(
                                    'About the project',
                                    style: GoogleFonts.dmSerifDisplay(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.espresso,
                                    ),
                                  ),
                                  content: Text(
                                    AppStrings.taglineLong,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.cocoa,
                                      height: 1.5,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: Text(
                                        AppStrings.ok,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.cherry,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                        const Divider(color: AppColors.sand, height: 1),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.delete_outline,
                            color: AppColors.cherry,
                          ),
                          title: Text(
                            'Clear history',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.cherry,
                            ),
                          ),
                          onTap: () async {
                            final ok = await _confirmDialog(
                              context,
                              title: 'Clear history',
                              body:
                                  'This will clear your scan history on this device.',
                            );
                            if (!context.mounted || !ok) return;
                            await context
                                .read<ScanHistoryProvider>()
                                .clearAll();
                          },
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.logout,
                            color: AppColors.cherry,
                          ),
                          title: Text(
                            'Sign out',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.cherry,
                            ),
                          ),
                          onTap: () async {
                            final ok = await _confirmDialog(
                              context,
                              title: 'Sign out',
                              body: 'Are you sure you want to sign out?',
                            );
                            if (!context.mounted || !ok) return;
                            await userProvider.logout();
                            if (!context.mounted) return;
                            context.go(AppRoutes.roleSelector);
                          },
                        ),
                      ],
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

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.06);
    final center = Offset(size.width * 0.86, size.height * 0.14);
    final radius = size.width * 0.78;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StatPill extends StatelessWidget {
  final String label;

  const _StatPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.butter.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.butter,
          height: 1.2,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;

  const _Card({required this.child, required this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.parchment,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sand, width: 0.5),
      ),
      child: child,
    );
  }
}

class _MiniProgressRow extends StatelessWidget {
  final IconData icon;
  final String name;
  final double pct;
  final Color barColor;

  const _MiniProgressRow({
    required this.icon,
    required this.name,
    required this.pct,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = pct.isNaN ? 0.0 : pct;
    final progress = (clamped / 100).clamp(0.0, 1.0);

    return SizedBox(
      height: 36,
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.cocoa),
          const SizedBox(width: 10),
          SizedBox(
            width: 92,
            child: Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.cocoa,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.oatDeep,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 44,
            child: Text(
              '${clamped.toStringAsFixed(0)}%',
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.cherry,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.fog,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.espresso,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String number;
  final String label;

  const _MetricTile({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.oat,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.sand, width: 0.5),
      ),
      child: Column(
        children: [
          Text(
            number,
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.cherry,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.cocoa,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color bg;
  final Color border;
  final Color fg;

  const _Chip({
    required this.text,
    required this.bg,
    required this.border,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }
}

class _ChipsWrap extends StatelessWidget {
  final List<String> chips;
  final String emptyText;
  final TextStyle emptyStyle;
  final Widget Function(String) chipBuilder;

  const _ChipsWrap({
    required this.chips,
    required this.emptyText,
    required this.emptyStyle,
    required this.chipBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) {
      return Text(emptyText, style: emptyStyle);
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: chips.map(chipBuilder).toList(growable: false),
    );
  }
}
