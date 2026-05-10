import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../core/firebase_service.dart';
import '../../../core/venue_alert_service.dart';
import '../../../providers/user_provider.dart';
import '../../../features/shared/compost_dashboard_panel.dart';
import '../../../shared/animations/shimmer_box.dart';
import '../../../widgets/animated_chat_fab.dart';

// ── Brand palette ──────────────────────────────────────────────────────────────
const _kOat = Color(0xFFF0F5F8);
const _kParchment = Color(0xFFFFFFFF);
const _kSand = Color(0xFFD9E9F5);
const _kCherry = Color(0xFF5A9FC9);
const _kCherryB = Color(0xFFD9E9F5);
const _kOlive = Color(0xFF35658F);
const _kOliveM = Color(0xFFEDF7F3);
const _kButter = Color(0xFFFFE566);
const _kButterD = Color(0xFFFFAB5B);
const _kCocoa = Color(0xFF5C4F48);
const _kEspresso = Color(0xFF26201B);
const _kFog = Color(0xFF8C7E78);
const _kInfo = Color(0xFF185FA5);
const _kInfoBg = Color(0xFFE6F1FB);

class HotelDashboardScreen extends StatefulWidget {
  const HotelDashboardScreen({super.key});

  @override
  State<HotelDashboardScreen> createState() => _HotelDashboardScreenState();
}

