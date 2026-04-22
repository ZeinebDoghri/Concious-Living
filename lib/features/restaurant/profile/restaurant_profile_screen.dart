import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants.dart';
import '../../../core/firebase_service.dart';
import '../../../providers/alerts_provider.dart';
import '../../../providers/inventory_provider.dart';
import '../../../providers/user_provider.dart';

class RestaurantProfileScreen extends StatefulWidget {
  const RestaurantProfileScreen({super.key});

  @override
  State<RestaurantProfileScreen> createState() => _RestaurantProfileScreenState();
}

class _RestaurantProfileScreenState extends State<RestaurantProfileScreen> {
  static const _oliveMutedText = Color(0xFFD4E8A8);
  static const _prefsExpiryWarningsKey = 'restaurant_expiry_warnings';
  static const _prefsWasteThresholdAlertsKey = 'restaurant_waste_threshold_alerts';

  bool _expiryWarnings = true;
  bool _wasteThresholdAlerts = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _expiryWarnings = prefs.getBool(_prefsExpiryWarningsKey) ?? true;
      _wasteThresholdAlerts = prefs.getBool(_prefsWasteThresholdAlertsKey) ?? true;
    });
  }

  Future<void> _setExpiryWarnings(bool value) async {
    setState(() => _expiryWarnings = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsExpiryWarningsKey, value);
  }

  Future<void> _setWasteThresholdAlerts(bool value) async {
    setState(() => _wasteThresholdAlerts = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsWasteThresholdAlertsKey, value);
  }

  String _fmtText(String? value, {String fallback = '—'}) {
    final v = (value ?? '').trim();
    return v.isEmpty ? fallback : v;
  }

  String _registrationDateText() {
    final dt = FirebaseAuth.instance.currentUser?.metadata.creationTime;
    if (dt == null) return '—';
    return DateFormat('MMM d, yyyy').format(dt);
  }

  void _about(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.parchment,
          title: Text(
            AppStrings.aboutProject,
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
              onPressed: () => context.pop(),
              child: Text(
                AppStrings.ok,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: AppColors.olive,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseService.signOut();
    if (!context.mounted) return;
    context.go(AppRoutes.roleSelector);
  }

  int _resolvedAlertsCount(AlertsProvider provider) {
    return provider.alerts.where((a) => a.status == 'resolved').length;
  }

  int _freshnessPct(InventoryProvider inventory) {
    final items = inventory.items;
    if (items.isEmpty) return 94;
    final fresh = items.where((e) => e.status == 'fresh').length;
    return ((fresh / items.length) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.currentUser;
    final alertsProvider = context.watch<AlertsProvider>();
    final inventoryProvider = context.watch<InventoryProvider>();

    final restaurantName = _fmtText(user?.restaurantName, fallback: AppStrings.appName);
    final cuisineType = _fmtText(user?.cuisineType);
    final covers = user?.covers ?? 0;
    final managerName = _fmtText(user?.name);
    final staffCount = user?.teamSize ?? user?.staffRoles.length ?? 0;

    final resolvedAlerts = _resolvedAlertsCount(alertsProvider);
    final freshPct = _freshnessPct(inventoryProvider);

    final pendingAlerts = alertsProvider.pendingCount;
    final expiringCount = inventoryProvider.items.where((e) => e.status == 'expiring').length;

    final logoUrl = (user?.avatarPath ?? '').trim();
    final hasLogo = logoUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.oat,
      body: Column(
        children: [
          SizedBox(
            height: 220,
            width: double.infinity,
            child: Stack(
              children: [
                Container(color: AppColors.olive),
                Positioned.fill(child: CustomPaint(painter: _ArcPainter())),
                SafeArea(
                  bottom: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(42),
                            child: Container(
                              width: 84,
                              height: 84,
                              color: AppColors.oliveMist,
                              alignment: Alignment.center,
                              child: hasLogo
                                  ? Image.network(
                                      logoUrl,
                                      width: 84,
                                      height: 84,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, _, error) {
                                        return const Icon(Icons.restaurant, size: 36, color: AppColors.olive);
                                      },
                                    )
                                  : const Icon(Icons.restaurant, size: 36, color: AppColors.olive),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.cherryBlush,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Restaurant',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.cherry,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            restaurantName,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.butter,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$cuisineType · $covers covers',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: _oliveMutedText,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            managerName,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: _oliveMutedText,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _StatPill(label: '$resolvedAlerts Alerts resolved'),
                              const SizedBox(width: 10),
                              _StatPill(label: '$freshPct% Freshness'),
                              const SizedBox(width: 10),
                              _StatPill(label: '$staffCount Staff'),
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
                          Text(
                            "Today's performance",
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
                                child: _KpiTile(
                                  number: '$pendingAlerts',
                                  label: 'Alerts',
                                  numberColor: AppColors.cherry,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _KpiTile(
                                  number: '$expiringCount',
                                  label: 'Expiring',
                                  numberColor: AppColors.riskModerateText,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: _KpiTile(
                                  number: '12kg',
                                  label: 'Waste',
                                  numberColor: AppColors.olive,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _KpiTile(
                                  number: '$freshPct%',
                                  label: 'Fresh',
                                  numberColor: AppColors.olive,
                                ),
                              ),
                            ],
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
                              'Restaurant information',
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.espresso,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => context.push('/restaurant/profile/edit'),
                              icon: const Icon(Icons.edit_outlined),
                              color: AppColors.olive,
                              iconSize: 18,
                              splashRadius: 18,
                            ),
                          ],
                        ),
                        _InfoRow(label: 'Restaurant name', value: restaurantName),
                        const Divider(color: AppColors.sand, height: 1),
                        _InfoRow(label: 'Manager', value: managerName),
                        const Divider(color: AppColors.sand, height: 1),
                        _InfoRow(label: 'Email', value: _fmtText(user?.email)),
                        const Divider(color: AppColors.sand, height: 1),
                        _InfoRow(label: 'Phone', value: _fmtText(user?.phone)),
                        const Divider(color: AppColors.sand, height: 1),
                        _InfoRow(label: 'Cuisine type', value: cuisineType),
                        const Divider(color: AppColors.sand, height: 1),
                        _InfoRow(label: 'Number of covers', value: covers.toString()),
                        const Divider(color: AppColors.sand, height: 1),
                        _InfoRow(label: 'Registration date', value: _registrationDateText()),
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
                              'Kitchen & safety',
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.espresso,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => context.push('/restaurant/profile/edit?step=2'),
                              icon: const Icon(Icons.edit_outlined),
                              color: AppColors.olive,
                              iconSize: 18,
                              splashRadius: 18,
                            ),
                          ],
                        ),
                        Text(
                          'Staff roles',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.fog,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _ChipsWrap(
                          chips: (user?.staffRoles ?? const <String>[])
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList(growable: false),
                          emptyText: 'No roles set',
                          emptyStyle: GoogleFonts.inter(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppColors.fog,
                          ),
                          chipBuilder: (r) => _Chip(
                            text: r,
                            bg: AppColors.oliveMist,
                            border: AppColors.olive,
                            fg: AppColors.olive,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Divider(color: AppColors.sand, height: 1),
                        const SizedBox(height: 10),
                        Text(
                          'Allergy handling',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.fog,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              (user?.allergyHandling ?? false) ? Icons.check_circle : Icons.cancel,
                              size: 16,
                              color: (user?.allergyHandling ?? false) ? AppColors.olive : AppColors.cherry,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              (user?.allergyHandling ?? false) ? 'Yes, we handle allergies' : 'No',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.espresso,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(color: AppColors.sand, height: 1),
                        const SizedBox(height: 10),
                        Text(
                          'Waste alert threshold',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.fog,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(user?.wasteThreshold ?? 10).toStringAsFixed(0)} kg per day',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.espresso,
                            height: 1.2,
                          ),
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
                          'Alert preferences',
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.espresso,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: AppColors.olive,
                          activeTrackColor: AppColors.olive.withValues(alpha: 0.25),
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
                            userProvider.saveProfile(existing.copyWith(notifyAllergens: v));
                          },
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: AppColors.olive,
                          activeTrackColor: AppColors.olive.withValues(alpha: 0.25),
                          title: Text(
                            'Expiry warnings',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.espresso,
                            ),
                          ),
                          value: _expiryWarnings,
                          onChanged: (v) => _setExpiryWarnings(v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: AppColors.olive,
                          activeTrackColor: AppColors.olive.withValues(alpha: 0.25),
                          title: Text(
                            'Daily waste report',
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
                            userProvider.saveProfile(existing.copyWith(notifyWeeklyReport: v));
                          },
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: AppColors.olive,
                          activeTrackColor: AppColors.olive.withValues(alpha: 0.25),
                          title: Text(
                            'Waste threshold alerts',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.espresso,
                            ),
                          ),
                          value: _wasteThresholdAlerts,
                          onChanged: (v) => _setWasteThresholdAlerts(v),
                        ),
                      ],
                    ),
                  ),
                  _Card(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.people_outline, color: AppColors.olive),
                          title: Text(
                            'Manage staff',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.espresso,
                            ),
                          ),
                          onTap: () {},
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.bar_chart, color: AppColors.olive),
                          title: Text(
                            'View full reports',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.espresso,
                            ),
                          ),
                          onTap: () => context.go(AppRoutes.restaurantWaste),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.info_outline, color: AppColors.fog),
                          title: Text(
                            'About the project',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.espresso,
                            ),
                          ),
                          onTap: () => _about(context),
                        ),
                        const Divider(color: AppColors.sand, height: 1),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.logout, color: AppColors.olive),
                          title: Text(
                            'Sign out',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.olive,
                            ),
                          ),
                          onTap: () => _signOut(context),
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

class _KpiTile extends StatelessWidget {
  final String number;
  final String label;
  final Color numberColor;

  const _KpiTile({
    required this.number,
    required this.label,
    required this.numberColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
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
              color: numberColor,
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
