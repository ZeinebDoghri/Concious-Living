import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/venue_alert_service.dart';
import '../../../providers/user_provider.dart';

// ── Brand palette ──────────────────────────────────────────────────────────────
const _kOat      = Color(0xFFEDE0D3);
const _kParchment= Color(0xFFFAF5EE);
const _kSand     = Color(0xFFD9C9B4);
const _kCherry   = Color(0xFF75070C);
const _kCherryL  = Color(0xFF9E1A21);
const _kCherryB  = Color(0xFFFBBCBF);
const _kOlive    = Color(0xFF4F6815);
const _kOliveM   = Color(0xFFD4E8A8);
const _kButter   = Color(0xFFFFEDAB);
const _kButterD  = Color(0xFFE8C84A);
const _kCocoa    = Color(0xFF5C3D3F);
const _kEspresso = Color(0xFF2C1A1B);
const _kFog      = Color(0xFF8C7B7C);
const _kInfo     = Color(0xFF185FA5);
const _kInfoBg   = Color(0xFFE6F1FB);

class HotelDashboardScreen extends StatefulWidget {
  const HotelDashboardScreen({super.key});

  @override
  State<HotelDashboardScreen> createState() => _HotelDashboardScreenState();
}

class _HotelDashboardScreenState extends State<HotelDashboardScreen>
    with TickerProviderStateMixin {
  late final AnimationController _enterCtrl;
  late final AnimationController _alertPulse;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _alertPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _alertPulse.dispose();
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final user      = context.watch<UserProvider>().currentUser;
    final hotelName = user?.hotelName ?? 'Your Hotel';
    final now       = DateTime.now();
    final dateStr   = DateFormat('EEEE, MMMM d').format(now);

    return Scaffold(
      backgroundColor: _kOat,
      body: RefreshIndicator(
        color: _kCherry,
        backgroundColor: _kParchment,
        onRefresh: () async => setState(() {}),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── App bar ────────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: _kCherry,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              flexibleSpace: FlexibleSpaceBar(
                background: _HotelHeader(
                  hotelName: hotelName,
                  greeting: _greeting(),
                  date: dateStr,
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // ── Live KPI row ─────────────────────────────────────────
                  _LiveKpiRow(hotelName: hotelName)
                      .animate(controller: _enterCtrl)
                      .fadeIn(delay: 100.ms)
                      .slideY(begin: 0.08, delay: 100.ms),

                  const SizedBox(height: 24),

                  // ── 🔔 Cross-notification: customer scans at this hotel ───
                  if (user?.id != null)
                    _HotelLiveCustomerAlerts(venueId: user!.id, pulseCtrl: _alertPulse)
                        .animate(controller: _enterCtrl)
                        .fadeIn(delay: 150.ms)
                        .slideY(begin: 0.06, delay: 150.ms),

                  const SizedBox(height: 24),

                  // ── Active guest allergen alerts ──────────────────────────
                  _SectionHeader(
                    title: 'Guest Allergen Alerts',
                    subtitle: 'Live — updates automatically',
                    icon: Icons.warning_amber_rounded,
                    iconColor: _kCherry,
                    dot: true,
                    pulseCtrl: _alertPulse,
                  ).animate(controller: _enterCtrl).fadeIn(delay: 200.ms),

                  const SizedBox(height: 10),

                  _AllergenAlertsStream(hotelName: hotelName, pulseCtrl: _alertPulse)
                      .animate(controller: _enterCtrl)
                      .fadeIn(delay: 300.ms)
                      .slideY(begin: 0.06, delay: 300.ms),

                  const SizedBox(height: 24),

                  // ── Expiry alerts ─────────────────────────────────────────
                  _SectionHeader(
                    title: 'Expiry Alerts',
                    subtitle: 'Items expiring within 48 h',
                    icon: Icons.schedule_rounded,
                    iconColor: _kButterD,
                  ).animate(controller: _enterCtrl).fadeIn(delay: 400.ms),

                  const SizedBox(height: 10),

                  _ExpiryAlertsStream(hotelName: hotelName)
                      .animate(controller: _enterCtrl)
                      .fadeIn(delay: 500.ms)
                      .slideY(begin: 0.06, delay: 500.ms),

                  const SizedBox(height: 24),

                  // ── Guest cards ───────────────────────────────────────────
                  _SectionHeader(
                    title: 'Current Guests',
                    subtitle: 'Checked-in profiles',
                    icon: Icons.people_rounded,
                    iconColor: _kInfo,
                  ).animate(controller: _enterCtrl).fadeIn(delay: 600.ms),

                  const SizedBox(height: 10),

                  _GuestCardsStream(hotelName: hotelName)
                      .animate(controller: _enterCtrl)
                      .fadeIn(delay: 700.ms)
                      .slideY(begin: 0.06, delay: 700.ms),

                  const SizedBox(height: 24),

                  // ── Quick actions ─────────────────────────────────────────
                  _SectionHeader(
                    title: 'Quick Actions',
                    icon: Icons.bolt_rounded,
                    iconColor: _kOlive,
                  ).animate(controller: _enterCtrl).fadeIn(delay: 800.ms),

                  const SizedBox(height: 10),

                  _QuickActionsRow(hotelName: hotelName)
                      .animate(controller: _enterCtrl)
                      .fadeIn(delay: 900.ms)
                      .slideY(begin: 0.06, delay: 900.ms),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hotel header ───────────────────────────────────────────────────────────────
class _HotelHeader extends StatelessWidget {
  final String hotelName;
  final String greeting;
  final String date;

  const _HotelHeader({
    required this.hotelName,
    required this.greeting,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF75070C), Color(0xFF9E1A21), Color(0xFF5C3D3F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kButter.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kButter.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(
                        color: _kButter, shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'HOTEL DASHBOARD',
                      style: GoogleFonts.inter(
                        fontSize: 9, fontWeight: FontWeight.w800,
                        color: _kButter, letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$greeting,',
            style: GoogleFonts.inter(
              fontSize: 13, color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          Text(
            hotelName,
            style: GoogleFonts.sora(
              fontSize: 22, fontWeight: FontWeight.w800,
              color: Colors.white, letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: GoogleFonts.inter(
              fontSize: 12, color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Live KPI row ───────────────────────────────────────────────────────────────
class _LiveKpiRow extends StatelessWidget {
  final String hotelName;
  const _LiveKpiRow({required this.hotelName});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('hotel_guests')
          .where('hotelName', isEqualTo: hotelName)
          .where('checkedIn', isEqualTo: true)
          .snapshots(),
      builder: (context, guestSnap) {
        final guestCount = guestSnap.data?.docs.length ?? 0;
        final allergenCount = guestSnap.data?.docs
            .where((d) => ((d.data() as Map)['allergens'] as List?)?.isNotEmpty == true)
            .length ?? 0;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('hotel_expiry_alerts')
              .where('hotelName', isEqualTo: hotelName)
              .where('resolved', isEqualTo: false)
              .snapshots(),
          builder: (context, expirySnap) {
            final expiryCount = expirySnap.data?.docs.length ?? 0;

            return Row(
              children: [
                Expanded(child: _KpiCard(
                  value: '$guestCount',
                  label: 'Guests In',
                  icon: Icons.hotel_rounded,
                  color: _kInfo,
                  bg: _kInfoBg,
                )),
                const SizedBox(width: 10),
                Expanded(child: _KpiCard(
                  value: '$allergenCount',
                  label: 'Allergen Profiles',
                  icon: Icons.warning_amber_rounded,
                  color: _kCherry,
                  bg: _kCherryB,
                )),
                const SizedBox(width: 10),
                Expanded(child: _KpiCard(
                  value: '$expiryCount',
                  label: 'Expiry Alerts',
                  icon: Icons.schedule_rounded,
                  color: _kButterD,
                  bg: _kButter,
                )),
              ],
            );
          },
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;

  const _KpiCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.sora(
              fontSize: 26, fontWeight: FontWeight.w800, color: _kEspresso,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.w500,
              color: _kFog, height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String  title;
  final String? subtitle;
  final IconData icon;
  final Color   iconColor;
  final bool    dot;
  final AnimationController? pulseCtrl;

  const _SectionHeader({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.iconColor,
    this.dot = false,
    this.pulseCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: GoogleFonts.sora(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: _kEspresso,
                    ),
                  ),
                  if (dot && pulseCtrl != null) ...[
                    const SizedBox(width: 8),
                    AnimatedBuilder(
                      animation: pulseCtrl!,
                      builder: (_, _) => Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _kOlive.withValues(alpha: 0.5 + pulseCtrl!.value * 0.5),
                          boxShadow: [
                            BoxShadow(
                              color: _kOlive.withValues(alpha: 0.4 * pulseCtrl!.value),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: GoogleFonts.inter(fontSize: 11, color: _kFog),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Allergen alerts stream ─────────────────────────────────────────────────────
class _AllergenAlertsStream extends StatelessWidget {
  final String hotelName;
  final AnimationController pulseCtrl;

  const _AllergenAlertsStream({
    required this.hotelName,
    required this.pulseCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('hotel_guests')
          .where('hotelName', isEqualTo: hotelName)
          .where('checkedIn', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _ShimmerCard(height: 80);
        }

        final docs = snapshot.data?.docs ?? [];
        final withAllergens = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final allergens = (data['allergens'] as List?) ?? [];
          return allergens.isNotEmpty;
        }).toList();

        if (withAllergens.isEmpty) {
          return _EmptyState(
            icon: Icons.check_circle_outline_rounded,
            message: 'No allergen alerts — all clear!',
            color: _kOlive,
          );
        }

        return Column(
          children: withAllergens.map((doc) {
            final data   = doc.data() as Map<String, dynamic>;
            final name   = data['guestName'] as String? ?? 'Guest';
            final room   = data['room'] as String? ?? '—';
            final allergens = List<String>.from(data['allergens'] as List? ?? []);
            return _AllergenAlertTile(
              guestName: name,
              room: room,
              allergens: allergens,
              pulseCtrl: pulseCtrl,
            );
          }).toList(),
        );
      },
    );
  }
}

class _AllergenAlertTile extends StatelessWidget {
  final String guestName;
  final String room;
  final List<String> allergens;
  final AnimationController pulseCtrl;

  const _AllergenAlertTile({
    required this.guestName,
    required this.room,
    required this.allergens,
    required this.pulseCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseCtrl,
      builder: (_, _) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCherryB.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _kCherry.withValues(alpha: 0.3 + pulseCtrl.value * 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _kCherry.withValues(alpha: 0.06 + pulseCtrl.value * 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _kCherry.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: _kCherry.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(
                  guestName.isNotEmpty ? guestName[0].toUpperCase() : 'G',
                  style: GoogleFonts.sora(
                    fontSize: 18, fontWeight: FontWeight.w800, color: _kCherry,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        guestName,
                        style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: _kEspresso,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _kInfo.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Room $room',
                          style: GoogleFonts.inter(
                            fontSize: 11, fontWeight: FontWeight.w600, color: _kInfo,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: allergens.map((a) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kCherry.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _kCherry.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '⚠ $a',
                        style: GoogleFonts.inter(
                          fontSize: 10, fontWeight: FontWeight.w700, color: _kCherry,
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Expiry alerts stream ───────────────────────────────────────────────────────
class _ExpiryAlertsStream extends StatelessWidget {
  final String hotelName;
  const _ExpiryAlertsStream({required this.hotelName});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('hotel_expiry_alerts')
          .where('hotelName', isEqualTo: hotelName)
          .where('resolved', isEqualTo: false)
          .orderBy('expiresAt')
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _ShimmerCard(height: 70);
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _EmptyState(
            icon: Icons.inventory_2_outlined,
            message: 'No expiry alerts — inventory is fresh!',
            color: _kOlive,
          );
        }

        return Column(
          children: docs.map((doc) {
            final data     = doc.data() as Map<String, dynamic>;
            final item     = data['itemName'] as String? ?? 'Unknown item';
            final location = data['location'] as String? ?? 'Storage';
            final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
            final hoursLeft = expiresAt != null
                ? expiresAt.difference(DateTime.now()).inHours
                : 0;
            final isUrgent = hoursLeft < 12;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isUrgent
                    ? _kCherryB.withValues(alpha: 0.3)
                    : _kButter.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isUrgent
                      ? _kCherry.withValues(alpha: 0.3)
                      : _kButterD.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    color: isUrgent ? _kCherry : _kButterD,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item,
                          style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: _kEspresso,
                          ),
                        ),
                        Text(
                          location,
                          style: GoogleFonts.inter(fontSize: 11, color: _kFog),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isUrgent
                          ? _kCherry.withValues(alpha: 0.12)
                          : _kButterD.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isUrgent ? '${hoursLeft}h left' : '${hoursLeft}h left',
                      style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.w800,
                        color: isUrgent ? _kCherry : _kButterD,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ── Guest cards stream ─────────────────────────────────────────────────────────
class _GuestCardsStream extends StatelessWidget {
  final String hotelName;
  const _GuestCardsStream({required this.hotelName});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('hotel_guests')
          .where('hotelName', isEqualTo: hotelName)
          .where('checkedIn', isEqualTo: true)
          .orderBy('checkInAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, _) => _ShimmerCard(width: 140, height: 140),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _EmptyState(
            icon: Icons.person_outline_rounded,
            message: 'No guests checked in yet.',
            color: _kInfo,
          );
        }

        return SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final name = data['guestName'] as String? ?? 'Guest';
              final room = data['room'] as String? ?? '—';
              final allergens = List<String>.from(data['allergens'] as List? ?? []);
              final checkIn = (data['checkInAt'] as Timestamp?)?.toDate();

              return _GuestCard(
                name: name,
                room: room,
                allergens: allergens,
                checkIn: checkIn,
              ).animate().fadeIn(delay: Duration(milliseconds: index * 80)).slideX(
                    begin: 0.1,
                    delay: Duration(milliseconds: index * 80),
                    curve: Curves.easeOutCubic,
                  );
            },
          ),
        );
      },
    );
  }
}

class _GuestCard extends StatelessWidget {
  final String        name;
  final String        room;
  final List<String>  allergens;
  final DateTime?     checkIn;

  const _GuestCard({
    required this.name,
    required this.room,
    required this.allergens,
    required this.checkIn,
  });

  Color get _avatarColor {
    final colors = [_kCherry, _kOlive, _kInfo, _kButterD, _kCocoa];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kParchment,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kSand),
        boxShadow: [
          BoxShadow(
            color: _kEspresso.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + room
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _avatarColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: _avatarColor.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Text(
                    name[0].toUpperCase(),
                    style: GoogleFonts.sora(
                      fontSize: 18, fontWeight: FontWeight.w800,
                      color: _avatarColor,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: _kInfo.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  room,
                  style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w700, color: _kInfo,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w700, color: _kEspresso,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (checkIn != null)
            Text(
              'In: ${DateFormat('HH:mm').format(checkIn!)}',
              style: GoogleFonts.inter(fontSize: 10, color: _kFog),
            ),
          const Spacer(),
          // Allergen pills
          if (allergens.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: _kOlive.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '✓ No allergens',
                style: GoogleFonts.inter(
                  fontSize: 9, fontWeight: FontWeight.w600, color: _kOlive,
                ),
              ),
            )
          else
            Wrap(
              spacing: 3,
              runSpacing: 3,
              children: allergens.take(2).map((a) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: _kCherry.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  a,
                  style: GoogleFonts.inter(
                    fontSize: 8, fontWeight: FontWeight.w700, color: _kCherry,
                  ),
                ),
              )).toList(),
            ),
        ],
      ),
    );
  }
}

// ── Quick actions ──────────────────────────────────────────────────────────────
class _QuickActionsRow extends StatelessWidget {
  final String hotelName;
  const _QuickActionsRow({required this.hotelName});

  void _checkInGuest(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _CheckInDialog(hotelName: hotelName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionBtn(
            icon: Icons.person_add_rounded,
            label: 'Check-in Guest',
            color: _kOlive,
            bg: _kOliveM,
            onTap: () => _checkInGuest(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionBtn(
            icon: Icons.qr_code_scanner_rounded,
            label: 'Scan Food',
            color: _kCherry,
            bg: _kCherryB,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionBtn(
            icon: Icons.add_alert_rounded,
            label: 'Add Alert',
            color: _kButterD,
            bg: _kButter,
            onTap: () => _showAddExpiryDialog(context, hotelName),
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatefulWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final Color    bg;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: widget.bg.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: widget.color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(widget.icon, color: widget.color, size: 24),
              const SizedBox(height: 6),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: widget.color, height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Check-in dialog ────────────────────────────────────────────────────────────
class _CheckInDialog extends StatefulWidget {
  final String hotelName;
  const _CheckInDialog({required this.hotelName});

  @override
  State<_CheckInDialog> createState() => _CheckInDialogState();
}

class _CheckInDialogState extends State<_CheckInDialog> {
  final _nameCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  final List<String> _selected = [];
  bool _saving = false;

  static const _commonAllergens = [
    'Gluten', 'Nuts', 'Dairy', 'Eggs', 'Shellfish',
    'Soy', 'Fish', 'Sesame', 'Peanuts', 'Mustard', 'Sulphites',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roomCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _roomCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('hotel_guests').add({
        'hotelName': widget.hotelName,
        'guestName': _nameCtrl.text.trim(),
        'room': _roomCtrl.text.trim(),
        'allergens': _selected,
        'checkedIn': true,
        'checkInAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _kParchment,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'Check-in Guest',
        style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700, color: _kEspresso),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Input(ctrl: _nameCtrl, hint: 'Guest full name', icon: Icons.person_rounded),
            const SizedBox(height: 12),
            _Input(ctrl: _roomCtrl, hint: 'Room number', icon: Icons.hotel_rounded, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            Text('Allergens / Conditions', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _kCocoa)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _commonAllergens.map((a) {
                final selected = _selected.contains(a);
                return GestureDetector(
                  onTap: () => setState(() {
                    selected ? _selected.remove(a) : _selected.add(a);
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: selected ? _kCherry : _kSand.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? _kCherry : _kSand,
                      ),
                    ),
                    child: Text(
                      a,
                      style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : _kCocoa,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: GoogleFonts.inter(color: _kFog, fontWeight: FontWeight.w600)),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: _kCherry,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('Check In', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ],
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;

  const _Input({
    required this.ctrl,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kSand),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(fontSize: 14, color: _kEspresso),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: _kCherry, size: 18),
          hintText: hint,
          hintStyle: GoogleFonts.inter(fontSize: 13, color: _kFog),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

// ── Add expiry dialog ──────────────────────────────────────────────────────────
void _showAddExpiryDialog(BuildContext context, String hotelName) {
  showDialog(
    context: context,
    builder: (_) => _AddExpiryDialog(hotelName: hotelName),
  );
}

class _AddExpiryDialog extends StatefulWidget {
  final String hotelName;
  const _AddExpiryDialog({required this.hotelName});

  @override
  State<_AddExpiryDialog> createState() => _AddExpiryDialogState();
}

class _AddExpiryDialogState extends State<_AddExpiryDialog> {
  final _itemCtrl     = TextEditingController();
  final _locationCtrl = TextEditingController();
  DateTime _expiresAt = DateTime.now().add(const Duration(hours: 24));
  bool _saving = false;

  @override
  void dispose() {
    _itemCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_itemCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('hotel_expiry_alerts').add({
        'hotelName': widget.hotelName,
        'itemName': _itemCtrl.text.trim(),
        'location': _locationCtrl.text.trim().isEmpty ? 'Storage' : _locationCtrl.text.trim(),
        'expiresAt': Timestamp.fromDate(_expiresAt),
        'resolved': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _kParchment,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'Add Expiry Alert',
        style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700, color: _kEspresso),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Input(ctrl: _itemCtrl, hint: 'Item name', icon: Icons.inventory_2_rounded),
          const SizedBox(height: 10),
          _Input(ctrl: _locationCtrl, hint: 'Location (Kitchen, Buffet...)', icon: Icons.place_rounded),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () async {
              final picked = await showDateTimePicker(context);
              if (picked != null) setState(() => _expiresAt = picked);
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kButter.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kButterD.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded, color: _kButterD, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMM d, HH:mm').format(_expiresAt),
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _kEspresso),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: GoogleFonts.inter(color: _kFog, fontWeight: FontWeight.w600)),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: _kCherry,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ],
    );
  }
}

Future<DateTime?> showDateTimePicker(BuildContext context) async {
  final date = await showDatePicker(
    context: context,
    initialDate: DateTime.now().add(const Duration(hours: 24)),
    firstDate: DateTime.now(),
    lastDate: DateTime.now().add(const Duration(days: 30)),
  );
  if (date == null) return null;
  if (!context.mounted) return null;
  final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
  if (time == null) return null;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

// ── Empty state ────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String   message;
  final Color    color;

  const _EmptyState({required this.icon, required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(
            message,
            style: GoogleFonts.inter(fontSize: 13, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ── Shimmer card ───────────────────────────────────────────────────────────────
class _ShimmerCard extends StatefulWidget {
  final double height;
  final double? width;
  const _ShimmerCard({required this.height, this.width});

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

// ── 🔔 Hotel Live Customer Alerts (cross-notification) ───────────────────────
/// Shows real-time alerts when a customer with allergens scans food
/// at THIS hotel. Data comes from the `venue_alerts` Firestore collection.
class _HotelLiveCustomerAlerts extends StatefulWidget {
  final String venueId;
  final AnimationController pulseCtrl;
  const _HotelLiveCustomerAlerts({required this.venueId, required this.pulseCtrl});

  @override
  State<_HotelLiveCustomerAlerts> createState() => _HotelLiveCustomerAlertsState();
}

class _HotelLiveCustomerAlertsState extends State<_HotelLiveCustomerAlerts> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: VenueAlertService.alertsStream(widget.venueId),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) return const SizedBox.shrink();

        final docs = snap.data!.docs;
        return Container(
          decoration: BoxDecoration(
            color: _kCherry.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _kCherry.withValues(alpha: 0.28), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: widget.pulseCtrl,
                      builder: (_, _) => Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _kCherry.withValues(
                            alpha: 0.4 + widget.pulseCtrl.value * 0.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '🚨 Guest Scans — ${docs.length} alert${docs.length == 1 ? '' : 's'}',
                        style: GoogleFonts.sora(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _kCherry,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => VenueAlertService.resolveAll(widget.venueId),
                      style: TextButton.styleFrom(
                        foregroundColor: _kCherry,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Clear all',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ...docs.map((doc) {
                final d = doc.data();
                final name      = d['customerName'] as String? ?? 'Guest';
                final allergens = List<String>.from(d['allergens'] as List? ?? []);
                final product   = d['productName'] as String? ?? '';
                final room      = d['room'] as String?;
                final risk      = d['riskLevel'] as String? ?? 'moderate';
                final riskColor = risk == 'high' ? _kCherry : risk == 'low' ? _kOlive : _kButterD;

                return Container(
                  margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _kParchment,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: riskColor.withValues(alpha: 0.25), width: 0.8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: riskColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Icon(Icons.person_rounded, size: 18, color: riskColor),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  name,
                                  style: GoogleFonts.sora(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _kEspresso,
                                  ),
                                ),
                                if (room != null) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _kInfo.withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      'Room $room',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: _kInfo,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (product.isNotEmpty)
                              Text(
                                'Scanned: $product',
                                style: GoogleFonts.inter(fontSize: 11, color: _kFog),
                              ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: allergens.map((a) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: riskColor.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: riskColor.withValues(alpha: 0.30)),
                                ),
                                child: Text(
                                  a,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: riskColor,
                                  ),
                                ),
                              )).toList(),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => VenueAlertService.resolve(doc.id),
                        child: Icon(Icons.check_circle_outline_rounded, size: 20, color: _kOlive),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment(-1.5 + _ctrl.value * 3, 0),
            end: Alignment(0 + _ctrl.value * 3, 0),
            colors: [
              _kSand.withValues(alpha: 0.4),
              _kParchment.withValues(alpha: 0.9),
              _kSand.withValues(alpha: 0.4),
            ],
          ),
        ),
      ),
    );
  }
}