class _HotelDashboardScreenState extends State<HotelDashboardScreen>
    with TickerProviderStateMixin {
  late final AnimationController _enterCtrl;
  late final AnimationController _alertPulse;
  int _dashboardTab = 0;

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

  Future<void> _signOut() async {
    await FirebaseService.signOut();
    if (!mounted) return;
    context.go('/');
  }

  String _hotelId(UserProvider userProvider) {
    final user = userProvider.currentUser;
    if (user == null) return '';
    return user.entityId ?? user.hotelId ?? user.id;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.currentUser;
    final hotelId = _hotelId(userProvider);
    final hotelName = user?.hotelName ?? 'Your Hotel';
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMMM d').format(now);
    final showCompost = _dashboardTab == 1;

    return Scaffold(
      backgroundColor: _kOat,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A7FA5),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greeting(),
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'FreshGuard',
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent_rounded, color: Colors.white),
            tooltip: 'Sage',
            onPressed: () => context.go('/hotel/chatbot'),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
          ),
        ],
      ),
      floatingActionButton: AnimatedChatFab(
        color: const Color(0xFF4A7FA5),
        label: 'Ask Sage',
        icon: Icons.support_agent_rounded,
        onTap: () => context.go('/hotel/chatbot'),
      ),
      body: RefreshIndicator(
        color: _kCherry,
        backgroundColor: _kParchment,
        onRefresh: () async => setState(() {}),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── App bar ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _HotelDashboardTabs(
                  showCompost: showCompost,
                  onOverview: () => setState(() => _dashboardTab = 0),
                  onCompost: () => setState(() => _dashboardTab = 1),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _HotelHeader(
                  hotelName: hotelName,
                  greeting: _greeting(),
                  date: dateStr,
                ),
              ),
            ),
            if (showCompost)
              SliverToBoxAdapter(
                child: CompostDashboardPanel(
                  entityId: hotelId,
                  entityCollection: 'hotels',
                  title: 'Hotel Compost',
                  showDepartmentSelector: true,
                  accent: _kOlive,
                  deep: _kCherry,
                  softBg: _kOliveM,
                  surface: _kOat,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Live KPI row ─────────────────────────────────────────
                    _LiveKpiRow(hotelId: hotelId)
                        .animate(controller: _enterCtrl)
                        .fadeIn(delay: 100.ms)
                        .slideY(begin: 0.08, delay: 100.ms),

                    const SizedBox(height: 24),

                    // ── 🔔 Cross-notification: customer scans at this hotel ───
                    if (user?.id != null)
                      _HotelLiveCustomerAlerts(
                            venueId: user!.id,
                            pulseCtrl: _alertPulse,
                          )
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

                    _AllergenAlertsStream(
                          hotelName: hotelName,
                          pulseCtrl: _alertPulse,
                        )
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

                    _QuickActionsRow(
                      hotelName: hotelName,
                      onOpenCompost: () => setState(() => _dashboardTab = 1),
                    )
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
      decoration: BoxDecoration(
        color: _kCherry,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _kButter.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kButter.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: _kButter,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'HOTEL DASHBOARD',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: _kButter,
                        letterSpacing: 1.2,
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
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          Text(
            hotelName,
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Live KPI row ───────────────────────────────────────────────────────────────
class _LiveKpiRow extends StatelessWidget {
  final String hotelId;
  const _LiveKpiRow({required this.hotelId});

  String isoWeek() {
    final now = DateTime.now();
    final thursday = now.add(Duration(days: 3 - ((now.weekday + 6) % 7)));
    final firstThursday = DateTime(thursday.year, 1, 4);
    final week = 1 +
        (thursday.difference(firstThursday).inDays / 7).floor();
    return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (hotelId.isEmpty) {
      return const _HotelKpiCards(
        wasteValue: '—',
        compostValue: '—',
        freshnessValue: '—',
        alertsValue: '—',
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('compost_totals')
          .doc(hotelId)
          .collection('weekly')
          .doc(isoWeek())
          .snapshots(),
      builder: (context, weeklySnap) {
        final weeklyLoading =
            weeklySnap.connectionState == ConnectionState.waiting;
        final weeklyExists = weeklySnap.data?.exists == true;
        final data = weeklySnap.data?.data() ?? const <String, dynamic>{};
        final wasteKg = _asDouble(data['waste_kg']);
        final compostableKg = _asDouble(data['compostable_kg']);
        final compostRate = wasteKg <= 0 ? 0.0 : compostableKg / wasteKg * 100;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('hotels')
              .doc(hotelId)
              .collection('scans')
              .orderBy('timestamp', descending: true)
              .limit(10)
              .snapshots(),
          builder: (context, freshnessSnap) {
            final freshnessLoading =
                freshnessSnap.connectionState == ConnectionState.waiting;
            final scores =
                freshnessSnap.data?.docs
                    .map(
                      (doc) => _asDouble(doc.data()['freshness_confidence']),
                    )
                    .where((score) => score > 0)
                    .toList() ??
                const <double>[];
            final hasFreshness = scores.isNotEmpty;
            final freshness = hasFreshness
                ? scores.reduce((a, b) => a + b) / scores.length
                : 0.0;

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('hotels')
                  .doc(hotelId)
                  .collection('alerts')
                  .where('resolved', isEqualTo: false)
                  .snapshots(),
              builder: (context, alertsSnap) {
                final alertsLoading =
                    alertsSnap.connectionState == ConnectionState.waiting;
                final alertCount = alertsSnap.data?.docs.length ?? 0;

                return _HotelKpiCards(
                  wasteValue: weeklyExists
                      ? '${wasteKg.toStringAsFixed(1)} kg'
                      : '—',
                  compostValue: weeklyExists
                      ? '${compostRate.toStringAsFixed(0)}%'
                      : '—',
                  freshnessValue: hasFreshness
                      ? '${freshness.toStringAsFixed(0)}%'
                      : '—',
                  alertsValue: '$alertCount alerts',
                  wasteLoading: weeklyLoading,
                  compostLoading: weeklyLoading,
                  freshnessLoading: freshnessLoading,
                  alertsLoading: alertsLoading,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _HotelKpiCards extends StatelessWidget {
  final String wasteValue;
  final String compostValue;
  final String freshnessValue;
  final String alertsValue;
  final bool wasteLoading;
  final bool compostLoading;
  final bool freshnessLoading;
  final bool alertsLoading;

  const _HotelKpiCards({
    required this.wasteValue,
    required this.compostValue,
    required this.freshnessValue,
    required this.alertsValue,
    this.wasteLoading = false,
    this.compostLoading = false,
    this.freshnessLoading = false,
    this.alertsLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.15,
      children: [
        _KpiCard(
          value: wasteValue,
          label: 'Waste This Week',
          icon: Icons.delete_outline_rounded,
          color: _kOlive,
          bg: _kOliveM,
          loading: wasteLoading,
        ),
        _KpiCard(
          value: compostValue,
          label: 'Compost Rate',
          icon: Icons.recycling_rounded,
          color: _kCherry,
          bg: _kCherryB,
          loading: compostLoading,
        ),
        _KpiCard(
          value: freshnessValue,
          label: 'Freshness Score',
          icon: Icons.eco_rounded,
          color: _kInfo,
          bg: _kInfoBg,
          loading: freshnessLoading,
        ),
        _KpiCard(
          value: alertsValue,
          label: 'Active Alerts',
          icon: Icons.warning_amber_rounded,
          color: _kButterD,
          bg: _kButter,
          loading: alertsLoading,
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  final bool loading;

  const _KpiCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
    this.loading = false,
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
          if (loading)
            const ShimmerBox(width: 72, height: 26, radius: 8)
          else
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _kEspresso,
              ),
            ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: _kFog,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final bool dot;
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
          width: 32,
          height: 32,
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
                  Flexible(
                    child: Text(
                      title,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kEspresso,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (dot && pulseCtrl != null) ...[
                    const SizedBox(width: 8),
                    AnimatedBuilder(
                      animation: pulseCtrl!,
                      builder: (_, _) => Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _kOlive.withValues(
                            alpha: 0.5 + pulseCtrl!.value * 0.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _kOlive.withValues(
                                alpha: 0.4 * pulseCtrl!.value,
                              ),
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
            final data = doc.data() as Map<String, dynamic>;
            final name = data['guestName'] as String? ?? 'Guest';
            final room = data['room'] as String? ?? '—';
            final allergens = List<String>.from(
              data['allergens'] as List? ?? [],
            );
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _kCherry.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: _kCherry.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(
                  guestName.isNotEmpty ? guestName[0].toUpperCase() : 'G',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _kCherry,
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
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _kEspresso,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _kInfo.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Room $room',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _kInfo,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: allergens
                        .map(
                          (a) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _kCherry.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _kCherry.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '⚠ $a',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _kCherry,
                              ),
                            ),
                          ),
                        )
                        .toList(),
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
            final data = doc.data() as Map<String, dynamic>;
            final item = data['itemName'] as String? ?? 'Unknown item';
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
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isUrgent
                          ? _kCherry.withValues(alpha: 0.12)
                          : _kButterD.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isUrgent ? '${hoursLeft}h left' : '${hoursLeft}h left',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
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
              final allergens = List<String>.from(
                data['allergens'] as List? ?? [],
              );
              final checkIn = (data['checkInAt'] as Timestamp?)?.toDate();

              return _GuestCard(
                    name: name,
                    room: room,
                    allergens: allergens,
                    checkIn: checkIn,
                  )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: index * 80))
                  .slideX(
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
  final String name;
  final String room;
  final List<String> allergens;
  final DateTime? checkIn;

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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _avatarColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _avatarColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    name[0].toUpperCase(),
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
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
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _kInfo,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _kEspresso,
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
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: _kOlive,
                ),
              ),
            )
          else
            Wrap(
              spacing: 3,
              runSpacing: 3,
              children: allergens
                  .take(2)
                  .map(
                    (a) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _kCherry.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        a,
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: _kCherry,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

// ── Quick actions ──────────────────────────────────────────────────────────────
class _QuickActionsRow extends StatelessWidget {
  final String hotelName;
  final VoidCallback onOpenCompost;
  const _QuickActionsRow({
    required this.hotelName,
    required this.onOpenCompost,
  });

  void _checkInGuest(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _CheckInDialog(hotelName: hotelName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _ActionBtn(
            icon: Icons.person_add_rounded,
            label: 'Check-in',
            color: _kOlive,
            bg: _kOliveM,
            onTap: () => _checkInGuest(context),
          ),
          const SizedBox(width: 12),
          _ActionBtn(
            icon: Icons.qr_code_scanner_rounded,
            label: 'Scanner',
            color: _kCherry,
            bg: _kCherryB,
            onTap: () => context.go(AppRoutes.hotelScan),
          ),
          const SizedBox(width: 12),
          _ActionBtn(
            icon: Icons.event_available_rounded,
            label: 'Expiry',
            color: _kButterD,
            bg: _kButter,
            onTap: () => context.go(AppRoutes.hotelExpiryDate),
          ),
          const SizedBox(width: 12),
          _ActionBtn(
            icon: Icons.recycling_rounded,
            label: 'Compost',
            color: const Color(0xFF45C4B0),
            bg: const Color(0xFFE8FBF7),
            onTap: onOpenCompost,
          ),
          const SizedBox(width: 12),
          _ActionBtn(
            icon: Icons.history_rounded,
            label: 'History',
            color: _kInfo,
            bg: _kInfoBg,
            onTap: () => context.go(AppRoutes.hotelHistory),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
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
          width: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: widget.bg.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: widget.color.withValues(alpha: 0.3)),
                ),
                child: Icon(widget.icon, color: widget.color, size: 24),
              ),
              const SizedBox(height: 6),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HotelDashboardTabs extends StatelessWidget {
  final bool showCompost;
  final VoidCallback onOverview;
  final VoidCallback onCompost;

  const _HotelDashboardTabs({
    required this.showCompost,
    required this.onOverview,
    required this.onCompost,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onOverview,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: showCompost ? Colors.transparent : const Color(0xFF4A7FA5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Overview',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: showCompost ? Colors.black54 : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: onCompost,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: showCompost ? const Color(0xFF4A7FA5) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Compost',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: showCompost ? Colors.white : Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
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
    'Gluten',
    'Nuts',
    'Dairy',
    'Eggs',
    'Shellfish',
    'Soy',
    'Fish',
    'Sesame',
    'Peanuts',
    'Mustard',
    'Sulphites',
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
        style: GoogleFonts.playfairDisplay(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: _kEspresso,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Input(
              ctrl: _nameCtrl,
              hint: 'Guest full name',
              icon: Icons.person_rounded,
            ),
            const SizedBox(height: 12),
            _Input(
              ctrl: _roomCtrl,
              hint: 'Room number',
              icon: Icons.hotel_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Text(
              'Allergens / Conditions',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _kCocoa,
              ),
            ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? _kCherry
                          : _kSand.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: selected ? _kCherry : _kSand),
                    ),
                    child: Text(
                      a,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(color: _kFog, fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: _kCherry,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Check In',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
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
  final _itemCtrl = TextEditingController();
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
        'location': _locationCtrl.text.trim().isEmpty
            ? 'Storage'
            : _locationCtrl.text.trim(),
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
        style: GoogleFonts.playfairDisplay(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: _kEspresso,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Input(
            ctrl: _itemCtrl,
            hint: 'Item name',
            icon: Icons.inventory_2_rounded,
          ),
          const SizedBox(height: 10),
          _Input(
            ctrl: _locationCtrl,
            hint: 'Location (Kitchen, Buffet...)',
            icon: Icons.place_rounded,
          ),
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
                  const Icon(
                    Icons.schedule_rounded,
                    color: _kButterD,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMM d, HH:mm').format(_expiresAt),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kEspresso,
                    ),
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
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(color: _kFog, fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: _kCherry,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Save',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
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
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
  );
  if (time == null) return null;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

// ── Empty state ────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.color,
  });

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
            style: GoogleFonts.inter(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
            ),
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
  const _HotelLiveCustomerAlerts({
    required this.venueId,
    required this.pulseCtrl,
  });

  @override
  State<_HotelLiveCustomerAlerts> createState() =>
      _HotelLiveCustomerAlertsState();
}

class _HotelLiveCustomerAlertsState extends State<_HotelLiveCustomerAlerts> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: VenueAlertService.alertsStream(widget.venueId),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty)
          return const SizedBox.shrink();

        final docs = snap.data!.docs;
        return Container(
          decoration: BoxDecoration(
            color: _kCherry.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _kCherry.withValues(alpha: 0.28),
              width: 1.2,
            ),
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
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _kCherry,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          VenueAlertService.resolveAll(widget.venueId),
                      style: TextButton.styleFrom(
                        foregroundColor: _kCherry,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Clear all',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ...docs.map((doc) {
                final d = doc.data();
                final name = d['customerName'] as String? ?? 'Guest';
                final allergens = List<String>.from(
                  d['allergens'] as List? ?? [],
                );
                final product = d['productName'] as String? ?? '';
                final room = d['room'] as String?;
                final risk = d['riskLevel'] as String? ?? 'moderate';
                final riskColor = risk == 'high'
                    ? _kCherry
                    : risk == 'low'
                    ? _kOlive
                    : _kButterD;

                return Container(
                  margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _kParchment,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: riskColor.withValues(alpha: 0.25),
                      width: 0.8,
                    ),
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
                          child: Icon(
                            Icons.person_rounded,
                            size: 18,
                            color: riskColor,
                          ),
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
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _kEspresso,
                                  ),
                                ),
                                if (room != null) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
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
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: _kFog,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: allergens
                                  .map(
                                    (a) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: riskColor.withValues(
                                          alpha: 0.10,
                                        ),
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color: riskColor.withValues(
                                            alpha: 0.30,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        a,
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: riskColor,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => VenueAlertService.resolve(doc.id),
                        child: Icon(
                          Icons.check_circle_outline_rounded,
                          size: 20,
                          color: _kOlive,
                        ),
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
