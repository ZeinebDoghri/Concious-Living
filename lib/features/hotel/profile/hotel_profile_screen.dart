import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../providers/user_provider.dart';

const _kPrimary = Color(0xFF5A9FC9);
const _kDeep = Color(0xFF35658F);
const _kSurface = Color(0xFFF0F5F8);
const _kSoftBg = Color(0xFFD9E9F5);
const _kTitle = Color(0xFF26201B);
const _kBody = Color(0xFF5C4F48);
const _kMuted = Color(0xFF8C7E78);

class HotelProfileScreen extends StatelessWidget {
  const HotelProfileScreen({super.key});

  String _text(String? value, {String fallback = '—'}) {
    final t = (value ?? '').trim();
    return t.isEmpty ? fallback : t;
  }

  String _memberSince() {
    final created = FirebaseAuth.instance.currentUser?.metadata.creationTime;
    if (created == null) return '—';
    return DateFormat('MMM d, yyyy').format(created);
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
        ),
        title: Text(
          AppStrings.signOut,
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _kTitle,
          ),
        ),
        content: Text(
          'You will need to sign in again to manage this hotel account.',
          style: GoogleFonts.inter(fontSize: 13, color: _kBody, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: Text(
              AppStrings.cancel,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: _kMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () => ctx.pop(true),
            child: Text(
              AppStrings.confirm,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: ORKATheme.danger,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<UserProvider>().logout();
    if (!context.mounted) return;
    context.go(AppRoutes.roleSelector);
  }

  void _about(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
        ),
        title: Text(
          AppStrings.aboutProject,
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _kTitle,
          ),
        ),
        content: Text(
          AppStrings.taglineLong,
          style: GoogleFonts.inter(fontSize: 13, color: _kBody, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (ctx.canPop()) {
                ctx.pop();
              }
            },
            child: Text(
              AppStrings.ok,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;
    final hotelName = _text(user?.hotelName, fallback: AppStrings.appName);
    final hotelType = _text(user?.hotelType);
    final rooms = user?.rooms ?? 0;
    final managerName = _text(user?.name);
    final email = _text(user?.email);
    final phone = _text(user?.phone);
    final logoUrl = (user?.avatarPath ?? '').trim();
    final hasLogo = logoUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: _kSurface,
      body: Column(
        children: [
          // ── Hero header ──────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 240),
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  children: [
                    // avatar
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _kSoftBg,
                        boxShadow: AppShadows.md(_kPrimary),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: hasLogo
                          ? Image.network(
                              logoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.hotel,
                                size: 40,
                                color: _kDeep,
                              ),
                            )
                          : const Icon(Icons.hotel, size: 40, color: _kDeep),
                    ),
                    const SizedBox(height: 12),
                    // role chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Text(
                        'Hotel',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      hotelName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$hotelType · $rooms rooms',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.80),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      managerName,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // info pills
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _InfoPill(
                          icon: Icons.verified_outlined,
                          label: _memberSince(),
                        ),
                        _InfoPill(icon: Icons.email_outlined, label: email),
                        _InfoPill(icon: Icons.phone_outlined, label: phone),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Scrollable body ──────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  // overlap card
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: _Section(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hotel overview',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _kTitle,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _KpiTile(
                                  value: '$rooms',
                                  label: 'Rooms',
                                  color: _kPrimary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _KpiTile(
                                  value: hotelType,
                                  label: 'Type',
                                  color: _kDeep,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _KpiTile(
                                  value: managerName,
                                  label: 'Manager',
                                  color: _kBody,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _KpiTile(
                                  value: '24/7',
                                  label: 'Support',
                                  color: _kPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Hotel info card
                  _Section(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Hotel information',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _kTitle,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () =>
                                  context.push(AppRoutes.hotelProfileEdit),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              color: _kPrimary,
                            ),
                          ],
                        ),
                        _InfoRow(label: 'Hotel name', value: hotelName),
                        _InfoRow(label: 'Hotel type', value: hotelType),
                        _InfoRow(label: 'Rooms', value: rooms.toString()),
                        _InfoRow(label: 'Manager', value: managerName),
                        _InfoRow(label: 'Email', value: email),
                        _InfoRow(label: 'Phone', value: phone),
                        _InfoRow(label: 'Member since', value: _memberSince()),
                      ],
                    ),
                  ),

                  // Operations card
                  _Section(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Operations & preferences',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _kTitle,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => context.push(
                                '${AppRoutes.hotelProfileEdit}?step=2',
                              ),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              color: _kPrimary,
                            ),
                          ],
                        ),
                        _BulletRow(
                          icon: Icons.bed_outlined,
                          text:
                              'Rooms and housekeeping planning are centralized here.',
                        ),
                        const SizedBox(height: 10),
                        _BulletRow(
                          icon: Icons.room_service_outlined,
                          text:
                              'Front desk, kitchen, and housekeeping staff tracked in the edit flow.',
                        ),
                        const SizedBox(height: 10),
                        _BulletRow(
                          icon: Icons.notifications_active_outlined,
                          text:
                              'Alert preferences configured in the hotel setup/edit flow.',
                        ),
                      ],
                    ),
                  ),

                  // Actions card
                  _Section(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _kSoftBg,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit_note_outlined,
                              color: _kDeep,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            'Edit profile',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _kTitle,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: _kMuted,
                            size: 18,
                          ),
                          onTap: () => context.push(AppRoutes.hotelProfileEdit),
                        ),
                        const Divider(color: Color(0xFFD9E9F5), height: 1),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _kSoftBg,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.info_outline,
                              color: _kDeep,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            'About the project',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _kTitle,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: _kMuted,
                            size: 18,
                          ),
                          onTap: () => _about(context),
                        ),
                        const Divider(color: Color(0xFFD9E9F5), height: 1),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: ORKATheme.danger.withValues(
                                alpha: 0.08,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.logout,
                              color: ORKATheme.danger,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            'Sign out',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: ORKATheme.danger,
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

class _Section extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;
  const _Section({required this.child, required this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.innerCard),
        boxShadow: AppShadows.sm(_kPrimary),
      ),
      child: child,
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 130),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _KpiTile({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _kSoftBg,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: _kMuted,
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _kMuted,
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
                    color: _kTitle,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Color(0xFFD9E9F5), height: 1),
      ],
    );
  }
}

class _BulletRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _BulletRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: _kPrimary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 13, color: _kBody, height: 1.45),
          ),
        ),
      ],
    );
  }
}
