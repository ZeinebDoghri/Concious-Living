import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../providers/user_provider.dart';

class HotelProfileScreen extends StatelessWidget {
  const HotelProfileScreen({super.key});

  static const _headerSecondaryText = AppColors.cocoa;

  String _text(String? value, {String fallback = '—'}) {
    final text = (value ?? '').trim();
    return text.isEmpty ? fallback : text;
  }

  String _memberSince() {
    final created = FirebaseAuth.instance.currentUser?.metadata.creationTime;
    if (created == null) return '—';
    return DateFormat('MMM d, yyyy').format(created);
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.parchment,
          title: Text(
            AppStrings.signOut,
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.espresso,
            ),
          ),
          content: Text(
            'You will need to sign in again to manage this hotel account.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.cocoa,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => dialogContext.pop(false),
              child: Text(
                AppStrings.cancel,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: AppColors.cocoa,
                ),
              ),
            ),
            TextButton(
              onPressed: () => dialogContext.pop(true),
              child: Text(
                AppStrings.confirm,
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

    if (confirmed != true || !context.mounted) return;

    await context.read<UserProvider>().logout();
    if (!context.mounted) return;
    context.go(AppRoutes.roleSelector);
  }

  void _about(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
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
              onPressed: () => dialogContext.pop(),
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
      backgroundColor: AppColors.oat,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 220),
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
                                        return const Icon(Icons.hotel, size: 36, color: AppColors.olive);
                                      },
                                    )
                                  : const Icon(Icons.hotel, size: 36, color: AppColors.olive),
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
                              'Hotel',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.cherry,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            hotelName,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.espresso,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$hotelType · $rooms rooms',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: _headerSecondaryText,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            managerName,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: _headerSecondaryText,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _StatPill(label: _memberSince(), icon: Icons.verified_outlined),
                              const SizedBox(width: 10),
                              _StatPill(label: email, icon: Icons.email_outlined),
                              const SizedBox(width: 10),
                              _StatPill(label: phone, icon: Icons.phone_outlined),
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
                            'Hotel overview',
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.espresso,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _KpiTile(number: '$rooms', label: 'Rooms', color: AppColors.olive)),
                              const SizedBox(width: 10),
                              Expanded(child: _KpiTile(number: hotelType, label: 'Type', color: AppColors.cherry)),
                              const SizedBox(width: 10),
                              Expanded(child: _KpiTile(number: managerName, label: 'Manager', color: AppColors.espresso)),
                              const SizedBox(width: 10),
                              Expanded(child: _KpiTile(number: '24/7', label: 'Support', color: AppColors.olive)),
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
                              'Hotel information',
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.espresso,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => context.push('/hotel/profile/edit'),
                              icon: const Icon(Icons.edit_outlined),
                              color: AppColors.olive,
                              iconSize: 18,
                              splashRadius: 18,
                            ),
                          ],
                        ),
                        _InfoRow(label: 'Hotel name', value: hotelName),
                        const Divider(color: AppColors.sand, height: 1),
                        _InfoRow(label: 'Hotel type', value: hotelType),
                        const Divider(color: AppColors.sand, height: 1),
                        _InfoRow(label: 'Rooms', value: rooms.toString()),
                        const Divider(color: AppColors.sand, height: 1),
                        _InfoRow(label: 'Manager', value: managerName),
                        const Divider(color: AppColors.sand, height: 1),
                        _InfoRow(label: 'Email', value: email),
                        const Divider(color: AppColors.sand, height: 1),
                        _InfoRow(label: 'Phone', value: phone),
                        const Divider(color: AppColors.sand, height: 1),
                        _InfoRow(label: 'Member since', value: _memberSince()),
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
                              'Operations & preferences',
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.espresso,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => context.push('/hotel/profile/edit?step=2'),
                              icon: const Icon(Icons.edit_outlined),
                              color: AppColors.olive,
                              iconSize: 18,
                              splashRadius: 18,
                            ),
                          ],
                        ),
                        _BulletRow(
                          icon: Icons.bed_outlined,
                          text: 'Rooms and housekeeping planning are centralized here.',
                        ),
                        const SizedBox(height: 12),
                        _BulletRow(
                          icon: Icons.room_service_outlined,
                          text: 'Front desk, kitchen, and housekeeping staff can be tracked in the edit flow.',
                        ),
                        const SizedBox(height: 12),
                        _BulletRow(
                          icon: Icons.notifications_active_outlined,
                          text: 'Alert preferences are configured in the hotel setup/edit flow.',
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
                          leading: const Icon(Icons.edit_note_outlined, color: AppColors.olive),
                          title: Text(
                            'Edit profile',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.espresso,
                            ),
                          ),
                          onTap: () => context.push('/hotel/profile/edit'),
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
    final center = Offset(size.width * 0.88, size.height * 0.12);
    final radius = size.width * 0.8;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

class _StatPill extends StatelessWidget {
  final String label;
  final IconData icon;

  const _StatPill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 112),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.parchment.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.espresso),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.espresso,
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
  final String number;
  final String label;
  final Color color;

  const _KpiTile({required this.number, required this.label, required this.color});

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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
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

class _BulletRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BulletRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.olive),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.espresso,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
